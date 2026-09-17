// Routes : contrat HTTP, et les suites sécurité M5 (bypass paywall) et M6
// (IDOR) exigées par la Test Strategy.

import { describe, expect, it } from "vitest";
import { FREE_ACTIVE_LIMIT } from "../src/services/plan.js";
import { fakeEmbedding, harness, json } from "./helpers/app.js";

/** Recule la création des lymarks existants de 2 h : sort du quota horaire sans toucher au plan. */
function backdate(h: ReturnType<typeof harness>) {
  for (const b of h.db.bookmarks_.values())
    b.createdAt = new Date(b.createdAt.getTime() - 2 * 60 * 60 * 1000);
}

async function create(
  h: ReturnType<typeof harness>,
  clerkId: string,
  url: string,
  extra: Record<string, unknown> = {},
) {
  const res = await h.as(clerkId)("/bookmarks", json({ url, ...extra }));
  const body = (await res.json()) as { bookmark: { id: string } };
  return { res, id: body.bookmark.id, body };
}

describe("santé et auth", () => {
  it("GET /health répond sans jeton", async () => {
    const h = harness();
    const res = await h.request("/health");
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ ok: true, version: "test", db: "ok" });
    expect(res.headers.get("strict-transport-security")).toContain("max-age");
  });

  it("toute route métier exige un jeton valide", async () => {
    const h = harness();
    for (const path of ["/bookmarks", "/search?q=x", "/me"]) {
      expect((await h.request(path)).status).toBe(401);
      expect((await h.request(path, { headers: { authorization: "Bearer bad" } })).status).toBe(
        401,
      );
    }
  });

  it("crée l'utilisateur Neon à la première requête", async () => {
    const h = harness();
    const res = await h.as("clerk_1")("/me");
    expect(res.status).toBe(200);
    const { me } = (await res.json()) as {
      me: { plan: string; lymarkCount: number; lymarkLimit: number };
    };
    expect(me).toMatchObject({ plan: "free", lymarkCount: 0, lymarkLimit: FREE_ACTIVE_LIMIT });
    expect(h.db.users_.size).toBe(1);
    await h.as("clerk_1")("/me");
    expect(h.db.users_.size).toBe(1);
  });
});

describe("POST /bookmarks", () => {
  it("201 en processing, URL normalisée, pipeline lancé via waitUntil", async () => {
    const h = harness();
    const { res, body } = await create(h, "u1", "https://Example.com/post/?utm_source=x", {
      note: "à lire",
      title: "Un post",
    });
    expect(res.status).toBe(201);
    expect(body).toMatchObject({
      duplicate: false,
      bookmark: {
        url: "https://example.com/post",
        domain: "example.com",
        status: "processing",
        note: "à lire",
        title: "Un post",
        source: "web",
        bullets: [],
        savedCount: 1,
      },
    });
    expect(h.jobs).toHaveLength(1);
    expect(h.jobs[0]).toMatchObject({ url: "https://example.com/post", title: "Un post" });
    expect(h.waited).toHaveLength(1);
  });

  it("400 sur URL invalide ou corps vide", async () => {
    const h = harness();
    expect((await h.as("u1")("/bookmarks", json({ url: "javascript:alert(1)" }))).status).toBe(400);
    expect((await h.as("u1")("/bookmarks", json({}))).status).toBe(400);
    expect((await h.as("u1")("/bookmarks", { method: "POST", body: "{oops" })).status).toBe(400);
  });

  it("doublon : 200, saved_count + 1, note remplacée, pas de second pipeline", async () => {
    const h = harness();
    await create(h, "u1", "https://youtu.be/abc?si=1", { note: "v1" });
    const { res, body } = await create(h, "u1", "https://www.youtube.com/watch?v=abc", {
      note: "v2",
    });
    expect(res.status).toBe(200);
    expect(body).toMatchObject({
      duplicate: true,
      bookmark: { savedCount: 2, note: "v2", source: "youtube" },
    });
    expect(h.jobs).toHaveLength(1);
    expect(h.db.bookmarks_.size).toBe(1);
  });

  it("M5 : la limite Free est appliquée côté serveur, 403 limit_reached au 31ᵉ", async () => {
    const h = harness();
    for (let i = 0; i < FREE_ACTIVE_LIMIT; i += 1) {
      expect((await create(h, "free", `https://example.com/${i}`)).res.status).toBe(201);
    }
    backdate(h);
    const blocked = await h.as("free")("/bookmarks", json({ url: "https://example.com/31" }));
    expect(blocked.status).toBe(403);
    expect(await blocked.json()).toMatchObject({
      error: "limit_reached",
      details: { limit: 30, count: 30 },
    });
    // Archiver libère une place.
    const first = [...h.db.bookmarks_.values()][0]!;
    await h.as("free")(`/bookmarks/${first.id}`, {
      method: "PATCH",
      body: JSON.stringify({ archived: true }),
    });
    expect((await create(h, "free", "https://example.com/31")).res.status).toBe(201);
  });

  it("M5 : un doublon ne consomme pas de place et reste accepté à la limite", async () => {
    const h = harness();
    for (let i = 0; i < FREE_ACTIVE_LIMIT; i += 1)
      await create(h, "free", `https://example.com/${i}`);
    const dup = await create(h, "free", "https://example.com/0");
    expect(dup.res.status).toBe(200);
  });

  it("Pro : pas de limite", async () => {
    const h = harness();
    const user = await h.db.users.create("pro");
    h.db.subscriptions_.set(user.id, {
      userId: user.id,
      rcAppUserId: "pro",
      entitlement: "pro",
      expiresAt: null,
      lastEventId: "e",
      lastEventAt: new Date(0),
    });
    for (let i = 0; i < FREE_ACTIVE_LIMIT; i += 1) {
      expect((await create(h, "pro", `https://example.com/${i}`)).res.status).toBe(201);
    }
    backdate(h);
    expect((await create(h, "pro", "https://example.com/31")).res.status).toBe(201);
  });

  it("M4 : 429 au-delà de 30 captures dans l'heure (règle serveur, pas de compteur client)", async () => {
    const h = harness();
    const user = await h.db.users.create("pro");
    h.db.subscriptions_.set(user.id, {
      userId: user.id,
      rcAppUserId: "pro",
      entitlement: "pro",
      expiresAt: null,
      lastEventId: "e",
      lastEventAt: new Date(0),
    });
    for (let i = 0; i < 30; i += 1) await create(h, "pro", `https://example.com/${i}`);
    const res = await h.as("pro")("/bookmarks", json({ url: "https://example.com/again" }));
    expect(res.status).toBe(429);
  });
});

