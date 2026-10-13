# Sous-intent — Lot 1 : Socle agent

- **Parent :** [ia-factory.md](../../../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** Tech lead
- **Dépend de :** —

## Problème

L'agent ne connaît ni les commandes, ni les conventions de l'équipe, et ne peut pas vérifier seul son travail. Les règles transverses ne sont pas appliquées automatiquement.

## Résultat attendu

L'agent travaille sur le dépôt pilote avec le contexte de l'équipe, se vérifie en une commande et est bloqué sur les règles transverses.

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

## Hors périmètre

- Skills métier et de standards (lots 2 à 7).
