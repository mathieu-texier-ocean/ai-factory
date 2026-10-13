# Sous-intent — Lot 7 : Étape Recette

- **Parent :** [ia-factory.md](ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** Recette
- **Dépend de :** lot 3

## Problème

La recette humaine est l'un des deux goulots du délai PR → production.

## Résultat attendu

Les critères d'acceptation de la spec sont transformés en tests automatisés exécutés avant la recette humaine, qui ne porte plus que sur le reste.

## Livrables

| Type | Élément |
|---|---|
| Skill | Génération de scénarios Gherkin depuis `spec.md` |
| Skill | Génération de tests E2E |
| Skill | Génération du plan de test pour la recette humaine résiduelle |

## Critère d'acceptation

- [ ] Les critères d'acceptation de la spec « activation en masse » sont couverts par des tests Gherkin et/ou E2E.
- [ ] Le plan de test humain est réduit, validé par la recette.

## Hors périmètre

- Suppression complète de la recette humaine.
