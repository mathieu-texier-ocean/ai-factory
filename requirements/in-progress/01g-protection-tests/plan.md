# Plan — Lot 1g : Protection des tests pendant un correctif

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** validé
- **À risque :** non
- **Validation :** développeur
- **Base :** `feat/lot-1g-protection-tests` (a06b4dd, spec validée), sur `main` d3d4948.

## Prérequis

- `spec.md` commitée au statut `validé` : fait (a06b4dd).
- Une seule PR pour le lot. Chaque étape ci-dessous = un commit.
- Lot 1e clos (consigne « corriger le code, pas le test ») ; lot 1f clos : `.claude/hooks/`, `.claude/settings.json` et `.claude/hooks/tests/` existent, `scripts/verifier.sh` lance tout `run.sh`.
- Décisions du 2026-10-28 (développeur) : Bash pur, comme 1f ; P1 → confirmation seulement si le chemin résolu existe ; P5 → un `run.sh` ; P4 → constaté en recette.

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `.claude/hooks/protection-tests.sh` | nouveau, exécutable | 1 |
| `.claude/hooks/tests/protection-tests/run.sh` | nouveau, exécutable | 2 |
| `.claude/settings.json` | modifié (2e entrée `PreToolUse`) | 3 |
| `README.md` | modifié (hooks Claude Code, tableau du dépôt) | 4 |
| `CLAUDE.md` | modifié (Architecture, ligne `.claude/hooks/`) | 4 |
| `requirements/in-progress/01g-protection-tests/validation.md` | nouveau | 4 |

Le nom du script est une proposition ; seul l'emplacement `.claude/hooks/` est fixé (C9).

## Étapes

### 1. Script `protection-tests.sh`

Bash et git seulement, sans `jq` ni Python. Indépendant des scripts de 1f : il ne les source pas et ne les modifie pas.

- **Entrée :** lit le JSON sur stdin. Une fonction `champ <nom>` extrait la première valeur chaîne `"<nom>":"…"` en tenant compte des échappements (`\"`, `\\`), puis les décode : `tool_name`, `cwd`, `tool_input.file_path`, `tool_input.command`. La recherche porte sur `command` seul, pas sur la description (≠ 1f, constat n°6 de la revue).
- **C1 :** racine `$CLAUDE_PROJECT_DIR`, à défaut `git rev-parse --show-toplevel` ; branche `git symbolic-ref --short -q HEAD`. Si elle ne commence pas par `bugfix/`, ou si HEAD est détachée : code 0 sans sortie (L1, L2).
- **C2 :** `est_test <chemin absolu>` normalise le chemin (`.` et `..` retirés à la main), le rend relatif à la racine et vérifie qu'un segment vaut `tests`. Un chemin hors de la racine n'est pas concerné (voir la question ouverte dans Risques).
- **Edit / Write (C3, C4) :** `file_path` sous `tests/` et existant (`-e`) → demande ; sinon code 0 (L3, L4).
- **Bash (C5, P1, P2) :**
  - découpe `command` en segments sur `&&`, `||`, `;`, `|` et les retours à la ligne (découpe naïve, sans gestion des guillemets) ;
  - suit un dossier courant, qui part de `cwd` : un segment `cd <dir>` le met à jour, en relatif ou en absolu (L11) ;
  - cibles d'écriture par segment : arguments non-options de `rm` et `mv` ; dernier argument de `cp` ; arguments de `tee` ; fichiers de `sed -i` (les arguments après le script) ; cible de `>` et `>>`, sauf `/dev/null` et `>&N` ;
  - chaque cible est résolue depuis le dossier courant. Elle est sous `tests/` et existe → demande (L5) ; elle est sous `tests/` et n'existe pas → passe (L10, P1) ; elle contient un glob → demande ;
  - une lecture (`cat`, `bash run.sh`) n'a pas de cible d'écriture → passe (L9).
