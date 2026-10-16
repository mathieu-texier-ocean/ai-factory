# Spec : Export des specs

<!-- Numéros C, L et A stables : une révision ajoute un nouveau numéro, elle ne renumérote jamais. Le lot 4 (plan) et le lot 7 (recette) s'y réfèrent. -->

- **Intent :** [intent.md](../contradiction/intent.md)
- **Auteur :** agent generation-spec (intent de Testeur)
- **Statut :** draft
- **Validation :** Tech lead

## Périmètre

Cette spec couvre un script qui publie le `spec.md` validé d'un lot dans le ticket Jira de ce lot, pour que les équipes métier, qui ne lisent pas Git, voient les specs avant la recette (intent, « Problème », « Résultat attendu »). Elle ne couvre pas la publication des plans. Son livrable unique contredit une contrainte de l'intent parent (voir « Points d'attention ») : la spec reste en draft tant que cette contradiction n'est pas tranchée.

## Comportements

### Script : publication de `spec.md` dans le ticket Jira du lot

- **C1.** Le script publie le contenu du `spec.md` d'un lot dans le ticket Jira associé à ce lot (intent, « Livrables » et « Résultat attendu »).
- **C2.** Le script ne publie que les specs dont le statut est `validé` (intent, « Résultat attendu » : « Chaque spec validée est publiée »).
- **C3.** Une spec dont le statut n'est pas `validé` n'est pas publiée, et le ticket Jira du lot n'est pas modifié (corollaire de C2).

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Le `spec.md` du lot est au statut `draft` | Aucune publication, ticket Jira inchangé (C3). |
| L2 | Le lot n'a pas de ticket Jira identifiable | À trancher : voir la question ouverte Q2 (C1). |
| L3 | Une spec déjà publiée est révisée puis revalidée | À trancher : voir la question ouverte Q4 (C1, C2). |
| L4 | Le lot n'a pas de `spec.md` | À trancher : voir la question ouverte Q5 (C1). |

## Contrats

L'intent ne définit pas l'interface du script. Ce qui en est connu :

- **Entrée :** le `spec.md` d'un lot, au statut `validé` (C1, C2).
- **Sortie :** le contenu de la spec visible dans le ticket Jira du lot (C1).
- **Non défini :** mode d'invocation et arguments, forme de la publication dans Jira, codes de retour et messages d'erreur. Voir les questions ouvertes Q1, Q3 et Q6.

## Critères d'acceptation

<!-- Une ligne = un scénario, lu par le lot 7. Chaque critère de l'intent a au moins une ligne. Type : Automatisé | Manuel | Humain. -->

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | La spec validée apparaît dans le ticket Jira du lot (intent, « Critère d'acceptation » ; C1, C2) | Un lot dont le `spec.md` est au statut `validé` et qui a un ticket Jira | On lance le script de publication pour ce lot | Le contenu du `spec.md` est visible dans le ticket Jira du lot | Manuel |
| A2 | Une spec non validée n'est pas publiée (C3) | Un lot dont le `spec.md` est au statut `draft` et qui a un ticket Jira | On lance le script de publication pour ce lot | Le ticket Jira du lot est inchangé et ne contient pas la spec | Manuel |

## Points d'attention

1. **Contradiction intent / parent sur Jira.** L'intent demande de publier la spec dans le ticket Jira (« Livrables », « Résultat attendu ») et pose « Jira devient la source de vérité des specs » (« Contraintes »). L'intent parent ([parent.md](../contradiction/parent.md), « Contraintes ») pose « Source de vérité des artefacts : Git. Aucune écriture dans Jira. » Le livrable unique du lot (C1) et sa contrainte s'opposent frontalement au parent. Non tranché. Décideur attendu : le tech lead (validation de l'intent), PO en copie ; une modification de la contrainte du parent relève de qui a validé le parent, non renseigné dans `parent.md`.
2. **Donnée sensible et contexte de l'agent.** Le parent pose « Aucune donnée sensible dans le contexte de l'agent ». Écrire dans Jira suppose un identifiant d'accès ; ni l'intent ni le parent ne disent qui le détient ni comment le script y accède. Décideur attendu : tech lead.
3. **Aucun skill de standards.** `.claude/skills/` ne contient aucun skill de sécurité, de conventions ou d'UX. La spec touche la sécurité (accès en écriture à Jira, gestion d'un identifiant) et les conventions (forme du script, format publié) sans référentiel pour les cadrer. Décideur attendu : tech lead.
4. **Critère de succès non mesurable.** « Les équipes métier lisent la spec avant la recette » n'a ni indicateur ni seuil ; il n'est pas repris en critère d'acceptation. Décideur attendu : PO.
5. **Priorité non définie.** « Niveau : à définir par le PO », justification vide. Décideur attendu : PO.

## Hors périmètre

- Publication des plans (intent, « Hors périmètre »).
- Production d'un `plan.md` ou d'un découpage en tâches.

## Questions ouvertes

<!-- L'intent ne contient aucune question ouverte ; celles-ci sont relevées pendant la génération. -->

- **Q1.** Sous quelle forme la spec est-elle publiée dans le ticket Jira (pièce jointe, commentaire, description, autre) ?
- **Q2.** Comment le script identifie-t-il le ticket Jira d'un lot, et que fait-il si aucun ticket n'est trouvé ?
- **Q3.** Qu'est-ce qui déclenche la publication (lancement manuel, passage au statut `validé`, autre) ?
- **Q4.** Quand une spec déjà publiée est révisée puis revalidée, la publication précédente est-elle remplacée, complétée ou conservée ?
- **Q5.** Que fait le script si le lot n'a pas de `spec.md` ?
- **Q6.** Quels codes de retour et messages d'erreur le script doit-il produire ?
- **Q7.** Quel est le niveau de priorité du lot (à définir par le PO) ?
