# ADR-007 — Android d'abord, iOS en V1.1
**Statut :** accepté · 2026-09-17
**Contexte :** la machine de développement est sous Windows ; aucun Mac, aucun device iOS. Or un build iOS exige Xcode, donc macOS, sans contournement local. La deadline stores est le 30/09/2026 (13 jours). Le Risk Register supposait un « device réel dès J3 » (R3) sans que ce device existe.
**Décision :** la V1.0 cible **Android uniquement** (Google Play). iOS bascule en **V1.1**, avec un Mac (achat d'occasion ou location cloud) à provisionner avant.
**Alternatives :** Mac mini d'occasion tout de suite (coût, délai de livraison, reste à apprendre Xcode et les App Groups en 13 jours) ; Mac cloud à l'heure (MacinCloud, Codemagic — faisable mais chaque itération sur la share extension passe par un build distant, incompatible avec « attaquée dès J3 sur device réel ») ; livrer les deux en repoussant la deadline (le Shipaton est daté).
**Conséquences :**
- PRD : F5 perd « Apple Sign-In obligatoire » en V1.0 (Google + e-mail suffisent sur Play) ; F7 reste P0 car Google Play l'exige aussi depuis 2024 pour toute app avec création de compte ; la contrainte « iOS 16+ » devient V1.1.
- Roadmap et Release Plan : étape 2 = share **Android** (`receive_sharing_intent`, Intent `ACTION_SEND`) ; critères GO ramenés à Play seul, 2 devices Android.
- Store Compliance : section Apple gelée, à reprendre en V1.1.
- Risk Register : R3 reformulé pour Android ; nouveau R10 (aucun moyen de builder iOS).
- Ce que la V1.1 devra rattraper : Apple Sign-In, App Groups pour l'extension, Privacy Nutrition Labels, IAP Apple via RevenueCat.
- Ce qui ne change pas : le backend, le pipeline IA, le design system, tout le code Flutter partagé.
