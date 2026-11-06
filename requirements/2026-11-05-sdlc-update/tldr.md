# TL;DR : 2026-11-05-sdlc-update

<!--
  Gabarit copié par le skill redaction-intent, puis tenu à jour à chaque étape :
  intent, spec, build et validation, dans la PR de l’étape. Quelques lignes, pour
  qui découvre le besoin : le détail reste dans intent.md, spec.md et plan.md.
  Pas de champ « Statut » : la fusion de la PR fait foi.
-->

## Résumé

<!-- Trois à cinq lignes : le problème, ce qui est livré, et où en est le besoin (étape en cours). -->

Les nouvelles versions d'ai-factory passent inaperçues : `git-sdlc` est copié à la main sur chaque poste, et le kit d'un dépôt produit n'est mis à jour que via `deploy.sh update` depuis un clone. Les commandes `git sdlc` signaleront, au plus une fois par jour, qu'une release plus récente existe et comment se mettre à jour. `git sdlc version` affiche la version, que chaque release joint en fichier `git-sdlc`, et `.sdlc/manifeste` porte le tag installé. La commande qui applique la mise à jour est un besoin séparé, `2026-11-05-sdlc-self-update`. Étape en cours : build. Le code et les tests sont livrés (`bin/tests/update-check`, `scripts/tests/release-asset`, `scripts/tests/deploy`), et la fiche de recette `validation.md` est jointe. Il reste à publier la première release du kit avant `ready`.

## Décisions

<!-- Une ligne par décision importante, la plus récente en bas, jamais réécrite :
     « - <AAAA-MM-JJ> · <intent | spec | build | validation> · <décision> (<décideur ou source>) ».
     Une décision révisée donne une nouvelle ligne qui cite l’ancienne. -->
- 2026-11-05 · intent · Référence = dernière release GitHub d'ai-factory, pas `main` (Mathieu Texier)
- 2026-11-05 · intent · Couvre `git-sdlc` du poste et le kit du dépôt produit (Mathieu Texier)
- 2026-11-05 · intent · Avis dans les commandes `git sdlc` et commande de mise à jour sur confirmation ; pas de hook `SessionStart` (Mathieu Texier)
- 2026-11-05 · intent · Vérification au plus une fois par jour, avis discret si GitHub est injoignable (Mathieu Texier)
- 2026-11-05 · intent · Priorité Moyenne, aucune échéance (Mathieu Texier, PO)
- 2026-11-05 · intent · Première release du kit publiée par le mainteneur avant le build (Mathieu Texier)
- 2026-11-05 · intent · Version de `git-sdlc` dans une variable renseignée avec le tag ; tag de release ajouté à `.sdlc/manifeste`, comparaison par SHA pour un manifeste ancien (Mathieu Texier)
- 2026-11-05 · intent · Dépôt de référence : `sdlc.kitRepo` de `.sdlc/config`, défaut `ocean-shiftmove/ai-factory` ; lecture via `gh`, sinon « vérification impossible » (Mathieu Texier)
- 2026-11-05 · intent · Cache dans le `.git` du dépôt ; désactivation par `git config sdlc.updateCheck false` (Mathieu Texier)
- 2026-11-05 · intent · Dossier de `git-sdlc` non inscriptible : refus expliqué, kit mis à jour quand même si confirmé (Mathieu Texier)
- 2026-11-05 · intent · Version de `git-sdlc` : fichier joint à chaque release du kit, variable = tag ; précise la ligne sur la variable renseignée avec le tag (Mathieu Texier)
- 2026-11-05 · intent · Découpage après contrôle de taille : ce besoin garde la détection et l'avis ; la commande de mise à jour et la décision « dossier non inscriptible » passent dans `2026-11-05-sdlc-self-update` (Mathieu Texier)
- 2026-11-05 · intent · Le fichier `git-sdlc` versionné est joint à la release par un workflow GitHub Actions déclenché par le tag, propre au kit et non copié par `deploy.sh` (Mathieu Texier)
- 2026-11-06 · spec · `git sdlc version` et `--version` affichent la version ; fichier joint nommé `git-sdlc` ; ligne `tag` optionnelle au manifeste (Mathieu Texier, PO)
- 2026-11-06 · spec · Workflow déclenché par la publication de la release, plutôt que par le tag ; `contents: write` sur ce seul job (Mathieu Texier, PO)
- 2026-11-06 · spec · Première release sans fichier joint acceptée ; recette du fichier joint à la release suivante (Mathieu Texier, PO)
- 2026-11-06 · spec · Manifeste sans tag : SHA différent de celui du tag = en retard (Mathieu Texier, PO)
- 2026-11-06 · spec · Manifeste illisible par un `deploy.sh` antérieur : accepté (Mathieu Texier, PO)
- 2026-11-06 · spec · Avis sur la sortie d'erreur, avant la sortie de la commande ; échec de vérification mis en cache pour la journée (Mathieu Texier, PO)
- 2026-11-06 · spec · Délai de la requête GitHub réglable par `sdlc.updateCheckTimeout`, 5 secondes par défaut (Mathieu Texier, PO)
- 2026-11-06 · build · À risque : non (Mathieu Texier)
- 2026-11-06 · build · Première release absente au départ : build poursuivi, release publiée avant `ready` (Mathieu Texier)
- 2026-11-06 · build · Délai par un garde-fou bash (`sleep` puis `kill`), plutôt que `perl alarm` ou un `timeout` facultatif (Mathieu Texier)
- 2026-11-06 · build · Logique du workflow dans `scripts/release-asset.sh`, testable, plutôt qu'en ligne dans le YAML (Mathieu Texier)
- 2026-11-06 · build · Lecture de GitHub par `gh api`, pas `curl` (Mathieu Texier)
- 2026-11-06 · build · Comparaison de versions dupliquée dans `git-sdlc` et `deploy.sh`, sans bibliothèque partagée (Mathieu Texier)
- 2026-11-06 · build · Aucune requête GitHub quand rien n'est à comparer (`git-sdlc` en `dev`, sans manifeste) (Mathieu Texier)
- 2026-11-06 · build · Cache indexé aussi par `sdlc.kitRepo` : un changement de dépôt de référence dans la journée relance la requête (Claude au build, à valider en revue)
- 2026-11-06 · build · `validation.md` joint à la PR build, colonne « Cas » remplie (Mathieu Texier)
