# Lymarks --- Wireframes & Screen Architecture

> **Document:** UX wireframes --- V0\
> **Purpose:** définir l'architecture exacte des écrans avant adaptation
> au code\
> **Source de vérité visuelle :** Design System Lymarks existant\
> **Source de vérité fonctionnelle :** PRD Lymarks existant\
> **Source de vérité comportementale :** UX Bible Lymarks existant
>
> **Principe de travail :** les écrans sont conçus d'abord comme
> expérience cible. L'implémentation technique sera adaptée ensuite.

------------------------------------------------------------------------

# 0. Principes globaux

Lymarks n'est pas pensé comme un simple gestionnaire de bookmarks.

Le produit doit transformer :

**Capture → Compréhension → Retrouver → Redécouvrir**

L'expérience doit rester :

-   rapide ;
-   calme ;
-   lisible ;
-   peu frictionnelle ;
-   centrée sur la mémoire plutôt que sur l'organisation manuelle.

Le design system existant reste la base visuelle. Les interfaces de
référence servent uniquement à inspirer la composition et les
interactions, pas à remplacer les tokens, composants ou règles
existants.

------------------------------------------------------------------------

# Architecture des 7 écrans

  -----------------------------------------------------------------------
  \#                      Écran                   Intention principale
  ----------------------- ----------------------- -----------------------
  01                      Onboarding              Comprendre Lymarks

  02                      Home / Knowledge Hub    Voir et explorer sa
                                                  mémoire

  03                      Category Path           Parcourir une partie de
                                                  sa mémoire

  04                      Lymark Detail / Memory  Comprendre et conserver
                          Page                    le contexte

  05                      Search                  Retrouver rapidement
                                                  quelque chose

  06                      Daily Digest            Redécouvrir du contenu
                                                  au bon moment

  07                      Settings / Account      Gérer son compte et ses
                                                  préférences
  -----------------------------------------------------------------------

> Les bottom sheets, menus, états de traitement et confirmations sont
> considérés comme des **surfaces secondaires**, pas comme des écrans
> principaux supplémentaires.

------------------------------------------------------------------------

# 01 --- Onboarding

## Objectif

Faire comprendre Lymarks rapidement sans transformer l'onboarding en
tutoriel.

L'utilisateur doit comprendre :

1.  ses liens deviennent une mémoire ;
2.  la capture est rapide ;
3.  Lymarks comprend le contenu automatiquement.

## Structure

### 01A --- Promise

``` text
┌────────────────────────────────────┐
│                                    │
│  Lymarks                      Skip │
│                                    │
│                                    │
│                                    │
│          [ VISUEL LYMARKS ]        │
│                                    │
│       liens → mémoire →            │
│          retrouvaille              │
│                                    │
│                                    │
│  Turn forgotten links              │
│  into active memory.               │
│                                    │
│  Save what you discover.           │
│  Find it when you need it.         │
│                                    │
│  ┌──────────────────────────────┐  │
│  │         Get started          │  │
│  └──────────────────────────────┘  │
│                                    │
│                 ● ○                │
└────────────────────────────────────┘
```

### Hiérarchie

1.  Logo / identité
2.  Skip
3.  Visuel central
4.  Headline
5.  Supporting text
6.  CTA
7.  Pagination

### Message

**Headline**

> Turn forgotten links into active memory.

**Supporting text**

> Save what you discover.\
> Find it when you need it.

------------------------------------------------------------------------

## 01B --- Mechanism

