# Sous-intent — Lot 2 : Étape Intent

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** PO
- **Dépend de :** —

## Problème

Les besoins arrivent sous des formes hétérogènes. L'étape spec n'a pas d'entrée structurée et versionnée.

## Pour qui

- **PO** : exprime le besoin et valide l'intent.
- **Tech lead** : lit l'intent validé pour en tirer la spec (lot 3).
- **Agent** : consomme l'intent comme entrée de l'étape spec.

## Pourquoi

Un besoin mal cadré en entrée génère des reprises en spec, puis en revue, et allonge le délai PR → production (≈ 10,7 jours). Un intent structuré, versionné et validé réduit ces allers-retours en amont et sert de point de départ commun à toute la chaîne.

## Résultat attendu

Chaque évolution démarre par un `intent.md` versionné dans Git, rédigé avec l'aide de l'agent et validé par le PO.

## Livrables

| Type | Élément |
|---|---|
| Template | `templates/intent.md` (problème, pour qui, pourquoi, priorité, résultat attendu, critère de succès, contraintes, hors périmètre, questions ouvertes) |
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

- [ ] Un intent est produit avec le skill.
- [ ] Le hook refuse un intent incomplet.
- [ ] Le skill de contrôle signale un intent présentant au moins un critère de découpage et propose un découpage.
- [ ] Le PO valide l'intent.

## Plan de test

| # | Critère couvert | Scénario | Résultat attendu | Type |
|---|---|---|---|---|
| 1 | Un intent est produit avec le skill | Lancer le skill avec un besoin brut quelconque | `intent.md` rempli, questions manquantes posées, toutes les sections du template présentes | Manuel |
| 2 | Le hook refuse un intent incomplet | Commiter un `intent.md` sans la section « Pourquoi » | Commit bloqué, message indiquant la section manquante | Automatisé |
| 3 | Le hook accepte un intent complet | Commiter un `intent.md` complet | Commit accepté | Automatisé |
| 4 | Le skill de contrôle signale un intent à découper | Passer un intent avec 2 problèmes indépendants et un livrable orphelin | Signaux 1 et 2 relevés, découpage proposé | Manuel |
| 5 | Le skill de contrôle ne sur-découpe pas | Passer un intent cohérent (ex. le lot 1) | Aucun signal, aucun découpage proposé (garde-fou) | Manuel |
| 6 | Le PO valide l'intent | Revue de l'intent produit au scénario 1 par le PO | Validation explicite | Humain |

**Jeu de données :** un besoin brut quelconque (cas nominal) et un intent volontairement trop gros (cas de découpage).

## Hors périmètre

- Génération de la spec (lot 3).
