# Intent : 2026-11-04-add-measure

<!--
  Gabarit du SDLC fondé sur l’IA, copié par `git sdlc new <slug>`.
  Rédigez-le avec Claude, dans vos propres mots : ce qui est voulu, pourquoi,
  et sous quelles contraintes. Poussez, puis `git sdlc ready 2026-11-04-add-measure intent` :
  le product owner relit la PR sur GitHub, demande des corrections ou la fusionne.

  N’ajoutez PAS de champ « Statut » : l’étape se déduit de git
  (`git sdlc status 2026-11-04-add-measure`) et des PR GitHub, elle ne peut donc pas diverger.
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

Le kit applique le SDLC du playbook, mais rien ne dit s'il fonctionne : aucune mesure des délais par étape, du taux de survie des intents, des retouches d'artefacts ni du rework des PR. `git sdlc status` et `git sdlc board` ne montrent que l'instantané, pas l'historique. Chaque play du playbook (`documents/sdlc-playbook.md`, « How to measure it ») définit pourtant ses indicateurs.

## Pour qui

- Exprime et valide : le mainteneur du kit (Mathieu Texier).
- Consomme : le mainteneur du kit, pour piloter son évolution et repérer l'étape qui bloque ; la direction, pour le reporting.

## Pourquoi

Sans mesure, on ne peut ni vérifier que le SDLC raccourcit le cycle, ni repérer l'étape qui ralentit, ni évaluer l'effet d'une modification du kit.

## Priorité

<!-- Décision du product owner, jamais déduite. Niveau : Haute | Moyenne | Basse.
     Justification en une phrase. Échéance seulement si elle est réelle, sinon « aucune ». -->

- Niveau : Moyenne
- Justification : utile au pilotage du kit et au reporting, mais aucun besoin en cours n'est bloqué sans mesures.
- Échéance : aucune

## Résultat attendu

Une commande `git sdlc metrics [--since <date>]` affiche, par besoin et en agrégé (médiane), les indicateurs du playbook calculables depuis git et GitHub. Sans `--since`, tout l'historique est pris en compte :

- Plan : délai entre le premier commit de l'intent et la fusion de sa PR ; taux de survie (intents fusionnés contre PR fermées `sdlc:rejected`) ; commits sur `intent.md` après le premier commit de `spec.md`.
- Design : délai entre la fusion de l'intent et celle de la spec ; commits sur `spec.md` après le premier commit de `plan.md`.
- Build : délai entre la fusion de la spec et celle du build ; part des PR fusionnées au premier passage (aucun commit poussé après la sortie du brouillon) ; cycles de rework par PR (séries de commits poussées après la sortie du brouillon).
- Test et Deploy : succès au premier passage du check CI `sdlc-conventions` ; délai jusqu'à la première revue ; durée de revue, de la sortie du brouillon à la fusion.
- DORA partiel : fréquence des releases (tags `YY.MM.DD[.V]`) ; délai entre la fusion du build et la release qui le contient.
- CLAUDE.md : nombre de corrections de `CLAUDE.md` dans le temps.

## Utilisateurs et systèmes concernés

- Utilisateurs : mainteneur du kit, direction ; tout dépôt produit où le kit est déployé.
- Systèmes, API, dépôts : `bin/git-sdlc` ; API GitHub en lecture via `gh` ; historique git du dossier `intentDir` et tags de release ; dépôts produits alimentés par `scripts/deploy.sh`.

## Contraintes

- Lecture seule : aucune écriture GitHub ni git.
- Bash 3.2 ; chemins lus en `-z`.
- Fonctionne seul dans un dépôt produit, sans fichier propre au kit.
- Respecte `prLimit` de `.sdlc/config`.
- Aucun statut ni chiffre stocké dans un artefact : tout est recalculé depuis git et GitHub.
- La fusion par rebase réécrit la date de committer : les délais s'appuient sur la date d'auteur ou sur la date de fusion GitHub.

## Hors périmètre

- Indicateurs qui demandent OpenTelemetry : sessions parallèles, attente aux gates des hooks.
- Indicateurs qui demandent un outil de suivi des incidents : change failure rate, défauts échappés en production, régressions en production.
- Evals, boucle Maintain (franchissement d'une bande de contrôle), triage des échecs de pipeline.
- Délai entre l'approbation d'une politique et la mise à jour de sa skill.
- Temps jusqu'à la première PR fusionnée d'un nouvel arrivant : l'équipe est trop petite pour que ce chiffre ait un sens.
- Exports CSV ou JSON : la sortie `--porcelain` (TSV) suffit.
- Collecte en continu et tableau de bord web.

## Critères de succès

Mesurables, pour que les tests et la revue puissent les vérifier.

- [ ] Chaque indicateur du « Résultat attendu » s'affiche par besoin et en agrégé (médiane).
- [ ] `--since <date>` exclut les besoins antérieurs à la date ; les agrégats ne portent que sur les besoins retenus.
- [ ] Sur un jeu de fixtures connu (dépôt git temporaire, PR simulées), les valeurs calculées égalent les valeurs attendues.
- [ ] Un besoin incomplet (spec absente, PR rejetée) affiche « — » pour les indicateurs concernés, sans erreur.
- [ ] Une sortie `--porcelain` (TSV, même convention que `status` et `board`) est stable et s'importe telle quelle dans un tableur pour le reporting de la direction.
- [ ] La commande n'écrit rien : aucun appel `gh` en écriture, `git status` inchangé après exécution.

## Questions ouvertes

Elles doivent être tranchées ou reportées explicitement dans spec.md.

- Aucune : toutes ont été tranchées le 2026-11-04 (voir `tldr.md`).
