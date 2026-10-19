# Plan — Lot 1f : Activation des hooks git

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** validé
- **Validation :** Tech lead
- **Base :** `main` (a2123fb, lot 1e clos).

## Prérequis

- `spec.md` commitée au statut `validé` : fait (789bb9e).
- Une seule PR pour le lot. Chaque étape ci-dessous = un commit.
- Lot 1b clos : `scripts/verifier.sh` trouve tout `run.sh` du dépôt, celui de `.claude/hooks/tests/` compris (C11).
- P1 de la spec (livrable « tests » absent de l'intent) : le plan livre le `run.sh` décidé le 2026-10-16 ; l'ajout du livrable à l'intent reste au PO.

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `.claude/hooks/hooks-git-actifs.sh` | nouveau, exécutable | 1 |
| `.claude/hooks/session-hooks-git.sh` | nouveau, exécutable | 1 |
| `.claude/hooks/commit-hooks-git.sh` | nouveau, exécutable | 1 |
| `.claude/hooks/tests/hook-activation/run.sh` | nouveau, exécutable | 2 |
| `.claude/settings.json` | nouveau | 3 |
| `README.md` | modifié (mise en route, tableau du dépôt) | 4 |
| `CLAUDE.md` | modifié (commandes, architecture) | 4 |
| `requirements/closed/01f-activation-hooks/RECETTE.md` | nouveau | 4 |

Les noms de scripts sont une proposition ; seul l'emplacement `.claude/hooks/` est fixé (C11).

## Étapes

### 1. Scripts des deux hooks

Bash et git seulement, comme `hooks/pre-commit` : pas de `jq` ni de Python, pour ne rien exiger de plus sur les postes.

**`hooks-git-actifs.sh` (C1, C5, C9, C12)**, sourcé par les deux autres, définit `hooks_git_actifs` :
- racine : `$CLAUDE_PROJECT_DIR` (fourni par Claude Code), à défaut `git rev-parse --show-toplevel` ;
- valeur : `git -C "$racine" config --get core.hooksPath` ; absente → inactif ;
- résolution : chemin relatif pris depuis la racine, puis `cd … && pwd -P` ; comparé à `cd "$racine/hooks" && pwd -P` ; égal → actif (`hooks`, `./hooks`, chemin absolu) ; sinon inactif (`.git/hooks`, autre dossier, dossier inexistant) ;
- lecture seule : aucun `git config` en écriture (C9).

**`session-hooks-git.sh` — `SessionStart` (C1 à C4)**
- Actif : aucune sortie, code 0 (C3).
- Inactif : JSON sur stdout, code 0 (la session s'ouvre toujours, C4) :
  - `systemMessage` pour l'humain ;
  - `hookSpecificOutput.additionalContext` pour l'agent ;
  - même texte : « Hooks git inactifs : les contrôles de commit (intent, spec, credential) ne jouent pas. Activez-les avec `git config core.hooksPath hooks`. » (C2).
  Le texte est fixe : le JSON s'écrit avec `printf`, sans `jq`.

**`commit-hooks-git.sh` — `PreToolUse` sur `Bash` (C5 à C8)**
- Lit l'entrée JSON sur stdin et cherche le texte `git commit` dans l'entrée entière (détection large voulue par C5 : une commande `grep "git commit"` est concernée).
- Pas de `git commit` : code 0, aucune sortie (C8).
- `git commit` et hooks actifs : code 0, aucune sortie (C7).
- `git commit` et hooks inactifs : code 2, message sur stderr : « Commit refusé : les hooks git ne sont pas actifs, ce commit ne serait pas contrôlé. Demandez à l'humain de lancer `git config core.hooksPath hooks`. » (C6). Le code 2 bloque l'appel et renvoie stderr à l'agent.

Couvre : C1 à C9, C12.

### 2. Tests `.claude/hooks/tests/hook-activation/run.sh`

Sur le modèle de `hooks/tests/<nom>/run.sh` : dépôt temporaire avec un dossier `hooks/`, copie des scripts de `.claude/hooks/` (sans `tests/`), `CLAUDE_PROJECT_DIR` pointé sur ce dépôt, `GIT_CONFIG_GLOBAL=/dev/null` et `GIT_CONFIG_NOSYSTEM=1` exportés (un `core.hooksPath` global ou système fausserait les cas « absent »), entrées JSON simulées via `printf | script`, une ligne `PASS`/`FAIL` par cas, sortie en erreur si un cas échoue (C11).

| Cas | `core.hooksPath` | Script et entrée | Attendu | Réf. |
|---|---|---|---|---|
| session, absent | — | session | code 0, `systemMessage` et `additionalContext` avec la commande | A1, C2, C4, L1 |
| session, actif | `hooks` | session | code 0, aucune sortie | A3, C3 |
| session, autre valeur | `.git/hooks` | session | message | L2, C12 |
| session, chemin absolu | `<racine>/hooks` | session | aucune sortie | L8, C12 |
| session, `./hooks` | `./hooks` | session | aucune sortie | C12 |
| commit, absent | — | `{"tool_input":{"command":"git commit -m x"}}` | code 2, raison + commande sur stderr | A2, C6, L1 |
| commit, actif | `hooks` | idem | code 0, aucune sortie | A3, C7 |
| commit enchaîné | — | `git add . && git commit -m x` | code 2 | L3 |
| `--no-verify`, actif | `hooks` | `git commit --no-verify -m x` | code 0 | L4 |
| texte sans commit réel | — | `grep -rn "git commit" .` | code 2 | L7 |
| autre commande | — | `ls` | code 0 | C8 |
| activation en cours de session | — puis `hooks` | commit, deux appels | code 2 puis 0 | L5 |
| lecture seule | — | session puis commit | `core.hooksPath` toujours absent | C9 |

Couvre : C11, et la vérification de C1 à C9, C12.

### 3. Déclaration dans `.claude/settings.json`

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session-hooks-git.sh" } ] }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/commit-hooks-git.sh" } ] }
    ]
  }
}
```

Fichier versionné (C10). Vérifier `git check-ignore -v .claude/settings.json .claude/hooks/*.sh .claude/hooks/tests/hook-activation/run.sh` : si un `.gitignore` global `.*/` les ignore, `git add -f` sur `settings.json` et tout `.claude/hooks/` (README). Un script déclaré mais non suivi fait échouer le hook en code 127, qui ne bloque rien (R6).

Couvre : C10.

### 4. README, recette et PR

- README : « Mise en route », étape 1 : dire que Claude Code signale et bloque tant que les hooks ne sont pas actifs ; étape 2 : `git add -f` étendu à tout `.claude/` (skills, hooks, `settings.json`) ; tableau du dépôt : lignes `.claude/settings.json`, `.claude/hooks/` et `.claude/hooks/tests/`.
- `CLAUDE.md` : « Commandes », le commentaire de `verifier.sh` cite aussi `.claude/hooks/tests/` ; « Architecture » : ligne `.claude/hooks/` et `.claude/settings.json`.
- `RECETTE.md`, en session réelle de Claude Code, dans un clone jetable :
  - A1 : `git config --unset core.hooksPath`, nouvelle session → message visible et commande donnée.
  - A2 : demander un commit à l'agent → refus, raison et commande.
  - A3 : `git config core.hooksPath hooks`, nouvelle session → aucun message ; commit de l'agent accepté, et le `pre-commit` joue (un intent incomplet est refusé).
- PR ouverte par l'humain, revue par le tech lead.

Couvre : A1 à A3.

## Tests à écrire

- Automatisés : `.claude/hooks/tests/hook-activation/run.sh`, 13 cas (étape 2), lancés par `scripts/verifier.sh`.
- Manuels : A1 à A3 en session réelle (étape 4), consignés dans `RECETTE.md`.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1–C9, C12 | 1 (testé en 2) |
| C10 | 3 |
| C11 | 2 |
| L1–L5, L7, L8 | 2 |
| L6 | hors périmètre (commit hors Claude Code) |
| A1–A3 | 4 (et 2 pour la logique) |

## Risques

- **R1 — Format des hooks Claude Code.** Les champs `systemMessage`, `hookSpecificOutput.additionalContext`, le code 2 et `$CLAUDE_PROJECT_DIR` sont ceux de la documentation actuelle de Claude Code. À revérifier au build ; un changement de format casse la recette A1 à A3 sans que le `run.sh` le voie.
- **R2 — Détection sur l'entrée entière.** Le texte `git commit` est cherché dans tout le JSON, y compris la description de la commande : faux positifs possibles quand les hooks sont inactifs (accepté, détection large). À l'inverse, `git -C x commit`, un alias ou un script qui commite passent (P2 de la spec).
- **R3 — Dépôt de session.** La configuration lue est celle de `$CLAUDE_PROJECT_DIR`. Un commit de l'agent dans un autre dépôt est évalué sur celle-ci (P3 de la spec).
- **R4 — Hooks de projet à approuver.** Claude Code peut demander à chaque personne d'approuver les hooks déclarés dans `.claude/settings.json` à leur première apparition. Tant que ce n'est pas fait, ni signalement ni blocage : à mentionner dans le README.
- **R5 — Lot 1g.** Le lot 1g ajoutera un second `PreToolUse` dans le même `settings.json` et réutilisera `.claude/hooks/`. Garder les scripts indépendants pour qu'il s'ajoute sans modifier ceux de 1f.
- **R6 — Scripts non suivis.** Un clone qui a `settings.json` sans les scripts de `.claude/hooks/` (`.gitignore` global `.*/`) échoue en code 127 : ni signalement ni blocage, sans message, soit le cas que le lot veut supprimer. Parade : `git check-ignore` de l'étape 3.
- **R7 — Session lancée hors de la racine** (constaté en recette). Les hooks de projet ne sont chargés que depuis le dossier de lancement : depuis un dossier parent, rien ne joue. Limite documentée dans le README ; traitement au lot 1i (P6 de la spec).

## Hors périmètre

Ceux de la spec : les contrôles eux-mêmes (lots 2, 3, 1c), commits hors de Claude Code, activation automatique de `core.hooksPath`, contrôle en CI.
