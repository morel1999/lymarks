-- Migration 003 — lymarks verrouillés au-delà de la limite Free.
-- Idempotente comme les précédentes (IF NOT EXISTS partout).

-- Le plan Free ne limite plus ce qu'on **stocke**, mais ce à quoi on
-- **accède**. Avant cette migration, la 31ᵉ capture d'un compte Free était
-- refusée par un 403 et le lien etait perdu : l'utilisateur continuait de
-- partager des pages depuis une autre app sans savoir qu'aucune n'arrivait.
--
-- Desormais elle est enregistree, marquee `locked`, et affichee floutee
-- derriere une invitation a passer Pro. Le passage a Pro les deverrouille
-- toutes.
ALTER TABLE bookmarks ADD COLUMN IF NOT EXISTS locked boolean NOT NULL DEFAULT false;

-- Compte des verrouilles (plafond par compte) et filtrage de la liste :
-- toujours scope par utilisateur.
CREATE INDEX IF NOT EXISTS bookmarks_user_locked ON bookmarks (user_id, locked);

-- Un lymark verrouille n'a jamais traverse le pipeline : ni resume, ni
-- mots-cles, ni embedding. On ne paie Groq et Gemini qu'au deverrouillage.
-- Son statut reste donc `processing` cote base ; l'app l'affiche floute a
-- partir de `locked`, sans attendre de resume.
