// Erreurs HTTP typées et leur sérialisation uniforme : { error, message }.
// Les corps de requête ne sont jamais journalisés (Privacy §4).

import type { Context } from "hono";
import { ZodError, type ZodType } from "zod";

export class HttpError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message?: string,
    public readonly details?: unknown,
  ) {
    super(message ?? code);
    this.name = "HttpError";
  }
}

export const unauthorized = (message = "Authentification requise"): HttpError =>
  new HttpError(401, "unauthorized", message);
export const notFound = (message = "Introuvable"): HttpError =>
  new HttpError(404, "not_found", message);

export function errorResponse(err: unknown, c: Context): Response {
  if (err instanceof HttpError) {
    return c.json(
      { error: err.code, message: err.message, ...(err.details ? { details: err.details } : {}) },
      err.status as 400,
    );
  }
  if (err instanceof ZodError) {
    return c.json(
      { error: "invalid_request", message: "Requête invalide", details: err.issues },
      400,
    );
  }
  console.error(
    JSON.stringify({
      event: "unhandled_error",
      message: (err as Error)?.message,
      stack: (err as Error)?.stack,
    }),
  );
  return c.json({ error: "internal_error", message: "Erreur interne" }, 500);
}

/** Corps JSON validé par Zod ; 400 sinon. Un corps vide vaut `{}`. */
export async function parseBody<T>(c: Context, schema: ZodType<T>): Promise<T> {
  let raw: unknown = {};
  const text = await c.req.text();
  if (text.trim()) {
    try {
      raw = JSON.parse(text);
    } catch {
      throw new HttpError(400, "invalid_json", "Corps JSON invalide");
    }
  }
  return schema.parse(raw);
}

export function parseQuery<T>(c: Context, schema: ZodType<T>): T {
  return schema.parse(c.req.query());
}