describe("lecture, modification, suppression", () => {
  it("liste antéchronologique avec curseur", async () => {
    const h = harness();
    for (let i = 0; i < 3; i += 1) await create(h, "u1", `https://example.com/${i}`);
    const res = await h.as("u1")("/bookmarks?limit=2");
    const page = (await res.json()) as { items: Array<{ url: string }>; nextCursor: string | null };
    expect(page.items.map((b) => b.url)).toEqual([
      "https://example.com/2",
      "https://example.com/1",
    ]);
    expect(page.nextCursor).not.toBeNull();
    const next = (await (
      await h.as("u1")(`/bookmarks?limit=2&before=${encodeURIComponent(page.nextCursor!)}`)
    ).json()) as {
      items: Array<{ url: string }>;
      nextCursor: string | null;
    };
    expect(next.items.map((b) => b.url)).toEqual(["https://example.com/0"]);
    expect(next.nextCursor).toBeNull();
  });

  it("PATCH note/archived, POST opened, DELETE", async () => {
    const h = harness();
    const { id } = await create(h, "u1", "https://example.com/a");
    const patched = await h.as("u1")(`/bookmarks/${id}`, {
      method: "PATCH",
      body: JSON.stringify({ note: "nouvelle" }),
    });
    expect(((await patched.json()) as { bookmark: { note: string } }).bookmark.note).toBe(
      "nouvelle",
    );
    const cleared = await h.as("u1")(`/bookmarks/${id}`, {
      method: "PATCH",
      body: JSON.stringify({ note: null }),
    });
    expect(((await cleared.json()) as { bookmark: { note: null } }).bookmark.note).toBeNull();
    expect(
      (await h.as("u1")(`/bookmarks/${id}`, { method: "PATCH", body: JSON.stringify({}) })).status,
    ).toBe(400);
    expect((await h.as("u1")(`/bookmarks/${id}/opened`, { method: "POST" })).status).toBe(204);
    expect(h.db.bookmarks_.get(id)?.lastOpenedAt).not.toBeNull();
    expect((await h.as("u1")(`/bookmarks/${id}`, { method: "DELETE" })).status).toBe(204);
    expect((await h.as("u1")(`/bookmarks/${id}`)).status).toBe(404);
  });

  it("retry : 202 seulement depuis failed/partial, relance le pipeline", async () => {
    const h = harness();
    const { id } = await create(h, "u1", "https://example.com/a");
    expect((await h.as("u1")(`/bookmarks/${id}/retry`, { method: "POST" })).status).toBe(409);
    await h.db.bookmarks.setResult(id, {
      status: "failed",
      title: null,
      summary: null,
      keywords: [],
      embedding: null,
      failureReason: "timeout",
    });
    const res = await h.as("u1")(`/bookmarks/${id}/retry`, { method: "POST" });
    expect(res.status).toBe(202);
    expect(((await res.json()) as { bookmark: { status: string } }).bookmark.status).toBe(
      "processing",
    );
    expect(h.jobs).toHaveLength(2);
  });

  it("M6 : un utilisateur ne voit, ne modifie, ne supprime ni ne relance les lymarks d'un autre", async () => {
    const h = harness();
    const { id } = await create(h, "alice", "https://example.com/private");
    const bob = h.as("bob");
    expect((await bob(`/bookmarks/${id}`)).status).toBe(404);
    expect(
      (await bob(`/bookmarks/${id}`, { method: "PATCH", body: JSON.stringify({ note: "pwn" }) }))
        .status,
    ).toBe(404);
    expect((await bob(`/bookmarks/${id}`, { method: "DELETE" })).status).toBe(404);
    expect((await bob(`/bookmarks/${id}/opened`, { method: "POST" })).status).toBe(404);
    expect((await bob(`/bookmarks/${id}/retry`, { method: "POST" })).status).toBe(404);
    expect((await bob(`/bookmarks/${id}/similar`)).status).toBe(404);
    const list = (await (await bob("/bookmarks")).json()) as { items: unknown[] };
    expect(list.items).toHaveLength(0);
    expect(h.db.bookmarks_.get(id)?.note).toBeNull();
    expect((await bob("/bookmarks/not-a-uuid")).status).toBe(400);
  });
});

