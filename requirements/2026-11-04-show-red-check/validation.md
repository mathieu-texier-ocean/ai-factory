# Recette : 2026-11-04-show-red-check

<!--
  Fiche de recette de la PR build : un critère d'acceptation de la spec par ligne, avec sa
  preuve. Le recetteur remplit les constats ; la recette se refait après toute modification
  de la branche, sur le nouveau commit. Pas de champ « Statut » : la case « Recette validée »
  de la PR et sa fusion font foi.
-->

- Spec : [spec.md](spec.md) · Plan : [plan.md](plan.md)
- Branche : `need/2026-11-04-show-red-check/build`
- Commit recetté : `f23e5ab` (à remplacer à chaque nouvelle recette)
- Recetteur : <à désigner>

## Critères automatisés

Commande, depuis la racine du dépôt (jq requis) :

```bash
bash bin/tests/git-sdlc-checks/run.sh   # une ligne PASS/FAIL par cas
bash scripts/verify.sh                  # tous les run.sh du dépôt
```

Constat du 2026-11-05, au commit `f23e5ab` : 35 cas PASS, 0 FAIL ; `verify.sh` : 7 run.sh lancés, 0 en échec.

Le banc rejoue des réponses de GitHub avec un faux `gh` qui applique `--jq` avec `jq`. Le vrai `gh` utilise son propre moteur jq : les critères marqués `Manuel` dans la spec se rejouent aussi contre GitHub (section suivante).

| Critère | Cas de `bin/tests/git-sdlc-checks/run.sh` |
|---|---|
| A1 Un check rouge détaillé | check Actions : raison = 1re annotation failure ; status rouges : détail juste sous « checks rouges » (C1) |
| A2 Plusieurs checks rouges | une ligne par check rouge ; checks verts et en cours non détaillés (L1) |
| A3 Sortie inchangée sans check rouge | status verts, en-cours, aucun : sortie identique à la référence ; ni gh pr checks ni gh api (C5) |
| A4 Détail au refus de `merge` | merge rouges : code 1 ; message actuel en tête ; détail sur la sortie d'erreur ; gh pr merge jamais appelé |
| A5 `--porcelain` inchangé | status --porcelain : sortie identique à la référence ; ni gh pr checks ni gh api |
| A6 Check run couvert | check run avec titre : raison = titre |
| A7 Statut de commit couvert | statut de commit : description sur une ligne (L5) |
| A8 Raison illisible | raison illisible : ligne sans raison (L6, C8) ; status rouges : code 0 |
| A9 Raison d'un check Actions | check Actions : raison = 1re annotation failure (L9) |

Les références `fixtures/attendu-*.txt` de A3 et A5 viennent de la version de `main` d'avant ce besoin.

Autres cas du banc, sans critère A dédié :
- L2, L4 : check sans lien ni raison.
- L3 : lien d'un CI externe, sans appel à l'API des check runs.
- L7 : PR en brouillon.
- L8 : board sans détail ni appel de plus.
- `checkReasonMax` : défaut 120, valeurs 20 et 0, valeur invalide signalée seulement quand un détail s'affiche.
- Raison sans caractère de contrôle, antislash intact.
- `gh` sans `pr checks --json` : signalé, `status` en code 0.

## Critères manuels

Ces essais demandent un jeton `gh` qui lit les PR et les check runs d'ai-factory. Le PAT du devcontainer ne lit pas les PR : ils se font côté hôte.

### Préparation

1. Depuis un clone d'ai-factory, sur une branche jetable `need/recette-checks/intent` hors de tout besoin réel, créer un commit sans trailer `Need:` (`git commit --no-verify --allow-empty -m recette`, le hook `commit-msg` le refuserait).
2. Pousser et ouvrir une PR brouillon vers `main` : le check `sdlc-conventions` échoue avec `::error::`.
3. Utiliser la version recettée : `bin/git-sdlc` de la branche build, appelé par son chemin, par exemple `alias sdlc=$PWD/bin/git-sdlc`.
4. Après la recette, fermer la PR et supprimer la branche.

### A1, A9 Détail dans `status` sur une vraie PR

1. `sdlc status recette-checks`.
2. Attendu : sous `checks       rouges`, la ligne `sdlc-conventions  FAILURE  <message de la première erreur>  <lien du job>`.
3. Ouvrir le lien : il mène au job en échec, et le message est celui de la première annotation.

| Date | Commit | Ligne affichée | Constat |
|---|---|---|---|
| | | | |

### A4 Détail au refus de `merge`

1. `sdlc merge --ready recette-checks intent` (la PR reste rouge, le refus intervient avant toute action).
2. Attendu : `git-sdlc : PR #<n> : checks rouges`, puis la même ligne de détail, sur la sortie d'erreur. Code 1, PR toujours ouverte et toujours en brouillon.

| Date | Commit | Sortie d'erreur | Code | Constat |
|---|---|---|---|---|
| | | | | |

### A3, A5 Sorties inchangées

1. Sur une PR de besoin aux checks verts, comparer `git sdlc status <id>` (version de `main`) et `sdlc status <id>` (version recettée).
2. Comparer `git sdlc status recette-checks --porcelain` et `sdlc status recette-checks --porcelain`.
3. Attendu : sorties identiques.

| Date | Commit | Comparaison | Constat |
|---|---|---|---|
| | | | |

### `checkReasonMax`

1. `git config sdlc.checkReasonMax 10`, puis `sdlc status recette-checks`.
2. Attendu : la raison est coupée à 10 caractères, `…` compris.
3. `git config --unset sdlc.checkReasonMax`.

| Date | Commit | Constat |
|---|---|---|
| | | |

## Écarts connus, à signaler dans la PR

- **Tests automatisés.** La spec marque A1 à A8 `Manuel` ; le développeur a retenu un faux `gh` au build (décision du 2026-11-05), ils sont donc aussi automatisés. Les essais manuels ci-dessus restent la preuve contre GitHub.
- **Longueur de la raison.** Fixée par la clé `checkReasonMax` de `.sdlc/config` (120 par défaut), question reportée au build par l'intent.
- **`gh` trop ancien.** Sans `gh pr checks --json`, `status` et `merge` le signalent et affichent le résumé sans détail. La spec ne prévoyait pas ce cas.
- **`board`.** Sa sortie passe par `column`, qui échappe les caractères non ASCII sous une locale POSIX ; le banc vérifie l'absence de détail et d'appel GitHub, sans référence figée.