``` text
┌────────────────────────────────────┐
│                                    │
│  Lymarks                      Skip │
│                                    │
│                                    │
│       ┌─────────┐                  │
│       │   URL   │                  │
│       │    ↗    │                  │
│       └────┬────┘                  │
│            │                       │
│            ▼                       │
│       ┌─────────┐                  │
│       │    ✦    │                  │
│       │   AI    │                  │
│       └────┬────┘                  │
│            │                       │
│            ▼                       │
│       ┌─────────┐                  │
│       │  3 key  │                  │
│       │  points │                  │
│       └─────────┘                  │
│                                    │
│  Save once.                        │
│  Lymarks remembers the context.    │
│                                    │
│  Capture → Understand → Rediscover │
│                                    │
│  ┌──────────────────────────────┐  │
│  │        Start saving          │  │
│  └──────────────────────────────┘  │
│                                    │
│                 ○ ●                │
└────────────────────────────────────┘
```

### Message

**Headline**

> Save once. Lymarks remembers the context.

**Supporting text**

> Capture → Understand → Rediscover

------------------------------------------------------------------------

## Onboarding --- décisions

-   2 écrans principaux.
-   Pas de longue présentation des fonctionnalités.
-   Pas de catégories, Digest ou Search pendant l'onboarding.
-   Pas de formulaire d'inscription directement dans les slides.
-   `Start saving` lance le parcours suivant.
-   L'authentification peut être une étape séparée.

### À garder ouvert

-   wording définitif ;
-   illustration / langage graphique ;
-   éventuel écran d'authentification après onboarding.

------------------------------------------------------------------------

# 02 --- Home / Knowledge Hub

## Objectif

Le Home doit répondre à deux questions :

> **Où se trouve ma mémoire ?**

et :

> **Qu'est-ce que j'ai récemment sauvegardé ?**

Le Home n'est donc pas simplement une liste de bookmarks.

------------------------------------------------------------------------

## Structure

``` text
┌────────────────────────────────────┐
│                                    │
│  Your knowledge                ◯   │
│                                    │
│  ┌──────────────────────────────┐  │
│  │                              │  │
│  │             AI               │  │
│  │                              │  │
│  │       Explore your AI        │  │
│  │          knowledge           │  │
│  │                              │  │
│  │       24 Lymarks        ↗    │  │
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────┐ ┌──────────┐ →       │
│  │ Design   │ │ Dev      │         │
│  │ 12       │ │ 18       │         │
│  └──────────┘ └──────────┘         │
│                                    │
│  All Lymarks               See all │
│                                    │
│  ┌──────────────────────────────┐  │
│  │        BookmarkCard         │  │
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │        BookmarkCard         │  │
│  └──────────────────────────────┘  │
│                                    │
├────────────────────────────────────┤
│       Home    Search    Digest     │
└────────────────────────────────────┘
```

------------------------------------------------------------------------

## Header

``` text
Your knowledge                              ◯
```

Le profil / compte est accessible depuis le coin supérieur droit.

------------------------------------------------------------------------

## Catégories

La catégorie principale est présentée sous forme de grande carte.

Exemple :

``` text
┌───────────────────────────────────┐
│                                   │
│  AI                               │
│                                   │
│  Explore your AI knowledge        │
│                                   │
│  24 Lymarks                  ↗    │
│                                   │
└───────────────────────────────────┘
```

Les autres catégories sont présentées horizontalement :

``` text
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Design    │  │ Development │  │  Business   │
│             │  │             │  │             │
│  12 Lymarks │  │ 18 Lymarks  │  │  7 Lymarks  │
│          ↗  │  │          ↗  │  │          ↗  │
└─────────────┘  └─────────────┘  └─────────────┘
```

**Interaction :** scroll horizontal.

------------------------------------------------------------------------

## Catégories et capture

L'utilisateur ne doit pas être obligé de choisir une catégorie pendant
la capture.

Principe :

> **Capture d'abord. Organisation intelligente ensuite.**

La catégorisation automatique est une évolution à formaliser dans le PRD
si elle est retenue dans le produit final.

------------------------------------------------------------------------

## All Lymarks

La section affiche les sauvegardes récentes dans l'ordre
antéchronologique.

Le `BookmarkCard` existant sert de base.

``` text
All Lymarks                              See all →

┌────────────────────────────────────┐
│ BookmarkCard                       │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ BookmarkCard                       │
└────────────────────────────────────┘
```

