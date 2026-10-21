# Plan — Lot 4b : Étape Plan, refus d'un plan sans amont validé

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Jeu de test · **Statut :** draft
- **À risque :** non
- **Validation :** Développeur
- **Base :** `main` (commit de départ non précisé)

## Prérequis

- `spec.md` commitée au statut `validé` (A14). Elle n'est pas encore commitée : la stager avec le plan, le hook `pre-commit` lit l'index ou `HEAD`, pas l'arbre de travail.
- Une seule PR pour le lot. Chaque étape ci-dessous = un commit.
- Lots dont celui-ci dépend : lot 3 (contrôle « intent validé avant la spec » en place dans `hooks/pre-commit`), lot 4a (`templates/plan.md`).

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `hooks/tests/hook-plan/run.sh` | nouveau | 1 |
| `hooks/tests/hook-plan/fixtures/` (intents `draft` et `validé`, statut sur sa ligne et sur celle de l'auteur, specs `draft` et `validé`, plan modèle) | nouveaux | 1 |
| `hooks/pre-commit` | modifié | 2 |

## Étapes

### 1. Tests du contrôle (écrits avant le hook)

`hooks/tests/hook-plan/run.sh` sur le modèle de `hooks/tests/hook-spec/run.sh` : dépôt git temporaire, copie de `hooks/pre-commit` et de `templates/intent.md`, un scénario par ligne `PASS`/`FAIL` citant les numéros A et L, code de sortie non nul si un scénario échoue. Intents de fixture complets, pour que le contrôle de complétude ne masque pas le résultat. Découvert par `scripts/verifier.sh` sans modification du script.

Scénarios : A1 à A11, et les cas limites L3, L4, L7, L8, L10, L13, L15, L17, L18, L19, L20, L21.

Couvre : C13, C14, C15 ; A1 à A11 ; L3, L4, L7, L8, L10, L13, L15, L17, L18, L19, L20, L21.

### 2. Contrôle dans `hooks/pre-commit`

À la suite du contrôle « intent validé » du lot 3, sans toucher à `check_spec_intent` ni à sa boucle. Lecture des `plan.md` ajoutés ou renommés avec `git diff --cached -z -M --diff-filter=AR` (chemins bruts), exclusions `templates/` à la racine et `tests/<nom>/fixtures/` à toute profondeur, intent et spec lus dans l'index (`git show ":<chemin>"`), statut `absent` si le champ manque. Les refus alimentent le `status` commun, sans sortie anticipée. Mise à jour du commentaire d'en-tête (quatre contrôles).

Vérification : `bash hooks/tests/hook-plan/run.sh`, puis `bash scripts/verifier.sh` (A12), puis lecture des messages de A1, A2 et A8 (A13).

Couvre : C1 à C12, C16, C17, C18 ; L1 à L21 ; A1 à A13.

## Tests à écrire

- Automatisés : `bash hooks/tests/hook-plan/run.sh` (A1 à A11 et les cas limites listés à l'étape 1), puis `bash scripts/verifier.sh` : `hook-intent`, `hook-spec`, `hook-credential` et `hook-plan` à `OK`, code 0 (A12).
- Manuel : lecture des messages refusés de A1, A2 et A8 (A13).
- Humain : validation de la spec par le tech lead (A14), prérequis.
- Sans scénario automatisé d'après la spec : L1, L2, L5, L6, L9, L11, L12, L14, L16. L1, L9, L14 et L16 sont proches de A1, A10 et A11 ; L6 relève du contrôle du lot 3 (P2).

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1–C12 | 2 |
| C13–C15 | 1 |
| C16–C18 | 2 |
| L1, L2, L5, L6, L9, L11, L12, L14, L16 | 2 |
| L3, L4, L7, L8, L10, L13, L15, L17, L18, L19, L20, L21 | 1 (scénario), 2 (comportement) |
| A1–A11 | 1 (scénario), 2 (comportement) |
| A12 | 2 |
| A13 | 2 (vérification manuelle) |
| A14 | Prérequis (validation humaine de la spec, avant l'étape 1) |

## Risques

- **Ce que le changement peut casser** (développeur) : le contrôle de la spec du lot 3 ne doit pas changer de comportement. Parade : `check_spec_intent` et sa boucle `--diff-filter=A` restent intacts (C11, C18) ; `hooks/tests/hook-spec/run.sh` reste `OK` (A12).
- **Étape la plus risquée** (développeur) : la modification de `hooks/pre-commit` (étape 2). Parade : contrôle ajouté à la suite des existants, `status` commun, pas de `exit` anticipé (C10) ; les quatre `run.sh` lancés par `scripts/verifier.sh` avant le commit.
- Contournement par renommage : couvert par C1 (lecture des `R` avec `-z -M`), scénarios A10 et L10.
- Question restée sans réponse : à l'étape 1, les tests sont écrits avant le hook ; le commit de l'étape 1 a donc `hooks/tests/hook-plan/run.sh` en échec et `scripts/verifier.sh` en erreur jusqu'à l'étape 2. Ordre à confirmer par le développeur.
- Question restée sans réponse : la spec (P4) annonce la correction dans ce lot des liens `Parent` des intents 4a et 4b et de la table de l'intent parent. Aucune étape ne la porte ; à placer ou à écarter par le développeur.
- La spec (P5) indique que `templates/plan.md` n'existe pas encore ; il existe désormais (lot 4a). Le plan modèle de fixture reste prévu (C14).
- Commit de départ non précisé dans `Base`.

### Options écartées

- Un hook séparé pour le plan : écarté pour garder un seul `pre-commit`.

## Hors périmètre

Ceux de la spec :

- Template et skill de production du plan (lot 4a).
- Contrôle du contenu ou de la taille du plan.
- Contrôle des modifications, suppressions et renommages sortants d'un plan existant.
- Correction du contrôle de la spec du lot 3 (renommage, chemins accentués, intent du même commit) : lot 3b.
