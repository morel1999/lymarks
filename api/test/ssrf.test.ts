// Suite sécurité M1 (Test Strategy) : toute URL visant un réseau privé est
// rejetée, avant fetch et après redirection.

import { describe, expect, it } from "vitest";
import { safeFetch } from "../src/services/scraper.js";
import {
  assertPublicUrl,
  isPublicIp,
  parseIPv6,
  UnsafeUrlError,
  type Resolver,
} from "../src/services/ssrf.js";

const publicResolver: Resolver = async () => ["93.184.216.34"];

async function reason(url: string, resolve: Resolver = publicResolver): Promise<string> {
  try {
    await assertPublicUrl(url, resolve);
    return "accepted";
  } catch (err) {
    return err instanceof UnsafeUrlError ? err.reason : "other";
  }
}

describe("isPublicIp", () => {
  it.each([
    ["10.0.0.1", false],
    ["172.16.5.5", false],
    ["172.31.255.255", false],
    ["172.32.0.1", true],
    ["192.168.1.1", false],
    ["127.0.0.1", false],
    ["169.254.169.254", false],
    ["100.64.0.1", false],
    ["0.0.0.0", false],
    ["224.0.0.1", false],
    ["8.8.8.8", true],
    ["93.184.216.34", true],
    ["::1", false],
    ["::", false],
    ["fc00::1", false],
    ["fd12:3456::1", false],
    ["fe80::1", false],
    ["::ffff:127.0.0.1", false],
    ["::ffff:8.8.8.8", true],
    ["64:ff9b::a00:1", false],
    ["2001:db8::1", false],
    ["2002:0a00:0001::1", false],
    ["2606:4700:4700::1111", true],
    ["not-an-ip", false],
  ])("%s → public=%s", (ip, expected) => {
    expect(isPublicIp(ip)).toBe(expected);
  });

  it("parse IPv6 avec :: et suffixe v4", () => {
    expect(parseIPv6("::1")).toEqual([0, 0, 0, 0, 0, 0, 0, 1]);
    expect(parseIPv6("[::ffff:1.2.3.4]")).toEqual([0, 0, 0, 0, 0, 0xffff, 0x0102, 0x0304]);
    expect(parseIPv6("1:2:3:4:5:6:7:8:9")).toBeNull();
    expect(parseIPv6("1::2::3")).toBeNull();
  });
});

describe("assertPublicUrl", () => {
  it("accepte une URL publique", async () => {
    expect(await reason("https://example.com/page")).toBe("accepted");
  });

  it("refuse les schémas non http(s) et les identifiants", async () => {
    expect(await reason("file:///etc/passwd")).toBe("scheme");
    expect(await reason("gopher://example.com")).toBe("scheme");
    expect(await reason("https://admin:secret@example.com/")).toBe("credentials");
  });

  it("refuse les ports non standards", async () => {
    expect(await reason("http://example.com:8080/")).toBe("port");
    expect(await reason("http://example.com:22/")).toBe("port");
  });

  it("refuse localhost, les IP privées littérales et le service de métadonnées", async () => {
    expect(await reason("http://localhost/")).toBe("host");
    expect(await reason("http://foo.localhost/")).toBe("host");
    expect(await reason("http://intranet/")).toBe("host");
    expect(await reason("http://metadata.google.internal/")).toBe("host");
    expect(await reason("http://127.0.0.1/")).toBe("private_ip");
    expect(await reason("http://169.254.169.254/latest/meta-data/")).toBe("private_ip");
    expect(await reason("http://[::1]/")).toBe("private_ip");
    expect(await reason("http://10.1.2.3/")).toBe("private_ip");
  });

  it("refuse les IP déguisées (décimal, octal, hexa) que le parseur d'URL normalise", async () => {
    // WHATWG URL réécrit ces formes en dotted-quad : elles tombent sur la plage privée.
    expect(await reason("http://2130706433/")).toBe("private_ip");
    expect(await reason("http://0x7f000001/")).toBe("private_ip");
    expect(await reason("http://0177.0.0.1/")).toBe("private_ip");
  });

  it("refuse un hôte public dont le DNS pointe vers une IP privée (rebinding)", async () => {
    expect(await reason("https://evil.example/", async () => ["93.184.216.34", "10.0.0.5"])).toBe(
      "private_ip",
    );
    expect(await reason("https://evil.example/", async () => ["::ffff:169.254.169.254"])).toBe(
      "private_ip",
    );
    expect(await reason("https://nowhere.example/", async () => [])).toBe("dns");
  });
});

describe("safeFetch — redirections", () => {
  const html = (body: string): Response =>
    new Response(body, { status: 200, headers: { "content-type": "text/html; charset=utf-8" } });

  it("re-vérifie chaque saut et refuse une redirection vers le réseau privé", async () => {
    const calls: string[] = [];
    const fetchFn = (async (input: RequestInfo | URL) => {
      const url = String(input);
      calls.push(url);
      if (url === "https://example.com/start") {
        return new Response(null, {
          status: 302,
          headers: { location: "http://169.254.169.254/" },
        });
      }
      return html("<html><body>never</body></html>");
    }) as typeof fetch;

    await expect(
      safeFetch("https://example.com/start", { fetch: fetchFn, resolve: publicResolver }),
    ).rejects.toMatchObject({
      reason: "unsafe_url",
    });
    expect(calls).toEqual(["https://example.com/start"]);
  });

  it("suit au plus 3 redirections", async () => {
    let n = 0;
    const fetchFn = (async () => {
      n += 1;
      return new Response(null, { status: 301, headers: { location: `https://example.com/${n}` } });
    }) as typeof fetch;
    await expect(
      safeFetch("https://example.com/0", { fetch: fetchFn, resolve: publicResolver }),
    ).rejects.toMatchObject({
      reason: "redirect",
    });
    expect(n).toBe(4);
  });

  it("suit une redirection relative vers une page publique", async () => {
    const fetchFn = (async (input: RequestInfo | URL) => {
      const url = String(input);
      if (url.endsWith("/old"))
        return new Response(null, { status: 302, headers: { location: "/new" } });
      return html("<html><head><title>New</title></head><body>ok</body></html>");
    }) as typeof fetch;
    const res = await safeFetch("https://example.com/old", {
      fetch: fetchFn,
      resolve: publicResolver,
    });
    expect(res.finalUrl).toBe("https://example.com/new");
    expect(res.html).toContain("<title>New</title>");
  });
});
