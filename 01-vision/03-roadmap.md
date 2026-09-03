# Product Roadmap — Lymarks

> **But :** jalons versionnés. · **Statut :** vivant · **Màj :** 2026-08-07

## Sprint Shipaton 2026 (V1.0)
| Étape | Jours | Contenu | Critère de sortie |
|---|---|---|---|
| 1. Infra cloud | J1–J2 | Neon + pgvector (schéma initial), Clerk configuré, API Hono déployée sur Workers | `GET /health` authentifié OK en prod |
| 2. Core Flutter + Share | J3–J6 | Projet Flutter, `receive_sharing_intent` iOS & Android, liste + états | Capture réelle depuis X et Safari sur device physique |
| 3. Pipeline IA + recherche | J7–J10 | Scraper → Groq → Gemini → Neon ; recherche plein texte + cosinus | Un lien partagé ressort via une requête sémantique |
| 4. Monétisation + stores | J11–J14 | Produits App Store/Play, paywall RevenueCat, gel des features à J11, soumission ≤ J14 | Builds soumis aux deux stores |

**Buffer review stores :** soumettre à J14 laisse la marge nécessaire avant le 30/09/2026 (rejet possible → itération, voir Risk Register R1).

## Post-lancement
- **V1.1 :** Daily Digest si sorti du périmètre V1.0, transcripts YouTube, meilleure extraction des pages JS.
- **V1.2 :** widgets iOS/Android, tags manuels, collections.
- **V2 :** ⚠️ à décider — app web ou API publique. Décision après données d'usage réelles.
