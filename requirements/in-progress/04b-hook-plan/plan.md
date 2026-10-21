# Plan — Lot 4b : Étape Plan, refus d'un plan sans amont validé

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **À risque :** oui (contrôle bloquant ajouté à `hooks/pre-commit`, actif sur tous les commits du dépôt et des projets mis à jour par `scripts/ai-factory.sh update` : un faux refus bloque tout commit d'un plan)
- **Validation :** Tech lead
- **Base :** `feat/lot-4b-hook-plan` (04ca046 : `main` 6642eb5, lot 4a clos, + spec rédigée fedf468, tranchée 56f7a4d, validée 04ca046).

## Prérequis

- `spec.md` commitée au statut `validé` : fait (04ca046). Arbre de travail propre, rien à stager avec le plan.
- Ce plan produit par le skill `generation-plan` du lot 4a (A2 du 4a), commité seul (`Lot 4b : rédige le plan`) avant tout code, puis relu par un développeur qui n'a pas vu la séance (A3 du 4a) et validé par le tech lead.
- Une seule PR pour le lot. Chaque étape ci-dessous = un commit (`Lot 4b : <verbe> …`).
- Lots dont celui-ci dépend : 3 (contrôle de la spec, motif de statut) et 4a (`templates/plan.md`, skill) : mergés sur `main`.

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `requirements/in-progress/04b-hook-plan/plan.md` | nouveau | prérequis |
| `hooks/tests/hook-plan/run.sh` | nouveau | 1 |
| `hooks/tests/hook-plan/fixtures/` (intents, specs, plan modèle) | nouveaux | 1 |
| `hooks/pre-commit` | modifié (commentaire de tête, fonctions de lecture, contrôle du plan) | 2 |
| `README.md` | modifié (tableau du dépôt, section « Produire le plan », liste des tests) | 3 |
| `templates/projet/README.md` | modifié (mêmes ajouts, sans référence aux lots) | 3 |
| `CLAUDE.md` | modifié (ligne `hooks/pre-commit` en place, 60 lignes) | 3 |
| `requirements/open/ia-factory.md` | modifié (lien du 4a vers `../closed/04a-plan/`, P4) | 3 |
| `requirements/in-progress/04b-hook-plan/validation.md` | nouveau | 4 |

## Étapes

### 1. Tests du contrôle (écrits avant le hook)

`hooks/tests/hook-plan/run.sh` sur le modèle de `hooks/tests/hook-spec/run.sh` : dépôt temporaire, copie de `hooks/pre-commit` et `templates/intent.md`, `core.hooksPath hooks`, état initial commité avec `-c core.hooksPath=/dev/null`, fonctions `fx`, `init`, `attempt` reprises. `init` vide `lot/`, `lot2/`, la racine et les dossiers de fixtures entre deux cas.

Fixtures dans `hooks/tests/hook-plan/fixtures/` (C14), intents complets dérivés de `hooks/tests/hook-spec/fixtures/` pour que le contrôle de sections ne masque pas le résultat :
- `intent-draft.md`, `intent-valide.md` (statut sur sa propre ligne), `intent-valide-auteur.md` (ligne de l'auteur), `intent-statut-majuscule.md` (`Validé`), `intent-sans-statut.md` ;
- `spec-draft.md`, `spec-valide.md`, `spec-sans-statut.md` ;
- `plan-modele.md` (le hook n'en lit pas le contenu, C9).

Aucune fixture ne s'appelle `intent.md`, `spec.md` ni `plan.md` : leur commit n'est vu par aucun contrôle.

Scénarios, une ligne `PASS`/`FAIL` citant les A et L couverts (C13) :

| Cas | État initial (HEAD) | Commit testé | Attendu | Réf. |
|---|---|---|---|---|
| sans intent, spec validée | spec `validé` | `lot/plan.md` | refus, `lot/plan.md : intent absent (lot/intent.md)` | A1, L1, C4 |
| racine sans intent | — | `plan.md` | refus, `plan.md : intent absent (intent.md)` | L2, C2 |
| spec draft | intent `validé`, spec `draft` | `lot/plan.md` | refus, `spec non validée (statut : draft)` | A2, C5 |
| spec validée | intent `validé`, spec `validé` | `lot/plan.md` | accepté | A3 |
| intent draft, spec validée | intent `draft`, spec `validé` | `lot/plan.md` | accepté | L3 |
| spec repassée en draft | intent et spec `validé` | spec → `draft` + `lot/plan.md` | refus, `statut : draft` | L4, C3 |
| spec draft même commit | intent `validé` | `lot/spec.md` `draft` + `lot/plan.md` | refus, `lot/plan.md : spec non validée (statut : draft)` | A4 |
| spec validée même commit | intent `validé` | `lot/spec.md` `validé` + `lot/plan.md` | accepté | A5 |
| intent draft même commit | — | `lot/intent.md` `draft` + `lot/plan.md` | refus, `intent non validé (statut : draft)` | A6 |
| intent validé même commit | — | `lot/intent.md` `validé` + `lot/plan.md` | accepté | A7 |
| intent passé à validé même commit | intent `draft` | intent → `validé` + `lot/plan.md` | accepté | L5 |
| sans spec, intent draft | intent `draft` | `lot/plan.md` | refus, `intent non validé (statut : draft)` | A8, C6 |
| sans spec, intent validé (ligne seule, ligne auteur) | intent `validé` | `lot/plan.md` | accepté, deux cas | A9, C7 |
| casse `Validé` | intent `Validé` | `lot/plan.md` | refus, `statut : Validé` | L7 |
| statut absent (intent, puis spec) | intent / spec sans `**Statut :**` | `lot/plan.md` | refus, `statut : absent` | L8, C16 |
| `git mv` vers amont draft | `lot/` validé avec plan, `lot2/` intent `draft` | `git mv lot/plan.md lot2/plan.md` | refus, `lot2/plan.md : intent non validé (statut : draft)` | A10, L9 |
| autre fichier renommé en plan | intent `draft`, `lot/brouillon.md` | `git mv` → `lot/plan.md` | refus | L10 |
| renommage sous le seuil | `lot/` validé avec plan, `lot2/` intent `draft` | `git mv` + contenu remplacé | refus | L11 |
| renommage sortant, suppression | intent `draft`, `lot/plan.md` | `git mv` → `notes.md`, puis `git rm` | acceptés | L12, C9 |
| modification d'un plan commité | intent `draft`, plan commité | plan modifié | accepté | L13, C9 |
| modèle et fixtures | — | `templates/plan.md`, puis `hooks/tests/x/fixtures/plan.md`, puis `tests/x/fixtures/plan.md` | trois acceptés | A11, L14, L16, C8 |
| sous `lot/templates/` | — | `lot/templates/plan.md` | refus, intent absent | L15 |
| `Plan.md`, `plan.MD`, `mon-plan.md` | — | les trois | accepté | L17 |
| dossier accentué avec espace | `lot é x/` intent `validé` | `lot é x/plan.md` | accepté (pas de faux « intent absent ») | L18 |
| deux plans refusés | `lot/` et `lot2/` intents `draft` | deux `plan.md` | refus, deux lignes | L19, C10 |
| intent supprimé | intent `validé` | `git rm lot/intent.md` + `lot/plan.md` | refus, `intent absent` | L20, C17 |
| spec supprimée | intent `validé` puis `draft`, spec `validé` | `git rm lot/spec.md` + `lot/plan.md` | accepté si intent `validé`, refus sinon | L21, C17 |

`verifier.sh` est rouge sur ce seul commit (`hook-plan` en échec), comme au lot 3 (tests avant le hook).

Couvre : C13, C14, C15 ; les scénarios ci-dessus.

### 2. Contrôle du plan dans `hooks/pre-commit`

Ajouté après la boucle de la spec (C11 : contrôles existants et `check_spec_intent` inchangés). Commentaire de tête : « Quatre contrôles », avec le 4e décrit.

- Fonctions de lecture dans l'index, réutilisables par le lot 3b (C3) :
  - `present_index <fichier>` : `git cat-file -e ":$fichier"`. L'index est l'état après commit : version stagée si le fichier en fait partie, celle de `HEAD` sinon, absent s'il est supprimé (C3, C17).
  - `statut_index <fichier>` : `git show ":$fichier"`, même `sed` que `check_spec_intent` (première occurrence de `**Statut :**`, ligne seule ou de l'auteur, C7) ; valeur vide → `absent` (C16).
- `check_plan <plan>` : dossier par `dirname`, `intent.md` si `.` (C2) ; intent absent → `<plan> : intent absent (<intent>)` (C4) ; sinon spec présente → son statut seul décide, `<plan> : spec non validée (statut : <valeur>)` (C5) ; sinon statut de l'intent, `<plan> : intent non validé (statut : <valeur>)` (C6). Refus sur stderr, `status=1`, le hook continue (C10).
- Boucle sur `git diff --cached --name-status -z -M --diff-filter=AR` : `A` → un chemin, `R<score>` → ancien puis nouveau, seul le nouveau compte (C1). Nom exact `plan.md` (L17). Exclusions sur la destination : `templates/*` à la racine, `"/$chemin"` en `*/tests/*/fixtures/*` (C8, même forme que le contrôle credential).
- Bash et git seulement (C12).

Couvre : C1 à C12, C16, C17 ; fait passer l'étape 1 (A1 à A12).

### 3. Documentation et lien du parent

- `README.md` : ligne `hooks/pre-commit` du tableau (« un nouveau `plan.md` dont l'amont n'est pas validé ») ; `hooks/tests/` (`hook-plan`) ; dans « Produire le plan », le commit refusé et ses trois messages, l'amont lu dans le commit en cours sinon dans `HEAD`, les exclusions ; `bash hooks/tests/hook-plan/run.sh` dans la liste des tests.
- `templates/projet/README.md` : mêmes ajouts, sans référence aux lots.
- `CLAUDE.md` : ligne `hooks/pre-commit` de l'Architecture modifiée en place (ajout « plan à côté d'un amont validé »), sans ligne ajoutée (60 lignes).
- `requirements/open/ia-factory.md` : lien du lot 4a vers `../closed/04a-plan/intent.md` (P4 ; les lignes `Parent` des intents 4a et 4b sont déjà justes).

Couvre : P4, C18 (écart avec le lot 3 documenté : la spec reste lue dans `HEAD` pour son propre contrôle).

### 4. Recette et validation

- `bash scripts/verifier.sh` : `hook-intent`, `hook-spec`, `hook-credential`, `hook-plan` `OK`, code 0 (A12).
- A13 (manuel) : lecture des messages de A1, A2 et A8 dans la sortie de `run.sh`, ou rejoués à la main dans un dépôt jetable.
- Contrôle en conditions réelles : `git mv` du dossier du lot vers `requirements/closed/` simulé dans l'index (`git commit --dry-run` ne lance pas le hook : lancer `bash hooks/pre-commit` après `git mv`, puis `git reset` / `git mv` inverse) → aucun refus.
- `validation.md` au format de `requirements/closed/04a-plan/validation.md`.

Couvre : A12, A13.

## Après la PR (hors PR)

- A14 : spec déjà validée (04ca046).
- Passage du lot en `closed` (`git mv` du dossier, liens mis à jour), comme « Clôture de 4a ».
- Lot 4a : compléter `validation.md` (A2, A3, A4, A5 sur le plan et la PR du 4b), sur `main`.

## Tests à écrire

- Automatisés : `hooks/tests/hook-plan/run.sh`, 28 scénarios environ (étape 1), lancé par `bash scripts/verifier.sh` sans modifier le script (C15).
- Manuels : A13 (messages lisibles), contrôle de clôture du lot (étape 4).
- Non-régression : `hooks/tests/hook-intent`, `hook-spec`, `hook-credential`, `.claude/hooks/tests/hook-activation`, `scripts/tests/ai-factory` inchangés et au vert.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1–C12, C16, C17 | 2 (prouvés par 1) |
| C13–C15 | 1 |
| C18 | 2 (lot 3 inchangé), 3 (doc) |
| L1–L5, L7–L21 | 1, 2 |
| L6 | hors tests : relève du contrôle du lot 3 (P2), traité au lot 3b |
| A1–A11 | 1, 2 |
| A12 | 4 |
| A13 | 4 |
| A14 | fait (04ca046) |

## Risques

- **R1 — Le hook (étape 2) est l'étape la plus risquée.** Un faux refus bloque tous les commits de plan, ici et dans les projets mis à jour. Points fragiles : analyse des enregistrements `-z` (un `A` a un chemin, un `R` en a deux), exclusions, chemins accentués. Parade : tests écrits avant (étape 1), dont L11, L12, L18 ; `verifier.sh` après chaque commit ; contrôle de clôture du lot à l'étape 4.
- **R2 — Faux vert des tests.** Un état initial mal remis à zéro entre deux cas peut faire passer un scénario pour une autre raison. Parade : `init` vide tous les dossiers utilisés, et chaque refus attendu vérifie le message exact.
- **R3 — Deux règles de lecture cohabitent** (P1, C18) : le contrôle de la spec lit l'intent dans `HEAD`, celui du plan dans l'index. L6 reste refusé jusqu'au lot 3b ; la doc de l'étape 3 décrit les deux.
- **R4 — Lot 3b en parallèle.** `feat/lot-3b-hook-spec` modifiera aussi `hooks/pre-commit` et réutilisera `present_index` / `statut_index` : à rebaser après le merge du 4b. Le chemin `requirements/open/03b-hook-spec/` cité par C18 n'existe pas sur cette branche tant que le 3b n'est pas mergé.
- **R5 — `CLAUDE.md` à 60 lignes.** Modification en place uniquement.
- **R6 — Commit rouge (étape 1).** `verifier.sh` échoue sur `hook-plan` entre les étapes 1 et 2 ; voulu, signalé dans le message de commit.

Options écartées :
- Lire l'amont dans `HEAD` puis dans le diff du commit en cours, séparément : écarté, l'index donne directement l'état après commit (C3), suppressions comprises (C17).
- Refactorer `check_spec_intent` sur les nouvelles fonctions : écarté, change le comportement du lot 3 (C11, C18) ; c'est l'objet du lot 3b.

## Hors périmètre

Ceux de la spec : template et skill du plan (4a), contenu et taille du plan, modifications, suppressions et renommages sortants d'un plan existant, correction du contrôle de la spec du lot 3 (3b).

## Vérification

- Après chaque commit à partir de l'étape 2 : `bash scripts/verifier.sh` → `6 run.sh lancés, 0 en échec`.
- `bash hooks/tests/hook-plan/run.sh` : toutes les lignes `PASS`.
- Étape 4 : `validation.md` rempli, A12 et A13 OK.
