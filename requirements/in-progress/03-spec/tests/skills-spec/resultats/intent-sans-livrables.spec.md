# Spec : Rappel de clôture des tournées

<!-- Numéros C, L et A stables : une révision ajoute un nouveau numéro, elle ne renumérote jamais. Le lot 4 (plan) et le lot 7 (recette) s'y réfèrent. -->

- **Intent :** [intent.md](../intent-sans-livrables/intent.md)
- **Auteur :** generation-spec
- **Statut :** draft
- **Validation :** PO

## Périmètre

Envoi d'un rappel avant la fin de service lorsqu'une tournée n'est pas clôturée, pour les exploitants, afin de réduire le nombre de tournées non clôturées qui faussent les rapports d'activité. La clôture automatique n'est pas couverte. L'intent ne liste aucun livrable explicite ni aucun critère d'acceptation : les comportements ci-dessous reprennent uniquement le « Résultat attendu » (voir « Points d'attention »).

## Comportements

### Rappel de clôture (repris du « Résultat attendu », aucun livrable explicite dans l'intent)

- **C1.** Avant la fin de service, si la tournée n'est pas clôturée, un rappel est envoyé. Source : intent, « Résultat attendu ».
- **C2.** Le rappel ne clôture pas la tournée : la clôture reste une action de l'utilisateur. Source : intent, « Hors périmètre » (clôture automatique).

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | La tournée est déjà clôturée avant la fin de service | Aucun rappel n'est envoyé (condition de C1 non remplie). |
| L2 | La tournée n'est toujours pas clôturée après l'envoi du rappel | La tournée reste non clôturée, aucune clôture automatique (C2). La suite (relance éventuelle) n'est pas définie : voir « Questions ouvertes ». |

## Contrats

Non déterminés : l'intent ne précise ni le canal du rappel, ni son destinataire, ni son contenu, ni la source de l'heure de fin de service. Voir « Questions ouvertes ».

## Critères d'acceptation

<!-- Une ligne = un scénario, lu par le lot 7. Chaque critère de l'intent a au moins une ligne. Type : Automatisé | Manuel | Humain. -->

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|

## Points d'attention

- **Aucun livrable explicite dans l'intent.** Les comportements C1 et C2 sont repris du « Résultat attendu » et du « Hors périmètre », pas d'une liste de livrables. Décideur : PO.
- **Aucun critère d'acceptation dans l'intent.** Le tableau des critères est laissé vide ; aucun critère n'a été dérivé des comportements ni du « Critère de succès ». Les critères sont à fournir avant le build. Décideur : PO.
- **« Critère de succès » non mesurable en l'état.** « Moins de tournées non clôturées » ne donne ni valeur de référence, ni seuil, ni période d'observation. Décideur : PO.
- **Aucun skill de standards dans `.claude/skills/`.** Aucun standard de sécurité, de conventions ni d'UX ne couvre l'envoi de notifications ou le contenu du rappel. Décideur : tech lead.
- **Pas d'intent parent.** L'intent ne référence aucun parent (`Dépend de : —`) : aucune contrainte héritée n'a pu être vérifiée.

## Hors périmètre

- Clôture automatique des tournées (intent, « Hors périmètre »).

## Questions ouvertes

- Combien de temps avant la fin de service le rappel doit-il être envoyé ?
- Comment est déterminée la fin de service (source, par tournée, par conducteur, par exploitant) ?
- Qui reçoit le rappel : l'exploitant, le conducteur de la tournée, ou les deux ?
- Par quel canal le rappel est-il envoyé, et avec quel contenu ?
- Un seul rappel est-il envoyé, ou des relances sont-elles prévues si la tournée reste non clôturée ?
- Quels sont les livrables et les critères d'acceptation de l'intent ?
- Priorité : niveau, justification et échéance restent « à définir par le PO » dans l'intent.
