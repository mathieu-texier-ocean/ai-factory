# Sous-intent — Lot 4 : Étape Plan

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** validé
- **Validation :** Tech lead
- **Dépend de :** lot 3

## Problème

Les PR sont trop grosses ou mal découpées, ce qui ralentit la revue.

## Pour qui

- **Tech lead** : relit et valide le plan.
- **Agent** : lit la spec validée (lot 3) et produit le plan.
- **Lot 5 (code + tests)** : consomme le plan, une étape après l'autre.

## Pourquoi

Des PR trop grosses ou mal découpées ralentissent la revue de code, l'un des deux goulots du délai PR → production (≈ 10,7 jours). Un plan qui découpe la spec en étapes ordonnées, chacune livrable en une PR, rend ces PR relisibles.

## Priorité

- **Niveau :** à définir par le PO
- **Justification :**
- **Échéance :** aucune

## Résultat attendu

Un `plan.md` qui découpe la spec en étapes ordonnées, chacune livrable en une PR de taille raisonnable.

## Critère de succès

- Les trois critères d'acceptation ci-dessous sont atteints.
- Le lot contribue aux indicateurs de l'intent parent : temps jusqu'à la première revue et nombre de cycles de reprise par PR.

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

## Contraintes

- Un lot = un sous-intent = une PR : chaque étape du plan correspond à une PR.
- Le plan se produit à partir d'une spec validée (lot 3).
- Un plan de plus de 5 à 7 étapes, ou avec des branches parallèles, renvoie l'intent en découpage (signal 7 du lot 2).
- Source de vérité : Git. Aucune donnée sensible ni secret dans le contexte de l'agent.
- La validation du plan reste celle du tech lead.

## Hors périmètre

- Génération du code (lot 5).

## Questions ouvertes

- Priorité du lot : niveau, justification et échéance à définir par le PO.
- Hook « plan → spec validée » : lire la spec dans `HEAD` (comme le contrôle du lot 3) ou dans l'index ? À confirmer par le tech lead.
- Statut absent de la spec : message à afficher (point R2 du plan du lot 3) ; le hook du lot 4 doit reprendre le motif de statut défini par la spec du lot 3.
