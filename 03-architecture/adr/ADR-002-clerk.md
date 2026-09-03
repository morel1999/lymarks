# ADR-002 — Clerk pour l'authentification
**Statut :** accepté · 2026-08-07
**Contexte :** Google/Apple/e-mail requis, zéro temps à consacrer à la sécurité des mots de passe.
**Décision :** Clerk ; l'API vérifie les JWT via JWKS (aucun appel réseau Clerk sur le chemin chaud).
**Alternatives :** Supabase Auth (couplerait à un autre écosystème DB), Firebase Auth (config native plus lourde), auth maison (exclu : risque + délai).
**Conséquences :** dépendance SaaS payante à l'échelle ; vendor lock-in limité (JWT standard) ; Apple Sign-In couvert nativement.
