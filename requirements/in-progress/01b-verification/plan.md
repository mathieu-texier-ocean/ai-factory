# Plan — Lot 1b : Commande de vérification

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **Validation :** Tech lead
- **Base :** `main` (1dec5ac, lots 1a et 1h fermés : tests des hooks dans `hooks/tests/`).

## Prérequis

- `spec.md` révisée après le lot 1h (P5 de la spec), commitée et revalidée par le tech lead : à faire. Validée une première fois en 789bb9e.
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

Bash seul, comme `hooks/pre-commit` et les `run.sh` existants. En-tête `#!/usr/bin/env bash`, `set -u`, commentaire de tête court (ce que fait la commande, sur quoi elle échoue). Compatible bash 3.2 (bash par défaut de macOS) : ni `mapfile` ni `readarray`, et aucun tableau éventuellement vide n'est développé par `"${t[@]}"` (sous `set -u`, bash < 4.4 sort en « unbound variable ») ; on teste `${#t[@]}` avant de boucler.

1. **Contrôle de la racine (C9).** `racine=$(git rev-parse --show-toplevel 2>/dev/null)`. Si la commande échoue ou si `$(pwd -P)` diffère de `racine`, écrire sur stderr `scripts/verifier.sh : à lancer depuis la racine du dépôt : cd <racine> && scripts/verifier.sh` (sans `<racine>` hors d'un dépôt git) et sortir en 1.
2. **Découverte (C2, C11).** `find . -name .git -prune -o -type f -name run.sh -print | sed 's|^\./||' | LC_ALL=C sort`, lu ligne à ligne dans un tableau (`while IFS= read -r f; do runs+=("$f"); done < <(…)`). Tout le dépôt est parcouru, sans dossier de départ ni liste en dur : `hooks/tests/`, `.claude/hooks/tests/`, `scripts/tests/` et les dossiers de lots sont couverts, y compris dans un nouveau projet sans `requirements/` (L8). La découverte lit le système de fichiers et non `git ls-files` : un `run.sh` pas encore commité, ou sous un dossier ignoré par un `.gitignore` global (`.*/`), est trouvé (L9). Seul `.git/` est exclu (L10).
3. **Aucun `run.sh` (C10).** `${#runs[@]}` vaut 0 : `scripts/verifier.sh : aucun run.sh trouvé dans le dépôt` sur stderr, sortie en 1.
4. **Exécution (C3, C4, C7, L4).** Pour chaque chemin, dans l'ordre trié : afficher `== <chemin>`, lancer `bash "<chemin>"` (le bit exécutable n'est pas requis), laisser passer sa sortie telle quelle, relever le code de sortie. Code ≠ 0 → ligne `ÉCHEC <chemin> (code <n>)` et ajout à la liste des échecs ; sinon `OK <chemin>`. On continue après un échec.
5. **Récapitulatif (C5).** `<n> run.sh lancés, <m> en échec`, puis un chemin par ligne pour chaque échec. La boucle sur la liste des échecs n'est parcourue que si `${#echecs[@]}` > 0.
6. **Code de sortie (C6).** 0 si aucun échec, 1 sinon.

Le script ne crée ni ne modifie aucun fichier du dépôt : chaque `run.sh` travaille dans son dépôt temporaire (C8). Mode exécutable enregistré dans git : `git update-index --chmod=+x scripts/verifier.sh`.

Couvre : C1 à C11, L1 à L10.

### 2. Documentation dans le README

- Tableau « Ce que contient le dépôt » : ligne `scripts/verifier.sh` → « Lance tous les `run.sh` du dépôt ; sort en erreur si l'un échoue ».
- Section « Vérifier » : `scripts/verifier.sh` en première ligne, les `run.sh` de `hooks/tests/` restent listés en dessous.
- « Mise en route », étape 3 : remplacer les deux commandes `bash hooks/tests/…/run.sh` par `scripts/verifier.sh` (au vert dans `ai-factory` comme dans un nouveau projet, L8).
- Aucun renvoi vers `requirements/` (règle C12 du lot 1h).

Le bloc « Vérifier son travail » de `CLAUDE.md` reste au lot 1e (hors périmètre).

Couvre : contrats (consommateurs).

### 3. Recette manuelle

Dans un clone jetable (`git clone . "$(mktemp -d)"`), pour ne jamais commiter de faux `run.sh`. Chaque cas repart d'un clone propre, sauf « Lot déplacé » qui reprend la préparation de « Deux échecs ». Résultats dans `RECETTE.md` : date, action, sortie observée, code de sortie.

