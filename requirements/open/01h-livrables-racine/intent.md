# Sous-intent — Lot 1h : Livrables rangés à la racine

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **Date :** 2026-10-19
- **Validation :** Tech lead
- **Dépend de :** —
- **Origine :** constat fait pendant le lot 1a, à traiter avant de le terminer

## Problème

Les tests automatisés des hooks, livrables qui restent en service après la clôture de leur lot, sont rangés dans le dossier du lot : `requirements/closed/02-intent/tests/hook-intent/` et `requirements/closed/03-spec/tests/hook-spec/`. Leur chemin change à chaque déplacement du lot (`open/` → `in-progress/` → `closed/`) ou à son renommage. Il faut alors chercher dans tout le dépôt les fichiers qui les citent pour corriger les liens : `README.md`, `CLAUDE.md` du lot 1a, plans et specs d'autres lots.

## Pour qui

- **Équipe** : déplace et renomme les lots sans corriger de liens vers les livrables.
- **Agent** : trouve les tests d'un livrable à côté du livrable, à un chemin qui ne change pas.
- **Tech lead** : valide la nouvelle organisation.
- **Lots 1a, 1b, 1c, 1f** : citent ou prévoient des tests sous `requirements/` (voir « Questions ouvertes »).

## Pourquoi

Chaque déplacement de lot casse des liens et oblige à une recherche manuelle dans le dépôt. Un lien oublié laisse une commande qui ne s'exécute plus (cas L1 de la spec 1a) ou une documentation fausse.

## Priorité

- **Niveau :** Haute
- **Justification :** À traiter avant de terminer le lot 1a, dont la section Commandes de `CLAUDE.md` cite ces chemins.
- **Échéance :** aucune

## Résultat attendu

- Les livrables et leurs tests automatisés sont rangés à la racine du projet, à un chemin indépendant du lot qui les a produits. Les tests des hooks git vont dans `hooks/tests/<nom>/` (`run.sh` et `fixtures/`).
- Seuls les tests des exigences (recette des critères d'acceptation d'un lot) restent dans le dossier du lot, à côté de son intent.
- Les références aux anciens chemins sont mises à jour.

## Critère de succès

- Déplacer ou renommer un dossier de lot ne demande de corriger aucun lien vers un livrable ou ses tests automatisés.
- Les tests des hooks git s'exécutent depuis `hooks/tests/` et sont tous `PASS`.

## Contraintes

- Les fichiers sont déplacés avec `git mv`, pour garder leur historique.
- Le contenu des tests ne change pas : seuls leur emplacement et les chemins qu'ils utilisent changent.
- Un lot = un sous-intent = une PR.

## Hors périmètre

- Écriture de nouveaux tests.
- Modification du comportement des hooks ou des skills.
- Commande unique de vérification (lot 1b).

## Questions ouvertes

- Les jeux de données de recette des skills (`requirements/closed/02-intent/tests/skills-intent/`, `requirements/closed/03-spec/tests/skills-spec/` avec `RESULTATS.md`) sont-ils des livrables, à ranger à la racine, ou des tests d'exigence, à laisser dans le lot ? À trancher plus tard.
- Les specs validées de 1b, 1c et 1f placent leurs tests ou leur découverte sous `requirements/` : 1b (C2, découverte des `run.sh` dans les dossiers de lots), 1c (C10, A4 : `tests/hook-credential/` du lot) et 1f (C11 : `tests/hook-activation/`). Qui les révise : ce lot, ou chaque lot avant son implémentation ? Une spec révisée repasse par la validation du tech lead.
- Où vont les tests des futurs livrables qui ne sont pas des hooks git (hooks Claude Code de `.claude/hooks/` du lot 1f, `scripts/verifier.sh` du lot 1b) ?
- Critères d'acceptation du lot : à préciser.
