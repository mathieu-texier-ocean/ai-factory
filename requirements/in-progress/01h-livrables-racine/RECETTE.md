# Recette — Lot 1h : Livrables rangés à la racine

- **Date :** 2026-10-19
- **Exécution :** clone propre de la branche `feat/lot-01h-livrables-racine` (commit 1332aae), `core.hooksPath` à `hooks`, commandes lancées depuis la racine du clone.

| Critère | Commande ou action | Résultat |
|---|---|---|
| A1 | `ls hooks/tests/hook-intent hooks/tests/hook-spec` ; `git log --follow --oneline` sur les deux `run.sh`, `fixtures/complet.md` et `fixtures/intent-valide.md` | OK : `run.sh` et `fixtures/` dans chaque dossier ; l'historique remonte à 0a2903e (lot 2) et 9eb212a (lot 3). Le commit d82ff0e ne contient que des renommages à 100 %, modes `100755` conservés |
| A2 | `bash hooks/tests/hook-intent/run.sh` ; `bash hooks/tests/hook-spec/run.sh` | OK : 7 et 9 lignes `PASS`, aucune autre, code 0 pour chacun. Aussi lancés depuis `/tmp` : code 0 (L4) |
| A3 | `git mv requirements/closed/03-spec requirements/closed/03-spec-x`, relance des deux `run.sh`, puis `git reset --hard` | OK : code 0 pour chacun |
| A4 | `git grep -nP '(?<!hooks/)tests/hook-(intent\|spec)' -- ':!requirements/*/01h-livrables-racine/*'` | OK : aucune ligne |
| A5 | Relecture du `README.md` (section « Ranger les livrables », commandes vers `hooks/tests/`) par le tech lead, en PR | À faire |
| A6 | `ls requirements/closed/02-intent/tests requirements/closed/03-spec/tests` | OK : `skills-intent` et `skills-spec` (avec `RESULTATS.md`) seuls |
| A7 | `git grep -nE 'requirements/(open\|in-progress\|closed)/([0-9]\|ia-factory)' -- ':!requirements'` | OK : aucune ligne. `git grep -n 'ia-factory.md' -- ':!requirements'` : aucune ligne. Restent les seules conventions génériques du README (`requirements/<état>/NN-lot/`) |
| A8 | `git archive HEAD` extrait dans un dossier temporaire, `requirements/` supprimé, `git init` et premier commit, puis les deux `run.sh` | OK : code 0 pour chacun. Le README n'a plus aucun lien relatif, donc aucun lien cassé dans la copie (C14) |

## Points à signaler en revue

- **Correction du plan validé.** L'exclusion `':!requirements/*/01h-livrables-racine'` des recherches ne correspondait à aucun fichier. Elle est devenue `…/01h-livrables-racine/*` (commit 2bf8516).
- **R1 du plan.** Sur `feat/lot-01a-contexte`, `CLAUDE.md` et `README.md` citent les anciens chemins. Le plan 1a (étape 2, Architecture) place encore les `tests/` dans le dossier du lot. Le second lot mergé adapte.
- **R2 du plan.** La spec 1b (C2) découvre les `run.sh` dans les dossiers de lots, donc pas dans `hooks/tests/`. À réviser avant d'implémenter 1b.
- **R5 du plan 1a.** `requirements/closed/02-intent/tests/skills-intent/README.md` cite toujours `requirements/open/01-socle/intent.md`. Non corrigé (hors périmètre).
