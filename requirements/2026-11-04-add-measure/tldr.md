# TL;DR : 2026-11-04-add-measure

<!--
  Gabarit copié par le skill redaction-intent, puis tenu à jour à chaque étape :
  intent, spec, build et validation, dans la PR de l’étape. Quelques lignes, pour
  qui découvre le besoin : le détail reste dans intent.md, spec.md et plan.md.
  Pas de champ « Statut » : la fusion de la PR fait foi.
-->

## Résumé

<!-- Trois à cinq lignes : le problème, ce qui est livré, et où en est le besoin (étape en cours). -->

Le kit applique le SDLC du playbook sans pouvoir mesurer s'il fonctionne. Le besoin ajoute `git sdlc metrics`, qui calcule depuis git et GitHub, par besoin et en agrégé, les indicateurs « How to measure it » du playbook : délais par étape, survie des intents, retouches, rework, CI au premier passage, revue, fréquence de release. Étape en cours : intent.

## Décisions

<!-- Une ligne par décision importante, la plus récente en bas, jamais réécrite :
     « - <AAAA-MM-JJ> · <intent | spec | build | validation> · <décision> (<décideur ou source>) ».
     Une décision révisée donne une nouvelle ligne qui cite l’ancienne. -->

- 2026-11-04 · intent · Périmètre limité aux indicateurs calculables depuis git et GitHub ; OpenTelemetry, incidents et evals hors périmètre (Mathieu Texier)
- 2026-11-04 · intent · Forme : sous-commande `git sdlc metrics` (Mathieu Texier)
- 2026-11-04 · intent · Consommateurs : mainteneur du kit et direction (Mathieu Texier)
- 2026-11-04 · intent · Priorité Moyenne, sans échéance (Mathieu Texier)
- 2026-11-04 · intent · Priorité Moyenne justifiée : utile au pilotage et au reporting, aucun besoin bloqué sans mesures (Mathieu Texier)
- 2026-11-04 · intent · Option `--since <date>` (défaut : tout l'historique) ; agrégat = médiane (Mathieu Texier)
- 2026-11-04 · intent · Export : `--porcelain` (TSV) suffit, ni CSV ni JSON (Mathieu Texier)
- 2026-11-04 · intent · Premier passage = aucun commit poussé après la sortie du brouillon ; cycle de rework = série de commits après la sortie du brouillon (Mathieu Texier)
- 2026-11-04 · intent · Temps jusqu'à la première PR d'un nouvel arrivant : hors périmètre (Mathieu Texier)
- 2026-11-04 · intent · Pas de découpage malgré une PR build estimée longue ; découper éventuellement au plan (Mathieu Texier)
