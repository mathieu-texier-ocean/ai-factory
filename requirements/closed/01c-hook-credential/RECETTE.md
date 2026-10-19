# Recette — Lot 1c : Hook credential en clair

- **Date :** 2026-10-19
- **Exécution :** un clone propre de la branche `feat/lot-01c-hook-credential` (commit c0e9c58), `core.hooksPath hooks`, commandes lancées depuis la racine. Chaque cas repart du commit de base (`git reset --hard`, `git clean`). Les fichiers d'essai sont des copies des fixtures, jamais commités. Les tests automatisés ont été relancés après la correction de `run.sh` (2ef5d5a, voir plus bas) : mêmes résultats.

| Cas | Préparation et action | Sortie observée | Code | Réf. |
|---|---|---|---|---|
| Tests du contrôle | `bash hooks/tests/hook-credential/run.sh` | 25 `PASS`, aucun `FAIL` | 0 | A4, C10 |
| Tests existants | `scripts/verifier.sh` | `OK` pour `hook-credential`, `hook-intent` et `hook-spec`, `3 run.sh lancés, 0 en échec` | 0 | A3, C12 |
| Credential refusé | copie de `url.txt` en `config.txt`, `git add`, `git commit` | `config.txt : credential en clair (URL avec identifiants). Retirez la valeur, remplacez-la par une référence (variable d'environnement, gestionnaire de secrets) et révoquez-la si elle est réelle. Faux positif : ajoutez credential-ok en commentaire sur la ligne.` | 1 | A1, C5, C6 |
| Valeur jamais affichée | copie de `aws.txt` en `notes.txt`, commit | message nommant `notes.txt`, la clé fictive absente de la sortie | 1 | A1, C7 |
| Sans credential | copie de `propre.txt` en `notes.txt`, commit | aucun message | 0 | A2, C8 |
| Fixture modifiée | une ligne de jeton fictif ajoutée à `fixtures/slack.txt`, commit normal | `hooks/tests/hook-credential/fixtures/slack.txt : credential en clair (jeton fournisseur)…` | 1 | L6 (avant révision, inversé depuis : voir plus bas) |
| Faux positif annoté | `doc.txt` avec une affectation fictive suivie de `# credential-ok`, commit | aucun message | 0 | L9, C14 |
| Nouveau projet | `git archive HEAD` extrait, `requirements/` supprimé, `git init`, premier commit **sans** hook, puis `scripts/verifier.sh` | `3 run.sh lancés, 0 en échec` | 0 | lot 1h C14 |
| Mutations du hook | un défaut réintroduit à la fois dans `hooks/pre-commit`, puis `run.sh` | sans `-z` : L12 et L14 en `FAIL` ; diff sur le seul nouveau chemin : L13 ; sans guillemet optionnel : « affectation littérale entre guillemets » ; sans filtre `credential-ok` : L9 et L10 ; hook qui affiche la ligne : les deux cas C7 | 1 | C2, C3, C7, C13, C14 |

## Points à signaler en revue

- **Valeur fictive dans `run.sh`, corrigée.** La recette a trouvé la clé AWS d'exemple écrite en dur dans `run.sh` pour le test C7. Elle était passée parce que `run.sh` avait été commité avant le hook. Corrigé dans 2ef5d5a : les valeurs sont lues dans les fixtures. Seule autre occurrence hors fixtures : la même clé d'exemple dans `plan.md` (tableau des fixtures), commitée avant le hook, sous `requirements/` donc absente d'un nouveau projet (R2).
- **Premier commit d'un nouveau projet avec le hook déjà actif : refusé** (résolu par la révision ci-dessous). Le lot 1h (C14) demande « dépôt git, premier commit » sans dire si le hook est actif. S'il l'est, le hook refuse les fixtures de `hook-credential` et `run.sh` (contenu déjà commité dans `ai-factory` avec `--no-verify`, mais neuf pour le nouveau dépôt), et aussi `templates/spec.md`, pris pour une spec sans intent (contrôle du lot 3, antérieur à ce lot). Premier commit sans hook, ou avec `--no-verify`, puis activation : tout passe. À trancher par le tech lead : ordre documenté dans la création d'un projet, ou exclusion de `hooks/tests/*/fixtures/` et `templates/` par les contrôles. Le refus de `run.sh` disparaît avec 2ef5d5a.
- **Écarts au plan**, déjà connus en revue : fixtures `intent-incomplet.md` (cas C9) et `affectation-guillemets.txt` (second commit `--no-verify`), L14 testé sur `dossier é/clé é.txt` (accent et espace), mention dans `CLAUDE.md` (commit à part).
- **R5 du plan** : les deux contrôles existants lisent toujours les chemins sans `-z` ; un `intent.md` ou `spec.md` sous un dossier au nom accentué leur échappe. Hors périmètre (C1).
- **A1 à A4** : OK.

## Révision du 2026-10-19 : fixtures et modèle exclus

- **Exécution :** commit c145afb. Tests automatisés dans le dépôt de travail ; A5, L18 et le contrôle de non-régression dans une copie `git archive HEAD` sans `requirements/`, `git init`, `core.hooksPath hooks`.

| Cas | Préparation et action | Sortie observée | Code | Réf. |
|---|---|---|---|---|
| Tests du contrôle | `bash hooks/tests/hook-credential/run.sh` | 31 `PASS`, aucun `FAIL` (dont L6, L16 à L18) | 0 | C16 |
| Tests des specs | `bash hooks/tests/hook-spec/run.sh` | `PASS modèle templates/spec.md ignoré`, `PASS spec sous lot/templates/ contrôlée`, aucun `FAIL` | 0 | C17, L20, A6 |
| Tous les tests | `scripts/verifier.sh` | `3 run.sh lancés, 0 en échec` | 0 | A3 |
| Premier commit d'un nouveau projet | copie sans `requirements/`, hook actif, `git add .`, `git commit` sans `--no-verify` | aucun message, puis `scripts/verifier.sh` : `3 run.sh lancés, 0 en échec` | 0 | A5, L19 |
| Fixture déplacée | dans la copie, `git mv hooks/tests/hook-credential/fixtures/aws.txt doc/aws.txt`, commit | aucun message | 0 | L18, P6 |
| Credential hors fixtures | dans la copie, copie de `url.txt` en `notes.txt`, commit | `notes.txt : credential en clair (URL avec identifiants)…` | 1 | A1 |
| Mutations du hook | sans le `/` en tête du chemin ; motif `*fixtures/*` au lieu de `*/tests/*/fixtures/*` | L16 (racine) en `FAIL` ; L17 (`fixtures/`, `tests/fixtures/`) en `FAIL` | 1 | C16 |

- **A5, A6** : OK. P6 constaté (L18) : une fixture déplacée hors de `fixtures/` sans modification passe.
