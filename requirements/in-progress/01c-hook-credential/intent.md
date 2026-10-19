# Sous-intent — Lot 1c : Hook credential en clair

- **Parent :** [ia-factory.md](../../open/ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** validé
- **Date :** 2026-10-16
- **Validation :** Tech lead
- **Dépend de :** —
- **Origine :** découpage du lot 1 (Socle agent)

## Problème

Rien n'empêche de committer un credential en clair dans `ai-factory` : `hooks/pre-commit` ne contrôle aujourd'hui que les intents et les specs.

## Pour qui

- **Agent et équipe** : sont bloqués au commit s'ils introduisent un credential en clair.
- **Tech lead** : valide le contrôle.
- **Lot 5 (Code + tests)** : s'appuie sur ce contrôle.

## Pourquoi

Un credential commité reste dans l'historique git même après suppression : il faut le révoquer. Il entre aussi dans le contexte de l'agent, qui lit le dépôt, alors que l'intent parent l'interdit.

## Priorité

- **Niveau :** Haute (confirmé par le PO)
- **Justification :** Règle de sécurité exigée par l'intent parent et prérequis du lot 5.
- **Échéance :** aucune

## Résultat attendu

Un commit qui introduit un credential en clair est refusé par `hooks/pre-commit`, avec un message qui explique pourquoi.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.
- Le lot contribue aux indicateurs de l'intent parent : nombre de cycles de reprise par PR. Le taux de succès CI au premier passage n'est pas mesurable : aucune CI n'est prévue sur `ai-factory`.

## Livrables

| Type | Élément |
|---|---|
| Hook | Contrôle « pas de credential en clair » dans `hooks/pre-commit` (bloquant) |
| Tests | `run.sh` et fixtures du contrôle, au même format que ceux des lots 2 et 3, dans `hooks/tests/hook-credential/` |

## Critère d'acceptation

- [ ] Un commit qui introduit un credential en clair est refusé, et le message nomme le fichier, la raison et la façon de corriger.
- [ ] Un commit sans credential passe, et les tests existants des lots 2 et 3 restent au vert.
- [ ] Les tests du contrôle passent et sont un `run.sh` dans `hooks/tests/hook-credential/`, à côté du hook, au même format que ceux des lots 2 et 3.

## Contraintes

- Appliqué d'abord à `ai-factory`, seul dépôt où le SDLC tourne aujourd'hui (le dépôt pilote n'existe pas encore).
- La règle est bloquante.
- Détection par un contrôle maison dans `hooks/pre-commit`. gitleaks est réservé à la CI, si elle existe (lot 13).
- Seul le contenu indexé pour le commit est contrôlé.
- Les fixtures de test utilisent des credentials fictifs, jamais de vrais. Elles sont commitées avec `--no-verify`, dans un commit qui ne contient qu'elles, puisque `--no-verify` saute tous les contrôles.
- Aucune donnée sensible ni secret dans le contexte de l'agent.
- Un lot = un sous-intent = une PR.

## Hors périmètre

- Activation de `core.hooksPath` dans les clones (lot 1f).
- Hook Claude Code sur les éditions de l'agent.
- Contrôle en CI par gitleaks, qui rattrape un `--no-verify` (lot 13, si une CI existe).
- Credentials déjà présents dans l'historique git.
- Règles langue et historique (écartées pour l'instant).
- Skills métier et de standards (lots 2 à 7).

## Questions ouvertes

