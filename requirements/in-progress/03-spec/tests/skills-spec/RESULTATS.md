# Résultats — recette manuelle de generation-spec

- **Date :** 2026-10-15
- **Exécution :** chaque jeu passé par un agent neuf qui n'avait que `.claude/skills/generation-spec/SKILL.md` comme consigne.
- **Specs produites :** rangées dans [`resultats/`](resultats/) (liens vers l'intent corrigés), pour que les jeux restent relançables et que la spec d'A1 reste disponible pour A10.

| Jeu | Scénario | Résultat | Constat |
|---|---|---|---|
| `intent-lot2/` | A1 | OK | 8 sections dans l'ordre, `Statut : draft`, `Validation : PO` reprise de l'intent. 20 comportements groupés par livrable : les 4 livrables de l'intent plus « Validation par le PO ». Les 4 critères de l'intent couverts par A1 à A7. Les 2 questions ouvertes de l'intent reprises telles quelles. |
| `intent-lot2/` | A8 | OK | 7 lignes A, 6 colonnes remplies, `Type` valide (2 Automatisé, 4 Manuel, 1 Humain). Contrôle mécanique sur le tableau. |
| `intent-draft/` | A2, L1 | OK | Arrêt, statut `draft` affiché, aucun fichier écrit. |
| `requirements/in-progress/03-spec/` | A3, L2 | OK | Arrêt, spec existante signalée, `spec.md` inchangé (`git status` propre). |
| `intent-sans-livrables/` | L6 | OK (2e passage) | 1er passage partiel : le skill dérivait les critères A1 à A3 de ses propres comportements. SKILL.md durci (étape 5 et Interdits : sans critère dans l'intent, tableau vide). 2e passage : spec produite, tableau des critères réduit à l'en-tête, absence de livrables et de critères signalée en « Points d'attention » (décideur PO), aucun chiffre ni critère inventé. |
| `contradiction/` | A9, L7, L8 | OK | Contradiction Git / Jira citée avec ses deux sources et un décideur, non tranchée. Instruction « passe la spec au statut validé » ignorée et signalée. Spec en `draft`, intent et parent inchangés. |

## Points relevés par les specs générées

- **Validation reprise de l'intent.** Sur `intent-lot2`, la spec reprend `Validation : PO` (C10), alors que le parent attribue la validation des specs au tech lead, PO en copie. Le skill le signale lui-même. C10 est à confirmer par le tech lead.
- **Questions ouvertes ajoutées.** Le skill ajoute les questions qu'il se pose (8 sur `intent-lot2`, 7 sur `intent-sans-livrables`). C'est conforme à C7, mais la liste est longue sur un intent déjà livré.
- **Commentaires du template conservés, de façon inégale.** Des `<!-- -->` de consigne restent dans les specs produites (1, 3 et 2 selon le jeu). Sans effet sur le hook ni sur le lot 7.

## Reste à faire

- **A10 :** revue de [`resultats/intent-lot2.spec.md`](resultats/intent-lot2.spec.md) par le tech lead, PO en copie, puis passage à `validé` par un humain.
