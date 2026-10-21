# Plan — Lot 3b : Étape Spec, contrôle de la spec aligné sur celui du plan

- **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **À risque :** oui (contrôle bloquant de `hooks/pre-commit`, actif sur tous les commits de spec du dépôt et des projets mis à jour par `scripts/ai-factory.sh update` : un faux refus bloque une spec, un faux accept laisse entrer une spec sur un intent non validé)
- **Validation :** Tech lead
- **Base :** `feat/lot-3b-hook-spec` (3a88b05 : `main` 561f5f4, lot 4b clos, + intent rédigé 4c270a2, validé 3a88b05)

## Prérequis

- Intent commité au statut `validé` (3a88b05). Pas de spec : l'intent décide (skill `generation-plan`, étape 2).
- Lot 4b mergé sur `main` (561f5f4) : `present_index`, `statut_index`, `check_plan` et la boucle `-z` sont disponibles. Branche rebasée dessus.
- Commit du plan (`Lot 3b : rédige le plan`) avant tout code. Le même commit déplace le dossier vers `in-progress/` et ajoute la ligne 3b dans `requirements/open/ia-factory.md`.
- Une seule PR pour le lot. Une étape = un commit (`Lot 3b : <verbe> …`).
- Sans spec, ce plan fait la déclaration que l'intent laissait à la spec du lot : **C14, L4 et A11 du lot 3 (`requirements/closed/03-spec/spec.md`) sont remplacés.** La spec close n'est pas modifiée.

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `requirements/in-progress/03b-hook-spec/` (dossier déplacé depuis `open/`) | modifié | prérequis |
| `requirements/in-progress/03b-hook-spec/plan.md` | nouveau | prérequis |
| `requirements/open/ia-factory.md` | modifié (ligne 3b) | prérequis |
| `hooks/tests/hook-spec/run.sh` | modifié | 1 |
| `hooks/tests/hook-spec/fixtures/intent-sans-statut.md` | nouveau | 1 |
| `hooks/pre-commit` | modifié (commentaire de tête, `check_spec_intent` supprimée, boucle commune) | 2 |
| `README.md` | modifié (« Créer une spec depuis un intent validé ») | 3 |
| `templates/projet/README.md` | modifié (même section) | 3 |
| `CLAUDE.md` | modifié (ligne « Intent validé et spec ajoutée dans le même commit » retirée des erreurs fréquentes) | 3 |
| `requirements/in-progress/03b-hook-spec/validation.md` | nouveau | 4 |

## Étapes

### 1. Tests du contrôle de la spec (écrits avant le hook)

`hooks/tests/hook-spec/run.sh` : même cadre (`fx`, `init`, `attempt`, `check`). `init` vide aussi `lot2/`, `lot é x/`, `tests/` et `hooks/tests/x/` entre deux cas.

Nouvelle fixture `intent-sans-statut.md` : intent complet sans ligne `**Statut :**`, dérivé de `hooks/tests/hook-plan/fixtures/intent-sans-statut.md`. Les autres fixtures restent inchangées.

Scénarios ajoutés ou modifiés :

| Cas | État initial (HEAD) | Commit testé | Attendu | Critère de l'intent |
|---|---|---|---|---|
| `git mv` vers un intent draft | `lot/` intent `validé` + spec ; `lot2/` intent `draft` | `git mv lot/spec.md lot2/spec.md` | refus, `lot2/spec.md : intent non validé (statut : draft)` | 1 |
| renommage sous le seuil | idem | `git mv` + contenu remplacé | refus | 1 |
| autre fichier renommé en spec | intent `draft`, `lot/brouillon.md` | `git mv` → `lot/spec.md` | refus | 1 |
| dossier accentué avec espace, intent validé | `lot é x/` intent `validé` | `lot é x/spec.md` | accepté | 2 |
| dossier accentué, intent draft | `lot é x/` intent `draft` | `lot é x/spec.md` | refus, chemin brut `lot é x/spec.md : intent non validé (statut : draft)` | 2 |
| intent passé à validé dans le même commit | intent `draft` | intent → `validé` + `lot/spec.md` | **accepté** (remplace « validé dans le même commit bloqué », A11/L4 du lot 3) | 3, 8 |
| intent draft dans le même commit | — | `lot/intent.md` `draft` + `lot/spec.md` | refus, `statut : draft` | 3 |
| intent supprimé | intent `validé` | `git rm lot/intent.md` + `lot/spec.md` | refus, `lot/spec.md : intent absent (lot/intent.md)` | 4 |
| statut absent | intent sans `**Statut :**` | `lot/spec.md` | refus, `lot/spec.md : intent non validé (statut : absent)` | 5 |
| fixtures | — | `hooks/tests/x/fixtures/spec.md`, puis `tests/x/fixtures/spec.md` | acceptés | 6 |
| spec et plan dans le même commit, intent passé à validé | intent `draft` | intent → `validé` + `lot/spec.md` `validé` + `lot/plan.md` | accepté (L6 du 4b, maintenant cohérent) | 7 |

