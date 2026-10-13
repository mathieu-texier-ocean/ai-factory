# Sous-intent — Lot 8 : Monitoring

- **Parent :** [ia-factory.md](../../../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** Tech lead
- **Dépend de :** lot 0

## Problème

Sans suivi continu, impossible de savoir quelle étape fait gagner du temps, laquelle bloque, et si l'objectif ÷2 est atteint.

## Résultat attendu

Un tableau de bord continu des indicateurs, plus des traces par étape de la chaîne.

## Livrables

| Type | Élément |
|---|---|
| Tableau de bord | Délai PR → prod, temps jusqu'à la 1re revue, CI au 1er passage, cycles de reprise par PR, échecs en prod |
| Traces | Par étape : skill utilisé, hook bloquant, nombre d'allers-retours |

## Critère d'acceptation

- [ ] Les indicateurs sont mis à jour automatiquement et comparés à la référence du lot 0.
- [ ] Les traces sont exploitables par le lot 9.

## Hors périmètre

- Modification des skills (lot 9).