- **Sortie, demande (C6) :** `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"…"}}` sur stdout, code 0. La raison donne la branche de correctif, le fichier visé et le rappel « pendant un correctif, corriger le code, pas le test ; si le changement de test est volontaire, le confirmer ». Le chemin est échappé pour le JSON (`\` et `"`).
- **C7 :** pas de cible sous `tests/` → code 0, aucune sortie.
- **C8 :** lecture seule : `git` en lecture, test d'existence, rien d'écrit.

Couvre : C1 à C8, L1 à L5, L8 à L11.

### 2. Tests `.claude/hooks/tests/protection-tests/run.sh`

Sur le modèle de `.claude/hooks/tests/hook-activation/run.sh` : dépôt temporaire, copie du script, `CLAUDE_PROJECT_DIR` pointé sur ce dépôt, `GIT_CONFIG_GLOBAL=/dev/null` et `GIT_CONFIG_NOSYSTEM=1`, un fichier `tests/x/existant.sh` commité, entrées JSON simulées, une ligne `PASS` ou `FAIL` par cas. Le script sort en erreur si un cas échoue.

| Cas | Branche | Entrée | Attendu | Réf. |
|---|---|---|---|---|
| Edit d'un test existant | `bugfix/a` | Edit `tests/x/existant.sh` | `ask`, raison avec le fichier | A1, C3, C6 |
| Write qui écrase | `bugfix/a` | Write `tests/x/existant.sh` | `ask` | L4, C3 |
| Write d'un nouveau test | `bugfix/a` | Write `tests/x/nouveau.sh` | rien | A3, C4, L3 |
| Edit hors `tests/` | `bugfix/a` | Edit `src.sh` | rien | A4, C7 |
| Autre branche | `feat/b` | Edit `tests/x/existant.sh` | rien | A5, C1 |
| `fix/`, `hotfix/` | `fix/a`, `hotfix/a` | idem | rien | L1 |
| HEAD détachée | — | idem | rien | L2 |
| `rm`, `mv`, `sed -i` | `bugfix/a` | `rm tests/x/existant.sh`, … | `ask` | A2, C5, L5 |
| Redirection `>` | `bugfix/a` | `echo > tests/x/existant.sh` | `ask` | C5 |
| Création par Bash | `bugfix/a` | `cat > tests/x/nouveau.sh` | rien | L10, P1 |
| Lectures | `bugfix/a` | `cat tests/x/existant.sh`, `bash tests/x/existant.sh 2>/dev/null` | rien | L9, P2 |
| `cd` puis relatif | `bugfix/a` | `cd tests/x && rm existant.sh` | `ask` | L11 |
| `cwd` sous `tests/` | `bugfix/a` | `cwd`=`…/tests/x`, `rm existant.sh` | `ask` | L11 |
| `tests/` ailleurs | `bugfix/a` | Edit `a/b/tests/c.sh` existant | `ask` | L8, C2 |
| Description qui cite `tests/` | `bugfix/a` | `ls`, description « rm tests/… » | rien | C5 |
| Lecture seule | `bugfix/a` | tous les cas | `git status` inchangé | C8 |

Couvre : vérification de C1 à C8, L1 à L5, L8 à L11, et la logique de A1 à A5.

### 3. Déclaration dans `.claude/settings.json`

Une 2e entrée dans `PreToolUse`, ajoutée après celle de 1f, que l'on ne touche pas (C9) :

```json
{ "matcher": "Edit|Write|Bash", "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protection-tests.sh" } ] }
```

Parade de l'étape risquée : relire le diff (seule une ligne ajoutée dans le tableau `PreToolUse`) ; contrôler que le JSON est valide en ouvrant une session (Claude Code signale un `settings.json` invalide) ; vérifier que le hook de 1f joue toujours (`run.sh` de 1f, et un commit refusé en recette) ; `git check-ignore -v` sur le nouveau script et sur le `run.sh`, et `git add -f` si besoin.

Couvre : C9.

### 4. Documentation et recette

- README : dans la description des hooks Claude Code, une ligne sur la protection des tests en `bugfix/`, avec la limite du lancement depuis la racine ; tableau du dépôt mis à jour si besoin.
- `CLAUDE.md`, section Architecture : la ligne `.claude/hooks/` cite aussi la protection des tests.
- `validation.md`, en session réelle de Claude Code lancée depuis la racine d'un clone jetable, sur une branche `bugfix/recette` :
  - A1 à A5, et L7 : refuser une confirmation → l'outil ne s'exécute pas ;
  - P4 : refaire A1 en mode auto, puis en `bypassPermissions`, et noter si la demande apparaît. Si elle est sautée, l'ajouter aux limites connues du README ; aucun changement de code.
- PR ouverte par l'humain.

Couvre : A1 à A5, L7.

## Tests à écrire

- Automatisés : `.claude/hooks/tests/protection-tests/run.sh` (étape 2), lancé par `bash scripts/verifier.sh`.
- Manuels : A1 à A5, L7 et P4 en session réelle (étape 4), consignés dans `validation.md`.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1–C8 | 1 (testé en 2) |
| C9 | 3 |
| L1–L5, L8–L11 | 1 (testé en 2) |
| L6 | hors périmètre (écriture indirecte par un script, risque accepté) |
| L7 | 4 (comportement de Claude Code) |
| A1–A5 | 4 (logique testée en 2) |

## Risques

- **Étape la plus risquée : la 3** (selon le développeur). Le `settings.json` est partagé avec 1f : une erreur de JSON désactive tous les hooks de projet. Parade : celle de l'étape 3.
- **R1 — Analyse Bash en Bash pur.** La découpe est naïve : guillemets, `$(…)`, `xargs`, `find -delete` ou `sh -c` lui échappent. Une écriture non reconnue passe sans confirmation, et un `;` ou un `>` cité entre guillemets peut provoquer une demande en trop. Choix accepté contre python3.
- **R2 — Hook qui plante.** Un code de sortie autre que 0 ou 2 ne bloque rien : l'écriture passe en silence. Le `run.sh` couvre les cas prévus ; une entrée inattendue reste un risque.
- **R3 — Format `permissionDecision: "ask"`.** C'est le format de la documentation actuelle de Claude Code, à revérifier au build ; le `run.sh` ne voit pas un changement de format.
- **R4 — Modes de permission (P4).** Constaté en recette ; si la demande est sautée en mode auto ou en contournement des permissions, c'est documenté comme limite.
- **R5 — Limite connue (spec) :** une session lancée depuis un dossier parent ne charge pas le hook (lot 1i).
- **R6 — Fichier « existant » jugé sur le disque.** Un test de régression créé par l'agent devient protégé dès sa création ; chaque retouche demande confirmation (constat n°2 de la revue, non retenu dans la spec).
- **Questions restées sans réponse :**
  - P2 : faut-il aussi détecter `git checkout`/`git restore` (qui écrasent un test), `truncate`, `dd of=`, `ln -sf`, `git apply`/`patch`/`stash` ? Pas de réponse : le plan s'en tient à la liste de la spec, et ces commandes passent sans confirmation.
  - P3 (PO) : trace de la confirmation pour le relecteur, absente.
  - Question ouverte de la spec : un `tests/` hors du dépôt de session. Le plan le traite comme non concerné (C2 : chemin relatif à la racine).
- **Options écartées :** python3 (`json`, `shlex`), jugé plus fiable mais ajoute une dépendance que 1f avait évitée ; confirmation pour toute écriture Bash sous `tests/` (P1), qui contredit la création libre ; refus (`deny`) dans les modes auto ou de contournement (P4), qui va plus loin que la spec.

## Hors périmètre

Ceux de la spec : la consigne de `CLAUDE.md` (lot 1e), les modifications de l'humain, les branches autres que `bugfix/`, le contrôle au commit ou en CI, les écritures indirectes par un script, le chargement depuis un dossier parent (lot 1i).
