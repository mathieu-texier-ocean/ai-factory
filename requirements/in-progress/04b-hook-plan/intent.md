# Sous-intent — Lot 4b : Étape Plan, refus d'un plan sans amont validé

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** validé
- **Date :** 2026-10-16
- **Validation :** Tech lead
- **Dépend de :** lot 3, lot 4a (son plan est produit par le skill du 4a)
- **Origine :** découpage du lot 4 (Étape Plan)

## Problème

Rien n'empêche de committer un `plan.md` loin de l'intent qu'il réalise, ou alors que la spec, ou l'intent quand il n'y a pas de spec, n'est pas validée. Le plan peut alors partir d'un besoin ou d'une conception que personne n'a acceptés, et la chaîne intent → spec → plan n'est plus lisible dans le dossier du lot.

## Pour qui

- **Développeur** : committe le plan et voit le refus et sa raison si l'amont n'est pas validé.
- **Tech lead** : s'appuie sur le refus pour ne relire que des plans dont l'amont est validé.
- **Lot 4a (production du plan)** : son skill ne produit un plan que sur un amont validé ; le hook en est le contrôle déterministe.

## Pourquoi

Le skill du lot 4a est un contrôle consultatif : rien n'oblige une session, ni un humain, à le respecter. Sans contrôle bloquant, un plan sur amont non validé n'est découvert qu'en revue, ou pas du tout.

## Priorité

- **Niveau :** Haute (proposé par l'auteur, à confirmer par le PO)
- **Justification :** reprend pour le plan le garde-fou que le lot 3 a posé pour la spec.
- **Échéance :** aucune

## Résultat attendu

Le hook `pre-commit` refuse la création d'un `plan.md`, ou son arrivée dans un dossier par renommage :

- si le dossier du plan ne contient d'`intent.md` ni dans `HEAD` ni dans le commit en cours : le plan est produit à côté de l'intent associé ;
- si la `spec.md` du même dossier n'est pas validée : elle est lue dans le commit en cours quand elle en fait partie, sinon dans `HEAD` ;
- sans spec, ni dans `HEAD` ni dans le commit en cours, si l'`intent.md` du dossier n'est pas validé.

Le message nomme le fichier en cause et, selon le cas, l'intent attendu ou le statut trouvé.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.

## Livrables

| Type | Élément |
|---|---|
| Hook | `hooks/pre-commit` : contrôle « plan à côté de son intent, spec validée, sinon intent validé » |
| Tests | Tests automatisés du contrôle, dans `hooks/tests/hook-plan/`, sur le modèle de `hooks/tests/hook-spec/run.sh` |

## Critère d'acceptation

- [ ] Un nouveau `plan.md` placé dans un dossier sans `intent.md` est refusé, même si une `spec.md` validée s'y trouve.
- [ ] Un nouveau `plan.md` est refusé quand la spec du dossier n'est pas validée, et accepté quand elle l'est.
- [ ] Une `spec.md` et un `plan.md` créés dans le même commit : le plan est refusé si la spec est en `draft`, accepté si elle est `validé`, même quand l'intent est validé.
- [ ] Sans spec, un `intent.md` et un `plan.md` créés dans le même commit : le plan est refusé si l'intent est en `draft`, accepté s'il est `validé`.
- [ ] Sans spec, un nouveau `plan.md` est refusé quand l'intent n'est pas validé, et accepté quand il est validé.
- [ ] Un `plan.md` déplacé par `git mv` vers un dossier dont l'amont n'est pas validé est refusé.
- [ ] `templates/plan.md` et les `plan.md` des fixtures de tests sont acceptés sans intent.
- [ ] Les tests des contrôles existants (intent, spec) restent au vert.

## Contraintes

- Même motif de statut que le contrôle du lot 3 : première occurrence de `**Statut :** <valeur>`, seul `validé` exact passe. L'intent et la spec sont lus dans le commit en cours quand ils en font partie, sinon dans `HEAD`.
- Le `plan.md` est produit dans le dossier de l'intent associé : l'intent attendu est `<dossier du plan>/intent.md`, comme pour la spec.
- Sont contrôlés la création d'un `plan.md` et son renommage (`git mv`), qui ne doit pas permettre de contourner le contrôle.
- Sont exclus `templates/` à la racine, comme pour la spec, et les fixtures de tests (`tests/<nom>/fixtures/`, à toute profondeur), comme pour le contrôle credential.
- Bash et git uniquement, comme les contrôles existants.
- Source de vérité : Git. Aucune donnée sensible ni secret dans le contexte de l'agent.

## Hors périmètre

- Template et skill de production du plan (lot 4a).
- Contrôle du contenu ou de la taille du plan.
- Contrôle des modifications d'un plan existant.

## Questions ouvertes

- Statut absent de la spec ou de l'intent : message à afficher (point R2 du plan du lot 3).
- Le contrôle de la spec (lot 3) lit l'intent dans `HEAD` seulement : un intent et une spec créés dans le même commit y sont refusés, alors qu'un intent et un plan passent ici. Aligner le lot 3 sur cette règle ? À trancher par le tech lead.
