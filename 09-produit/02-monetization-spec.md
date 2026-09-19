# Monetization Spec — Lymarks (RevenueCat)

> **But :** produits, entitlements, enforcement. · **Statut :** vivant · **Màj :** 2026-09-19

## 1. Offres
| Plan | Contenu | Limites appliquées |
|---|---|---|
| **Free** | Capture + résumés IA, recherche mots-clés | 30 lymarks actifs (`archived=false`), pas de sémantique, pas de digest |
| **Pro** mensuel / annuel | Illimité, recherche sémantique, Daily Digest, export | — |

Prix ⚠️ à décider — proposition : 4,99 €/mois · 39,99 €/an (−33 %), à ajuster par territoire via les consoles. Essai gratuit ⚠️ à décider (proposition : 7 jours sur l'annuel uniquement).

## 2. RevenueCat
Entitlement unique **`pro`** ; offerings `default` (monthly, annual). App : `purchases_flutter`, login RevenueCat avec l'ID Clerk (`appUserID = clerk_id`) pour lier achats ↔ compte. « Restaurer mes achats » visible sur le paywall et dans les réglages (exigence Apple).

### Configuration effective (19/09, branchée dans le code)
| Objet | Valeur | Où c'est lu |
|---|---|---|
| Entitlement | `pro` | `RevenueCatBilling.proEntitlement` ; webhook `entitlement_ids` |
| Offering courante | `default` (« current ») | `Purchases.getOfferings().current` |
| Packages | `$rc_monthly` → mensuel, `$rc_annual` → annuel (types standard RevenueCat ; tout autre package est ignoré) | `RevenueCatBilling.offer()` |
| Produits (Test Store) | `lymarks_pro_monthly` (P1M), `lymarks_pro_annual` (P1Y) | RevenueCat seulement — l'app ne connaît que les packages |
| Clé SDK | `--dart-define=REVENUECAT_API_KEY` (GitHub Secret, clé publique du SDK) | `AppConfig.revenuecatApiKey` |
| Webhook | `POST https://lymarks-api…/webhooks/revenuecat`, en-tête `Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>` (secret Workers) | `api/src/routes/webhooks.ts` |

**Chemin Shipaton Next Gen : le Test Store.** Sans compte développeur Play, RevenueCat fournit une app de type *Test Store* : le SDK, configuré avec sa clé, affiche une feuille d'achat simulée (réussir / échouer / annuler), les abonnements se renouvellent en accéléré (5 renouvellements, puis annulation) et **les webhooks partent comme en production** (`environment: SANDBOX`). Passer à Google Play plus tard = créer l'app Play dans RevenueCat, y rattacher les mêmes produits/entitlement/offering, changer la clé au build. Le code ne bouge pas.

**Côté app** (`app/lib/core/billing/`) : `Billing` est le contrat (offre, achat, restauration, identité) ; `RevenueCatBilling` l'implémente, `NoBilling` sert la démo et les tests ; `BillingLink` suit la session Clerk (`identify` à la connexion, `forget` à la déconnexion). Après un achat confirmé par le store, `ProfileNotifier` affiche Pro immédiatement et relit `GET /me` (1, 2, 4, 8 s) jusqu'à ce que le webhook ait posé le droit côté serveur — l'app n'attend jamais, ne décide jamais.

## 3. Enforcement — règle absolue
**La source de vérité des droits est la table `subscriptions`, alimentée par le webhook RevenueCat (signé, idempotent).** L'API vérifie le plan à chaque : création au-delà de 30 (`403 limit_reached`), recherche sémantique, inscription au digest, export. Le client ne fait qu'afficher — jamais décider (Threat Model M5).

## 4. Déclencheurs du paywall (UX Bible règle 11)
31ᵉ capture (après enregistrement, bandeau in-app — jamais dans la share sheet) · 1ʳᵉ recherche sémantique · activation du digest · écran réglages. Downgrade (expiration Pro) : rien n'est supprimé ; au-delà de 30 lymarks, lecture seule sur l'excédent + capture bloquée jusqu'à archivage ⚠️ à valider.
