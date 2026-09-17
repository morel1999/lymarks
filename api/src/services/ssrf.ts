// Anti-SSRF : la surface critique n°1 (Security §3, Threat Model M1).
//
// L'utilisateur soumet une URL arbitraire que NOTRE serveur va chercher. Tout
// ce qui pourrait viser un réseau privé, un service de métadonnées cloud ou
// l'edge lui-même est refusé, avant le fetch ET après chaque redirection.
//
// Ce module est pur : la résolution DNS est injectée (DoH en prod, table
// fixe en test).

export type Resolver = (hostname: string) => Promise<string[]>;

export class UnsafeUrlError extends Error {
  constructor(
    public readonly reason: string,
    message: string,
  ) {
    super(message);
    this.name = "UnsafeUrlError";
  }
}

const BLOCKED_HOST_SUFFIXES = [
  ".localhost",
  ".local",
  ".internal",
  ".home.arpa",
  ".onion",
  ".arpa",
];
const BLOCKED_HOSTS = new Set(["localhost", "metadata.google.internal", "metadata"]);

/** Plages IPv4 réservées (RFC 6890 et suivantes), en [préfixe, longueur]. */
const V4_BLOCKED: Array<[number, number]> = [
  [ip4("0.0.0.0"), 8],
  [ip4("10.0.0.0"), 8],
  [ip4("100.64.0.0"), 10],
  [ip4("127.0.0.0"), 8],
  [ip4("169.254.0.0"), 16],
  [ip4("172.16.0.0"), 12],
  [ip4("192.0.0.0"), 24],
  [ip4("192.0.2.0"), 24],
  [ip4("192.88.99.0"), 24],
  [ip4("192.168.0.0"), 16],
  [ip4("198.18.0.0"), 15],
  [ip4("198.51.100.0"), 24],
  [ip4("203.0.113.0"), 24],
  [ip4("224.0.0.0"), 4],
  [ip4("240.0.0.0"), 4],
];

function ip4(s: string): number {
  const parts = s.split(".").map(Number);
  return ((parts[0]! << 24) | (parts[1]! << 16) | (parts[2]! << 8) | parts[3]!) >>> 0;
}

export function parseIPv4(s: string): number | null {
  const m = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(s);
  if (!m) return null;
  const parts = m.slice(1).map(Number);
  if (parts.some((p) => p > 255)) return null;
  return ((parts[0]! << 24) | (parts[1]! << 16) | (parts[2]! << 8) | parts[3]!) >>> 0;
}

/** Retourne les 8 groupes de 16 bits, ou null si invalide. Gère `::` et le suffixe IPv4. */
export function parseIPv6(input: string): number[] | null {
  let s = input.trim();
  if (s.startsWith("[") && s.endsWith("]")) s = s.slice(1, -1);
  const zone = s.indexOf("%");
  if (zone >= 0) s = s.slice(0, zone);
  if (!/^[0-9a-fA-F:.]+$/.test(s)) return null;

  // Suffixe IPv4 (::ffff:1.2.3.4) → deux groupes.
  const lastColon = s.lastIndexOf(":");
  if (s.includes(".")) {
    const v4 = parseIPv4(s.slice(lastColon + 1));
    if (v4 === null) return null;
    s = `${s.slice(0, lastColon)}:${(v4 >>> 16).toString(16)}:${(v4 & 0xffff).toString(16)}`;
  }

  const halves = s.split("::");
  if (halves.length > 2) return null;
  const head = halves[0] ? halves[0].split(":") : [];
  const tail = halves.length === 2 && halves[1] ? halves[1].split(":") : [];
  if (halves.length === 1 && head.length !== 8) return null;
  if (halves.length === 2 && head.length + tail.length > 7) return null;
  const groups = [...head, ...Array<string>(8 - head.length - tail.length).fill("0"), ...tail];
  const out: number[] = [];
  for (const g of groups) {
    if (g.length === 0 || g.length > 4) return null;
    out.push(parseInt(g, 16));
  }
  return out;
}

function v4InBlocked(addr: number): boolean {
  return V4_BLOCKED.some(([net, bits]) => {
    const mask = bits === 0 ? 0 : (~0 << (32 - bits)) >>> 0;
    return (addr & mask) >>> 0 === (net & mask) >>> 0;
  });
}

