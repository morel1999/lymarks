# Lymarks — Devpost submission text

Texte prêt à coller dans le formulaire Devpost. En anglais : c'est la langue
du jury. Les titres suivent les champs habituels du formulaire ; adapte si
Devpost en propose d'autres.

---

## Inspiration

I save links constantly — a thread, a tutorial, a post I want to come back to.
And then I never come back. The link is saved, the reason I saved it is gone.
Every bookmarking app I tried solves storage. None of them solves **recall**.

Lymarks is built on one idea: a saved link is worthless until you can find it
again on a day when you've forgotten its title, its site, and the words it used.

## What it does

You share a link from any app. That's the whole interaction — one tap, no form,
no folder to choose. Two seconds later the sheet is gone.

Behind that, Lymarks fetches the page, extracts the text, and asks a model for
**three bullets and a category**. The card fills itself while you're already
doing something else. From then on the link is searchable by what it *said*,
not by what it was called — including semantic search, where you describe what
you half-remember and it surfaces anyway.

Some pages refuse a server. When that happens the **phone reads the page
itself** and hands the text back to the same pipeline, so a site that blocks
robots still ends up in your memory.

And it works without a network: the library is kept on the device, search falls
back to full text locally, and a banner tells you plainly that you're looking at
the last sync rather than pretending everything is fine.

## How I built it

```
Flutter app ──► Cloudflare Worker API ──► Neon Postgres (pgvector + full-text)
                        │
                        ├─► Groq → Gemini Flash   summary, 3 bullets, category
                        ├─► Gemini                embeddings for semantic search
                        ├─► Clerk                 identity
                        └─► RevenueCat webhook    entitlements
```

Flutter + Riverpod on the client, Hono on Cloudflare Workers for the API, Neon
Postgres with pgvector and a generated tsvector column for hybrid search. Page
fetching is SSRF-guarded, with DNS resolved over DoH before every request *and*
every redirect.

Everything is optimistic first: each gesture changes the local list immediately
and reconciles with the server afterwards. Deleting is reversible for five
seconds, and the real purge only leaves once the undo window closes.

## RevenueCat: what the free plan does instead of refusing

This is the part I'd most like judged.

The obvious free-plan design is a limit that **refuses**: past 30 links, the
capture fails. I shipped that first, and testing it on a real phone showed how
bad it is — you keep sharing links from other apps and none of them arrive. You
don't find out until you open the app. The product quietly loses your data to
protect its own pricing.

So the limit moved. Past 30, the link is still **saved** — it just arrives
locked: visible in your library, blurred, with the mascot asleep next to a line
that says *"We saved every link you sent. Nothing is lost."* No AI call is spent
on a locked link, so the free tier still costs nothing to run. The moment the
RevenueCat webhook confirms the entitlement, every locked link unlocks **and the
pipeline runs on all of them at once**.

The upgrade isn't a gate you hit. It's a key to something you already own.

RevenueCat carries the whole flow: offerings drive the paywall prices, the
`appUserID` is the Clerk user id, and the entitlement is confirmed **server
side** by the webhook — the app never decides on its own that you're Pro.

## Try it in one minute, with no keys

```
git clone <repo> && cd lymarks/app
flutter run
```

Without API keys the app boots in **demo mode**: a full curated library, every
screen reachable, purchases simulated. It's not a mock layer bolted on for
judges — it's the same code path the test suite runs against.

## Accomplishments

- The locked-instead-of-refused free tier, which changed how the product feels.
- Offline reading that actually works, found and fixed on a real device.
- 112 behaviour tests and 30 reference renders on the app, plus the API's
  security suites — and the reference renders caught real regressions, not just
  cosmetic drift.
- A design system with its own mascot, nine poses generated and colour-matched
  by a reproducible pipeline in the repo.

## What I learned

That a device tells you things a test suite cannot. Offline mode passed every
test and was still unreachable on a real phone: the auth SDK awaited a network
token fetch during startup, retried it eight times with exponential backoff, and
the app never drew a single frame. Fifty seconds of logcat found it. No unit
test would have.

## What's next

Automatic clustering — the category paths currently run on the taxonomy, and the
server doesn't compute clusters yet. The Daily Digest has its schema and its
screen but no scheduled job. Push notifications have no token plumbing. iOS is
untouched, for want of a Mac.

These are written in the README too. An honest map of what isn't done is worth
more than a demo that pretends.

## Built with

`flutter` · `dart` · `riverpod` · `cloudflare-workers` · `hono` · `neon` ·
`postgres` · `pgvector` · `revenuecat` · `clerk` · `groq` · `gemini`
