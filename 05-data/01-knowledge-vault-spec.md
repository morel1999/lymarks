# Knowledge Vault Specification — Lymarks

> **But :** la mémoire de connaissances : structure, indexation, re-surfaçage. · **Statut :** vivant · **Màj :** 2026-08-07

## 1. Unité de connaissance : le lymark
```
lymark = {
  url, url_hash, source,           // source ∈ {x, youtube, linkedin, web}
  title, note_utilisateur,
  summary: [puce1, puce2, puce3],  // générées, langue du contenu
  keywords: [..],                  // 3–6, générés
  embedding: vector(768),          // sur titre + puces
  status, saved_count,
  created_at, last_opened_at, last_surfaced_at
}
```
La **note utilisateur** est l'intention (« pour mon projet du week-end ») : elle pèse dans la recherche plein texte mais n'est jamais envoyée aux LLM (Privacy §2).

## 2. Tags
V1.0 : `keywords` générés = tags de fait (affichés en chips, cliquables → recherche). Tags manuels éditables : V1.2. Pas de dossiers, jamais (philosophie : le rangement est le travail de la machine).

## 3. Relations et graphe
V1.0 : relations implicites uniquement — « lymarks similaires » = top-3 par cosinus (>0,75) affichés sur la fiche. Graphe explicite : hors périmètre (⚠️ réévaluer en V2 si usage réel).

## 4. Re-surfaçage (algorithme du Daily Digest)
Candidats : lymarks `ready`, non ouverts depuis ≥7 jours, non surfacés depuis ≥14 jours, non archivés.
```
score = 0,5 × pertinence + 0,3 × oubli + 0,2 × fraîcheur_intérêt
  pertinence      = cos(embedding, centroïde des 10 derniers lymarks sauvés)
  oubli           = min(jours_depuis_sauvegarde / 30, 1)      // inspiré révision espacée
  fraîcheur_intérêt = 1 si keywords ∩ keywords récents ≠ ∅, sinon 0,3
```
Sélection = meilleur score ; égalité → le plus ancien. « Reporter » → exclu 7 jours. « Archiver » → exclu définitivement. Coefficients ⚠️ à calibrer après 2 semaines de données réelles.

## 5. Recherche et indexation
- Plein texte : Postgres `tsvector` sur (title, note, puces, keywords), config `simple` (multilingue FR/EN ⚠️ à valider).
- Sémantique : pgvector, distance cosinus, index **HNSW** (`m=16, ef_construction=64`) — créé dès la migration 001 (coût nul à petite échelle, évite un re-index).
- Fusion Pro : `score = 0,7 × sémantique + 0,3 × texte` (⚠️ à calibrer, voir SAD Flux 2).

## 6. Versioning et synchronisation
Le serveur est la source de vérité (sync multi-appareils automatique). Modification de note : dernière écriture gagne (V1) ; résolution de conflits offline : P2 (PRD). Re-résumé d'un lymark : remplace puces+keywords+embedding, `summary_version += 1`.
