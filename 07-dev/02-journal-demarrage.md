# Journal de démarrage — app Flutter

> **But :** tracer les décisions prises au démarrage du code, et tout écart assumé vis-à-vis des documents. · **Statut :** vivant · **Màj :** 2026-09-17

Étape 2 de la roadmap (« Core Flutter ») démarrée avant l'étape 1 (« Infra cloud »), qui exige des comptes Neon / Clerk / Cloudflare non provisionnables sans accès. L'app tourne donc sur données mock ; aucun écran ne dépend de `MockData` autrement que par les providers, le branchement API est un remplacement de providers.

## 1. Décisions verrouillées (levées de ⚠️)

| Point | Décision | Raison |
|---|---|---|
| State management | **Riverpod** (`flutter_riverpod` 2.6) | Proposition des coding standards ; testable sans widget, `ProviderContainer` utilisé dans les tests unitaires. |
| Navigation | **go_router** + `StatefulShellRoute.indexedStack` | Implémente directement l'UX Bible règle 10 : chaque onglet garde sa pile, son scroll et sa requête. |
| Typographie | **Inter embarqué** (`assets/fonts/`, 4 graisses, 1,3 Mo) | `google_fonts` télécharge la police au runtime : appel réseau tiers à chaque cold start, contraire au budget « cold start < 2 s » et au principe 5. |
| Icônes | **`lucide_icons_flutter` 3.1.17** | Écart assumé : les coding standards citent `lucide_flutter` (4 ★, ~18k dl/30 j). Le paquet retenu fait 196 ★, 159k dl/30 j, 160/160 pts pub, à jour du 21/08/2026. |
| Modèles | Classes immuables écrites à la main | Écart temporaire : `freezed` sera introduit avec le contrat d'API (sérialisation JSON), pas pour 5 modèles mock sans JSON. |

## 2. Couleur — la Home est la seule référence

La palette n'est pas inventée : elle est **échantillonnée au pixel** sur les maquettes (décodeur PNG ad hoc, pas d'estimation à l'œil).

| Token | Valeur | Source |
|---|---|---|
| `primary` | `#4A35E8` | Home — nav active, « See all », puces |
| `surface` / `card` | `#FAFAFD` / `#FFFFFF` | Home + Parcours |
| `navSurface` | `#EEEBFD` | Home — barre d'onglets |
| `badgeInk` | `#171717` | Home — pastilles d'icônes |
| `lime` | `#EDF9CC` / `#C3E91C` | Home (hero) + Parcours (point) |
| `blue` | `#DAF3FD` / `#72D7F3` | idem |
| `lavender` | `#EDE8FC` / `#8C58D6` | idem |
| `yellow` | `#FDF7D3` / `#FDDB71` | idem |
| `pink` | `#FEE7E2` / `#F87F85` | idem |

Le `#4A35E8` mesuré confirme à 3 % près le `#4F46E5` du Design System : **`02-ux/02-design-system.md` §Couleurs peut passer de « palette proposée, à valider » à validée**, en substituant les valeurs mesurées.

Les cinq familles sont attribuées par **emplacement explicite** : une catégorie porte `accent`, un cluster aussi, et un lymark hérite `accentSlot` de sa catégorie. Le hachage (`accentFor`) ne sert plus que de repli pour un lymark sans catégorie. Raison : une couleur hachée changerait si l'identifiant changeait, et ne serait pas garantie identique entre appareils — c'est donc au serveur de porter cet emplacement. Les emplacements des données de démo reproduisent la Home (IA vert, Design bleu, Development lavande, Business jaune, Product rose).

Les thèmes des autres maquettes (olive/crème du Détail, menthe/carmin du Digest) **ne sont pas repris** : la Home est la référence unique.

Le mode sombre est **dérivé**, pas mesuré — aucune maquette sombre n'existe. À revoir quand il y en aura une.

## 3. Écarts assumés vis-à-vis des maquettes

