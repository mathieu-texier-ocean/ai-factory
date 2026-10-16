# Spec — Lot 1f : Activation des hooks git

- **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** validé
- **Validation :** Tech lead

## Périmètre

Deux hooks Claude Code, déclarés dans `.claude/settings.json` versionné, qui détectent un clone d'`ai-factory` où `core.hooksPath` ne désigne pas le dossier `hooks` du dépôt : le premier le signale à l'ouverture de la session, le second refuse les `git commit` lancés par l'agent tant que les hooks ne sont pas actifs. Les deux donnent la commande d'activation ; aucun ne l'exécute.

## Comportements

### Hook `SessionStart`

- **C1.** À l'ouverture d'une session, le hook lit `core.hooksPath` dans la configuration git du dépôt.
- **C2.** S'il ne désigne pas le dossier `hooks` du dépôt (C12), il signale que les contrôles de commit ne jouent pas et donne la commande `git config core.hooksPath hooks`. Le message atteint l'humain et le contexte de l'agent.
- **C3.** S'il désigne le dossier `hooks` du dépôt, il ne signale rien.
- **C4.** Il n'empêche jamais l'ouverture de la session.

### Hook `PreToolUse` sur `git commit`

- **C5.** Avant chaque commande Bash de l'agent dont le texte contient `git commit`, le hook lit `core.hooksPath`. La détection est volontairement large : elle ne cherche pas à savoir si la commande lance réellement le commit.
- **C6.** S'il ne désigne pas le dossier `hooks` du dépôt, la commande est refusée, avec un message qui donne la raison (les hooks git ne sont pas actifs, le commit ne serait pas contrôlé) et la commande `git config core.hooksPath hooks`.
- **C7.** S'il désigne le dossier `hooks` du dépôt, la commande passe sans message.
- **C8.** Les commandes Bash dont le texte ne contient pas `git commit` ne sont pas concernées.

### Communs

- **C9.** Les deux hooks ne font que lire la configuration git : ils n'écrivent jamais `core.hooksPath`.
- **C10.** Les deux hooks sont déclarés dans `.claude/settings.json`, versionné.

### Arbitrages du 2026-10-16

- **C11.** Les scripts des deux hooks sont dans `.claude/hooks/`, séparés des hooks git de `hooks/`. Un `run.sh` dans `tests/hook-activation/` les teste hors de Claude Code (entrée JSON simulée, code de sortie et message) ; `scripts/verifier.sh` (lot 1b) le lance avec les autres.
- **C12.** `core.hooksPath` désigne le dossier `hooks` du dépôt quand le chemin qu'il donne, résolu depuis la racine, est `<racine>/hooks` : `hooks`, `./hooks` ou le chemin absolu de ce dossier valent activation.

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | `core.hooksPath` absent | Signalé à l'ouverture (C2), commit de l'agent refusé (C6) |
| L2 | `core.hooksPath` vaut une autre valeur (par exemple `.git/hooks`) | Même traitement qu'absent (C12) |
| L3 | `git commit` enchaîné dans une commande (`git add . && git commit …`) | Détecté et refusé si les hooks ne sont pas actifs (C5) |
| L4 | `git commit --no-verify` avec les hooks actifs | Passe : le hook vérifie l'activation, pas les options du commit |
| L5 | L'humain active les hooks en cours de session | Le commit suivant de l'agent passe : la configuration est relue à chaque commande (C5) |
| L6 | Commit fait par l'humain hors de Claude Code | Non concerné (hors périmètre) |
| L7 | Commande qui contient le texte « git commit » sans le lancer (par exemple un `grep`) | Refusée si les hooks ne sont pas actifs (C5) |
| L8 | `core.hooksPath` vaut le chemin absolu du dossier `hooks` | Activation reconnue (C12) |

## Contrats

- **Scripts :** `.claude/hooks/` ; tests : `tests/hook-activation/run.sh`.
- **Déclaration :** `.claude/settings.json`, clé `hooks`, une entrée `SessionStart` et une entrée `PreToolUse` sur l'outil `Bash`.
- **Lecture :** `git config --get core.hooksPath` dans le dépôt de la session.
- **`SessionStart`, hooks inactifs :** message d'avertissement avec la commande d'activation, visible par l'humain et ajouté au contexte de l'agent ; session ouverte normalement.
- **`PreToolUse`, hooks inactifs :** commande refusée (blocage Claude Code), raison et commande d'activation renvoyées à l'agent.
- **Hooks actifs :** aucune sortie, aucun blocage.

## Critères d'acceptation

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | La session signale un `core.hooksPath` absent | Un clone d'`ai-factory` sans `core.hooksPath` | On ouvre une session Claude Code | Un message signale les hooks inactifs et donne `git config core.hooksPath hooks` | Manuel |
| A2 | Le commit de l'agent est refusé, avec raison et commande | Un clone sans `core.hooksPath` | L'agent lance un `git commit` | La commande est refusée ; le message donne la raison et `git config core.hooksPath hooks` | Manuel |
| A3 | Rien à signaler sur un clone configuré | Un clone avec `core.hooksPath` = `hooks` | On ouvre une session, puis l'agent lance un `git commit` | Aucun message à l'ouverture ; le commit passe (et les contrôles du `pre-commit` jouent) | Manuel |

## Points d'attention

- **P1 — Livrable « tests » absent de l'intent.** Le `run.sh` de C11 est une décision du 2026-10-16 que l'intent ne liste pas en livrable. Décideur : PO (ajouter le livrable à l'intent).
- **P2 — Détection par le texte de la commande.** Le `PreToolUse` repère `git commit` dans le texte de la commande Bash : un alias, un script qui commite ou un `git -c core.hooksPath=… commit` lui échappent. À l'inverse, un `grep "git commit"` est refusé tant que les hooks sont inactifs (risque accepté le 2026-10-16). Décideur : tech lead.
- **P3 — Commits de l'agent dans un autre dépôt.** Les `run.sh` des lots 2 et 3 commitent dans des dépôts temporaires, mais via `bash run.sh`, donc sans être concernés. Un `git -C <autre dépôt> commit` lancé directement serait évalué sur la configuration du dépôt de session. Décideur : tech lead.
- **P4 — Pas de CI.** Le PO a confirmé l'absence de CI sur `ai-factory` : rien ne rattrape un commit fait sans hooks hors de Claude Code. Le lot 13 est suspendu tant qu'aucune CI n'existe. Décideur : PO.
- **P5 — Aucun skill de standards.** Aucun skill de conventions n'existe dans `.claude/skills/` ; l'emplacement `.claude/hooks/` est une décision du 2026-10-16. Décideur : tech lead.

## Hors périmètre

- Les contrôles eux-mêmes (lots 2, 3, 1c).
- Commits faits hors de Claude Code.
- Activation automatique de `core.hooksPath`.
- Contrôle en CI (le lot 13 couvre les credentials).

## Questions ouvertes

