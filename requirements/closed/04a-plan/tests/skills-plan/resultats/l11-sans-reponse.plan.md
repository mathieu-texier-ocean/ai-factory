# Plan : Lot 4b — Étape Plan, refus d'un plan sans amont validé

<!-- Un lot = un plan = une PR ; une étape = un commit. Le plan est accepté avant tout code. S'il est modifié une fois validé, il repasse en draft. -->

- **Intent :** [intent.md](intent.md)
- **Auteur :** <à renseigner : non communiqué pendant la séance> · **Statut :** draft
- **À risque :** non
- **Validation :** développeur
- **Base :** `feat/lot-4a-plan`, commit `9d10950` (constaté pendant la séance, à confirmer par le développeur)

## Prérequis

- Amont : pas de spec ; l'intent (`intent.md`) est `validé` et c'est lui qui fait foi. Il n'est pas encore commité : le stager avec le plan, le hook `pre-commit` lit l'index ou `HEAD`, pas l'arbre de travail.
- Une seule PR pour le lot.
- Dépend du lot 3 (contrôle « intent validé avant la spec » dans `hooks/pre-commit`, tests `hooks/tests/hook-spec/`) et du lot 4a (skill de production du plan).

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `hooks/pre-commit` | modifié | 1, 2 |
| `hooks/tests/hook-plan/run.sh` | nouveau | 2 |
| `hooks/tests/hook-plan/fixtures/` (intents et specs `draft` / `validé`, plan modèle) | nouveau | 2 |
| `README.md` | modifié | 3 |
| `CLAUDE.md` | modifié | 3 |

## Étapes

### 1. Isoler la lecture du statut dans `hooks/pre-commit`, sans changer le contrôle de la spec

Extraire en une fonction la lecture de la première occurrence de `**Statut :** <valeur>` (ligne seule ou ligne de l'auteur), et la faire appeler par `check_spec_intent`, qui continue de lire l'intent dans `HEAD` seulement. Aucun changement de comportement : `hooks/tests/hook-spec/run.sh` reste au vert sans modification.

Couvre : sans objet (pas de spec) ; critère d'acceptation de l'intent « les tests des contrôles existants (intent, spec) restent au vert ».

### 2. Ajouter le contrôle du plan et ses tests

Dans `hooks/pre-commit`, pour chaque `plan.md` ajouté ou arrivé par renommage dans le commit (`git diff --cached -M --diff-filter=AR`), hors `templates/` à la racine et hors `tests/<nom>/fixtures/` à toute profondeur :

- `<dossier du plan>/intent.md` absent du commit en cours et de `HEAD` : refus, message avec l'intent attendu ;
- `spec.md` présente dans le dossier (commit en cours, sinon `HEAD`) : elle seule décide ; statut autre que `validé` : refus, message avec la spec et le statut trouvé ;
- sans spec : statut de l'intent (commit en cours, sinon `HEAD`) autre que `validé` : refus, message avec l'intent et le statut trouvé.

Mettre à jour le commentaire d'en-tête du hook. Écrire `hooks/tests/hook-plan/run.sh` et ses fixtures sur le modèle de `hooks/tests/hook-spec/run.sh`.

Couvre : sans objet (pas de spec) ; critères d'acceptation 1 à 7 de l'intent.

### 3. Documenter le contrôle

Ajouter le refus d'un nouveau `plan.md` sans amont validé à la ligne `hooks/pre-commit` de `README.md` et de `CLAUDE.md` (section Architecture).

Couvre : sans objet (pas de spec).

## Tests à écrire

- Automatisés, `hooks/tests/hook-plan/run.sh`, un cas par critère d'acceptation de l'intent :
  - plan dans un dossier sans `intent.md`, avec une `spec.md` validée : refusé ;
  - spec `draft` : plan refusé ; spec `validé` : plan accepté ;
  - spec et plan créés dans le même commit, intent validé : refusé si la spec est `draft`, accepté si elle est `validé` ;
  - sans spec, intent et plan créés dans le même commit : refusé si l'intent est `draft`, accepté s'il est `validé` ;
  - sans spec, intent commité : refusé s'il n'est pas validé, accepté s'il l'est ;
  - `git mv` d'un plan vers un dossier dont l'amont n'est pas validé : refusé ;
  - `templates/plan.md` et un `plan.md` sous `tests/<nom>/fixtures/` : acceptés sans intent.
- Non-régression : `hooks/tests/hook-spec/run.sh`, `hooks/tests/hook-intent/run.sh`, `hooks/tests/hook-credential/run.sh` inchangés et au vert.
- Commande, depuis la racine : `bash scripts/verifier.sh`, à chaque étape.

## Couverture de la spec

Sans objet.

## Risques

- **Ce que le changement peut casser** (développeur) : le contrôle de la spec du lot 3 ne doit pas changer de comportement. Parade : étape 1 sans changement de comportement, `hooks/tests/hook-spec/run.sh` lancé sans modification à chaque étape ; `check_spec_intent` continue de lire l'intent dans `HEAD` seulement.
- **Étape la plus risquée** (développeur) : la modification de `hooks/pre-commit` (étapes 1 et 2). Parade : `bash scripts/verifier.sh` vert avant chaque commit.
- **Options écartées : question posée, restée sans réponse.**
- Questions ouvertes de l'intent, non tranchées par ce plan :
  - statut absent de la spec ou de l'intent : message à afficher (point R2 du plan du lot 3) ;
  - aligner le contrôle de la spec (lot 3), qui lit l'intent dans `HEAD` seulement, sur la règle du plan (commit en cours, sinon `HEAD`) : à trancher par le tech lead. Le plan ne le fait pas, conformément à la réponse sur ce que le changement peut casser.

## Hors périmètre

- Template et skill de production du plan (lot 4a).
- Contrôle du contenu ou de la taille du plan.
- Contrôle des modifications d'un plan existant.
- Changement du comportement du contrôle de la spec (lot 3).
