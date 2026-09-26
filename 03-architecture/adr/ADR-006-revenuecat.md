# ADR-006 — RevenueCat for monetisation
**Status:** accepted · 2026-08-07
**Context:** iOS+Android subscriptions, Shipaton context (RevenueCat), no time for raw StoreKit/Billing.
**Decision:** `purchases_flutter` + single entitlement `pro`; RevenueCat webhook → `subscriptions` table for server-side enforcement.
**Alternatives:** StoreKit2/Play Billing directly (dual implementation, self-validating receipts).
**Consequences:** RevenueCat commission beyond the free tier; source of truth for rights = server, never the client.