------------------------------------------------------------------------

## Navigation principale

``` text
Home        Search        Digest
  ●           ○             ○
```

Trois intentions principales :

-   **Home** → explorer ;
-   **Search** → retrouver ;
-   **Digest** → redécouvrir.

Les Settings restent accessibles depuis le compte.

------------------------------------------------------------------------

## Navigation vers Category Path

``` text
Home
  ↓
Category Path
```

La carte de catégorie doit pouvoir donner l'impression de se transformer
en entrée dans le parcours de connaissance.

------------------------------------------------------------------------

# 03 --- Category Path

## Objectif

L'utilisateur ne doit pas arriver sur une simple liste lorsqu'il
sélectionne une catégorie.

Il doit avoir l'impression d'entrer :

> **dans cette partie de sa mémoire.**

La catégorie devient un **chemin de connaissances**.

------------------------------------------------------------------------

## Structure

``` text
┌────────────────────────────────────┐
│                                    │
│  ←    AI                      ⋯   │
│                                    │
│       24 Lymarks                   │
│                                    │
│                 ●                  │
│                 │                  │
│        ┌────────────────┐          │
│        │   AI Agents    │          │
│        │                │          │
│        │   8 Lymarks ↗  │          │
│        └───────┬────────┘          │
│                │                   │
│                │                   │
│       ┌────────┘                   │
│       │                            │
│  ┌───────────────┐                 │
│  │      RAG      │                 │
│  │               │                 │
│  │  6 Lymarks ↗  │                 │
│  └───────┬───────┘                 │
│          │                         │
│          ●                         │
│          │                         │
│               ┌───────────────┐    │
│               │  Vector DB    │    │
│               │               │    │
│               │  4 Lymarks ↗  │    │
│               └───────────────┘    │
│                                    │
└────────────────────────────────────┘
```

------------------------------------------------------------------------

## Header

``` text
←    AI                                  ⋯
```

Sous le header :

> 24 Lymarks

------------------------------------------------------------------------

## Modèle mental

Le modèle logique peut être :

``` text
Category
   ↓
Clusters
   ↓
Lymarks
```

Exemple :

``` text
AI
│
├── AI Agents
│
├── RAG
│
├── Vector Databases
│
└── Machine Learning
```

Mais l'interface ne doit **pas** afficher un arbre complexe.

Le modèle interne devient un chemin visuel.

------------------------------------------------------------------------

## Forme du chemin

Le chemin est :

-   vertical ;
-   légèrement sinueux ;
-   composé de quelques nœuds/cartes ;
-   suffisamment espacé ;
-   scrollable.

Éviter :

-   mind map complexe ;
-   dizaines de connexions ;
-   graphes techniques ;
-   lignes dans toutes les directions.

Le chemin est une **métaphore visuelle**, pas un graphe scientifique.

------------------------------------------------------------------------

## Interaction

Tap sur un cluster :

``` text
Category Path
      ↓
Cluster / Lymarks
```

Le cluster affiche les Lymarks associés.

Exemple :

``` text
AI Agents

8 Lymarks

┌───────────────────────────┐
│ Building AI Agents       │
│ huggingface.co           │
└───────────────────────────┘

┌───────────────────────────┐
│ Agent memory patterns    │
│ article.com              │
└───────────────────────────┘

┌───────────────────────────┐
│ MCP for agents            │
│ website.com              │
└───────────────────────────┘
```

------------------------------------------------------------------------

## États

### Catégorie riche

Afficher plusieurs clusters.

### Catégorie peu remplie

Ne pas créer artificiellement plusieurs niveaux.

### Catégorie vide

Si les catégories manuelles existent :

> Nothing here yet.

> Save something related to this category to start building this path.

------------------------------------------------------------------------

## Navigation

Pas de navigation basse.

Le parcours est secondaire :

``` text
Home
 ↓
Category
 ↓
Cluster
 ↓
Lymark
```

