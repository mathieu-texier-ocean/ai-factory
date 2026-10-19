# Spec — Lot 1a : Contexte d'équipe

- **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** validé
- **Validation :** Tech lead

## Périmètre

Donner à l'agent, à chaque session, le savoir de l'équipe sur `ai-factory` : un `CLAUDE.md` versionné à la racine du dépôt, court, qui liste les commandes, les conventions, l'architecture et les erreurs fréquentes, avec une règle d'entretien. Le lot ne couvre ni la commande unique de vérification (lot 1b) ni le bloc « vérifier avant de déclarer fini » (lot 1e), qui s'ajoutera à ce même fichier.

## Comportements

### Fichier `CLAUDE.md`

- **C1.** `CLAUDE.md` est à la racine d'`ai-factory`, versionné, et Claude Code le charge à l'ouverture d'une session dans le dépôt.
- **C2.** Il contient quatre sections, chacune avec un titre de niveau 2 : `Commandes`, `Conventions`, `Architecture`, `Erreurs fréquentes`.
- **C3.** `Commandes` liste les commandes qui existent aujourd'hui dans le dépôt, sous une forme exécutable telle quelle depuis la racine : activation des hooks (`git config core.hooksPath hooks`) et lancement des `run.sh` des lots 2 et 3. Aucune commande prévue par un autre lot (1b, 1e) n'y figure tant qu'elle n'existe pas.
- **C4.** `Conventions` reprend les règles déjà écrites dans le README et l'intent parent : un lot = un sous-intent = une PR, cycle `open/` → `in-progress/` → `closed/`, statut `validé` écrit uniquement par un humain, aucune donnée sensible ni secret dans un artefact.
- **C5.** `Architecture` décrit la chaîne `intent.md` → `spec.md` → `plan.md` → diff + tests → PR revue → production et l'emplacement des briques (`templates/`, `.claude/skills/`, `hooks/`, `requirements/`).
- **C6.** `Erreurs fréquentes` liste les pièges déjà constatés sur `ai-factory`. Elle peut démarrer courte : la règle d'entretien (C8) l'alimente.
- **C7.** Le fichier tient sur moins d'une page, soit 60 lignes au plus (`wc -l CLAUDE.md`, décision du 2026-10-16), et ne contient aucune donnée sensible ni secret (contraintes de l'intent).

### Règle d'entretien

- **C8.** `CLAUDE.md` contient la règle : une erreur de l'agent constatée deux fois donne une correction dans `CLAUDE.md`, ajoutée par PR.
- **C9.** Toute modification de `CLAUDE.md` passe par une PR approuvée par son code owner : le tech lead, ou un dev qui a pris la main sur ce rôle (réponse du PO à la question ouverte de l'intent).

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Une commande listée ne s'exécute plus (script déplacé, lot passé en `closed/`) | La commande est corrigée dans `CLAUDE.md` par PR (C3, C8) |
| L2 | Le lot 1e ajoute son bloc « Vérifier son travail » | Le fichier reste sous 60 lignes : le bloc s'ajoute sans dépasser, sinon une section est resserrée (C7) |
| L3 | Une erreur de l'agent constatée une seule fois | Pas de correction obligatoire dans `CLAUDE.md` (C8) |
| L4 | Une commande listée exige un secret ou un identifiant | Interdit : la commande n'est pas listée, ou listée sans la valeur (C7) |
| L5 | Un dev reprend le rôle de code owner | Il approuve les PR sur `CLAUDE.md` à la place du tech lead (C9) |

## Contrats

- **Fichier :** `CLAUDE.md` à la racine, Markdown, sections de niveau 2 `## Commandes`, `## Conventions`, `## Architecture`, `## Erreurs fréquentes`.
- **Lecteurs :** Claude Code (chargement automatique en début de session), l'équipe, le lot 1e (qui y ajoute un bloc) et le lot 5.

## Critères d'acceptation

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | `CLAUDE.md` présent et court | Le dépôt `ai-factory` après merge du lot | On ouvre la racine du dépôt et on lance `wc -l CLAUDE.md` | `CLAUDE.md` est présent et compte 60 lignes au plus | Manuel |
| A2 | Les quatre sections sont présentes | `CLAUDE.md` mergé | On relit ses titres | Les sections Commandes, Conventions, Architecture et Erreurs fréquentes sont présentes | Manuel |
| A3 | Les commandes s'exécutent | Un clone propre d'`ai-factory` | On lance chaque commande de la section Commandes depuis la racine, telle qu'écrite | Chaque commande s'exécute sans modification, et les `run.sh` sont tous `PASS` | Manuel |
| A4 | La règle d'entretien figure dans le fichier | `CLAUDE.md` mergé | On relit le fichier | La règle « erreur constatée deux fois → correction dans `CLAUDE.md` » y figure | Manuel |
| A5 | Ajouté par PR et approuvé par le code owner | La PR qui ajoute `CLAUDE.md` | Revue de la PR | Approbation explicite du tech lead ou du dev qui a pris la main | Humain |

## Points d'attention

- **P2 — Le code owner est déclaratif.** Le dépôt n'a pas de fichier `CODEOWNERS` : rien n'impose techniquement l'approbation de C9. L'intent parent exige pourtant « branch protection, code owner ». Ajouter un `CODEOWNERS` n'a pas été retenu le 2026-10-16 : risque accepté. Décideur : tech lead.
- **P3 — Aucun critère ne vérifie que l'agent lit `CLAUDE.md`.** C1 (chargement en début de session) n'est couvert par aucun critère de l'intent. Ajouter un critère relève du PO. Décideur : PO.
- **P4 — Aucun skill de standards.** Aucun skill de conventions n'existe dans `.claude/skills/` : la section Conventions s'appuie seulement sur le README et l'intent parent. Décideur : tech lead.
- **P5 — Indicateur de succès.** Le taux de succès CI au premier passage n'est pas mesurable sans CI. Le lot 13 est suspendu tant qu'aucune CI n'existe ; le valideur « CI » du lot 5 dans `ia-factory.md` en suppose toujours une. Décideur : PO.

## Hors périmètre

- Commande unique de vérification (lot 1b) et bloc « vérifier avant de déclarer fini » (lot 1e).
- Règles transverses bloquantes (lot 1c).
- Alimentation de `CLAUDE.md` par les constats de revue (lots 6 et 9).
- `CLAUDE.md` du futur dépôt pilote, et template générique pour d'autres dépôts.
- Skills métier et de standards (lots 2 à 7).

## Questions ouvertes
