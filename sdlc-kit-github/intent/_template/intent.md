# Intent : {{ID}}

<!--
  Gabarit du SDLC fondé sur l’IA, copié par `git sdlc new <slug>`.
  Rédigez-le avec Claude, dans vos propres mots : ce qui est voulu, pourquoi,
  et sous quelles contraintes. Poussez, puis `git sdlc ready {{ID}} intent` :
  le product owner relit la PR sur GitHub, demande des corrections ou la fusionne.

  N’ajoutez PAS de champ « Statut » : l’étape se déduit de git
  (`git sdlc status {{ID}}`) et des PR GitHub, elle ne peut donc pas diverger.
  Les champs ci-dessous sont lus par git-sdlc : gardez « Clé: valeur » en début de ligne.
-->

Author: {{AUTHOR}}
Product-Owner: <Prénom Nom> <email>
Created: {{DATE}}
Origin: {{ORIGIN}}
Parent: {{PARENT}}
Ticket: —
Risk: standard

<!--
  Origin   idée | ticket | incident | scan-securite
  Parent   id du besoin d’origine quand l’intent naît d’un incident (boucle Maintain)
  Ticket   référence Jira / ServiceNow si un outil existant reste la source de vérité ;
           reportez-y en retour le SHA du commit qui accepte cet intent
  Risk     standard | élevé — « élevé » impose l’avis d’un tech lead avant le build
-->

## Problème

Ce qu’on ne peut pas faire aujourd’hui, qui est touché, et ce que ça coûte.

## Résultat attendu

À quoi ressemble « mieux », vu par l’utilisateur.

## Utilisateurs et systèmes concernés

- Utilisateurs :
- Systèmes, API, dépôts :

## Contraintes

Sécurité, données personnelles, conformité, performance, compatibilité.

## Hors périmètre

Ce que ce besoin ne couvre volontairement pas.

## Critères de succès

Mesurables, pour que les tests et la revue puissent les vérifier.

- [ ] 

## Questions ouvertes

Elles doivent être tranchées ou reportées explicitement dans spec.md.

- 
