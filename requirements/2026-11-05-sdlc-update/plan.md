# Plan : 2026-11-05-sdlc-update

<!--
  Gabarit copié par `git sdlc claim 2026-11-05-sdlc-update build`, puis rempli par le skill
  generation-plan, en plan mode, sur la branche need/2026-11-05-sdlc-update/build, une fois spec.md
  fusionnée sur main. Commitez le plan rempli seul, avant tout code ; une étape = un
  commit. Si l’implémentation diverge, mettez le plan à jour dans la même PR. Pas de
  champ « Statut » : la fusion de la PR fait foi.
-->

- Spec : [spec.md](spec.md) · Intent : [intent.md](intent.md)
- Auteur : Mathieu Texier
- À risque : non
- Base : 04b33d0

<!-- « À risque » : oui si l’intent porte « Risk: élevé » ou si le développeur l’estime d’après ce que le changement peut casser. Oui → avis d’un tech lead sur le plan avant le code. -->

## Prérequis

- Intent et spec fusionnés sur `main` (spec : 04b33d0). Aucun besoin amont.
- La première release du kit, voulue par l'intent avant le build, n'existe pas au départ : `releases/latest` répond 404 sur `ocean-shiftmove/ai-factory`. Le build continue (décision du développeur) : les tests n'en dépendent pas, ils utilisent un `gh` factice. Le mainteneur la publie avant `git sdlc ready` ; A1 se joue à la release suivante, comme l'accepte la spec.

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `bin/git-sdlc` | modifié | 1, 4, 5 |
| `bin/tests/update-check/run.sh` | nouveau | 1, 4, 5 |
| `bin/tests/update-check/fixtures/gh` | nouveau | 4, 5 |
| `scripts/release-asset.sh` | nouveau | 2 |
| `scripts/tests/release-asset/run.sh` | nouveau | 2 |
| `scripts/tests/release-asset/fixtures/gh` | nouveau | 2 |
| `.github/workflows/release.yml` | nouveau | 2 |
| `scripts/deploy.sh` | modifié | 2, 3 |
| `scripts/tests/deploy/run.sh` | modifié | 2, 3 |
| `.sdlc/config` | modifié | 6 |
| `README.md` | modifié | 6 |
| `CLAUDE.md` | modifié | 6 |
| `requirements/2026-11-05-sdlc-update/tldr.md` | modifié | 6 |
| `requirements/2026-11-05-sdlc-update/validation.md` | nouveau | 6 |

## Étapes

### 1. Version de `git-sdlc`

Couvre : C3, C4, A2.

- Ligne unique `VERSION=dev` en tête de `bin/git-sdlc`.
- `version` et `--version` sont traités avant le contrôle du dépôt et de `gh` : la version seule sur la sortie standard, code 0, sans réseau. Ligne ajoutée à `usage`.
- Nouvelle suite `bin/tests/update-check/`, sur le modèle de `bin/tests/metrics/run.sh` (`depot`, `lance`, `ok`/`ko`).

### 2. Fichier `git-sdlc` joint à chaque release

Couvre : C5, C6, C7, A1, A3.

