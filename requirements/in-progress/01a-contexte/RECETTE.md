# Recette — Lot 1a : Contexte d'équipe

- **Date :** 2026-10-16
- **Exécution :** clone propre de la branche `feat/lot-01a-contexte` (commit c463ce5), commandes lancées depuis la racine du clone.

| Critère | Commande ou action | Résultat |
|---|---|---|
| A1 | `wc -l CLAUDE.md` | OK : 39 lignes (≤ 60, cible 45 tenue : 21 lignes libres pour le lot 1e) |
| A2 | `grep -n '^## ' CLAUDE.md` | OK : `Commandes` (l. 3), `Conventions` (l. 13), `Architecture` (l. 22), `Erreurs fréquentes` (l. 31) |
| A3 | Bloc de `## Commandes` extrait de `CLAUDE.md` sans retouche, lancé avec `bash -e` | OK : code de sortie 0, `core.hooksPath` vaut `hooks`, 16 lignes `PASS` et aucune autre sur les deux `run.sh` |
| A4 | `grep -n 'deux fois' CLAUDE.md` | OK : règle d'entretien l. 33 |
| Aucun secret (C7, L4) | Relecture, et `grep -niE 'token\|password\|mot de passe\|secret\|https?://[^ ]*@' CLAUDE.md` | OK : seule occurrence, la convention « Aucune donnée sensible ni secret » (l. 18) |
| A5 | PR ouverte par un humain, approbation du code owner de `CLAUDE.md` | À faire |

## Points à signaler en revue

- **R3 du plan.** Les erreurs fréquentes viennent du README et des pièges constatés par l'équipe, pas encore d'erreurs de l'agent constatées deux fois. À confirmer par le tech lead.
- **R5 du plan.** `requirements/closed/02-intent/tests/skills-intent/README.md` cite toujours `requirements/open/01-socle/intent.md`, découpé en 1a à 1f. Non corrigé (hors périmètre).
