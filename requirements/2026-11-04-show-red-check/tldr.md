# TL;DR : 2026-11-04-show-red-check

<!--
  Gabarit copié par le skill redaction-intent, puis tenu à jour à chaque étape :
  intent, spec, build et validation, dans la PR de l’étape. Quelques lignes, pour
  qui découvre le besoin : le détail reste dans intent.md, spec.md et plan.md.
  Pas de champ « Statut » : la fusion de la PR fait foi.
-->

## Résumé

<!-- Trois à cinq lignes : le problème, ce qui est livré, et où en est le besoin (étape en cours). -->

`git sdlc status` et le refus de `git sdlc merge` disent seulement « checks rouges » : pour savoir quel check échoue et pourquoi, il faut ouvrir la PR sur GitHub. Le besoin ajoute, pour chaque check rouge, son nom, sa conclusion, la raison donnée par GitHub et son lien. La spec fixe 8 comportements (C1–C8), 8 cas limites et 8 critères d'acceptation, tous manuels faute de test automatisé de `bin/git-sdlc`. Étape en cours : spec.

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