- `scripts/release-asset.sh <tag>`, propre au kit (`scripts/` n'est jamais copié) :
  - tag hors format `YY.MM.DD[.V]` : message, code 0, aucun fichier ;
  - fichier `git-sdlc` déjà joint (`gh release view --json assets`) : échec, message explicite, rien n'est remplacé ;
  - sinon : `git show <tag>:bin/git-sdlc`, la seule ligne `VERSION=dev` remplacée par `VERSION=<tag>` (échec si elle n'apparaît pas exactement une fois), `chmod +x`, `gh release upload`.
- `.github/workflows/release.yml` : `on: release: types: [published]`, `contents: read` au niveau du workflow, `contents: write` sur le seul job. Checkout du tag, tag passé par `env`, appel du script.
- `scripts/deploy.sh` : `.github/workflows/release.yml` ajouté à `EXCLUS`.
- Tests : suite `scripts/tests/release-asset/` avec un `gh` factice. Dans `scripts/tests/deploy/run.sh`, un `release.yml` placé dans le faux clone doit être absent du dépôt produit et du manifeste après install et update.

### 3. Tag de la release dans `.sdlc/manifeste`

Couvre : C8, C9, A4, L17, L18.

- Dans `deploy.sh`, le tag source est le plus récent (C2, fonction locale de comparaison) des tags `YY.MM.DD[.V]` de `git tag --points-at HEAD`.
- `appliquer` écrit `tag <T>` en ligne 3 quand ce tag existe ; sinon le manifeste ne porte que le SHA.
- `lire_manifeste` accepte une ligne 3 `tag …` facultative.
- « Déjà à jour » exige aussi le même tag : sinon le manifeste est réécrit (tag ajouté, ou retiré pour L18).
- Tests dans `scripts/tests/deploy/` : install au tag `26.11.05`, update depuis un tag plus récent, deux tags sur `HEAD`, update hors tag, manifeste sans tag relu puis complété.

### 4. Vérification et avis

Couvre : C1, C2, C10, C11, C12, C13, L1–L9, L14, L15, A5, A6, A7, A8, A13, A14.

- `update_check` est appelée dans le `case` final de `bin/git-sdlc`, avant chaque commande sauf `help`, `version`, `--version` et un usage invalide.
- Rien à comparer (`VERSION=dev` et pas de `.sdlc/manifeste`) : aucune requête.
- Référence : `cfg kitRepo ocean-shiftmove/ai-factory` ; `gh api repos/<r>/releases/latest --jq .tag_name`, puis `gh api repos/<r>/commits/<tag> --jq .sha`. Les valeurs sont validées par format, car en 404 `gh api` écrit le corps d'erreur sur la sortie standard.
- Comparaison `YY.MM.DD[.V]` champ par champ (C2) ; `git-sdlc` selon C11 ; kit selon C12, par le tag du manifeste ou, à défaut, par le SHA.
- Un avis par élément en retard, par `warn`, au format des Contrats ; le chemin de `git-sdlc` vient de `$0`.
- Aucun `die` dans la vérification : la sortie standard et le code de retour de la commande sont inchangés.
- Tests : une copie de `git-sdlc` avec `VERSION=26.11.05` et un `gh` factice (tag, SHA, échec, 404, délai, journal des appels). La sortie standard et le code de retour sont comparés à une exécution avec `sdlc.updateCheck=false`.

### 5. Cache, échec, délai, désactivation

Couvre : C14, C15, C16, C17, C18, C19, C20, L10–L13, L16, L19–L21, A9, A10, A11, A12, A16.

- Cache : `$(git rev-parse --git-common-dir)/sdlc-update-check`, une ligne `<date>\tok\t<tag>\t<sha>` ou `<date>\tko\t<raison>`. Si sa date est le jour local, il sert sans requête. S'il est illisible, il vaut un cache absent.
- Échec : une ligne « vérification impossible (<raison>) », puis l'échec est mis en cache. Aucun nouvel avis le même jour.
- Délai : `gh` tourne en arrière-plan, avec un garde-fou `sleep <délai>; kill` en sous-shell. Un dépassement donne la raison « délai dépassé ». `sdlc.updateCheckTimeout` vaut `5` s'il n'est pas un entier positif. Le garde-fou et les fichiers temporaires sont arrêtés ou supprimés par `cleanup`, `die` compris.
- `sdlc.updateCheck=false` : ni requête, ni lecture ou écriture du cache, ni avis.
- Tests :
  - deux commandes le même jour : un seul appel au journal ;
  - cache partagé avec un worktree ; nouvelle requête depuis un autre dépôt ;
  - cache de la veille ; cache tronqué ;
  - `gh` qui répond en 3 s avec un délai de 1 : la commande finit en moins de 3 s ;
  - délai `0`, `abc` ou vide ;
  - `false` en global, `true` en local.

### 6. Documentation et fiche de recette

Couvre : A15.

- `README.md` : installation de `git-sdlc` depuis le fichier joint à la release, `git sdlc version`, avis et réglages (`sdlc.kitRepo`, `sdlc.updateCheck`, `sdlc.updateCheckTimeout`), ligne `tag` du manifeste, workflow de release propre au kit.
- `CLAUDE.md` : la ligne sur les tests de `bin/git-sdlc` et l'architecture (workflow de release, `scripts/release-asset.sh`).
- `.sdlc/config` : `updateCheckTimeout` ajouté en commentaire.
- `tldr.md` : résumé à l'étape build.
- `validation.md` : fiche de recette ajoutée à la PR build, avec la colonne « Cas » remplie par les libellés `PASS` réels.

## Tests à écrire

- `bash bin/tests/update-check/run.sh` : version, vérification, avis, cache, échec, délai, désactivation (étapes 1, 4, 5). Il faut `jq` si le `gh` factice en a besoin.
- `bash scripts/tests/release-asset/run.sh` : fichier joint, refus d'un fichier déjà joint, tag hors format (étape 2).
- `bash scripts/tests/deploy/run.sh` : workflow non copié, tag au manifeste (étapes 2, 3).
- `bash scripts/verify.sh` : tous les `run.sh` du dépôt, à chaque étape ; `bash -n bin/git-sdlc`.
- Manuel : A1, à la première release qui suit la fusion du build.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1, C2 | 4 |
| C3, C4 | 1 |
| C5, C6, C7 | 2 |
| C8, C9 | 3 |
| C10, C11, C12, C13 | 4 |
| C14–C20 | 5 |
| L1–L9, L14, L15 | 4 |
| L10–L13, L16, L19–L21 | 5 |
| L17, L18 | 3 |
| A1, A3 | 2 |
| A2 | 1 |
| A4 | 3 |
| A5–A8, A13, A14 | 4 |
| A9–A12, A16 | 5 |
| A15 | 1–6 |

Les étapes 2 et 3 ne s'appuient pas sur l'étape 4 : ce sont des branches parallèles, mais petites, et le développeur maintient le plan d'un seul tenant.

## Risques

- Étape la plus risquée, la 5 : un processus orphelin ou une commande bloquée par le garde-fou, en particulier après un `die`. Parade : garde-fou tué dans `cleanup`, A16 et L14 testés.
- Ce qui peut casser :
  - la sortie standard ou le code de retour des commandes existantes. Parade : A6 et A10 comparent avec une exécution désactivée, et les suites `metrics` et `git-sdlc-checks` restent vertes, car la version `dev` sans manifeste ne fait aucune requête ;
  - la lecture des manifestes par `deploy.sh`. Parade : cas de manifeste ancien dans les tests. Un manifeste avec `tag` est illisible par un ancien `deploy.sh` : la spec l'accepte.
- Première release absente au départ : à publier avant `git sdlc ready`. A1 n'est jouable qu'à la release qui suit le build.
- Options écartées :
  - script inline dans le YAML du workflow : remplacé par `scripts/release-asset.sh`, qui se teste ;
  - `curl` sur l'API : remplacé par `gh api`, prérequis de l'intent, qui couvre les dépôts privés ;
  - bibliothèque partagée pour la comparaison de versions : la fonction est dupliquée, car `git-sdlc` doit fonctionner seul sur un poste ;
  - requête GitHub quand rien n'est à comparer ;
  - `perl -e alarm` ou `timeout` facultatif : remplacés par un garde-fou en bash.

## Hors périmètre

- Commande qui applique la mise à jour (`2026-11-05-sdlc-self-update`).
- Publication de la première release du kit : geste du mainteneur.
- Vérification d'empreinte ou de signature du fichier joint.
