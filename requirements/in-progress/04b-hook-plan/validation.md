# Recette — Lot 4b : Étape Plan, refus d'un plan sans amont validé

- **Date :** 2026-10-21
- **Exécution :** branche `feat/lot-4b-hook-plan` (commit 6598b9c), depuis la racine du dépôt, git 2.51.1.

## Tests automatisés

| Cas | Action | Résultat observé | Réf. |
|---|---|---|---|
| Contrôle du plan | `bash hooks/tests/hook-plan/run.sh` | 34 lignes `PASS`, code 0 | A1 à A11, L1 à L5, L7 à L21 |
| Tests écrits avant le hook | même commande sur a4e8338 (hook du lot 3) | refus attendus en `FAIL` (rc=0), cas acceptés en `PASS` | R6 du plan |
| Ensemble du dépôt | `bash scripts/verifier.sh`, après les étapes 2 et 3 | `6 run.sh lancés, 0 en échec` | A12 |

Entre les étapes 2 et 3, avec le hook modifié mais non commité, `scripts/tests/ai-factory/run.sh` échouait : il crée un projet depuis `HEAD`, qui portait encore l'ancien hook. Vert dès le commit (5c3a657).

## Recette manuelle

| Réf. | Action | Résultat observé |
|---|---|---|
| A13 | Dépôt jetable, trois dossiers dans l'état de A1, A2 et A8, un `plan.md` dans chacun, `bash hooks/pre-commit` | `a1/plan.md : intent absent (a1/intent.md)` · `a2/plan.md : spec non validée (statut : draft)` · `a8/plan.md : intent non validé (statut : draft)`, code 1. Chaque ligne nomme le plan et l'intent attendu ou le statut trouvé : OK |
| Clôture du lot | Clone jetable de la branche, `git mv requirements/in-progress/04b-hook-plan requirements/closed/04b-hook-plan`, `bash hooks/pre-commit` | Trois `R100` (intent, plan, spec), aucun refus, code 0 : OK |

## Critères d'acceptation

| # | Résultat | Constat |
|---|---|---|
| A1 à A11 | OK | `hook-plan/run.sh`, voir ci-dessus. |
| A12 | OK | `6 run.sh lancés, 0 en échec`. |
| A13 | OK | Messages ci-dessus. |
| A14 | OK | Spec validée par un humain (04ca046). |

## Points à signaler en revue

- **Plan validé avant le code.** Plan rédigé avec le skill `generation-plan` (a703c8c, A2 du 4a), validé par le développeur (ea93601). Relecture par un développeur qui n'a pas vu la séance (A3 du 4a) et validation tech lead (`À risque : oui`) attendues en revue.
- **Écart au plan, étape 1.** 34 scénarios au lieu des 28 environ prévus : L18 est joué avec un intent `validé` et avec un intent `draft` (le refus doit nommer le chemin accentué brut), L21 avec les deux statuts, L8 sur l'intent et sur la spec. Le plan n'a pas été modifié.
- **Fonctions `present_index` et `statut_index`** : utilisées par le seul contrôle du plan ; `check_spec_intent` du lot 3 est inchangée (C11, C18). Le lot 3b s'y branchera.
- **L6** n'a pas de scénario : il relève du contrôle de la spec du lot 3 (P2), traité au lot 3b.
- **Lot 4a** : `validation.md` du 4a à compléter sur `main` (A2 à A5) après le merge de cette PR.
