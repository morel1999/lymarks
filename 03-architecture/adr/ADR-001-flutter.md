# ADR-001 — Flutter pour le mobile
**Statut :** accepté · 2026-08-07
**Contexte :** app iOS+Android à livrer en 14 jours par un dev solo ; UI fluide (60–120 FPS) et intégration du menu de partage requises.
**Décision :** Flutter (Dart), avec `receive_sharing_intent` pour la share extension.
**Alternatives :** React Native (écosystème share extensions plus fragmenté), natif double (impossible en solo/14 j), KMP (maturité UI).
**Conséquences :** un seul codebase ; vigilance sur la partie native de l'extension de partage iOS (App Groups) ; taille d'app à surveiller (budget <40 MB).
