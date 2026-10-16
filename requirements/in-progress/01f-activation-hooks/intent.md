# Sous-intent — Lot 1f : Activation des hooks git

- **Parent :** [ia-factory.md](../../open/ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** validé
- **Date :** 2026-10-16
- **Validation :** Tech lead
- **Dépend de :** —
- **Origine :** retravail du lot 1c (point R5 du plan du lot 3)

## Problème

`hooks/pre-commit` ne joue que si `core.hooksPath` vaut `hooks` dans le clone. Ce réglage n'est pas versionné : sur un clone où personne ne l'a fait, aucun contrôle ne s'exécute, et rien ne le signale.

## Pour qui

- **Agent** : est prévenu en début de session et bloqué au commit quand les hooks git ne sont pas actifs.
- **Équipe** : sait que ses commits ne sont pas contrôlés.
- **Lots 2, 3 et 1c** : leurs contrôles de commit ne jouent que si les hooks sont actifs.

## Pourquoi

Un clone sans `core.hooksPath` accepte en silence un intent incomplet, une spec sur un intent non validé et, après le lot 1c, un credential en clair. Le problème n'apparaît qu'en revue, ou pas du tout.

## Priorité

- **Niveau :** Haute (confirmé par le PO)
- **Justification :** Sans activation, les contrôles des lots 2, 3 et 1c ne jouent pas.
- **Échéance :** aucune

## Résultat attendu

Sur `ai-factory`, quand `core.hooksPath` ne vaut pas `hooks`, une session Claude Code le signale dès son ouverture et refuse les commits de l'agent, en donnant la commande qui active les hooks.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.
- Le lot contribue aux indicateurs de l'intent parent : nombre de cycles de reprise par PR. Le taux de succès CI au premier passage n'est pas mesurable : aucune CI n'est prévue sur `ai-factory`.

## Livrables

| Type | Élément |
|---|---|
| Hook Claude Code | Au démarrage de session (`SessionStart`) : signale un `core.hooksPath` absent et donne la commande |
| Hook Claude Code | Avant un `git commit` de l'agent (`PreToolUse`) : bloque tant que `core.hooksPath` est absent, avec la raison et la commande |

## Critère d'acceptation

- [ ] Sur un clone sans `core.hooksPath`, une session Claude Code le signale dès son ouverture et donne la commande `git config core.hooksPath hooks`.
- [ ] Sur un clone sans `core.hooksPath`, un `git commit` lancé par l'agent est refusé, et le message donne la raison et la commande.
- [ ] Sur un clone configuré, la session ne signale rien et le commit de l'agent passe.

## Contraintes

- Appliqué d'abord à `ai-factory`, seul dépôt où le SDLC tourne aujourd'hui (le dépôt pilote n'existe pas encore).
- Les hooks ne font que lire la configuration git : l'activation reste une commande lancée par l'humain.
- Les deux hooks sont déclarés dans `.claude/settings.json`, versionné.
- Aucune donnée sensible ni secret dans le contexte de l'agent.
- Un lot = un sous-intent = une PR.

## Hors périmètre

- Les contrôles eux-mêmes (lots 2, 3, 1c).
- Commits faits hors de Claude Code.
- Activation automatique de `core.hooksPath`.
- Contrôle en CI (le lot 13 couvre les credentials).

## Questions ouvertes

