// Joue les migrations SQL de `migrations/` dans l'ordre, une seule fois chacune.
//
//   npm run migrate                # lit DATABASE_URL depuis l'env, sinon .dev.vars
//   DATABASE_URL=... npm run migrate
//
// Tourne sous Node (tsx), jamais dans le Worker. Chaque fichier est joué dans
// une transaction avec son enregistrement dans schema_migrations : soit tout
// passe, soit rien (Database Schema § Règles).

import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { Client } from "@neondatabase/serverless";

const here = dirname(fileURLToPath(import.meta.url));
const apiRoot = join(here, "..");
const migrationsDir = join(apiRoot, "migrations");

function readDevVar(name: string): string | undefined {
  const file = join(apiRoot, ".dev.vars");
  if (!existsSync(file)) return undefined;
  for (const raw of readFileSync(file, "utf8").split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const eq = line.indexOf("=");
    if (eq < 0) continue;
    if (line.slice(0, eq).trim() === name) {
      const value = line.slice(eq + 1).trim();
      return value.replace(/^["']|["']$/g, "");
    }
  }
  return undefined;
}

async function main(): Promise<void> {
  const url = (process.env["DATABASE_URL"] ?? readDevVar("DATABASE_URL") ?? "").trim();
  if (!url.startsWith("postgres")) {
    console.error(
      `DATABASE_URL manquante ou invalide (env ou api/.dev.vars) : ${url.length} caractère(s), préfixe « ${url.slice(0, 8)} ».`,
    );
    process.exit(2);
  }

  const files = readdirSync(migrationsDir)
    .filter((f) => /^\d{3}_.+\.sql$/.test(f))
    .sort();

  const client = new Client({ connectionString: url });
  await client.connect();
  try {
    await client.query(
      `CREATE TABLE IF NOT EXISTS schema_migrations (
         name text PRIMARY KEY,
         applied_at timestamptz NOT NULL DEFAULT now()
       )`,
    );
    const { rows } = await client.query<{ name: string }>("SELECT name FROM schema_migrations");
    const applied = new Set(rows.map((r) => r.name));

    let count = 0;
    for (const file of files) {
      if (applied.has(file)) {
        console.error(`= ${file} (déjà appliquée)`);
        continue;
      }
      const sql = readFileSync(join(migrationsDir, file), "utf8");
      await client.query("BEGIN");
      try {
        await client.query(sql);
        await client.query("INSERT INTO schema_migrations (name) VALUES ($1)", [file]);
        await client.query("COMMIT");
      } catch (err) {
        await client.query("ROLLBACK");
        throw new Error(`Migration ${file} annulée : ${(err as Error).message}`);
      }
      console.error(`+ ${file}`);
      count += 1;
    }
    console.error(count === 0 ? "Schéma à jour." : `${count} migration(s) appliquée(s).`);
  } finally {
    await client.end();
  }
}

main().catch((err: unknown) => {
  console.error((err as Error).message);
  process.exit(1);
});