Scénarios du lot 3 conservés tels quels : intent draft, intent absent, validé ligne seule et ligne de l'auteur, casse `Validé`, autre fichier ignoré, modification de spec acceptée, spec à la racine, `templates/spec.md` ignoré (critère 6), `lot/templates/spec.md` contrôlé.

Sur ce commit seul, `verifier.sh` est rouge (`hook-spec` en échec), comme aux lots 3 et 4b. Le message de commit le signale.

Couvre : critères d'acceptation 1 à 6 et 8 de l'intent.

### 2. Contrôle de la spec branché sur la lecture du plan

Dans `hooks/pre-commit` :
- `present_index` et `statut_index` remontent avant le premier contrôle qui les utilise ; leur code ne change pas.
- `check_spec_intent` est supprimée et remplacée par `check_spec <spec>` : dossier par `dirname`, `intent.md` si `.` ; `present_index "$intent"` sinon `<spec> : intent absent (<intent>)` ; `statut_index "$intent"` différent de `validé` → `<spec> : intent non validé (statut : <valeur>)`. Refus sur stderr, `status=1`, et le hook continue.
- L'ancienne boucle `--name-only --diff-filter=A` est supprimée. La boucle `-z -M --diff-filter=AR` du plan devient commune : mêmes exclusions (`templates/*` à la racine, `*/tests/*/fixtures/*`), puis `case "$(basename "$chemin")" in spec.md) check_spec ;; plan.md) check_plan ;; esac`.
- Commentaire de tête : le contrôle 2 est décrit comme le 4 (créé ou renommé, intent lu dans l'index, exclusions), et la lecture commune est dite une fois.
- Bash et git seulement.

Ordre des messages : quand un commit refuse à la fois des specs et des plans, les lignes suivent l'ordre des chemins du diff, et non plus « specs d'abord ». Aucun test ne dépend de cet ordre.

Couvre : critère 7 (une seule lecture de l'amont) ; fait passer l'étape 1 ; critère 9 vérifié par `hook-plan`, `hook-intent` et `hook-credential` inchangés.

### 3. Documentation

- `README.md`, section « Créer une spec depuis un intent validé » : le prérequis « et commité… refusé » est remplacé par « commitez-le, ou stagez-le avec la spec ». L'étape 3 « Committer » décrit maintenant le refus sur création ou renommage, les deux messages (dont `statut : absent`), l'intent lu dans le commit en cours sinon dans le dernier commit, et l'exclusion des fixtures.
- `templates/projet/README.md` : mêmes changements, sans référence aux lots.
- `CLAUDE.md` : la ligne « Intent validé et spec ajoutée dans le même commit → refusé » est retirée des erreurs fréquentes. La ligne `hooks/pre-commit` de l'Architecture reste juste telle quelle. Le retrait passe par la PR et demande l'approbation du code owner de `CLAUDE.md`.
- Le tableau de `README.md` (ligne `hook-spec`) reste juste.

Couvre : critère 8 (le changement de comportement est documenté ; il est aussi signalé dans la PR).

### 4. Recette et validation

- `bash scripts/verifier.sh` : 6 `run.sh` lancés, 0 en échec (critère 9).
- Manuel, en conditions réelles : dans un clone jetable, `git mv` d'une spec existante du dépôt vers un dossier dont l'intent est `draft`, puis `bash hooks/pre-commit` → refus. `git mv` de `requirements/in-progress/03b-hook-spec` vers `closed/`, puis `bash hooks/pre-commit` → aucun refus (le dossier sera déplacé avec un intent sans spec).
- Contrôle de clôture du dépôt : `git mv` de chaque dossier `closed/*` qui contient une spec vers un nom temporaire, puis `bash hooks/pre-commit` → aucun faux refus sur les specs historiques (leurs intents sont `validé`).
- `validation.md` au format de `requirements/closed/04b-hook-plan/validation.md`.

Couvre : critère 9, plus la preuve manuelle des critères 1 et 2.

## Tests à écrire

- Automatisés : `hooks/tests/hook-spec/run.sh` complété (11 scénarios ajoutés ou modifiés, 10 conservés), lancé par `bash scripts/verifier.sh` sans modifier ce script.
- Manuels : renommage et clôture en conditions réelles (étape 4).
- Non-régression : `hooks/tests/hook-plan`, `hook-intent`, `hook-credential`, `.claude/hooks/tests/hook-activation` et `scripts/tests/ai-factory` restent inchangés et au vert.

## Couverture de la spec

Sans objet : il n'y a pas de spec. Rattachement des critères d'acceptation de l'intent :

| Critère de l'intent | Étape |
|---|---|
| 1. `git mv` vers un intent non validé refusé | 1, 2, 4 |
| 2. Dossier accentué accepté | 1, 2, 4 |
| 3. Intent validé dans le même commit accepté, draft refusé | 1, 2 |
| 4. Intent supprimé → intent absent | 1, 2 |
| 5. Statut absent → `(statut : absent)` | 1, 2 |
| 6. `templates/spec.md` et fixtures acceptés | 1, 2 |
| 7. Même lecture de l'amont pour la spec et le plan | 2 |
| 8. Scénario A11 du lot 3 remplacé, signalé en PR | 1, 3 |
| 9. Tests existants au vert | 2, 4 |

## Risques

- **R1 — L'étape 2 (boucle commune) est la plus risquée.** Elle touche aussi le contrôle du plan déjà livré : une erreur de lecture des enregistrements `-z` ou du dispatch casse les deux contrôles. Le pire cas est un faux accept, une spec qui passe sans intent validé. Parade : tests écrits avant le hook (étape 1), `hook-plan` (34 scénarios) inchangé et au vert, `verifier.sh` après chaque commit, contrôle sur les specs réelles du dépôt (étape 4).
- **R2 — Faux vert des tests.** Un état initial mal remis à zéro peut faire passer un scénario pour une autre raison. Parade : `init` vide tous les dossiers utilisés, et chaque refus attendu vérifie le message exact.
- **R3 — Changement de comportement visible.** « Intent validé et spec dans le même commit » était refusé et documenté comme erreur fréquente dans `CLAUDE.md`. Désormais il passe. Parade : doc, `CLAUDE.md` et PR mis à jour ensemble (étape 3) ; le retrait de la ligne demande l'approbation du code owner de `CLAUDE.md`.
- **R4 — Projets déjà créés.** `ai-factory.sh update` livrera le nouveau hook. Une spec qu'un projet aurait déplacée par `git mv` vers un dossier non validé est maintenant refusée, ce qui est voulu.
- **R5 — Écart avec le skill.** Le déplacement du dossier et la ligne du parent partent dans le commit du plan à la demande du développeur. Le skill `generation-plan` interdit, à lui seul, de modifier l'intent parent : c'est signalé ici.

Options écartées :
- Deux boucles `-z`, une par contrôle : la lecture des enregistrements serait dupliquée, ce qui est contraire à la contrainte de l'intent (« réutilise sa lecture de l'amont au lieu de la dupliquer »).
- Lire l'intent dans `HEAD` puis dans le diff, séparément : l'index donne directement l'état après commit, suppressions comprises (même choix qu'au 4b).

## Hors périmètre

Ceux de l'intent : contrôle du plan (lot 4b), contenu d'une spec et modification d'une spec existante, skill `generation-spec` (il lit l'arbre de travail), spec close du lot 3, laissée telle quelle.

## Vérification

- Après chaque commit à partir de l'étape 2 : `bash scripts/verifier.sh` → `6 run.sh lancés, 0 en échec`.
- `bash hooks/tests/hook-spec/run.sh` et `bash hooks/tests/hook-plan/run.sh` : toutes les lignes en `PASS`.
- Étape 4 : `validation.md` rempli.
