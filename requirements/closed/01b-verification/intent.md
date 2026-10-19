# Sous-intent — Lot 1b : Commande de vérification

- **Parent :** [ia-factory.md](../../open/ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** validé
- **Date :** 2026-10-16
- **Validation :** Tech lead
- **Dépend de :** —
- **Origine :** découpage du lot 1 (Socle agent)

## Problème

Aucune commande ne vérifie le dépôt d'un coup. Les tests sont éparpillés, un `run.sh` par lot, et se lancent un par un.

## Pour qui

- **Agent** : vérifie son travail en une commande.
- **Équipe** : lance la même vérification que l'agent.
- **Lot 1e (Vérifier avant de déclarer fini)** : documente cette commande dans `CLAUDE.md`.
- **Lot 5 (Code + tests)** : son hook exige la commande au vert avant l'ouverture d'une PR.

## Pourquoi

Sans commande unique, l'agent ou le relecteur oublie un `run.sh`, et une erreur qu'un test aurait attrapée arrive en revue.

## Priorité

- **Niveau :** Haute (confirmé par le PO)
- **Justification :** Prérequis des lots 1e et 5.
- **Échéance :** aucune

## Résultat attendu

Une commande lance toutes les vérifications automatisées d'`ai-factory` et dit si elles passent.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.
- Le lot contribue aux indicateurs de l'intent parent : nombre de cycles de reprise par PR. Le taux de succès CI au premier passage n'est pas mesurable : aucune CI n'est prévue sur `ai-factory`.

## Livrables

| Type | Élément |
|---|---|
| Script | Une commande qui lance tous les `run.sh` des lots et sort en erreur si un test échoue |

## Critère d'acceptation

- [ ] La commande lance tous les `run.sh` présents, y compris celui d'un lot ajouté après coup, sans modifier le script.
- [ ] Elle sort en 0 si tout passe, en erreur si un test échoue, et nomme le test en échec.

## Contraintes

- Appliqué d'abord à `ai-factory`, seul dépôt où le SDLC tourne aujourd'hui (le dépôt pilote n'existe pas encore).
- Aucune donnée sensible ni secret dans le contexte de l'agent.
- Un lot = un sous-intent = une PR.

## Hors périmètre

- Documentation de la commande et règle « vérifier avant de déclarer fini » dans `CLAUDE.md` (lot 1e).
- Hook qui bloque l'édition des tests pendant un correctif.
- Hook « commande au vert avant ouverture de PR » (lot 5).
- Build et lint : `ai-factory` n'en a pas aujourd'hui.
- Recettes manuelles des skills (`skills-intent`, `skills-spec`).
- Mise en place d'une CI : aucune n'est prévue sur `ai-factory`.
- Règles transverses bloquantes (lot 1c).

## Questions ouvertes

- Quel lot porte le hook qui protège les tests pendant un correctif ?
