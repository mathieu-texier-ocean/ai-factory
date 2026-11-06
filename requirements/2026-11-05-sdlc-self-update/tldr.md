# TL;DR : 2026-11-05-sdlc-self-update

<!--
  Gabarit copié par le skill redaction-intent, puis tenu à jour à chaque étape :
  intent, spec, build et validation, dans la PR de l’étape. Quelques lignes, pour
  qui découvre le besoin : le détail reste dans intent.md, spec.md et plan.md.
  Pas de champ « Statut » : la fusion de la PR fait foi.
-->

## Résumé

<!-- Trois à cinq lignes : le problème, ce qui est livré, et où en est le besoin (étape en cours). -->

Averti d'une release plus récente du kit (besoin `2026-11-05-sdlc-update`), l'utilisateur doit encore se mettre à jour à la main, avec un clone du kit pour le dépôt. Une commande `git sdlc` remplacera, sur confirmation, `git-sdlc` et le kit du dépôt par la dernière release, sans clone ni commit, avec les mêmes résultats que `deploy.sh update`. Étape en cours : spec ; elle attend la livraison de `2026-11-05-sdlc-update`, dont elle reprend la version de `git-sdlc`, le fichier joint et le format du manifeste.

## Décisions

<!-- Une ligne par décision importante, la plus récente en bas, jamais réécrite :
     « - <AAAA-MM-JJ> · <intent | spec | build | validation> · <décision> (<décideur ou source>) ».
     Une décision révisée donne une nouvelle ligne qui cite l’ancienne. -->
- 2026-11-05 · intent · Né du découpage de `2026-11-05-sdlc-update` après contrôle de taille : reprend la commande de mise à jour (Mathieu Texier)
- 2026-11-05 · intent · Met à jour `git-sdlc` et le kit du dépôt, sur confirmation, sans commit (Mathieu Texier)
- 2026-11-05 · intent · Dossier de `git-sdlc` non inscriptible : refus expliqué, kit mis à jour quand même si confirmé (Mathieu Texier)
- 2026-11-06 · spec · Priorité Moyenne confirmée, aucune échéance (Mathieu Texier, PO)
- 2026-11-06 · spec · Une question de confirmation par élément : `git-sdlc`, puis le kit (Mathieu Texier, PO)
- 2026-11-06 · spec · Partage du code avec `deploy.sh` reporté au plan ; équivalence vérifiée par un test contre `deploy.sh update` (Mathieu Texier, PO)
- 2026-11-06 · spec · Commande `git sdlc update` ; refus utilisateur = code 0, sans terminal = code 1 (Mathieu Texier, PO)
- 2026-11-06 · spec · `--force` met à jour le kit même hors lignée, avec avertissement ; écart assumé avec « retour arrière hors périmètre » de l'intent (Mathieu Texier, PO)
- 2026-11-06 · spec · `git-sdlc` en lien symbolique ou en version `dev` : non remplacé, kit quand même proposé (Mathieu Texier, PO)
- 2026-11-06 · spec · Pas de vérification d'empreinte : confiance dans `gh` et `sdlc.kitRepo`, dépôt source nommé dans les questions (Mathieu Texier, PO)
- 2026-11-06 · spec · Build après la livraison de `2026-11-05-sdlc-update` (Mathieu Texier, PO)
