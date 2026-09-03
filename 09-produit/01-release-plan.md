# Release Plan — Lymarks V1.0

> **But :** jalons, gel, critères go/no-go, soumission. · **Statut :** vivant · **Màj :** 2026-08-07

## Jalons (sprint 14 jours — cf. Roadmap)
- **J1–J2** infra · **J3–J6** app+share · **J7–J10** IA+recherche · **J11** 🔒 **gel des features** · **J11–J13** paywall, polish, checklist E2E, assets stores · **J14** soumission App Store + Play.
- Entre soumission et le **30/09/2026** : buffer review (48 h à plusieurs jours) + 1 cycle de rejet absorbable (Risk R1).

## Critères GO de soumission
1. Checklist E2E manuelle 100 % verte sur 4 devices (2 iOS, 2 Android).
2. Gates CI verts (Test Strategy) ; budgets perfs « capture <2 s » et « recherche <800 ms » tenus.
3. Achat sandbox + restore OK sur les deux plateformes ; suppression de compte fonctionnelle.
4. Privacy labels / Data Safety remplis conformément à la Privacy Spec ; Store Compliance checklist verte.

## Règles de version
`MAJOR.MINOR.PATCH` + build number auto. Tout envoi aux stores = tag git + entrée changelog. Hotfix post-lancement : branche depuis le tag, patch only.