1. **Digest** — la maquette montre une série de 7 jours, « Great job! 🔥 », un pourcentage de progression et des « trending topics ». L'UX Bible §Ton interdit explicitement la gamification et les badges, et la règle 6 limite le digest à un rappel par jour. L'écran suit donc le **wireframe 06**, pas le PNG.
2. **Profil** — même raison : le « 7 Day streak » est remplacé par « With Lymarks » (ancienneté), factuel.
3. **Icônes de marque** — Lucide a retiré ses icônes de marque (licence). Pas de logo React / Medium / Vercel / HuggingFace : chaque source reçoit une icône sémantique (`squarePlay` pour YouTube, `briefcase` pour LinkedIn…). Si les logos sont indispensables au rendu final, il faudra une seconde bibliothèque (`simple-icons`) — **question ouverte**.
4. **Aperçu de source (fiche détail)** — aplat dégradé teinté de l'accent au lieu de l'image OG. Aucune image distante n'est chargée dans les listes : cela protège le budget de scroll 60 FPS et évite toute requête tierce depuis l'app.
5. **Barre d'onglets** — visible uniquement sur Home / Search / Digest. Les maquettes la montrent aussi sur Détail, Parcours et Réglages ; les wireframes 03, 04, 07 et le §9 « Navigation globale » disent l'inverse. Le comportement suit les wireframes (source de vérité comportementale), la couleur suit la Home.
6. **`Ecran/Home.png` est un doublon exact** de `Ecran/Profil moderne aux accents pastel.png` (même MD5). Il n'existe donc **aucune maquette d'onboarding** : l'écran 01 est construit à partir du seul wireframe.

## 4. Vérification et contraintes de test découvertes

`flutter analyze` (very_good_analysis, strict) : **0 issue**. `flutter test` : **23 tests verts** — 8 de comportement, 15 rendus de référence.

### Le rendu se vérifie par golden tests, pas par navigateur

Le build web se compile (`flutter build web --release`, exit 0) mais **ne se rend pas en Chromium headless** : Flutter monte `flt-glass-pane` en 0×0 et ne crée aucun `<canvas>`. Aucune erreur console, la page est simplement blanche. Piste écartée, non résolue.

À la place, `test/golden_test.dart` rend les 7 écrans en PNG via le moteur Flutter lui-même (`flutter test --update-goldens`), sans device ni navigateur. Les images sont versionnées dans `app/test/goldens/` : preuve visuelle **et** garde-fou anti-régression.

Deux pièges rencontrés, tous deux documentés dans le code :

1. **`pumpAndSettle` ne termine jamais** dès qu'un lymark `processing` est à l'écran : le shimmer boucle indéfiniment (Design System : 1,2 s en boucle). Les tests pompent un nombre fixe de frames.
2. **Les polices ne sont pas chargées par défaut** dans `flutter test` : sans `FontLoader` explicite, chaque glyphe est un pavé plein et les goldens ne valident que la mise en page. `_loadFonts()` charge Inter et Lucide.

Troisième piège mineur : les listes étant paresseuses, la surface de test par défaut (800×600) ne construit aucune carte. Les tests fixent 420×1400.

À reporter dans `08-qualite/01-test-strategy.md`.

### Les goldens suivaient l'horloge réelle (corrigé le 18/09)

Deux semaines après leur génération, trois goldens échouaient sans qu'aucun pixel de code n'ait changé : le Digest affiche la date du jour, le Profil compte les mois depuis l'inscription, la Home salue selon l'heure. Tout `DateTime.now()` d'un écran passe désormais par `clockProvider`, que les goldens figent au 4 septembre 9 h. Règle à retenir : **un rendu de référence ne doit dépendre d'aucune horloge, d'aucun aléa, d'aucune plateforme**.

### Les E/S réelles et l'horloge simulée des tests de widget

La feuille de partage écrit un vrai fichier. Sous `testWidgets`, chaque `await` qui suit une E/S reprend dans une microtâche de la zone simulée, vidée uniquement par `pump` : attendre en temps réel ne suffit pas, il faut alterner `runAsync(delay)` et `pump()` jusqu'à l'événement attendu (`_waitForClose` dans `test/capture_test.dart`).

### Deux défauts trouvés par les goldens, et corrigés

- **Débordement horizontal** (`RenderFlex overflowed by 141 pixels`) sur l'écran Search : le `Spacer(flex:1)` et le libellé de mode se partageaient l'espace à parts égales, affamant le libellé. Corrigé (`Expanded` sur le libellé, textes tronquables). Ce défaut était invisible sans rendu — il justifie à lui seul les goldens.
- **Dégradés ternes en mode sombre** : les fonds de hero mélangeaient du blanc, ce qui vire au gris sur fond sombre et efface l'identité de couleur. Remplacé par `LyPalette.lift()`, qui renforce la teinte au lieu d'ajouter du blanc — correct dans les deux thèmes.

## 5. Poids embarqué — mesure

`lucide_icons_flutter` déclare **7 familles de police** dans son pubspec ; Flutter embarque toutes les polices d'une dépendance, sans opt-out possible.

