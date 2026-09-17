// Dépendances injectées dans l'application. `src/index.ts` les construit
// depuis l'environnement Workers ; les tests les remplacent par des doubles.

import type { Db } from "./db/types.js";
import type { TokenVerifier } from "./middleware/auth.js";
import type { PipelineJob } from "./services/pipeline.js";

export interface AppDeps {
  db: Db;
  verifyToken: TokenVerifier;
  /** Lance le pipeline d'ingestion (hors requête, via waitUntil). */
  runPipeline: (job: PipelineJob) => Promise<unknown>;
  /** Vectorise une requête de recherche (Pro). */
  embedQuery: (query: string) => Promise<number[]>;
  /** Valeur attendue dans l'en-tête Authorization du webhook RevenueCat ; null = webhook désactivé. */
  revenuecatWebhookSecret: string | null;
  /** Suppression du compte chez Clerk ; null en test. */
  deleteClerkUser: ((clerkId: string) => Promise<void>) | null;
  /** Suppression de l'abonné RevenueCat (best-effort) ; null si non configuré. */
  deleteRevenuecatSubscriber: ((appUserId: string) => Promise<void>) | null;
  now: () => Date;
  version: string;
  log: (event: Record<string, unknown>) => void;
}
