# Plan — Lot 4b : Étape Plan, refus d'un plan sans amont validé

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Jeu de test · **Statut :** draft
- **À risque :** non
- **Validation :** Développeur
- **Base :** `main`

## Prérequis

- `spec.md` commitée au statut `validé`.
- Une seule PR pour le lot. Chaque étape ci-dessous = un commit.

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `hooks/tests/hook-plan/run.sh` et `fixtures/` | nouveaux | 1 |
| `hooks/pre-commit` | modifié | 2 |
| `README.md` | modifié | 3 |

## Étapes

### 1. Tests du contrôle (écrits avant le hook)

`hooks/tests/hook-plan/run.sh` sur le modèle de `hooks/tests/hook-spec/run.sh`.

Couvre : C13 à C15, A1 à A11.

### 2. Contrôle dans `hooks/pre-commit`

Couvre : C1 à C12, C16 à C18.

### 3. Documentation du contrôle du plan dans `README.md`

S'appuie sur l'étape 2 : documente le contrôle tel qu'il est livré.

- Table « Ce que contient le dépôt » : ligne `hooks/pre-commit` (refus d'un nouveau `plan.md` sans intent à côté, ou dont l'amont n'est pas validé) et ligne `hooks/tests/` (`hook-plan`).
- « Produire le plan », étape « Committer le plan » : ce que le hook refuse (intent absent, spec non validée, sans spec intent non validé ; création et renommage), lu dans le commit en cours sinon dans `HEAD`, exclusions (`templates/` à la racine, fixtures de tests).
- « Vérifier » : `bash hooks/tests/hook-plan/run.sh`.

Couvre : aucun numéro de la spec (documentation ajoutée à la demande du développeur, hors spec).

## Tests à écrire

- `bash hooks/tests/hook-plan/run.sh`, puis `bash scripts/verifier.sh`.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1–C12, C16–C18 | 2 |
| C13–C15 | 1 |
| A1–A12 | 1 |
| L1–L21, A13, A14 | Non rattachés : signalé pendant la séance, à rattacher par le développeur |

## Risques

- Ce que le changement peut casser : le contrôle de la spec du lot 3 ne doit pas changer de comportement (C11, C18). Parade : `hooks/tests/hook-spec/run.sh` reste au vert, via `bash scripts/verifier.sh` (A12).
- Étape la plus risquée : la modification de `hooks/pre-commit` (étape 2). Parade : tests écrits avant le hook (étape 1).
- Contournement par renommage : couvert par C1.
- Couverture incomplète : L1–L21, A13 et A14 ne sont rattachés à aucune étape (voir « Couverture de la spec »).
- Incohérence à lever : l'étape 1 cite A1 à A11, la couverture rattache A1–A12 à l'étape 1.

Options écartées :

- Un hook séparé pour le plan : écarté pour garder un seul `pre-commit`.

## Hors périmètre

Ceux de la spec.
