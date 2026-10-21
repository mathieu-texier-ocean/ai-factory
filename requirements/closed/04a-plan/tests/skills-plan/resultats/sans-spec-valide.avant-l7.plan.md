# Plan : Lot 4b : Étape Plan, refus d'un plan sans amont validé

<!-- Un lot = un plan = une PR ; une étape = un commit. Le plan est accepté avant tout code. S'il est modifié une fois validé, il repasse en draft. -->

- **Intent :** [intent.md](intent.md)
- **Auteur :** <à renseigner par le développeur> · **Statut :** draft
- **À risque :** non
- **Validation :** développeur
- **Base :** <à confirmer par le développeur> (branche courante constatée : `feat/lot-4a-plan`, `9d10950`)

## Prérequis

- Intent du lot 4b `validé` et commité (pas de spec : l'intent fait foi).
- Une seule PR pour le lot.
- Lots dont celui-ci dépend : lot 3 (contrôle de la spec dans `hooks/pre-commit`), lot 4a (skill et template du plan).

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `hooks/pre-commit` | modifié | 1, 2 |
| `hooks/tests/hook-plan/run.sh` | nouveau | 2 |
| `hooks/tests/hook-plan/fixtures/` (intents, specs `draft` / `validé`, plan modèle) | nouveau | 2 |
| `README.md` (ligne `hooks/pre-commit` du tableau, étape Committer du plan) | modifié | 3 |
| `CLAUDE.md` (ligne Architecture de `hooks/pre-commit`) | modifié | 3 |

## Étapes

### 1. Extraire la lecture du statut dans une fonction commune, sans changer le contrôle de la spec

Isoler dans `hooks/pre-commit` la lecture « première occurrence de `**Statut :** <valeur>` » (aujourd'hui dans `check_spec_intent`) pour la réutiliser. Le contrôle de la spec garde sa source (`HEAD` seulement) et ses messages à l'identique. `hooks/tests/hook-spec/run.sh` passe sans modification.

Couvre : critère « Les tests des contrôles existants (intent, spec) restent au vert ».

### 2. Ajouter le contrôle du plan et ses tests

Dans `hooks/pre-commit` : pour tout `plan.md` créé ou arrivé par renommage (`git diff --cached --name-status -M --diff-filter=AR`), hors `templates/` à la racine et hors `tests/<nom>/fixtures/` à toute profondeur :
- `intent.md` absent du dossier, ni dans `HEAD` ni dans le commit en cours → refus en nommant l'intent attendu ;
- `spec.md` présente (commit en cours, sinon `HEAD`) → elle seule décide ; statut autre que `validé` → refus avec le statut trouvé ;
- sans spec → l'intent (commit en cours, sinon `HEAD`) décide ; statut autre que `validé` → refus avec le statut trouvé.

Tests `hooks/tests/hook-plan/run.sh` sur le modèle de `hooks/tests/hook-spec/run.sh`, un cas par critère d'acceptation de l'intent.

Couvre : tous les critères d'acceptation de l'intent (dossier sans intent, spec non validée / validée, spec et plan dans le même commit, intent et plan dans le même commit, sans spec, `git mv`, `templates/plan.md` et fixtures, tests existants au vert).

### 3. Documenter le contrôle

Mettre à jour le commentaire d'en-tête de `hooks/pre-commit` (fait à l'étape 2), la ligne `hooks/pre-commit` de `README.md` et son étape « Committer » pour le plan, et la ligne Architecture de `CLAUDE.md`.

Couvre : aucun critère d'acceptation (documentation).

## Tests à écrire

- Automatisés : `hooks/tests/hook-plan/run.sh`, dans un dépôt git temporaire, un cas par critère d'acceptation : plan dans un dossier sans intent mais avec spec validée (refusé) ; spec `draft` (refusé) / `validé` (accepté) ; spec + plan dans le même commit, `draft` refusé / `validé` accepté avec intent validé ; intent + plan dans le même commit sans spec, `draft` refusé / `validé` accepté ; sans spec, intent `draft` refusé / `validé` accepté ; `git mv` d'un plan vers un dossier non validé (refusé) ; `templates/plan.md` et un `plan.md` sous `tests/<nom>/fixtures/` acceptés sans intent.
- Non-régression : `hooks/tests/hook-spec/run.sh` et `hooks/tests/hook-intent/run.sh` inchangés et au vert.
- Commande, depuis la racine : `bash scripts/verifier.sh`.

## Couverture de la spec

Sans objet.

## Risques

- **Ce que le changement peut casser** (développeur) : le contrôle de la spec du lot 3 ne doit pas changer de comportement. Parade : étape 1 sans changement de comportement, vérifiée par `hooks/tests/hook-spec/run.sh` non modifié ; le contrôle du plan lit l'intent dans le commit en cours, le contrôle de la spec continue de le lire dans `HEAD` seulement.
- **Étape la plus risquée** (développeur) : la modification de `hooks/pre-commit` (étapes 1 et 2). Parade : `bash scripts/verifier.sh` vert à chaque commit.
- Détection du renommage : `--diff-filter=A` seul ne voit pas un `git mv` ; il faut `-M` et le filtre `R`, et lire le nouveau chemin.
- Fixtures du lot : les `plan.md` de `hooks/tests/hook-plan/fixtures/` doivent être exclus, sinon le commit de l'étape 2 est refusé par son propre contrôle.
- Questions sans réponse (questions ouvertes de l'intent, non tranchées dans cette séance) :
  - Statut absent de la spec ou de l'intent : message à afficher (point R2 du plan du lot 3). Non tranché.
  - Aligner le contrôle de la spec du lot 3 sur la règle « intent lu dans le commit en cours » ? À trancher par le tech lead. Ce plan ne l'aligne pas, conformément à la réponse du développeur sur ce qui ne doit pas casser.
- **Options écartées** (développeur) : un hook séparé pour le plan, écarté pour garder un seul `pre-commit`.

## Hors périmètre

- Template et skill de production du plan (lot 4a).
- Contrôle du contenu ou de la taille du plan.
- Contrôle des modifications d'un plan existant.
- Alignement du contrôle de la spec du lot 3 sur la lecture de l'intent dans le commit en cours.
