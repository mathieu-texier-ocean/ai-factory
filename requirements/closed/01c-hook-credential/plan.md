# Plan — Lot 1c : Hook credential en clair

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** validé
- **Validation :** Tech lead
- **Base :** `main` (011bdc5, lot 1b clos : `scripts/verifier.sh` est sur `main`).

## Prérequis

- `spec.md` commitée au statut `validé` : fait (789bb9e), puis révisée (tests dans `hooks/tests/hook-credential/`, L12 à L15) et repassée en `draft`. À revalider par le tech lead avant l'étape 1 ; l'intent, révisé sur le même point, est à revalider par le PO.
- Une seule PR pour le lot (contrainte du parent). Chaque étape ci-dessous = un commit, sauf les fixtures qui ont leur propre commit (étape 1).
- `core.hooksPath` vaut `hooks` dans le clone de travail.
- P2 de la spec (fixtures : annotation ou `--no-verify`) : ce plan suit la lettre de l'intent, `--no-verify`. Voir R1 pour l'alternative.
- **Emplacement des tests.** Les tests vont dans `hooks/tests/hook-credential/`, à côté du hook (règle du lot 1h, README « Ranger les livrables ») : un nouveau projet, copié sans `requirements/`, reçoit le hook avec ses tests, et le chemin ne change pas quand le lot passe en `closed/`. La spec (C10, contrat « Tests », A4) et l'intent (livrable « Tests », critère d'acceptation) sont révisés en ce sens.

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `hooks/tests/hook-credential/fixtures/*` | nouveaux | 1 |
| `hooks/tests/hook-credential/run.sh` | nouveau, exécutable | 2 |
| `hooks/pre-commit` | modifié | 3 |
| `README.md` | modifié (tableau du dépôt, section « Vérifier ») | 4 |

## Étapes

### 1. Fixtures (commit isolé, `--no-verify`)

Un fichier par cas, avec des valeurs manifestement fictives (suffixe `EXAMPLE`, `0000…`, `fictif`). Aucune vraie valeur, même révoquée (C11).

| Fixture | Contenu | Famille |
|---|---|---|
| `cle-privee.txt` | bloc `BEGIN … PRIVATE KEY` / `END …` avec un corps fictif | clé privée |
| `aws.txt` | `AKIAIOSFODNN7EXAMPLE` (exemple officiel AWS) | jeton fournisseur |
| `github.txt` | un `ghp_` et un `github_pat_` fictifs de la bonne longueur | jeton fournisseur |
| `anthropic.txt` | un `sk-ant-` fictif | jeton fournisseur |
| `slack.txt` | un `xoxb-` fictif | jeton fournisseur |
| `affectation.txt` | `password=` suivi d'une valeur littérale fictive | affectation générique |
| `affectation-reference.txt` | `password=$DB_PASSWORD`, `token=<à renseigner>`, et les formes entre guillemets `password="$DB_PASSWORD"`, `token="${GH_TOKEN}"`, `secret='<à renseigner>'` | aucune (référence, pas une valeur) |
| `url.txt` | URL de base de données avec utilisateur et mot de passe fictifs | URL avec identifiants |
| `annote.txt` | une affectation fictive suivie du marqueur `credential-ok` en commentaire | aucune (C14) |
| `propre.txt` | texte sans credential | aucune |
| `binaire.bin` | quelques octets nuls puis un jeton fictif | aucune (binaire, C15) |

