# Spec — Lot 1h : Livrables rangés à la racine

- **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **Validation :** Tech lead

## Périmètre

Déplacer les tests automatisés des hooks git des lots 2 et 3 depuis le dossier de leur lot vers `hooks/tests/hook-intent/` et `hooks/tests/hook-spec/`, avec `git mv` et sans changer leur contenu. Mettre à jour toutes les références à leurs anciens chemins, artefacts des lots fermés compris. Écrire dans le `README.md` la règle de rangement : les tests d'un livrable dans `<dossier du livrable>/tests/<nom>/`, les tests d'exigence dans le dossier du lot. Les jeux de données de recette des skills restent où ils sont.

## Comportements

### Tests déplacés (`hooks/tests/`)

- **C1.** `requirements/closed/02-intent/tests/hook-intent/` (`run.sh` et `fixtures/`) est déplacé vers `hooks/tests/hook-intent/`, et `requirements/closed/03-spec/tests/hook-spec/` vers `hooks/tests/hook-spec/`. Les noms des dossiers sont conservés.
- **C2.** Les déplacements se font avec `git mv`, dans un commit qui ne contient que des renommages, pour que git les détecte comme tels (similarité 100 %) et que `git log --follow` remonte l'historique de chaque fichier.
- **C3.** Le contenu des `run.sh` et des fixtures ne change pas, mode exécutable (`100755`) des `run.sh` compris. Les deux scripts résolvent déjà leurs chemins à partir de leur emplacement (`dirname "$0"`) et de la racine du dépôt (`git rev-parse --show-toplevel`) : aucun chemin interne n'est à adapter.
- **C4.** Les dossiers `tests/` des lots 2 et 3 ne contiennent plus que les jeux de données de recette des skills : `skills-intent/` pour le lot 2, `skills-spec/` (avec `RESULTATS.md`) pour le lot 3.
- **C5.** `hooks/tests/` n'a aucun effet sur l'exécution des hooks : avec `core.hooksPath hooks`, git ne lance que les fichiers nommés comme un hook (`hooks/pre-commit`).

### Documentation (`README.md`)

- **C6.** Le tableau « Ce que contient le dépôt » remplace les lignes `requirements/closed/02-intent/tests/` et `requirements/closed/03-spec/tests/` par une ligne `hooks/tests/` (tests des hooks git) et une ligne pour les jeux de données de recette des skills, laissés dans leur lot.
- **C7.** Les commandes de « Mise en route » (étape 3) et de « Vérifier » citent `bash hooks/tests/hook-intent/run.sh` et `bash hooks/tests/hook-spec/run.sh`.
- **C8.** Le README énonce la règle de rangement : les tests automatisés d'un livrable vont dans `<dossier du livrable>/tests/<nom>/` (`run.sh` et `fixtures/`), à un chemin indépendant du lot qui l'a produit. Exemples : `hooks/tests/<nom>/`, `.claude/hooks/tests/<nom>/`, `scripts/tests/<nom>/`. Seuls les tests d'exigence (recette des critères d'acceptation d'un lot, jeux de données des skills compris) restent dans le dossier du lot.

### Références mises à jour

- **C9.** Le plan du lot 1a (`requirements/in-progress/01a-contexte/plan.md`, section Commandes) cite les nouveaux chemins.
- **C10.** Le plan et la spec du lot 3 (`requirements/closed/03-spec/plan.md`, `spec.md`) citent `hooks/tests/hook-spec/` et `hooks/tests/hook-intent/` à la place de `tests/hook-spec/` et `tests/hook-intent/`, relatifs au lot. Les mentions de `tests/skills-spec/` et `tests/skills-intent/` ne changent pas (C4).
- **C11.** Après le lot, `git grep -nP '(?<!hooks/)tests/hook-(intent|spec)'` ne renvoie aucune ligne, hors exceptions tranchées en P1 et P2.

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Renommage ou déplacement d'un dossier de lot (`open/` → `in-progress/` → `closed/`) | Les `run.sh` de `hooks/tests/` restent au vert et aucun lien vers eux n'est à corriger (C1, C3) |
| L2 | Déplacement mêlé à une modification de contenu dans le même commit | À éviter : git peut ne plus détecter le renommage et `--follow` perd l'historique (C2) |
| L3 | Hooks activés (`core.hooksPath hooks`) avec le nouveau dossier `hooks/tests/` | Aucun effet : seul `hooks/pre-commit` est lancé par git (C5) |
| L4 | Lancement d'un `run.sh` depuis un autre répertoire que la racine | Il passe : les chemins sont résolus depuis l'emplacement du script (C3) |
| L5 | Agent sur une branche `bugfix/…` une fois le lot 1g livré | Les fichiers de `hooks/tests/` sont sous un dossier `tests/` et sont protégés comme les autres (spec 1g, C2 et L8) |
| L6 | Le lot 1b est implémenté avant d'avoir révisé sa spec (C2 de 1b : découverte des `run.sh` dans les dossiers de lots) | `scripts/verifier.sh` ne trouve pas `hooks/tests/` : hors périmètre de ce lot, à traiter par la révision de la spec 1b |
| L7 | Les mots `tests/hook-intent` et `tests/hook-spec` restent dans des textes qui décrivent l'ancien emplacement (intent et spec du lot 1h) | Voir P1 |

## Contrats

