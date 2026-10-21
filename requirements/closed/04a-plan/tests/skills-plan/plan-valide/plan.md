# Plan — Lot 4b : Étape Plan, refus d'un plan sans amont validé

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Jeu de test · **Statut :** validé
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

## Étapes

### 1. Tests du contrôle (écrits avant le hook)

`hooks/tests/hook-plan/run.sh` sur le modèle de `hooks/tests/hook-spec/run.sh`.

Couvre : C13 à C15, A1 à A11.

### 2. Contrôle dans `hooks/pre-commit`

Couvre : C1 à C12, C16 à C18.

## Tests à écrire

- `bash hooks/tests/hook-plan/run.sh`, puis `bash scripts/verifier.sh`.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1–C12, C16–C18 | 2 |
| C13–C15 | 1 |
| A1–A12 | 1 |

## Risques

- Contournement par renommage : couvert par C1.

## Hors périmètre

Ceux de la spec.