Le bouton retour doit restaurer exactement le contexte précédent.

------------------------------------------------------------------------

## Point à formaliser

Le PRD actuel définit les embeddings et la recherche sémantique, mais le
système de clustering automatique doit être formalisé séparément si
cette fonctionnalité est retenue.

Le wireframe ne doit toutefois pas être bloqué par cette décision
technique.

------------------------------------------------------------------------

# 04 --- Lymark Detail / Memory Page

## Objectif

La fiche Lymark n'est pas une simple fiche de bookmark.

Elle doit restituer :

> **le contexte que l'utilisateur risque d'avoir oublié.**

Elle devient une véritable **Memory Page**.

------------------------------------------------------------------------

## Structure

``` text
┌────────────────────────────────────┐
│                                    │
│  ←                            ⋯    │
│                                    │
│  ○  huggingface.co                 │
│                                    │
│  Building AI Agents                │
│  Saved 2 days ago                  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │       SOURCE PREVIEW         │  │
│  │                              │  │
│  │        image / metadata      │  │
│  └──────────────────────────────┘  │
│                                    │
│  Remember this                     │
│                                    │
│  • First key point...              │
│  • Second key point...             │
│  • Third key point...              │
│                                    │
│  Your note                         │
│  This could be useful for...       │
│                                    │
│  AI     Agents     Development     │
│                                    │
│  Related Lymarks                   │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ MCP for AI Agents            │  │
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ Agent Memory Patterns        │  │
│  └──────────────────────────────┘  │
│                                    │
│  Explore related →                │
│                                    │
│  ┌──────────────────────────────┐  │
│  │       Open original ↗       │  │
│  └──────────────────────────────┘  │
│                                    │
└────────────────────────────────────┘
```

------------------------------------------------------------------------

## Header

``` text
←                                  ⋯
```

### Menu

Actions secondaires :

-   copier le lien ;
-   modifier la note ;
-   supprimer ;
-   éventuellement partager.

------------------------------------------------------------------------

## Source

``` text
○  huggingface.co

Building AI Agents

Saved 2 days ago
```

Afficher la source de manière identifiable sans exposer une URL
interminable.

------------------------------------------------------------------------

## Source Preview

Utiliser l'image OG / thumbnail lorsqu'elle existe.

Si elle n'existe pas :

-   placeholder ;
-   métadonnées disponibles ;
-   état `partial` si nécessaire.

------------------------------------------------------------------------

## Remember this

C'est le cœur de la page.

``` text
Remember this

• First key point...

• Second key point...

• Third key point...
```

Le résumé reste limité à **3 puces**.

Le terme « Remember this » est préféré à « AI Summary » parce que le
résumé est présenté comme un outil de mémoire et non comme une
fonctionnalité isolée.

------------------------------------------------------------------------

## Your Note

``` text
Your note

This could be useful for the agent system
I'm building.
```

Interaction :

``` text
Tap note
   ↓
Bottom Sheet
   ↓
Edit
   ↓
Save
```

Ne pas créer une page séparée uniquement pour modifier la note.

------------------------------------------------------------------------

## Tags

``` text
AI     Agents     Development
```

Les tags ne doivent pas être confondus avec le Category Path.

### Distinction

**Category / Path**

> organisation globale de la connaissance.

**Tags**

> description du contenu.

Exemple :

``` text
Category
AI

Path
AI → Agents → RAG

Tags
agents
LLM
tool-calling
architecture
```

------------------------------------------------------------------------

## Related Lymarks

Afficher un petit nombre de contenus liés.

Objectif :

``` text
Lymark
   ↓
Related Lymarks
   ↓
Category Path
   ↓
Autres Lymarks
```

Limiter la section à environ 3 résultats avant une éventuelle action :

> Explore related →

------------------------------------------------------------------------

## Open Original

CTA principal en bas :

``` text
┌──────────────────────────────────┐
│          Open original ↗         │
└──────────────────────────────────┘
```