- **Tests des hooks git :** `bash hooks/tests/hook-intent/run.sh` et `bash hooks/tests/hook-spec/run.sh`, depuis n'importe quel répertoire du dépôt. Sortie inchangée : une ligne `PASS <nom>` ou `FAIL <nom>` par cas, code 0 si tout passe.
- **Recherche des anciens chemins :** `git grep -nP '(?<!hooks/)tests/hook-(intent|spec)'`, sans résultat hors exceptions P1 et P2.
- **Historique :** `git log --follow --oneline hooks/tests/hook-intent/run.sh` (et de même pour les autres fichiers) montre des commits antérieurs au déplacement.

## Critères d'acceptation

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Tests déplacés avec leur historique | Le lot livré | On liste `hooks/tests/hook-intent/` et `hooks/tests/hook-spec/`, puis on lance `git log --follow` sur chaque `run.sh` et une fixture de chaque dossier | Chaque dossier contient `run.sh` et `fixtures/` ; l'historique remonte aux commits des lots 2 et 3 | Automatisé |
| A2 | Tests des hooks au vert depuis `hooks/tests/` | Le lot livré | On lance `bash hooks/tests/hook-intent/run.sh` puis `bash hooks/tests/hook-spec/run.sh` | Uniquement des lignes `PASS`, code de sortie 0 pour chacun | Automatisé |
| A3 | Indépendance vis-à-vis du dossier de lot | Le lot livré, arbre de travail propre | On renomme un dossier de lot (`git mv requirements/closed/03-spec requirements/closed/03-spec-x`), on relance les deux `run.sh`, puis on annule le renommage | Les deux `run.sh` restent au vert | Automatisé |
| A4 | Plus aucune référence aux anciens chemins | Le lot livré | On lance `git grep -nP '(?<!hooks/)tests/hook-(intent\|spec)'` | Aucune ligne, hors exceptions P1 et P2 ; `README.md`, plan du lot 1a, plan et spec du lot 3 compris | Automatisé |
| A5 | La règle de rangement est documentée | Le `README.md` du lot | On le relit | Il énonce la règle de C8 (livrable et tests dans `<dossier du livrable>/tests/<nom>/`, tests d'exigence dans le dossier du lot) et ses commandes citent `hooks/tests/` | Humain |
| A6 | Les jeux de données des skills restent dans leur lot | Le lot livré | On liste `requirements/closed/02-intent/tests/` et `requirements/closed/03-spec/tests/` | Ils contiennent `skills-intent/` et `skills-spec/` (avec `RESULTATS.md`), et plus `hook-intent/` ni `hook-spec/` | Automatisé |

## Points d'attention

- **P1 — L'intent et la spec du lot 1h citent les anciens chemins.** Le Problème de l'intent décrit l'emplacement d'origine, et cette spec le cite pour décrire le déplacement. Le critère « `git grep` ne renvoie rien » de l'intent les attrape. Proposition : exclure `requirements/*/01h-livrables-racine/` de la recherche, puisque ces textes décrivent l'état d'avant. Décideur : tech lead.
- **P2 — Le plan et la spec du lot 1c citent aussi les anciens chemins.** `01c-hook-credential/plan.md` (étape 2 : « sur le modèle de `requirements/closed/02-intent/tests/hook-intent/run.sh` ») et `spec.md` (C10 : « sur le modèle de `tests/hook-spec/run.sh` »). L'intent veut des références à jour « partout » (Résultat attendu, critère `git grep`), mais met la révision de la spec 1c hors périmètre. Deux options : corriger ici ces seuls renvois « sur le modèle de », qui ne changent pas le comportement de 1c, ou les laisser à la révision de 1c et les exclure de la recherche. Décideur : tech lead.
- **P3 — `CLAUDE.md` du lot 1a sur une branche non mergée.** `CLAUDE.md` (section Commandes) et le `README.md` de `feat/lot-01a-contexte` citent les anciens chemins. `CLAUDE.md` n'existe pas sur `main`, donc ce lot ne peut pas le corriger. Le lot mergé en second adapte les chemins. Si c'est 1a, sa recette (L1 de la spec 1a) le signale. Décideur : tech lead.
- **P4 — Lot 3 fermé modifié.** Corriger le plan et la spec d'un lot fermé (C10) réécrit des artefacts déjà validés. L'intent l'impose (« artefacts des lots fermés compris »). La spec du lot 3 garde son statut `validé`, puisque seuls des chemins changent. Décideur : tech lead, s'il veut une revalidation.
- **P5 — Aucun skill de standards.** Aucun skill de conventions dans `.claude/skills/` ne fixe le rangement des tests. Le README (C8) devient la seule source de la règle. Décideur : tech lead.

## Hors périmètre

- Écriture de nouveaux tests.
- Modification du comportement des hooks ou des skills.
- Commande unique de vérification (lot 1b).
- Révision des specs et plans de 1b (C2, découverte des `run.sh` dans les dossiers de lots), 1c (C10, A4 : `tests/hook-credential/`) et 1f (C11 : `tests/hook-activation/`) : chaque lot révise sa spec avant son implémentation et la fait revalider par le tech lead. Les renvois « sur le modèle de » du lot 1c sont l'objet de P2.
- Déplacement des jeux de données de recette des skills, qui restent dans leur lot.
- Chemin périmé `requirements/open/01-socle` dans `skills-intent/README.md` (R5 du plan 1a).

## Questions ouvertes
