// Authentification Clerk (ADR-002, Security §1) : JWT vérifié à chaque requête
// via le JWKS de l'instance, `sub` = identifiant Clerk. L'utilisateur Neon est
// créé à la première requête authentifiée. Le `user_id` ne vient JAMAIS du
// corps : uniquement d'ici.

import type { Context, MiddlewareHandler } from "hono";
import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from "jose";
import type { Db } from "../db/types.js";
import { unauthorized } from "./errors.js";

export interface AuthUser {
  id: string;
  clerkId: string;
}

export type TokenVerifier = (token: string) => Promise<{ clerkId: string }>;

export type AuthVariables = { user: AuthUser };

/**
 * Le « frontend API » de l'instance Clerk est encodé dans la publishable key :
 * pk_test_<base64(host)$>. C'est l'émetteur (`iss`) des JWT et l'hôte du JWKS.
 */
export function clerkFrontendApi(publishableKey: string): string {
  const m = /^pk_(test|live)_([A-Za-z0-9+/=]+)$/.exec(publishableKey.trim());
  if (!m) throw new Error("CLERK_PUBLISHABLE_KEY invalide");
  const decoded = atob(m[2]!).replace(/\$$/, "");
  if (!/^[a-z0-9.-]+$/i.test(decoded)) throw new Error("CLERK_PUBLISHABLE_KEY invalide");
  return decoded;
}

export interface ClerkVerifierOptions {
  publishableKey: string;
  /** Surcharge pour les tests (jeu de clés local). */
  getKey?: JWTVerifyGetKey;
  now?: () => Date;
}

export function createClerkVerifier(opts: ClerkVerifierOptions): TokenVerifier {
  const host = clerkFrontendApi(opts.publishableKey);
  const issuer = `https://${host}`;
  const getKey =
    opts.getKey ??
    createRemoteJWKSet(new URL(`${issuer}/.well-known/jwks.json`), {
      cacheMaxAge: 10 * 60 * 1000,
      cooldownDuration: 30 * 1000,
    });

  return async (token) => {
    try {
      const { payload } = await jwtVerify(token, getKey, {
        issuer,
        algorithms: ["RS256"],
        clockTolerance: 5,
        ...(opts.now ? { currentDate: opts.now() } : {}),
      });
      if (typeof payload.sub !== "string" || !payload.sub) throw new Error("sub manquant");
      return { clerkId: payload.sub };
    } catch {
      throw unauthorized("Jeton invalide ou expiré");
    }
  };
}

function bearer(c: Context): string {
  const header = c.req.header("authorization") ?? "";
  const m = /^Bearer\s+(.+)$/i.exec(header);
  if (!m) throw unauthorized();
  return m[1]!.trim();
}

/** Middleware : vérifie le jeton, charge (ou crée) l'utilisateur, l'expose dans `c.var.user`. */
export function requireAuth(
  verify: TokenVerifier,
  db: Db,
): MiddlewareHandler<{ Variables: AuthVariables }> {
  return async (c, next) => {
    const { clerkId } = await verify(bearer(c));
    const user = (await db.users.findByClerkId(clerkId)) ?? (await db.users.create(clerkId));
    c.set("user", { id: user.id, clerkId: user.clerkId });
    await next();
  };
}
