# ADR-009 — Accès aux données : SQL brut, pas d'ORM
**Statut :** accepté · 2026-09-18
**Contexte :** le Database Schema proposait Drizzle ORM (⚠️ à décider) et le registre des dépendances listait `drizzle-orm` + `@neondatabase/serverless` avec l'alternative « SQL brut + postgres.js ». Le schéma de référence est déjà écrit en SQL dans la doc ; les opérations clés — distance cosinus pgvector (`<=>`), `to_tsquery` avec préfixes, `ON CONFLICT … WHERE` pour l'idempotence du webhook — sont du SQL que tout ORM finit par exposer en `sql\`…\``.
**Décision :** SQL brut via le pilote HTTP `@neondatabase/serverless` (`neon(url).query(text, params)`), concentré dans un seul fichier `api/src/db/neon.ts` qui implémente le contrat `Db` (`api/src/db/types.ts`). Migrations = fichiers SQL numérotés dans `api/migrations/`, joués par `scripts/migrate.ts` (Node, transaction par fichier, table `schema_migrations`). Un dépôt en mémoire implémente le même contrat pour les tests.
**Alternatives :** Drizzle — un schéma TypeScript à maintenir en double du SQL de la doc, `drizzle-kit` en plus dans une machine à 3,8 Go, et les requêtes vectorielles/FTS restent en SQL brut de toute façon ; Prisma — client lourd, pgvector mal supporté sur Workers.
**Conséquences :**
- Le contrat `Db` est la frontière testable : les routes ne voient jamais de SQL, les suites M5/M6 tournent sans base (Coding Standards §3 respectés à la lettre : « aucune requête SQL hors de `src/db/` »).
- Le mapping ligne → objet est manuel (`toBookmark`, `toUser`) : lisible, mais à mettre à jour à chaque colonne ajoutée — le typecheck strict le signale.
- Pas de branche Neon de test en CI pour l'instant : `neon.ts` est vérifié par le typecheck et par la première mise en service ; un test d'intégration sur branche éphémère est à ajouter quand le pipeline tourne (Test Strategy, intégration API).
- Réversible : passer à Drizzle plus tard ne change que `neon.ts`.