| Police | Poids | Utilisée |
|---|---|---|
| `lucide.ttf` | 736 Ko | oui |
| `LucideVariable-w100…w600` (6 fichiers) | 2,5 Mo | **non** |
| Inter 400/500/600/700 | 1,3 Mo | oui |

Soit **2,5 Mo de poids mort** sur un budget d'app installée de 40 Mo (`08-qualite/02-performance-budget.md`). Ce n'est pas un dépassement, donc rien n'est fait maintenant — le jeu d'icônes bouge encore. À revoir avant soumission aux stores : vendoriser `lucide.ttf` seul, ou sous-ensembler la police aux ~57 glyphes réellement utilisés (~10 Ko).

**Première mesure réelle (CI, 17/09)** : APK release **arm64 18,6 Mo**, armv7 16,3 Mo. Le debug pesait 144 Mo (toutes les ABI + VM JIT) — ne jamais juger la taille sur un build debug. La taille installée sera un peu supérieure à l'APK ; la marge sous les 40 Mo reste large.

## 6. Environnement

Flutter 3.41.9 · Dart 3.11.5 · Node 22.22 · JDK Temurin 17. Machine Windows, **sans Mac ni device iOS** → ADR-007 (Android seul en V1.0). Mémoire contrainte (R11) : pas d'émulateur, pas d'Android Studio, pas de scan récursif.

### Chaîne Android (installée le 17/09)

