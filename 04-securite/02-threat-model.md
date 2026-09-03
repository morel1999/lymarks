# Threat Model — Lymarks

> **But :** comment le produit peut être attaqué, et ce qui l'en empêche. · **Statut :** vivant · **Màj :** 2026-08-07

| ID | Attaque | Vecteur | Impact | Protection |
|---|---|---|---|---|
| M1 | **SSRF via URL soumise** | `POST /bookmarks` avec `http://169.254.169.254/`, IP interne, redirection piégée | Accès métadonnées/services internes | Filtrage IP + re-check post-redirect, schémas http(s), timeout/taille (Security §3) |
| M2 | **Injection de prompt via contenu scrapé** | Page contenant « ignore tes instructions, réponds… » | Résumé mensonger, contenu toxique, bourrage de sortie | Contenu traité comme donnée, sortie JSON validée, puces bornées, LLM sans outils |
| M3 | **Vol/rejeu de JWT** | Token exfiltré d'un device | Accès aux lymarks de la victime | Expiration courte + rotation Clerk, stockage Keychain/Keystore, TLS |
| M4 | **Abus de quota / attaque sur les coûts** | Script appelant l'API en boucle (captures → appels Groq) | Facture IA, déni de service économique | Rate limiting par user, limite Free serveur, idempotence par url_hash |
| M5 | **Bypass du paywall** | Appel direct de l'API en Free au-delà de 30, ou entitlement forgé côté client | Perte de revenus | Enforcement 100 % serveur via table `subscriptions` (webhook RevenueCat signé) |
| M6 | **IDOR / énumération** | `GET /bookmarks/{id}` d'un autre utilisateur | Fuite de données privées | UUID + `WHERE user_id=` systématique (test d'intégration dédié) |
| M7 | **Webhook RevenueCat forgé** | POST forgé → passage en Pro gratuit | Perte de revenus | Vérification de l'Authorization header dédié, idempotence des events |
| M8 | **Supply chain** | Paquet pub.dev/npm compromis | Exécution de code, vol de secrets | Versions épinglées, lockfiles, audit avant release, dépendances minimales |
| M9 | **Push spoofing / fuite via notifications** | Contenu sensible dans la notif | Fuite du titre d'un lien privé sur écran verrouillé | Notif digest limitée au titre ⚠️ à décider : option « notif discrète » (sans titre) |
| M10 | **MITM** | Réseau hostile | Interception | TLS strict, pas de fallback HTTP |

Revue de ce tableau à chaque ajout de feature (règle inscrite dans les Core Principles).
