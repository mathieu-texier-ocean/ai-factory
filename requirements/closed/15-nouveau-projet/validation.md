# Recette — Lot 15 : Déployer ai-factory dans un nouveau projet

- **Date :** 2026-10-20
- **Exécution :** branche `feat/lot-15-nouveau-projet` (commit df74742), depuis la racine du dépôt.

## Tests automatisés

| Cas | Action | Résultat observé | Réf. |
|---|---|---|---|
| 39 cas du script | `bash scripts/tests/ai-factory/run.sh` | 39 `PASS` (dont A1, cible illisible jouée hors root), code 0 | C1–C40, L1–L21, A1–A7 |
| Commits du lot | commits des étapes 1 à 4 avec `core.hooksPath hooks` | acceptés : aucune fixture ne déclenche le contrôle des sections de l'intent | plan, étape 4 |
| Ensemble du dépôt | `bash scripts/verifier.sh` | `5 run.sh lancés, 0 en échec` | C33 |

### Tests capables d'échouer

Mutations de `scripts/ai-factory.sh`, dans une copie jetable du dépôt :

| Mutation | Cas passés en `FAIL` |
|---|---|
| délégation retirée (`if false`) | liste blanche étendue (C38, L18), source sans script (C38) |
| source non ramenée à la racine (`cd <dossier> && pwd`) | 24 cas, dont le sous-dossier du clone (C37, L17) |
| `chmod +x` de l'alignement des droits retiré | droits (C39, L19) |
| remplacement de `scripts/ai-factory.sh` non différé | aucun : voir « Points à signaler » |

## Essai réel

Dans un dossier jetable, sur un `git clone` local d'ai-factory au commit a9fd42a :

| Étape | Commande | Observé |
|---|---|---|
| Création | `clone/scripts/ai-factory.sh create projet demo` | code 0 ; marche à suivre affichée ; le projet a `.ai-factory`, `.claude`, `.gitignore`, `CLAUDE.md`, `README.md`, `hooks`, `scripts`, `templates`, et ni `requirements/` ni `documents/` |
| Marche à suivre | `git init`, `git config core.hooksPath hooks`, `bash scripts/verifier.sh` | `5 run.sh lancés, 0 en échec` ; le `run.sh` copié saute A1 (R4) |
| Modification locale | une ligne ajoutée à `CLAUDE.md` du projet | — |
| Évolution d'ai-factory | commit factice dans le clone : une convention de `templates/projet/CLAUDE.md` reformulée, une ligne ajoutée à `hooks/pre-commit` | — |
| Mise à jour | `scripts/ai-factory.sh update ../clone` | code 0 ; rapport : ancien et nouveau SHA, `hooks/pre-commit` remplacé, `CLAUDE.md.nouveau` écrit ; `CLAUDE.md` garde la ligne locale ; le `diff` avec `.nouveau` ne montre que la convention reformulée et la ligne locale ; `git status` ne liste pas le `.nouveau` |
| Relance par un sous-dossier | `scripts/ai-factory.sh update ../clone/scripts` | « Déjà à jour », rien n'est modifié |

### Essai réel sur macOS (projet `activation-en-masse`)

Création puis mise à jour depuis le clone d'ai-factory, avec le `chmod` et le `sed` BSD :

| Constat | Correction |
|---|---|
| `create` échoue : `chmod: --: No such file or directory` (le `chmod` BSD lit `-x` comme le mode) | `chmod -- a+x` et `chmod -- a-x` (e18a99f) |
| Tests : `sha256sum -c`, `xargs sha256sum` et `sed -i` absents ou différents sous macOS | `shasum -a 256`, `sed -i.bak` (e18a99f) |
| `update <projet>` (le projet lui-même comme source) : message trompeur, et manifeste non suivi par Git non reconnu | message explicite ; le dossier de travail fait foi (ee031dc, a636684) |
| Commandes `creer` et `mettre-a-jour` | renommées `create` et `update` ; `mettre-a-jour` reste accepté pour la délégation des projets déjà créés (df74742) |

Après correction : `bash scripts/verifier.sh` donne `5 run.sh lancés, 0 en échec`, et `update` depuis `~/workspace/ai-factory` aboutit sur `activation-en-masse`.

## Points à signaler en revue

- **C32 sans effet observable.** Avec la délégation (C38), le script en cours d'exécution est une copie temporaire. Et toute écriture passe par un fichier `.tmp` puis `mv`. Remplacer `scripts/ai-factory.sh` en dernier ne change donc plus rien de visible : la mutation correspondante n'est détectée par aucun test. Le remplacement en dernier est conservé comme le prévoit le plan.
- **P5 plus pessimiste que le comportement.** Après une mise à jour interrompue, la relance ne produit pas de `.nouveau` superflu pour un fichier déjà remplacé : il vérifie L = N (C25), donc seul le manifeste est mis à jour. Un `.nouveau` superflu n'apparaît que si ai-factory a encore changé ce fichier entre-temps. Le cas L13 vérifie l'absence de perte.
- **Refus d'une cible fichier (C40).** Sans le contrôle « n'est pas un dossier », la cible serait quand même refusée comme non vide, avec un message moins clair. Le test vérifie le code de retour, pas le message.
- **C2, liste des outils.** Le script utilise aussi `dirname` et `sort`, absents de la liste de C2. `find` et `sed`, qui y figurent, ne sont pas utilisés par le script, seulement par les tests. Ce sont tous des outils standards.
- **`CLAUDE.md` à 60 lignes**, la limite du lot 1e (C6). `scripts/ai-factory.sh` et `templates/projet/` ont été ajoutés dans la ligne `templates/` existante, pas en lignes séparées.
- **Spec et plan modifiés après validation** (e264e26, corrections issues de la revue) : le statut reste `validé`, la modification est à confirmer par le tech lead.
