# Sous-intent — Lot 2 : Étape Intent

- **Parent :** [ia-factory.md](../../../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** PO
- **Dépend de :** lot 1

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

## Critère d'acceptation

- [ ] Un intent « activation en masse » est produit avec le skill.
- [ ] Le hook refuse un intent incomplet.
- [ ] Le PO valide l'intent.

## Hors périmètre

- Génération de la spec (lot 3).
