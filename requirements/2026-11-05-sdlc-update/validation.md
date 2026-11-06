# Recette : 2026-11-05-sdlc-update

<!--
  Fiche de recette de la PR build : un critère d'acceptation de la spec par ligne, avec sa
  preuve. Le recetteur remplit les constats ; la recette se refait après toute modification
  de la branche, sur le nouveau commit. Pas de champ « Statut » : la case « Recette validée »
  de la PR et sa fusion font foi.
-->

- Spec : [spec.md](spec.md) · Plan : [plan.md](plan.md)
- Branche : `need/2026-11-05-sdlc-update/build`
- Commit recetté : <à renseigner à chaque recette>
- Recetteur : <à désigner>

Fiche préparée avant le build, colonne « Cas » remplie au build avec les libellés `PASS` réels. Si un cas manque, le critère n'est pas couvert.

## Critères automatisés

Commandes, depuis la racine du dépôt (les faux `gh` de ces suites n'utilisent pas `jq`) :

```bash
bash bin/tests/update-check/run.sh          # version, vérification et avis : une ligne PASS/FAIL par cas
bash scripts/tests/deploy/run.sh            # tag au manifeste, workflow non copié
bash scripts/tests/release-asset/run.sh     # fichier joint à la release (appui d'A1)
bash scripts/verify.sh                      # tous les run.sh du dépôt
```

Constat du <date>, au commit `<sha>` : <n> cas PASS, <n> FAIL ; `verify.sh` : <n> run.sh lancés, <n> en échec.

### `git-sdlc` : version, vérification, avis (`bin/tests/update-check/`)

| Critère | Ce que le cas doit montrer | Cas |
|---|---|---|
| A2 Version `dev` dans le dépôt du kit | `bin/git-sdlc version` et `--version` affichent `dev`, sans appel au faux `gh` (C4) || `version : dev dans le dépôt du kit` · `--version : synonyme de version` · `version, --version : aucun appel à gh` |
| A5 Dépôt de référence | Journal du faux `gh` : le dépôt de `.sdlc/config` est interrogé, puis `ocean-shiftmove/ai-factory` quand la clé est absente || `sdlc.kitRepo de .sdlc/config interrogé` · `sdlc.kitRepo : git config l'emporte sur .sdlc/config` · `sans sdlc.kitRepo : ocean-shiftmove/ai-factory` |
| A6 Avis pour `git-sdlc` en retard | Une ligne d'avis sur la sortie d'erreur, qui nomme `26.11.12` ; sortie standard et code identiques avec `sdlc.updateCheck=false` || `git-sdlc en retard : une ligne d'avis` · `… : version installée et disponible` · `… : mise à jour manuelle citée` · `… : code et sortie standard inchangés (die de status)` |
| A7 Aucun avis à jour | Sortie d'erreur vide de tout avis || `à jour : aucun avis` |
| A8 Avis pour le kit en retard | Une ligne d'avis qui nomme `26.11.12` et `deploy.sh update` || `kit en retard : une seule ligne d'avis` · `kit en retard : version, release et deploy.sh update` |
| A9 Une requête par jour | Deux commandes, une seule interrogation de la release au journal || `deux commandes le même jour : GitHub interrogé une fois` |
| A10 GitHub injoignable | Avis « vérification impossible », code égal à celui d'une exécution sans vérification || `GitHub injoignable : avis vérification impossible` · `… : code et sortie standard inchangés` · `… : la commande s'exécute (board, code 0)` |
| A11 Dépôt du kit illisible | Même résultat qu'A10, avec une réponse « introuvable » du faux `gh` || `dépôt du kit introuvable : avis vérification impossible` · `… : corps d'erreur de gh non affiché, code 0` |
| A12 Désactivation | Aucun appel pour la release, aucun avis, aucun fichier de cache || `sdlc.updateCheck false : aucun appel de release, aucun avis` · `désactivée : aucun cache écrit` · `désactivée : cache ni lu ni réécrit` |
| A13 Manifeste ancien à jour | Manifeste sans tag au SHA du tag : aucun avis pour le kit || `manifeste sans tag au SHA de la release : aucun avis` · `manifeste sans tag : SHA du tag demandé` |
| A14 Manifeste ancien en retard | Manifeste sans tag à un SHA antérieur : avis pour le kit || `manifeste sans tag, SHA antérieur : avis nommant la release` |
| A16 Délai de la requête | Faux `gh` lent de 3 s, `sdlc.updateCheckTimeout = 1` : avis « délai dépassé », commande terminée en moins de 3 s || `délai dépassé : avis vérification impossible (délai dépassé)` · `… : commande terminée en moins de 3 s` · `… : commande exécutée, code inchangé` |

Cas limites à couvrir sans critère A dédié, à relier ici au build :
- C2, L9 : comparaison numérique des tags (`26.11.05.10` après `26.11.05.9`, `26.11.05` avant `26.11.05.2`) → `26.11.05 installé, 26.11.05.2 publié : avis`, `26.11.05.2 < 26.11.05.10 numériquement` ;
- L2, L3 → `kit en retard : une seule ligne d'avis`, `les deux en retard : deux lignes d'avis` ;
- L4 : `git-sdlc` en `dev`, aucun avis → `git-sdlc dev, kit à jour : aucun avis`, `git-sdlc dev sans manifeste : aucune requête de release` ;
- L5 → `sans manifeste : seul git-sdlc vérifié, à jour` ;
- L8 : tag installé plus récent que la release, aucun avis → `installé plus récent que la release : aucun avis` ;
- L10 et L11 : cache partagé par les worktrees, distinct d'un autre dépôt → `autre worktree du dépôt : cache partagé, aucune requête`, `autre dépôt le même jour : nouvelle requête` ;
- C15 → `depuis le cache : l'avis se refait`, `git-sdlc mis à jour dans la journée : plus d'avis, sans requête` ;
- L12, L19 : cache de la veille ou illisible, nouvelle requête → `cache de la veille : nouvelle requête`, `cache de la veille : réécrit au jour`, `cache tronqué : traité comme absent, nouvelle requête`, `cache corrompu : nouvelle requête` ;
- L13, C18 : échec mis en cache, avis d'échec une seule fois par jour → `échec : avis la première fois`, `échec mis en cache : ni requête ni avis le même jour`, `gh non authentifié : avis vérification impossible`, `délai dépassé : échec mis en cache` ;
- L14 : commande qui échoue d'elle-même, avis avant, code 1 → `git-sdlc en retard : code et sortie standard inchangés (die de status)`, `git-sdlc en retard : avis avant l'erreur de la commande` ;
- L15 : `--porcelain`, sortie standard inchangée → `board --porcelain : sortie standard et code inchangés, avis sur stderr` ;
- L16 : `sdlc.updateCheck` à `false` en global et `true` en local, vérification active → `false en global, true en local : vérification active`, `false en global seul : désactivée` ;
- L21 : `sdlc.updateCheckTimeout` invalide, délai de 5 s → `délai « 0 » …`, `délai « abc » …`, `délai « vide » : 5 s par défaut, réponse en 1 s acceptée` ;
- C10 → `help, version, usage invalide : aucune vérification`.

### `deploy.sh` : tag et workflow (`scripts/tests/deploy/`)

| Critère | Ce que le cas doit montrer | Cas |
|---|---|---|
| A3 Workflow non copié | Après `install` puis `update`, le workflow de release est absent du dépôt produit et de son manifeste || `install : workflow de release du kit non copié, hors manifeste` · `update : workflow de release du kit non copié, hors manifeste` · `bout en bout : workflow de release du kit réel non copié` |
| A4 Tag écrit au manifeste | `tag 26.11.05` après `install` depuis ce tag, puis le nouveau tag après `update` || `tag : install depuis un tag, ligne tag en 3e ligne` · `tag : update depuis un tag plus récent, deux tags à HEAD : le plus récent` |

Cas limites à couvrir :
- L17 : deux tags sur `HEAD`, le plus récent est écrit → `tag : update depuis un tag plus récent, deux tags à HEAD : le plus récent` (`26.11.05.10` devant `26.11.05.2`) ;
- L18 : `update` depuis un clone hors tag, ligne `tag` retirée → `tag : update hors tag, ligne tag retirée` ;
- C9 : manifeste sans tag lu par le nouveau `deploy.sh`, tag ajouté par une mise à jour depuis un tag → `tag : manifeste sans tag, même SHA tagué depuis : tag ajouté`, `tag : manifeste sans tag, rien d'autre écrit` ;
- ligne `tag` mal formée → `tag : ligne tag illisible refusée` ;
- les cas existants de `scripts/tests/deploy/run.sh` passent toujours.

### Fichier joint à la release (`scripts/tests/release-asset/`), appui d'A1

A1 reste manuel ; ces cas couvrent la logique du workflow, avec un faux `gh`.

| Règle | Ce que le cas doit montrer | Cas |
|---|---|---|
| C5 | Fichier `git-sdlc` exécutable joint à la release du tag, version = tag, seule la ligne `VERSION` change | `tag YY.MM.DD : fichier joint` · `… : envoyé sous le nom git-sdlc, à la release du tag` · `… : exécutable` · `… : version affichée = tag` · `… : seule la ligne VERSION change` · `tag YY.MM.DD.V : fichier joint, version = tag` |
| C6 | Fichier déjà joint : échec explicite, rien remplacé ; tag hors format : aucun fichier ; `contents: write` sur le seul job | `déjà joint : échec explicite, rien envoyé` · `déjà joint : message` · `déjà joint : aucun upload demandé` · `tag hors format : code 0, aucun fichier, aucun appel à gh` · `workflow : contents: write sur le seul job` |
| C5 | Déclenché par la publication de la release | `workflow : déclenché par la publication de la release` |

### A15 Tests en dépôt temporaire

Constat à reporter : les deux suites créent un dépôt git temporaire, utilisent un `gh` factice et écrivent une ligne `PASS`/`FAIL` par cas.

## Critères manuels

Le faux `gh` applique `--jq` avec `jq`, et le vrai `gh` a son propre moteur (constat de `2026-11-04-show-red-check`). Ces essais se font donc aussi contre GitHub. Ils demandent de créer une release et de lire les releases : le PAT du devcontainer est en lecture seule, ils se font côté hôte.

### Préparation

1. Utiliser un dépôt jetable où l'on peut publier des releases, par exemple le fork `mathieu-texier-ocean/ai-factory`, jamais `ocean-shiftmove/ai-factory`. Le workflow d'une release est lu au commit du tag : y pousser la branche build.
2. Utiliser la version recettée : `bin/git-sdlc` de la branche build, appelé par son chemin, par exemple `alias sdlc=$PWD/bin/git-sdlc`.
3. Après la recette, supprimer les releases et les tags de test sur le fork.

### A1 Fichier joint à chaque release (Manuel)

Procédure :

1. Sur le fork, publier une release sur la branche build : `gh release create <YY.MM.DD> -R <fork> --target need/2026-11-05-sdlc-update/build --title <YY.MM.DD> --generate-notes`, c'est-à-dire ce que fait `git sdlc release`, mais visant la branche.
2. Attendre la fin du workflow (`gh run list -R <fork> --workflow <fichier du workflow>`).
3. `gh release download <YY.MM.DD> -R <fork> -p git-sdlc -O /tmp/git-sdlc-recette && chmod +x /tmp/git-sdlc-recette && /tmp/git-sdlc-recette version`.
4. Attendu : le fichier est joint sans autre action, et la version affichée vaut le tag.
5. Publier une seconde release le même jour (`<YY.MM.DD>.2`) : attendu, un fichier joint dont la version vaut `<YY.MM.DD>.2`.
6. Relancer le workflow sur la première release (`gh run rerun`) : attendu, un échec explicite, le fichier joint inchangé (C6).

| Date | Commit | Tag | Fichier joint | Version affichée | Constat |
|---|---|---|---|---|---|
| | | | | | |

Sur `ocean-shiftmove/ai-factory`, la première release publiée avant le build n'a pas de fichier joint, ce qui est accepté par le PO. A1 s'y vérifie de nouveau à la première release après la fusion du build.

### Vérification contre le vrai `gh` (complément aux critères A5 à A14)

Dans un dépôt produit de test, avec `git config sdlc.kitRepo <fork>` :

1. Manifeste à un tag antérieur à la dernière release du fork : `sdlc status` affiche l'avis du kit (A8).
2. `git-sdlc` téléchargé de la release précédente : l'avis de `git-sdlc` s'affiche (A6). Avec celui de la dernière release, aucun avis (A7).
3. Manifeste sans tag, au SHA du tag de la dernière release : aucun avis pour le kit (A13).
4. Deuxième commande dans la journée : aucune requête GitHub, constatée avec `GH_DEBUG=api` (A9).
5. `git config sdlc.kitRepo <org>/inexistant` après suppression du cache : avis « vérification impossible » (A11).
6. Hors réseau, ou avec `sdlc.updateCheckTimeout = 1` sur un réseau lent : avis « vérification impossible », commande exécutée (A10, A16).
7. Sur macOS (bash 3.2), rejouer les étapes 1 et 6 : le délai doit fonctionner sans la commande `timeout`.

| Date | Commit | Étape | Poste (Linux / macOS) | Constat |
|---|---|---|---|---|
| | | | | |

## Écarts connus, à signaler dans la PR

- **Déclencheur du workflow.** La publication de la release, et non le tag comme l'écrit l'intent : arbitrage du PO du 2026-11-06, noté dans la spec.
- **Première release sans fichier joint.** Acceptée par le PO ; A1 est recetté sur le fork, puis à la première release après la fusion.
- **Cache par dépôt du kit.** La ligne du cache porte aussi `sdlc.kitRepo` : changer de dépôt de référence dans la journée relance la requête. Ajout du build, sans effet sur les critères.
- **`--jq` non rejoué par le faux `gh`.** Les faux `gh` de `update-check` et `release-asset` ignorent `--jq` et répondent directement la valeur filtrée. Les filtres réels (`.tag_name`, `.sha`, `.assets[].name`) ne sont donc éprouvés que par les critères manuels contre GitHub.
- **Requête abandonnée.** Au-delà du délai, le garde-fou tue la requête ; un `gh` déjà lancé peut finir seul en arrière-plan, sans effet sur la commande (il n'écrit que dans un dossier temporaire supprimé).
- **Désactivation avancée.** `sdlc.updateCheck=false` (C19) est livrée à l'étape 4 du plan plutôt qu'à la 5 : elle sert de témoin aux tests ; `plan.md` est à jour.
