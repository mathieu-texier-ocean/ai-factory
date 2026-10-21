# Recette — Lot 3b : Étape Spec, contrôle de la spec aligné sur celui du plan

- **Date :** 2026-10-21
- **Exécution :** branche `feat/lot-3b-hook-spec` (commit 57c27ad), depuis la racine du dépôt, git 2.51.1.

## Tests automatisés

| Cas | Action | Résultat observé | Réf. |
|---|---|---|---|
| Contrôle de la spec | `bash hooks/tests/hook-spec/run.sh` | 22 lignes `PASS`, code 0 | critères 1 à 6 et 8 |
| Tests écrits avant le hook | même commande sur 1ab8490 (hook du lot 3) | 10 `FAIL` : les 10 comportements nouveaux, avec les refus attendus absents ou un message différent ; les 12 autres en `PASS` | étape 1 du plan |
| Contrôle du plan | `bash hooks/tests/hook-plan/run.sh` | 34 lignes `PASS`, sans modification du test | critère 9, R1 du plan |
| Ensemble du dépôt | `bash scripts/verifier.sh`, après les étapes 2 et 3 | `6 run.sh lancés, 0 en échec` | critère 9 |

## Recette manuelle

Clone jetable de la branche (57c27ad), `bash hooks/pre-commit` sur l'index.

| Réf. | Action | Résultat observé |
|---|---|---|
| Critère 1 | `git mv requirements/closed/03-spec/spec.md requirements/open/05-code-tests/spec.md` (intent `draft`) | `R`, puis `requirements/open/05-code-tests/spec.md : intent non validé (statut : draft)`, code 1 : OK |
| Critère 2 | `requirements/open/99-é x/` avec un intent `draft` et une `spec.md` | `requirements/open/99-é x/spec.md : intent non validé (statut : draft)`, chemin brut, code 1 : OK |
| Clôture du lot | `git mv requirements/in-progress/03b-hook-spec requirements/closed/03b-hook-spec` | Deux `R` (intent, plan), aucun refus, code 0 : OK |
| Specs historiques | `git mv` de chacun des 11 dossiers de `closed/` qui contiennent une `spec.md`, vers `<dossier>-tmp` | 18 `spec.md` renommées ; un refus : `requirements/closed/04a-plan-tmp/tests/skills-plan/sans-intent/spec.md : intent absent (…)`. Voir « Points à signaler » |

## Critères d'acceptation

| # | Résultat | Constat |
|---|---|---|
| 1 | OK | `git mv` vers un intent `draft` refusé, renommage sous le seuil et autre fichier renommé en `spec.md` aussi ; recette manuelle. |
| 2 | OK | Dossier `lot é x/` : accepté avec un intent `validé`, refusé avec le chemin brut sinon. |
| 3 | OK | Intent passé à `validé` dans le même commit : accepté ; intent `draft` dans le même commit : refusé. |
| 4 | OK | Intent supprimé dans le commit de la spec : `intent absent (lot/intent.md)`. |
| 5 | OK | `(statut : absent)`. |
| 6 | OK | `templates/spec.md`, `hooks/tests/x/fixtures/spec.md` et `tests/x/fixtures/spec.md` acceptés. |
| 7 | OK | `check_spec` et `check_plan` sont appelées par la même boucle `-z -M --diff-filter=AR` et lisent l'amont par `present_index` / `statut_index` ; `check_spec_intent` est supprimée. |
| 8 | OK | Scénario « validé dans le même commit bloqué » remplacé par sa version acceptée ; README, README de projet et `CLAUDE.md` mis à jour. À signaler dans la PR. |
| 9 | OK | `6 run.sh lancés, 0 en échec`. |

## Points à signaler en revue

- **Changement de comportement (critère 8).** Un intent passé à `validé` dans le même commit que la spec est désormais accepté. Cela remplace C14, L4 et A11 du lot 3 ; la spec close du lot 3 n'est pas modifiée. La ligne correspondante des erreurs fréquentes de `CLAUDE.md` est retirée : il faut l'approbation du code owner de `CLAUDE.md`.
- **Dossier accentué : contournement, pas faux refus.** L'intent décrit un faux « intent absent ». Constaté sur 1ab8490 avec git 2.51.1 : le chemin entre guillemets donne le basename `spec.md"`, et la spec n'est donc **pas contrôlée du tout**. Elle était acceptée même avec un intent `draft`. Le correctif couvre les deux lectures.
- **Jeux de test d'exigence hors `fixtures/`.** `requirements/closed/04a-plan/tests/skills-plan/sans-intent/spec.md` n'a pas d'intent et n'est pas sous un dossier `fixtures/`. Un déplacement du dossier 04a serait donc refusé, alors que l'ancien hook ignorait les renommages. Les dossiers de `closed/` ne sont plus déplacés, donc rien n'est bloqué aujourd'hui. Mais un futur lot qui range des `spec.md` ou `plan.md` de test hors `tests/<nom>/fixtures/` verra sa clôture refusée ; le contrôle du plan a déjà ce comportement. Hors périmètre de l'intent (exclusions = fixtures, comme pour le plan) : à trancher, soit en rangeant ces cas sous `fixtures/`, soit en élargissant l'exclusion dans un lot à part.
- **Écart au plan, étape 1.** Deux fixtures ajoutées au lieu d'une : `intent-sans-statut.md` et `spec-valide.md`, cette dernière pour le scénario spec + plan dans le même commit, où le contrôle du plan exige une spec `validé`. `init` vide tout le dépôt (hors hook et modèle d'intent), comme dans `hook-plan`, au lieu de lister les dossiers. Le plan n'a pas été modifié.
- **Ordre des messages.** Les refus de spec et de plan suivent l'ordre des chemins du diff ; aucun test n'en dépend.
