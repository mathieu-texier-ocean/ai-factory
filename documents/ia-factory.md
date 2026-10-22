# IA Factory — SDLC natif IA pour l'équipe de développement

- **Auteur :** Khaled KORIFI
- **Date :** 2026-10-13
- **Dépôt :** `ai-factory` (outillage IA Factory)

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

## Lots

Chaque étape de la chaîne est découpée en lots, rangés sous `requirements/<état>/NN-lot/`. La validation et les dépendances d'un lot se lisent dans l'en-tête de son intent (`Validation`, `Dépend de`).

Grandes lignes : la mesure (0) et le socle (1x : contexte, vérification, hooks) démarrent en parallèle de l'intent (2), puis viennent la spec (3), le plan (4), le code et les tests (5), la revue de PR (6), la recette (7), le monitoring (8) et l'auto-apprentissage (9). Un premier passage minimal sur les lots 2 à 7 fait traverser toute la chaîne à une PR de test, puis chaque étape est enrichie.