describe("GET /search", () => {
  async function seeded() {
    const h = harness();
    const { id: a } = await create(h, "u1", "https://example.com/flutter", {
      note: "pour mon app",
    });
    await h.db.bookmarks.setResult(a, {
      status: "ready",
      title: "Flutter state management",
      summary: { bullets: ["Riverpod expliqué"], lang: "en" },
      keywords: ["flutter", "riverpod"],
      embedding: fakeEmbedding("flutter riverpod state"),
      failureReason: null,
    });
    const { id: b } = await create(h, "u1", "https://example.com/pasta");
    await h.db.bookmarks.setResult(b, {
      status: "ready",
      title: "Recette de pâtes",
      summary: { bullets: ["Carbonara sans crème"], lang: "fr" },
      keywords: ["cuisine"],
      embedding: fakeEmbedding("recette pâtes carbonara"),
      failureReason: null,
    });
    await create(h, "other", "https://example.com/flutter-other", {
      title: "Flutter chez un autre",
    });
    return { h, a, b };
  }

  it("plein texte : titre, note, puces et mots-clés, scopé par utilisateur", async () => {
    const { h, a } = await seeded();
    const res = await h.as("u1")("/search?q=flutter");
    const body = (await res.json()) as { items: Array<{ bookmark: { id: string } }>; mode: string };
    expect(body.mode).toBe("text");
    expect(body.items.map((i) => i.bookmark.id)).toEqual([a]);
    const byNote = (await (await h.as("u1")("/search?q=app")).json()) as {
      items: Array<{ bookmark: { id: string } }>;
    };
    expect(byNote.items.map((i) => i.bookmark.id)).toEqual([a]);
  });

  it("M5 : sémantique refusée en Free (403 pro_required), servie en Pro", async () => {
    const { h, a } = await seeded();
    const free = await h.as("u1")("/search?q=gestion%20etat&mode=semantic");
    expect(free.status).toBe(403);
    expect(await free.json()).toMatchObject({ error: "pro_required" });

    const user = (await h.db.users.findByClerkId("u1"))!;
    h.db.subscriptions_.set(user.id, {
      userId: user.id,
      rcAppUserId: "u1",
      entitlement: "pro",
      expiresAt: null,
      lastEventId: "e",
      lastEventAt: new Date(0),
    });
    const pro = await h.as("u1")("/search?q=riverpod%20state&mode=semantic");
    expect(pro.status).toBe(200);
    const body = (await pro.json()) as {
      items: Array<{ bookmark: { id: string }; score: number }>;
      mode: string;
    };
    expect(body.mode).toBe("semantic");
    expect(body.items[0]!.bookmark.id).toBe(a);
    expect(body.items[0]!.score).toBeGreaterThan(body.items[1]!.score);
  });

  it("400 sans requête", async () => {
    const h = harness();
    expect((await h.as("u1")("/search")).status).toBe(400);
    expect((await h.as("u1")("/search?q=%20")).status).toBe(400);
  });
});

