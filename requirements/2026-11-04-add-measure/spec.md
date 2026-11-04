# Spec : 2026-11-04-add-measure

<!--
  Gabarit copié par `git sdlc claim 2026-11-04-add-measure spec`, puis rempli par le skill
  generation-spec, sur la branche need/2026-11-04-add-measure/spec, une fois intent.md fusionné sur main.
  Le product owner relit la PR et la fusionne : pas de champ « Statut », l’étape se
  déduit de git (`git sdlc status 2026-11-04-add-measure`).
  Numéros C, L et A stables : une révision ajoute un nouveau numéro, elle ne renumérote
  jamais. Le plan et la recette s’y réfèrent.
-->

- Intent : [intent.md](intent.md)
- Auteur : Mathieu Texier

## Périmètre

Une sous-commande `git sdlc metrics` de `bin/git-sdlc`, en lecture seule. Elle recalcule à chaque appel, depuis l'historique git (branche principale, branches `need/*`, tags) et les PR GitHub lues par `gh`, les indicateurs du playbook listés dans l'intent. Elle les affiche par besoin, par PR et en agrégé (médiane), sur tout l'historique ou depuis une date (`--since`). Elle offre une sortie lisible et une sortie `--porcelain` (TSV) pour le reporting.

## Comportements

### Commande et sélection des besoins

