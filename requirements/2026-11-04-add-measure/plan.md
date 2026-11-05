# Plan : 2026-11-04-add-measure

<!--
  Gabarit copié par `git sdlc claim 2026-11-04-add-measure build`, puis rempli par le skill
  generation-plan, en plan mode, sur la branche need/2026-11-04-add-measure/build, une fois spec.md
  fusionnée sur main. Commitez le plan rempli seul, avant tout code ; une étape = un
  commit. Si l’implémentation diverge, mettez le plan à jour dans la même PR. Pas de
  champ « Statut » : la fusion de la PR fait foi.
-->

- Spec : [spec.md](spec.md) · Intent : [intent.md](intent.md)
- Auteur : Mathieu Texier
- À risque : non
- Base : 6ba975d

<!-- « À risque » : oui si l’intent porte « Risk: élevé » ou si le développeur l’estime d’après ce que le changement peut casser. Oui → avis d’un tech lead sur le plan avant le code. -->

## Prérequis

<!-- Intent et spec fusionnés sur main, besoins dont celui-ci dépend, base de départ. -->

- Intent et spec fusionnés sur `main` (`6ba975d`) ; aucun besoin dont celui-ci dépend.
- `jq` installé pour lancer les tests, pas pour la commande : `git-sdlc` n'utilise que le `--jq` intégré à `gh`.

## Fichiers touchés

<!-- Nature : nouveau | modifié | supprimé. Étape : numéro de l’étape qui touche le fichier. -->

| Fichier | Nature | Étape |
|---|---|---|
| `bin/git-sdlc` | modifié | 1 à 6 |
| `bin/tests/metrics/run.sh` | nouveau | 1 à 5 |
| `bin/tests/metrics/fixtures/gh` (gh factice) | nouveau | 1, 3, 4 |
| `bin/tests/metrics/fixtures/*.json` (PR, GraphQL, releases) | nouveau | 1 à 5 |
| `README.md` | modifié | 6 |
| `templates/projet/README.md` | modifié | 6 |
| `CLAUDE.md` | modifié | 6 |
| `requirements/2026-11-04-add-measure/tldr.md` | modifié | 6 |

Principes communs aux étapes :

- **Aucune fonction existante modifiée.** `cmd_metrics` et ses fonctions `m_*` s'ajoutent au script. Sont réutilisés tels quels `cfg`, `do_fetch`, `resolve_main`/`main_ref`, `branch_ref`, `list_ids` (sur un fichier `$PRS` propre à metrics, l'id en colonne 1), `has_tag`, `RELEASE_GLOBS`, `re_escape`, `align`, `die` et `warn`. Ne sont pas réutilisés `load_prs`, `merge_info`, `pr_get` et `merge_of`, qui tronquent les dates au jour ou retiennent la fusion la plus récente (C4).
- **Dates en epoch UTC dès la source.** Côté git : `%at`, `%ct`, `%(taggerdate:unix)`. Côté GitHub : `fromdateiso8601` dans le `--jq` de `gh`. `--since` est converti en awk, par arithmétique sur les jours. « Aujourd'hui » vient de `date -u +%s`, remplaçable par la variable `SDLC_NOW`, réservée aux tests. Ni `date -d` (GNU) ni `mktime` (gawk) : bash 3.2 et awk POSIX, comme sur macOS.
- **Collecte en bash, calcul en awk.** Les sources produisent des TSV temporaires, nettoyés par le `trap` existant. Un programme awk calcule les valeurs par besoin, par PR et en agrégé : médiane par tri d'insertion, taux, fréquence. Il émet les lignes `need`, `pr`, `agg` et `claude`, d'où la sortie lisible est rendue.

## Étapes

<!-- Numérotées dans l’ordre d’exécution. Une étape = un commit. Chaque étape cite les numéros C, L et A de la spec qu’elle couvre. Au-delà de 7 étapes, ou avec des étapes indépendantes, l’intent est peut-être à découper. -->

### 1. Squelette de `metrics` et banc de test

