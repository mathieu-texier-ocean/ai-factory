# Sous-intent — Lot 1 : Socle agent

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** validé
- **Validation :** Tech lead
- **Dépend de :** —

## Problème

L'agent ne connaît ni les commandes, ni les conventions de l'équipe, et ne peut pas vérifier seul son travail. Les règles transverses ne sont pas appliquées automatiquement.

## Pour qui

- **Tech lead** : relit et valide `CLAUDE.md` d'équipe.
- **Agent** : travaille avec le contexte de l'équipe et se vérifie lui-même.
- **Lot 5 (Code + tests)** : s'appuie sur le socle.

## Pourquoi

Le savoir de l'équipe (conventions, pièges récurrents, règles de sécurité) vit dans les têtes et n'est pas appliqué de façon homogène, ce qui allonge les allers-retours en revue. Un socle partagé (contexte, vérification en une commande, règles bloquantes) les applique automatiquement.

## Priorité

- **Niveau :** à définir par le PO
- **Justification :**
- **Échéance :** aucune

## Résultat attendu

L'agent travaille sur le dépôt pilote avec le contexte de l'équipe, se vérifie en une commande et est bloqué sur les règles transverses.

## Critère de succès

- Les trois critères d'acceptation ci-dessous sont atteints.
- Le lot contribue aux indicateurs de l'intent parent : taux de succès CI au premier passage et nombre de cycles de reprise par PR.

## Livrables

| Type | Élément |
|---|---|
| Template | `CLAUDE.md` d'équipe (commandes, conventions, erreurs fréquentes) |
| Script | Boucle de vérification : build + TU + lint en une commande |
| Hook | Pas de credential en clair dans le code (bloquant) |
| Hook | Langue fr/en imposée (bloquant) |
| Hook | Historique propre : un commit = une action, squash des PR |

## Critère d'acceptation

- [ ] L'agent lance la boucle de vérification et lit le résultat vert/rouge.
- [ ] Un credential en clair est bloqué par le hook.
- [ ] `CLAUDE.md` relu et validé par le tech lead.

## Contraintes

- Démarrage sur un seul dépôt pilote.
- Aucune donnée sensible ni secret dans le contexte de l'agent.
- Les règles transverses sont bloquantes : credential en clair, langue fr/en, historique propre (un commit = une action, squash des PR).
- Un lot = un sous-intent = une PR.

## Hors périmètre

- Skills métier et de standards (lots 2 à 7).

## Questions ouvertes

- Priorité du lot : niveau, justification et échéance à définir par le PO.
- Activation des hooks par défaut : `core.hooksPath` n'est pas configuré dans les clones, donc les contrôles ne jouent que si chacun les active (point R5 du plan du lot 3). Ce lot doit-il l'imposer ?
- Dépôt pilote : à nommer.
