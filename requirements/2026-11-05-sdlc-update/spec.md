# Spec : 2026-11-05-sdlc-update

<!--
  Gabarit copié par `git sdlc claim 2026-11-05-sdlc-update spec`, puis rempli par le skill
  generation-spec, sur la branche need/2026-11-05-sdlc-update/spec, une fois intent.md fusionné sur main.
  Le product owner relit la PR et la fusionne : pas de champ « Statut », l’étape se
  déduit de git (`git sdlc status 2026-11-05-sdlc-update`).
  Numéros C, L et A stables : une révision ajoute un nouveau numéro, elle ne renumérote
  jamais. Le plan et la recette s’y réfèrent.
-->

- Intent : [intent.md](intent.md)
- Auteur : Mathieu Texier

## Périmètre

<!-- Ce que la spec couvre, en un paragraphe. -->

Savoir qu'une release plus récente du kit existe, sans rien appliquer. La spec couvre : la version portée par `git-sdlc` et sa publication en fichier joint à chaque release par un workflow propre au kit ; le tag de la release dans `.sdlc/manifeste`, écrit par `deploy.sh` ; la vérification, au plus une fois par jour et par dépôt, de `git-sdlc` et du kit du dépôt courant contre la dernière release de `sdlc.kitRepo` ; l'avis d'une ligne qu'en tirent les commandes `git sdlc`, et sa désactivation. Elle fixe aussi le nom du fichier joint, l'affichage de la version et le format du manifeste, sur lesquels s'appuie `2026-11-05-sdlc-self-update`.

## Comportements

<!-- Règles numérotées C1, C2… groupées par résultat attendu de l’intent. Chaque résultat a au moins un comportement. -->

### Release de référence

- **C1.** La référence est la dernière release du dépôt du kit, telle que GitHub la désigne (ni brouillon, ni pré-release). Le dépôt est la clé `sdlc.kitRepo`, lue comme les autres réglages (`git config`, puis `.sdlc/config`), par défaut `ocean-shiftmove/ai-factory`.
- **C2.** Deux versions `YY.MM.DD[.V]` se comparent champ par champ, numériquement ; un tag sans `.V` vaut `.1`. Ainsi `26.11.05` < `26.11.05.2` < `26.11.05.10` < `26.11.06`.

### Version de `git-sdlc` et fichier joint à la release

- **C3.** `bin/git-sdlc` porte sa version dans une variable, sur une ligne unique et repérable du script, qui vaut `dev` dans le dépôt du kit.
- **C4.** `git sdlc version` affiche cette version seule sur une ligne ; `git sdlc --version` est un synonyme. Ni l'un ni l'autre ne déclenche la vérification (C10).
- **C5.** Un workflow GitHub Actions du dépôt du kit, déclenché par la publication d'une release dont le tag est `YY.MM.DD[.V]` (créée avec son tag par `git sdlc release`), joint à la release de ce tag un fichier nommé `git-sdlc` : le `bin/git-sdlc` du tag, variable de version égale au tag, exécutable. Aucune action manuelle n'est nécessaire.
- **C6.** Si le fichier est déjà joint à la release, le workflow échoue avec un message explicite sans rien remplacer. Une release dont le tag n'est pas au format `YY.MM.DD[.V]` ne reçoit aucun fichier. Seul le job qui joint le fichier a la permission `contents: write`.

### Workflow propre au kit

- **C7.** Le workflow de C5 n'est jamais copié dans un dépôt produit par `deploy.sh install` ni `update`. Un dépôt produit où il aurait été copié avant ce besoin n'en a pas : il n'existait pas.

### Tag dans `.sdlc/manifeste`

- **C8.** Quand le `HEAD` du clone du kit porte un ou plusieurs tags `YY.MM.DD[.V]`, `deploy.sh install` et `update` écrivent le plus récent (C2) dans le manifeste, en plus du SHA. Sans tel tag, le manifeste ne porte que le SHA, comme aujourd'hui.
- **C9.** `deploy.sh update` lit un manifeste avec ou sans tag. Un manifeste sans tag reste lisible par le nouveau `deploy.sh`, et une mise à jour depuis un tag y ajoute le tag.

### Vérification et avis

