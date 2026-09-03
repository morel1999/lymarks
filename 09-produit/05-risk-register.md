# Risk Register — Lymarks

> **But :** risques, probabilité (P), impact (I), mitigation. Échelle 1–3. · **Statut :** vivant · **Màj :** 2026-08-07

| ID | Risque | Cat. | P | I | Mitigation |
|---|---|---|---|---|---|
| R1 | Rejet store → deadline 30/09 manquée | Produit | 2 | 3 | Store Compliance checklist, soumission J14 (buffer), compte démo review, hotfix process |
| R2 | Sprint 14 j intenable en solo | Planning | 2 | 3 | P0 minimal strict, gel J11, P1 basculables en V1.1 (digest inclus) |
| R3 | Share extension iOS capricieuse (App Groups, mémoire) | Technique | 2 | 3 | Attaquée dès J3, device réel, plan B = canal natif maison |
| R4 | Extraction médiocre (X, pages JS, paywalls) | Technique | 3 | 2 | Statut `partial` assumé, fallback métadonnées OG, amélioration V1.1 |
| R5 | Coûts IA dérapent avec le Free | Financier | 1 | 2 | Limite 30, rate limiting, cache url_hash, alertes budget J1 |
| R6 | Scraping vs ToS des plateformes (X, LinkedIn) | Légal | 2 | 2 | Fetch simple sans contournement d'auth, User-Agent identifié, respect robots ⚠️ à trancher, réévaluation post-launch |
| R7 | Indispo Groq pendant le sprint/le launch | Technique | 1 | 2 | Fallback Gemini Flash (AI Arch §1), statut `failed` + retry propre |
| R8 | Bus factor = 1 (solo) | Organisation | 3 | 2 | Cette documentation ; CI reproductible ; secrets dans un vault personnel |
| R9 | Fuite de clé API | Sécurité | 1 | 3 | Workers Secrets, GitLeaks CI, rotation immédiate documentée |

Revue : à chaque fin d'étape du sprint (J2, J6, J10, J14).
