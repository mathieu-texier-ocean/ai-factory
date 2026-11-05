# Intent : 2026-11-05-sdlc-update

<!--
  Gabarit du SDLC fondé sur l’IA, copié par `git sdlc new <slug>`.
  Rédigez-le avec Claude, dans vos propres mots : ce qui est voulu, pourquoi,
  et sous quelles contraintes. Poussez, puis `git sdlc ready 2026-11-05-sdlc-update intent` :
  le product owner relit la PR sur GitHub, demande des corrections ou la fusionne.

  N’ajoutez PAS de champ « Statut » : l’étape se déduit de git
  (`git sdlc status 2026-11-05-sdlc-update`) et des PR GitHub, elle ne peut donc pas diverger.
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

Rien ne signale qu'une nouvelle version d'ai-factory existe. `git-sdlc` est copié à la main dans le `PATH` de chaque poste, et le kit d'un dépôt produit n'évolue que si quelqu'un lance `scripts/deploy.sh update` depuis un clone récent du kit. Les mises à jour passent donc inaperçues pendant l'usage : postes et dépôts restent sur d'anciennes versions, et une évolution du kit met longtemps à atteindre ses utilisateurs.

## Pour qui

- Exprime et valide : le mainteneur du kit (Mathieu Texier).
- Consomme : chaque utilisateur de `git sdlc` sur son poste, et les dépôts produits où le kit est déployé.

## Pourquoi

Sans signal, les correctifs et évolutions du kit restent inutilisés, et des postes d'une même équipe tournent avec des versions différentes de `git-sdlc` et du kit.

## Priorité

<!-- Décision du product owner, jamais déduite. Niveau : Haute | Moyenne | Basse.
     Justification en une phrase. Échéance seulement si elle est réelle, sinon « aucune ». -->

- Niveau : Moyenne
- Justification : les postes et dépôts restent sur d'anciennes versions sans le savoir, mais aucun besoin en cours n'est bloqué.
- Échéance : aucune

## Résultat attendu

- La référence est la dernière release GitHub du dépôt du kit (tag `YY.MM.DD[.V]`) : clé `sdlc.kitRepo` de `.sdlc/config`, surchargeable par `git config`, par défaut `ocean-shiftmove/ai-factory`.
- `git-sdlc` porte sa version dans une variable (« dev » dans le dépôt du kit). Chaque release du kit joint en fichier un `git-sdlc` dont la variable vaut le tag ; c'est ce fichier qu'un poste installe. `.sdlc/manifeste` enregistre, en plus du SHA, le tag de la release installée ; un manifeste ancien, sans tag, est comparé par le SHA que vise le tag.
- Les commandes `git sdlc` comparent à cette release la version de `git-sdlc` installée sur le poste et celle du kit installé dans le dépôt courant. Si l'une est en retard, elles affichent un avis d'une ligne qui nomme la version disponible et la façon de se mettre à jour à la main : télécharger le `git-sdlc` de la release, lancer `deploy.sh update` depuis un clone du kit à ce tag.
- La vérification interroge GitHub au plus une fois par jour et par dépôt ; le résultat est mis en cache dans le `.git` du dépôt.
- GitHub injoignable ou dépôt du kit illisible : un avis discret « vérification impossible », la commande s'exécute normalement.
- `git config sdlc.updateCheck false` (local ou global) désactive la vérification.

## Utilisateurs et systèmes concernés

- Utilisateurs : utilisateurs de `git sdlc` sur leur poste ; mainteneur du kit, qui publie les releases.
- Systèmes, API, dépôts : `bin/git-sdlc` ; `.sdlc/manifeste` des dépôts produits ; releases GitHub de `ocean-shiftmove/ai-factory`, lues via `gh` ; `scripts/deploy.sh`, qui écrit le manifeste.

## Contraintes

- Bash 3.2 ; chemins lus en `-z`.
- Prérequis de chaque utilisateur : accès en lecture au dépôt du kit avec le `gh` déjà authentifié.
- La première release du kit est publiée par le mainteneur avant le build de ce besoin, pour servir de référence réelle.
- Fonctionne seul dans un dépôt produit, sans clone du kit ni fichier propre au kit (`scripts/deploy.sh` n'y est pas copié).
- Lecture seule côté GitHub ; la vérification n'écrit dans le dépôt que son cache, sous `.git`.
- L'avis et la vérification ne bloquent ni ne ralentissent sensiblement une commande `git sdlc`.

## Hors périmètre

- Commande qui applique la mise à jour : besoin séparé `2026-11-05-sdlc-self-update`, découpé de celui-ci le 2026-11-05.
- Mise à jour automatique.
- Signal à l'ouverture de session Claude Code (hook `SessionStart`) : non retenu le 2026-11-05.
- Retour à une version antérieure.
- Suivre `main` d'ai-factory plutôt que ses releases.

## Critères de succès

Mesurables, pour que les tests et la revue puissent les vérifier.

- [ ] Chaque release du kit contient en fichier un `git-sdlc` dont la version affichée vaut le tag ; le `git-sdlc` du dépôt du kit affiche « dev ».
- [ ] `deploy.sh install` et `update` à partir d'un tag écrivent ce tag dans `.sdlc/manifeste`.
- [ ] La référence suit `sdlc.kitRepo` quand elle est définie, `ocean-shiftmove/ai-factory` sinon.
- [ ] Avec une release plus récente que `git-sdlc` installé, une commande `git sdlc` affiche un avis nommant la version disponible et la mise à jour à faire ; à jour, aucun avis.
- [ ] Même chose pour le kit d'un dépôt produit plus ancien que la release.
- [ ] Deux commandes lancées le même jour dans un même dépôt n'interrogent GitHub qu'une fois.
- [ ] GitHub injoignable ou dépôt du kit illisible : avis « vérification impossible », code de sortie de la commande inchangé.
- [ ] Avec `sdlc.updateCheck` à `false`, aucune requête GitHub et aucun avis.
- [ ] Un manifeste sans tag (installé avant ce besoin) est comparé correctement à la release.
- [ ] Testé dans un dépôt git temporaire avec un `gh` factice, une ligne `PASS`/`FAIL` par cas.

## Questions ouvertes

Elles doivent être tranchées ou reportées explicitement dans spec.md.

- Ce qui produit et joint le fichier `git-sdlc` à la release du kit (`git sdlc release`, workflow CI sur le tag…) : à préciser en spec.
- Les autres questions ont été tranchées le 2026-11-05 (voir `tldr.md`).