- **Options.** `--since`, `--porcelain` et `--no-fetch`. La date est validée (L12, rien sur stdout).
- **Lecture des PR.** Fetch, puis un `gh pr list` propre à metrics : champs de `load_prs` plus `createdAt`, dates en epoch. Un avertissement est émis si le nombre lu atteint `prLimit` (L5).
- **Besoins.** Ils viennent de `list_ids` ; sans besoin, la commande affiche « Aucun besoin sur la période. » (L11).
- **Aide et aiguillage.** Ligne d'aide dans « Suivi », et cas `metrics)` dans l'aiguillage.
- **Banc de test.** `bin/tests/metrics/run.sh` crée un dépôt git temporaire (`GIT_CONFIG_GLOBAL=/dev/null`) et écrit une ligne PASS/FAIL par cas. Un gh factice, en tête du `PATH`, journalise ses arguments, sert les JSON de `fixtures/` et applique le filtre `--jq` avec `jq`.

Couvre : C1, C2, C25, L5, L11, L12, L13, L14, A7, A10.

### 2. Fusions et délais depuis git et la liste des PR

- **Première fusion d'une étape.** La plus ancienne de deux dates : celle de la première PR `MERGED` de `need/<id>/<étape>`, et celle du plus ancien commit `--first-parent` de main qui porte `Need:` et `Stage:` (C4, L4, L20).
- **Filtre `--since`.** Il porte sur la date de début du besoin (C3, L2).
- **Premier commit d'un artefact.** `git log --reverse --format=%at` sur main, sinon sur la branche de l'étape (C5).
- **Indicateurs.** Survie (C6, C7, L3), retouches (C8, C10), délais C9 et C11, médiane et `n` (C24).
- **Sortie.** Lignes `need` et `agg` en `--porcelain`.

Couvre : C3, C4, C5, C6, C7, C8, C9, C10, C11, C24, L1, L2, L3, L4, L20, A3, A4, A5, A6, A14, A19.

### 3. Releases et CLAUDE.md

- **Dates de release.** Un seul appel `gh release list --json tagName,publishedAt`. À défaut, date du tag, puis date de committer du commit tagué.
- **Release d'un besoin.** Celle qui contient la première fusion du build, trouvée par `git tag --contains` comme dans `compute` (C19).
- **Fréquence.** Sur une fenêtre qui compte ses deux jours extrêmes, et 0,0 si `--since` est dans le futur (C20, L10, L19).
- **CLAUDE.md.** Commits de `CLAUDE.md` par mois UTC (C21, L15), émis en lignes `claude`.

Couvre : C19, C20, C21, L10, L15, L19, A17.

### 4. Lecture GraphQL des PR

- **PR lues.** Les PR `need/*` fusionnées, d'après l'étape 1.
- **Requêtes.** `gh api graphql -F owner='{owner}' -F name='{repo}'`, par lots de 50 alias `pullRequest(number:)`.
- **Limites de C26.** Un événement « ready for review » (`last: 1`), 100 revues, 100 commits, 10 suites filtrées sur `sdlc-conventions` par commit, 1 run par suite.
- **Pagination.** Une liste qui atteint sa limite est complétée par des requêtes à curseur propres à la PR ou au commit (L18).
- **Calculs.** Sortie du brouillon (C12, L6, L7), revues retenues (C28, L16), premier passage (C13, L8), rework (C14), CI au premier passage avec runs non concluants ignorés (C15, L9, L17), C16 et C17, valeurs du build sur la ligne du besoin (C18).
- **Sortie.** Lignes `pr` et agrégats par étape.

Couvre : C12, C13, C14, C15, C16, C17, C18, C26, C28, L6, L7, L8, L9, L16, L17, L18, A11, A12, A15, A16.

### 5. Sortie lisible

- **Tableaux.** Besoins, PR et Agrégats, alignés et rendus depuis les lignes `--porcelain`.
- **Formats.** « 5 h » sous 48 h (heures arrondies), « 3,5 j » au-delà, « — » pour une valeur absente (C22, C23).
- **Fixture.** Une fixture complète, avec sa sortie `--porcelain` attendue figée.

Couvre : C22, C23, A1, A2, A8.

### 6. Documentation

- **Aide et `README.md` du kit.** Section `metrics`, et limite du rebase force-poussé (C27, L8).
- **`templates/projet/README.md`.** Ligne `git sdlc metrics` dans le suivi.
- **`CLAUDE.md`.** Seule `metrics` a un test automatisé, le reste garde `bash -n` (P4), et la sortie saine de `verify.sh` passe à 6 `run.sh`.
- **`tldr.md`.** Mis à jour.

