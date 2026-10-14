# Sous-intent — Lot 2 : Étape Intent

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** PO
- **Dépend de :** —

## Problème

Les besoins arrivent sous des formes hétérogènes. L'étape spec n'a pas d'entrée structurée et versionnée.

## Résultat attendu

Chaque évolution démarre par un `intent.md` versionné dans Git, rédigé avec l'aide de l'agent et validé par le PO.

## Livrables

| Type | Élément |
|---|---|
| Template | `templates/intent.md` (problème, résultat attendu, critère de succès, contraintes, hors périmètre, questions ouvertes) |
| Skill | Rédaction d'intent : pose les questions manquantes, remplit le template |
| Hook | Sections obligatoires présentes avant commit |
| Skill | Contrôle de taille : applique les critères de découpage et propose des sous-intents |

## Critères de découpage

Un intent doit tenir en une PR (un lot = un sous-intent = une PR). Il est à découper dès qu'un de ces signaux apparaît.

Signaux structurels, lisibles dans le fichier :

1. **Plusieurs problèmes** : la section « Problème » juxtapose des constats indépendants.
2. **Livrable orphelin** : un livrable n'est couvert par aucun critère d'acceptation.
3. **Critères indépendants** : un critère peut passer pendant qu'un autre est bloqué, sans perdre son intérêt.
4. **Dépendances hétérogènes** : une partie des livrables dépend d'un autre lot, l'autre non.
5. **Validations hétérogènes** : relecture humaine et blocage automatique, ou plusieurs validateurs.

Signaux de taille, à estimer :

6. **PR trop longue à relire** : le diff estimé dépasse ce qui se relit en une fois (quelques centaines de lignes).
7. **Plan trop long** : le `plan.md` produit au lot 4 dépasse 5 à 7 étapes ou comporte des branches parallèles. Ce signal arrive après coup et renvoie l'intent en découpage.
8. **Plusieurs démos** : le résultat attendu ne se prouve pas en une seule démonstration.

Garde-fou : chaque sous-intent doit apporter seul une valeur vérifiable. Un élément qui n'a d'intérêt que combiné à un autre reste avec lui.

## Critère d'acceptation

- [ ] Un intent « activation en masse » est produit avec le skill.
- [ ] Le hook refuse un intent incomplet.
- [ ] Le skill de contrôle signale un intent présentant au moins un critère de découpage et propose un découpage.
- [ ] Le PO valide l'intent.

## Hors périmètre

- Génération de la spec (lot 3).
