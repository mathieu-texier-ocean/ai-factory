# Sous-intent — Lot 3b : Étape Spec, contrôle de la spec aligné sur celui du plan

- **Parent :** [ia-factory.md](../../open/ia-factory.md)
- **Auteur :** Mathieu TEXIER · **Statut :** validé
- **Date :** 2026-10-21
- **Validation :** Tech lead
- **Dépend de :** lot 3, lot 4b (livré avant : sa lecture de l'amont est réutilisée)
- **Origine :** spec du lot 4b (points d'attention P1 et P3, comportement C18)

## Problème

Le contrôle « intent validé » du lot 3 dans `hooks/pre-commit` ne voit que les `spec.md` ajoutées, lit leurs chemins sans `-z` et lit l'intent dans `HEAD` seulement. Trois conséquences, constatées avec git 2.51 :

- une `spec.md` déplacée par `git mv` apparaît comme un renommage (`R`) et n'est pas contrôlée : le garde-fou se contourne ;
- un dossier dont le nom contient un accent arrive entre guillemets (`core.quotePath`) : le hook ne trouve pas l'intent et refuse à tort (« intent absent ») ;
- un intent validé dans le même commit que la spec est refusé, alors que le contrôle du plan (lot 4b) accepte un intent ou une spec validés dans le même commit que le plan.

Un champ `**Statut :**` absent donne en plus un message au statut vide, `(statut : )`.

## Pour qui

- **Développeur** : committe une spec et obtient le même traitement que pour un plan, sans faux refus.
- **Tech lead** : s'appuie sur un refus que `git mv` ne contourne pas.

## Pourquoi

Tant que le contrôle se contourne par renommage, une spec sur un intent non validé peut entrer dans le dépôt sans être vue. Les règles différentes pour la spec et pour le plan obligent le développeur à retenir deux comportements pour le même motif de statut.

## Priorité

- **Niveau :** Moyenne (proposé par l'auteur, à confirmer par le PO)
- **Justification :** faille connue mais contournement rare : `git mv` d'une spec suppose un geste volontaire, et les faux refus sur un dossier accentué restent rares.
- **Échéance :** aucune

## Résultat attendu

Le contrôle de la spec de `hooks/pre-commit` suit la règle de lecture du contrôle du plan (lot 4b) :

- une `spec.md` arrivée dans un dossier par renommage est contrôlée comme une création ;
- les chemins sont lus bruts (`-z`) : un dossier avec un accent ou une espace est contrôlé normalement ;
- l'`intent.md` du dossier est lu dans le commit en cours quand il en fait partie, sinon dans `HEAD` ; un intent supprimé dans le commit de la spec est absent ;
- un champ `**Statut :**` absent est affiché `absent` : `<spec> : intent non validé (statut : absent)` ;
- les fixtures de tests (`tests/<nom>/fixtures/`, à toute profondeur) sont exclues, comme pour le plan et le credential.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.

## Livrables

| Type | Élément |
|---|---|
| Hook | `hooks/pre-commit` : contrôle « intent validé » de la spec aligné sur le contrôle du plan |
| Tests | `hooks/tests/hook-spec/run.sh` et ses fixtures, complétés et mis à jour |

## Critère d'acceptation

- [ ] Une `spec.md` déplacée par `git mv` vers un dossier dont l'intent n'est pas validé est refusée.
- [ ] Une `spec.md` créée dans un dossier dont le nom contient un accent, à côté d'un intent validé, est acceptée.
- [ ] Un `intent.md` passé à `validé` et une `spec.md` créés dans le même commit : la spec est acceptée ; l'intent en `draft` dans le même commit est refusé.
- [ ] Un `intent.md` présent dans `HEAD` et supprimé dans le commit de la spec : la spec est refusée, « intent absent ».
- [ ] Un intent sans champ `**Statut :**` : la spec est refusée, message `(statut : absent)`.
- [ ] `templates/spec.md` et une `spec.md` sous `tests/<nom>/fixtures/` sont acceptés sans intent.
- [ ] Le contrôle de la spec et celui du plan passent par la même lecture de l'amont (chemins, renommage, index sinon `HEAD`).
- [ ] Le scénario du lot 3 « validé dans le même commit bloqué » est remplacé par le scénario accepté, et le changement de comportement est signalé dans la PR.
- [ ] Les tests des contrôles existants (intent, credential, plan s'il est livré) restent au vert.

## Contraintes

- Même motif de statut que le lot 3 : première occurrence de `**Statut :** <valeur>`, seul `validé` exact passe.
- Exclusions : `templates/` à la racine et les fixtures de tests (`tests/<nom>/fixtures/`, à toute profondeur), comme pour le plan.
- Le lot 4b est livré d'abord ; ce lot réutilise sa lecture de l'amont au lieu de la dupliquer.
- Messages au format actuel du lot 3 (`intent absent (<chemin>)`, `intent non validé (statut : <valeur>)`).
- Bash et git uniquement, comme les contrôles existants.
- Source de vérité : Git. Aucune donnée sensible ni secret dans le contexte de l'agent.

## Hors périmètre

- Contrôle du plan (lot 4b).
- Contrôle du contenu de la spec ou de la modification d'une spec existante.
- Skill `generation-spec` : il lit le statut dans l'arbre de travail et n'est pas modifié.
- Spec close du lot 3 (`requirements/closed/03-spec/spec.md`) : laissée telle quelle ; la spec de ce lot cite C14 et A11 du lot 3 comme remplacés.

## Questions ouvertes
