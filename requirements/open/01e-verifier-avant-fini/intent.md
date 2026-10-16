# Sous-intent — Lot 1e : Vérifier avant de déclarer fini

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Date :** 2026-10-16
- **Validation :** Tech lead
- **Dépend de :** 1a (contexte d'équipe), 1b (commande de vérification)
- **Origine :** découpage du lot 1b

## Problème

Même avec une commande de vérification, rien ne dit à l'agent de la lancer avant de déclarer une tâche finie, ni de montrer le résultat.

## Pour qui

- **Agent** : lance la vérification avant de déclarer fini et colle la sortie.
- **Relecteur** : reçoit la sortie de l'outil comme preuve, sans relancer lui-même.
- **Tech lead** : relit et approuve le bloc de `CLAUDE.md`.

## Pourquoi

Une tâche déclarée finie sans vérification arrive en revue avec des erreurs qu'un test aurait attrapées, et le relecteur doit relancer lui-même les tests pour le savoir.

## Priorité

- **Niveau :** Haute (proposé par l'auteur, à confirmer par le PO)
- **Justification :** Transforme la commande du lot 1b en habitude de l'agent, pour le coût de quelques lignes.
- **Échéance :** aucune

## Résultat attendu

L'agent lance la commande de vérification avant de déclarer une tâche finie et colle sa sortie.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.
- Le lot contribue aux indicateurs de l'intent parent : nombre de cycles de reprise par PR et, quand une CI existera, taux de succès CI au premier passage.

## Livrables

| Type | Élément |
|---|---|
| Bloc `CLAUDE.md` | « Vérifier son travail » : la commande du lot 1b, un exemple de sortie saine et la règle « lancer avant de déclarer fini et coller la sortie ; pendant un correctif, corriger le code, pas le test ; si le comportement change volontairement, mettre à jour le test et le signaler » |

## Critère d'acceptation

- [ ] Le bloc de `CLAUDE.md` donne la commande, un exemple de sortie saine et la règle.
- [ ] Sur une tâche de démonstration qui modifie `templates/intent.md` (par exemple l'ajout d'une section obligatoire), l'agent lance la commande avant de déclarer fini, met à jour les fixtures concernées en le signalant, et colle la sortie au vert.

## Contraintes

- Appliqué d'abord à `ai-factory`, seul dépôt où le SDLC tourne aujourd'hui (le dépôt pilote n'existe pas encore).
- Le bloc garde `CLAUDE.md` sous une page (contrainte du lot 1a).
- Aucune donnée sensible ni secret dans le contexte de l'agent.
- Un lot = un sous-intent = une PR.

## Hors périmètre

- La commande de vérification elle-même (lot 1b).
- Hook qui bloque l'édition des tests pendant un correctif.
- Hook « commande au vert avant ouverture de PR » (lot 5) : 1e est une consigne, pas un blocage.

## Questions ouvertes

