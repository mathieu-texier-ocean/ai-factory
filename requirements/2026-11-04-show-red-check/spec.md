# Spec : 2026-11-04-show-red-check

<!--
  Gabarit copié par `git sdlc claim 2026-11-04-show-red-check spec`, puis rempli par le skill
  generation-spec, sur la branche need/2026-11-04-show-red-check/spec, une fois intent.md fusionné sur main.
  Le product owner relit la PR et la fusionne : pas de champ « Statut », l’étape se
  déduit de git (`git sdlc status 2026-11-04-show-red-check`).
  Numéros C, L et A stables : une révision ajoute un nouveau numéro, elle ne renumérote
  jamais. Le plan et la recette s’y réfèrent.
-->

- Intent : [intent.md](intent.md)
- Auteur : Mathieu Texier

## Périmètre

<!-- Ce que la spec couvre, en un paragraphe. -->

Le détail des checks rouges d'une PR ouverte d'un besoin, dans la sortie humaine de `git sdlc status` et dans le refus de `git sdlc merge` pour checks rouges : une ligne par check rouge, avec son nom, sa conclusion, la raison de l'échec donnée par GitHub et son lien. Le résumé actuel (`verts`, `rouges`, `en cours`, `aucun`), `status --porcelain` et `board` ne changent pas.

## Comportements

<!-- Règles numérotées C1, C2… groupées par résultat attendu de l’intent. Chaque résultat a au moins un comportement. -->

### `git sdlc status` : une ligne par check en échec

- **C1.** Quand le résumé des checks d'une PR ouverte vaut `rouges`, la ligne `checks       rouges` des preuves est suivie d'une ligne par check rouge, indentée sous elle, dans l'ordre où GitHub renvoie les checks.
- **C2.** Un check est rouge quand sa conclusion, ou son état pour un statut de commit, fait partie de l'ensemble qui donne déjà le résumé `rouges` : `FAILURE`, `ERROR`, `CANCELLED`, `TIMED_OUT`, `ACTION_REQUIRED`, `STARTUP_FAILURE`. Les checks verts ou en cours ne sont pas détaillés.
- **C3.** Une ligne de détail donne, dans cet ordre : le nom du check (nom du check run, ou contexte du statut de commit), sa conclusion telle que GitHub la renvoie, la raison (C4) et le lien vers le détail (URL du check run ou du statut de commit).
- **C4.** La raison est, pour un check run (GitHub Actions), le titre de sa sortie, ou son résumé s'il n'a pas de titre ; pour un statut de commit, sa description. Elle est ramenée à une seule ligne : les retours à la ligne deviennent des espaces.
- **C5.** Quand aucun check n'est rouge, la sortie de `status` est identique à celle d'avant ce besoin, et `status` ne fait aucun appel GitHub de plus.
- **C6.** La sortie de `status --porcelain` est inchangée.

### `git sdlc merge` : le même détail au refus

- **C7.** Quand `git sdlc merge` refuse la fusion pour checks rouges, il affiche le message actuel (`PR #<n> : checks rouges`), puis les lignes de détail de C1 à C4 sur la sortie d'erreur. Le code de retour reste celui d'aujourd'hui, et aucune fusion n'a lieu.

### Raison illisible

- **C8.** Quand la raison d'un check rouge ne peut pas être lue (droits insuffisants, API indisponible, sortie vide), la ligne du check s'affiche avec son nom, sa conclusion et son lien, sans raison. La commande se poursuit et garde le code de retour qu'elle aurait eu sans ce détail.

### Raison d'un check GitHub Actions

- **C9.** Un check run sans titre ni résumé de sortie prend pour raison le message de sa première annotation de niveau `failure`. Sans une telle annotation, C8 s'applique.

## Cas limites

<!-- Situations aux bords et comportement attendu, en citant la règle C concernée. -->

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Checks rouges et checks en cours sur la même PR | Résumé `rouges` ; seuls les checks rouges sont détaillés (C1, C2). |
| L2 | Check run sans titre ni résumé de sortie | Ligne sans raison (C8). |
| L3 | Statut de commit sans description | Ligne sans raison (C8). |
| L4 | Check sans lien de détail | Ligne sans lien ; les autres champs restent affichés (C3). |
| L5 | Raison sur plusieurs lignes | Ramenée à une ligne (C4). |
| L6 | Jeton sans accès aux check runs, ou API GitHub indisponible pendant la lecture des raisons | Lignes sans raison, `status` se termine normalement (C8). |
| L7 | PR encore en brouillon avec des checks rouges | Le détail s'affiche aussi : les preuves de `status` couvrent toute PR ouverte (C1). |
| L8 | `git sdlc board` sur un besoin dont la PR a des checks rouges | Sortie inchangée (hors périmètre). |
| L9 | Job GitHub Actions en échec : titre et résumé de sortie vides, une annotation `::error::<message>` | La raison affichée est `<message>` (C9). |

## Contrats

