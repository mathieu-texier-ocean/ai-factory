# Intent : IA Factory — SDLC natif IA pour l'équipe de développement

- **Auteur :** Khaled KORIFI
- **Statut :** draft
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

## Sous-intents

| Lot | Fichier | Validation | Dépend de |
|---|---|---|---|
| 0. Mesure | [00-mesure/intent.md](00-mesure/intent.md) | — | — |
| 1a. Socle : contexte d'équipe | [01a-contexte/intent.md](../closed/01a-contexte/intent.md) | Tech lead | — |
| 1b. Socle : commande de vérification | [01b-verification/intent.md](../closed/01b-verification/intent.md) | Tech lead | — |
| 1c. Socle : hook credential | [01c-hook-credential/intent.md](../closed/01c-hook-credential/intent.md) | Tech lead | — |
| 1e. Socle : vérifier avant de déclarer fini | [01e-verifier-avant-fini/intent.md](../closed/01e-verifier-avant-fini/intent.md) | Tech lead | 1a, 1b |
| 1f. Socle : activation des hooks git | [01f-activation-hooks/intent.md](../closed/01f-activation-hooks/intent.md) | Tech lead | — |
| 1g. Socle : protection des tests pendant un correctif | [01g-protection-tests/intent.md](../in-progress/01g-protection-tests/intent.md) | Tech lead | 1e, 1f |
| 1h. Socle : livrables rangés à la racine | [01h-livrables-racine/intent.md](../closed/01h-livrables-racine/intent.md) | Tech lead | — |
| 2. Intent | [02-intent/intent.md](../closed/02-intent/intent.md) | PO | — |
| 3. Spec | [../closed/03-spec/intent.md](../closed/03-spec/intent.md) | Tech lead, PO en copie | 2 |
| 4a. Plan : production du plan | [04a-plan/intent.md](04a-plan/intent.md) | Développeur, tech lead si à risque | 3 |
| 4b. Plan : refus d'un plan sans amont validé | [04b-hook-plan/intent.md](04b-hook-plan/intent.md) | Tech lead | 3 |
| 5. Code + tests | [05-code-tests/intent.md](05-code-tests/intent.md) | CI | 1a à 1c, 1e, 1f, 4, 13 |
| 6. Revue PR | [06-revue-pr/intent.md](06-revue-pr/intent.md) | Humain | 5 |
| 7. Recette | [07-recette/intent.md](07-recette/intent.md) | Recette | 3 |
| 8. Monitoring | [08-monitoring/intent.md](08-monitoring/intent.md) | Tech lead | 0 |
| 9. Auto-apprentissage | [09-auto-apprentissage/intent.md](09-auto-apprentissage/intent.md) | Humain (PR) | 8 |
| 13. Contrôle credential en CI (suspendu : pas de CI) | [13-credential-ci/intent.md](13-credential-ci/intent.md) | Tech lead | 1c |
| 14. Retrait du signal 7 | [14-retrait-signal-7/intent.md](14-retrait-signal-7/intent.md) | PO | — |

Les lots 0, 1 (1a à 1c, 1f) et 2 démarrent en parallèle ; 1e suit 1a et 1b, 1g suit 1e et 1f. 13 suivra 1c, mais il est suspendu tant qu'aucune CI n'existe. Un premier passage minimal sur les lots 2 à 7 fait traverser toute la chaîne à une PR de test, puis chaque étape est enrichie.
