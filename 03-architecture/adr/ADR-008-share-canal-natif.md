# ADR-008 — Menu de partage Android : canal natif maison
**Statut :** accepté · 2026-09-18
**Contexte :** F1 (capture via le menu de partage) est le cœur du P0. Les coding standards prévoient `receive_sharing_intent`, avec la réserve « maintenance variable → alternative : canal natif maison », et le Risk Register R3 nomme ce canal comme plan B. Le périmètre V1.0 est Android seul (ADR-007).
**Décision :** une `ShareActivity` Kotlin dédiée (translucide, sans historique ni entrée dans les récents, sans affinité de tâche) qui héberge son propre moteur Flutter sur l'entrée Dart `shareMain`, et un `MethodChannel` de deux méthodes (`getShared`, `close`). Pas de dépendance tierce.
**Alternatives :** `receive_sharing_intent` — conçu autour des App Groups iOS, lourd pour Android seul, et il route le partage vers `MainActivity`, ce qui ouvre l'app (contraire à l'UX Bible règle 2) ; une seule activité avec détection de route — même problème d'ouverture de l'app, et le moteur charge tout le routeur et les données.
**Conséquences :**
- Le chemin « tap → fermeture » ne charge que la feuille de capture : ni routeur, ni onglets, ni données de démo. `close` rend la durée mesurée depuis la création de l'activité, journalisée contre le budget < 2 s.
- La feuille écrit dans une file locale (`capture_queue.json`, écriture atomique) que l'app principale vide au lancement et à chaque retour au premier plan — c'est la file « hors-ligne » du PRD §3, même sans réseau et sans backend.
- Doublon d'URL (PRD §3) : `saved_count` +1 et note remplacée, pas de second lymark ; normalisation locale minimale en attendant le `url_hash` serveur.
- Décisions produit prises ici, à confirmer dans le PRD : plusieurs URL dans un partage → la première est enregistrée et l'utilisateur en est informé ; partage sans URL → refus explicite (« No link in what you shared »), Lymarks n'enregistre que des liens.
- iOS (V1.1) réutilisera le même contrat Dart (`ShareHost`) : l'extension native sera à écrire, mais rien côté feuille ni file ne change.
