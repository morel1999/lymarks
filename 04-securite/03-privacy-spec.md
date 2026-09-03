# Privacy Specification — Lymarks

> **But :** quelles données, où, combien de temps, et comment tout supprimer. · **Statut :** vivant · **Màj :** 2026-08-07

## 1. Données collectées
| Donnée | Pourquoi | Où |
|---|---|---|
| Identité (e-mail, nom, ID OAuth) | Compte | Clerk |
| URL, titre, contenu extrait (temporaire), note perso | Cœur du service | Neon (contenu extrait non conservé après résumé ⚠️ confirmé : on garde uniquement titre+puces+keywords) |
| Résumés, mots-clés, embeddings | Recherche/digest | Neon |
| Token push, fuseau, heure de digest | Digest | Neon |
| Statut d'abonnement | Droits Pro | RevenueCat + Neon |

Aucune collecte analytics tierce en V1.0 (⚠️ à décider si ajout : consentement + mise à jour des privacy labels).

## 2. Ce qui part vers des tiers
- **Groq** : texte extrait de la page (pas la note perso ⚠️ décision : la note n'est PAS envoyée au LLM, elle est purement locale à la fiche).
- **Gemini** : titre + puces (+ requêtes de recherche Pro) pour vectorisation.
- **Clerk / RevenueCat** : identité / achats, respectivement.
Aucune donnée vendue, aucun profilage publicitaire.

## 3. Ce qui reste local (device)
File d'attente hors-ligne, préférences UI, cache d'affichage. Tout le reste est serveur (la sync multi-appareils en découle).

## 4. Rétention
Données de compte et lymarks : conservés tant que le compte existe. Logs API : 7 jours, sans corps de requêtes. Événements digest : 90 jours (réglage de l'algorithme).

## 5. Suppression et portabilité
- **Suppression de compte in-app** (exigence Apple) : purge Neon (bookmarks, embeddings, digests, subscriptions) + suppression Clerk + delete RevenueCat subscriber. Effet ≤ 30 jours, immédiat pour l'accès.
- **Export JSON** : url, note, résumé, tags, dates. Prévu Pro. ⚠️ À décider : le RGPD (art. 20) impose la portabilité aussi en Free → proposition : export disponible pour tous, mis en avant en Pro.
- Suppression unitaire d'un lymark : efface aussi son embedding et ses événements digest.

## 6. Conformité
RGPD (UE) / KVKK (Turquie) : base légale = exécution du contrat ; digest = traitement basé sur le profil d'intérêts → activable/désactivable librement. Privacy labels App Store et Data Safety Play remplis d'après ce document (voir Store Compliance).
