# Recette — Lot 1g : Protection des tests pendant un correctif

- **Date :** 2026-10-28
- **Exécution :** branche `feat/lot-1g-protection-tests` (commit a3efc53), depuis la racine du dépôt.

## Tests automatisés

| Cas | Action | Résultat observé | Réf. |
|---|---|---|---|
| 27 cas du hook | `bash .claude/hooks/tests/protection-tests/run.sh` | 27 `PASS`, code 0 | C1–C8, L1–L5, L8–L11, logique de A1–A5 |
| Tests capables d'échouer | copie de `.claude/` avec le test « sous `tests/` » de `protege` remplacé par `:` | 3 cas en `FAIL` : Edit hors `tests/`, `cd ..` hors de `tests/`, écriture hors `tests/` | C2, C7 |
| Commande du `settings.json` | commande de la 2e entrée `PreToolUse` extraite du fichier et lancée via `sh -c`, entrée Edit d'un test existant | dépôt jetable sur `bugfix/r` : décision `ask` ; dépôt sur `feat/…` : aucune sortie, code 0 | C1, C3, C9 |
| JSON de la décision | sortie précédente passée à `python3 -m json.tool` | JSON valide, `hookSpecificOutput.permissionDecision` = `ask`, raison avec branche, fichier et rappel | C6 |
| Hook du lot 1f intact | `bash .claude/hooks/tests/hook-activation/run.sh` | 13 `PASS`, code 0 | C9 |
| Fichiers suivis | `git check-ignore -v .claude/settings.json .claude/hooks/protection-tests.sh .claude/hooks/tests/protection-tests/run.sh` | aucune sortie : rien n'est ignoré sur ce poste | C9 |
| Ensemble du dépôt | `bash scripts/verifier.sh` | `7 run.sh lancés, 0 en échec` | — |

## Recette en session réelle (A1 à A5, L7, P4)

Faite par un humain le 2026-10-28, dans un clone jetable, Claude Code lancé depuis la racine, sur une branche `bugfix/recette` (sauf A5). Approuver les hooks du projet si Claude Code le demande.

| # | Préparation | Action | Attendu | Observé |
|---|---|---|---|---|
| A1 | `bugfix/recette` | demander à l'agent de modifier `hooks/tests/hook-intent/run.sh` | confirmation demandée, avec la branche, le fichier et le rappel | OK |
| A2 | idem | demander à l'agent de supprimer ce fichier avec `rm` | confirmation demandée | OK |
| A3 | idem | demander à l'agent de créer `hooks/tests/nouveau/run.sh` avec Write | créé sans confirmation | OK |
| A4 | idem | demander à l'agent de modifier `README.md` | modifié sans confirmation | OK |
| A5 | `feat/recette` | refaire A1 | modifié sans confirmation | OK |
| L7 | `bugfix/recette` | refaire A1 et refuser la confirmation | fichier inchangé ; l'agent rapporte le refus | OK |
| P4 | idem | refaire A1 en mode auto, puis en `bypassPermissions` | noter si la demande apparaît ; sinon, limite à ajouter au README | OK |

## Points à signaler en revue

- **Écart au plan, couverture du `run.sh`.** 27 cas au lieu des 16 lignes du tableau du plan : `cp`, `tee`, glob, `cd ..`, test hors du dépôt et écriture hors `tests/` ajoutés.
- **`settings.json`** : la ligne du lot 1f ne change que par la virgule ajoutée en fin de ligne.
- **P2 sans réponse** : `git checkout`/`git restore -- tests/…` passent sans confirmation ; mentionné dans le README.
