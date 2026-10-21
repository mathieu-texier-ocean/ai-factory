# Plan : Lot 4b : Étape Plan, refus d'un plan sans amont validé

<!-- Un lot = un plan = une PR ; une étape = un commit. Le plan est accepté avant tout code. S'il est modifié une fois validé, il repasse en draft. -->

- **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu Texier · **Statut :** draft
- **À risque :** non
- **Validation :** développeur
- **Base :** `feat/lot-4a-plan` à `9d10950`

## Prérequis

- Amont : pas de spec dans le dossier ; l'intent est `validé` et commité.
- Une seule PR pour le lot.
- Base de départ : `feat/lot-4a-plan` à `9d10950`.
- Dépend du lot 3 (contrôle de la spec dans `hooks/pre-commit`, tests `hooks/tests/hook-spec/`) et du lot 4a (`templates/plan.md`, skill de production du plan).

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `hooks/pre-commit` | modifié | 1, 2 |
| `hooks/tests/hook-plan/run.sh` | nouveau | 1, 2 |
| `hooks/tests/hook-plan/fixtures/` (intents et specs `draft` / `validé`, plan modèle) | nouveau | 1, 2 |
| `README.md` | modifié | 3 |
| `CLAUDE.md` (ligne `hooks/pre-commit` de l'architecture) | modifié | 3 |

## Étapes

### 1. Ajoute le contrôle « plan à côté d'un amont validé » à la création

Dans `hooks/pre-commit`, nouvelle fonction propre au plan, sans toucher `check_spec_intent` : pour chaque `plan.md` ajouté (`--diff-filter=A`), hors `templates/` à la racine :

- `<dossier>/intent.md` absent de l'index et de `HEAD` : refus, message « intent absent (<chemin>) » ;
- `<dossier>/spec.md` présente (index si elle fait partie du commit, sinon `HEAD`) : elle seule décide ; statut autre que `validé` : refus avec le statut trouvé ;
- sans spec : l'intent décide (index s'il fait partie du commit, sinon `HEAD`) ; statut autre que `validé` : refus avec le statut trouvé.

Même motif de statut que le lot 3 (première occurrence de `**Statut :** <valeur>`, seul `validé` exact). Tests `hooks/tests/hook-plan/run.sh` sur le modèle de `hooks/tests/hook-spec/run.sh` : critères d'acceptation 1 à 5 de l'intent.

Couvre : critères d'acceptation 1, 2, 3, 4, 5 de l'intent (pas de spec, donc pas de numéros C, L, A).

### 2. Étend le contrôle au renommage et exclut les modèles et fixtures

S'appuie sur l'étape 1. Les `plan.md` arrivant par `git mv` (`-M --diff-filter=R`, chemin de destination) passent par le même contrôle. Exclusions : `templates/` à la racine et `tests/<nom>/fixtures/` à toute profondeur, comme le contrôle credential. Tests ajoutés à `hooks/tests/hook-plan/run.sh` : `git mv` vers un dossier non validé refusé, `templates/plan.md` et un `plan.md` de fixture acceptés sans intent.

Couvre : critères d'acceptation 6 et 7 de l'intent.

### 3. Documente le contrôle du plan

S'appuie sur l'étape 2. Commentaire d'en-tête de `hooks/pre-commit` (quatre contrôles), `README.md` (table des livrables, liste des tests, prérequis de l'étape Plan) et ligne `hooks/pre-commit` de `CLAUDE.md`. Lancer `bash scripts/verifier.sh` et coller sa sortie.

Couvre : critère d'acceptation 8 de l'intent (vérification finale de non-régression).

## Tests à écrire

- Automatisés : `hooks/tests/hook-plan/run.sh` (dépôt git temporaire, fixtures dans `hooks/tests/hook-plan/fixtures/`), un cas par critère d'acceptation 1 à 7 de l'intent. Commande : `bash hooks/tests/hook-plan/run.sh`.
- Non-régression : `bash hooks/tests/hook-spec/run.sh` inchangé et au vert, ainsi que `hook-intent` et `hook-credential` ; ensemble : `bash scripts/verifier.sh` depuis la racine (critère 8).

## Couverture de la spec

Sans objet.

## Risques

- **Ce que le changement peut casser** (réponse du développeur) : le contrôle de la spec du lot 3 ne doit pas changer de comportement. Parade : fonction distincte pour le plan, `check_spec_intent` et sa boucle non modifiés, `hooks/tests/hook-spec/run.sh` non modifié et relancé à chaque étape.
- **Étape la plus risquée** (réponse du développeur) : la modification de `hooks/pre-commit` (étapes 1 et 2). Parade : tests `hook-plan` écrits dans le même commit que chaque changement du hook, `bash scripts/verifier.sh` avant chaque commit.
- **Questions restées sans réponse** (questions ouvertes de l'intent, non tranchées en séance) :
  - Statut absent de la spec ou de l'intent : message à afficher (point R2 du plan du lot 3).
  - Aligner le lot 3 sur la règle « intent lu dans le commit en cours, sinon `HEAD` » ? À trancher par le tech lead. Ce plan ne le fait pas : la réponse du développeur exclut tout changement de comportement du contrôle de la spec.
- **Options écartées** (réponse du développeur) : un hook séparé pour le plan, écarté pour garder un seul `pre-commit`.

## Hors périmètre

- Template et skill de production du plan (lot 4a).
- Contrôle du contenu ou de la taille du plan.
- Contrôle des modifications d'un plan existant.
- Alignement du contrôle de la spec (lot 3) sur la lecture de l'intent dans le commit en cours.
