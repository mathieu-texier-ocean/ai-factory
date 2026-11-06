# Spec : 2026-11-05-sdlc-self-update

<!--
  Gabarit copié par `git sdlc claim 2026-11-05-sdlc-self-update spec`, puis rempli par le skill
  generation-spec, sur la branche need/2026-11-05-sdlc-self-update/spec, une fois intent.md fusionné sur main.
  Le product owner relit la PR et la fusionne : pas de champ « Statut », l’étape se
  déduit de git (`git sdlc status 2026-11-05-sdlc-self-update`).
  Numéros C, L et A stables : une révision ajoute un nouveau numéro, elle ne renumérote
  jamais. Le plan et la recette s’y réfèrent.
-->

- Intent : [intent.md](intent.md)
- Auteur : Mathieu Texier

## Périmètre

<!-- Ce que la spec couvre, en un paragraphe. -->

Une commande `git sdlc update` qui, sur confirmation de l'utilisateur, met à la version de la dernière release du kit (dépôt `sdlc.kitRepo`) deux éléments : le fichier `git-sdlc` qu'elle exécute, remplacé par le fichier joint à la release, puis le kit du dépôt produit courant, mis à jour selon les règles de `scripts/deploy.sh update` sans clone du kit. Elle s'appuie sur ce que livre le besoin `2026-11-05-sdlc-update` (version portée par `git-sdlc`, fichier joint à la release, tag dans `.sdlc/manifeste`, clé `sdlc.kitRepo`) et ne crée aucun commit. La détection et l'avis d'une release plus récente restent dans ce besoin-là.

## Comportements

<!-- Règles numérotées C1, C2… groupées par résultat attendu de l’intent. Chaque résultat a au moins un comportement. -->

### Commande et confirmation

- **C1.** `git sdlc update` lit la dernière release du dépôt du kit : clé `sdlc.kitRepo` lue comme les autres réglages (`git config`, puis `.sdlc/config`), par défaut `ocean-shiftmove/ai-factory`. La release de référence est celle que GitHub désigne comme la dernière (ni brouillon, ni pré-release).
- **C2.** Avant toute question, la commande affiche, pour chaque élément, sa version actuelle et la version cible : `git-sdlc` (version portée par le script, chemin du fichier) et kit du dépôt (tag ou SHA lu dans `.sdlc/manifeste`). Un élément déjà à la version cible est annoncé « à jour » et n'est pas proposé.
- **C3.** Une question par élément proposé : `git-sdlc` d'abord, puis le kit du dépôt. Aucun fichier d'un élément n'est écrit (ni `git-sdlc`, ni fichier du dépôt, ni `.nouveau`, ni manifeste) tant que l'utilisateur n'a pas répondu oui à sa question. Toute autre réponse, ou une fin d'entrée, vaut non ; un non à `git-sdlc` n'empêche pas de proposer le kit.
- **C4.** Sans terminal interactif sur l'entrée standard, la commande n'écrit rien : elle affiche ce qu'elle aurait proposé (C2) et indique qu'une confirmation interactive est nécessaire.
- **C5.** Quand les deux éléments sont à jour, la commande l'indique, ne pose aucune question et n'écrit rien.
- **C24.** Chaque question nomme le dépôt source (`sdlc.kitRepo`) et le tag cible, et signale quand `sdlc.kitRepo` n'est pas la valeur par défaut. Aucune autre vérification du fichier téléchargé n'est faite : la confiance repose sur la lecture authentifiée par `gh` du dépôt configuré.

### Remplacement de `git-sdlc`

- **C6.** Le fichier remplacé est celui qu'exécute la commande en cours, son chemin résolu tel qu'il est dans le `PATH`. Le nouveau contenu est le fichier `git-sdlc` joint à la release cible (nom et forme fixés par `2026-11-05-sdlc-update`).
- **C7.** Le nouveau fichier est entièrement téléchargé, rendu exécutable et écrit à côté de l'ancien, puis substitué par renommage : la commande en cours n'est pas altérée, et un échec avant le renommage laisse l'ancien fichier intact.
- **C8.** Après remplacement, la version affichée par `git-sdlc` (mécanisme de `2026-11-05-sdlc-update`) vaut le tag de la release.

