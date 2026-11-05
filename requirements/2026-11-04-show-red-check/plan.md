# Plan : 2026-11-04-show-red-check

<!--
  Gabarit copié par `git sdlc claim 2026-11-04-show-red-check build`, puis rempli par le skill
  generation-plan, en plan mode, sur la branche need/2026-11-04-show-red-check/build, une fois spec.md
  fusionnée sur main. Commitez le plan rempli seul, avant tout code ; une étape = un
  commit. Si l’implémentation diverge, mettez le plan à jour dans la même PR. Pas de
  champ « Statut » : la fusion de la PR fait foi.
-->

- Spec : [spec.md](spec.md) · Intent : [intent.md](intent.md)
- Auteur : Mathieu Texier
- À risque : non
- Base : 972543b

<!-- « À risque » : oui si l’intent porte « Risk: élevé » ou si le développeur l’estime d’après ce que le changement peut casser. Oui → avis d’un tech lead sur le plan avant le code. -->

## Prérequis

<!-- Intent et spec fusionnés sur main, besoins dont celui-ci dépend, base de départ. -->

- Intent fusionné sur main ; spec fusionnée, révision du 2026-11-05 comprise (C9, L9, A9), base `972543b`.
- Aucun besoin amont.
- `jq` disponible pour les tests (le faux `gh` applique `--jq` avec lui).

## Fichiers touchés

<!-- Nature : nouveau | modifié | supprimé. Étape : numéro de l’étape qui touche le fichier. -->

| Fichier | Nature | Étape |
|---|---|---|
| `bin/git-sdlc` | modifié | 1, 2 |
| `README.md` | modifié | 1 |
| `.sdlc/config` | modifié | 1 |
| `bin/tests/git-sdlc-checks/run.sh` | nouveau | 3 |
| `bin/tests/git-sdlc-checks/fixtures/*` | nouveau | 3 |

## Étapes

<!-- Numérotées dans l’ordre d’exécution. Une étape = un commit. Chaque étape cite les numéros C, L et A de la spec qu’elle couvre. Au-delà de 7 étapes, ou avec des étapes indépendantes, l’intent est peut-être à découper. -->

### 1. Détail des checks rouges dans `status`

- `JQ_PRS` et `load_prs` inchangés : `--porcelain` et `board` gardent leur sortie.
- `open_state` mémorise la PR à détailler (`RED_PR`) quand le résumé vaut `rouges`, sans appel GitHub : `board` passe aussi par là.
- Nouvelle fonction `red_checks <pr>` : `gh pr checks <pr> --json name,state,description,link` (code de retour non nul toléré), filtre `state` sur l'ensemble de C2 repris de `JQ_PRS` ; pour une description vide et un lien `…/job/<id>` ou `…/runs/<id>`, `gh api repos/{owner}/{repo}/check-runs/<id>` (titre, sinon résumé), puis ses annotations (premier `failure`). Toute erreur laisse la raison vide. Raison ramenée à une ligne ; champs vides omis.
- `cmd_status`, sortie humaine seulement : lignes insérées, indentées, sous `checks       rouges`.
- `README.md` : la ligne des preuves de `status` mentionne le détail.

Couvre : C1, C2, C3, C4, C5, C6, C8, C9, L1, L2, L3, L4, L5, L6, L7, L9, A1, A2, A3, A5, A6, A7, A8, A9.

### 2. Détail au refus de `merge`

- `cmd_merge` : `PR #<n> : checks rouges` sur la sortie d'erreur, puis les lignes de `red_checks`, puis code 1, sans fusion.

Couvre : C7, A4.

### 3. Tests avec un faux `gh`

- `bin/tests/git-sdlc-checks/run.sh` : dépôt git temporaire avec un remote nu, intent et spec sur `main`, `need/<id>/build` poussée ; un `gh` simulé en tête du `PATH` rejoue les JSON de `fixtures/` (`pr list` avec `--jq`, `pr checks`, `api`) et journalise ses appels. Une ligne `PASS`/`FAIL` par cas.

Couvre : A1, A2, A3, A4, A5, A6, A7, A8, A9, L8.

## Tests à écrire

<!-- Tests qui prouvent le changement (automatisés et manuels), avec la commande qui les lance. -->

- `bash bin/tests/git-sdlc-checks/run.sh` (lancé aussi par `bash scripts/verify.sh`) :
  - un check run rouge avec annotation : nom, conclusion, raison, lien (A1, A9, L9) ;
  - deux checks rouges, un en cours : deux lignes (A2, L1) ;
  - checks verts, en cours, absents : sortie identique à la référence, aucun appel `pr checks` ni `api` (A3, C5) ;
  - `merge` refusé : détail sur la sortie d'erreur, code 1, `pr merge` jamais appelé (A4) ;
  - `status --porcelain` identique à la référence ; `board` sans ligne de détail ; ni l'un ni l'autre n'appelle `pr checks` ou `api` (A5, L8). `board` passe par `column`, dont la sortie dépend de la locale : pas de référence figée ;
  - check run avec titre ; statut de commit avec description (A6, A7) ;
  - `gh api` en échec, check sans lien, raison sur plusieurs lignes (A8, L4, L5, L6).
- `bash -n bin/git-sdlc`.
- Manuel, côté hôte : `git sdlc status` sur une PR dont `sdlc-conventions` est rouge, décrit dans le commit (le jeton du devcontainer ne lit pas les PR).

## Couverture de la spec

<!-- Chaque numéro C, L et A de la spec rattaché à au moins une étape. -->

| Réf. | Étape |
|---|---|
| C1–C6, C8, C9 | 1 |
| C7 | 2 |
| L1–L7, L9 | 1, 3 |
| L8 | 1, 3 |
| A1–A3, A5–A9 | 1, 3 |
| A4 | 2, 3 |

## Risques

<!-- Ce que le changement peut casser, l’étape la plus risquée, et la parade prévue. Une question restée sans réponse reste visible ici. Puis les options écartées. -->

- Peut casser : la sortie de `status` sans check rouge, `--porcelain`, `board`, et le refus de `merge`. Parade : comparaison à une référence dans les tests (A3, A5, L8).
- Étape la plus risquée : 1, lecture des liens et tolérance aux erreurs de `gh` sous `set -e` (`gh pr checks` sort en 1 ou 8 quand des checks échouent ou tournent). Parade : cas L2–L6 dans les tests.
- Question reportée par l'intent : longueur maximale de la raison. Clé `checkReasonMax` de `.sdlc/config` (défaut 120, 0 : sans limite, valeur invalide signalée et remplacée par 120) ; au-delà, la raison est coupée et terminée par « … ».
- Références `fixtures/attendu-*.txt` : produites par la version de `main` d'avant ce besoin (`GIT_SDLC=<ancienne version> ATTENDU_ECRIRE=1 bash run.sh`) ; cette version échoue à 9 cas du test.
- Options écartées :
  - ajouter les champs à `JQ_PRS` : `statusCheckRollup` ne porte pas la raison, et `board` changerait ;
  - GraphQL `checkRun.annotations` : requête dédiée plus lourde que deux appels REST ;
  - tests manuels seuls (décision du développeur, 2026-11-05).

## Hors périmètre

<!-- Ce que le plan ne fait volontairement pas. -->

- `git sdlc board`, le détail des checks verts ou en cours, la relance des checks.
- Les autres commandes de `git-sdlc` et leurs tests.
