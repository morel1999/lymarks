# UX Bible — Lymarks

> **But :** règles d'expérience non négociables, valables pour des années. · **Statut :** stable · **Màj :** 2026-08-07

## Règles dures
1. **La capture ne bloque jamais.** La share sheet se ferme dès le tap sur Enregistrer (<2 s tap→fermeture). Aucun spinner d'attente du pipeline IA, jamais.
2. **L'utilisateur ne quitte jamais son environnement.** La capture se fait dans la fenêtre de partage native ; retour automatique à l'app source. Jamais d'ouverture de l'app Lymarks pendant une capture.
3. **Zéro décision imposée à la capture.** Pas de dossier, pas de tag obligatoire, pas de catégorie. La note est optionnelle. Un seul bouton principal.
4. **Le traitement est visible mais pas bruyant.** Dans l'app, un lymark en cours = carte squelette animée qui se remplit seule. Pas de notification « votre résumé est prêt ».
5. **La recherche est un seul champ.** Pas de filtres obligatoires, pas de syntaxe. Résultats <500 ms (plein texte) / <800 ms (sémantique).
6. **Le digest respecte l'attention.** 1 notification/jour maximum, jamais deux. Opt-out en 1 geste depuis la notification. Aucune notification marketing.
7. **Toute action destructive est réversible.** Suppression d'un lymark = undo 5 s (snackbar). Exception : suppression de compte (confirmation explicite double).
8. **Animations <150 ms** pour les micro-interactions ; 200–250 ms max pour les transitions de listes. Jamais d'animation qui fait attendre.
9. **Jamais de full page pour une action simple.** Note, tags, report du digest : bottom sheets. Les pages complètes sont réservées à la lecture d'un lymark et aux réglages.
10. **Toujours revenir à l'endroit exact.** Position de scroll, requête de recherche et onglet sont restaurés après navigation ou kill de l'app.
11. **Le paywall n'interrompt jamais une capture.** La limite Free se signale *après* l'enregistrement (le 31ᵉ lien est capturé puis mis en attente), jamais dans la share sheet. ⚠️ À décider : file « en attente » vs blocage doux — proposition : capture acceptée + bandeau dans l'app.
12. **Le vide est un état conçu.** Liste vide = mini-tutoriel de capture (3 étapes illustrées), pas un écran blanc.

## Ton et langage
Interface sobre, vocabulaire concret (« Enregistré », « 1 lien oublié refait surface »). Pas de gamification, pas de badges, pas de culpabilisation (« vous avez 47 liens non lus » est interdit).