L'implémentation navigateur in-app / externe reste une décision
technique à prendre ultérieurement.

------------------------------------------------------------------------

## États

### Processing

Skeleton + shimmer.

### Ready

Fiche complète.

### Partial

Afficher clairement une information de traitement partiel tout en
conservant les métadonnées disponibles.

### Failed

``` text
Couldn't process this link.

[ Try again ]
```

------------------------------------------------------------------------

# 05 --- Search

## Objectif

Search doit répondre à :

> « Je sais plus exactement quel était le lien, mais je sais ce que je
> cherche. »

Search est une expérience de **récupération**, pas d'exploration.

------------------------------------------------------------------------

## État initial

``` text
┌────────────────────────────────────┐
│                                    │
│  Search                        ×   │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ ✦  Search your memory...     │  │
│  └──────────────────────────────┘  │
│                                    │
│          Search your Lymarks       │
│                                    │
│     Find something you saved       │
│     without remembering the        │
│     exact words.                   │
│                                    │
│       Recent searches              │
│                                    │
│       AI agents                    │
│       React architecture           │
│       design systems               │
│                                    │
└────────────────────────────────────┘
```

Le champ de recherche est l'élément dominant.

Réutiliser `SearchField`.

------------------------------------------------------------------------

## Recherche active

Exemple :

``` text
┌────────────────────────────────────┐
│  Search                        ×   │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ react component architecture │  │
│  └──────────────────────────────┘  │
│                                    │
│  ✨ Semantic search                │
│                                    │
│  12 results                        │
│                                    │
│  ┌──────────────────────────────┐  │
│  │        BookmarkCard         │  │
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │        BookmarkCard         │  │
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```

------------------------------------------------------------------------

## Principe de recherche

Pas de choix manuel :

``` text
Keyword
   OU
Semantic
```

L'utilisateur ne doit pas sélectionner un mode.

La recherche sémantique doit apparaître comme une capacité naturelle du
produit.

------------------------------------------------------------------------

## Résultats

Réutiliser `BookmarkCard`.

Le résultat doit être suffisamment riche pour permettre à l'utilisateur
de reconnaître pourquoi le Lymark correspond à sa recherche.

------------------------------------------------------------------------

## Aucun filtre obligatoire

Ne pas afficher :

-   Category ;
-   Date ;
-   Source ;
-   Tags ;
-   syntaxe avancée.

Search doit rester un seul champ.

------------------------------------------------------------------------

## Navigation

``` text
Search
 ↓
Lymark Detail
 ↓
Back
 ↓
Search
```

La requête et la position doivent être conservées.

------------------------------------------------------------------------

## Aucun résultat

``` text
Search

┌────────────────────────────────┐
│ ancient AI architecture       │
└────────────────────────────────┘


Nothing surfaced yet.

Try describing what you remember
rather than searching exact words.
```

Le wording devra être adapté au niveau de recherche disponible pour
l'utilisateur.

------------------------------------------------------------------------

## Paywall

La recherche sémantique Pro peut déclencher le `PaywallSheet`.

Principe :

``` text
Search
   ↓
PaywallSheet
```

Le Search reste visible derrière le bottom sheet.

Ne pas remplacer brutalement l'écran.

------------------------------------------------------------------------

# 06 --- Daily Digest

## Objectif

Le Digest est différent de Search.

Search répond :

> **Je cherche quelque chose.**

Digest répond :

> **Lymarks me rappelle quelque chose au bon moment.**

Le Daily Digest est donc la fonctionnalité qui ferme la boucle de
mémoire.

------------------------------------------------------------------------

# État principal

