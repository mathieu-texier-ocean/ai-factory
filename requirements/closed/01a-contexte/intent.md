# Sous-intent — Lot 1a : Contexte d'équipe

- **Parent :** [ia-factory.md](../../open/ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** validé
- **Date :** 2026-10-16
- **Validation :** Tech lead
- **Dépend de :** —
- **Origine :** découpage du lot 1 (Socle agent)

## Problème

L'agent ne connaît ni les commandes, ni les conventions, ni les pièges récurrents de l'équipe. Ce savoir vit dans les têtes : l'agent ne le lit nulle part en début de session.

## Pour qui

- **Tech lead** : relit et approuve `CLAUDE.md` en code owner. Un dev peut prendre la main sur ce rôle.
- **Équipe** : maintient `CLAUDE.md` au fil des erreurs constatées.
- **Agent** : lit `CLAUDE.md` à chaque session.
- **Lot 5 (Code + tests)** : s'appuie sur ce contexte.

## Pourquoi

Sans contexte partagé, l'agent refait les mêmes erreurs d'une session à l'autre et chaque relecteur les corrige à la main en revue. Les allers-retours s'allongent et les conventions restent appliquées de façon inégale.

## Priorité

- **Niveau :** Haute (confirmé par le PO)
- **Justification :** Prérequis du lot 5 et utile tout de suite sur `ai-factory`, pour le coût d'une page.
- **Échéance :** aucune

## Résultat attendu

Un `CLAUDE.md` versionné à la racine d'`ai-factory`, lu par l'agent à chaque session et maintenu par l'équipe.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.
- Indicateur propre au lot : nombre d'erreurs répétées que `CLAUDE.md` aurait dû éviter, suivi par les corrections dans son historique git.
- Le lot contribue aux indicateurs de l'intent parent : nombre de cycles de reprise par PR. Le taux de succès CI au premier passage n'est pas mesurable : aucune CI n'est prévue sur `ai-factory`.

## Livrables

| Type    | Élément                                                                                           |
| ------- | ------------------------------------------------------------------------------------------------- |
| Fichier | `CLAUDE.md` à la racine d'`ai-factory` : commandes, conventions, architecture, erreurs fréquentes |
| Règle   | Entretien : une erreur de l'agent constatée deux fois donne une correction dans `CLAUDE.md`       |

## Critère d'acceptation

- [ ] `CLAUDE.md` est présent à la racine d'`ai-factory` et tient sur moins d'une page.
- [ ] Il contient les sections Commandes, Conventions, Architecture et Erreurs fréquentes.
- [ ] Chaque commande listée s'exécute telle quelle sur `ai-factory`.
- [ ] La règle d'entretien figure dans `CLAUDE.md`.
- [ ] `CLAUDE.md` est ajouté par PR et approuvé par son code owner (tech lead, ou le dev qui a pris la main).

## Contraintes

- Appliqué d'abord à `ai-factory`, seul dépôt où le SDLC tourne aujourd'hui (le dépôt pilote n'existe pas encore).
- `CLAUDE.md` tient sur moins d'une page : l'agent le lit en entier à chaque session.
- Aucune donnée sensible ni secret dans `CLAUDE.md`.
- Un lot = un sous-intent = une PR.

## Hors périmètre

- Commande unique de vérification (lot 1b) et règle « vérifier avant de déclarer fini » (lot 1e) : 1a liste les commandes existantes, 1e ajoute à `CLAUDE.md` le bloc de vérification.
- Règles transverses bloquantes (lot 1c).
- Alimentation de `CLAUDE.md` par les constats de revue (lots 6 et 9).
- `CLAUDE.md` du futur dépôt pilote, et template générique pour d'autres dépôts.
- Skills métier et de standards (lots 2 à 7).

## Questions ouvertes

