# Risk Register — Lymarks

> **But :** risques, probabilité (P), impact (I), mitigation. Échelle 1–3. · **Statut :** vivant · **Màj :** 2026-09-18

| ID | Risque | Cat. | P | I | Mitigation |
|---|---|---|---|---|---|
| R1 | Rejet store → deadline 30/09 manquée | Produit | 2 | 3 | Store Compliance checklist, soumission J14 (buffer), compte démo review, hotfix process |
| R2 | Sprint 14 j intenable en solo | Planning | 2 | 3 | P0 minimal strict, gel J11, P1 basculables en V1.1 (digest inclus) |
| R3 | Share sheet Android capricieux (Intent `ACTION_SEND`, texte sans URL, multi-URL) | Technique | 2 | 2 | Attaqué dès la reprise, device physique en USB, plan B = canal natif maison. La version iOS (App Groups, mémoire de l'extension) est reportée en V1.1 |
| R4 | Extraction médiocre (X, pages JS, paywalls) | Technique | 3 | 2 | Statut `partial` assumé, fallback métadonnées OG, amélioration V1.1 |
| R5 | Coûts IA dérapent avec le Free | Financier | 1 | 2 | Limite 30, rate limiting, cache url_hash, alertes budget J1 |
| R6 | Scraping vs ToS des plateformes (X, LinkedIn) | Légal | 2 | 2 | Fetch simple sans contournement d'auth, User-Agent identifié, respect robots ⚠️ à trancher, réévaluation post-launch |
| R7 | Indispo Groq pendant le sprint/le launch | Technique | 1 | 2 | Fallback Gemini Flash (AI Arch §1), statut `failed` + retry propre |
| R8 | Bus factor = 1 (solo) | Organisation | 3 | 2 | Cette documentation ; CI reproductible ; secrets dans un vault personnel |
| R9 | Fuite de clé API | Sécurité | 1 | 3 | Workers Secrets, GitLeaks CI, rotation immédiate documentée |
| R10 | Aucun moyen de builder iOS (pas de Mac, pas de device) → la moitié du marché absente au lancement | Produit | 3 | 2 | **Décision prise (ADR-007) : Android seul en V1.0, iOS en V1.1.** Provisionner un Mac (occasion ou cloud) avant d'ouvrir la V1.1 ; ne rien promettre d'iOS sur le store listing ni le site |
| R11 | Machine de dev à **3,8 Go de RAM** (mesuré le 17/09 : 0,4 Go libre, 2,5 Go en swap). Premier build Gradle tué faute de mémoire après 18 min | Organisation | 3 | 3 | **Build Android en CI** (GitHub Actions, .github/workflows/android.yml) comme voie principale ; en local : Gradle à 1 Go sans daemon, Kotlin in-process, VS Code et navigateur fermés. Pas d'émulateur, pas d'Android Studio, aucun scan récursif |
| R12 | **`workers.dev` filtré par certains FAI** — constaté le 18/09 : Türk Telekom « Güvenli İnternet » redirige le HTTP vers sa page de blocage et casse le TLS ; la machine de dev ne joint pas l'API | Tech | 3 | 3 | Servir l'API sur un domaine propre via une route Cloudflare (`api.<domaine>`) avant la soumission ; d'ici là, tests de prod depuis la CI (`probe.yml`) |

Revue : à chaque fin d'étape du sprint (J2, J6, J10, J14).