<!-- Entrées, sorties, codes de retour et formats échangés (API, CLI, fichiers). « Sans objet » si rien n’est exposé. -->

- Entrées : inchangées (`git sdlc status [<id>] [--porcelain] [--no-fetch]`, `git sdlc merge [--ready] [<id> [<étape>]]`).
- `status`, sortie standard : sous la ligne `checks       rouges`, une ligne par check rouge, champs séparés par deux espaces, champ absent omis :

  ```
  Preuves
    PR           #42  https://github.com/<org>/<dépôt>/pull/42
    checks       rouges
      sdlc-conventions  FAILURE  <raison>  <lien>
      <statut>          ERROR    <lien>
  ```

- `merge`, sortie d'erreur : `git-sdlc : PR #<n> : checks rouges`, puis les mêmes lignes de détail ; code de retour inchangé (1).
- `status --porcelain` et `board` : format inchangé.
- GitHub : lecture seule via `gh`, check runs et statuts de commit de la PR.

## Critères d’acceptation

<!-- Une ligne = un scénario, lu par la recette. Chaque critère de succès de l’intent a au moins une ligne. Type : Automatisé | Manuel | Humain. -->

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Un check rouge détaillé | Une PR ouverte de besoin dont un check run est en échec | `git sdlc status <id>` | Sous `checks       rouges`, une ligne avec le nom du check, `FAILURE`, sa raison et son lien | Manuel |
| A2 | Plusieurs checks rouges | Une PR ouverte dont deux checks sont en échec | `git sdlc status <id>` | Deux lignes de détail, une par check rouge | Manuel |
| A3 | Sortie inchangée sans check rouge | Trois PR ouvertes : checks tous verts, en cours, absents | `git sdlc status <id>` avant et après le changement | Sorties identiques pour chacune | Manuel |
| A4 | Détail au refus de `merge` | Une PR ouverte avec un check rouge | `git sdlc merge <id> <étape>` | Message `checks rouges`, puis la ligne de détail sur la sortie d'erreur ; code 1, aucune fusion | Manuel |
| A5 | `--porcelain` inchangé | Une PR ouverte avec un check rouge | `git sdlc status <id> --porcelain` avant et après le changement | Sorties identiques | Manuel |
| A6 | Check run couvert | Un check run GitHub Actions en échec, avec un titre de sortie | `git sdlc status <id>` | La raison affichée est ce titre | Manuel |
| A7 | Statut de commit couvert | Un statut de commit en `failure` ou `error`, avec une description | `git sdlc status <id>` | La ligne donne le contexte, l'état, la description et le lien | Manuel |
| A8 | Raison illisible | Un check rouge dont la raison ne peut pas être lue (jeton sans accès aux check runs) | `git sdlc status <id>` | La ligne s'affiche sans raison ; code de retour 0 | Manuel |
| A9 | Raison d'un check Actions | Une PR dont le check `sdlc-conventions` échoue avec `::error::<message>` | `git sdlc status <id>` | La ligne du check affiche `<message>` comme raison | Automatisé |

## Points d’attention

<!-- Contradictions, risques et arbitrages à trancher avant le build, chacun avec le décideur attendu. « Aucun » s’il n’y en a pas. -->

- Format de ligne (ordre des champs, séparateur de deux espaces, indentation) : proposé par cette spec, pas par l'intent. À valider par le product owner.
- `bin/git-sdlc` n'a pas de test automatisé : tous les critères sont `Manuel`, à jouer contre un dépôt GitHub. Ajouter un faux `gh` pour les automatiser est à arbitrer par le tech lead.
- La raison d'un check run (titre ou résumé de sa sortie) n'est pas dans le résumé des checks de la liste des PR : il faut une lecture GitHub de plus, seulement quand un check est rouge (C5). Un jeton sans accès aux check runs donne C8. Risque à confirmer par le tech lead au build.
- Aucun skill de standards dans `.claude/skills/` ne couvre le format des sorties en ligne de commande.
- Révision du 2026-11-05 (C9, L9, A9) : un sondage de GitHub (dépôt `cli/cli` et check `sdlc-conventions`) montre qu'un job GitHub Actions en échec a un titre et un résumé de sortie vides ; la raison est dans ses annotations (`::error::`). Sans C9, C4 afficherait toujours un check Actions sans raison. La lecture des annotations est un appel GitHub de plus, seulement pour un check rouge (C5 tenu).
- Faux `gh` : retenu par le développeur le 2026-11-05 pour automatiser les tests au build.

## Hors périmètre

<!-- Ce que la spec ne couvre volontairement pas. -->

- `git sdlc board`.
- Le détail des checks verts ou en cours.
- La relance ou la correction des checks.

## Questions ouvertes

<!-- Questions de l’intent non tranchées, et informations manquantes. Peut rester vide. -->

- Longueur maximale de la raison affichée (tronquer le résumé ?) : reportée au build par l'intent, à fixer avec les premiers essais.