Command-line tools 22.0 seuls (148 Mo, SHA-256 vérifié contre l'empreinte publiée par Google), dans `%LOCALAPPDATA%\Android\Sdk`. Paquets : `platform-tools`, `platforms;android-36`, `build-tools;36.0.0` — ce que Flutter 3.41.9 exige (compileSdk 36, minSdk 24, AGP 8.11.1). `flutter doctor` : tout vert.

### Piège machine : AVG intercepte le HTTPS

**AVG Antivirus (« Web/Mail Shield ») re-signe tout le trafic HTTPS avec sa propre racine.** Windows lui fait confiance, donc navigateurs, `curl` et Dart passent. **Java non** : la JVM a son propre magasin (`cacerts`) qui ignore AVG → `PKIX path building failed` sur `sdkmanager`, et ce serait pareil pour Gradle, AGP, Kotlin.

Correctif retenu, réversible et hors dépôt : faire lire à Java le magasin Windows via `-Djavax.net.ssl.trustStoreType=WINDOWS-ROOT`, posé à trois endroits :
- `SDKMANAGER_OPTS` pour sdkmanager ;
- `GRADLE_OPTS` (variable utilisateur) pour le wrapper qui télécharge la distribution ;
- `systemProp.javax.net.ssl.trustStoreType=WINDOWS-ROOT` dans `~/.gradle/gradle.properties` pour le daemon qui télécharge les dépendances.

Alternative écartée : importer la racine AVG dans le `cacerts` du JDK (à refaire à chaque mise à jour du JDK).

**Résolu le 17/09 :** l'analyse HTTPS d'AVG a été désactivée (Bouclier Web → « Activer l'analyse HTTPS » décoché). Vérifié : `dl.google.com` présente désormais un certificat émis par Google Trust Services. Le réglage `WINDOWS-ROOT` est conservé : inoffensif, et il protège si l'analyse est réactivée.

Autre piège : `Invoke-WebRequest` (PowerShell 5.1) plafonne à ~60 Ko/s à cause de sa barre de progression ; `curl.exe` natif fait 2,4 Mo/s sur la même connexion. Et `Expand-Archive` échoue sur ce zip ; `tar.exe` (natif Windows 10+) fonctionne.

## 7. API — décisions prises à l'implémentation (18/09)

Le code est dans `api/` (README dedans : routes, commandes, déploiement). Ce qui a été tranché en l'écrivant, et pourquoi :

- **SQL brut, pas Drizzle** → ADR-009. Le contrat `Db` (`src/db/types.ts`) a deux implémentations : Neon (`src/db/neon.ts`, seul fichier avec du SQL) et mémoire (`test/helpers/memory-db.ts`). Les 104 tests tournent sans base ni réseau : sur cette machine c'est la seule façon d'avoir une suite rapide (10 s) et sûre pour la RAM.
- **Auth Clerk sans SDK** : `jose` vérifie le JWT contre le JWKS de l'instance ; l'hôte du JWKS est décodé depuis la publishable key (`pk_test_<base64(host)$>`), donc une seule clé à configurer. La `secret key` ne sert qu'à supprimer le compte chez Clerk (F7).
- **Anti-SSRF sans DNS système** : le Worker n'a pas d'API DNS, on interroge le résolveur DoH de Cloudflare avant le fetch, puis à chaque redirection (3 max). Ports 80/443 seulement. Les formes d'IP exotiques (`http://2130706433/`) sont neutralisées par le parseur WHATWG lui-même, testé.
- **Scraper sans DOM** : extracteur regex (article/main/body, balises de bruit retirées, entités décodées). Suffisant pour 3 puces, et zéro dépendance. **X** : l'endpoint oEmbed public rend le texte du post que le HTML brut ne contient pas ; tenté d'abord, page en repli.
- **Résumeur = une classe, deux fournisseurs** : Groq et Gemini parlent tous deux le protocole chat-completions d'OpenAI. Chaîne : Groq (1 retry) → Gemini Flash (1 retry) → `failed`. Sortie hors format (M2) → second appel avec la réponse fautive en contexte et consigne de correction, comme prévu AI Architecture §3. Le fallback Gemini Flash, ⚠️ dans la doc, est donc **retenu** : zéro fournisseur en plus.
- **Embeddings** : `outputDimensionality: 768` envoyé systématiquement — ignoré par `text-embedding-004`, respecté par les modèles plus larges. Le jour où Google retire ce modèle, on change la variable `GEMINI_EMBEDDING_MODEL` dans `wrangler.toml`, pas le schéma.
- **Statuts** : `failed` = rien n'a pu être récupéré (404, timeout, SSRF, résumeur à plat) avec `failure_reason` ; `partial` = page mince (paywall, JS), résumé sur les métadonnées OG, ou embedding indisponible. Le titre transmis par la feuille de partage sert de secours dans tous les cas.
- **Limites côté serveur** : Free 30 actifs (403 `limit_reached`, un doublon ne consomme rien, archiver libère), 30 captures/h par comptage Neon (429). Le rate limiting des recherches (60/h prévu Security §5) est **reporté** : la recherche texte est une requête SQL bon marché, la sémantique est réservée aux Pro payants ; à ajouter si les logs montrent un abus.
- **Export JSON pour tous** (`GET /me/export`) : la question RGPD art. 20 de la Privacy Spec est tranchée dans le sens de la portabilité.
- **Webhook RevenueCat** : `Authorization` comparé en temps constant, idempotence par `event.id`, rejet des événements plus anciens que le dernier appliqué (`last_event_at`). Toujours 200 une fois authentifié, sinon RevenueCat rejoue indéfiniment.
- **Cache de résumés inter-utilisateurs** (AI Architecture §2) : implémenté dans le pipeline, index `bookmarks_url_hash` ajouté pour ça.

**Première migration réelle (18/09)** : Postgres a refusé l'index GIN de la doc — `array_to_string()` est `STABLE`, pas `IMMUTABLE`, donc interdit dans une expression d'index. Correctif : fonction `keywords_text()` immuable + colonne générée `fts tsvector … STORED` indexée directement ; les requêtes lisent `fts` au lieu de répéter l'expression (un écart de virgule entre l'index et la requête aurait suffi à perdre l'index). La transaction par fichier a fait son travail : rien n'était à moitié appliqué, le rejeu après correctif est passé, et un second rejeu répond « déjà appliquée ». Base : PostgreSQL 18.6, pgvector 0.8.6, eu-central-1.

**Mise en service (18/09, soirée)** — ce qui a mordu, dans l'ordre :
- `neon login` : le CLI n'ouvre pas le navigateur sur cette machine et expire en 60 s (3 échecs). Solution : clé API (`NEON_API_KEY` dans `.dev.vars`), le CLI la lit dans l'environnement. Le CLI Clerk, lui, a ouvert le navigateur et attend 15 min : `clerk env pull --app … --file` a livré les deux clés dans un fichier gitignoré, sans presse-papiers.
- **Secrets GitHub avec un BOM** : sous une console en code page UTF-8, PowerShell 5.1 préfixe d'un `U+FEFF` tout ce qu'il pipe vers un exécutable natif — quel que soit `$OutputEncoding`, testé. Invisible dans `gh secret list`, visible seulement par la longueur (154 au lieu de 153). Wrangler refusait l'Account ID, `migrate.ts` passait grâce à `String.trim()` qui retire aussi le BOM. Correctif : `push-secrets.ps1` écrit un dotenv temporaire (UTF-8 sans préambule) lu par `gh secret set -f`, plus un pas de diagnostic « forme des secrets » (longueur, préfixe, jamais la valeur) dans `api.yml`.
- `| tee` masquait l'échec de `wrangler deploy` : `shell: bash` explicite (= `pipefail`).
- Un compte Cloudflare neuf n'a pas de sous-domaine `workers.dev` ; wrangler le demande interactivement, impossible en CI. Enregistré par l'API (`PUT /accounts/{id}/workers/subdomain`) : **`lymarks.workers.dev`**. Le certificat `*.lymarks.workers.dev` a mis ~5 min à être émis (`sslv3 alert handshake failure` entre-temps).
- **Le FAI local bloque `workers.dev`** (Türk Telekom « Güvenli İnternet » : 307 vers sa page en HTTP, TLS cassé en HTTPS). La machine de dev ne peut pas tester la prod ; `probe.yml` le fait depuis un runner. Risque produit R12 : domaine propre à prévoir avant la soumission.
- Un jeton Cloudflare a été affiché en clair par un script de contrôle qui ne masquait que les lignes `NOM=valeur` (l'utilisateur avait écrit `Nom: valeur`). Révoqué et régénéré dans la minute — la règle R9 appliquée à soi-même.

**App ↔ API (18/09, nuit)** — ce qui a été tranché en branchant l'app :
- **`clerk_flutter` beta épinglé + mode démo** → ADR-010. Le contrat `AuthSession` isole le SDK ; `DemoAuthSession` porte le profil de démo (« Morel Herval », Pro) pour que les 15 rendus de référence restent valables.
- **Dépôt = frontière testable** (`LymarksRepository`) : API en mode réel, `MockLymarksRepository` en démo/tests, mêmes règles (doublon, retry, recherche pondérée). Le client HTTP est testé sur `MockClient` ; aucun test ne touche le réseau.
- **Optimiste d'abord** : chaque geste modifie la liste locale puis part au serveur ; le serveur remplace l'entrée à sa réponse. Un compteur de mutations empêche un `refresh` parti avant un geste de l'écraser (bug trouvé par le test « une capture envoyée est consommée »). Après disposition du provider (fin de test, déconnexion), les continuations réseau ne touchent plus à l'état.
- **Suppression réversible sans timer** : `remove` archive côté serveur tout de suite, `restore` désarchive, et la suppression réelle (`purge`) part quand le SnackBar se ferme sans « Undo » (`controller.closed`). Aucun `Timer` dans le notifier : `testWidgets` échoue sur tout timer en suspens, et le sondage des cartes `processing` (4 s, borné à 30 tours) n'existe qu'en mode réel pour la même raison.
- **31ᵉ capture** : le serveur répond 403 `limit_reached`, la capture est consommée (pas rejouée), et la Home affiche le paywall — jamais la feuille de partage (Monetization §4).
- **Formatage** : `dart format` (style Dart 3.11) appliqué à tout `lib/` et `test/` — d'où un diff large mais neutre sur des fichiers non modifiés.
- Manifest : `INTERNET` ajouté explicitement (le debug l'obtient tout seul, pas la release). CI : `--dart-define` de la clé Clerk et de l'URL de l'API, échec si la clé manque.

Ce qui n'est **pas** fait : Digest (M4, P1) — les colonnes existent, pas le cron ; push tokens ; test d'intégration sur branche Neon (ADR-009, conséquences). Et surtout : **rien n'est déployé** tant que les comptes n'existent pas — `api/.dev.vars` attend les clés, `api/scripts/push-secrets.ps1` les envoie en GitHub Secrets, `api.yml` fait le reste.

## 8. Questions ouvertes créées par les écrans

Elles ne bloquent pas le code actuel mais devront être tranchées :

1. **Clustering automatique** — le Category Path affiche des clusters (« AI Agents », « RAG »…). Le wireframe 03 le signale déjà (« Point à formaliser ») : rien dans le PRD ni le Knowledge Vault Spec ne définit comment un cluster naît, se recalcule, ou accueille un nouveau lymark. L'écran fonctionne sur des clusters mock.
2. **Digest Free ou Pro** — le PRD le classe P1/Pro, le wireframe 06 laisse la question ouverte. L'app affiche un bandeau d'upsell en Free ; à confirmer.
3. **« Open original »** — navigateur in-app (Custom Tabs / SFSafariViewController) ou externe. Le bouton existe, l'action est un stub.
4. **Logos de marque** — voir §3.3.
