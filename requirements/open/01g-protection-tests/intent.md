# Sous-intent — Lot 1g : Protection des tests pendant un correctif

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **Date :** 2026-10-16
- **Validation :** Tech lead
- **Dépend de :** 1e (vérifier avant de déclarer fini)
- **Origine :** question ouverte du lot 1b, tranchée le 2026-10-16

## Problème

Le lot 1e demande à l'agent, pendant un correctif, de corriger le code et pas le test. C'est une consigne : rien n'empêche l'agent de modifier un test pour le faire passer au vert sans que personne le voie.

## Pour qui

- **Agent** : doit obtenir l'accord de l'humain avant de modifier un test sur une branche de correctif.
- **Humain qui pilote la session** : approuve ou refuse chaque modification de test au cas par cas.
- **Relecteur** : sait qu'une modification de test sur un correctif a été approuvée par un humain.
- **Tech lead** : valide le contrôle.

## Pourquoi

Un test modifié pour coller au code fautif fait passer un correctif au vert sans corriger le bug. Le défaut arrive en revue ou en production, et le test ne protège plus.

## Priorité

- **Niveau :** Moyenne
- **Justification :** La consigne du lot 1e couvre le besoin en attendant ; 1g la rend contraignante.
- **Échéance :** aucune

## Résultat attendu

Sur une branche `bugfix/…` d'`ai-factory`, toute modification par l'agent d'un fichier sous un dossier `tests/` demande la confirmation de l'humain dans Claude Code avant de s'appliquer.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.
- Le lot contribue à l'indicateur de l'intent parent : nombre de cycles de reprise par PR.

## Livrables

| Type | Élément |
|---|---|
| Hook Claude Code | Avant une édition de l'agent (`PreToolUse`) : sur une branche `bugfix/…`, demande la confirmation de l'humain pour toute écriture sous un dossier `tests/` |

## Critère d'acceptation

- [ ] Sur une branche `bugfix/…`, une modification par l'agent (Edit ou Write) d'un fichier sous `tests/` demande la confirmation de l'humain, avec la raison.
- [ ] Sur une branche `bugfix/…`, une commande Bash de l'agent qui écrit sous `tests/` demande aussi la confirmation.
- [ ] Sur une branche `bugfix/…`, une modification hors de `tests/` passe sans confirmation.
- [ ] Sur une autre branche, une modification sous `tests/` passe sans confirmation.

## Contraintes

- Appliqué d'abord à `ai-factory`, seul dépôt où le SDLC tourne aujourd'hui (le dépôt pilote n'existe pas encore).
- Le correctif est reconnu au nom de la branche courante : préfixe `bugfix/` uniquement.
- Un « test » est tout fichier sous un dossier `tests/` (scripts et fixtures).
- Le hook demande confirmation, il ne bloque pas : la décision reste à l'humain.
- Sont interceptés les outils d'édition (Edit, Write) et les commandes Bash qui écrivent sous `tests/`.
- Aucune donnée sensible ni secret dans le contexte de l'agent.
- Un lot = un sous-intent = une PR.

## Hors périmètre

- La consigne « corriger le code, pas le test » dans `CLAUDE.md` (lot 1e).
- Les modifications faites par l'humain, hors de Claude Code.
- Les branches autres que `bugfix/…` (dont `fix/` et `hotfix/`).
- Contrôle au commit ou en CI.

## Questions ouvertes

- La création d'un nouveau fichier sous `tests/` (ajout d'un test de non-régression, cas courant d'un correctif) demande-t-elle aussi confirmation, ou seulement la modification et la suppression d'un fichier existant ?
- Détection des écritures Bash : la reconnaissance par le texte de la commande (comme au lot 1f) laisse passer un script qui écrit sous `tests/`. Risque accepté ?
- Emplacement et déclaration du hook : `.claude/hooks/` et `.claude/settings.json`, comme le lot 1f ? Si oui, 1g dépend aussi de 1f.
