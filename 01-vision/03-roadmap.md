# Product Roadmap — Lymarks

> **But :** jalons versionnés. · **Statut :** vivant · **Màj :** 2026-09-18

> **Périmètre V1.0 = Android seul** (ADR-007). iOS en V1.1.

## Sprint Shipaton 2026 (V1.0)
| Étape | Jours | Contenu | Critère de sortie |
|---|---|---|---|
| 1. Infra cloud | J1–J2 | Neon + pgvector (schéma initial), Clerk configuré, API Hono déployée sur Workers | **Atteint le 18/09** : `https://lymarks-api.lymarks.workers.dev/health` → `{ok:true, db:ok}`, `/me` → 401 sans jeton. Neon eu-central-1 migré, Clerk lié, secrets en CI. |
| 2. Core Flutter + Share | J3–J6 | Projet Flutter ✔ (04/09), share sheet **Android** en canal natif ✔ (ADR-008, 18/09), liste + états ✔, **app branchée sur l'API + auth Clerk ✔ (18/09, ADR-010)** | **Atteint le 18/09** : capture réelle depuis Chrome sur un Android physique, réactivité jugée bonne, cartes `processing` visibles. X et YouTube à confirmer. Bout en bout (capture → résumé IA sur device) à valider avec l'APK suivant. |
| 3. Pipeline IA + recherche | J7–J10 | Scraper → Groq → Gemini → Neon ; recherche plein texte + cosinus | Code prêt le 18/09 (pipeline, anti-SSRF, recherche hybride, sur mocks). Critère inchangé : un lien partagé ressort via une requête sémantique **en prod** |
| 4. Monétisation + store | J11–J14 | Produits Play, paywall RevenueCat, gel des features à J11, soumission ≤ J14 | Build soumis à Google Play |

**Buffer review stores :** soumettre à J14 laisse la marge nécessaire avant le 30/09/2026 (rejet possible → itération, voir Risk Register R1).

## Post-lancement
- **V1.1 :** **iOS** (Apple Sign-In, share extension avec App Groups, Privacy Labels, IAP Apple — nécessite un Mac, voir ADR-007), Daily Digest si sorti du périmètre V1.0, transcripts YouTube, meilleure extraction des pages JS.
- **V1.2 :** widgets iOS/Android, tags manuels, collections.
- **V2 :** ⚠️ à décider — app web ou API publique. Décision après données d'usage réelles.
