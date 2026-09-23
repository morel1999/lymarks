# Script de la vidéo — 1 min 50

Sous les deux minutes exigées, avec de la marge. Le billet officiel
« How we judge Shipaton » dit ce que les deux premières minutes doivent
contenir : **le pitch, l'app en marche, et les catégories visées avec leur
raison**. Les trois y sont, dans cet ordre.

Il dit aussi : *« Production quality doesn't matter — clarity does. »* Pas de
montage à faire. Une capture d'écran du téléphone, une voix par-dessus.

---

## Avant de filmer

**Prépare ta bibliothèque.** Le haut de ta Home sera à l'écran pendant vingt
secondes. Aujourd'hui elle s'ouvre sur des posts Instagram avec des noms de
personnes : c'est la vie privée de tiers, et le règlement demande d'éviter les
marques tierces. Enregistre trois ou quatre liens neutres juste avant — une doc
Flutter, un billet de blog, un article technique — pour qu'ils soient en tête.

**Coupe les notifications.** Mode Ne pas déranger. Une bannière WhatsApp au
milieu d'un plan, c'est le plan à refaire.

**Charge le téléphone.** L'enregistreur d'écran de HyperOS et un build profile
consomment ; tu étais à 8 % hier soir.

**Répète la séquence d'achat une fois** — mais sache que le passage à Pro est
définitif côté serveur tant que l'abonnement Test Store n'a pas expiré. Tes deux
lymarks verrouillés s'ouvriront. **Filme ce plan-là en premier, ou accepte de ne
l'avoir qu'en une prise.**

**Si ton anglais parlé te gêne** : filme muet et ajoute des cartons de texte. Le
jury note la clarté, pas l'accent. Le texte à l'écran marche aussi bien.

---

## 0:00 – 0:12 · L'accroche

**À l'écran** — tu tapes sur l'icône Lymarks. L'écran d'ouverture, la mascotte,
puis la Home.

**Voix**

> You don't need to remember the link. You only need to remember what you were
> looking for.
>
> I'm entering Lymarks in **Next Gen** — I'm a student, there's no paid developer
> account behind this, so the repository is the submission.

*Pourquoi commencer par là : le présélectionneur ne regarde que le début. Le
slogan dit le produit en une phrase, et la catégorie est annoncée tout de suite.*

---

## 0:12 – 0:32 · La capture

**À l'écran** — tu quittes Lymarks, tu ouvres un navigateur sur un article, tu
partages → Lymarks. La feuille apparaît, tu valides, elle disparaît. Retour à
Lymarks : la carte est là, en cours de traitement, puis elle se remplit.

**Voix**

> I save links all day and never open them again. So this is the whole
> interaction: share, done. Two seconds.
>
> Behind that, Lymarks fetches the page, and a model writes three bullets and
> files it under a category. The card fills itself while I've already moved on.

*Ne commente pas l'attente. Si le pipeline met dix secondes, coupe — c'est le
seul montage nécessaire de toute la vidéo.*

---

## 0:32 – 0:52 · Le rappel

**À l'écran** — onglet Search. Tu tapes une phrase approximative, pas les mots
exacts du titre. Les résultats sortent. Tu ouvres une fiche : les trois puces, la
note, les liens voisins.

**Voix**

> Months later, I don't remember the title or the site. I only remember what I
> was after. So I describe it — and it comes back.
>
> This is the part every bookmarking app misses. They solve storage. None of them
> solves recall.

---

## 0:52 – 1:18 · Le plan gratuit, et RevenueCat

**À l'écran** — tu fais défiler la Home jusqu'aux lymarks verrouillés : les
cartes floutées, la mascotte endormie, « 2 lymarks are waiting for you ». Tu
tapes « Unlock with Pro ». Le paywall s'ouvre. Tu achètes. Les cartes s'ouvrent.

**Voix**

> Here's the part I'd most like judged, and it's why I'm also entering the
> **HAMM award** for monetization.
>
> The obvious free plan refuses you past its limit. I shipped that first — then I
> tested it on a real phone and saw how bad it is. You keep sharing links, none of
> them arrive, and you don't find out until you open the app. The product quietly
> loses your data to protect its own pricing.
>
> So the limit changed nature. Past thirty, the link is still saved. It just
> arrives locked — there, blurred, with a line that says nothing is lost.
>
> The RevenueCat webhook confirms the entitlement, and every locked link unlocks
> at once — and the AI pipeline runs on all of them. You don't get an empty Pro.
> You get your own backlog, summarised.
>
> The upgrade isn't a gate you hit. It's a key to something you already own.

*C'est le cœur de la vidéo. Si un plan doit être soigné, c'est celui-là.*

---

## 1:18 – 1:32 · Sans réseau

**À l'écran** — tu tues l'app, tu actives le mode avion, tu la rouvres. Elle
s'ouvre, ta bibliothèque est là, le bandeau jaune l'explique. Tu fais une
recherche : elle répond.

**Voix**

> And it works on the metro. The library is on the device, search falls back to
> the phone, and a banner tells you what you're looking at instead of pretending
> everything is fine.

---

## 1:32 – 1:50 · La fermeture

**À l'écran** — le dépôt GitHub, puis `flutter run` qui démarre l'app en mode
démo.

**Voix**

> Everything is open source. Clone it, run it — with no API keys it boots into a
> full demo mode with no network calls at all. That's not a mock built for
> judges: it's the same code path the tests run against.
>
> Lymarks. You only need to remember what you were looking for.

---

## Ce qu'il ne faut pas faire

- **Ne pas lister les technos à l'oral.** Elles sont dans la description. Vingt
  secondes de stack, c'est vingt secondes sans l'app à l'écran.
- **Ne pas s'excuser** de ce qui n'est pas fait. C'est écrit dans le README, à sa
  place. La vidéo montre ce qui marche.
- **Ne pas viser d'autres catégories** que les deux annoncées. Le billet du jury
  prévient explicitement contre l'entrée qui se force dans toutes les cases.
- **Pas de musique.** Le règlement interdit le matériel sous droits, et une voix
  seule est plus claire.

## Après

Publie sur **YouTube ou Vimeo**, en **public** — le règlement l'exige, un fichier
joint ne compte pas. Titre : `Lymarks — Shipaton 2026 (Next Gen)`. Colle le lien
dans Devpost, et vérifie que le formulaire t'a bien reconnu comme Next Gen : le
tri automatique élimine les entrées sans lien de store, et c'est précisément ce
que cette catégorie te dispense de fournir.