/** Vrai si l'adresse (v4 ou v6, littérale) est publique et routable. */
export function isPublicIp(ip: string): boolean {
  const v4 = parseIPv4(ip);
  if (v4 !== null) return !v4InBlocked(v4);

  const v6 = parseIPv6(ip);
  if (!v6) return false;
  const [g0, g1, g2, g3, g4, g5, g6, g7] = v6 as [
    number,
    number,
    number,
    number,
    number,
    number,
    number,
    number,
  ];
  const allZeroPrefix = g0 === 0 && g1 === 0 && g2 === 0 && g3 === 0 && g4 === 0;
  if (allZeroPrefix && g5 === 0 && g6 === 0 && (g7 === 0 || g7 === 1)) return false; // :: et ::1
  if (allZeroPrefix && g5 === 0xffff) return !v4InBlocked(((g6 << 16) | g7) >>> 0); // ::ffff:a.b.c.d
  if (allZeroPrefix && g5 === 0) return false; // ::a.b.c.d (compatible IPv4, obsolète)
  if (g0 === 0x64 && g1 === 0xff9b) return false; // 64:ff9b::/96 NAT64
  if ((g0 & 0xfe00) === 0xfc00) return false; // fc00::/7 ULA
  if ((g0 & 0xffc0) === 0xfe80) return false; // fe80::/10 link-local
  if ((g0 & 0xffc0) === 0xfec0) return false; // fec0::/10 site-local (obsolète)
  if (g0 === 0x2001 && g1 === 0x0db8) return false; // documentation
  if (g0 === 0x2001 && g1 === 0) return false; // Teredo : encapsule une v4 arbitraire
  if (g0 === 0x2002) return false; // 6to4 : idem
  if ((g0 & 0xff00) === 0xff00) return false; // multicast
  return true;
}

function isIpLiteral(host: string): boolean {
  return parseIPv4(host) !== null || host.startsWith("[") || parseIPv6(host) !== null;
}

/**
 * Vérifie une URL avant fetch : schéma, port, hôte, et — via le résolveur —
 * chaque adresse vers laquelle l'hôte pointe. Lève UnsafeUrlError sinon.
 */
export async function assertPublicUrl(raw: string, resolve: Resolver): Promise<URL> {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new UnsafeUrlError("invalid_url", "URL invalide");
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new UnsafeUrlError("scheme", `Schéma refusé : ${url.protocol}`);
  }
  if (url.username || url.password) {
    throw new UnsafeUrlError("credentials", "Identifiants dans l'URL refusés");
  }
  if (url.port && url.port !== "80" && url.port !== "443") {
    throw new UnsafeUrlError("port", `Port refusé : ${url.port}`);
  }

  const host = url.hostname.toLowerCase().replace(/\.$/, "");
  if (!host) throw new UnsafeUrlError("host", "Hôte vide");
  if (BLOCKED_HOSTS.has(host) || BLOCKED_HOST_SUFFIXES.some((s) => host.endsWith(s))) {
    throw new UnsafeUrlError("host", `Hôte refusé : ${host}`);
  }
  // Un hôte sans point n'est jamais public ("intranet", "metadata"...).
  if (!host.includes(".") && !isIpLiteral(host)) {
    throw new UnsafeUrlError("host", `Hôte non qualifié refusé : ${host}`);
  }
  // Représentations exotiques d'IP (octal, décimal, hexa) : refusées d'office.
  if (/^[0-9]+$/.test(host) || /^0x/i.test(host)) {
    throw new UnsafeUrlError("host", `Adresse ambiguë refusée : ${host}`);
  }

  if (isIpLiteral(host)) {
    if (!isPublicIp(host))
      throw new UnsafeUrlError("private_ip", `Adresse privée refusée : ${host}`);
    return url;
  }

  const addresses = await resolve(host);
  if (addresses.length === 0) throw new UnsafeUrlError("dns", `Hôte introuvable : ${host}`);
  for (const ip of addresses) {
    if (!isPublicIp(ip))
      throw new UnsafeUrlError("private_ip", `${host} pointe vers une adresse privée`);
  }
  return url;
}

/**
 * Résolveur DNS-over-HTTPS (Cloudflare 1.1.1.1). Le Worker n'a pas d'API DNS :
 * on interroge le résolveur public pour connaître les adresses avant le fetch.
 */
export function dohResolver(fetchFn: typeof fetch = fetch): Resolver {
  return async (hostname) => {
    const lookup = async (type: "A" | "AAAA"): Promise<string[]> => {
      const res = await fetchFn(
        `https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(hostname)}&type=${type}`,
        { headers: { accept: "application/dns-json" } },
      );
      if (!res.ok) return [];
      const body = (await res.json()) as { Answer?: Array<{ type: number; data: string }> };
      const wanted = type === "A" ? 1 : 28;
      return (body.Answer ?? []).filter((a) => a.type === wanted).map((a) => a.data);
    };
    const [a, aaaa] = await Promise.all([lookup("A"), lookup("AAAA")]);
    return [...a, ...aaaa];
  };
}
