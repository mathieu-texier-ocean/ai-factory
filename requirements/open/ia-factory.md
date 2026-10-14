# Intent : IA Factory — SDLC natif IA pour l'équipe de développement

- **Auteur :** Khaled KORIFI
- **Statut :** draft
- **Date :** 2026-10-13
- **Dépôt :** `ai-factory` (outillage IA Factory)
- **Projet pilote :** « activation en masse »

## Problème

Le délai entre l'ouverture d'une PR et sa mise en production est d'environ 10,7 jours en moyenne. Le code n'est plus le goulot : l'attente se concentre sur la revue de code et la recette humaine.

Le savoir de l'équipe (conventions, pièges récurrents, règles de sécurité) vit dans les têtes et n'est pas appliqué de façon homogène, ce qui allonge les allers-retours en revue.

## Résultat attendu

Une chaîne SDLC natif IA outillée dans `ai-factory`, où chaque étape produit un artefact versionné que l'étape suivante lit :

`intent.md` → `spec.md` → `plan.md` → diff + tests → PR revue → production

## Critère de succès

- Délai PR → production divisé par deux sur le pilote (cible ≈ 5 jours, référence 10,7 jours).
- Indicateurs suivis : temps jusqu'à la première revue, taux de succès CI au premier passage, nombre de cycles de reprise par PR, taux d'échec des changements en production.

## Contraintes

- Démarrage sur un seul dépôt pilote avant toute généralisation.
- Un lot = un sous-intent = une PR.
- L'agent ne franchit pas la porte de production : approbation humaine obligatoire (branch protection, code owner).
- Aucune donnée sensible ni secret dans le contexte de l'agent.
- Source de vérité des artefacts : Git (test sans Jira).

## Hors périmètre (pilote)

- Déploiement autonome en production.
- Boucle de maintenance autonome (Stage 6).
- Extension aux autres équipes ou dépôts.

## Sous-intents

| Lot | Fichier | Validation | Dépend de |
|---|---|---|---|
| 0. Mesure | [00-mesure/intent.md](00-mesure/intent.md) | — | — |
| 1. Socle | [01-socle/intent.md](01-socle/intent.md) | Tech lead | — |
| 2. Intent | [02-intent/intent.md](02-intent/intent.md) | PO | — |
| 3. Spec | [03-spec/intent.md](03-spec/intent.md) | Tech lead, PO en copie | 2 |
| 4. Plan | [04-plan/intent.md](04-plan/intent.md) | Tech lead | 3 |
| 5. Code + tests | [05-code-tests/intent.md](05-code-tests/intent.md) | CI | 1, 4 |
| 6. Revue PR | [06-revue-pr/intent.md](06-revue-pr/intent.md) | Humain | 5 |
| 7. Recette | [07-recette/intent.md](07-recette/intent.md) | Recette | 3 |
| 8. Monitoring | [08-monitoring/intent.md](08-monitoring/intent.md) | Tech lead | 0 |
| 9. Auto-apprentissage | [09-auto-apprentissage/intent.md](09-auto-apprentissage/intent.md) | Humain (PR) | 8 |

Les lots 0, 1 et 2 démarrent en parallèle. Un premier passage minimal sur les lots 2 à 7 fait traverser toute la chaîne à une PR « activation en masse », puis chaque étape est enrichie.
