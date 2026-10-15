# Spec : Rappel de clôture des tournées

<!-- Numéros C, L et A stables : une révision ajoute un nouveau numéro, elle ne renumérote jamais. Le lot 4 (plan) et le lot 7 (recette) s'y réfèrent. -->

- **Intent :** [intent.md](../intent-sans-livrables/intent.md)
- **Auteur :** brouillon généré par le skill generation-spec (auteur humain à renseigner)
- **Statut :** draft
- **Validation :** PO

## Périmètre

La spec couvre l'envoi d'un rappel, avant la fin de service, pour une tournée qui n'est pas encore clôturée (intent, « Résultat attendu »), à destination des exploitants (intent, « Pour qui »), afin de réduire le nombre de tournées non clôturées qui faussent les rapports d'activité (intent, « Problème », « Pourquoi »). L'intent ne liste aucun livrable ni critère d'acceptation explicite : le seul livrable retenu ici est déduit du « Résultat attendu » (voir « Points d'attention »).

## Comportements

<!-- Règles numérotées C1, C2… groupées par livrable de l'intent. Chaque livrable a au moins un comportement. -->

### Rappel de clôture (déduit du « Résultat attendu » de l'intent)

- **C1.** Avant la fin de service, si une tournée n'est pas clôturée, un rappel est envoyé (source : intent, « Résultat attendu »). Le délai avant la fin de service, le canal et le destinataire exact ne sont pas définis (voir « Questions ouvertes »).
- **C2.** Aucun rappel n'est envoyé pour une tournée déjà clôturée au moment où le rappel serait déclenché (source : intent, « Résultat attendu », condition « si la tournée n'est pas clôturée »).
- **C3.** Le rappel ne clôture pas la tournée : la clôture reste une action de l'utilisateur (source : intent, « Hors périmètre » : « Clôture automatique »).

## Cas limites

<!-- Situations aux bords et comportement attendu, en citant la règle C concernée. -->

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | La tournée est clôturée juste avant le déclenchement du rappel | Aucun rappel n'est envoyé (C2). |
| L2 | La tournée est toujours non clôturée après l'envoi du rappel | La tournée reste ouverte, aucune clôture automatique (C3). Rappels répétés : non défini (voir « Questions ouvertes »). |
| L3 | La tournée n'a pas d'heure de fin de service connue | Non défini par l'intent (voir « Questions ouvertes ») ; C1 ne peut pas s'appliquer sans heure de référence. |
| L4 | Le destinataire du rappel est injoignable ou l'envoi échoue | Non défini par l'intent (voir « Questions ouvertes »). |

## Contrats

Non déterminable à ce stade : l'intent ne précise ni le canal du rappel (notification, SMS, e-mail…), ni le format du message, ni la source de l'heure de fin de service. À compléter une fois les questions ouvertes tranchées.

## Critères d'acceptation

<!-- Une ligne = un scénario, lu par le lot 7. Chaque critère de l'intent a au moins une ligne. Type : Automatisé | Manuel | Humain. -->

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Rappel envoyé pour une tournée non clôturée (C1) | Une tournée non clôturée dont la fin de service approche | Le moment de déclenchement du rappel (délai à définir) est atteint | Un rappel est émis vers le destinataire prévu et sa trace est observable | Automatisé |
| A2 | Pas de rappel pour une tournée clôturée (C2) | Une tournée clôturée avant le moment de déclenchement du rappel | Le moment de déclenchement du rappel est atteint | Aucun rappel n'est émis pour cette tournée | Automatisé |
| A3 | Pas de clôture automatique (C3) | Une tournée non clôturée ayant reçu un rappel | La fin de service est dépassée sans action de l'utilisateur | La tournée est toujours à l'état non clôturé | Automatisé |
| A4 | Moins de tournées non clôturées (intent, « Critère de succès ») | Une mesure de référence du nombre ou du taux de tournées non clôturées avant mise en service (valeur à fournir) | La période d'observation après mise en service (durée à définir) est écoulée | Le nombre ou le taux mesuré de tournées non clôturées est inférieur à la référence | Humain |

## Points d'attention

<!-- Contradictions, risques et arbitrages à trancher avant le build, chacun avec le décideur attendu. « Aucun » s'il n'y en a pas. -->

- **Livrables absents de l'intent.** L'intent ne contient aucune liste de livrables. Le livrable « Rappel de clôture » a été déduit du « Résultat attendu » ; à confirmer ou compléter dans l'intent. Décideur : PO.
- **Critères d'acceptation absents de l'intent.** L'intent ne donne qu'un « Critère de succès » (« Moins de tournées non clôturées »), sans référence, seuil ni période de mesure. A1 à A3 sont dérivés des comportements, A4 reprend le critère de succès sans pouvoir le chiffrer. Décideur : PO.
- **Priorité non définie.** « Niveau : à définir par le PO », justification vide. Décideur : PO.
- **Aucun parent.** L'intent ne référence pas d'intent parent (« Dépend de : — ») : aucune contrainte héritée n'a pu être vérifiée.
- **Aucun skill de standards.** `.claude/skills/` ne contient aucun skill de standards (sécurité, conventions, UX) ; la spec touche à l'envoi de messages à des utilisateurs (contenu, canal, données personnelles éventuelles) sans référentiel pour le cadrer. Décideur : tech lead.

## Hors périmètre

<!-- Ce que la spec ne couvre volontairement pas. -->

- Clôture automatique des tournées (intent, « Hors périmètre »).

## Questions ouvertes

<!-- Informations manquantes ou à trancher. Peut rester vide. -->

- Combien de temps avant la fin de service le rappel est-il envoyé ?
- À qui le rappel est-il envoyé : aux exploitants (intent, « Pour qui »), au conducteur de la tournée, ou aux deux ?
- Par quel canal le rappel est-il envoyé, et avec quel contenu ?
- D'où vient l'heure de fin de service d'une tournée, et que faire si elle est absente ?
- Le rappel est-il unique ou répété tant que la tournée n'est pas clôturée ?
- Que faire si l'envoi du rappel échoue ?
- Quelle est la mesure de référence des tournées non clôturées, la période d'observation et le seuil attendu pour le critère de succès ?
