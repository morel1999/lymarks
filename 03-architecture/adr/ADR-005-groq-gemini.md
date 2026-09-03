# ADR-005 — Groq (Llama 3.3) pour les résumés, Gemini pour les embeddings
**Statut :** accepté · 2026-08-07
**Contexte :** résumés en 3 puces quasi temps réel, coût par lymark minimal ; embeddings de qualité multilingue.
**Décision :** Groq Llama 3.3 70B (vitesse d'inférence, coût faible) ; Gemini `text-embedding-004` (768 d) pour la vectorisation.
**Alternatives :** GPT-4o-mini / Claude Haiku (résumés : plus chers ou plus lents), embeddings OpenAI (dimension supérieure = stockage/latence en plus sans gain prouvé ici).
**Conséquences :** deux fournisseurs IA → deux clés à protéger ; fallback résumés à définir (voir AI Architecture §4) ; embeddings verrouillés sur 768 d (migration = re-embedding complet, coût assumé).
