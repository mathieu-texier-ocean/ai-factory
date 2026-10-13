# Sous-intent — Lot 6 : Étape Revue PR

- **Parent :** [ia-factory.md](ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** Humain (approbation de la PR)
- **Dépend de :** lot 5

## Problème

La revue de code est l'un des deux goulots du délai PR → production.

## Résultat attendu

Un agent IA fait une première revue de chaque PR, guidée par `REVIEW.md`, et commente directement la PR. L'humain se concentre sur ce qui reste et approuve.

## Livrables

| Type | Élément |
|---|---|
| Template | `REVIEW.md` (points à vérifier, niveaux de gravité) |
| Skill | Agent de revue : lit diff + spec + `REVIEW.md`, poste ses retours sur la PR |
| Hook | Revue IA exécutée avant demande de revue humaine |

## Critère d'acceptation

- [ ] Chaque PR du pilote reçoit une revue IA commentée.
- [ ] Le temps jusqu'à la première revue diminue (mesuré au lot 8).
- [ ] L'approbation reste humaine (branch protection, code owner).

## Hors périmètre

- Approbation ou merge automatique.
