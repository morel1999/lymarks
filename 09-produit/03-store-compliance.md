# Store Compliance Spec — Lymarks

> **But :** passer les reviews Apple/Google du premier coup. Risque n°1 de la deadline. · **Statut :** vivant · **Màj :** 2026-09-17

> **V1.0 = Google Play seul** (ADR-007). La section Apple est gelée jusqu'à la V1.1.

## Apple App Store — V1.1
- [ ] **IAP uniquement** pour Pro (RevenueCat ✔), aucun lien d'achat externe.
- [ ] **Sign in with Apple** proposé (Google présent → obligatoire).
- [ ] **Suppression de compte in-app** accessible en ≤2 taps depuis les réglages (guideline 5.1.1(v)).
- [ ] **Privacy Nutrition Labels** conformes à la Privacy Spec (identifiants, contenu utilisateur ; pas de tracking tiers).
- [ ] Share extension : légère, pas d'UI trompeuse, App Group correctement configuré.
- [ ] Guideline 4.2 (valeur minimale) : l'app seule doit démontrer la boucle complète en review → fournir un **compte démo pré-rempli** dans les notes de review.
- [ ] Permission notifications demandée **en contexte** (activation du digest), jamais au premier lancement.

## Google Play — V1.0
- [ ] **Data Safety form** aligné sur la Privacy Spec.
- [ ] **Suppression de compte in-app** + URL web de suppression déclarée dans la console (exigé depuis 2024 pour toute app avec création de compte).
- [ ] Play Billing via RevenueCat ✔ ; App Signing by Google Play.
- [ ] Compte démo dans les notes de review ; target API level courant requis par Play.
- [ ] Politique de confidentialité hébergée (URL publique) ⚠️ à créer avant J13 (générée depuis la Privacy Spec).

## Causes classiques de rejet anticipées
Crash au premier lancement (checklist E2E), paywall sans restore (✔ prévu), suppression de compte absente (✔ P0-F7), métadonnées mentionnant d'autres plateformes, permission notifications injustifiée (✔ en contexte).
