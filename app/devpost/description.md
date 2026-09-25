# Lymarks — Devpost submission text

Texte prêt à coller dans le formulaire Devpost. En anglais : c'est la langue du
jury. Les titres suivent les champs habituels du formulaire.

**Une section est à toi** : « Inspiration ». J'ai écrit une version qui tient
debout, mais la genèse est la tienne — le jury note l'histoire avant la
technique, et une phrase vraie de toi vaudra mieux que trois de moi.

**Ce que le règlement de notation exige** et qui est déjà en place ici : dire
quelles catégories tu vises et pourquoi. Même chose à l'oral dans les deux
premières minutes de la vidéo.

---

## Tagline

> **You don't need to remember the link. You only need to remember what you were
> looking for.**

*(Version française, si le formulaire le permet : « Vous n'avez pas besoin de vous
souvenir du lien. Vous devez seulement vous souvenir de ce que vous cherchiez. »)*

## Categories I'm entering, and why

**Next Gen** — I'm a student, there's no paid developer account behind this. The
whole app runs from source, and the repository is the submission.

**HAMM Award** (smartest monetization) — because the interesting thing I built
this month isn't a feature, it's what the free plan does when you hit its limit.
See the monetization section below; it's the part I'd most like judged.

That's two. The app could be argued into others and I'd rather not: the design
is good, but it isn't a design product.

## Inspiration

I save links all day. A thread I want to reread, a tool someone mentioned, an
article I'll need "later". Later never comes — and when it finally does, I can't
find the thing, because I've forgotten its title, the site it was on, and the
exact words it used.

Every bookmarking app I tried solves **storage**. None of them solves **recall**.
That's the whole idea of Lymarks: a saved link is worthless until you can find it
again on a day when you remember nothing about it but a vague shape.

So the app is built around one promise: **you don't need to remember the link. You
only need to remember what you were looking for.**

## What it does

You share a link from any app. That's the entire interaction — one tap, no form,
no folder to pick. Two seconds later the sheet is gone and you're back where you
were.

Behind that, Lymarks fetches the page, extracts the text, and asks a model for
**three bullets and a category**. The card fills itself while you've already
moved on. From then on the link is findable by what it *said*, not by what it was
called — including semantic search, where you describe what you half-remember and
it surfaces anyway.

Some pages refuse a server. When that happens the **phone reads the page itself**
and hands the text back to the same pipeline, so a site that blocks robots still
ends up in your memory.

And it works without a network: the library lives on the device, search falls back
to full text locally, and a banner says plainly that you're looking at the last
sync instead of pretending everything is fine.

## Monetization: what the free plan does instead of refusing

This is the part I'd most like judged.

The obvious free-plan design is a limit that **refuses**: past 30 links, the
capture fails. I shipped that first. Then I tested it on a real phone and saw how
bad it is — you keep sharing links from other apps, none of them arrive, and you
don't find out until you next open the app. The product quietly loses your data
to protect its own pricing.

So the limit changed nature. Past 30, the link is still **saved**. It just arrives
locked: there in your library, blurred, with the mascot asleep beside a line that
says *"We saved every link you sent. Nothing is lost."* No model call is spent on
a locked link, so the free tier still costs nothing to run. The moment the
RevenueCat webhook confirms the entitlement, every locked link unlocks **and the
pipeline runs on all of them at once** — you don't get an empty Pro, you get your
own backlog, summarised.

The upgrade isn't a gate you hit. It's a key to something you already own.

RevenueCat carries that whole flow: offerings drive the paywall prices, the
`appUserID` is the Clerk user id, and the entitlement is confirmed **server side**
by the webhook. The app never decides on its own that you're Pro — the store
confirms the payment, the server decides the right.

## How I built it

```
Flutter app ──► Cloudflare Worker API ──► Neon Postgres (pgvector + full-text)
                        │
                        ├─► Groq → Gemini Flash   summary, 3 bullets, category
                        ├─► Gemini                embeddings for semantic search
                        ├─► Clerk                 identity
                        └─► RevenueCat webhook    entitlements
```

Flutter and Riverpod on the client, Hono on Cloudflare Workers for the API, Neon
Postgres with pgvector and a generated tsvector column for hybrid search. Page
fetching is SSRF-guarded, with DNS resolved over DoH before every request *and*
every redirect.

Everything is optimistic first: each gesture changes the local list immediately
and reconciles with the server afterwards. Deleting is reversible for five
seconds, and the real purge only leaves once the undo window closes.

## See it in one minute, with no keys

```
git clone https://github.com/morel1999/lymarks.git && cd lymarks/app
flutter run
```

With no API keys the app boots in **demo mode**: a full library, every screen
reachable, purchases simulated, and **no network calls at all**. It isn't a mock
layer bolted on for reviewers — it's the same code path the test suite and the
reference renders run against.

## Challenges I ran into

**A feature can pass every test and still not exist.** Offline reading was green
across the suite and completely unreachable on a real phone: the auth SDK awaited
a session-token fetch during startup, retried it eight times with exponential
backoff, and since that was the only `await` before the app started, Flutter never
drew a single frame. You saw the launch screen forever. Fifty seconds of logcat
found it. No unit test would have.

**Reference renders that failed at random**, on and off for days. The cause was in
the demo data: it called `DateTime.now()` once per item, so two links saved "nine
days ago" sometimes landed in the same millisecond and sometimes didn't — and
`List.sort` isn't stable in Dart, so their order flipped between runs.

## Accomplishments I'm proud of

- The locked-instead-of-refused free tier. It changed how the product feels, and
  it came from testing on a device rather than from a spec.
- 118 behaviour tests and 32 reference renders on the app, plus the API's security
  suites. The renders caught real regressions, not just cosmetic drift.
- A design system with its own mascot, whose poses are colour-matched by a
  reproducible pipeline that lives in the repository: the target hue is measured
  off the asset the app actually ships, never written as a constant.
- The onboarding's two 3D scenes, held to that same discipline. Both arrived with the
  mascot 25° too violet to be the one the app ships, one of them as a 26 MB 256-colour
  GIF whose dark gradient was a dither pattern that crawls on an OLED screen. The build
  script measures the target hue off the shipped mascot instead of hard-coding it,
  removes the dither before upscaling rather than after, and neutralises a third-party
  logo that was legible on a card. 255 KB for both, at the exact pixel width of the
  screen.
- Documentation kept alive rather than written once, including a build journal
  that records what actually broke and why.

## What I learned

That the gap between "it works" and "it works on a phone" is where the real work
is. Three of the best things in this app — the locked free plan, offline reading,
a launch screen that doesn't flash white — exist because something was wrong on a
device and nothing in CI could see it.

## What's next

Automatic clustering: category paths currently run on a fixed taxonomy, and the
server doesn't compute clusters yet. The Daily Digest has its schema and its
screen but no scheduled job. Push notifications have no token plumbing. iOS is
untouched, for want of a Mac.

These are in the README too. An honest map of what isn't done is worth more than a
demo that pretends.

## Built with

`flutter` · `dart` · `riverpod` · `cloudflare-workers` · `hono` · `neon` ·
`postgres` · `pgvector` · `revenuecat` · `clerk` · `groq` · `gemini`
