# Recette — Lot 1c : Hook credential en clair

- **Date :** 2026-10-19
- **Exécution :** un clone propre de la branche `feat/lot-01c-hook-credential` (commit 345b3ef), `core.hooksPath hooks`, commandes lancées depuis la racine. Chaque cas repart du commit de base (`git reset --hard`, `git clean`). Les fichiers d'essai sont des copies des fixtures, jamais commités. Les tests automatisés ont été relancés après la correction de `run.sh` (fe1538e, voir plus bas) : mêmes résultats.

| Cas | Préparation et action | Sortie observée | Code | Réf. |
|---|---|---|---|---|
| Tests du contrôle | `bash hooks/tests/hook-credential/run.sh` | 25 `PASS`, aucun `FAIL` | 0 | A4, C10 |
| Tests existants | `scripts/verifier.sh` | `OK` pour `hook-credential`, `hook-intent` et `hook-spec`, `3 run.sh lancés, 0 en échec` | 0 | A3, C12 |
| Credential refusé | copie de `url.txt` en `config.txt`, `git add`, `git commit` | `config.txt : credential en clair (URL avec identifiants). Retirez la valeur, remplacez-la par une référence (variable d'environnement, gestionnaire de secrets) et révoquez-la si elle est réelle. Faux positif : ajoutez credential-ok en commentaire sur la ligne.` | 1 | A1, C5, C6 |
| Valeur jamais affichée | copie de `aws.txt` en `notes.txt`, commit | message nommant `notes.txt`, la clé fictive absente de la sortie | 1 | A1, C7 |
| Sans credential | copie de `propre.txt` en `notes.txt`, commit | aucun message | 0 | A2, C8 |
| Fixture modifiée | une ligne de jeton fictif ajoutée à `fixtures/slack.txt`, commit normal | `hooks/tests/hook-credential/fixtures/slack.txt : credential en clair (jeton fournisseur)…` | 1 | L6 |
| Faux positif annoté | `doc.txt` avec une affectation fictive suivie de `# credential-ok`, commit | aucun message | 0 | L9, C14 |
| Nouveau projet | `git archive HEAD` extrait, `requirements/` supprimé, `git init`, premier commit **sans** hook, puis `scripts/verifier.sh` | `3 run.sh lancés, 0 en échec` | 0 | lot 1h C14 |
| Mutations du hook | un défaut réintroduit à la fois dans `hooks/pre-commit`, puis `run.sh` | sans `-z` : L12 et L14 en `FAIL` ; diff sur le seul nouveau chemin : L13 ; sans guillemet optionnel : « affectation littérale entre guillemets » ; sans filtre `credential-ok` : L9 et L10 ; hook qui affiche la ligne : les deux cas C7 | 1 | C2, C3, C7, C13, C14 |

## Points à signaler en revue

- **Valeur fictive dans `run.sh`, corrigée.** La recette a trouvé la clé AWS d'exemple écrite en dur dans `run.sh` pour le test C7. Elle était passée parce que `run.sh` avait été commité avant le hook. Corrigé dans fe1538e : les valeurs sont lues dans les fixtures. Seule autre occurrence hors fixtures : la même clé d'exemple dans `plan.md` (tableau des fixtures), commitée avant le hook, sous `requirements/` donc absente d'un nouveau projet (R2).
- **Premier commit d'un nouveau projet avec le hook déjà actif : refusé.** Le lot 1h (C14) demande « dépôt git, premier commit » sans dire si le hook est actif. S'il l'est, le hook refuse les fixtures de `hook-credential` et `run.sh` (contenu déjà commité dans `ai-factory` avec `--no-verify`, mais neuf pour le nouveau dépôt), et aussi `templates/spec.md`, pris pour une spec sans intent (contrôle du lot 3, antérieur à ce lot). Premier commit sans hook, ou avec `--no-verify`, puis activation : tout passe. À trancher par le tech lead : ordre documenté dans la création d'un projet, ou exclusion de `hooks/tests/*/fixtures/` et `templates/` par les contrôles. Le refus de `run.sh` disparaît avec fe1538e.
- **Écarts au plan**, déjà connus en revue : fixtures `intent-incomplet.md` (cas C9) et `affectation-guillemets.txt` (second commit `--no-verify`), L14 testé sur `dossier é/clé é.txt` (accent et espace), mention dans `CLAUDE.md` (commit à part).
- **R5 du plan** : les deux contrôles existants lisent toujours les chemins sans `-z` ; un `intent.md` ou `spec.md` sous un dossier au nom accentué leur échappe. Hors périmètre (C1).
- **A1 à A4** : OK.