- **C10.** Toute commande `git sdlc` vérifie, avant sa propre sortie, sauf `help`, `version`, `--version` et un usage invalide. La vérification ne change ni la sortie standard, ni le code de retour de la commande.
- **C11.** `git-sdlc` est en retard quand sa version est un tag inférieur au tag de la release (C2). Une version `dev` n'est jamais en retard et ne donne aucun avis.
- **C12.** Le kit du dépôt courant est vérifié seulement si `.sdlc/manifeste` existe. Avec un tag au manifeste, il est en retard si ce tag est inférieur à celui de la release. Sans tag, il est comparé au SHA du commit que vise le tag de la release : différent, il est en retard.
- **C13.** Pour chaque élément en retard, un avis d'une ligne sur la sortie d'erreur, préfixé `git-sdlc : `, nomme l'élément, sa version installée, la version disponible et la mise à jour manuelle : pour `git-sdlc`, télécharger le fichier joint à la release dans le `PATH` ; pour le kit, lancer `deploy.sh update` depuis un clone du kit à ce tag. À jour : aucun avis.

### Une interrogation de GitHub par jour

- **C14.** Le résultat de la vérification (date du jour, tag de la release, SHA qu'il vise, ou l'échec) est mis en cache dans un fichier sous le dossier git commun du dépôt (`git rev-parse --git-common-dir`), partagé par ses worktrees.
- **C15.** Si le cache date du jour local, la commande s'en sert sans interroger GitHub. Sinon, elle interroge GitHub et réécrit le cache. Les comparaisons de C11 et C12 se refont à chaque commande, depuis le cache : un `git-sdlc` ou un kit mis à jour dans la journée ne donne plus d'avis.
- **C16.** Un cache illisible ou corrompu vaut un cache absent.

### GitHub injoignable

- **C17.** Si GitHub est injoignable, si `gh` n'est pas authentifié ou si le dépôt du kit, ou sa dernière release, est illisible, la commande affiche une ligne sur la sortie d'erreur, `git-sdlc : vérification des mises à jour impossible (<raison courte>)`, puis s'exécute normalement, avec son code de retour inchangé.
- **C18.** L'échec est mis en cache pour le jour : les commandes suivantes du même jour n'interrogent pas GitHub et n'affichent pas de nouveau l'avis d'échec.
- **C20.** La requête GitHub d'une vérification est abandonnée au-delà du délai `sdlc.updateCheckTimeout`, en secondes, lu comme les autres réglages (`git config`, puis `.sdlc/config`), par défaut `5`. Une valeur qui n'est pas un entier positif vaut `5`. Un dépassement est un échec au sens de C17, raison « délai dépassé », mis en cache selon C18.

### Désactivation

- **C19.** Si `git config sdlc.updateCheck` vaut `false` (local ou global), la commande n'interroge pas GitHub, ne lit ni n'écrit le cache et n'affiche aucun avis. Toute autre valeur, ou l'absence de la clé, laisse la vérification active.

## Cas limites

