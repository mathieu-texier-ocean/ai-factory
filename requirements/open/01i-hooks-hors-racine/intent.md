# Sous-intent — Lot 1i : Hooks Claude Code hors de la racine du dépôt

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **Date :** 2026-10-19
- **Validation :** Tech lead
- **Dépend de :** 1f (activation des hooks git)
- **Origine :** limite constatée pendant la recette du lot 1f (P6 de sa spec, R7 de son plan)

## Problème

Claude Code ne lit le `.claude/settings.json` de projet que dans le dossier où il est lancé ([documentation](https://code.claude.com/docs/en/settings.md)) ; `--add-dir` ne le charge pas non plus. Une session lancée depuis un dossier parent (par exemple `/home/ocean/Projets`, puis travail dans `ticket/ai-factory`) ne charge donc aucun hook d'`ai-factory` : le commit de l'agent n'est pas refusé quand `core.hooksPath` est absent, et rien ne le signale. C'est l'usage courant sur nos postes.

## Pour qui

- **Agent** : bloqué au commit quand les hooks git ne sont pas actifs, quel que soit le dossier de lancement.
- **Équipe** : n'a pas à se souvenir de lancer Claude Code depuis la racine.

## Pourquoi

Le lot 1f ne protège que les sessions lancées à la racine du dépôt. Ailleurs, on retombe sur le cas qu'il devait supprimer : un commit non contrôlé, sans aucun message.

## Priorité

- **Niveau :** à définir par le PO
- **Justification :**
- **Échéance :** aucune

## Résultat attendu

Un `git commit` lancé par l'agent dans un dépôt `ai-factory` (ou un projet qui en dérive) est refusé tant que `core.hooksPath` n'y vaut pas `hooks`, même si la session a été lancée hors de la racine de ce dépôt. Le message donne la raison et la commande d'activation.

## Critère de succès

- Session lancée depuis un dossier parent, clone sans `core.hooksPath` : le commit de l'agent est refusé, avec la raison et la commande.
- Même session, clone configuré : le commit passe.
- Session lancée à la racine : comportement du lot 1f inchangé, sans double message.

## Contraintes

- Piste étudiée : un hook `PreToolUse` livré par un plugin interne (marketplace déjà utilisée, comme `shiftmove-core`), activé au niveau de l'utilisateur. Il part du `cwd` de la commande (qui suit les `cd`, contrairement à `CLAUDE_PROJECT_DIR`), remonte au dépôt git et n'agit que si ce dépôt contient `.claude/hooks/commit-hooks-git.sh`.
- Le hook ne fait que lire la configuration git : l'activation reste une commande humaine.
- Aucune donnée sensible ni secret dans le contexte de l'agent.
- Un lot = un sous-intent = une PR.

## Hors périmètre

- Le signalement à l'ouverture de session depuis un dossier parent : au démarrage, le dépôt de travail n'est pas connu.
- Les managed settings (administration Claude Code de l'organisation).
- Commits faits hors de Claude Code.

## Questions ouvertes

- Plugin interne ou script qui écrit dans `~/.claude/settings.json` : à trancher par le tech lead.
- Dans quel dépôt vit le plugin (marketplace interne) et qui le maintient ?
- Session lancée à la racine : comment éviter que le plugin et le hook du lot 1f jouent tous les deux ?
