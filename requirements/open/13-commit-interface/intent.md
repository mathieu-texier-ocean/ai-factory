# Intent : Commit depuis l'interface web

- **Auteur :** Nicola Ruivo
- **Statut :** draft
- **Date :** 2026-10-15
- **Validation :** PO
- **Dépend de :** [12-interface-view](../12-interface-view/intent.md)

## Problème

Une fois un intent rédigé dans l'interface web (lot 12), le committer demande encore la ligne de commande git, et les refus du hook `pre-commit` s'affichent dans un terminal. Les PO et autres profils non développeurs ne peuvent pas le faire sans connaissance en développement.

## Pour qui

Les PO et les autres profils non développeurs (recette, métier).

## Pourquoi

Sans commit depuis l'interface, les PO dépendent encore d'un développeur pour verser leurs artefacts dans la chaîne.

## Priorité

- **Niveau :** Moyenne
- **Justification :** aucune
- **Échéance :** aucune

## Résultat attendu

L'interface web permet de committer les artefacts rédigés, de pousser la branche et d'ouvrir une PR. Le hook `pre-commit` du dépôt s'applique, et ses refus s'affichent de façon compréhensible pour un non-développeur.

## Critère de succès

- Un PO sans connaissance en développement commite un intent et ouvre la PR correspondante via l'interface, sans aide.
- Un intent auquel il manque une section obligatoire est refusé, avec un message clair qui nomme les sections manquantes.

## Contraintes

- Accessible sans connaissance en développement : pas de ligne de commande.

## Hors périmètre

- Création ou modification de skills et de hooks : l'interface utilise ceux qui existent.
- Ouverture à d'autres dépôts que `ai-factory`.
- Validation d'un intent : le passage en « validé » reste un geste manuel du PO, hors interface.

## Questions ouvertes

- Le hook `pre-commit` doit-il être impossible à contourner depuis l'interface ?
