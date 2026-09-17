import { describe, expect, it } from "vitest";
import { detectSource, domainOf, normalizeUrl, urlHash } from "../src/services/url.js";

describe("normalizeUrl", () => {
  it("retire fragment, tracking et slash final, trie les paramètres", () => {
    expect(
      normalizeUrl("HTTPS://Example.com/Article/?utm_source=x&b=2&a=1&fbclid=abc#section"),
    ).toBe("https://example.com/Article?a=1&b=2");
  });

  it("garde la racine avec son slash et retire le port par défaut", () => {
    expect(normalizeUrl("https://example.com:443/")).toBe("https://example.com/");
    expect(normalizeUrl("http://example.com:80")).toBe("http://example.com/");
    expect(normalizeUrl("https://example.com:8443/x")).toBe("https://example.com:8443/x");
  });

  it("ramène twitter.com et mobile.twitter.com sur x.com, sans ?s= ni ?t=", () => {
    const a = normalizeUrl("https://twitter.com/user/status/123?s=20&t=abc");
    const b = normalizeUrl("https://mobile.twitter.com/user/status/123");
    const c = normalizeUrl("https://x.com/user/status/123?t=zzz");
    expect(a).toBe("https://x.com/user/status/123");
    expect(b).toBe(a);
    expect(c).toBe(a);
  });

  it("ramène youtu.be et m.youtube.com sur www.youtube.com/watch?v=", () => {
    const a = normalizeUrl("https://youtu.be/dQw4w9WgXcQ?si=share123");
    const b = normalizeUrl("https://m.youtube.com/watch?v=dQw4w9WgXcQ&feature=share");
    const c = normalizeUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
    expect(a).toBe("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
    expect(b).toBe(a);
    expect(c).toBe(a);
  });

  it("refuse les schémas non http(s), les identifiants et les chaînes vides", () => {
    expect(normalizeUrl("ftp://example.com/x")).toBeNull();
    expect(normalizeUrl("javascript:alert(1)")).toBeNull();
    expect(normalizeUrl("https://user:pw@example.com/")).toBeNull();
    expect(normalizeUrl("pas une url")).toBeNull();
    expect(normalizeUrl("")).toBeNull();
  });

  it("conserve les paramètres utiles (v, q, id)", () => {
    expect(normalizeUrl("https://example.com/search?q=flutter&page=2")).toBe(
      "https://example.com/search?page=2&q=flutter",
    );
  });
});

describe("urlHash", () => {
  it("est stable et hexadécimal sur 64 caractères", async () => {
    const h1 = await urlHash("https://example.com/a");
    const h2 = await urlHash("https://example.com/a");
    expect(h1).toBe(h2);
    expect(h1).toMatch(/^[0-9a-f]{64}$/);
    expect(await urlHash("https://example.com/b")).not.toBe(h1);
  });
});

describe("detectSource / domainOf", () => {
  it("détecte x, youtube, linkedin, web", () => {
    expect(detectSource("https://x.com/a/status/1")).toBe("x");
    expect(detectSource("https://twitter.com/a")).toBe("x");
    expect(detectSource("https://www.youtube.com/watch?v=1")).toBe("youtube");
    expect(detectSource("https://youtu.be/1")).toBe("youtube");
    expect(detectSource("https://www.linkedin.com/posts/x")).toBe("linkedin");
    expect(detectSource("https://notx.com/")).toBe("web");
    expect(detectSource("https://x.com.evil.io/")).toBe("web");
  });

  it("affiche le domaine sans www.", () => {
    expect(domainOf("https://www.lemonde.fr/article")).toBe("lemonde.fr");
    expect(domainOf("https://x.com/a")).toBe("x.com");
  });
});
