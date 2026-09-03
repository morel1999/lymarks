# Core Principles & Engineering Manifesto — Lymarks

> **But :** les règles qui ne changent pas, même quand la stack change. · **Statut :** stable · **Màj :** 2026-08-07

1. **La capture ne bloque jamais l'utilisateur.** Toute intelligence s'exécute en arrière-plan ; aucune feature ne peut ajouter de friction à l'inflow.
2. **La sécurité prime sur la vitesse** quand un arbitrage est nécessaire — y compris pendant un sprint de 14 jours.
3. **Les droits se vérifient côté serveur.** Le client affiche, le serveur décide. Aucune limite de plan appliquée uniquement dans l'app.
4. **Les données de l'utilisateur lui appartiennent.** Export complet et suppression totale fonctionnels à tout moment ; la note personnelle ne quitte jamais notre périmètre (jamais envoyée aux LLM).
5. **Tout contenu tiers est non fiable par défaut** : URLs (SSRF), pages web (injection de prompt), webhooks (signature).
6. **Le digest respecte l'attention : 1 lien par jour, maximum.** Aucune notification d'engagement, jamais de culpabilisation.
7. **La valeur se mesure à l'outflow.** Une feature qui augmente les sauvegardes sans améliorer recherche ou re-surfaçage n'est pas prioritaire.
8. **Chiffres avant adjectifs.** Toute exigence de performance ou de limite est un nombre inscrit dans un document, pas un ressenti.
9. **Architecture modulaire, pipeline remplaçable.** Groq, Gemini ou Neon peuvent changer ; les interfaces des modules (SAD) restent.
10. **Toute nouvelle feature passe par la revue du Threat Model** avant d'être codée.

Les dépendances peuvent changer ; ces principes restent la base de toutes les décisions.
