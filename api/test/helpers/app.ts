// Fabrique une application de test : dépôt en mémoire, jetons factices
// (« tok:<clerkId> »), pipeline capturé au lieu d'être exécuté.

import { createApp } from "../../src/app.js";
import type { AppDeps } from "../../src/deps.js";
import { unauthorized } from "../../src/middleware/errors.js";
import type { PipelineJob } from "../../src/services/pipeline.js";
import { MemoryDb } from "./memory-db.js";

export const FIXED_NOW = new Date("2026-09-18T10:00:00Z");

export interface TestHarness {
  app: ReturnType<typeof createApp>;
  db: MemoryDb;
  deps: AppDeps;
  jobs: PipelineJob[];
  logs: Array<Record<string, unknown>>;
  /** Requête authentifiée en tant que `clerkId`. */
  as: (clerkId: string) => (path: string, init?: RequestInit) => Promise<Response>;
  request: (path: string, init?: RequestInit) => Promise<Response>;
  waited: Promise<unknown>[];
}

export function harness(overrides: Partial<AppDeps> = {}): TestHarness {
  const db = new MemoryDb();
  db.now = () => FIXED_NOW;
  const jobs: PipelineJob[] = [];
  const logs: Array<Record<string, unknown>> = [];
  const waited: Promise<unknown>[] = [];

  const deps: AppDeps = {
    db,
    verifyToken: async (token) => {
      if (!token.startsWith("tok:")) throw unauthorized();
      return { clerkId: token.slice(4) };
    },
    runPipeline: async (job) => {
      jobs.push(job);
    },
    embedQuery: async (q) => fakeEmbedding(q),
    revenuecatWebhookSecret: "whsec_test",
    deleteClerkUser: null,
    deleteRevenuecatSubscriber: null,
    now: () => FIXED_NOW,
    version: "test",
    log: (e) => {
      logs.push(e);
    },
    ...overrides,
  };
  const app = createApp(deps);
  const ctx = {
    waitUntil: (p: Promise<unknown>) => {
      waited.push(p);
    },
    passThroughOnException: () => undefined,
    props: {},
  } as unknown as ExecutionContext;

  const request = async (path: string, init?: RequestInit): Promise<Response> =>
    app.request(path, init, {}, ctx);
  const as =
    (clerkId: string) =>
    (path: string, init: RequestInit = {}) => {
      const headers = new Headers(init.headers);
      headers.set("authorization", `Bearer tok:${clerkId}`);
      if (init.body && !headers.has("content-type"))
        headers.set("content-type", "application/json");
      return request(path, { ...init, headers });
    };
  return { app, db, deps, jobs, logs, as, request, waited };
}

export const json = (body: unknown): RequestInit => ({
  method: "POST",
  body: JSON.stringify(body),
});

/** Embedding déterministe : chaque mot pousse une dimension. Suffit pour ordonner des cosinus. */
export function fakeEmbedding(text: string, dims = 768): number[] {
  const v = new Array<number>(dims).fill(0);
  for (const word of text.toLowerCase().split(/\W+/).filter(Boolean)) {
    let h = 0;
    for (const ch of word) h = (h * 31 + ch.charCodeAt(0)) % dims;
    v[h] = (v[h] ?? 0) + 1;
  }
  return v;
}
