# Plan — Lot 1b : Commande de vérification

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **Validation :** Tech lead
- **Base :** `main` (cc5057c, plan du lot 1a commité).

## Prérequis

- `spec.md` commitée au statut `validé` : fait (789bb9e).
- Une seule PR pour le lot (contrainte du parent). Chaque étape ci-dessous = un commit.
- `core.hooksPath` vaut `hooks` dans le clone de travail.

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `scripts/verifier.sh` | nouveau, exécutable (mode `100755`) | 1 |
| `README.md` | modifié (tableau du dépôt, section « Vérifier ») | 2 |
| `requirements/in-progress/01b-verification/RECETTE.md` | nouveau | 3 |

Pas de test automatisé de la commande (décision du 2026-10-16, P1 de la spec).

## Étapes

### 1. Script `scripts/verifier.sh`

Bash seul, comme `hooks/pre-commit` et les `run.sh` existants. En-tête `#!/usr/bin/env bash`, `set -u`, commentaire de tête court (ce que fait la commande, sur quoi elle échoue).

1. **Contrôle de la racine (C9).** `racine=$(git rev-parse --show-toplevel 2>/dev/null)`. Si la commande échoue ou si `$(pwd -P)` diffère de `racine`, écrire sur stderr `scripts/verifier.sh : à lancer depuis la racine du dépôt : cd <racine> && scripts/verifier.sh` (sans `<racine>` hors d'un dépôt git) et sortir en 1.
2. **Découverte (C2, C11).** `find requirements -type f -name run.sh | LC_ALL=C sort`, lu dans un tableau. Aucune exclusion de chemin, aucune liste en dur : un lot ajouté ou déplacé entre `open/`, `in-progress/` et `closed/` est trouvé à l'exécution suivante.
3. **Aucun `run.sh` (C10).** Tableau vide : `scripts/verifier.sh : aucun run.sh trouvé sous requirements/` sur stderr, sortie en 1.
4. **Exécution (C3, C4, C7, L4).** Pour chaque chemin, dans l'ordre trié : afficher `== <chemin>`, lancer `bash "<chemin>"` (le bit exécutable n'est pas requis), laisser passer sa sortie telle quelle, relever le code de sortie. Code ≠ 0 → ligne `ÉCHEC <chemin> (code <n>)` et ajout à la liste des échecs ; sinon `OK <chemin>`. On continue après un échec.
5. **Récapitulatif (C5).** `<n> run.sh lancés, <m> en échec`, puis un chemin par ligne pour chaque échec.
6. **Code de sortie (C6).** 0 si aucun échec, 1 sinon.

Le script ne crée ni ne modifie aucun fichier du dépôt : chaque `run.sh` travaille dans son dépôt temporaire (C8). Mode exécutable enregistré dans git : `git update-index --chmod=+x scripts/verifier.sh`.

Couvre : C1 à C11, L1 à L7.

### 2. Documentation dans le README

- Tableau « Ce que contient le dépôt » : ligne `scripts/verifier.sh` → « Lance tous les `run.sh` des lots ; sort en erreur si l'un échoue ».
- Section « Vérifier » : `scripts/verifier.sh` en première ligne, les `run.sh` individuels restent listés en dessous.
- « Mise en route », étape 3 : remplacer les deux commandes `run.sh` par `scripts/verifier.sh`.

Le bloc « Vérifier son travail » de `CLAUDE.md` reste au lot 1e (hors périmètre).

Couvre : contrats (consommateurs).

### 3. Recette manuelle

Dans un clone jetable (`git clone . "$(mktemp -d)"`), pour ne jamais commiter de faux `run.sh`. Résultats dans `RECETTE.md` : date, action, sortie observée, code de sortie.

| Cas | Préparation | Action | Attendu | Réf. |
|---|---|---|---|---|
| Nominal | aucune | `scripts/verifier.sh` | les deux `run.sh` (lots 2 et 3) nommés, `OK`, `2 run.sh lancés, 0 en échec`, code 0 | A1, A3 |
| Ajout après coup | `requirements/in-progress/01b-verification/tests/recette-ok/run.sh` qui fait `exit 0` | `scripts/verifier.sh`, script inchangé | 3 `run.sh` lancés, le nouveau nommé, code 0 | A2, L1 |
| Échec | `…/tests/recette-ko/run.sh` qui fait `echo "FAIL recette"; exit 1` | `scripts/verifier.sh` | ce `run.sh` nommé `ÉCHEC` et dans le récapitulatif, les autres lancés quand même, code ≠ 0 | A4, L3 |
| Lot déplacé | `git mv requirements/closed/02-intent requirements/in-progress/` | `scripts/verifier.sh` | `run.sh` du lot 2 toujours trouvé | L2 |
| Sans bit exécutable | `chmod -x` sur un `run.sh` | `scripts/verifier.sh` | lancé quand même | L4 |
| Aucun `run.sh` | `rm` de tous les `run.sh` | `scripts/verifier.sh` | message « aucun run.sh trouvé », code ≠ 0 | L5, C10 |
| Sous `fixtures/` | `…/tests/x/fixtures/run.sh` qui fait `exit 0` | `scripts/verifier.sh` | lancé et nommé | L6, C11 |
| Sous-dossier | `cd requirements` | `../scripts/verifier.sh` | refus, message avec la commande depuis la racine, code ≠ 0 | L7, C9 |

Puis PR ouverte par l'humain, revue par le tech lead.

Couvre : A1 à A4.

## Tests à écrire

- Aucun test automatisé (P1 de la spec).
- Recette manuelle de l'étape 3, consignée dans `RECETTE.md`.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1–C11 | 1 |
| L1–L7 | 1, recettés en 3 |
| A1–A4 | 3 |

## Risques

- **R1 — Régression silencieuse.** Sans test automatisé, une modification de `scripts/verifier.sh` n'est vérifiée qu'à la main (P1 de la spec, accepté).
- **R2 — `run.sh` sous `fixtures/`.** Pas d'exclusion (C11). Une fixture nommée `run.sh` serait lancée et pourrait faire échouer la commande. Aujourd'hui aucune n'existe ; un lot qui en aurait besoin devra la nommer autrement.
- **R3 — Durée.** Les `run.sh` tournent l'un après l'autre. Avec deux lots, la commande prend quelques secondes ; chaque nouveau lot testé l'allonge.
- **R4 — Racine et liens symboliques.** La comparaison `pwd -P` / `git rev-parse --show-toplevel` suppose des chemins résolus des deux côtés ; un clone ouvert via un lien symbolique est à vérifier pendant la recette.
- **R5 — Dépendants.** Le lot 1e documente cette commande dans `CLAUDE.md`, le lot 1f fait tester ses hooks par elle, le lot 5 l'exige au vert. Changer son nom ou son code de sortie après merge impose de reprendre ces lots.

## Hors périmètre

Ceux de la spec : documentation dans `CLAUDE.md` (1e), hook de protection des tests (1g), hook « commande au vert avant PR » (lot 5), build et lint, recettes manuelles des skills, CI, règles bloquantes (1c).
