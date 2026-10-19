# Recette — Lot 1f : Activation des hooks git

- **Date :** 2026-10-19
- **Exécution :** branche `feat/lot-1f-activation-hooks` (commit 8c35ef7), depuis la racine du dépôt.

## Tests automatisés

| Cas | Action | Résultat observé | Réf. |
|---|---|---|---|
| 13 cas du hook | `bash .claude/hooks/tests/hook-activation/run.sh` | 13 `PASS`, code 0 | C1–C9, C12, L1–L5, L7, L8 |
| Tests capables d'échouer | copie de `.claude/` avec `hooks_git_actifs` muté (comparaison finale remplacée par `true`) | le cas `.git/hooks` passe en `FAIL` | C12 |
| Commande du `settings.json` | commande `PreToolUse` extraite du fichier et lancée via `sh -c`, entrée `git commit -m x` | dépôt actif : code 0 ; clone sans `core.hooksPath` : code 2, raison et commande sur stderr | C6, C7, C10 |
| JSON `SessionStart` | sortie de `session-hooks-git.sh` sur un clone inactif, passée à `python3 -m json.tool` | JSON valide, `systemMessage` et `hookSpecificOutput.additionalContext` identiques | C2 |
| Fichiers suivis | `git check-ignore -v .claude/settings.json .claude/hooks/*.sh .claude/hooks/tests/hook-activation/run.sh` | aucune sortie : rien n'est ignoré sur ce poste | C10, R6 |
| Ensemble du dépôt | `bash scripts/verifier.sh` | `4 run.sh lancés, 0 en échec` | C11 |

## Recette en session réelle (A1 à A3)

Faite par un humain le 2026-10-19 dans un clone jetable, une nouvelle session Claude Code par cas. Approuver les hooks du projet si Claude Code le demande (R4).

| #   | Préparation                         | Action                                                                                    | Attendu                                                                                              | Observé |
| --- | ----------------------------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- | ------- |
| A1  | `git config --unset core.hooksPath` | ouvrir une session                                                                        | message « Hooks git inactifs… » visible, avec `git config core.hooksPath hooks` ; l'agent le connaît | OK      |
| A2  | idem                                | demander un commit à l'agent                                                              | commande refusée ; l'agent rapporte la raison et la commande                                         | OK      |
| A3  | `git config core.hooksPath hooks`   | ouvrir une session, puis demander le commit d'un intent incomplet, puis d'un fichier sain | aucun message à l'ouverture ; intent incomplet refusé par `pre-commit` ; fichier sain commité        | OK      |

Constaté pendant la recette : une session lancée depuis un dossier parent du dépôt ne charge pas `.claude/settings.json`, et rien n'est signalé ni bloqué. Claude Code ne lit les réglages de projet que dans le dossier de lancement ([documentation](https://code.claude.com/docs/en/settings.md)). Limite documentée dans le README, traitement au lot 1i (P6, R7).

## Points à signaler en revue

- **Écart au plan, racine du dépôt.** `hooks-git-actifs.sh` prend le toplevel git de `$CLAUDE_PROJECT_DIR` au lieu de `$CLAUDE_PROJECT_DIR` tel quel. Le résultat est le même à la racine, et le hook tient aussi pour une session ouverte dans un sous-dossier.
- **`CLAUDE.md` à 60 lignes**, soit la limite du lot 1e (C6). La prochaine ligne demandera d'en retirer une.
- **Spec modifiée après validation** : chemin des tests (C11, contrats, 2cda17d) et point P6 (lancement hors de la racine). Le statut reste `validé`, et la modification est à confirmer par le tech lead.
- **Plan au statut `draft`** : il n'a pas été validé avant le build.