Commit, depuis la racine du dépôt : `git add hooks/tests/hook-credential/fixtures && git commit --no-verify`. Avant de committer, `git diff --cached --name-only` ne doit lister que des fichiers de ce dossier : le commit ne contient que les fixtures, et son message le dit (contrainte de l'intent).

Couvre : C11.

### 2. Tests du contrôle (écrits avant le hook)

`hooks/tests/hook-credential/run.sh` sur le modèle de `hooks/tests/hook-intent/run.sh` : dépôt temporaire, copie de `templates/intent.md` et `hooks/pre-commit`, `core.hooksPath hooks`, une ligne `PASS`/`FAIL` par cas, sortie en erreur si un cas échoue (C10).

Fonctions :
- `check <nom> <fixture> <cible> <pass|block> [texte attendu]`, comme au lot 2.
- `absent <nom> <texte>` : vérifie qu'une valeur fictive n'apparaît **pas** dans la sortie du hook (C7).
- État initial commité sans hook (`-c core.hooksPath=/dev/null`) pour les cas qui partent d'un fichier existant.

| Cas | Préparation | Commit testé | Attendu | Réf. |
|---|---|---|---|---|
| clé privée | — | `cle-privee.txt` | bloqué, chemin + « clé privée » + correction | A1, C5, C6, C13 |
| AWS / GitHub / Anthropic / Slack | — | chaque fixture | bloqué, « jeton » | C13 |
| affectation littérale | — | `affectation.txt` | bloqué | C13 |
| affectation par référence | — | `affectation-reference.txt` (formes nues et entre guillemets) | accepté | C13, L15 |
| URL avec identifiants | — | `url.txt` | bloqué | C13 |
| valeur jamais affichée | — | `aws.txt` | la valeur fictive absente de la sortie | C7 |
| sans credential | — | `propre.txt` | accepté | A2, C8 |
| ligne déjà dans HEAD | `affectation.txt` commité sans hook | ajout d'une ligne propre au même fichier | accepté | L1, C3 |
| non indexé | `aws.txt` copié, pas `git add` ; `propre.txt` indexé | commit | accepté | L2, L3, C2 |
| fichier supprimé | `aws.txt` commité sans hook | `git rm aws.txt` | accepté | L4 |
| renommé + credential | `propre.txt` (assez long pour que git détecte le renommage) commité sans hook dans `a/` | `git mv a b`, puis le contenu de `affectation.txt` ajouté à `b/propre.txt` | bloqué, `b/propre.txt` nommé | L12 |
| renommé sans ajout | `affectation.txt` suivi de `propre.txt` (pour atteindre le seuil de similarité de git), commité sans hook dans `a/` | `git mv a b` | accepté (aucune ligne ajoutée) | L13 |
| nom accentué | — | `aws.txt` copié sous `clé-é.txt` | bloqué, `clé-é.txt` nommé en clair | L14 |
| deux fichiers | — | `aws.txt` + `url.txt` | bloqué, les deux chemins nommés | L5 |
| annotation | — | `annote.txt` | accepté | L9, C14 |
| annotation + autre | — | `annote.txt` + `aws.txt` | bloqué, seul `aws.txt` nommé | L10, C14 |
| binaire | — | `binaire.bin` | accepté | L11, C15 |
| cumul avec le lot 2 | — | `lot/intent.md` incomplet + `aws.txt` | bloqué, les deux messages | C1, C9 |

Non-régression : les `run.sh` des lots 2 et 3 passent sans changement (étape 3).

Couvre : C10, A4, et la vérification de C1 à C9, C13 à C15.

### 3. Contrôle dans `hooks/pre-commit`

Troisième contrôle, ajouté après les deux existants. Leurs boucles et leurs messages ne changent pas (C1). Bash, git, `grep -E` et `awk` seulement (C4, pas d'outil externe).

- Commentaire de tête : trois contrôles.
- **Fichiers lus (C2, C15).** `git diff --cached --numstat -z -M --diff-filter=ACMR`, lu avec `read -d ''`. `-z` donne les chemins bruts : sans lui, `core.quotePath` met entre guillemets et échappe un nom non ASCII (`"\303\251.txt"`), qui n'est plus un chemin valide et serait sauté sans erreur. Un enregistrement est `<ajouts>\t<suppressions>\t<chemin>\0`, ou, pour un renommage, `<ajouts>\t<suppressions>\t\0<ancien>\0<nouveau>\0` (champ chemin vide, deux chemins à lire ensuite). Les enregistrements `-\t-` (binaires) sont ignorés.
- **Lignes ajoutées (C3).** `git diff --cached -U0 -M --no-color -- "$ancien" "$chemin"` (`$ancien` = `$chemin` hors renommage), puis `awk` qui ne garde que les lignes `+` après le premier `@@` (l'en-tête `+++` est écarté). Passer les deux chemins garde le renommage apparié : seules les lignes réellement ajoutées sont lues. Avec le seul nouveau chemin, ou avec `--no-renames`, tout le fichier renommé passerait pour ajouté et un credential déjà commité serait signalé au simple déplacement. Le format `{a => b}/f` que `--numstat` affiche sans `-z` n'est pas un chemin : avec lui, le diff du fichier renommé était vide et un credential ajouté au même commit passait.
- **Annotation (C14).** Les lignes qui contiennent `credential-ok` sont retirées avant la recherche.
- **Motifs (C13).** Une famille = une expression `grep -E`, nommée dans le message :
  - clé privée : en-tête PEM `BEGIN` … `PRIVATE KEY` ;
  - jeton fournisseur : `AKIA` + 16 majuscules/chiffres, `ghp_` + 36 alphanumériques, `github_pat_` + au moins 22, `sk-ant-` + au moins 20, `xox[abprs]-` + au moins 10 ;
  - affectation générique, insensible à la casse : `password`, `secret`, `token`, `api_key`, puis `=`, puis une valeur littérale d'au moins 4 caractères. Un guillemet simple ou double en tête de valeur est sauté avant le test : une valeur qui commence alors par `$`, `<` ou `{` est une référence ou un gabarit et n'est pas signalée (`password="$DB_PASSWORD"`, `token="${GH_TOKEN}"` passent) ;
  - URL avec identifiants : schéma, `://`, utilisateur, `:`, mot de passe non vide, `@`.
  Les longueurs minimales limitent les faux positifs ; elles sont figées par les tests de l'étape 2.
- **Message (C6, C7).** Une ligne par fichier et par famille, sur stderr, au format des messages existants : `<chemin> : credential en clair (<famille>). Retirez la valeur, remplacez-la par une référence (variable d'environnement, gestionnaire de secrets) et révoquez-la si elle est réelle. Faux positif : ajoutez credential-ok en commentaire sur la ligne.` Ni la ligne ni la valeur ne sont affichées.
- **Statut (C5, C8, C9).** Une détection met `status=1` ; les autres contrôles s'exécutent quand même et leurs messages s'ajoutent.

Vérification : `scripts/verifier.sh` depuis la racine, qui lance `hooks/tests/hook-credential/run.sh` et les `run.sh` des lots 2 et 3 (A3, C12).

Couvre : C1 à C9, C12 à C15.

### 4. README et validation

- Tableau « Ce que contient le dépôt » : la ligne `hooks/pre-commit` mentionne le refus d'un credential en clair ; ligne pour `hooks/tests/hook-credential/`.
- Section « Vérifier » : `bash hooks/tests/hook-credential/run.sh` : refus d'un credential en clair. Aucun renvoi vers `requirements/`.
- « Règles à respecter » : le marqueur `credential-ok` et son usage (faux positif uniquement, visible en revue).
- PR ouverte par l'humain, revue par le tech lead.

Couvre : contrats (annotation, tests).

### 5. Révision du 2026-10-19 : fixtures et modèle exclus

Constat de la recette : le premier commit d'un nouveau projet, hook actif, est refusé. Spec révisée : C16, C17, L6 modifié, L16 à L20, A5, A6, P2 tranché, P6.

- **Tests d'abord.** `hooks/tests/hook-credential/run.sh` : credential fictif sous `hooks/tests/x/fixtures/` et sous `tests/x/fixtures/` acceptés (L16, L6) ; sous `fixtures/` et `tests/fixtures/` refusés (L17). `hooks/tests/hook-spec/run.sh` : `templates/spec.md` sans intent accepté, `lot/templates/spec.md` refusé (L20, A6).
- **Hook.** Contrôle des credentials : `case "/$chemin" in */tests/*/fixtures/*) continue ;; esac`, après la lecture des deux chemins (le `/` en tête couvre `tests/` à la racine). Contrôle « intent validé » : `case $path in templates/*) continue ;; esac` avant le test du nom (C17, modifie une boucle existante : révise C1 pour ce seul point).
- **README.** « Règles à respecter » : fixtures non contrôlées ; étape 3 de la spec : le modèle `templates/spec.md` n'est pas contrôlé.
- **Recette.** A5 en manuel : copie sans `requirements/`, `git init`, hook actif, premier commit sans `--no-verify` ; L18 constaté.

Couvre : C16, C17, L6, L16 à L20, A5, A6.

## Tests à écrire

- Automatisés : `hooks/tests/hook-credential/run.sh`, environ 21 cas (étape 2).
- Manuel : A5 (premier commit d'un nouveau projet), à la recette de l'étape 5. L6 n'est plus manuel : la fixture modifiée est acceptée et testée (étape 5).

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1–C9, C12–C15 | 3 (testé en 2) |
| C10, C11 | 2, 1 |
| L1–L5, L9–L15 | 2 |
| C16, C17, L6, L16–L20, A5, A6 | 5 |
| L7, L8 | hors portée du hook (lots 13 et 1f) |
| A1–A4 | 2, 3 |

## Risques

- **R1 — Fixtures en clair dans le dépôt (P2, P4 de la spec).** Le plan suit l'intent : fixtures commitées avec `--no-verify`. Alternative à trancher par le tech lead avant l'étape 1 : `run.sh` assemble les valeurs fictives à l'exécution (concaténation de morceaux), si bien qu'aucun fichier du dépôt ne contient de credential complet. Plus de `--no-verify`, et rien à signaler pour un futur gitleaks ni pour la push protection de GitHub.
- **R2 — Push protection GitHub.** Si l'organisation l'active, un jeton fictif au bon format (`ghp_`, `github_pat_`, `xoxb-`) peut bloquer le push des fixtures. L'exemple AWS officiel est connu et ignoré ; les autres non. R1 supprime le risque.
- **R3 — Le dépôt se signale lui-même.** La spec 1c, ce plan et le README décrivent les motifs. Une ligne nouvelle qui contient un exemple complet (URL avec identifiants, `password=` suivi d'une valeur) sera refusée : écrire les exemples sous forme de gabarit (`<utilisateur>`, `<mot de passe>`) ou annoter.
- **R4 — Affectations en YAML ou JSON.** La spec cite `password=` : `password: valeur` (YAML) et `"password": "valeur"` (JSON) ne sont pas couverts. Élargir au `:` augmente les faux positifs. Décideur : tech lead.
- **R5 — Noms de fichiers avec espaces ou caractères spéciaux.** Le nouveau contrôle lit les chemins avec `-z` : accents, espaces et retours à la ligne sont couverts. Les deux contrôles existants lisent `--name-only` ligne à ligne, sans `-z` : un `intent.md` ou un `spec.md` dans un dossier au nom accentué y échappe. Hors périmètre (C1 interdit de modifier leurs boucles) ; à signaler au tech lead pour un lot ultérieur.
- **R6 — Contournements.** `--no-verify`, hooks non actifs (lot 1f) et absence de CI (lot 13 suspendu) laissent passer un credential (P3 de la spec, risque accepté).

## Hors périmètre

Ceux de la spec : activation de `core.hooksPath` (1f), hook Claude Code sur les éditions, contrôle en CI (lot 13), historique git existant, règles langue et historique, skills de standards.