| Cas | Préparation | Action | Attendu | Réf. |
|---|---|---|---|---|
| Nominal | aucune | `scripts/verifier.sh` | `hooks/tests/hook-intent/run.sh` et `hooks/tests/hook-spec/run.sh` nommés, `OK`, `2 run.sh lancés, 0 en échec`, code 0 | A1, A3 |
| Ajout après coup | `scripts/tests/recette-ok/run.sh` qui fait `exit 0`, non commité | `scripts/verifier.sh`, script inchangé | 3 `run.sh` lancés, le nouveau nommé, code 0 | A2, L1, L9 |
| Dossier caché | `.claude/hooks/tests/recette-ok/run.sh` qui fait `exit 0` | `scripts/verifier.sh` | lancé et nommé | L9, C11 |
| Deux échecs | `scripts/tests/recette-ko/run.sh` et `requirements/in-progress/01b-verification/tests/recette-ko/run.sh` qui font `echo "FAIL recette"; exit 1` | `scripts/verifier.sh` | les deux nommés `ÉCHEC` et dans le récapitulatif, les autres lancés quand même, code ≠ 0 | A4, L3 |
| Lot déplacé | le `run.sh` en échec du lot 1b ci-dessus, puis `git mv requirements/in-progress/01b-verification requirements/closed/` | `scripts/verifier.sh` | trouvé sous `requirements/closed/01b-verification/` | L2 |
| Livrable renommé | `git mv hooks/tests/hook-spec hooks/tests/hook-spec-x` | `scripts/verifier.sh` | `hooks/tests/hook-spec-x/run.sh` trouvé et `OK` | L2 |
| Sans bit exécutable | `chmod -x hooks/tests/hook-intent/run.sh` | `scripts/verifier.sh` | lancé quand même | L4 |
| Sous `fixtures/` | `hooks/tests/hook-intent/fixtures/recette/run.sh` qui fait `exit 0` | `scripts/verifier.sh` | lancé et nommé | L6, C11 |
| Sous `.git/` | `.git/recette/run.sh` qui fait `exit 1` | `scripts/verifier.sh` | absent de la sortie, code 0 | L10 |
| Aucun `run.sh` | `find . -name .git -prune -o -name run.sh -exec rm {} +` | `scripts/verifier.sh` | message « aucun run.sh trouvé dans le dépôt », code ≠ 0 | L5, C10 |
| Nouveau projet | copie sans `requirements/` (commande « Copie sans `requirements/` » des contrats du lot 1h), depuis le commit de l'étape 2 | `scripts/verifier.sh` dans la copie | 2 `run.sh` lancés, 0 en échec, code 0 | L8 |
| Sous-dossier | `cd hooks` | `../scripts/verifier.sh` | refus, message avec la commande depuis la racine, code ≠ 0 | L7, C9 |
| bash 3.2 | aucune | `docker run --rm -v "$PWD":/w -w /w bash:3.2 bash scripts/verifier.sh` (git à installer dans le conteneur), une fois au vert et une fois avec un `run.sh` en échec | même sortie et même code qu'en bash récent, pas de « unbound variable » | C5, C6 |

Puis PR ouverte par l'humain, revue par le tech lead.

Couvre : A1 à A4.

## Tests à écrire

- Aucun test automatisé (P1 de la spec).
- Recette manuelle de l'étape 3, consignée dans `RECETTE.md`.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1–C11 | 1 |
| L1–L10 | 1, recettés en 3 |
| A1–A4 | 3 |

## Risques

- **R1 — Régression silencieuse.** Sans test automatisé, une modification de `scripts/verifier.sh` n'est vérifiée qu'à la main (P1 de la spec, accepté).
- **R2 — `run.sh` sous `fixtures/` ou dans un dossier non suivi.** Pas d'exclusion hors `.git/` (C11). Une fixture nommée `run.sh`, ou un `run.sh` dans un dossier non suivi par git (`documents/`, `.obsidian/`, un futur `node_modules/`), serait lancé et pourrait faire échouer la commande. Aujourd'hui aucun n'existe ; un lot qui en aurait besoin devra le nommer autrement.
- **R3 — Durée.** Les `run.sh` tournent l'un après l'autre, et `find` parcourt tout le dépôt. Avec deux `run.sh`, la commande prend quelques secondes ; chaque nouveau test l'allonge.
- **R4 — Racine et liens symboliques.** La comparaison `pwd -P` / `git rev-parse --show-toplevel` suppose des chemins résolus des deux côtés ; un clone ouvert via un lien symbolique est à vérifier pendant la recette.
- **R5 — Dépendants.** Le lot 1e documente cette commande dans `CLAUDE.md`, le lot 1f fait tester ses hooks par elle, le lot 5 l'exige au vert. Changer son nom ou son code de sortie après merge impose de reprendre ces lots.
- **R6 — Version de bash.** Le script doit tourner sous bash 3.2 (macOS) : une syntaxe bash 4 (`mapfile`, `"${t[@]}"` sur un tableau vide sous `set -u`) passerait en recette Linux et casserait sur macOS. Le cas « bash 3.2 » de la recette le couvre.

## Hors périmètre

Ceux de la spec : documentation dans `CLAUDE.md` (1e), hook de protection des tests (1g), hook « commande au vert avant PR » (lot 5), build et lint, recettes manuelles des skills, CI, règles bloquantes (1c).