<!-- Situations aux bords et comportement attendu, en citant la règle C concernée. -->

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | `git-sdlc` et kit à la dernière release | Aucun avis (C13). |
| L2 | `git-sdlc` en retard, kit à jour (ou l'inverse) | Un seul avis, pour l'élément en retard (C13). |
| L3 | Les deux en retard | Deux lignes d'avis (C13). |
| L4 | `git-sdlc` en version `dev` | Aucun avis pour `git-sdlc` (C11). |
| L5 | Dépôt sans `.sdlc/manifeste` (dépôt du kit, ou kit non installé) | Seul `git-sdlc` est vérifié (C12). |
| L6 | Manifeste sans tag, SHA égal à celui que vise le tag de la release | Aucun avis pour le kit (C12). |
| L7 | Manifeste sans tag, installé depuis un commit postérieur à la release | Avis pour le kit, le SHA étant différent (C12) ; voir « Points d'attention ». |
| L8 | Tag installé plus récent que la dernière release (release supprimée, ou pré-release) | Aucun avis (C11, C12). |
| L9 | Deux tags le même jour, `26.11.05` installé, `26.11.05.2` publié | Avis (C2). |
| L10 | Deuxième commande le même jour, dans le même dépôt ou un autre worktree du dépôt | Aucune requête GitHub (C14, C15). |
| L11 | Autre dépôt le même jour | Nouvelle requête : le cache est par dépôt (C14). |
| L12 | Cache de la veille | Nouvelle requête, cache réécrit (C15). |
| L13 | GitHub injoignable, `gh` non authentifié ou dépôt du kit sans release | Avis « vérification impossible », commande exécutée, code inchangé (C17) ; une fois par jour (C18). |
| L14 | Commande qui échoue d'elle-même (`die`) | Avis éventuel affiché avant, code 1 de la commande inchangé (C10). |
| L15 | `status --porcelain`, `board --porcelain`, `metrics --porcelain` | Sortie standard inchangée : l'avis va sur la sortie d'erreur (C10, C13). |
| L16 | `sdlc.updateCheck` à `false` en global, `true` en local | Vérification active : la valeur locale l'emporte (C19). |
| L17 | `HEAD` du clone du kit porte deux tags de release | Le plus récent est écrit au manifeste (C8). |
| L18 | `deploy.sh update` depuis un clone hors tag sur un manifeste qui a un tag | Manifeste réécrit sans tag : la version installée n'est plus une release (C8). |
| L19 | Cache rendu illisible (contenu tronqué) | Traité comme absent, nouvelle requête (C16). |
| L20 | GitHub répond au-delà du délai | Requête abandonnée, avis « vérification impossible (délai dépassé) », commande exécutée (C20). |
| L21 | `sdlc.updateCheckTimeout` vaut `0`, `abc` ou est vide | Délai de 5 secondes (C20). |

## Contrats

<!-- Entrées, sorties, codes de retour et formats échangés (API, CLI, fichiers). « Sans objet » si rien n’est exposé. -->

- Réglages : `sdlc.kitRepo` (`git config`, puis `.sdlc/config`, défaut `ocean-shiftmove/ai-factory`) ; `sdlc.updateCheckTimeout` (`git config`, puis `.sdlc/config`, secondes, défaut `5`), ajouté commenté au `.sdlc/config` du kit ; `sdlc.updateCheck` (`git config` local ou global, `false` désactive).
- `git sdlc version`, `git sdlc --version` : sortie standard `<version>\n` (`dev` ou `YY.MM.DD[.V]`), code 0, sans accès réseau.
- Avis, sur la sortie d'erreur, une ligne par élément en retard, par exemple :

  ```
  git-sdlc : git-sdlc 26.11.05 installé, 26.11.12 disponible : gh release download 26.11.12 -R <kitRepo> -p git-sdlc -O <chemin> --clobber && chmod +x <chemin>
  git-sdlc : kit du dépôt 26.11.05 installé, 26.11.12 disponible : <clone du kit au tag 26.11.12>/scripts/deploy.sh update <dépôt>
  git-sdlc : vérification des mises à jour impossible (<raison courte>)
  ```

- Codes de retour et sortie standard des commandes : inchangés.
- Fichier joint à chaque release du kit : nom `git-sdlc`, `bin/git-sdlc` du tag avec la variable de version égale au tag.
- `.sdlc/manifeste` : ligne 1 `sdlc-kit <SHA>`, ligne 2 `projet <nom>`, puis, seulement si le kit est installé depuis un tag, une ligne `tag <YY.MM.DD[.V]>`, puis les lignes `<sha256>  <chemin>` triées par chemin.
- Cache : un fichier sous `$(git rev-parse --git-common-dir)`, jamais suivi par git ; contenu interne, non garanti.
- GitHub, lecture seule via `gh` : dernière release de `sdlc.kitRepo` et SHA du commit que vise son tag. Le workflow de release, déclenché par `release: published`, écrit seulement le fichier joint, sur le dépôt du kit, avec `contents: write` sur ce seul job.

## Critères d’acceptation

<!-- Une ligne = un scénario, lu par la recette. Chaque critère de succès de l’intent a au moins une ligne. Type : Automatisé | Manuel | Humain. -->

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Fichier joint à chaque release | Le workflow de release sur `main` du kit | Le mainteneur crée une release `YY.MM.DD` avec `git sdlc release` | La release a un fichier `git-sdlc` joint, sans action manuelle, et `git-sdlc version` de ce fichier affiche le tag | Manuel |
| A2 | Version `dev` dans le dépôt du kit | Le `bin/git-sdlc` du dépôt du kit | `bin/git-sdlc version` | Affiche `dev` | Automatisé |
| A3 | Workflow non copié | Un clone du kit qui contient le workflow de release | `deploy.sh install` puis `deploy.sh update` dans un dépôt produit | Le workflow est absent du dépôt produit et de son manifeste | Automatisé |
| A4 | Tag écrit au manifeste | Un clone du kit dont `HEAD` porte le tag `26.11.05` | `deploy.sh install`, puis `deploy.sh update` depuis un tag plus récent | Le manifeste porte `tag 26.11.05`, puis le nouveau tag | Automatisé |
| A5 | Dépôt de référence | `sdlc.kitRepo` défini dans `.sdlc/config`, puis absent | Une commande `git sdlc`, cache vidé | Le `gh` factice est interrogé sur ce dépôt, puis sur `ocean-shiftmove/ai-factory` | Automatisé |
| A6 | Avis pour `git-sdlc` en retard | Un `git-sdlc` à la version `26.11.05`, une release `26.11.12` | `git sdlc status` | Une ligne d'avis nomme `26.11.12` et la mise à jour de `git-sdlc` ; code et sortie standard identiques à une exécution sans vérification | Automatisé |
| A7 | Aucun avis à jour | `git-sdlc` et manifeste à `26.11.12`, release `26.11.12` | `git sdlc status` | Aucun avis | Automatisé |
| A8 | Avis pour le kit en retard | Manifeste à `tag 26.11.05`, release `26.11.12` | `git sdlc status` | Une ligne d'avis nomme `26.11.12` et `deploy.sh update` | Automatisé |
| A9 | Une requête par jour | Cache vide | Deux commandes `git sdlc` le même jour, dans le même dépôt | Le `gh` factice n'est interrogé qu'une fois | Automatisé |
| A10 | GitHub injoignable | Un `gh` factice qui échoue | `git sdlc status` | Avis « vérification impossible », code de retour égal à celui d'une exécution sans vérification | Automatisé |
| A11 | Dépôt du kit illisible | Un `gh` factice qui répond « introuvable » pour `sdlc.kitRepo` | `git sdlc status` | Même résultat qu'A10 | Automatisé |
| A12 | Désactivation | `git config sdlc.updateCheck false` | Une commande `git sdlc` | Aucun appel au `gh` factice pour la release, aucun avis, aucun cache écrit | Automatisé |
| A13 | Manifeste ancien à jour | Manifeste sans tag, au SHA que vise le tag de la release | `git sdlc status` | Aucun avis pour le kit | Automatisé |
| A14 | Manifeste ancien en retard | Manifeste sans tag, à un SHA antérieur | `git sdlc status` | Avis pour le kit, nommant la release | Automatisé |
| A15 | Tests en dépôt temporaire | Les suites de tests du besoin | `bash scripts/verify.sh` | Elles tournent dans un dépôt git temporaire avec un `gh` factice, une ligne `PASS`/`FAIL` par cas | Automatisé |
| A16 | Délai de la requête | Un `gh` factice qui répond après 3 secondes, `sdlc.updateCheckTimeout` à `1` dans `.sdlc/config` | `git sdlc status` | Avis « vérification impossible (délai dépassé) », commande terminée en moins de 3 secondes, code inchangé | Automatisé |

## Points d’attention

<!-- Contradictions, risques et arbitrages à trancher avant le build, chacun avec le décideur attendu. « Aucun » s’il n’y en a pas. -->

- Première release : l'intent la veut publiée avant le build, alors que le workflow de C5 naît du build. Accepté le 2026-11-06 par le product owner : elle sert de référence sans fichier joint, les manifestes installés depuis elle sont comparés par SHA (C12), et A1 se joue à la première release après le build.
- Déclencheur : l'intent dit « déclenché par le tag » ; le product owner a retenu le 2026-11-06 la publication de la release (C5), créée avec son tag par `git sdlc release`. L'effet est le même pour l'utilisateur, et la release existe toujours quand le fichier est joint. L'intent n'est pas modifié par cette PR.
- Arbitrés le 2026-11-06 par le product owner :
  - manifeste sans tag, SHA différent = en retard (C12, L7), sans requête de plus ;
  - la ligne `tag` rend le manifeste illisible pour un `deploy.sh` antérieur : accepté, puisqu'on met à jour depuis un clone plus récent ;
  - échec mis en cache pour la journée (C18) ;
  - avis affiché avant la sortie de la commande (C10) ;
  - `git sdlc version` et `--version` (C4) ;
  - format de l'avis (Contrats), que `2026-11-05-sdlc-self-update` pourra changer pour citer `git sdlc update` ;
  - délai réglable par `sdlc.updateCheckTimeout`, 5 secondes par défaut (C20) ;
  - `contents: write` sur le seul job du workflow qui joint le fichier (C6) ;
  - tests : une nouvelle suite sous `bin/tests/<nom>/` avec un `gh` factice, et des cas ajoutés à `scripts/tests/deploy/`.
- Délai (C20) : macOS n'a pas de commande `timeout`, et les scripts tournent en bash 3.2. La façon d'abandonner la requête est à choisir au plan. Décideur : tech lead.
- Aucun skill de standards dans `.claude/skills/` ne couvre la sécurité d'un workflow GitHub Actions ni le format des sorties en ligne de commande.

## Hors périmètre

<!-- Ce que la spec ne couvre volontairement pas. -->

- Commande qui applique la mise à jour : besoin `2026-11-05-sdlc-self-update`.
- Mise à jour automatique.
- Signal à l'ouverture d'une session Claude Code (hook `SessionStart`).
- Retour à une version antérieure.
- Suivi de `main` du kit plutôt que de ses releases.
- Vérification d'empreinte ou de signature du fichier joint.

## Questions ouvertes

<!-- Questions de l’intent non tranchées, et informations manquantes. Peut rester vide. -->

- Aucune : le délai de la requête GitHub (« ne ralentit pas sensiblement ») est fixé par C20.