- **C1.** `git sdlc metrics` accepte `--since <AAAA-MM-JJ>`, `--porcelain` et `--no-fetch`. Comme `status` et `board`, elle fait d'abord un fetch, sauf avec `--no-fetch`, puis lit les PR vers la branche principale dans la limite `prLimit`.
- **C2.** Les besoins sont ceux que liste déjà `board` : PR, branches `need/<id>/*`, dossiers `<intentDir>/<id>` sur la branche principale et tags `rejected/<id>`.
- **C3.** Avec `--since`, un besoin n'est retenu que si la date d'auteur du premier commit de son intent (C5) est postérieure ou égale à la date. Sans `--since`, tous les besoins sont retenus.
- **C4.** Les dates utilisées sont des dates qui survivent à la fusion par rebase (contrainte de l'intent) :
  - premier commit d'un artefact : date d'auteur ;
  - fusion d'une étape : `mergedAt` de la PR GitHub, sinon date de committer du commit de la branche principale qui porte `Need: <id>` et `Stage: <stage>`, c'est-à-dire la date du rebase, donc de la fusion (repli de `merge_info`) ;
  - release : date de publication GitHub, sinon date du tag, sinon date de committer du commit tagué (même ordre que `compute`).

### Plan

- **C5.** **Délai de rédaction de l'intent** : de la date d'auteur du premier commit qui touche `<intentDir>/<id>/intent.md` jusqu'à la fusion de l'étape intent. Ce premier commit est cherché sur la branche principale, sinon sur la branche `need/<id>/intent`.
- **C6.** **Survie d'un intent** : `accepté` si l'étape intent est fusionnée, même si le besoin est rejeté plus tard ; `rejeté` si le besoin est rejeté (PR fermée `sdlc:rejected` ou tag `rejected/<id>`) sans intent fusionné ; `en cours` sinon.
- **C7.** **Taux de survie** (agrégé) : accepté / (accepté + rejeté), sur les besoins retenus. Les besoins `en cours` ne comptent ni au numérateur ni au dénominateur.
- **C8.** **Retouches de l'intent** : nombre de commits de la branche principale qui touchent `intent.md` et dont la date d'auteur est postérieure à celle du premier commit qui touche `spec.md` du même besoin.

### Design

- **C9.** **Délai intent → spec** : de la fusion de l'étape intent à la fusion de l'étape spec.
- **C10.** **Retouches de la spec** : nombre de commits de la branche principale qui touchent `spec.md` et dont la date d'auteur est postérieure à celle du premier commit qui touche `plan.md` du même besoin.

### Build

- **C11.** **Délai spec → build** : de la fusion de l'étape spec à la fusion de l'étape build.
- **C12.** **Sortie du brouillon** d'une PR : date du dernier événement « ready for review » de sa timeline GitHub. Une PR jamais passée en brouillon en a pour date sa création.
- **C13.** **Premier passage** d'une PR fusionnée : `oui` si aucun de ses commits n'a une date de committer postérieure à sa sortie du brouillon (C12), `non` sinon. **Part au premier passage** (agrégé) : nombre de `oui` / nombre de PR fusionnées, par étape.
- **C14.** **Cycles de rework** d'une PR fusionnée : nombre d'intervalles contenant au moins un commit postérieur à la sortie du brouillon. Les bornes des intervalles sont la sortie du brouillon, chaque revue soumise et la fusion (arbitrage P1).

### Test et Deploy

- **C15.** **CI au premier passage** d'une PR : `oui` si le premier run terminé du check `sdlc-conventions` après la sortie du brouillon a réussi, `non` s'il a échoué, `—` si aucun run n'existe. Part (agrégée) : `oui` / (`oui` + `non`), par étape.
- **C16.** **Délai jusqu'à la première revue** : de la sortie du brouillon à la première revue soumise, quel que soit son état. `—` si la PR n'a reçu aucune revue.
- **C17.** **Durée de revue** : de la sortie du brouillon à la fusion de la PR.
- **C18.** C13 à C17 sont calculés pour chaque PR fusionnée des étapes intent, spec et build. La ligne d'un besoin (C22) reprend les valeurs de sa PR build ; les agrégats (C24) sont donnés par étape.

### DORA partiel

- **C19.** **Délai jusqu'à la release** : de la fusion de l'étape build jusqu'à la date (C4) de la première release `YY.MM.DD[.V]` qui contient le commit de fusion, c'est-à-dire la même release que `status` affiche.
- **C20.** **Fréquence des releases** : nombre de tags `YY.MM.DD[.V]` datés dans la fenêtre, divisé par le nombre de semaines de la fenêtre, à une décimale. La fenêtre va de `--since`, ou à défaut du plus ancien tag de release, jusqu'au jour de l'appel.

### CLAUDE.md

- **C21.** **Corrections de CLAUDE.md** : nombre de commits de la branche principale qui touchent `CLAUDE.md` à la racine, groupés par mois (`AAAA-MM`) de la date de committer, et restreints à la fenêtre `--since` s'il y en a une.

### Affichage

- **C22.** La sortie lisible comporte trois tableaux alignés (`align`) :
  - **Besoins**, une ligne par besoin retenu : survie, C5, C8, C9, C10, C11, C19, premier passage et rework du build ;
  - **PR**, une ligne par PR fusionnée : besoin, étape, numéro, C13 à C17 ;
  - **Agrégats** : médianes des délais, taux C7, parts C13 et C15 par étape, médianes C14, C16 et C17 par étape, C20, puis C21 mois par mois.
- **C23.** En sortie lisible, une durée s'écrit en heures sous 48 h (« 5 h ») et en jours au-delà (« 3,5 j »). Une valeur absente s'écrit « — ».
- **C24.** Chaque agrégat est la médiane des valeurs présentes (moyenne des deux valeurs centrales si leur nombre est pair) et indique son effectif `n`. Un agrégat sans aucune valeur vaut « — ».
- **C25.** Lecture seule : la commande n'appelle aucune commande `gh` qui écrit et aucune mutation GraphQL. En dehors du fetch, elle ne crée, ne déplace ni ne supprime aucune référence git, et ne modifie ni l'index ni la copie de travail.
- **C26.** Les détails de PR (timeline, commits, revues, checks) sont lus par une seule requête GraphQL paginée, par lots de 50, et seulement pour les PR fusionnées dont la branche est `need/<id>/<étape>`. Aucun appel n'est fait PR par PR, et aucun seuil de durée n'est imposé (arbitrage P3).
- **C27.** L'aide de la commande et le `README.md` signalent la limite de L8 : un rebase force-poussé après la sortie du brouillon compte comme du rework (arbitrage P2).

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Besoin à l'étape intent, sans spec ni build | C9, C10, C11, C19 et les colonnes du build affichent « — » ; aucune erreur (C22, C23). |
| L2 | Besoin rejeté par PR `sdlc:rejected` avant la fusion de l'intent | Survie `rejeté` (C6) ; C5 et toutes les colonnes suivantes affichent « — ». |
| L3 | Besoin rejeté par tag `rejected/<id>` après la fusion de l'intent | Survie `accepté` (C6) ; les délais des étapes non fusionnées affichent « — ». |
| L4 | Étape fusionnée sans PR GitHub trouvée (au-delà de `prLimit`, ou fusion faite hors `gh`) | Date de fusion par repli sur le commit portant les trailers (C4) ; C13 à C17 de cette étape affichent « — ». |
| L5 | Nombre de PR lues égal à `prLimit` | Avertissement sur stderr : résultats peut-être incomplets, augmenter `prLimit`. Le code de retour reste 0 (C1). |
| L6 | PR créée hors brouillon | La sortie du brouillon est la date de création de la PR (C12). |
| L7 | PR remise en brouillon puis ressortie | Seul le dernier événement « ready for review » compte (C12). |
| L8 | Branche rebasée et force-poussée après la sortie du brouillon | Les dates de committer récentes comptent comme du rework (C13, C14) ; ce biais est accepté et documenté (C27, arbitrage P2). |
| L9 | Aucun run du check `sdlc-conventions` (dépôt sans CI) | C15 affiche « — » pour la PR, et la part agrégée ne la compte pas. |
| L10 | Aucun tag de release, ou aucun dans la fenêtre | C19 affiche « — » ; C20 vaut 0,0 avec `--since`, « — » sans. |
| L11 | Aucun besoin retenu (dépôt neuf, `--since` dans le futur) | Message « Aucun besoin sur la période. », code 0 ; en `--porcelain`, seules les lignes `agg` et `claude` sont produites. |
| L12 | `--since` mal formé | Erreur `git-sdlc : date invalide pour --since : <valeur> (AAAA-MM-JJ)`, code 1, rien sur stdout. |
| L13 | Remote absent ou fetch en échec | Avertissement de `do_fetch`, calcul sur l'état local (C1). |
| L14 | `gh` non authentifié ou API indisponible | Erreur de `load_prs`, code 1 (même comportement que `board`). |
| L15 | Pas de `CLAUDE.md` à la racine | C21 n'affiche aucune ligne mensuelle et indique « — » (C24). |

## Contrats

**Ligne de commande**

```
git sdlc metrics [--since <AAAA-MM-JJ>] [--porcelain] [--no-fetch]
```

L'aide (`usage`) gagne cette ligne dans la section « Suivi ». Codes de retour : 0 en cas de succès, y compris sans besoin (L11) ; 1 pour une option inconnue, une date invalide (L12) ou une lecture GitHub impossible (L14).

**Sources lues** : `git log`, `git for-each-ref` et `git tag --contains` en local ; `gh pr list` (même requête que `load_prs`) ; une lecture GraphQL des PR `need/*` fusionnées, paginée par 50 (C26), qui ne fait que des `query` (timeline « ready for review », commits avec date de committer, revues avec `submittedAt`, runs du check `sdlc-conventions`) ; `gh release view` pour les dates de release. Toute lecture GitHub passe par `gh`, de sorte qu'un `gh` factice dans le `PATH` peut simuler GitHub en test.

**Sortie `--porcelain`** : TSV sans en-tête et sans alignement. Le premier champ donne le type de ligne. Les durées sont en heures décimales avec un point et une décimale (`26.5`), les parts entre 0 et 1 avec deux décimales (`0.75`) ; une valeur absente vaut `—`. L'ordre des colonnes est figé, et toute colonne ajoutée plus tard le sera en fin de ligne.

| Type | Colonnes après le type |
|---|---|
| `need` | id, survie (`accepté`/`rejeté`/`en cours`), délai intent (C5), retouches intent (C8), délai intent→spec (C9), retouches spec (C10), délai spec→build (C11), délai build→release (C19), premier passage build (`oui`/`non`/`—`), cycles de rework build |
| `pr` | id, étape (`intent`/`spec`/`build`), numéro, premier passage, cycles de rework, CI au premier passage, délai 1re revue (C16), durée de revue (C17) |
| `agg` | nom de l'indicateur, étape (ou `—`), valeur, n |
| `claude` | mois `AAAA-MM`, nombre de commits |

Noms d'indicateurs `agg` : `delai_intent`, `survie`, `retouches_intent`, `delai_intent_spec`, `retouches_spec`, `delai_spec_build`, `delai_build_release`, `premier_passage`, `rework`, `ci_premier_passage`, `delai_premiere_revue`, `duree_revue`, `releases_par_semaine`.

## Critères d’acceptation

Les tests automatisés vivent dans `bin/tests/metrics/run.sh` : un dépôt git temporaire, un `gh` factice qui sert des fixtures JSON, une ligne `PASS`/`FAIL` par cas.

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Chaque indicateur s'affiche par besoin et en agrégé | Un dépôt de fixtures avec un besoin livré (intent, spec, build fusionnés, release taguée) | `git sdlc metrics --no-fetch` | Les tableaux Besoins, PR et Agrégats contiennent une colonne ou une ligne pour chacun des indicateurs C5 à C21 | Automatisé |
| A2 | Valeurs calculées égales aux valeurs attendues | Le dépôt de fixtures de A1, aux dates d'auteur, de fusion, de revue et de release connues | `git sdlc metrics --porcelain --no-fetch` | Chaque ligne `need`, `pr` et `agg` est identique à la sortie attendue de la fixture | Automatisé |
| A3 | Médiane | Trois besoins aux délais intent de 2 h, 4 h et 30 h, puis un quatrième à 10 h | `--porcelain` | `agg delai_intent` vaut 4.0 (n=3), puis 7.0 (n=4) | Automatisé |
| A4 | Besoin incomplet → « — » sans erreur | Un besoin à l'étape intent (L1) et un besoin rejeté par PR `sdlc:rejected` (L2) | `git sdlc metrics --no-fetch` | Code 0 ; colonnes non calculables à « — » ; survie `en cours` puis `rejeté` | Automatisé |
| A5 | Besoin incomplet → « — » sans erreur | Un besoin rejeté par tag après la fusion de son intent (L3) | `--porcelain` | Survie `accepté` ; `agg survie` compte ce besoin au numérateur | Automatisé |
| A6 | Fenêtre `--since` | Deux besoins, intents commencés le 2026-10-01 et le 2026-11-01 | `--since 2026-10-15 --porcelain` | Une seule ligne `need` (le second) ; les `n` des agrégats valent 1 | Automatisé |
| A7 | Fenêtre `--since` | Aucun argument valide | `--since 15/10/2026` | Code 1, message de L12, stdout vide | Automatisé |
| A8 | `--porcelain` stable pour la direction | Le dépôt de fixtures de A1 | Deux appels successifs à `--porcelain --no-fetch` | Sorties identiques, TSV sans en-tête, colonnes conformes au contrat, aucun alignement par espaces | Automatisé |
| A9 | `--porcelain` stable pour la direction | La sortie de A8 | Import dans un tableur (LibreOffice ou Excel) | Une colonne par champ, durées reconnues comme nombres | Manuel |
| A10 | La commande n'écrit rien | Le dépôt de fixtures, avec un `gh` factice qui journalise ses arguments | `git sdlc metrics --no-fetch` | Le journal ne contient que des lectures (`pr list`, `release view`, `api graphql` sans `mutation`) ; `git status --porcelain` et `git for-each-ref` sont identiques avant et après | Automatisé |
| A11 | Premier passage et rework | Une PR fusionnée avec deux commits après la sortie du brouillon, séparés par une revue | `--porcelain` | Premier passage `non`, cycles de rework `2` | Automatisé |
| A12 | CI au premier passage | Deux PR : premier run `sdlc-conventions` en échec puis en succès, et premier run en succès | `--porcelain` | `non` puis `oui` ; `agg ci_premier_passage` vaut 0.50 | Automatisé |
| A13 | Résultats sur un dépôt réel | Le dépôt ai-factory sur GitHub | `git sdlc metrics` | Le besoin 2026-11-04-add-measure apparaît, et ses délais concordent avec les dates des PR sur GitHub | Humain |

## Points d’attention

Arbitrés le 2026-11-04 par Mathieu Texier (voir `tldr.md`) :

- **P1. Cycle de rework.** git n'enregistre pas l'heure d'un push. Un cycle est donc un intervalle entre la sortie du brouillon, les revues successives et la fusion qui contient au moins un commit (C14).
- **P2. Rebase avant revue.** Le biais est accepté sans détection des force-push, et documenté (L8, C27).
- **P3. Performance.** Une requête GraphQL paginée par 50, limitée aux PR `need/*` fusionnées, sans seuil de durée (C26).
- **P4. Tests de `bin/git-sdlc`.** Premier test automatisé du script, dans `bin/tests/metrics/run.sh`, avec un `gh` factice. Au build, `CLAUDE.md` précisera que seule `metrics` est testée et que le reste garde `bash -n`.
- **P5. Aucun skill de standards** dans `.claude/skills/` ne couvre le format des sorties CLI ni les conventions de reporting. La forme suit celle de `status` et `board`.

## Hors périmètre

- Tout ce que l'intent exclut : OpenTelemetry, outil de suivi des incidents, evals, boucle Maintain, triage des pipelines, délai d'une politique jusqu'à sa skill, temps jusqu'à la première PR d'un nouvel arrivant, exports CSV et JSON, collecte en continu, tableau de bord web.
- Les métriques d'un besoin isolé (`git sdlc metrics <id>`) : `git sdlc status <id>` reste la vue d'un besoin.
- Les seuils, alertes et bandes de contrôle sur ces indicateurs.
- Les PR qui ne suivent pas les branches `need/<id>/<étape>`, comme les correctifs `Need: none`.

## Questions ouvertes

<!-- Questions de l’intent non tranchées, et informations manquantes. Peut rester vide. -->

Les questions ouvertes de l'intent ont été tranchées au moment de l'intent (voir `tldr.md`) et sont reprises en C3, C20, C24, C13, C14 et dans les contrats. Aucune.
