# Recette — Lot 1a : Contexte d'équipe

- **Date :** 2026-10-19
- **Exécution :** clone propre de la branche `feat/lot-01a-contexte` (commit 392b6eb, rebasée sur le lot 1h), commandes lancées depuis la racine du clone.

| Critère | Commande ou action | Résultat |
|---|---|---|
| A1 | `wc -l CLAUDE.md` | OK : 41 lignes (≤ 60, cible 45 tenue : 19 lignes libres pour le lot 1e) |
| A2 | `grep -n '^## ' CLAUDE.md` | OK : `Commandes` (l. 3), `Conventions` (l. 13), `Architecture` (l. 24), `Erreurs fréquentes` (l. 33) |
| A3 | Bloc de `## Commandes` extrait de `CLAUDE.md` sans retouche, lancé avec `bash -e` | OK : code de sortie 0, `core.hooksPath` vaut `hooks`, 16 lignes `PASS` et aucune autre sur les deux `run.sh` de `hooks/tests/` |
| A3, copie sans `requirements/` | Même bloc dans une copie du dépôt sans `requirements/`, initialisée comme un nouveau projet (C14 du lot 1h) | OK : code de sortie 0, 16 lignes `PASS` et aucune autre |
| A4 | `grep -n 'deux fois' CLAUDE.md` | OK : règle d'entretien l. 35 |
| Aucun secret (C7, L4) | Relecture, et `grep -niE 'token\|password\|mot de passe\|secret\|https?://[^ ]*@' CLAUDE.md` | OK : seule occurrence, la convention « Aucune donnée sensible ni secret » (l. 18) |
| Aucun renvoi sous `requirements/` (C12 du lot 1h) | `grep -nE 'requirements/(open\|in-progress\|closed)/[0-9]\|ia-factory\.md' CLAUDE.md` | OK : aucune ligne ; restent les dossiers d'état et la convention `requirements/<état>/<NN-lot>/` |
| A5 | PR ouverte par un humain, approbation du code owner de `CLAUDE.md` | À faire |

## Écarts au plan

- **Rebase sur le lot 1h.** Les commandes citent `hooks/tests/hook-intent/run.sh` et `hooks/tests/hook-spec/run.sh`, comme le plan mis à jour par 1h. Conventions reprend les deux règles de rangement ajoutées au README par 1h (C4 : règles reprises du README). La ligne d'erreur fréquente sur les liens cite « la table de l'intent parent » au lieu de `ia-factory.md` (C12 du lot 1h).

## Points à signaler en revue

- **R3 du plan.** Les erreurs fréquentes viennent du README et des pièges constatés par l'équipe, pas encore d'erreurs de l'agent constatées deux fois. À confirmer par le tech lead.
- **R5 du plan.** `requirements/closed/02-intent/tests/skills-intent/README.md` cite toujours `requirements/open/01-socle/intent.md`, découpé en 1a à 1f. Non corrigé (hors périmètre).
