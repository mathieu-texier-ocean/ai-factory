# Intent : IA Factory — SDLC natif IA pour l'équipe de développement

- **Auteur :** Khaled KORIFI
- **Statut :** draft
- **Date :** 2026-10-13
- **Dépôt :** `ai-sdlc` (outillage IA Factory)
- **Projet pilote :** « activation en masse »

## Problème

Le délai entre l'ouverture d'une PR et sa mise en production est d'environ 10,7 jours en moyenne. Le code n'est plus le goulot : l'attente se concentre sur la revue de code et la recette humaine.

Le savoir de l'équipe (conventions, pièges récurrents, règles de sécurité) vit dans les têtes et n'est pas appliqué de façon homogène, ce qui allonge les allers-retours en revue.

## Résultat attendu

Une chaîne SDLC natif IA outillée dans `ai-sdlc`, où chaque étape produit un artefact versionné que l'étape suivante lit :

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
| 0. Mesure | [lot-00-mesure.md](lot-00-mesure.md) | — | — |
| 1. Socle | [lot-01-socle.md](lot-01-socle.md) | Tech lead | — |
| 2. Intent | [lot-02-intent.md](lot-02-intent.md) | PO | 1 |
| 3. Spec | [lot-03-spec.md](lot-03-spec.md) | Tech lead, PO en copie | 2 |
| 4. Plan | [lot-04-plan.md](lot-04-plan.md) | Tech lead | 3 |
| 5. Code + tests | [lot-05-code-tests.md](lot-05-code-tests.md) | CI | 1, 4 |
| 6. Revue PR | [lot-06-revue-pr.md](lot-06-revue-pr.md) | Humain | 5 |
| 7. Recette | [lot-07-recette.md](lot-07-recette.md) | Recette | 3 |
| 8. Monitoring | [lot-08-monitoring.md](lot-08-monitoring.md) | Tech lead | 0 |
| 9. Auto-apprentissage | [lot-09-auto-apprentissage.md](lot-09-auto-apprentissage.md) | Humain (PR) | 8 |

Les lots 0 et 1 démarrent en parallèle. Un premier passage minimal sur les lots 2 à 7 fait traverser toute la chaîne à une PR « activation en masse », puis chaque étape est enrichie.
