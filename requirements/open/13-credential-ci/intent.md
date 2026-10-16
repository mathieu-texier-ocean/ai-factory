# Sous-intent — Lot 13 : Contrôle credential en CI

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Suspendu :** tant qu'aucune CI n'existe sur `ai-factory` (décision PO, 2026-10-16)
- **Date :** 2026-10-16
- **Validation :** Tech lead
- **Dépend de :** 1c (hook credential)
- **Origine :** retravail du lot 1c

## Problème

Le contrôle credential du lot 1c est un hook local : il se contourne par `--no-verify` ou ne joue pas si les hooks ne sont pas activés. `ai-factory` n'a pas de CI pour rattraper ces cas.

## Pour qui

- **Tech lead** : sait qu'aucune PR avec un credential en clair n'arrive à la fusion.
- **Agent et équipe** : voient leur PR bloquée s'ils ont contourné le hook.
- **Lot 5 (Code + tests)** : s'appuie sur ce contrôle.

## Pourquoi

Sans contrôle côté serveur, un seul commit fait avec `--no-verify`, ou sur un clone sans hooks, suffit à faire entrer un credential dans l'historique partagé. Il faut alors le révoquer.

## Priorité

- **Niveau :** Haute (proposé par l'auteur, à confirmer par le PO)
- **Justification :** Seul contrôle qui ne dépend pas du poste de chacun.
- **Échéance :** aucune

## Résultat attendu

Une PR sur `ai-factory` qui introduit un credential en clair est signalée en échec par la CI, avec le même diagnostic que le hook du lot 1c.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.
- Le lot contribue aux indicateurs de l'intent parent : taux de succès CI au premier passage et nombre de cycles de reprise par PR.

## Livrables

| Type | Élément |
|---|---|
| CI | Job qui applique le contrôle credential du lot 1c aux commits d'une PR |

## Critère d'acceptation

- [ ] Une PR dont un commit introduit un credential en clair, même commité avec `--no-verify`, a son check en échec, et le message nomme le fichier et la raison.
- [ ] Une PR sans credential a son check au vert.
- [ ] Les fixtures de test du lot 1c ne font pas échouer le check.

## Contraintes

- Appliqué d'abord à `ai-factory`, seul dépôt où le SDLC tourne aujourd'hui (le dépôt pilote n'existe pas encore).
- Même détection que le hook du lot 1c, sans la dupliquer.
- Aucune donnée sensible ni secret dans le contexte de l'agent.
- Un lot = un sous-intent = une PR.

## Hors périmètre

- La détection elle-même (lot 1c).
- Les autres contrôles en CI (sections de l'intent, intent validé, commande du lot 1b).
- Credentials déjà présents dans l'historique git.

## Questions ouvertes

- Plateforme de CI : le dépôt est sur GitHub, mais rien n'est en place aujourd'hui.
- Le check bloque-t-il la fusion (branch protection), ou se contente-t-il d'être en échec ?
- Comment la CI distingue-t-elle les fixtures du lot 1c des vrais credentials ?
