# TL;DR : 2026-11-04-add-measure

<!--
  Gabarit copié par le skill redaction-intent, puis tenu à jour à chaque étape :
  intent, spec, build et validation, dans la PR de l’étape. Quelques lignes, pour
  qui découvre le besoin : le détail reste dans intent.md, spec.md et plan.md.
  Pas de champ « Statut » : la fusion de la PR fait foi.
-->

## Résumé

<!-- Trois à cinq lignes : le problème, ce qui est livré, et où en est le besoin (étape en cours). -->

Le kit applique le SDLC du playbook sans pouvoir mesurer s'il fonctionne. Le besoin ajoute `git sdlc metrics`, qui calcule depuis git et GitHub, par besoin et en agrégé, les indicateurs « How to measure it » du playbook : délais par étape, survie des intents, retouches, rework, CI au premier passage, revue, fréquence de release. La spec fixe 28 comportements, 20 cas limites, la sortie `--porcelain` (lignes `need`, `pr`, `agg`, `claude`) et 19 critères d'acceptation, testés avec un `gh` factice. Étape en cours : build, codé en 6 étapes et testé par `bin/tests/metrics/run.sh` (45 cas) ; reste la recette A9, A13 et A18 sur ai-factory, tracée dans `validation.md`.

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
- 2026-11-04 · spec · Cycle de rework = intervalle entre sortie du brouillon, revues et fusion contenant au moins un commit (P1, Mathieu Texier)
- 2026-11-04 · spec · Rebase force-poussé après la sortie du brouillon : biais accepté et documenté, pas de détection (P2, Mathieu Texier)
- 2026-11-04 · spec · Lecture GraphQL paginée par 50, PR need/* fusionnées seulement, sans seuil de durée (P3, Mathieu Texier)
- 2026-11-04 · spec · Premier test automatisé de bin/git-sdlc dans bin/tests/metrics, CLAUDE.md mis à jour au build (P4, Mathieu Texier)
- 2026-11-04 · spec · Dates lues à la seconde, sans les troncatures au jour de load_prs, merge_info et compute (C4, revue de la spec)
- 2026-11-04 · spec · Date de début d'un besoin rejeté sans commit d'intent : création de sa PR, sinon tag rejected (C3, revue de la spec)
- 2026-11-04 · spec · Revues retenues : après la sortie du brouillon et d'un autre compte que l'auteur (C28, revue de la spec)
- 2026-11-04 · spec · CI au premier passage : runs annulés, ignorés ou neutres non concluants (C15, revue de la spec)
- 2026-11-04 · spec · Précise P3 : PR choisies d'après gh pr list, listes imbriquées au-delà de 100 complétées par PR (C26, revue de la spec)
- 2026-11-05 · spec · Révise la décision C26 du 2026-11-04 : bornes par niveau (100 revues, 100 commits, 10 suites, 1 run), 110 050 nœuds par lot de 50 PR, sous la limite GitHub de 500 000 (revue de vkphan)
- 2026-11-05 · spec · Étape fusionnée plusieurs fois : les délais partent de sa première fusion (C4, L20, revue de vkphan)
- 2026-11-05 · build · À risque : non, sous-commande neuve en lecture seule, sans modification des fonctions existantes (Mathieu Texier)
- 2026-11-05 · build · Étape la plus risquée : la lecture GraphQL des PR, vérifiable contre GitHub seulement à la recette (A18, A13) (Mathieu Texier)
- 2026-11-05 · build · Le gh factice des tests applique les filtres --jq avec jq : jq requis pour les tests, pas pour git-sdlc (Mathieu Texier)
- 2026-11-05 · build · Dates de release lues par gh release list en un appel, plutôt que gh release view par tag (Mathieu Texier)
- 2026-11-05 · build · Écartés : réutiliser load_prs et merge_info, gh pr view par PR, gh run list (API Actions), gh factice à sorties préfiltrées, jq comme dépendance, date -d de GNU (Mathieu Texier)
