# Recette — Lot 4a : Étape Plan, production du plan

- **Date :** 2026-10-21
- **Exécution :** branche `feat/lot-4a-plan` (commit 9d10950), depuis la racine du dépôt.

## Tests automatisés

| Cas | Action | Résultat observé | Réf. |
|---|---|---|---|
| Ensemble du dépôt | `bash scripts/verifier.sh`, après chaque étape | `5 run.sh lancés, 0 en échec` | non-régression |
| Copie dans un nouveau projet | lecture de `LISTE_BLANCHE` en tête de `scripts/ai-factory.sh` | `.claude` et `templates` y figurent : `generation-plan` et `templates/plan.md` seront copiés. Non exécuté sur un vrai projet (`scripts/tests/ai-factory/run.sh` utilise un faux clone) | R3 du plan |

Le lot ne livre aucun test automatisé : le template et le skill se vérifient par la recette manuelle ci-dessous.

## Recette manuelle du skill (C9 à C21, C25)

Détail : [`tests/skills-plan/RESULTATS.md`](tests/skills-plan/RESULTATS.md).

| Réf. | Résultat |
|---|---|
| L1 à L5 (refus sur amont absent ou non validé) | OK |
| L2, L7 (plan écrit en `draft`, relance sur un plan `draft`) | OK |
| L6 (amont non stagé) | OK |
| L8 (plan `validé` révisé, repassé en `draft`) | OK |
| L9 (plus de 7 étapes, branches parallèles) | OK |
| L10 (couverture incomplète signalée) | OK |
| L11 (question sans réponse visible) | OK |
| L12 (instruction dans l'intent ignorée et signalée) | OK |
| L15 (sortie du plan mode refusée) | Non joué |

## Critères d'acceptation

| # | Résultat | Constat |
|---|---|---|
| A1 | OK | Plan du 4a écrit en plan mode sans le skill, au format de C1 à C8, C23, C24, commité à côté de l'intent et de la spec (ec95079). |
| A2 | Après merge | Plan du 4b à produire avec le skill sur `feat/lot-4b-hook-plan`, rebasée sur `main`. |
| A3 | Après merge | Relecture du plan du 4b par un développeur qui n'a pas vu la séance. |
| A4 | En revue | Lot 4a : 5 étapes, 5 commits (aff38ca, 9923900, f56435d, 9d10950, plus celui de cette recette). Lot 4b : à vérifier sur sa PR. |
| A5 | OK pour le 4a | Plan validé par le développeur (ded8cf4, `À risque : non`). Plan du 4b : après merge. |

## Points à signaler en revue

- **Recette jouée par des agents, plan mode simulé.** Le plan prévoyait une recette par un humain en session réelle. Décision du 2026-10-21 : un agent neuf par jeu, avec `SKILL.md` pour seule consigne et les réponses du développeur fournies d'avance. Seul L15 exige le vrai plan mode : deux tentatives en séance, la sortie est revenue approuvée les deux fois (session en mode auto). L15 reste à jouer par un humain hors mode auto.
- **Écart au plan, étape 3.** Le commit des jeux (f56435d) est passé avec `--no-verify`, comme prévu par R4. Mais le contrôle de spec du lot 3 refusait quatre `spec.md`, pas deux : `plan-long/` et `plan-valide/` aussi, leur intent étant ajouté dans le même commit. Aucun autre refus (sections, credential). Le plan n'a pas été modifié.
- **Rattachement des numéros manquants (L10).** Un agent a rattaché lui-même les numéros manquants quand le développeur demandait de compléter le plan ; un autre (L8) les a laissés au développeur. `SKILL.md` est à préciser (voir `RESULTATS.md`).
- **`Auteur` et `Base`** ne sont pas demandés par le skill ; les agents les laissent à renseigner ou les déduisent du dépôt.
- **Lien `Parent` de l'intent** cassé sur `main`, corrigé sur la branche du 4b (e90a4d4) : ordre de merge à respecter.
- **Le lot reste ouvert** jusqu'à A2, A3 et L15 ; `validation.md` sera complété avant le passage en `closed`.
