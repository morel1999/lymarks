# ADR-010 — Auth mobile via le SDK Clerk Flutter (beta), et un mode démo
**Statut :** accepté · 2026-09-18
**Contexte :** F5 impose Clerk (ADR-002) avec Google et e-mail. Clerk n'a pas de SDK Flutter stable : `clerk_flutter` est annoncé en beta (changelog Clerk du 26/03/2025), publié par clerk.com mais « maintenu par la communauté », avec la consigne d'épingler la version patch. L'alternative est de parler à l'API Frontend de Clerk à la main : le flux e-mail + code est simple, mais Google OAuth demande un navigateur, un retour par deep link et la gestion de la session — plusieurs jours pour un développeur solo à 12 jours de la deadline.
**Décision :** `clerk_flutter` + `clerk_auth` épinglés en version exacte (`0.0.18-beta`), écran de connexion prébuilt (`ClerkAuthentication`, les stratégies affichées sont celles du dashboard), jeton via `ClerkAuthState.sessionToken()`. Le reste de l'app ne voit que le contrat `AuthSession` (`core/auth/auth_session.dart`) : `isSignedIn`, `user`, `token()`, `signOut()`, observable.
Corollaire : **un mode démo**. Sans `--dart-define=CLERK_PUBLISHABLE_KEY`, l'app tourne sur une session factice et un dépôt en mémoire (`MockLymarksRepository`, mêmes règles métier que l'API). C'est le mode des tests, des rendus de référence et de toute machine sans clé. La CI refuse de produire un APK sans clé.
**Alternatives :** API Frontend maison (coût, risque sur OAuth) ; Firebase Auth (rompt ADR-002) ; reporter l'auth (impossible : F6 et F7 en dépendent).
**Conséquences :**
- Le SDK ouvre Google OAuth dans une WebView avec un user-agent personnalisé pour contourner le refus des WebViews par Google : ça marche, c'est fragile. Risque à suivre ; issue de repli = flux navigateur externe (`redirectionGenerator` + `deepLinkStream` du SDK).
- 60 dépendances transitives de plus (webview, url_launcher, passkeys, image_picker…) : à mesurer sur l'APK (budget 40 Mo).
- Aucun upgrade du SDK pendant le sprint (Coding Standards §5) ; revue après le Shipaton, migration vers la 1.0 quand elle sort.
- La logique d'état (`LymarksNotifier`, recherche, profil) est testée sur le dépôt mémoire et le client HTTP sur un `MockClient` : 37 tests, sans réseau ni SDK.
