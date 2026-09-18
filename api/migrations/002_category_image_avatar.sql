-- Migration 002 — catégorie et image d'aperçu des lymarks, avatar utilisateur.
-- Idempotente comme 001 (IF NOT EXISTS partout), jouée par `npm run migrate`.

-- Taxonomie fermée (src/services/categories.ts), choisie par le résumeur ;
-- 'other' par défaut pour que les lignes existantes restent valides sans rejeu.
ALTER TABLE bookmarks ADD COLUMN IF NOT EXISTS category text NOT NULL DEFAULT 'other';
-- Filtre « par catégorie » de la Home : toujours scopé par utilisateur.
CREATE INDEX IF NOT EXISTS bookmarks_user_category ON bookmarks (user_id, category);

-- og:image (ou twitter:image) résolue en URL absolue https ; jamais l'image
-- elle-même, seulement son adresse.
ALTER TABLE bookmarks ADD COLUMN IF NOT EXISTS image_url text;

-- Un emoji (séquences comprises), ou null : aucun fichier stocké.
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar text;