Couvre : C27, A9, A13, A18.

## Tests à écrire

<!-- Tests qui prouvent le changement (automatisés et manuels), avec la commande qui les lance. -->

- `bash bin/tests/metrics/run.sh`, aussi lancé par `bash scripts/verify.sh` : un cas PASS/FAIL pour chacun de A1 à A8, A10 à A12, A14 à A17 et A19, ainsi que pour L5, L12 et L18.
- `bash -n bin/git-sdlc` à chaque étape.
- Recette manuelle, avec un jeton qui lit les PR :
  - A9 : import de la sortie `--porcelain` dans un tableur ;
  - A18 : requête d'un lot de 50 PR passée avec `rateLimit(dryRun: true)`, `nodeCount` ≤ 500 000 ;
  - A13 : `git sdlc metrics` sur ai-factory, délais comparés aux PR GitHub.

## Couverture de la spec

<!-- Chaque numéro C, L et A de la spec rattaché à au moins une étape. -->

| Réf. | Étape |
|---|---|
| C1, C2, C25 | 1 |
| C3 à C11, C24 | 2 |
| C19, C20, C21 | 3 |
| C12 à C18, C26, C28 | 4 |
| C22, C23 | 5 |
| C27 | 6 |
| L5, L11, L12, L13, L14 | 1 |
| L1, L2, L3, L4, L20 | 2 |
| L10, L15, L19 | 3 |
| L6, L7, L8, L9, L16, L17, L18 | 4 (L8 documenté en 6) |
| A7, A10 | 1 |
| A3, A4, A5, A6, A14, A19 | 2 |
| A17 | 3 |
| A11, A12, A15, A16 | 4 |
| A1, A2, A8 | 5 |
| A9, A13, A18 | 6 (recette manuelle) |

## Risques

<!-- Ce que le changement peut casser, l’étape la plus risquée, et la parade prévue. Une question restée sans réponse reste visible ici. Puis les options écartées. -->

- **Lecture GraphQL (étape 4), l'étape la plus risquée.** La forme de la requête, les limites et la pagination ne se vérifient contre le vrai GitHub qu'à la recette (A18, puis A13). Parades : les limites sont mesurées en dry-run (110 050 nœuds pour 50 PR), et le gh factice sert des réponses à la forme réelle.
- **Postulat non vérifié.** Chaque exécution de `sdlc.yml` est censée former sa propre suite de checks (C26). Si c'est faux, des runs peuvent manquer. À contrôler en A13.
- **Portabilité.** L'arithmétique des dates et les formats sont écrits en awk POSIX, mais testés avec mawk et GNU awk, pas avec le BWK awk de macOS.
- **Écart avec la spec.** Ses sources et A10 citent `gh release view`, alors que le build lit `gh release list` : une lecture aussi, en un seul appel. À signaler dans la PR.
- **`bin/git-sdlc` est déployé sur chaque poste.** Un défaut dans l'aiguillage ou l'aide toucherait toutes les commandes. Parades : aucune fonction existante modifiée, `bash -n`, et les autres `run.sh` doivent passer.
- **Coût GitHub.** 552 points par lot de 50 PR, soit environ 450 PR par heure dans le quota de 5 000 points.
- **Taille.** 6 étapes chaînées, sans branche parallèle : pas de découpage. L'étape 4 est la plus grosse.

Options écartées :

- réutiliser `load_prs` et `merge_info` (dates tronquées, fusion la plus récente) ;
- `gh pr view` PR par PR ;
- `gh run list` pour la CI (API Actions, refusée aux PAT sans droit Actions) ;
- un gh factice qui sert des sorties déjà filtrées (les filtres `--jq` ne seraient pas testés) ;
- `gh release view` par tag ;
- `jq` comme dépendance de `git-sdlc` ;
- `date -d` de GNU.

## Hors périmètre

<!-- Ce que le plan ne fait volontairement pas. -->

- Tout ce que la spec exclut : `metrics <id>`, seuils et alertes, PR hors `need/<id>/<étape>`, OpenTelemetry, exports CSV et JSON.
- Aucun test ni refonte des autres commandes : `load_prs`, `merge_info` et `compute` restent tels quels.
