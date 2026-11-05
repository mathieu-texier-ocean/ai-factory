# Recette : 2026-11-04-add-measure

<!--
  Fiche de recette de la PR build : un critère d'acceptation de la spec par ligne, avec sa
  preuve. Le recetteur remplit les constats ; la recette se refait après toute modification
  de la branche, sur le nouveau commit. Pas de champ « Statut » : la case « Recette validée »
  de la PR et sa fusion font foi.
-->

- Spec : [spec.md](spec.md) · Plan : [plan.md](plan.md)
- Branche : `need/2026-11-04-add-measure/build`
- Commit recetté : `f67356d` (à remplacer à chaque nouvelle recette)
- Recetteur : <à désigner>

## Critères automatisés

Commande, depuis la racine du dépôt (jq requis) :

```bash
bash bin/tests/metrics/run.sh     # une ligne PASS/FAIL par cas
bash scripts/verify.sh            # tous les run.sh du dépôt
```

Constat du 2026-11-05, au commit `f67356d` : 45 cas PASS, 0 FAIL ; `verify.sh` : 6 run.sh lancés, 0 en échec. Le check `sdlc-conventions` passe aussi en local sur la branche.

| Critère | Cas de `bin/tests/metrics/run.sh` |
|---|---|
| A1 Chaque indicateur par besoin et en agrégé | A1 sortie lisible : un tableau par niveau, chaque indicateur C5 à C21 |
| A2 Valeurs égales aux valeurs attendues | A2 valeurs égales à la sortie attendue (`fixtures/livre.attendu`) |
| A3 Médiane | A3 médiane impaire ; A3 médiane paire |
| A4 Besoin incomplet → « — » | A4 besoin à l'étape intent ; A4 besoin rejeté par PR avant l'intent (L2) |
| A5 Rejet par tag après l'intent | A5 rejet par tag après l'intent (L3) |
| A6 Fenêtre `--since` | A6 --since : seul le besoin récent, n = 1 |
| A7 `--since` mal formé | A7 --since mal formé ; L12 date inexistante refusée |
| A8 `--porcelain` stable | A8 deux appels successifs identiques ; A8 TSV sans en-tête ni alignement |
| A10 La commande n'écrit rien | A10 lecture seule ; A10 la requête GraphQL est une query |
| A11 Premier passage et rework | A11 deux commits après le brouillon, séparés par une revue |
| A12 CI au premier passage | A12 premier run en échec puis en succès |
| A14 Rejeté sans commit d'intent | A14 retenu par la création de sa PR ; A14 écarté si sa PR est antérieure à --since |
| A15 Run annulé ignoré | A15 run annulé ignoré (L17) |
| A16 Revues retenues | A16 revue du brouillon et réponses de l'auteur ignorées |
| A17 Fréquence des releases | A17 un tag du jour, sans --since ; A17 --since dans le futur |
| A19 Étape fusionnée deux fois | A19 étape refusionnée (C5, C9, C8) ; A19 PR intent refusionnée (lignes pr) |

Les autres cas du banc couvrent des comportements et des cas limites sans critère A dédié : C2, C4, C9 à C11, C18 à C21, C23, ainsi que L5, L6, L7, L9, L10, L13, L14, L15 et L18.

## Critères manuels et humains

Ces critères demandent un jeton `gh` qui lit les PR et l'API GraphQL d'ai-factory. Le PAT du devcontainer ne le peut pas : la commande y échoue proprement, comme le prévoit L14.

### A18 Requête acceptée par GitHub (Manuel)

Préparé le 2026-11-05 : la requête d'un lot de 50 PR, telle que la commande la produit, passe le dry-run sur le dépôt public `cli/cli`, avec 110 050 nœuds et un coût de 552. Les trois requêtes de complément (revues, commits, suites d'un commit) sont acceptées elles aussi.

Procédure sur ai-factory :

1. Lancer `git sdlc metrics` avec un gh qui journalise ses appels, ou relever la requête dans `GH_DEBUG=api git sdlc metrics`.
2. Renvoyer la requête du premier lot en remplaçant `repository(owner: $owner, name: $name)` par `rateLimit(dryRun: true) { nodeCount cost } repository(owner: "ocean-shiftmove", name: "ai-factory")`.
3. Attendu : pas d'erreur `MAX_NODE_LIMIT_EXCEEDED`, et `nodeCount` ≤ 500 000.

| Date | Commit | nodeCount | cost | Constat |
|---|---|---|---|---|
| | | | | |

### A13 Résultats sur un dépôt réel (Humain)

Procédure, depuis un clone d'ai-factory à jour :

1. `git sdlc metrics`, puis `git sdlc metrics --porcelain`.
2. Vérifier que le besoin `2026-11-04-add-measure` apparaît.
3. Comparer ses délais aux dates des PR sur GitHub :
   - délai intent : du premier commit de l'intent à la fusion de la PR intent ;
   - délai intent → spec : entre les deux fusions ;
   - durée de revue : de la sortie du brouillon à la fusion.
4. Points à contrôler en même temps, laissés ouverts au plan :
   - chaque exécution de `sdlc.yml` forme sa propre suite de checks : la CI au premier passage d'une PR doit correspondre à l'onglet Checks ;
   - les dates de release viennent de `gh release list`, et non de `gh release view` comme l'écrit la spec ;
   - un avertissement `prLimit` n'apparaît que si le dépôt a au moins 300 PR.

| Date | Commit | Indicateur comparé | Valeur de `metrics` | Valeur sur GitHub | Constat |
|---|---|---|---|---|---|
| | | | | | |

### A9 Import dans un tableur (Manuel)

Procédure :

1. `git sdlc metrics --porcelain > mesures.tsv`.
2. Ouvrir le fichier dans LibreOffice ou Excel, avec la tabulation comme séparateur.
3. Attendu : une colonne par champ, et des durées et taux reconnus comme nombres. Le séparateur décimal est le point : sous une locale française, importer en « anglais (États-Unis) » ou remplacer les points.

| Date | Tableur | Constat |
|---|---|---|
| | | |

## Écarts connus, à signaler dans la PR

- **Dates de release.** Elles sont lues par `gh release list`, en un seul appel, au lieu de `gh release view` cité par la spec (sources et A10). C'est aussi une lecture.
- **Locale.** Sous une locale POSIX, `column` échappe les caractères non ASCII de la sortie lisible, pour `board` comme pour `metrics`. Les tests de la sortie lisible prennent une locale UTF-8.
