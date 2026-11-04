# Intent : 2026-11-04-show-red-check

<!--
  Gabarit du SDLC fondé sur l’IA, copié par `git sdlc new <slug>`.
  Rédigez-le avec Claude, dans vos propres mots : ce qui est voulu, pourquoi,
  et sous quelles contraintes. Poussez, puis `git sdlc ready 2026-11-04-show-red-check intent` :
  le product owner relit la PR sur GitHub, demande des corrections ou la fusionne.

  N’ajoutez PAS de champ « Statut » : l’étape se déduit de git
  (`git sdlc status 2026-11-04-show-red-check`) et des PR GitHub, elle ne peut donc pas diverger.
  Product-Owner et Parent sont lus par git-sdlc : gardez « Clé: valeur » en début de ligne.
-->

Author: Mathieu Texier
Product-Owner: Mathieu Texier <mathieu.texier@ocean.fr>
Created: 2026-11-04
Origin: idée
Parent: —
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

`git sdlc status` résume les checks d'une PR ouverte en un mot (« rouges »), et `git sdlc merge` refuse la fusion avec « checks rouges ». Aucune des deux commandes ne dit quel check échoue ni pourquoi : il faut ouvrir la PR sur GitHub pour le savoir, ce qui casse le flux en ligne de commande.

## Pour qui

- Exprime et valide : le mainteneur du kit (Mathieu Texier).
- Consomme : ceux qui lancent `git sdlc status` et `git sdlc merge` (auteur de la PR, product owner, tech lead).

## Pourquoi

Chaque check rouge impose un aller-retour sur GitHub, alors que `git sdlc` se veut le point d'entrée en ligne de commande du SDLC.

## Priorité

<!-- Décision du product owner, jamais déduite. Niveau : Haute | Moyenne | Basse.
     Justification en une phrase. Échéance seulement si elle est réelle, sinon « aucune ». -->

- Niveau : Basse
- Justification :
- Échéance : aucune

## Résultat attendu

- `git sdlc status` : sous la ligne `checks rouges` des preuves, une ligne par check en échec, avec son nom, sa conclusion, la raison de l'échec fournie par GitHub (titre ou résumé) et le lien vers le détail. Les checks verts ou en cours ne sont pas détaillés.
- `git sdlc merge` : quand la fusion est refusée pour checks rouges, le même détail s'affiche.

## Utilisateurs et systèmes concernés

- Utilisateurs : auteurs de PR, product owners, tech leads, dans tout dépôt où le kit est déployé.
- Systèmes, API, dépôts : `bin/git-sdlc` ; API GitHub en lecture via `gh` (check runs et statuts de commit).

## Contraintes

- Bash 3.2.
- Lecture seule côté GitHub.
- Fonctionne seul dans un dépôt produit, sans fichier propre au kit.
- La sortie `status --porcelain` reste inchangée.
- Aucun appel GitHub supplémentaire quand aucun check n'est rouge.

## Hors périmètre

- `git sdlc board`.
- Le détail des checks verts ou en cours.
- La relance ou la correction des checks.

## Critères de succès

Mesurables, pour que les tests et la revue puissent les vérifier.

- [ ] PR avec un check rouge : `status` affiche son nom, sa conclusion, sa raison et son lien.
- [ ] PR avec plusieurs checks rouges : une ligne pour chacun.
- [ ] Checks tous verts, en cours ou absents : la sortie de `status` est identique à celle d'aujourd'hui.
- [ ] Le refus de `git sdlc merge` pour checks rouges affiche le même détail.
- [ ] La sortie `status --porcelain` est inchangée.
- [ ] Les check runs (GitHub Actions) comme les statuts de commit sont couverts.

## Questions ouvertes

Elles doivent être tranchées ou reportées explicitement dans spec.md.

- Justification de la priorité Basse (product owner).
- Longueur maximale de la raison affichée : faut-il tronquer le résumé ?
- Raison illisible (droits, API indisponible) : afficher le check sans raison ?
