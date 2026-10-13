# Sous-intent — Lot 9 : Auto-apprentissage

- **Parent :** [ia-factory.md](../../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** Humain (approbation de la PR)
- **Dépend de :** lot 8

## Problème

Les mêmes erreurs reviennent en revue, en CI et en recette, sans que les skills, hooks ou `CLAUDE.md` soient mis à jour.

## Résultat attendu

Les signaux de la chaîne sont analysés et transformés en propositions d'amélioration de l'outillage, validées par un humain.

## Livrables

| Type | Élément |
|---|---|
| Collecte | Commentaires de revue, échecs CI, défauts de recette, hooks déclenchés (traces du lot 8) |
| Skill | Analyse des signaux et proposition d'une mise à jour de skill, de hook ou de `CLAUDE.md` **via une PR** |
| Evals | Vérification qu'un skill modifié ne régresse pas |

## Critère d'acceptation

- [ ] Au moins une amélioration proposée par PR, validée et mergée.
- [ ] Les evals passent avant merge de toute modification de skill.

## Hors périmètre

- Modification sans validation humaine.
- Boucle de maintenance autonome du code produit (hors périmètre du pilote).
