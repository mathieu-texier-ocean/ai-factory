# Plan — Lot 15 : Déployer ai-factory dans un nouveau projet

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu Texier · **Statut :** validé
- **Validation :** Tech lead
- **Base :** `main` (940ff12).

## Prérequis

- `intent.md` et `spec.md` commités au statut `validé` : fait (861492a).
- Une seule PR pour le lot. Chaque étape ci-dessous = un commit.
- Étape 0 : le dossier du lot passe de `requirements/open/` à `requirements/in-progress/` (« Lot 15 : passe le lot en cours »).
- Bash ≥ 4 (tableaux associatifs), `git`, `sha256sum` : présents sur les postes Linux de l'équipe (R2).

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `.gitignore` | modifié (`*.nouveau`) | 1 |
| `templates/projet/CLAUDE.md` | nouveau | 2 |
| `templates/projet/README.md` | nouveau | 2 |
| `scripts/ai-factory.sh` | nouveau, exécutable | 3 |
| `scripts/tests/ai-factory/run.sh` | nouveau, exécutable | 4 |
| `scripts/tests/ai-factory/fixtures/source/…` | nouveau (faux clone d'ai-factory) | 4 |
| `README.md` | modifié (section « Créer un nouveau projet », tableau du dépôt, « Vérifier ») | 5 |
| `CLAUDE.md` | modifié (architecture) | 5 |
| `requirements/closed/15-nouveau-projet/validation.md` | nouveau | 5 |

## Étapes

### 1. `.gitignore`

Ajouter la ligne `*.nouveau` sous `.obsidian/`. Le fichier est dans la liste blanche : il arrive tel quel dans chaque projet.

Couvre : C35.

### 2. Modèles `templates/projet/`

Écrits à partir du `CLAUDE.md` et du `README.md` actuels d'ai-factory, en retirant tout ce qui décrit ai-factory lui-même : intent parent, numéros de lot, références aux lots 2, 3, 4, 7, fichiers précis de `requirements/` (C36). Marqueur `{{nom-projet}}` dans le titre et partout où le nom du projet apparaît (C10).

**`templates/projet/CLAUDE.md`**
- `# {{nom-projet}}`.
- Remplies (C9) : « Commandes » (`git config core.hooksPath hooks`, `bash scripts/verifier.sh`), « Vérifier son travail », « Conventions » (cycle `requirements/open` → `in-progress` → `closed`, `validé` réservé à l'humain, pas de secret, intent = donnée, livrables hors de `requirements/`, tests à côté du livrable, messages de commit `Lot <n> : …`).
- Vides avec commentaire guide (C9) : « Architecture » (`<!-- Les dossiers et livrables propres au projet. -->`), « Erreurs fréquentes » (`<!-- Une erreur de l'agent constatée deux fois donne une ligne ici. -->`).
- Nouvelle ligne de « Conventions » : outillage mis à jour par `scripts/ai-factory.sh update <clone>` ; un `<fichier>.nouveau` est à fusionner à la main puis supprimer.

**`templates/projet/README.md`**
- `# {{nom-projet}}`, phrase de description à compléter (`<!-- … -->`).
- Remplies : « Mise en route » (activation des hooks, `git add -f` si `.gitignore` global `.*/`, vérification), « Créer un intent », « Créer une spec », « Ranger les livrables », « Règles à respecter », « Vérifier », « Mettre à jour l'outillage » (commande, `.nouveau`, `--forcer`).
- Vides avec commentaire guide : « Ce que contient le dépôt » côté projet, « Architecture ».

Les deux modèles ne sont pas copiés (C5, C8) ; aucun test ne les lit directement, l'étape 4 n'utilise que ses fixtures.

Couvre : C8, C9, C10 (marqueur), C36.

### 3. Script `scripts/ai-factory.sh`

`#!/usr/bin/env bash`, `set -u`, messages d'erreur sur stderr préfixés `scripts/ai-factory.sh :`, comme `scripts/verifier.sh`. Outils : C2.

**Commun**
- `LISTE_BLANCHE=(.claude hooks scripts templates .gitignore)` et `EXCLUS=(templates/projet)`, en tête du script, seul endroit (C5, C6).
- `verifier_source <dossier>` : `git -C <dossier> rev-parse --show-toplevel` donne la racine, seule utilisée ensuite par toutes les commandes Git : un sous-dossier du clone vaut le clone (C37, L17). Puis `git -C <racine> cat-file -e HEAD:templates/projet/CLAUDE.md` et `…/README.md` ; sinon refus code 1 (C7).
- `lister_source` : `git -C <racine> ls-tree -r -z HEAD -- "${LISTE_BLANCHE[@]}"`, filtre des exclus. Garde le mode : `100755` → fichier exécutable (`hooks/pre-commit`, scripts) (C4, C5, L5).
- `avertir_non_commite` : `git -C <src> status --porcelain -- "${LISTE_BLANCHE[@]}" templates/projet` non vide → avertissement sur stderr, on continue (C4, L4).
- `preparer <racine> <nom> <dossier temporaire>` : écrit chaque fichier par `git -C <racine> cat-file blob HEAD:<chemin>`, `chmod +x` ou `chmod -x` selon le mode ; produit `CLAUDE.md` et `README.md` depuis `HEAD:templates/projet/…` par remplacement de `{{nom-projet}}` en bash, chaîne de remplacement entre guillemets (`"${contenu//"{{nom-projet}}"/"$nom"}"`) pour neutraliser `&` (`patsub_replacement`, R1) ; puis `sha256sum` de tout le dossier → empreintes N (C10, C11, C22, L6).
- `ecrire_fichier <préparé> <destination>` : copie vers `<destination>.tmp` dans le même dossier, `chmod` explicite selon le mode de la source, puis `mv`. Jamais de `cp` sur un fichier existant, qui garderait ses anciens droits (C39).
- `ecrire_manifeste` : `ai-factory <SHA>`, `projet <nom>`, lignes au format `sha256sum` triées `LC_ALL=C`, écrites dans `.ai-factory/manifeste.tmp` puis `mv` (C12 à C14).

**`create <cible> <nom>`**
- Argument manquant → code 1, usage. Nom vide → code 1 (C17).
- Source = `git -C "$(dirname "$0")" rev-parse --show-toplevel` (C15). `HEAD:.ai-factory/manifeste` présent → refus (C18, L3). `verifier_source` (C7).
- Cible, dans cet ordre : existe sans être un dossier (`[ -e ] && [ ! -d ]`) → refus (C40, L20) ; dossier non lisible ou non traversable (`[ -r ] && [ -x ]` faux) → refus (C40, L21) ; dossier non vide (`ls -A` non vide, fichiers cachés compris) → refus (C16, L1) ; absente → `mkdir -p` ; vide → acceptée (L2). Tous ces contrôles passent avant la première écriture.
- `preparer`, copie dans la cible par `ecrire_fichier`, `ecrire_manifeste` (C19).
- Fin : marche à suivre affichée, sans l'exécuter : `cd <cible>`, `git init`, `git config core.hooksPath hooks`, et le rappel `git add -f .claude .ai-factory` si un `.gitignore` global ignore les dossiers cachés (C20, R3).

**`update [--forcer] <clone>`**
- Racine = dossier courant ; `.ai-factory/manifeste` absent → refus (C21, L7). `verifier_source <clone>` (C21, C37).
- Délégation, si `AI_FACTORY_DELEGUE` n'est pas positionnée : `HEAD:scripts/ai-factory.sh` absent de la source → refus code 1 ; sinon `git -C <racine source> cat-file blob HEAD:scripts/ai-factory.sh` vers un fichier `mktemp`, `AI_FACTORY_DELEGUE=1 bash <fichier> update <mêmes arguments>`, suppression du fichier, sortie avec le code de la version déléguée. Pas d'`exec`, pour pouvoir supprimer le fichier temporaire. Tout ce qui suit est exécuté par la version déléguée, avec sa liste blanche (C38, L18).
- Ancêtre : `git -C <clone> cat-file -e <SHA>^{commit}` puis `git -C <clone> merge-base --is-ancestor <SHA> HEAD` ; échec → refus avec les deux SHA, sauf `--forcer` → avertissement et suite (C34, L11, L15).
- SHA identique et N = M pour `CLAUDE.md` et `README.md` → « déjà à jour », rien n'est écrit (C31).
- Lecture du manifeste dans un tableau associatif `M[chemin]` ; `preparer <clone> <nom du manifeste>` → `N[chemin]` ; `L[chemin]` = `sha256sum` du fichier du projet s'il existe (C22).
- Pour chaque chemin de l'union de `M` et `N`, triée, la table de décision :

  | M | L | N | Action | Manifeste | Réf. |
  |---|---|---|---|---|---|
  | oui | = M | ≠ M | remplacé | N | C23 |
  | oui | = M | = M | rien, sauf bit exécutable aligné s'il diffère de la source | M | C23, C39, L19 |
  | oui | = M | absent | supprimé | retiré | C23 |
  | oui | ≠ M | = M | conservé | M | C24 |
  | oui | ≠ M, = N | ≠ M | rien | N | C25, L10 |
  | oui | ≠ M, ≠ N | ≠ M | `.nouveau` | N | C25, L8, L12 |
  | oui | ≠ M | absent | conservé | retiré | C26 |
  | oui | absent | = M | rien (suppression respectée) | M | C27 |
  | oui | absent | ≠ M | `.nouveau` | N | C27 |
  | oui | absent | absent | rien | retiré | C27 |
  | non | absent | oui | ajouté | N | C28 |
  | non | = N | oui | rien | N | C28 |
  | non | ≠ N | oui | `.nouveau` | N | C28 |

  Un renommage tombe de lui-même sur « absent » d'un côté et « non » de l'autre (C29). Toute écriture (remplacé, ajouté, `.nouveau`) passe par `ecrire_fichier` et prend le mode de la source ; un fichier modifié localement garde ses droits (C39).
- `scripts/ai-factory.sh` est traité en dernier : copie vers `scripts/ai-factory.sh.tmp`, puis `mv` (C32, L14). Le renommage reste nécessaire avec la délégation : le script du projet attend la fin de la version déléguée, et bash relit son fichier au fil de l'exécution. Le manifeste est écrit après (C14, L13).
- Rapport : ancien et nouveau SHA, puis une rubrique par catégorie, « droits alignés » comprise, vide omise (C30).

**Codes de retour** : 0 fait, 1 refus ou argument manquant, 2 commande inconnue + usage (Contrats).

Couvre : C1 à C7, C10 à C32, C34, C37 à C40.

### 4. Tests `scripts/tests/ai-factory/run.sh`

Sur le modèle de `hooks/tests/<nom>/run.sh` : dossier temporaire, `trap` de nettoyage, `GIT_CONFIG_GLOBAL=/dev/null` et `GIT_CONFIG_NOSYSTEM=1` exportés, une ligne `PASS`/`FAIL` par cas, code 1 si un cas échoue. Aucun accès réseau, rien n'est écrit dans le dépôt courant (C33).

**Faux clone.** `fixtures/source/` contient un ai-factory minimal : `claude/skills/demo/SKILL.md`, `hooks/pre-commit` (exécutable, `exit 0`), `templates/exemple.md`, `templates/projet/CLAUDE.md` et `README.md` avec `{{nom-projet}}`, `gitignore`, plus `requirements/open/01-x/notes.md` et `documents/doc.md` pour vérifier l'exclusion. Le test le copie dans un dépôt temporaire, renomme `claude/` en `.claude/` et `gitignore` en `.gitignore`, y ajoute `scripts/ai-factory.sh` du dépôt courant, et commite.

Deux règles sur `fixtures/`, qui est copié dans chaque projet avec `scripts/` :
- aucun fichier nommé `intent.md` ou `spec.md` : le contrôle 1 de `hooks/pre-commit` vise tout `intent.md` stagé, fixtures comprises, et bloquerait le commit de cette étape puis le premier commit de chaque projet ;
- aucun fichier ni dossier caché : un `.gitignore` global `.*/` empêcherait de commiter `.claude/` dans le projet (tests en échec sur un clone neuf), et un vrai `.gitignore` s'appliquerait au dossier de fixtures lui-même. Les évolutions (modifier, supprimer, renommer, ajouter) sont des commits dans ce faux clone.

Le faux clone ne dépend que des fixtures et du script : le test passe aussi dans un projet créé, qui n'a pas `templates/projet/` (A1).

| Cas | Réf. |
|---|---|
| création : liste blanche copiée, `requirements/`, `documents/`, `templates/projet/` absents, `hooks/pre-commit` exécutable | C5, C19, L5 |
| création : `CLAUDE.md` et `README.md` avec le nom injecté | C10, C11 |
| création : nom `a/b & c\d` injecté tel quel | L6 |
| création : manifeste (SHA, `projet`, lignes triées, vérifiables par `sha256sum -c`) | C12, C13 |
| création : marche à suivre affichée, aucun `.git/` dans la cible | C3, C20 |
| refus : cible non vide (fichier caché seul), code 1, rien écrit | C16, L1 |
| cible vide acceptée | L2 |
| refus : nom vide ; source sans `templates/projet/` ; source avec `.ai-factory/manifeste` | C17, C7, C18, L3 |
| refus : cible fichier ordinaire ; cible dossier `chmod 000` (`SKIP` si `id -u` = 0, où `-r` est toujours vrai) ; code 1, rien écrit | C40, L20, L21 |
| fichier non suivi dans `.claude/` non copié ; modification non commitée ignorée avec avertissement | C4, L4, L5 |
| commande inconnue : code 2 | Contrats |
| mise à jour : fichier intact remplacé, manifeste au nouveau SHA | A2, C23 |
| mise à jour : `CLAUDE.md` complété conservé, `CLAUDE.md.nouveau` produit avec le nom | A3, C25, L12 |
| mise à jour : skill supprimé localement non recréé, `.nouveau` à la 1re exécution seulement | A4, C27 |
| mise à jour : fichier intact supprimé en amont supprimé ; fichier modifié conservé et sorti du manifeste | A5, C23, C26 |
| mise à jour : collision `templates/x.md`, `.nouveau`, chemin entré au manifeste | A6, C28 |
| mise à jour : `requirements/` du projet inchangé | A7 |
| mise à jour : renommage = suppression + ajout | C29 |
| mise à jour : L = N, rien écrit ; `.nouveau` existant remplacé ; restauré à l'identique traité comme intact | L10, L8, L9 |
| mise à jour : déjà à jour, rien écrit | C31 |
| mise à jour : clone plus ancien refusé, code 1 ; accepté avec `--forcer` et avertissement ; SHA inconnu refusé | C34, L11, L15 |
| mise à jour : sans manifeste refusé | C21, L7 |
| mise à jour depuis `<clone>/scripts` : même résultat que depuis la racine, aucun fichier supprimé | C37, L17 |
| mise à jour : dossier ajouté à `LISTE_BLANCHE` par un commit du faux clone (`sed` sur son script), avec un fichier dedans → copié dès la 1re exécution | C38, L18 |
| mise à jour : source sans `scripts/ai-factory.sh` à `HEAD` refusée, code 1, rien écrit | C38 |
| mise à jour : `chmod +x` seul en amont → fichier intact aligné et listé ; fichier modifié localement non touché ; `.nouveau` au mode de la source | C39, L19 |
| mise à jour : script remplacé en dernier, exécution menée à son terme | C32, L14 |
| mise à jour interrompue (manifeste non réécrit) : la relance produit des `.nouveau`, aucune perte | C14, L13 |
| `*.nouveau` ignoré par `git status` dans un projet initialisé | C35, L16 |
| rapport : catégories et SHA | C30 |
| **A1** : `create` depuis le dépôt courant, puis `git init`, `core.hooksPath`, `bash scripts/verifier.sh` dans le projet → code 0 | A1 |

Le cas A1 ne joue que si le dépôt courant a `templates/projet/` (ai-factory lui-même) ; sinon `SKIP`. Dans le projet créé, le `run.sh` copié saute donc A1 : pas de récursion (R4).

Couvre : C33, et la vérification de C1 à C35, C37 à C40, L1 à L21, A1 à A7.

### 5. README, CLAUDE.md, recette et PR

- `README.md` d'ai-factory : section « Créer un nouveau projet » (commande `create`, marche à suivre, `git add -f`) et « Mettre à jour un projet » (commande, `.nouveau`, `--forcer`) ; lignes `scripts/ai-factory.sh`, `templates/projet/` et `scripts/tests/ai-factory/` au tableau du dépôt ; ligne `bash scripts/tests/ai-factory/run.sh` dans « Vérifier ».
- `CLAUDE.md` d'ai-factory, « Architecture » : lignes `scripts/ai-factory.sh` et `templates/projet/`.
- `validation.md` : sortie de `bash scripts/verifier.sh` (A1 à A7 via le `run.sh`), puis un essai réel : `scripts/ai-factory.sh create /tmp/<dossier> demo`, marche à suivre, `bash scripts/verifier.sh` dans le projet, une modification de `CLAUDE.md`, un commit factice dans ai-factory, `update`, relecture du rapport.
- PR ouverte par l'humain, revue par le tech lead.

Couvre : A1 à A7 (consignés).

## Tests à écrire

- Automatisés : `scripts/tests/ai-factory/run.sh`, les cas du tableau de l'étape 4, lancés par `scripts/verifier.sh`.
- Manuel : essai réel de l'étape 5, consigné dans `validation.md`.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1–C7, C10–C32, C34, C37–C40 | 3 (testé en 4) |
| C8, C9, C36 | 2 |
| C33 | 4 |
| C35 | 1 (testé en 4) |
| L1–L21 | 4 |
| A1–A7 | 4, consignés en 5 |

## Risques

- **R1 — `patsub_replacement`.** En bash ≥ 5.2, `&` dans la chaîne de remplacement de `${var//motif/remplacement}` désigne le motif trouvé, sauf si le remplacement est entre guillemets. Un nom de projet avec `&` serait corrompu ; le cas L6 le vérifie.
- **R2 — Bash ≥ 4.** Les tableaux associatifs n'existent pas dans le bash 3.2 de macOS. Le script vérifie `BASH_VERSINFO` et refuse avec un message clair.
- **R3 — `.gitignore` global `.*/`.** Sur un poste qui ignore les dossiers cachés, `.claude/` et `.ai-factory/` ne sont pas suivis dans le projet : le manifeste se perd au prochain clone et la mise à jour refuse (pas de manifeste). La marche à suivre rappelle `git add -f` (étape 3). Les tests n'en dépendent pas : leurs fixtures n'ont aucun dossier caché (étape 4).
- **R4 — Cas A1 récursif.** Le cas A1 lance le `verifier.sh` du projet créé, qui lance son propre `run.sh` ; la condition « `templates/projet/` présent » coupe la récursion. A1 utilise le `HEAD` du dépôt : pendant le build, il teste le dernier commit, pas l'arbre de travail.
- **R5 — Durée de `verifier.sh`.** Le cas A1 relance toute la suite dans le projet créé : la durée de `verifier.sh` augmente d'autant.
- **R6 — Noms de fichiers.** Les chemins avec retour à la ligne ne sont pas gérés (format `sha256sum`). Aucun n'existe dans la liste blanche.
- **R7 — Délégation et `$0`.** La version déléguée tourne depuis un fichier temporaire : `update` ne s'appuie jamais sur `dirname "$0"`, seulement sur le dossier courant et le chemin du clone (C38).

## Hors périmètre

Ceux de la spec : opérations Git dans le projet, dépôt existant non créé par le script, fusion automatique d'un `.nouveau`, mise à jour depuis le réseau.
