// Vérification réelle de JWT (jose) avec un jeu de clés local : signature,
// émetteur, expiration.

import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "jose";
import { beforeAll, describe, expect, it } from "vitest";
import { clerkFrontendApi, createClerkVerifier } from "../src/middleware/auth.js";

const HOST = "clerk.lymarks.test";
const PK = `pk_test_${btoa(`${HOST}$`)}`;

describe("clerkFrontendApi", () => {
  it("décode l'hôte du frontend API depuis la publishable key", () => {
    expect(clerkFrontendApi(PK)).toBe(HOST);
    expect(clerkFrontendApi("pk_live_Y2xlcmsuZXhhbXBsZS5jb20k")).toBe("clerk.example.com");
    expect(() => clerkFrontendApi("sk_test_nope")).toThrow();
    expect(() => clerkFrontendApi("pk_test_!!!")).toThrow();
  });
});

describe("createClerkVerifier", () => {
  let privateKey: CryptoKey;
  let getKey: ReturnType<typeof createLocalJWKSet>;
  let otherKey: CryptoKey;

  beforeAll(async () => {
    const pair = await generateKeyPair("RS256", { modulusLength: 2048 });
    privateKey = pair.privateKey as CryptoKey;
    const other = await generateKeyPair("RS256", { modulusLength: 2048 });
    otherKey = other.privateKey as CryptoKey;
    getKey = createLocalJWKSet({
      keys: [{ ...(await exportJWK(pair.publicKey)), kid: "k1", alg: "RS256", use: "sig" }],
    });
  });

  const sign = (key: CryptoKey, claims: Record<string, unknown> = {}, issuer = `https://${HOST}`) =>
    new SignJWT({ ...claims })
      .setProtectedHeader({ alg: "RS256", kid: "k1" })
      .setIssuer(issuer)
      .setSubject((claims["sub"] as string | undefined) ?? "user_123")
      .setIssuedAt()
      .setExpirationTime("2m")
      .sign(key);

  it("accepte un jeton signé par l'instance et renvoie le sub", async () => {
    const verify = createClerkVerifier({ publishableKey: PK, getKey });
    expect(await verify(await sign(privateKey))).toEqual({ clerkId: "user_123" });
  });

  it("refuse mauvaise signature, mauvais émetteur, jeton expiré, jeton malformé", async () => {
    const verify = createClerkVerifier({ publishableKey: PK, getKey });
    await expect(verify(await sign(otherKey))).rejects.toMatchObject({ status: 401 });
    await expect(verify(await sign(privateKey, {}, "https://evil.test"))).rejects.toMatchObject({
      status: 401,
    });
    const later = createClerkVerifier({
      publishableKey: PK,
      getKey,
      now: () => new Date(Date.now() + 10 * 60 * 1000),
    });
    await expect(later(await sign(privateKey))).rejects.toMatchObject({ status: 401 });
    await expect(verify("not.a.jwt")).rejects.toMatchObject({ status: 401 });
  });
});