describe("/me", () => {
  it("PATCH réglages ; le digest exige Pro", async () => {
    const h = harness();
    const ok = await h.as("u1")("/me", {
      method: "PATCH",
      body: JSON.stringify({ tz: "Europe/Paris", digestHour: 9 }),
    });
    expect(ok.status).toBe(200);
    expect(((await ok.json()) as { me: { tz: string; digestHour: number } }).me).toMatchObject({
      tz: "Europe/Paris",
      digestHour: 9,
    });
    const digest = await h.as("u1")("/me", {
      method: "PATCH",
      body: JSON.stringify({ digestOptin: true }),
    });
    expect(digest.status).toBe(403);
    expect(
      (await h.as("u1")("/me", { method: "PATCH", body: JSON.stringify({ tz: "../etc" }) })).status,
    ).toBe(400);
  });

  it("export JSON : url, note, résumé, tags, dates", async () => {
    const h = harness();
    const { id } = await create(h, "u1", "https://example.com/a", { note: "n" });
    await h.db.bookmarks.setResult(id, {
      status: "ready",
      title: "T",
      summary: { bullets: ["b"], lang: "fr" },
      keywords: ["k"],
      embedding: null,
      failureReason: null,
    });
    const body = (await (await h.as("u1")("/me/export")).json()) as { lymarks: unknown[] };
    expect(body.lymarks).toEqual([
      expect.objectContaining({
        url: "https://example.com/a",
        note: "n",
        title: "T",
        bullets: ["b"],
        keywords: ["k"],
        archived: false,
      }),
    ]);
  });

  it("DELETE purge Neon puis Clerk ; 502 si Clerk échoue après la purge", async () => {
    const deleted: string[] = [];
    const h = harness({ deleteClerkUser: async (id) => void deleted.push(id) });
    await create(h, "u1", "https://example.com/a");
    expect((await h.as("u1")("/me", { method: "DELETE" })).status).toBe(204);
    expect(deleted).toEqual(["u1"]);
    expect(h.db.bookmarks_.size).toBe(0);
    expect(h.db.users_.size).toBe(0);

    const broken = harness({
      deleteClerkUser: async () => {
        throw new Error("clerk down");
      },
    });
    await create(broken, "u2", "https://example.com/a");
    expect((await broken.as("u2")("/me", { method: "DELETE" })).status).toBe(502);
    expect(broken.db.bookmarks_.size).toBe(0);
  });
});

describe("POST /webhooks/revenuecat", () => {
  const event = (over: Record<string, unknown> = {}) => ({
    api_version: "1.0",
    event: {
      id: "evt_1",
      type: "INITIAL_PURCHASE",
      app_user_id: "u1",
      entitlement_ids: ["pro"],
      expiration_at_ms: Date.UTC(2027, 0, 1),
      event_timestamp_ms: Date.UTC(2026, 8, 18, 9),
      ...over,
    },
  });
  const send = (h: ReturnType<typeof harness>, body: unknown, auth = "whsec_test") =>
    h.request("/webhooks/revenuecat", {
      method: "POST",
      body: JSON.stringify(body),
      headers: { authorization: auth, "content-type": "application/json" },
    });

  it("M7 : refuse sans le bon en-tête, ou si le webhook n'est pas configuré", async () => {
    const h = harness();
    expect((await send(h, event(), "wrong")).status).toBe(401);
    expect((await send(h, event(), "")).status).toBe(401);
    const off = harness({ revenuecatWebhookSecret: null });
    expect((await send(off, event())).status).toBe(503);
  });

  it("passe l'utilisateur en Pro, idempotent, et ignore un événement plus ancien", async () => {
    const h = harness();
    await h.as("u1")("/me");
    const first = await send(h, event());
    expect(first.status).toBe(200);
    expect(await first.json()).toEqual({ ok: true, outcome: "applied" });
    const user = (await h.db.users.findByClerkId("u1"))!;
    expect(await h.db.subscriptions.getPlan(user.id)).toBe("pro");

    expect(await (await send(h, event())).json()).toEqual({ ok: true, outcome: "ignored" });

    const stale = event({
      id: "evt_0",
      type: "EXPIRATION",
      event_timestamp_ms: Date.UTC(2026, 8, 18, 8),
    });
    expect(await (await send(h, stale)).json()).toEqual({ ok: true, outcome: "ignored" });
    expect(await h.db.subscriptions.getPlan(user.id)).toBe("pro");

    const expired = event({
      id: "evt_2",
      type: "EXPIRATION",
      event_timestamp_ms: Date.UTC(2026, 8, 18, 10),
    });
    expect(await (await send(h, expired)).json()).toEqual({ ok: true, outcome: "applied" });
    expect(await h.db.subscriptions.getPlan(user.id)).toBe("free");
  });

  it("utilisateur inconnu → 200 unknown_user ; TEST ignoré ; corps invalide → 400", async () => {
    const h = harness();
    expect(await (await send(h, event({ app_user_id: "ghost" }))).json()).toEqual({
      ok: true,
      outcome: "unknown_user",
    });
    expect(await (await send(h, event({ type: "TEST" }))).json()).toEqual({
      ok: true,
      ignored: "test",
    });
    expect((await send(h, { event: { nope: true } })).status).toBe(400);
  });
});
