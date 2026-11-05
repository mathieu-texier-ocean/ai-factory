# Intent : 2026-11-05-sdlc-self-update

<!--
  Gabarit du SDLC fondé sur l’IA, copié par `git sdlc new <slug>`.
  Rédigez-le avec Claude, dans vos propres mots : ce qui est voulu, pourquoi,
  et sous quelles contraintes. Poussez, puis `git sdlc ready 2026-11-05-sdlc-self-update intent` :
  le product owner relit la PR sur GitHub, demande des corrections ou la fusionne.

  N’ajoutez PAS de champ « Statut » : l’étape se déduit de git
  (`git sdlc status 2026-11-05-sdlc-self-update`) et des PR GitHub, elle ne peut donc pas diverger.
  Product-Owner et Parent sont lus par git-sdlc : gardez « Clé: valeur » en début de ligne.
-->

Author: Mathieu Texier
Product-Owner: Mathieu Texier <mathieu.texier@ocean.fr>
Created: 2026-11-05
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

Une fois averti qu'une release plus récente du kit existe (besoin `2026-11-05-sdlc-update`), l'utilisateur doit se mettre à jour à la main : télécharger le `git-sdlc` de la release dans son `PATH`, et lancer `scripts/deploy.sh update` depuis un clone du kit à ce tag. Sans clone du kit sous la main, la mise à jour du dépôt est reportée, et les évolutions du kit tardent à se déployer.

## Pour qui

- Exprime et valide : le mainteneur du kit (Mathieu Texier).
- Consomme : chaque utilisateur de `git sdlc` sur son poste, et les dépôts produits où le kit est déployé.

## Pourquoi

Une mise à jour en plusieurs étapes manuelles est remise à plus tard : l'avis seul ne suffit pas à faire converger postes et dépôts vers la dernière release.

## Priorité

<!-- Décision du product owner, jamais déduite. Niveau : Haute | Moyenne | Basse.
     Justification en une phrase. Échéance seulement si elle est réelle, sinon « aucune ». -->

- Niveau : Moyenne (reprise du besoin d'origine `2026-11-05-sdlc-update`, à confirmer par le PO)
- Justification : les postes et dépôts restent sur d'anciennes versions sans le savoir, mais aucun besoin en cours n'est bloqué.
- Échéance : aucune

## Résultat attendu

- Une commande de mise à jour (par exemple `git sdlc update`), sur confirmation de l'utilisateur, remplace `git-sdlc` dans le `PATH` par le fichier joint à la dernière release du kit.
- Elle met ensuite à jour le kit du dépôt courant depuis cette release, sans clone du kit, avec les règles de `deploy.sh update` : fichier intact remplacé, fichier modifié localement conservé avec la nouvelle version en `<fichier>.nouveau`, `.sdlc/manifeste` réécrit avec le tag.
- Si le dossier de `git-sdlc` n'est pas inscriptible, elle n'y touche pas, indique le chemin et la commande à lancer à la main, et met quand même à jour le kit si l'utilisateur l'a confirmé.
- Elle ne crée aucun commit : l'utilisateur relit et commite la mise à jour.

## Utilisateurs et systèmes concernés

- Utilisateurs : utilisateurs de `git sdlc` sur leur poste.
- Systèmes, API, dépôts : `bin/git-sdlc` ; `.sdlc/manifeste` des dépôts produits ; releases GitHub du dépôt du kit (`sdlc.kitRepo`), lues via `gh` ; règles de mise à jour de `scripts/deploy.sh`.

## Contraintes

- Dépend du besoin `2026-11-05-sdlc-update` : version de `git-sdlc`, fichier joint à la release, tag dans le manifeste et `sdlc.kitRepo`.
- Bash 3.2 ; chemins lus en `-z`.
- Fonctionne seul dans un dépôt produit, sans clone du kit ni fichier propre au kit (`scripts/deploy.sh` n'y est pas copié).
- Lecture seule côté GitHub ; aucune opération git (ni commit, ni push) dans le dépôt produit.
- Aucune modification sans confirmation explicite de l'utilisateur.

## Hors périmètre

- Détection et avis d'une release plus récente : besoin `2026-11-05-sdlc-update`.
- Mise à jour automatique sans confirmation.
- Retour à une version antérieure.

## Critères de succès

Mesurables, pour que les tests et la revue puissent les vérifier.

- [ ] Sans confirmation, la commande ne modifie ni `git-sdlc` ni le dépôt.
- [ ] Après confirmation, `git-sdlc` affiche la version de la release, et le kit du dépôt et `.sdlc/manifeste` sont à ce tag.
- [ ] Un fichier modifié localement est conservé, et sa nouvelle version est écrite en `<fichier>.nouveau`, comme avec `deploy.sh update`.
- [ ] Dossier de `git-sdlc` non inscriptible : le script n'est pas modifié, le message donne le chemin et la commande manuelle, et le kit est mis à jour si confirmé.
- [ ] Aucun commit créé, aucune écriture GitHub.
- [ ] Testé dans un dépôt git temporaire avec un `gh` factice, une ligne `PASS`/`FAIL` par cas.

## Questions ouvertes

Elles doivent être tranchées ou reportées explicitement dans spec.md.

- Priorité : niveau Moyenne repris du besoin d'origine, à confirmer par le PO.
- Partage des règles de mise à jour entre `git-sdlc` et `scripts/deploy.sh` (code commun ou réimplémentation) : à préciser en spec.
- Confirmation unique pour `git-sdlc` et le kit, ou une par élément : à préciser en spec.
