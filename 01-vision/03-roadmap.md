# Product Roadmap — Lymarks

> **But :** jalons versionnés. · **Statut :** vivant · **Màj :** 2026-09-17

> **Périmètre V1.0 = Android seul** (ADR-007). iOS en V1.1.

## Sprint Shipaton 2026 (V1.0)
| Étape | Jours | Contenu | Critère de sortie |
|---|---|---|---|
| 1. Infra cloud | J1–J2 | Neon + pgvector (schéma initial), Clerk configuré, API Hono déployée sur Workers | `GET /health` authentifié OK en prod |
| 2. Core Flutter + Share | J3–J6 | Projet Flutter ✔ (fait le 04/09), `receive_sharing_intent` **Android**, liste + états ✔ | Capture réelle depuis X et Chrome sur un Android physique |
| 3. Pipeline IA + recherche | J7–J10 | Scraper → Groq → Gemini → Neon ; recherche plein texte + cosinus | Un lien partagé ressort via une requête sémantique |
| 4. Monétisation + store | J11–J14 | Produits Play, paywall RevenueCat, gel des features à J11, soumission ≤ J14 | Build soumis à Google Play |

**Buffer review stores :** soumettre à J14 laisse la marge nécessaire avant le 30/09/2026 (rejet possible → itération, voir Risk Register R1).

## Post-lancement
- **V1.1 :** **iOS** (Apple Sign-In, share extension avec App Groups, Privacy Labels, IAP Apple — nécessite un Mac, voir ADR-007), Daily Digest si sorti du périmètre V1.0, transcripts YouTube, meilleure extraction des pages JS.
- **V1.2 :** widgets iOS/Android, tags manuels, collections.
- **V2 :** ⚠️ à décider — app web ou API publique. Décision après données d'usage réelles.