### Mise à jour du kit du dépôt courant

- **C9.** La mise à jour du kit porte sur le dépôt courant (racine de `git rev-parse --show-toplevel`), seulement s'il contient `.sdlc/manifeste`. Sans manifeste, la commande l'indique et ne propose que `git-sdlc`.
- **C10.** Le contenu du kit au tag cible est lu sur GitHub (lecture seule), sans clone du kit ni fichier propre au kit dans le dépôt produit.
- **C11.** Les fichiers retenus sont ceux que `deploy.sh` retiendrait au même tag : liste blanche, exclusions, dossiers `tests/` exclus, bit exécutable, `CLAUDE.md` et `README.md` produits depuis `templates/projet/` avec le nom de projet du manifeste.
- **C12.** Chaque fichier suit les règles de `deploy.sh update` : intact (empreinte du manifeste) remplacé, ou supprimé s'il a disparu du kit ; modifié localement et changé dans le kit : conservé, nouvelle version écrite en `<fichier>.nouveau` ; supprimé localement : non recréé ; nouveau fichier du kit : ajouté, ou proposé en `.nouveau` si un fichier différent occupe déjà le chemin ; droits alignés sur un fichier intact.
- **C13.** `.sdlc/manifeste` est réécrit en dernier, au format de `2026-11-05-sdlc-update` (SHA du kit au tag, tag, nom du projet, empreinte par fichier).
- **C14.** La commande affiche ensuite le même rapport par catégorie que `deploy.sh update` (remplacés, ajoutés, supprimés, droits alignés, `.nouveau` écrits, supprimés localement, sortis du manifeste).
- **C15.** Le tag cible doit descendre de la version installée (SHA ou tag du manifeste), comme `deploy.sh update` l'exige d'un clone. Sinon la commande refuse la mise à jour du kit, explique pourquoi, rappelle l'option `--force` et n'écrit rien dans le dépôt.
- **C21.** Avec `--force`, la mise à jour du kit refusée par C15 est quand même proposée : la question et un avertissement sur la sortie d'erreur disent que le tag cible ne descend pas de la version installée, ce qui peut ramener le kit en arrière. `--force` ne change rien au traitement de `git-sdlc`.

### Dossier de `git-sdlc` non inscriptible

- **C16.** Si le dossier du fichier de C6 n'est pas inscriptible, la commande ne propose pas de remplacer `git-sdlc` et n'y touche pas. Elle affiche le chemin du fichier et la commande à lancer à la main pour l'installer depuis la release (téléchargement du fichier joint vers ce chemin, puis droit d'exécution).
- **C17.** Dans ce cas, la mise à jour du kit reste proposée et s'applique si l'utilisateur la confirme (C3, C9 à C14).
- **C22.** Si le `git-sdlc` du `PATH` est un lien symbolique, la commande n'y touche pas, ni au lien ni à sa cible, comme en C16 : elle affiche le chemin du lien, sa cible et la commande manuelle, et propose quand même le kit (C17).
- **C23.** Si la version portée par `git-sdlc` est `dev` (copie du dépôt du kit), la commande ne propose pas de le remplacer : elle l'indique, et propose quand même le kit.

### Aucun commit, aucune écriture distante

- **C18.** La commande n'exécute aucune opération git qui écrit dans le dépôt produit (ni `add`, ni `commit`, ni `push`, ni modification de l'index) ; elle termine en rappelant de relire, fusionner puis supprimer les `.nouveau`, et de commiter.
- **C19.** Côté GitHub, la commande ne fait que des lectures via `gh` (release, fichier joint, contenu du kit au tag).
- **C20.** Tout ce qui doit être lu sur GitHub l'est avant la première écriture : un échec de lecture (GitHub injoignable, release ou fichier joint absent, dépôt du kit illisible) arrête la commande sans rien écrire, avec un message qui nomme ce qui manque.

## Cas limites

