# Spec — Lot 1b : Commande de vérification

- **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **Validation :** Tech lead

## Périmètre

Une commande unique, `scripts/verifier.sh`, lancée depuis la racine d'`ai-factory`, qui découvre et exécute tous les `run.sh` du dépôt (tests des livrables rangés dans `<dossier du livrable>/tests/<nom>/`, tests d'exigence restés dans le dossier d'un lot), affiche le résultat de chacun et sort en erreur si l'un échoue. Elle sert à l'agent, à l'équipe, au lot 1e (qui la documente dans `CLAUDE.md`) et au lot 5 (qui l'exige au vert avant une PR). Ni build, ni lint, ni recettes manuelles, ni CI.

## Comportements

### Script de vérification

- **C1.** La commande est `scripts/verifier.sh`. Elle se lance depuis la racine du dépôt, sans argument.
- **C2.** Elle découvre les `run.sh` à l'exécution, en parcourant toute l'arborescence du dépôt depuis la racine. Aucune liste de tests ni aucun dossier n'est écrit dans le script : un `run.sh` ajouté à côté d'un livrable (`hooks/tests/`, `.claude/hooks/tests/`, `scripts/tests/`…) ou dans le dossier d'un lot, ou un dossier déplacé, est pris en compte sans modifier le script. La commande ne dépend pas de `requirements/` : elle fonctionne dans un nouveau projet copié sans ce dossier.
- **C3.** Elle lance chaque `run.sh` trouvé, dans un ordre stable (tri par chemin), même si un précédent a échoué.
- **C4.** Elle affiche, pour chaque `run.sh`, son chemin et son résultat (succès ou échec), en conservant la sortie du `run.sh` (lignes `PASS` / `FAIL`).
- **C5.** Elle termine par un récapitulatif : nombre de `run.sh` lancés, nombre en échec, et chemin de chaque `run.sh` en échec.
- **C6.** Code de sortie : 0 si tous les `run.sh` sortent en 0 ; différent de 0 si au moins un échoue.
- **C7.** Un `run.sh` est en échec quand son code de sortie est différent de 0. La commande ne réinterprète pas sa sortie.
- **C8.** La commande ne modifie pas le dépôt : chaque `run.sh` travaille dans son propre dépôt temporaire (modèle des tests de `hooks/tests/`).
- **C9.** Lancée ailleurs qu'à la racine du dépôt, la commande refuse avec un message qui donne la commande à lancer depuis la racine, et sort en erreur.
- **C10.** Si la découverte ne trouve aucun `run.sh`, la commande le signale et sort en erreur : un déplacement de dossier ne doit pas passer au vert en silence.
- **C11.** Tous les `run.sh` trouvés sont lancés, y compris sous un dossier `fixtures/`, un dossier caché (`.claude/`) ou un fichier pas encore suivi par git : la découverte n'exclut que le dossier `.git/`.

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Un livrable ajoute `<dossier du livrable>/tests/<nom>/run.sh` après coup | Lancé à l'exécution suivante sans changement du script (C2) |
| L2 | Un lot passe de `in-progress/` à `closed/`, ou le dossier d'un livrable est renommé | Les `run.sh` qu'il contient restent trouvés, à leur nouvel emplacement (C2) |
| L3 | Deux `run.sh` en échec | Les deux sont lancés et nommés dans le récapitulatif, sortie ≠ 0 (C3, C5) |
| L4 | Un `run.sh` sans bit exécutable | Lancé quand même (via `bash`), comme dans le README actuel |
| L5 | Aucun `run.sh` trouvé | Message, sortie en erreur (C10) |
| L6 | Un `run.sh` placé dans un dossier `fixtures/` | Lancé comme les autres (C11) |
| L7 | Lancement depuis un sous-dossier | Refus avec message, sortie en erreur (C9) |
| L8 | Nouveau projet copié sans `requirements/` (règle du lot 1h) | Les `run.sh` de `hooks/tests/` sont trouvés et lancés, la commande passe au vert (C2) |
| L9 | `run.sh` pas encore commité, ou sous un dossier ignoré par un `.gitignore` global (règle `.*/`, cas de `.claude/`) | Lancé quand même : la découverte lit le système de fichiers, pas l'index git (C11) |
| L10 | Fichier nommé `run.sh` sous `.git/` | Ignoré (C11) |

## Contrats

- **Commande :** `scripts/verifier.sh`, sans argument, depuis la racine d'`ai-factory` (refus ailleurs, C9).
- **Sortie standard :** pour chaque `run.sh`, son chemin puis sa sortie ; puis le récapitulatif de C5.
- **Code de sortie :** 0 si tout passe, différent de 0 si un `run.sh` échoue, si aucun n'est trouvé ou si la commande n'est pas lancée depuis la racine.
- **Contrat des `run.sh` de lot :** script bash autonome, lancé par `bash <chemin>`, code de sortie 0 en cas de succès, une ligne `PASS <nom>` ou `FAIL <nom>` par test (format des tests de `hooks/tests/`).
- **Consommateurs :** lot 1e (documentation dans `CLAUDE.md`), lot 5 (hook « commande au vert avant ouverture de PR »).

## Critères d'acceptation

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Tous les `run.sh` présents sont lancés | Le dépôt avec les `run.sh` de `hooks/tests/hook-intent/` et `hooks/tests/hook-spec/` | On lance la commande | Les deux `run.sh` sont lancés et nommés dans la sortie | Manuel |
| A2 | Un `run.sh` ajouté après coup est lancé sans modifier le script | Un `run.sh` qui sort en 0 ajouté dans le `tests/` d'un livrable (par exemple `scripts/tests/<nom>/`) | On relance la commande, script inchangé | Ce `run.sh` est lancé et nommé dans la sortie | Manuel |
| A3 | Sortie 0 quand tout passe | Tous les `run.sh` sortent en 0 | On lance la commande | Code de sortie 0 | Manuel |
| A4 | Sortie en erreur et test nommé quand un test échoue | Un `run.sh` qui sort en erreur ajouté dans le `tests/` d'un livrable ou d'un lot | On lance la commande | Code de sortie ≠ 0, et le récapitulatif nomme ce `run.sh` | Manuel |

## Points d'attention

- **P1 — Pas de tests automatisés de la commande.** Décision du 2026-10-16 : le lot 1b ne livre pas de `run.sh` pour la commande elle-même. A1 à A4 se vérifient à la main, et une régression de la commande ne sera détectée qu'à l'usage. Décideur : tech lead.
- **P3 — Pas de CI.** Le PO a confirmé l'absence de CI sur `ai-factory` ; le lot 13 est suspendu tant qu'aucune CI n'existe. Le valideur « CI » du lot 5 dans `ia-factory.md` en suppose toujours une. Décideur : PO.
- **P4 — Aucun skill de standards.** Aucun skill de conventions (nommage, emplacement des scripts) n'existe dans `.claude/skills/`. Le `README.md` (règles de rangement du lot 1h) est la seule source de l'emplacement des tests. Décideur : tech lead.
- **P5 — Révision après le lot 1h.** Le lot 1h a sorti les tests de `requirements/` (`hooks/tests/`) et range ceux d'un livrable dans `<dossier du livrable>/tests/<nom>/`. C2 (découverte dans les dossiers de lots) laissait `scripts/verifier.sh` sans aucun `run.sh` à lancer (L6 de la spec 1h). Révisés : Périmètre, C2, C8, C11, L1, L2, contrat des `run.sh`, A1, A2, A4 ; ajoutés : L8 à L10. L'intent parle encore des « `run.sh` des lots » (Livrables) ; son Résultat attendu (« toutes les vérifications automatisées d'`ai-factory` ») couvre la découverte dans tout le dépôt, l'intent n'est donc pas modifié. La spec repasse en `draft` pour revalidation. Décideur : tech lead.

## Hors périmètre

- Documentation de la commande et règle « vérifier avant de déclarer fini » dans `CLAUDE.md` (lot 1e).
- Hook qui bloque l'édition des tests pendant un correctif (nouveau sous-lot 1g, décision du 2026-10-16).
- Hook « commande au vert avant ouverture de PR » (lot 5).
- Build et lint : `ai-factory` n'en a pas aujourd'hui.
- Recettes manuelles des skills (`skills-intent`, `skills-spec`).
- Mise en place d'une CI : aucune n'est prévue sur `ai-factory`.
- Règles transverses bloquantes (lot 1c).

## Questions ouvertes

