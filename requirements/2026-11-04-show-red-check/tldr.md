# TL;DR : 2026-11-04-show-red-check

<!--
  Gabarit copié par le skill redaction-intent, puis tenu à jour à chaque étape :
  intent, spec, build et validation, dans la PR de l’étape. Quelques lignes, pour
  qui découvre le besoin : le détail reste dans intent.md, spec.md et plan.md.
  Pas de champ « Statut » : la fusion de la PR fait foi.
-->

## Résumé

<!-- Trois à cinq lignes : le problème, ce qui est livré, et où en est le besoin (étape en cours). -->

`git sdlc status` et le refus de `git sdlc merge` disent seulement « checks rouges » : pour savoir quel check échoue et pourquoi, il faut ouvrir la PR sur GitHub. Le besoin ajoute, pour chaque check rouge, son nom, sa conclusion, la raison donnée par GitHub et son lien. La spec fixe 9 comportements (C1–C9), 9 cas limites et 9 critères d'acceptation ; sa révision du 2026-11-05 lit la raison d'un check GitHub Actions dans ses annotations, son titre et son résumé étant vides. Build livré en trois étapes (détail dans `status`, détail au refus de `merge`, tests avec un faux `gh`), puis corrigé après revue. Étape en cours : recette, fiche dans `validation.md` (critères automatisés constatés, essais contre GitHub à faire côté hôte).

## Décisions

<!-- Une ligne par décision importante, la plus récente en bas, jamais réécrite :
     « - <AAAA-MM-JJ> · <intent | spec | build | validation> · <décision> (<décideur ou source>) ».
     Une décision révisée donne une nouvelle ligne qui cite l’ancienne. -->

- 2026-11-04 · intent · Détail limité aux checks rouges, avec leur raison (Mathieu Texier)
- 2026-11-04 · intent · Périmètre : `status` et refus de `merge` ; `board` hors périmètre (Mathieu Texier)
- 2026-11-04 · intent · Priorité Basse, sans échéance (Mathieu Texier)
- 2026-11-04 · intent · Product owner : Mathieu Texier (Mathieu Texier)
- 2026-11-04 · intent · Priorité Basse justifiée : gain de confort, l'information reste sur GitHub et aucun besoin n'est bloqué (Mathieu Texier)
- 2026-11-04 · intent · Raison illisible : check affiché sans raison, la commande n'échoue pas (Mathieu Texier)
- 2026-11-04 · intent · Longueur maximale de la raison : reportée au build, à fixer avec les premiers essais (Mathieu Texier)
- 2026-11-05 · spec · Raison d'un check Actions lue dans ses annotations : titre et résumé vides (Mathieu Texier)
- 2026-11-05 · build · À risque : non (Mathieu Texier)
- 2026-11-05 · build · Tests automatisés avec un faux `gh` ; tests manuels seuls écartés (Mathieu Texier)
- 2026-11-05 · build · Champs ajoutés à `JQ_PRS` et GraphQL des annotations écartés : lecture REST seulement pour un check rouge (Mathieu Texier)
- 2026-11-05 · build · Longueur maximale de la raison réglable par `checkReasonMax` dans `.sdlc/config` : 120 par défaut, 0 sans limite (Mathieu Texier)
