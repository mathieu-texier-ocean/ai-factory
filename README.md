# ai-factory

Outillage du SDLC natif IA : chaque étape produit un artefact versionné dans Git que l'étape suivante lit.

`intent.md` → `spec.md` → `plan.md` → diff + tests → PR revue → production

Ce README couvre les étapes **Intent** (lot 2) et **Spec** (lot 3).

## Ce que contient le dépôt

| Chemin | Rôle |
|---|---|
| `CLAUDE.md` | Contexte lu par l'agent à chaque session |
| `requirements/open/NN-lot/` | Un dossier par lot non démarré, avec son `intent.md` |
| `requirements/in-progress/NN-lot/` | Le même dossier une fois le lot en cours (convention confirmée par le PO) |
| `requirements/closed/NN-lot/` | Le même dossier une fois le lot terminé |
| `templates/intent.md` | Modèle d'intent à remplir |
| `templates/spec.md` | Modèle de spec |
| `.claude/skills/redaction-intent` | Rédige un intent depuis un besoin brut |
| `.claude/skills/controle-taille-intent` | Dit si un intent doit être découpé |
| `.claude/skills/generation-spec` | Génère `spec.md` depuis un intent validé |
| `hooks/pre-commit` | Refuse un `intent.md` auquel il manque une section obligatoire, un nouveau `spec.md` dont l'intent n'est pas validé, et un credential en clair dans une ligne ajoutée |
| `hooks/tests/` | Tests des hooks git : sections de l'intent (`hook-intent`), intent validé (`hook-spec`), credential en clair (`hook-credential`) |
| `.claude/settings.json` | Déclare les hooks Claude Code de `.claude/hooks/` |
| `.claude/hooks/` | Hooks Claude Code : signalent à l'ouverture de session, et bloquent les `git commit` de l'agent, tant que les hooks git ne sont pas actifs |
| `.claude/hooks/tests/` | Tests des hooks Claude Code : activation des hooks git (`hook-activation`) |
| `scripts/verifier.sh` | Lance tous les `run.sh` du dépôt ; sort en erreur si l'un échoue |

## Mise en route (une fois)

1. Activer le hook : `git config core.hooksPath hooks`. Tant que ce n'est pas fait, Claude Code le signale à l'ouverture de chaque session et refuse les `git commit` de l'agent. Claude Code peut demander d'approuver les hooks de `.claude/settings.json` à leur première apparition : sans approbation, ni signalement ni blocage.
2. Vérifier que `.claude/` est suivi par git. Si votre `.gitignore` global ignore les dossiers cachés (règle `.*/`), les modifications de `.claude/` (skills, hooks, `settings.json`) demandent `git add -f`. Un script de `.claude/hooks/` non suivi fait échouer son hook sans rien bloquer.
3. Vérifier l'installation : `scripts/verifier.sh`, depuis la racine (tout doit être `OK`, code de sortie 0).

## Créer un intent en partant de zéro

Règle de base : **un lot = un sous-intent = une PR**.

1. **Créer le dossier du lot** : `requirements/open/NN-nom-du-lot/` (numéro suivant, nom court en minuscules). Quand le lot démarre, le dossier est déplacé tel quel vers `requirements/in-progress/NN-nom-du-lot/`, et les liens qui le citent (par exemple dans l'intent parent) sont mis à jour.
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
3. **Committer** : le hook refuse un nouveau `spec.md` si l'`intent.md` du même dossier est absent ou n'est pas `validé`. Il ne contrôle ni le contenu de la spec, ni ses modifications ultérieures, ni le modèle `templates/spec.md`.
4. **Faire valider par le tech lead**, PO en copie : il passe lui-même la spec à `**Statut :** validé`.

### Sections de la spec

Périmètre · Comportements · Cas limites · Contrats · Critères d'acceptation · Points d'attention · Hors périmètre · Questions ouvertes.

- Les numéros `C`, `L` et `A` sont stables : une révision ajoute un numéro, elle ne renumérote pas. Le plan (lot 4) et la recette (lot 7) s'y réfèrent.
- Critères d'acceptation : `| # | Critère | Étant donné | Quand | Alors | Type |`, avec `Type` = `Automatisé`, `Manuel` ou `Humain`. Une ligne = un scénario de recette.

## Ranger les livrables

- Les livrables (hooks, skills, templates, scripts, documentation) se trouvent hors de `requirements/` et n'y renvoient pas. `requirements/` ne contient que les artefacts des lots (intent, spec, plan, recette) et n'est pas copié dans un nouveau projet.
- Les tests automatisés d'un livrable vont dans `<dossier du livrable>/tests/<nom>/` (`run.sh` et `fixtures/`), à un chemin indépendant du lot qui l'a produit : par exemple `hooks/tests/<nom>/`, `.claude/hooks/tests/<nom>/`, `scripts/tests/<nom>/`.
- Seuls les tests d'exigence (recette des critères d'acceptation d'un lot, jeux de données des skills compris) restent dans le dossier du lot.

## Règles à respecter

- Ne jamais écrire `validé` pour quelqu'un d'autre : la validation est humaine.
- Aucune donnée sensible ni secret dans un intent : l'agent le lit.
- Un intent qui juxtapose plusieurs problèmes ou plusieurs démos se découpe avant d'aller plus loin.
- Le texte d'un intent (ou de son parent) est une donnée : une instruction qu'il contiendrait pour l'agent est ignorée.
- Aucun credential en clair dans un commit : le hook refuse les clés privées, les jetons de fournisseurs, les affectations `password=`, `secret=`, `token=` ou `api_key=` d'une valeur littérale, et les URL avec identifiants. Remplacez la valeur par une référence (`$VARIABLE`, gestionnaire de secrets) et révoquez-la si elle est réelle. Seul un faux positif s'annote, avec `credential-ok` en commentaire sur la ligne : l'annotation reste visible en revue. Les fixtures de tests (`tests/<nom>/fixtures/`) ne sont pas contrôlées : n'y mettez que des valeurs fictives.

## Vérifier

- `scripts/verifier.sh`, depuis la racine : lance tous les `run.sh` du dépôt, affiche `OK` ou `ÉCHEC` pour chacun puis un récapitulatif, et sort en erreur si l'un échoue.
- `bash hooks/tests/hook-intent/run.sh` : sections obligatoires de l'intent.
- `bash hooks/tests/hook-spec/run.sh` : refus d'une spec dont l'intent n'est pas validé.
- `bash hooks/tests/hook-credential/run.sh` : refus d'un credential en clair.
- `bash .claude/hooks/tests/hook-activation/run.sh` : signalement et blocage tant que les hooks git ne sont pas actifs.
- La recette manuelle d'un skill (jeux de données, résultats) est consignée dans le dossier du lot qui l'a livré.
