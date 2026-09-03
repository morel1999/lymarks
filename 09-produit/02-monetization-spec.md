# Monetization Spec — Lymarks (RevenueCat)

> **But :** produits, entitlements, enforcement. · **Statut :** vivant · **Màj :** 2026-08-07

## 1. Offres
| Plan | Contenu | Limites appliquées |
|---|---|---|
| **Free** | Capture + résumés IA, recherche mots-clés | 30 lymarks actifs (`archived=false`), pas de sémantique, pas de digest |
| **Pro** mensuel / annuel | Illimité, recherche sémantique, Daily Digest, export | — |

Prix ⚠️ à décider — proposition : 4,99 €/mois · 39,99 €/an (−33 %), à ajuster par territoire via les consoles. Essai gratuit ⚠️ à décider (proposition : 7 jours sur l'annuel uniquement).

## 2. RevenueCat
Entitlement unique **`pro`** ; offerings `default` (monthly, annual). App : `purchases_flutter`, login RevenueCat avec l'ID Clerk (`appUserID = clerk_id`) pour lier achats ↔ compte. « Restaurer mes achats » visible sur le paywall et dans les réglages (exigence Apple).

## 3. Enforcement — règle absolue
**La source de vérité des droits est la table `subscriptions`, alimentée par le webhook RevenueCat (signé, idempotent).** L'API vérifie le plan à chaque : création au-delà de 30 (`403 limit_reached`), recherche sémantique, inscription au digest, export. Le client ne fait qu'afficher — jamais décider (Threat Model M5).

## 4. Déclencheurs du paywall (UX Bible règle 11)
31ᵉ capture (après enregistrement, bandeau in-app — jamais dans la share sheet) · 1ʳᵉ recherche sémantique · activation du digest · écran réglages. Downgrade (expiration Pro) : rien n'est supprimé ; au-delà de 30 lymarks, lecture seule sur l'excédent + capture bloquée jusqu'à archivage ⚠️ à valider.
