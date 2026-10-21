# Plan : Lot 4b : Étape Plan, refus d'un plan sans amont validé

<!-- Un lot = un plan = une PR ; une étape = un commit. Le plan est accepté avant tout code. S'il est modifié une fois validé, il repasse en draft. -->

- **Intent :** [intent.md](intent.md)
- **Auteur :** <à compléter par le développeur> · **Statut :** draft
- **À risque :** non
- **Validation :** développeur
- **Base :** <à confirmer par le développeur ; branche courante lors de la séance : `feat/lot-4a-plan` @ `9d10950`>

<!-- Sans spec, retirer le lien Spec. « À risque » est renseigné par le développeur d'après ce que le changement peut casser : oui → validation par le tech lead, non → par le développeur. -->

## Prérequis

- Amont : pas de `spec.md` ; c'est l'intent qui décide, et il est `validé`. Il n'est pas commité (non suivi dans l'arbre de travail) : le stager avec le plan, le hook `pre-commit` lit l'index ou `HEAD`.
- Une seule PR pour le lot.
- Dépend du lot 3 (contrôle de la spec dans `hooks/pre-commit`, tests `hooks/tests/hook-spec/`) et du lot 4a (skill de production du plan).

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `hooks/pre-commit` | modifié | 1, 2 |
| `hooks/tests/hook-plan/run.sh` | nouveau | 1, 2 |
| `hooks/tests/hook-plan/fixtures/` (intents et specs `draft` / `validé`, plan modèle) | nouveau | 1, 2 |
| `README.md` (ligne `hooks/pre-commit` de la table des livrables) | modifié | 3 |
| `CLAUDE.md` (ligne `hooks/pre-commit` de « Architecture ») | modifié | 3 |

## Étapes

### 1. Refuse la création d'un `plan.md` sans amont validé

Ajoute à `hooks/pre-commit` un contrôle des `plan.md` créés (`--diff-filter=A`), distinct de `check_spec_intent`, qui reste inchangé :

- `<dossier du plan>/intent.md` absent à la fois de `HEAD` et du commit en cours : refus « intent absent (<intent attendu>) », même si une spec validée est présente ;
- `<dossier>/spec.md` présente (dans le commit en cours ou dans `HEAD`) : elle seule décide ; lue dans le commit en cours quand elle en fait partie, sinon dans `HEAD` ; statut autre que `validé` : refus « spec non validée (statut : <valeur>) » ;
- sans spec : l'intent décide, lu de la même façon ; statut autre que `validé` : refus « intent non validé (statut : <valeur>) ».

Même motif de statut que le lot 3 (première occurrence de `**Statut :** <valeur>`, seul `validé` exact passe). Exclusions : `templates/` à la racine et `tests/<nom>/fixtures/` à toute profondeur.

Crée `hooks/tests/hook-plan/run.sh` sur le modèle de `hooks/tests/hook-spec/run.sh`, avec les cas de création.

Couvre : critères d'acceptation 1, 2, 3, 4, 5, 7.

### 2. Refuse l'arrivée d'un `plan.md` par renommage

Étend le contrôle aux renommages (`git mv`, `--diff-filter=R` avec `-M`) : le dossier de destination est contrôlé comme pour une création. Ajoute les cas de renommage à `hooks/tests/hook-plan/run.sh`.

S'appuie sur l'étape 1 (même fonction de contrôle).

Couvre : critère d'acceptation 6.

### 3. Documente le contrôle du plan

Met à jour le commentaire d'en-tête de `hooks/pre-commit` (quatre contrôles), la ligne `hooks/pre-commit` de `README.md` et celle de `CLAUDE.md`.

Couvre : documentation des livrables (aucun critère d'acceptation propre).

## Tests à écrire

- Automatisés, `hooks/tests/hook-plan/run.sh` (dépôt git temporaire, comme `hook-spec`) :
  - plan dans un dossier sans intent, avec spec validée : bloqué, message « intent absent » ;
  - spec `draft` : bloqué ; spec `validé` : accepté ;
  - spec et plan créés dans le même commit, intent validé : bloqué si spec `draft`, accepté si spec `validé` ;
  - sans spec, intent et plan créés dans le même commit : bloqué si intent `draft`, accepté si `validé` ;
  - sans spec, intent dans `HEAD` : bloqué si `draft`, accepté si `validé` ;
  - `git mv` d'un plan vers un dossier dont l'amont n'est pas validé : bloqué ;
  - `templates/plan.md` et un `plan.md` sous `tests/<nom>/fixtures/` sans intent : acceptés.
- Non-régression : `hooks/tests/hook-intent/run.sh`, `hooks/tests/hook-spec/run.sh` et `hooks/tests/hook-credential/run.sh` inchangés et au vert (critère d'acceptation 8).
- Commande, depuis la racine : `bash scripts/verifier.sh`.

## Couverture de la spec

Sans objet.

## Risques

- **Ce que le changement peut casser** (développeur) : le contrôle de la spec du lot 3 ne doit pas changer de comportement. Parade : contrôle du plan dans une fonction et une boucle à part, `check_spec_intent` non modifié, et `hooks/tests/hook-spec/run.sh` inchangé et au vert à chaque étape.
- **Étape la plus risquée** (développeur) : la modification de `hooks/pre-commit` (étapes 1 et 2). Parade : tests `hook-plan` écrits dans le même commit que le contrôle, `bash scripts/verifier.sh` lancé avant chaque commit.
- **Questions restées sans réponse** :
  - Statut absent de la spec ou de l'intent : message à afficher (question ouverte de l'intent, point R2 du plan du lot 3). Non tranché pendant la séance.
  - Aligner le contrôle de la spec du lot 3 sur la règle « lu dans le commit en cours, sinon dans `HEAD` » : à trancher par le tech lead (question ouverte de l'intent). La réponse du développeur exclut de changer le comportement du lot 3 dans ce lot ; la décision d'alignement reste ouverte.
- **Options écartées** (développeur) : un hook séparé pour le plan, écarté pour garder un seul `pre-commit`.

## Hors périmètre

- Template et skill de production du plan (lot 4a).
- Contrôle du contenu ou de la taille du plan.
- Contrôle des modifications d'un plan existant.
- Tout changement de comportement du contrôle de la spec du lot 3.