<!-- Situations aux bords et comportement attendu, en citant la règle C concernée. -->

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | `git-sdlc` et kit du dépôt déjà au tag de la dernière release | « à jour », aucune question, rien d'écrit (C5). |
| L2 | `git-sdlc` à jour, kit en retard (ou l'inverse) | Seul l'élément en retard est proposé (C2). |
| L3 | L'utilisateur répond non, ou ferme l'entrée (Ctrl-D) | Rien d'écrit (C3). |
| L4 | Commande lancée sans terminal (CI, tube) | Rien d'écrit, confirmation interactive demandée (C4). |
| L5 | Dépôt sans `.sdlc/manifeste` (kit non installé, ou dépôt du kit lui-même) | Seul `git-sdlc` est proposé (C9). |
| L6 | `git-sdlc` installé en `~/.local/bin`, dossier inscriptible | Fichier remplacé par renommage, version = tag (C6 à C8). |
| L7 | `git-sdlc` dans un dossier système non inscriptible (`/usr/local/bin` sans droits) | Fichier intact, chemin et commande manuelle affichés ; kit mis à jour si confirmé (C16, C17). |
| L8 | `git-sdlc` du `PATH` est un lien symbolique vers un clone du kit | Lien et cible intacts, chemin, cible et commande manuelle affichés ; kit proposé (C22). |
| L9 | `git-sdlc` installé affiche « dev » (copie du dépôt du kit) | Non proposé au remplacement, message ; kit proposé (C23). |
| L10 | Manifeste ancien, sans tag | Version installée = SHA du manifeste ; comparée et vérifiée par descendance (C2, C15) ; manifeste réécrit avec le tag (C13). |
| L11 | Manifeste à un SHA qui ne précède pas le tag cible (installé depuis une branche, ou plus récent que la release) | Kit non mis à jour, raison et `--force` affichés (C15) ; avec `--force`, proposé avec avertissement (C21). |
| L12 | Fichier du kit modifié localement et modifié dans la release | Fichier conservé, `<fichier>.nouveau` écrit (C12). |
| L13 | Un `<fichier>.nouveau` d'une mise à jour précédente existe encore | Même traitement que `deploy.sh update` au même tag (C11, C12). |
| L14 | GitHub injoignable ou dépôt du kit illisible | Arrêt avant toute écriture, message explicite (C20). |
| L15 | Release sans fichier `git-sdlc` joint | Arrêt avant toute écriture, message qui nomme le fichier manquant (C20). |
| L16 | Échec d'écriture au milieu de la mise à jour du kit (disque plein, droits) | Comme `deploy.sh update` : arrêt avec le chemin en cause ; manifeste non réécrit (C13). |
| L17 | Chemin de fichier du kit avec espace ou caractère non ASCII | Traité sans erreur (chemins lus en `-z`). |
| L18 | `git-sdlc` refusé (non), kit en retard | Le kit est quand même proposé (C3). |
| L19 | `sdlc.kitRepo` surchargé par `git config` vers un autre dépôt | Les questions nomment ce dépôt et signalent qu'il n'est pas celui par défaut (C24). |

## Contrats

<!-- Entrées, sorties, codes de retour et formats échangés (API, CLI, fichiers). « Sans objet » si rien n’est exposé. -->

- Entrée : `git sdlc update [--force]`, depuis un dépôt git. Une réponse oui/non par élément proposé, sur l'entrée standard, interactive.
- Réglages lus : `sdlc.kitRepo` (`git config`, puis `.sdlc/config`, défaut `ocean-shiftmove/ai-factory`).
- Sortie standard : versions actuelle et cible par élément (C2), question(s) de confirmation, rapport (C14), rappel final (C18). Sortie d'erreur : préfixe `git-sdlc : ` des autres commandes, pour les refus et les échecs.
- Codes de retour : `0` mise à jour faite, déjà à jour ou refusée par l'utilisateur ; `1` échec de lecture GitHub (C20), pas de terminal (C4), refus de C15 sans `--force` ou échec d'écriture ; `2` argument inconnu.
- Fichiers écrits : le fichier `git-sdlc` résolu (C6) ; dans le dépôt produit, les fichiers du kit, les `<fichier>.nouveau` et `.sdlc/manifeste`. Rien d'autre, ni sous `.git` hormis ce que fait déjà `2026-11-05-sdlc-update` (cache).
- GitHub, lecture seule via `gh` : dernière release de `sdlc.kitRepo`, son fichier `git-sdlc` joint, le contenu du kit au tag, et ce qu'il faut pour vérifier la descendance (C15).
- Format de `.sdlc/manifeste` et version de `git-sdlc` : ceux de `2026-11-05-sdlc-update`.

## Critères d’acceptation

<!-- Une ligne = un scénario, lu par la recette. Chaque critère de succès de l’intent a au moins une ligne. Type : Automatisé | Manuel | Humain. -->

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Sans confirmation, rien n'est modifié | Un dépôt produit au kit d'un tag ancien, un `git-sdlc` ancien dans un dossier inscriptible, un `gh` factice qui sert une release plus récente | `git sdlc update`, réponse « n » | `git-sdlc` et le dépôt (fichiers suivis, non suivis et `.sdlc/manifeste`) sont identiques octet pour octet à l'état de départ | Automatisé |
| A2 | Sans terminal, rien n'est modifié | Même situation que A1 | `git sdlc update < /dev/null` | Rien n'est modifié ; le message demande une confirmation interactive | Automatisé |
| A3 | `git-sdlc` à la version de la release | Même situation que A1 | `git sdlc update`, confirmation | Le fichier `git-sdlc` du `PATH` affiche la version égale au tag de la release et reste exécutable | Automatisé |
| A4 | Kit et manifeste au tag | Même situation que A1 | `git sdlc update`, confirmation | Les fichiers intacts du kit ont le contenu du tag ; `.sdlc/manifeste` porte le SHA et le tag de la release | Automatisé |
| A5 | Fichier modifié localement conservé | Un fichier du kit modifié dans le dépôt produit et modifié aussi dans la release | `git sdlc update`, confirmation | Le fichier local est inchangé ; `<fichier>.nouveau` contient la version de la release | Automatisé |
| A6 | Mêmes résultats que `deploy.sh update` | Deux copies d'un même dépôt produit (fichiers intacts, modifiés, supprimés localement, disparus du kit, nouveaux) | `git sdlc update` sur l'une, `deploy.sh update` depuis un clone du kit au même tag sur l'autre | Arbres de fichiers et manifestes identiques, hors ligne du tag si `deploy.sh` ne l'écrit pas | Automatisé |
| A7 | Dossier non inscriptible | `git-sdlc` dans un dossier sans droit d'écriture, kit du dépôt en retard | `git sdlc update`, confirmation du kit | `git-sdlc` inchangé ; la sortie donne son chemin et la commande manuelle ; le kit et le manifeste sont au tag | Automatisé |
| A8 | Dossier non inscriptible, kit refusé | Même situation que A7 | `git sdlc update`, réponse « n » | `git-sdlc` et le dépôt inchangés ; chemin et commande manuelle affichés | Automatisé |
| A9 | Aucun commit | Même situation que A1 | `git sdlc update`, confirmation | `HEAD`, l'index et les références du dépôt sont inchangés | Automatisé |
| A10 | Aucune écriture GitHub | `gh` factice qui journalise ses appels | `git sdlc update`, confirmation | Le journal ne contient que des lectures (aucun `POST`, `PATCH`, `PUT`, `DELETE`, ni commande `gh` qui écrit) | Automatisé |
| A11 | Tests en dépôt temporaire | La suite de tests de la commande | `bash scripts/verify.sh` | La suite tourne dans un dépôt git temporaire avec un `gh` factice et écrit une ligne `PASS`/`FAIL` par cas | Automatisé |
| A12 | Mise à jour réelle | Un dépôt produit réel au kit d'une release antérieure, `gh` authentifié | `git sdlc update`, confirmation | `git-sdlc` et le kit sont à la dernière release du kit ; `git status` montre les fichiers mis à jour, non commités | Manuel |
| A13 | Version installée hors lignée | Un manifeste à un SHA qui ne précède pas le tag de la release | `git sdlc update`, puis `git sdlc update --force` avec confirmation | Sans `--force` : code 1, dépôt inchangé, `--force` mentionné ; avec : avertissement, kit et manifeste au tag | Automatisé |
| A14 | Lien symbolique intact | Le `git-sdlc` du `PATH` est un lien vers un `bin/git-sdlc` d'un autre dossier, kit en retard | `git sdlc update`, confirmation du kit | Lien et cible inchangés ; chemin, cible et commande manuelle affichés ; kit au tag | Automatisé |
| A15 | Version dev non remplacée | Un `git-sdlc` qui affiche `dev`, kit en retard | `git sdlc update`, confirmation du kit | `git-sdlc` inchangé, message `dev` ; kit au tag | Automatisé |
| A16 | Une question par élément | `git-sdlc` et kit en retard | `git sdlc update`, non pour `git-sdlc`, oui pour le kit | `git-sdlc` inchangé ; kit et manifeste au tag | Automatisé |
| A17 | Dépôt source nommé | `sdlc.kitRepo` défini par `git config` vers un dépôt servi par le `gh` factice | `git sdlc update` | Chaque question nomme ce dépôt et le tag, et signale le dépôt non par défaut | Automatisé |

## Points d’attention

<!-- Contradictions, risques et arbitrages à trancher avant le build, chacun avec le décideur attendu. « Aucun » s’il n’y en a pas. -->

- Dépendance : le besoin `2026-11-05-sdlc-update` n'a ni spec ni build sur `main`. Le nom du fichier joint à la release, l'affichage de la version de `git-sdlc` et le format du tag dans le manifeste (C6, C8, C13, C23) en dépendent. Tranché le 2026-11-06 par le product owner : cette spec peut être fusionnée, le build attend la livraison de `2026-11-05-sdlc-update`.
- Contradiction avec l'intent, arbitrée : l'intent met « Retour à une version antérieure » hors périmètre, et `--force` (C21) peut ramener le kit en arrière. Le product owner l'a retenu le 2026-11-06, pour garder l'équivalent de `deploy.sh update --forcer`, en anglais pour rester cohérent avec les options de `git sdlc`. L'intent n'est pas modifié par cette PR.
- Nommage : la même option s'appelle `--forcer` dans `deploy.sh` et `--force` ici. Cette spec ne renomme pas celle de `deploy.sh`.
- Arbitrés le 2026-11-06 par le product owner : nom `git sdlc update` ; codes de retour (Contrats) ; une question par élément (C3) ; lien symbolique non touché (C22) ; version `dev` non proposée (C23) ; confiance dans `gh` et `sdlc.kitRepo`, dépôt source nommé dans les questions (C24), sans vérification d'empreinte.
- Tests : validé le 2026-11-06 par le product owner, une nouvelle suite sous `bin/tests/<nom>/` avec un `gh` factice qui sert la release, son fichier joint et le contenu du kit au tag ; A6 la compare à `deploy.sh update` sur un clone du kit au même tag.
- Aucun skill de standards dans `.claude/skills/` ne couvre la sécurité, le format des sorties en ligne de commande ni l'interaction (question, réponse par défaut).

## Hors périmètre

<!-- Ce que la spec ne couvre volontairement pas. -->

- Détection et avis d'une release plus récente, cache de la vérification, `sdlc.updateCheck` : besoin `2026-11-05-sdlc-update`.
- Mise à jour sans confirmation (option `--yes` ou équivalent), automatique ou planifiée.
- Retour à une version antérieure, sauf par `--force` pour le kit (C21) ; choix d'une release autre que la dernière ; suivi de `main` du kit.
- Installation initiale du kit dans un dépôt (`deploy.sh install`).
- Fusion des `<fichier>.nouveau`, commit et push de la mise à jour : laissés à l'utilisateur.

## Questions ouvertes

<!-- Questions de l’intent non tranchées, et informations manquantes. Peut rester vide. -->

- Partage des règles de mise à jour entre `git-sdlc` et `scripts/deploy.sh` (code commun ou réimplémentation) : reportée au plan par le product owner le 2026-11-06. L'intent la restreint sans la trancher : rien de propre au kit ne peut être lu dans le dépôt produit, donc `git-sdlc` ne peut ni sourcer ni appeler le `deploy.sh` d'un clone. A6 vérifie l'équivalence quelle que soit la réponse. Décideur : tech lead.
