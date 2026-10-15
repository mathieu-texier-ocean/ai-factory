# Sous-intent — Lot 4 : Étape Plan

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** Tech lead
- **Dépend de :** lot 3

## Problème

Les PR sont trop grosses ou mal découpées, ce qui ralentit la revue.

## Résultat attendu

Un `plan.md` qui découpe la spec en étapes ordonnées, chacune livrable en une PR de taille raisonnable.

## Livrables

| Type | Élément |
|---|---|
| Template | `templates/plan.md` (étapes, fichiers touchés, tests à écrire, risques) |
| Skill | Découpage : lit `spec.md`, produit `plan.md` |
| Hook | Refus de créer un plan si la spec n'est pas validée |

## Critère d'acceptation

- [ ] Un plan est généré depuis la spec du lot 3.
- [ ] Chaque étape correspond à une PR.
- [ ] Validé par le tech lead.

## Hors périmètre

- Génération du code (lot 5).
