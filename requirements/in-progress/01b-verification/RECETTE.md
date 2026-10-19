# Recette — Lot 1b : Commande de vérification

- **Date :** 2026-10-19
- **Exécution :** un clone propre de la branche `feat/lot-01b-verification` (commit 1b65b9c) par cas, sauf « Lot déplacé » qui reprend la préparation de « Deux échecs ». Commande lancée depuis la racine du clone. Les faux `run.sh` ne sont jamais commités. Les lignes `PASS` des `run.sh` de `hooks/tests/` sont omises ci-dessous : toutes `PASS`, aucune `FAIL`.

| Cas | Préparation et action | Sortie observée | Code | Réf. |
|---|---|---|---|---|
| Nominal | `scripts/verifier.sh` | `OK hooks/tests/hook-intent/run.sh`, `OK hooks/tests/hook-spec/run.sh`, `2 run.sh lancés, 0 en échec` | 0 | A1, A3 |
| Ajout après coup | `scripts/tests/recette-ok/run.sh` (`exit 0`), non commité (`?? scripts/tests/`), script inchangé | le nouveau `run.sh` nommé et `OK`, `3 run.sh lancés, 0 en échec` | 0 | A2, L1, L9 |
| Dossier caché | `.claude/hooks/tests/recette-ok/run.sh` (`exit 0`) | lancé en premier (tri par chemin), `OK`, `3 run.sh lancés, 0 en échec` | 0 | L9, C11 |
| Deux échecs | `scripts/tests/recette-ko/run.sh` et `requirements/in-progress/01b-verification/tests/recette-ko/run.sh` (`echo "FAIL recette"; exit 1`) | `FAIL recette` conservé, `ÉCHEC <chemin> (code 1)` pour chacun, les deux `hooks/tests/` lancés et `OK`, `4 run.sh lancés, 2 en échec` suivi des deux chemins | 1 | A4, L3, C4, C5 |
| Lot déplacé | suite du cas précédent, `git mv requirements/in-progress/01b-verification requirements/closed/` | `ÉCHEC requirements/closed/01b-verification/tests/recette-ko/run.sh (code 1)`, `4 run.sh lancés, 2 en échec` | 1 | L2 |
| Livrable renommé | `git mv hooks/tests/hook-spec hooks/tests/hook-spec-x` | `OK hooks/tests/hook-spec-x/run.sh`, `2 run.sh lancés, 0 en échec` | 0 | L2 |
| Sans bit exécutable | `chmod -x hooks/tests/hook-intent/run.sh` (`-rw-r--r--`) | `OK hooks/tests/hook-intent/run.sh` | 0 | L4 |
| Sous `fixtures/` | `hooks/tests/hook-intent/fixtures/recette/run.sh` (`exit 0`) | lancé et `OK`, `3 run.sh lancés, 0 en échec` | 0 | L6, C11 |
| Sous `.git/` | `.git/recette/run.sh` (`exit 1`) | absent de la sortie, `2 run.sh lancés, 0 en échec` | 0 | L10 |
| Aucun `run.sh` | `find . -name .git -prune -o -name run.sh -exec rm {} +` | `scripts/verifier.sh : aucun run.sh trouvé dans le dépôt` (stderr) | 1 | L5, C10 |
| Nouveau projet | `git archive HEAD` extrait, `requirements/` supprimé, `git init` et premier commit (contrats du lot 1h) | `2 run.sh lancés, 0 en échec` | 0 | L8 |
| Sous-dossier | `cd hooks && ../scripts/verifier.sh` | `scripts/verifier.sh : à lancer depuis la racine du dépôt : cd <racine du clone> && scripts/verifier.sh` | 1 | L7, C9 |
| Hors dépôt git | copie seule du script dans un dossier temporaire, `./verifier.sh` | `scripts/verifier.sh : à lancer depuis la racine du dépôt : scripts/verifier.sh` | 1 | C9 |
| Lien symbolique | clone ouvert via un lien symbolique, `scripts/verifier.sh` | `2 run.sh lancés, 0 en échec` | 0 | R4 |
| bash 3.2 | conteneur `bash:3.2` (3.2.57), git installé par `apk`, une fois au vert puis avec `scripts/tests/recette-ko/run.sh` en échec | au vert : `2 run.sh lancés, 0 en échec` ; en échec : `ÉCHEC scripts/tests/recette-ko/run.sh (code 1)`, `3 run.sh lancés, 1 en échec`. Aucun « unbound variable » | 0 puis 1 | C5, C6, R6 |

## Points à signaler en revue

- **Écart au plan, cas bash 3.2.** Le plan monte le clone dans le conteneur par `-v "$PWD":/w`. Le clone, sous `/tmp` du devcontainer, n'est pas visible du démon docker de l'hôte : il a été passé au conteneur par `tar` sur l'entrée standard. Même résultat attendu, même vérification.
- **Cas ajoutés au plan.** « Hors dépôt git » (message sans `<racine>`, étape 1 du plan) et « Lien symbolique » (R4 du plan), non listés dans le tableau de recette du plan.
- **A1 à A4** : OK. Pas de test automatisé de la commande (P1 de la spec).