``` text
┌────────────────────────────────────┐
│                                    │
│  Daily Digest                 ⋯   │
│                                    │
│  Tuesday, August 25                │
│                                    │
│  A few things worth revisiting     │
│                                    │
│  ┌──────────────────────────────┐  │
│  │                              │  │
│  │  Building AI Agents          │  │
│  │                              │  │
│  │  Saved 12 days ago           │  │
│  │                              │  │
│  │  • Key point...              │  │
│  │  • Key point...              │  │
│  │  • Key point...              │  │
│  │                              │  │
│  │       Open Lymark ↗          │  │
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │                              │  │
│  │  React Architecture          │  │
│  │                              │  │
│  │  Saved 21 days ago           │  │
│  │                              │  │
│  │       Open Lymark ↗          │  │
│  └──────────────────────────────┘  │
│                                    │
├────────────────────────────────────┤
│       Home    Search    Digest     │
└────────────────────────────────────┘
```

------------------------------------------------------------------------

## Header

``` text
Daily Digest                              ⋯
```

Date :

> Tuesday, August 25

Puis :

> A few things worth revisiting

Le ton doit être éditorial et calme.

------------------------------------------------------------------------

## Contenu

Le Digest ne doit pas devenir une deuxième Home.

Chaque élément doit répondre à :

> Pourquoi est-ce que Lymarks me montre ça aujourd'hui ?

La logique de sélection doit pouvoir prendre en compte :

-   ancienneté ;
-   intérêt ;
-   pertinence ;
-   possibilité de redécouverte.

Les règles exactes de sélection sont à formaliser dans le PRD si elles
ne sont pas déjà présentes dans les documents complets.

------------------------------------------------------------------------

## Digest Card

On peut réutiliser `DigestCard` du Design System.

Structure :

``` text
┌────────────────────────────────────┐
│ Building AI Agents                │
│                                    │
│ Saved 12 days ago                  │
│                                    │
│ • First key point...              │
│ • Second key point...             │
│ • Third key point...              │
│                                    │
│ Open Lymark ↗                     │
└────────────────────────────────────┘
```

------------------------------------------------------------------------

## Interaction

Tap :

``` text
Digest Card
    ↓
Memory Page
```

Le retour doit restaurer le Digest.

------------------------------------------------------------------------

## Empty state

Il ne faut jamais présenter un Digest artificiel.

Si rien n'est pertinent :

``` text
Nothing to revisit yet.

Keep saving things.
We'll bring something back
when it matters.
```

Le message doit rester positif et non culpabilisant.

------------------------------------------------------------------------

## Pro / Free

Si le Digest est une fonctionnalité Pro, le paywall doit rester cohérent
avec le principe des bottom sheets existants.

Si le Digest fait partie du périmètre Free, cette distinction devra être
précisée dans le PRD final.

Ne pas inventer la règle tarifaire pendant le wireframing.

------------------------------------------------------------------------

## Navigation

``` text
Home        Search        Digest
  ○           ○             ●
```

------------------------------------------------------------------------

# 07 --- Settings / Account

## Objectif

Settings doit rester une zone utilitaire.

Elle ne doit pas devenir une deuxième application.

Le compte, les préférences et la gestion du plan doivent être regroupés
dans une structure simple.

------------------------------------------------------------------------

# Structure

``` text
┌────────────────────────────────────┐
│                                    │
│  ←       Settings                  │
│                                    │
│  ACCOUNT                            │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ ○                             │  │
│  │   Morel                       │  │
│  │   email@example.com           │  │
│  │                         →     │  │
│  └──────────────────────────────┘  │
│                                    │
│  PLAN                               │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ Free                         │  │
│  │                              │  │
│  │ Upgrade to Pro          →    │  │
│  └──────────────────────────────┘  │
│                                    │
│  PREFERENCES                        │
│                                    │
│  Daily Digest                  →   │
│  Appearance                    →   │
│  Notifications                →   │
│                                    │
│  DATA                                │
│                                    │
│  Export my data                 →  │
│  Delete account                →   │
│                                    │
│  ABOUT                               │
│                                    │
│  Privacy policy                →   │
│  Terms of service              →   │
│  About Lymarks                 →   │
│                                    │
│  Log out                            │
│                                    │
└────────────────────────────────────┘
```

