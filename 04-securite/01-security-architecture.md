# Security Architecture — Lymarks

> **But :** mesures de sécurité par couche. · **Statut :** vivant · **Màj :** 2026-08-07

## 1. Authentification et sessions
- JWT Clerk vérifiés à **chaque** requête par le middleware Hono (signature via JWKS mis en cache, `exp` court, audience contrôlée).
- Aucun endpoint non authentifié hors `/health` et le webhook RevenueCat (protégé par signature dédiée).
- `user_id` extrait du JWT uniquement — jamais du body — et injecté dans **chaque** requête SQL (`WHERE user_id = $1`). Aucun ID de ressource énumérable : UUID v4 partout.

## 2. Secrets
- Clés Groq, Gemini, Neon, secret webhook RevenueCat : **Cloudflare Workers Secrets** exclusivement. Zéro clé dans l'app Flutter, zéro clé dans le repo (`.dev.vars` gitignoré, GitLeaks en CI ⚠️ à confirmer dans les Coding Standards).
- L'app mobile ne parle qu'à l'API Lymarks — jamais directement à Groq/Gemini/Neon.
- Clerk publishable key (publique par design) seule embarquée côté client.

## 3. Scraper — anti-SSRF (surface critique n°1)
L'utilisateur soumet une URL arbitraire que **notre** serveur va fetcher :
- Schémas autorisés : `http(s)` uniquement.
- Résolution DNS puis blocage des IP privées/réservées (10/8, 172.16/12, 192.168/16, 127/8, 169.254/16, ::1, fd00::/8) — re-vérifié **après chaque redirection** (max 3).
- Timeout 10 s, taille max 2 MB, content-types autorisés : `text/html`, `application/xhtml+xml`.
- Le fetch part de l'edge Cloudflare, sans credentials, User-Agent identifié `LymarksBot/1.0`.

## 4. Contenu non fiable → LLM
Le texte scrapé peut contenir des instructions hostiles. Voir Threat Model M2. Mesures : prompt système strict (le contenu est une donnée, pas une instruction), sortie JSON schéma-validée (3 puces max, longueurs bornées), aucune capacité d'action donnée au LLM (pas d'outils), échappement à l'affichage côté Flutter.

## 5. Quotas et abus
- Rate limiting par utilisateur : 30 captures/h, 60 recherches/h (Workers Rate Limiting ⚠️ ou compteur Neon). Protège les coûts Groq/Gemini.
- Limites de plan appliquées côté serveur (voir Monetization Spec §3).

## 6. Transport, stockage, client
- TLS partout (défaut Cloudflare/Neon), HSTS.
- Neon : chiffrement au repos (natif), rôle SQL applicatif aux droits minimaux, branch dev ≠ prod.
- Flutter : tokens en stockage sécurisé (`flutter_secure_storage` : Keychain/Keystore), pas de logs de données sensibles, certificate pinning ⚠️ à décider (proposé : non en V1, complexité > risque).

## 7. Chaîne de livraison
- Signature des builds : App Store (automatique), Play App Signing.
- CI : lint + tests + scan secrets avant tout déploiement (`wrangler deploy` uniquement depuis la CI).
- Dépendances épinglées (pubspec.lock / package-lock committés), audit avant release.
