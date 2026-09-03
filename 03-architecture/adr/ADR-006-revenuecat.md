# ADR-006 — RevenueCat pour la monétisation
**Statut :** accepté · 2026-08-07
**Contexte :** abonnements iOS+Android, contexte Shipaton (RevenueCat), pas de temps pour StoreKit/Billing bruts.
**Décision :** `purchases_flutter` + entitlement unique `pro` ; webhook RevenueCat → table `subscriptions` pour l'enforcement serveur.
**Alternatives :** StoreKit2/Play Billing en direct (double implémentation, reçus à valider soi-même).
**Conséquences :** commission RevenueCat au-delà du palier gratuit ; source de vérité des droits = serveur, jamais le client.
