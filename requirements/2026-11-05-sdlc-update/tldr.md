# TL;DR : 2026-11-05-sdlc-update

<!--
  Gabarit copié par le skill redaction-intent, puis tenu à jour à chaque étape :
  intent, spec, build et validation, dans la PR de l’étape. Quelques lignes, pour
  qui découvre le besoin : le détail reste dans intent.md, spec.md et plan.md.
  Pas de champ « Statut » : la fusion de la PR fait foi.
-->

## Résumé

<!-- Trois à cinq lignes : le problème, ce qui est livré, et où en est le besoin (étape en cours). -->

Les nouvelles versions d'ai-factory passent inaperçues : `git-sdlc` est copié à la main sur chaque poste, et le kit d'un dépôt produit n'est mis à jour que via `deploy.sh update` depuis un clone. Les commandes `git sdlc` signaleront, au plus une fois par jour, qu'une release plus récente existe, et une commande mettra à jour `git-sdlc` et le kit sur confirmation, sans commit. Étape en cours : intent.

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
