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
- **Lot 1a** : les commandes de son `CLAUDE.md` et son plan citent les tests des hooks ; ce lot met à jour son plan.
- **Lots 1b, 1c, 1f** : leurs specs placent des tests ou leur découverte sous `requirements/` ; ils appliquent la règle en révisant leur spec.

## Pourquoi

Chaque déplacement de lot casse des liens et oblige à une recherche manuelle dans le dépôt. Un lien oublié laisse une commande qui ne s'exécute plus (cas L1 de la spec 1a) ou une documentation fausse.

## Priorité

- **Niveau :** Haute
- **Justification :** À traiter avant de terminer le lot 1a, dont la section Commandes de `CLAUDE.md` cite ces chemins.
- **Échéance :** aucune

## Résultat attendu

- Règle : les tests automatisés d'un livrable sont rangés à côté du livrable, dans `<dossier du livrable>/tests/<nom>/` (`run.sh` et `fixtures/`), à un chemin indépendant du lot qui l'a produit. Par exemple `hooks/tests/<nom>/` pour les hooks git, `.claude/hooks/tests/<nom>/` pour les hooks Claude Code (lot 1f), `scripts/tests/<nom>/` pour les scripts (lot 1b).
- Les tests des hooks git des lots 2 et 3 sont déplacés vers `hooks/tests/hook-intent/` et `hooks/tests/hook-spec/` (noms conservés).
- Seuls les tests des exigences (recette des critères d'acceptation d'un lot) restent dans le dossier du lot, à côté de son intent. Les jeux de données de recette des skills (`skills-intent/` du lot 2, `skills-spec/` et `RESULTATS.md` du lot 3) en font partie et restent dans leur lot.
- Les références aux anciens chemins sont mises à jour partout, artefacts des lots fermés compris.
- Le `README.md` décrit la règle.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.
- Déplacer ou renommer un dossier de lot ne demande de corriger aucun lien vers un livrable ou ses tests automatisés.
- Les tests des hooks git s'exécutent depuis `hooks/tests/` et sont tous `PASS`.

## Livrables

| Type | Élément |
|---|---|
| Tests | `hooks/tests/hook-intent/` et `hooks/tests/hook-spec/` (`run.sh` et `fixtures/`), déplacés depuis les lots 2 et 3 |
| Documentation | `README.md` : règle de rangement des tests, chemins des commandes de vérification |
| Références | Chemins mis à jour dans le plan du lot 1a, le plan et la spec du lot 3 |

## Critère d'acceptation

- [ ] `hooks/tests/hook-intent/` et `hooks/tests/hook-spec/` contiennent `run.sh` et `fixtures/`, déplacés avec `git mv` : `git log --follow` montre leur historique.
- [ ] `bash hooks/tests/hook-intent/run.sh` et `bash hooks/tests/hook-spec/run.sh` affichent uniquement des lignes `PASS` et sortent en 0.
- [ ] Après renommage d'un dossier de lot (par exemple `git mv requirements/closed/03-spec requirements/closed/03-spec-x`), les deux `run.sh` restent au vert.
- [ ] Une recherche `git grep` des anciens chemins (`tests/hook-intent` et `tests/hook-spec` hors de `hooks/tests/`) ne renvoie rien, `README.md`, plan du lot 1a et artefacts du lot 3 compris.
- [ ] Le `README.md` décrit la règle : un livrable et ses tests dans `<dossier du livrable>/tests/<nom>/`, les tests d'exigence dans le dossier du lot.
- [ ] `skills-intent/` et `skills-spec/` sont toujours dans le dossier de leur lot.

## Contraintes

- Les fichiers sont déplacés avec `git mv`, pour garder leur historique.
- Le contenu des tests ne change pas : seuls leur emplacement et les chemins qu'ils utilisent changent.
- Un lot = un sous-intent = une PR.

## Hors périmètre

- Écriture de nouveaux tests.
- Modification du comportement des hooks ou des skills.
- Commande unique de vérification (lot 1b).
- Révision des specs et plans de 1b (C2, découverte des `run.sh` dans les dossiers de lots), 1c (C10, A4 : `tests/hook-credential/`) et 1f (C11 : `tests/hook-activation/`) : chaque lot révise sa spec avant son implémentation et la fait revalider par le tech lead.
- Déplacement des jeux de données de recette des skills, qui restent dans leur lot.
- Chemin périmé `requirements/open/01-socle` dans `skills-intent/README.md` (R5 du plan 1a).

## Questions ouvertes