------------------------------------------------------------------------

## Account

Afficher :

-   avatar ;
-   nom ;
-   adresse e-mail.

Tap :

``` text
Account
 ↓
Account details
```

La page de détails peut rester une sous-page utilitaire et n'est pas
comptée comme écran principal.

------------------------------------------------------------------------

## Plan

``` text
Free

Upgrade to Pro →
```

Le CTA ouvre le `PaywallSheet`.

Ne pas créer un dashboard financier.

------------------------------------------------------------------------

## Preferences

### Daily Digest

Permettre :

-   activer / désactiver ;
-   éventuellement définir l'heure ;
-   éventuellement contrôler la fréquence si cette option existe dans le
    produit final.

### Appearance

-   Light
-   Dark
-   System

### Notifications

Réglages liés aux notifications.

------------------------------------------------------------------------

## Data

### Export

Action permettant de demander l'export des données selon le périmètre
défini par le produit.

### Delete account

Action destructive.

Elle doit utiliser une confirmation explicite et ne doit jamais être
accessible via une simple action accidentelle.

------------------------------------------------------------------------

## About

Informations légales et produit.

------------------------------------------------------------------------

# 8. Surfaces secondaires

Ces éléments ne sont pas comptés comme les 7 écrans principaux, mais
doivent être conçus ensuite avec le même niveau de précision.

## Share Sheet

Flux principal :

``` text
External app
   ↓
Native Share
   ↓
Lymarks
   ↓
ShareSheetView
   ↓
Save
   ↓
Lymarks processing
```

Le principe fondamental reste :

-   aucune catégorie obligatoire ;
-   aucune décision obligatoire ;
-   note optionnelle ;
-   fermeture immédiate après sauvegarde.

------------------------------------------------------------------------

## Note Bottom Sheet

``` text
Lymark Detail
   ↓
Tap Your Note
   ↓
Bottom Sheet
   ↓
Text input
   ↓
Save
```

------------------------------------------------------------------------

## Paywall Bottom Sheet

Utilisé notamment pour les fonctionnalités Pro.

``` text
Feature
   ↓
PaywallSheet
   ↓
Upgrade
```

Le contexte de l'écran d'origine doit rester visible derrière le sheet.

------------------------------------------------------------------------

## Delete Confirmation

Pour les actions destructives :

``` text
Delete Lymark?

This can't be undone.

Cancel        Delete
```

Le bouton destructif doit être clairement distingué.

------------------------------------------------------------------------

# 9. Navigation globale

Architecture principale :

``` text
                         ┌──────────────┐
                         │     Home     │
                         └──────┬───────┘
                                │
              ┌─────────────────┼──────────────────┐
              │                 │                   │
              ▼                 ▼                   ▼
        Category Path         Search             Digest
              │                 │                   │
              │                 │                   │
              └────────────┬────┴──────────────┬────┘
                           ▼                   ▼
                    Lymark Detail         Lymark Detail
                           │
                           ▼
                    Open Original
```

Settings reste accessible depuis le profil :

``` text
Home
 ↓
Profile / Account
 ↓
Settings
```

------------------------------------------------------------------------

# 10. Architecture mentale du produit

Les écrans doivent rester différenciés par leur intention.

## Home

> **What do I have?**

Vue de collection.

## Category Path

> **How is it connected?**

Vue de parcours.

## Lymark Detail

> **What should I remember?**

Vue de compréhension.

## Search

> **Where is what I'm looking for?**

Vue de récupération.

## Digest

> **What should I rediscover today?**

Vue de redécouverte.

## Settings

> **How do I manage Lymarks?**

Vue utilitaire.

------------------------------------------------------------------------

# 11. Design System --- règle de travail

Le Design System Lymarks existant reste la base.

Les composants existants doivent être réutilisés lorsque leur rôle
correspond :

