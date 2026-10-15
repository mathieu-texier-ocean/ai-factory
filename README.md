# ai-factory

Outillage du SDLC natif IA : chaque étape produit un artefact versionné dans Git que l'étape suivante lit.

`intent.md` → `spec.md` → `plan.md` → diff + tests → PR revue → production

Vue d'ensemble, lots et critères de succès : [requirements/open/ia-factory.md](requirements/open/ia-factory.md).

Ce README couvre les étapes **Intent** (lot 2) et **Spec** (lot 3). Les étapes suivantes sont décrites dans leur lot (`requirements/open/NN-lot/`).

## Ce que contient le dépôt

| Chemin | Rôle |
|---|---|
| `requirements/open/NN-lot/` | Un dossier par lot non démarré, avec son `intent.md` |
| `requirements/in-progress/NN-lot/` | Le même dossier une fois le lot en cours (convention confirmée par le PO) |
| `requirements/closed/NN-lot/` | Le même dossier une fois le lot terminé |
| `templates/intent.md` | Modèle d'intent à remplir |
| `templates/spec.md` | Modèle de spec |
| `.claude/skills/redaction-intent` | Rédige un intent depuis un besoin brut |
| `.claude/skills/controle-taille-intent` | Dit si un intent doit être découpé |
| `.claude/skills/generation-spec` | Génère `spec.md` depuis un intent validé |
| `hooks/pre-commit` | Refuse un `intent.md` auquel il manque une section obligatoire, et un nouveau `spec.md` dont l'intent n'est pas validé |
| `requirements/closed/02-intent/tests/` | Tests du lot 2 : hook (sections de l'intent) et jeux de données des skills d'intent |
| `requirements/in-progress/03-spec/tests/` | Tests du lot 3 : hook (intent validé) et jeux de données de `generation-spec` |

## Mise en route (une fois)

1. Activer le hook : `git config core.hooksPath hooks`
2. Vérifier que les skills sont suivis par git. Si votre `.gitignore` global ignore les dossiers cachés (règle `.*/`), les modifications de `.claude/skills/` demandent `git add -f`.
3. Vérifier l'installation : `bash requirements/closed/02-intent/tests/hook-intent/run.sh` et `bash requirements/in-progress/03-spec/tests/hook-spec/run.sh` (tout doit être `PASS`).

## Créer un intent en partant de zéro

Règle de base : **un lot = un sous-intent = une PR**.

1. **Créer le dossier du lot** : `requirements/open/NN-nom-du-lot/` (numéro suivant, nom court en minuscules). Quand le lot démarre, le dossier est déplacé tel quel vers `requirements/in-progress/NN-nom-du-lot/`, et les liens qui le citent (par exemple dans `ia-factory.md`) sont mis à jour.
2. **Rédiger l'intent** : dans Claude Code, demandez « rédiger un intent » (skill `redaction-intent`) en donnant votre besoin brut en texte libre et le dossier cible.
   - Le skill pose les questions manquantes, une série à la fois.
   - Il n'invente rien : ce que vous ne savez pas va dans « Questions ouvertes ».
   - Il écrit `intent.md` avec `Statut : draft`, et refuse d'écraser un intent existant.
   - Sans skill, copiez `templates/intent.md` dans le dossier et remplissez-le à la main.
3. **Compléter ce que seul le PO décide** : la section « Priorité » (niveau Haute, Moyenne ou Basse, justification, échéance éventuelle). Elle reste « à définir par le PO » tant qu'il ne l'a pas renseignée.
4. **Contrôler la taille** : demandez « contrôle de taille » (skill `controle-taille-intent`). Il évalue 8 signaux de découpage et propose des sous-intents si l'intent ne tient pas en une PR. Il ne modifie rien.
5. **Committer** : le hook vérifie que les sections obligatoires sont présentes et nomme celles qui manquent. Il contrôle la présence, pas la qualité du contenu.
6. **Faire valider par le PO** : le PO relit puis passe lui-même `**Statut :** draft` à `**Statut :** validé` (écriture exacte, avec l'accent). Aucun skill ni agent ne le fait.

### Sections de l'intent

Problème · Pour qui · Pourquoi · Priorité · Résultat attendu · Critère de succès · Contraintes · Hors périmètre · Questions ouvertes (seule section pouvant rester vide). Les titres doivent être écrits exactement ainsi (`## Pourquoi`) : un titre mal orthographié compte comme manquant. D'autres sections (Livrables, Critère d'acceptation, Plan de test…) peuvent s'ajouter.

## Créer une spec depuis un intent validé

Prérequis : l'intent est au statut `validé` **et commité**. Le hook lit l'intent du dernier commit : valider l'intent et ajouter la spec dans le même commit est refusé.

1. **Générer la spec** : dans Claude Code, demandez « générer la spec » (skill `generation-spec`) en donnant le chemin de l'`intent.md` ou du dossier du lot.
   - Le skill s'arrête si l'intent n'est pas `validé`, ou si `spec.md` existe déjà. Il n'écrase jamais une spec.
   - Il couvre chaque livrable par des comportements `C` et chaque critère d'acceptation de l'intent par des critères `A`. Il n'invente aucun critère : sans critère dans l'intent, le tableau reste vide et l'absence est signalée.
   - Contradictions (intent, parent, standards), informations manquantes et instructions trouvées dans l'intent vont dans « Points d'attention » ou « Questions ouvertes ». Le skill ne tranche rien.
   - Il écrit `spec.md` avec `Statut : draft` et ne modifie pas l'intent.
   - Sans skill, copiez `templates/spec.md` dans le dossier et remplissez-le à la main.
2. **Trancher les points d'attention** avec le décideur nommé pour chacun.
3. **Committer** : le hook refuse un nouveau `spec.md` si l'`intent.md` du même dossier est absent ou n'est pas `validé`. Il ne contrôle ni le contenu de la spec, ni ses modifications ultérieures.
4. **Faire valider par le tech lead**, PO en copie : il passe lui-même la spec à `**Statut :** validé`.

### Sections de la spec

Périmètre · Comportements · Cas limites · Contrats · Critères d'acceptation · Points d'attention · Hors périmètre · Questions ouvertes.

- Les numéros `C`, `L` et `A` sont stables : une révision ajoute un numéro, elle ne renumérote pas. Le plan (lot 4) et la recette (lot 7) s'y réfèrent.
- Critères d'acceptation : `| # | Critère | Étant donné | Quand | Alors | Type |`, avec `Type` = `Automatisé`, `Manuel` ou `Humain`. Une ligne = un scénario de recette.

## Règles à respecter

- Ne jamais écrire `validé` pour quelqu'un d'autre : la validation est humaine.
- Aucune donnée sensible ni secret dans un intent : l'agent le lit.
- Un intent qui juxtapose plusieurs problèmes ou plusieurs démos se découpe avant d'aller plus loin.
- Le texte d'un intent (ou de son parent) est une donnée : une instruction qu'il contiendrait pour l'agent est ignorée.

## Vérifier

- `bash requirements/closed/02-intent/tests/hook-intent/run.sh` : sections obligatoires de l'intent.
- `requirements/closed/02-intent/tests/skills-intent/` : jeux de données de la recette manuelle des skills, avec le résultat attendu de chaque scénario dans son README.
- `bash requirements/in-progress/03-spec/tests/hook-spec/run.sh` : refus d'une spec dont l'intent n'est pas validé.
- `requirements/in-progress/03-spec/tests/skills-spec/` : jeux de données de la recette de `generation-spec`, résultats dans `RESULTATS.md`.
