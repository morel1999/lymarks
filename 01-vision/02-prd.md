# PRD — Lymarks

> **But :** décrire précisément fonctionnalités, comportements, flux et priorités. · **Statut :** vivant · **Màj :** 2026-08-07

Priorités : **P0** = indispensable V1.0 (Shipaton) · **P1** = V1.0 si le temps le permet, sinon V1.1 · **P2** = post-lancement.

## 1. Fonctionnalités

### P0 — Cœur
| # | Fonctionnalité | Comportement attendu |
|---|---|---|
| F1 | Capture via menu de partage | Depuis toute app (X, Safari, Chrome, YouTube, LinkedIn) : Partager → Lymarks ouvre une fenêtre native légère. Champ note optionnel. Bouton **Enregistrer**. Fermeture immédiate ; traitement en arrière-plan. Cible : <2 s tap→fermeture. |
| F2 | Pipeline IA | Backend : extraction du texte de la page → résumé en 3 puces + mots-clés (Groq Llama 3.3) → embedding (Gemini) → stockage Neon. Cible <15 s. L'utilisateur n'attend jamais ce pipeline. |
| F3 | Liste des lymarks | Tri antéchronologique. Carte : titre, favicon/source, 3 puces, note perso, tags. États : `processing` (squelette animé), `ready`, `partial`, `failed` (bouton réessayer). |
| F4 | Recherche mots-clés (Free) | Recherche plein texte (titre, note, résumé, tags). Résultats <500 ms. |
| F5 | Auth | Clerk : Google / Apple / e-mail. Apple Sign-In obligatoire sur iOS dès qu'un login social est proposé. |
| F6 | Freemium + Paywall | Limite Free : 30 lymarks. Paywall RevenueCat déclenché au 31ᵉ enregistrement et à la 1ʳᵉ recherche sémantique. Enforcement **côté serveur** (voir `../09-produit/02-monetization-spec.md`). |
| F7 | Suppression de compte in-app | Obligatoire Apple. Supprime tout (voir Privacy Spec). |

### P1
| # | Fonctionnalité | Comportement |
|---|---|---|
| F8 | Recherche sémantique (Pro) | Requête en langage naturel → embedding → similarité cosinus pgvector → résultats fusionnés avec le plein texte. |
| F9 | Smart Daily Digest (Pro) | 1 notification push/jour max, heure configurable (défaut 8h30 locale) : « 1 lien oublié » choisi par l'algorithme de re-surfaçage (voir `../05-data/01-knowledge-vault-spec.md`). Opt-out en 1 geste. |
| F10 | Export de données (Pro) | Export JSON complet depuis les réglages. ⚠️ À décider : la portabilité RGPD peut imposer un export même en Free (voir Privacy Spec §6). |
| F11 | Dictée de la note | Via la dictée clavier native (aucun dev spécifique ; à vérifier dans la share sheet iOS). |

### P2
Résolution de conflits hors-ligne pour la sync multi-appareils (le cloud donne déjà la sync de base), widgets home-screen, tags manuels éditables, collections/projets, app web.

## 2. Flux utilisateur principaux
1. **Capture :** app source → Partager → Lymarks → [note optionnelle] → Enregistrer → retour app source. Aucune étape supplémentaire, jamais.
2. **Retrouver :** ouvrir l'app → champ recherche → requête en langage naturel → ouvrir le lien. ⚠️ À décider : navigateur in-app (Custom Tabs / SFSafariViewController — proposé) ou externe.
3. **Digest :** notification 8h30 → tap → fiche du lymark → lire / reporter / archiver.
4. **Upgrade :** heurter une limite → paywall → achat → déblocage immédiat (entitlement `pro`).

## 3. Cas limites et comportements
- **Page inaccessible au scraping** (paywall presse, X sans login, page 100 % JS) : fallback = titre + balises OG uniquement, statut `partial`, résumé sur métadonnées ; jamais d'échec silencieux.
- **Vidéo YouTube :** V1.0 = titre + description. ⚠️ À décider : transcript en V1.1.
- **Doublon d'URL (même utilisateur) :** incrément de `saved_count` + mise à jour de la note ; pas de doublon en base.
- **Hors-ligne à la capture :** file d'attente locale, envoi au retour du réseau ; l'UX de capture reste identique.
- **Contenu de page malveillant :** le texte scrapé est traité comme non fiable (anti-injection, voir Threat Model M2).

## 4. Contraintes
- Deadline stores : publication avant le **30/09/2026**.
- Développeur solo, sprint 14 jours : tout P0 doit être atteignable seul.
- Coût IA par lymark maîtrisé (voir `../06-ia/01-ai-architecture.md` §Coûts).
- iOS 16+ / Android 10+ ⚠️ à confirmer selon les contraintes de `receive_sharing_intent`.

## 5. Hors périmètre V1.0 (explicite)
Web clipper desktop, collaboration/partage de collections, import Pocket/Instapaper, mode équipe.
