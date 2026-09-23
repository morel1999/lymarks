/**
 * Travail qui survit a la reponse HTTP.
 *
 * Sur Workers, une promesse non attendue meurt avec l'invocation : le
 * pipeline d'ingestion doit passer par `waitUntil`. Hors Workers (tests),
 * il n'y a pas de contexte et la promesse tourne seule.
 *
 * Partage entre la capture et le webhook RevenueCat, qui relance le pipeline
 * sur les lymarks deverrouilles.
 */
export function background(
  promise: Promise<unknown>,
  ctx: () => { waitUntil(p: Promise<unknown>): void },
): void {
  const safe = promise.catch((err: unknown) => {
    console.error(JSON.stringify({ event: "pipeline_crashed", message: (err as Error)?.message }));
  });
  try {
    ctx().waitUntil(safe);
  } catch {
    // Hors Workers (tests sans contexte) : la promesse tourne seule.
  }
}
