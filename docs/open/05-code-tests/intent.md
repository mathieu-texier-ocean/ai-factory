# Sous-intent — Lot 5 : Étape Code + tests

- **Parent :** [ia-factory.md](../../../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** CI
- **Dépend de :** lots 1 et 4

## Problème

Les standards de l'équipe (sécurité API, conventions) ne sont pas appliqués de façon homogène, ce qui multiplie les allers-retours en revue.

## Résultat attendu

L'agent implémente chaque étape du plan en appliquant les standards de l'équipe, avec des TU au vert avant d'ouvrir la PR.

## Livrables

| Type | Élément |
|---|---|
| Skill | Sécurité API |
| Skill | Conventions de l'équipe |
| Skill | TU au vert si présents |
| Hook | Sélection d'un skill obligatoire avant de coder |
| Hook | Boucle de vérification (lot 1) au vert avant ouverture de PR |

## Critère d'acceptation

- [ ] Une étape du plan « activation en masse » est implémentée et passe la CI au premier passage.
- [ ] Une PR avec des TU rouges ne peut pas être ouverte.

## Hors périmètre

- Revue de la PR (lot 6).