-   `BookmarkCard`
-   `DigestCard`
-   `SearchField`
-   `PaywallSheet`
-   `ShareSheetView`
-   tokens de couleur ;
-   typographie ;
-   espacements ;
-   rayons ;
-   animations ;
-   Light / Dark mode.

Les nouveaux écrans ne doivent donc pas entraîner automatiquement la
création de nouveaux composants visuels.

La priorité est :

1.  réutiliser ;
2.  adapter ;
3.  seulement ensuite créer.

------------------------------------------------------------------------

# 12. Ce qui doit être ajouté au PRD après validation des écrans

Les wireframes introduisent plusieurs concepts qui devront être vérifiés
contre les autres documents du projet.

## Category Path

À formaliser si confirmé :

-   définition d'un cluster ;
-   génération des clusters ;
-   relation entre catégorie et cluster ;
-   comportement d'un nouveau Lymark ;
-   recalcul des relations ;
-   affichage des Lymarks associés.

## Related Lymarks

À préciser :

-   nombre maximum ;
-   logique de similarité ;
-   relation avec les embeddings ;
-   navigation vers le Category Path.

## Daily Digest

À préciser :

-   algorithme de sélection ;
-   fréquence ;
-   critères de redécouverte ;
-   comportement lorsqu'il n'y a rien de pertinent ;
-   disponibilité Free / Pro.

## Search

À préciser :

-   comportement exact Free ;
-   comportement exact Pro ;
-   recherche hybride ;
-   déclenchement du paywall ;
-   conservation de l'état de recherche.

## Categories

À préciser :

-   catégories automatiques ;
-   catégories manuelles éventuelles ;
-   nombre maximum ;
-   fusion / renommage ;
-   relation avec les tags.

------------------------------------------------------------------------

# 13. Ordre de conception après les wireframes

Les écrans sont maintenant suffisamment définis pour passer à l'étape
suivante :

### Phase 1 --- Wireframes

**01 → 07**

Terminé.

### Phase 2 --- Design UI

Pour chaque écran :

-   appliquer le Design System ;
-   définir les tailles exactes ;
-   définir les espacements ;
-   définir les composants ;
-   définir les états ;
-   définir les interactions ;
-   définir Light / Dark.

### Phase 3 --- Prototype

Créer le parcours :

``` text
Onboarding
    ↓
Home
    ↓
Category Path
    ↓
Lymark Detail
    ↓
Search
    ↓
Digest
    ↓
Settings
```

avec les transitions principales.

### Phase 4 --- Adaptation au code

Comparer les écrans avec :

-   architecture existante ;
-   composants actuels ;
-   modèles de données ;
-   routes ;
-   logique backend ;
-   contraintes Flutter ;
-   performances.

Puis décider :

**à conserver / modifier / créer / reporter.**

------------------------------------------------------------------------

# 14. Principe final

Ne pas concevoir les écrans comme des pages indépendantes.

Lymarks doit être perçu comme une seule boucle :

``` text
                 CAPTURE
                    │
                    ▼
              ┌───────────┐
              │   HOME    │
              └─────┬─────┘
                    │
             ┌──────┴──────┐
             ▼             ▼
          CATEGORY       SEARCH
             │             │
             └──────┬──────┘
                    ▼
              LYMARK DETAIL
                    │
             ┌──────┴──────┐
             ▼             ▼
          RELATED        DIGEST
             │             │
             └──────┬──────┘
                    ▼
               REDISCOVER
```

**La promesse de Lymarks n'est pas de stocker davantage.**

La promesse est de faire en sorte que ce que l'utilisateur a déjà
découvert **reste utile plus tard**.

------------------------------------------------------------------------

## Statut

**Wireframes V0 --- 7 écrans définis.**

Les wireframes sont volontairement indépendants des détails
d'implémentation.

Les éléments encore ouverts devront être résolus lors de la
confrontation avec le PRD complet et les autres documents du projet
avant de passer au design UI final.
