# Kit SDLC git + GitHub

Ce kit met en œuvre le *AI-native SDLC playbook* d’Anthropic avec git et GitHub. Chaque étape d’un besoin est une pull request vers `main`, relue sur GitHub ; sa fusion franchit la gate. Il répond à deux questions : qui travaille sur quoi, et à quelle étape en est chaque besoin. L’étape se déduit de l’état réel des branches, des PR et des tags ; elle n’est jamais saisie à la main.

## Contenu

| Fichier | Rôle |
|---|---|
| `bin/git-sdlc` | à placer dans le `PATH` de chaque poste : `git sdlc …` |
| `.github/workflows/sdlc.yml` | lance le check requis `sdlc-conventions` sur chaque PR |
| `.github/scripts/sdlc-check.sh` | règles du check : trailers, périmètre par étape, artefacts présents, credentials en clair |
| `.githooks/commit-msg` | ajoute `Need:` et `Stage:` sur les branches `need/*`, `Need: none` ailleurs |
| `.githooks/pre-commit` | refuse un `intent.md` auquel il manque une section du gabarit, et un credential en clair dans une ligne ajoutée |
| `.githooks/lib/credential.sh` | détection des credentials, partagée par le pre-commit et le check CI |
| `.sdlc/config` | réglages partagés (branche principale, arguments de fusion, équipe release facultative…) |
| `templates/intent.md` | gabarit copié par `git sdlc new` |
| `templates/spec.md`, `plan.md` | gabarits copiés par `git sdlc claim` (étapes spec et build), remplis par les skills de spec et de plan |
| `.claude/skills/` | skills Claude Code des étapes (voir « Les skills de Claude ») |
| `.claude/settings.json`, `.claude/hooks/` | hooks Claude Code : signalent à l’ouverture de session, et bloquent les `git commit` de Claude, tant que `core.hooksPath` ne vaut pas `.githooks` |
| `REVIEW.md` | consignes de revue, pour Claude comme pour les humains |
| `templates/projet/CLAUDE.md` | modèle du `CLAUDE.md` du dépôt produit, rempli par `scripts/deployer.sh` ; non copié tel quel |
| `scripts/deployer.sh` | installe le kit dans un dépôt produit, puis y répercute ses évolutions ; reste dans le dépôt du kit |
| `scripts/verifier.sh` | lance tous les tests du kit (`<livrable>/tests/<nom>/run.sh`) ; reste dans le dépôt du kit |

Prérequis : git 2.30+, bash 3.2+ (celui de macOS convient), GitHub CLI `gh` installé et authentifié (`gh auth login`) sur chaque poste. Les rulesets et les PR brouillon sur un dépôt privé dépendent de votre offre GitHub. Sans PR brouillon, le script se rabat sur une PR simple.

## Installation

**1. Dans le dépôt produit**, une seule fois, par un administrateur du dépôt, depuis un clone du kit :

```sh
<clone du kit>/scripts/deployer.sh install /chemin/du/depot [<nom du projet>]
cd /chemin/du/depot
# Fusionnez puis supprimez les .nouveau listés, complétez CLAUDE.md, puis :
git config core.hooksPath .githooks
git add -A && git commit -m "Initialisation du SDLC" && git push
cp <clone du kit>/bin/git-sdlc ~/.local/bin/ && chmod +x ~/.local/bin/git-sdlc   # si absent : setup en a besoin (étape 2)
git sdlc setup --dry-run    # affiche ce qui va être configuré
git sdlc setup              # applique
```

Le dépôt peut être existant ou vide ; un dossier absent est créé. Le script ne fait aucune opération Git dans le dépôt et lit le kit au commit `HEAD` du clone (les modifications non commitées sont ignorées et signalées). Il copie `.claude/`, `.github/`, `.githooks/`, `.sdlc/`, `templates/` et `REVIEW.md`, sans les dossiers `tests/` du kit ni `templates/projet/`, et produit `CLAUDE.md` depuis `templates/projet/CLAUDE.md` (nom du projet par défaut : celui du dossier). Un fichier déjà présent avec un autre contenu, par exemple un `.claude/settings.json` ou un `CLAUDE.md` existant, est conservé : la version du kit est écrite à côté en `<fichier>.nouveau`, à fusionner à la main puis supprimer. Pour `settings.json`, ajoutez les entrées `SessionStart` et `PreToolUse` du kit.

Le script écrit `.sdlc/manifeste` : le SHA du kit installé, le nom du projet et l’empreinte sha256 de chaque fichier copié. Commitez-le : la mise à jour en dépend.

**Mettre à jour le kit d’un dépôt produit**, depuis un clone du kit plus récent :

```sh
<clone du kit>/scripts/deployer.sh update [--forcer] /chemin/du/depot
```

Un fichier intact (même empreinte qu’au manifeste) est remplacé, ou supprimé s’il a disparu du kit. Un fichier modifié dans le dépôt est conservé ; si le kit l’a changé aussi, sa nouvelle version est écrite en `<fichier>.nouveau`, une seule fois par version du kit. Un fichier supprimé dans le dépôt n’est pas recréé. Le rapport liste chaque catégorie. `update` refuse un clone dont `HEAD` ne descend pas du SHA installé (clone plus ancien, branche divergente) ; `--forcer` passe outre. Les `.nouveau` ne sont pas ignorés par Git : ne les commitez pas.

**2. Sur chaque poste** :

```sh
cp <clone du kit>/bin/git-sdlc ~/.local/bin/ && chmod +x ~/.local/bin/git-sdlc   # tout dossier du PATH
gh auth login
git config core.hooksPath .githooks                                                # dans chaque clone
```

## Une journée type

```sh
# Initiatrice (Jade) : capter l’intent avec Claude
git sdlc new claims-status        # branche need/2026-10-28-claims-status/intent + PR brouillon
#   … rédaction avec Claude, commits, git push …
git sdlc ready 2026-10-28-claims-status intent       # revue demandée au PO

# PO (Paul) : relire sur GitHub, puis fusionner
git sdlc merge 2026-10-28-claims-status intent       # gate franchi

# Spec : produite avec Claude par l’initiatrice ou un analyste, fusionnée par le PO
git sdlc claim 2026-10-28-claims-status spec      # copie templates/spec.md dans spec.md
#   … spec.md, push, git sdlc ready … ; Paul relit et fusionne

# Dev (Dina) : plan mode, puis code
git sdlc claim 2026-10-28-claims-status build     # copie templates/plan.md dans plan.md
#   … plan.md d’abord, puis le code et les tests, push, git sdlc ready …

# Tech lead (Léa) : revue selon REVIEW.md, puis gate
git sdlc merge 2026-10-28-claims-status build

# Release manager (Rémi)
git sdlc release                  # release GitHub sur le tag YY.MM.DD du jour (.2, .3… si déjà livré)
git sdlc release 26.11.04         # ou à la date de mise en production prévue

# Tout le monde
git sdlc status 2026-10-28-claims-status
git sdlc board                    # besoins en cours, triés par étape
git sdlc board --by-person        # regroupés par personne ou équipe
git sdlc board --all              # y compris livrés et rejetés
```

`new`, `claim`, `ready`, `merge` et `reject` affichent ensuite la ligne de `git sdlc board` du besoin, relue sur GitHub.

Depuis une branche `need/<id>/<étape>`, `status`, `claim`, `ready`, `merge` et `reject` se lancent sans id : `git sdlc status`, `git sdlc ready`, `git sdlc reject "<raison>"`. Avec l’id seul (`git sdlc merge <id>`), l’étape est celle de l’unique PR ouverte du besoin ; s’il y en a plusieurs, précisez-la. `git sdlc claim <id>` prend l’étape en cours du besoin, ou la suivante si la précédente est fusionnée (spec après l’intent, build après la spec). Le besoin et l’étape déduits sont affichés avant l’action. `reject` sans id demande confirmation, et refuse sans terminal : un id mal saisi passerait sinon pour le début de la raison.

`merge` refuse une PR encore en brouillon. En terminal, il propose de la sortir du brouillon puis de fusionner ; `git sdlc merge --ready` le fait sans question. Si les checks requis tournent encore (juste après un push ou la sortie du brouillon, qui relance `sdlc-conventions`), `merge` les attend avant de fusionner : le ruleset refuserait la fusion.

Avant de fusionner, `merge` signale les commits de la branche locale `need/<id>/<étape>` absents de la branche distante, et les modifications non commitées si c’est la branche courante : la fusion porte sur la PR telle qu’elle est sur GitHub, et `--delete-branch` supprime la branche locale. En terminal, il demande confirmation ; sans terminal, il refuse.

Toutes ces actions restent possibles dans l’interface GitHub. `git sdlc` lit l’état réel des PR : une PR fusionnée dans le navigateur apparaît comme gate franchi dans `board`.

## Branches et trailer `Stage:`

Le trailer `Stage:` porte l’étape du cycle du playbook, pas le nom de la branche. Le hook `commit-msg` et `git sdlc` appliquent cette correspondance :

| Branche | Fichier produit | `Stage:` |
|---|---|---|
| `need/<id>/intent` | `intent/<id>/intent.md` | `plan` |
| `need/<id>/spec` | `intent/<id>/spec.md` | `design` |
| `need/<id>/build` | `intent/<id>/plan.md`, puis le code | `build` |

Un commit d’intent porte donc `Stage: plan`. Le fichier `plan.md`, lui, relève de l’étape build : c’est le plan d’implémentation produit en plan mode avant le code. Les valeurs `test`, `deploy` et `maintain` sont acceptées par le hook pour les commits saisis à la main ; aucune branche ne les produit.

## Les skills de Claude

Quatre skills, dans `.claude/skills/`, outillent les étapes. Ils lisent les gabarits de `templates/`, n’écrivent aucun statut et ne lancent jamais `ready`, `merge` ni `release`.

| Skill | Branche | Rôle |
|---|---|---|
| `redaction-intent` | `need/<id>/intent` | remplit `intent.md` depuis un besoin brut, en posant les questions manquantes ; la priorité reste celle du PO |
| `controle-taille-intent` | toutes | dit si un intent doit être découpé, d’après 8 signaux ; lecture seule |
| `generation-spec` | `need/<id>/spec` | écrit `spec.md` depuis l’intent fusionné : comportements C, cas limites L, critères d’acceptation A en Étant donné / Quand / Alors |
| `generation-plan` | `need/<id>/build` | conduit la séance de plan en plan mode, puis écrit `plan.md` : fichiers touchés, étapes = commits, tests, risques, couverture des C, L, A |

L’amont est accepté quand sa PR est fusionnée : le skill de spec refuse tant que `intent.md` n’est pas sur `main`, celui de plan tant que `spec.md` n’y est pas. Le check `sdlc-conventions` applique la même règle à la PR.

## Comment l’étape et « qui » sont calculés

Pour l’étape en cours, l’état de la PR détermine qui a la main :

| État de la PR | Étape affichée | « Qui » |
|---|---|---|
| brouillon | `<Étape> en cours` | assigné(e)s, à défaut l’auteur |
| prête (hors brouillon) | `<Étape> en revue, à fusionner` | relecteurs sollicités, à défaut PO ou tech lead |
| corrections demandées | `<Étape> : corrections demandées` | assigné(e)s, à défaut l’auteur |
| fusionnée, étape suivante pas commencée | `Intent accepté…`, `Spec acceptée…`, `Prêt à livrer` | rôle qui doit agir : analyste, Dev, RM |

L’auteur d’une fusion n’apparaît pas dans QUI : `git sdlc status` l’indique dans les preuves.

L’ordre de priorité est le suivant :

1. PR fermée avec `sdlc:rejected`, ou tag `rejected/<id>` → **Rejeté**.
2. PR build fusionnée dont le dernier commit est contenu dans un tag `YY.MM.DD[.V]` → **Livré** ; sinon **Prêt à livrer**.
3. PR build ouverte → son état ci-dessus ; sinon branche build sans PR → **en cours (sans PR)**.
4. PR spec fusionnée → **Spec acceptée** ; sinon PR spec ouverte, puis branche spec sans PR.
5. PR intent fusionnée → **Intent accepté** ; sinon PR intent ouverte, puis branche intent sans PR.

`status` affiche aussi les preuves : chaque gate franchi (date, PR, auteur de la fusion), l’état des checks, et les incidents enfants (`Parent: <id>`).

## La revue par Claude

`REVIEW.md` est écrit pour être lu par Claude comme par les humains. Deux intégrations décrites dans le playbook s’y branchent sans modifier le kit :

- **Code Review géré** : un administrateur l’active et choisit les dépôts ; la revue suit `REVIEW.md`. Documentation : https://code.claude.com/docs/en/code-review
- **claude-code-action** dans vos propres Actions : un commentaire `@claude` sur la PR demande une correction, poussée sur la branche. Documentation : https://code.claude.com/docs/en/github-actions

Dans les deux cas, Claude commente ; il ne fusionne pas. La gate reste la fusion, faite par un humain.

## CLAUDE.md du dépôt produit

`scripts/deployer.sh install` produit le `CLAUDE.md` du dépôt depuis `templates/projet/CLAUDE.md` : section SDLC remplie (branches, trailers, gates humains, skills, vérification, secrets), sections du projet à compléter. Si le dépôt a déjà un `CLAUDE.md`, le modèle arrive en `CLAUDE.md.nouveau` : reportez-en la section SDLC.

## Points d’attention

- **Séparation des tâches.** Sans approbation requise, GitHub laisse toute personne ayant le droit d’écriture fusionner, y compris l’auteur de la PR. Le rôle (PO pour intent et spec, tech lead pour le build) et « l’auteur ne fusionne pas sa propre PR » sont des conventions : `status` les rend visibles, rien ne les impose. Réservez le droit d’écriture en conséquence.
- **Hooks client.** `commit-msg` et `pre-commit` se contournent avec `--no-verify`, et ne jouent pas sans `git config core.hooksPath .githooks` ; les hooks Claude Code le signalent et bloquent alors les commits de Claude. Le check `sdlc-conventions`, requis par le ruleset, revérifie côté GitHub le trailer `Need:`, le périmètre des fichiers et les credentials en clair ; la valeur de `Stage:` et les sections de l’intent ne sont contrôlées que par les hooks.
- **Credentials.** La détection repère des formes connues (clé privée, jetons AWS, GitHub, Anthropic, Slack, affectation `password=…`, URL avec identifiants), pas tous les secrets. Une ligne marquée `credential-ok` et les fichiers sous `tests/<nom>/fixtures/` sont ignorés : la revue reste la dernière barrière. Un credential poussé est à révoquer, même retiré ensuite.
- **Mode de fusion.** Seul le rebase garde les trailers `Need:`/`Stage:` sur chaque commit ; un squash les fusionnerait au gré du message. `setup` désactive squash et merge commit. `git sdlc merge` appelle `gh pr merge --rebase --delete-branch` (clé `mergeArgs` de `.sdlc/config`) : la branche distante et la branche locale sont supprimées. L’auteur de la fusion n’est connu que par l’API GitHub : sans elle (hors ligne, PR au-delà de `prLimit`), `status` retrouve l’étape par les trailers mais pas qui l’a fusionnée.
- **Recette.** La checklist de la PR build demande une recette validée, refaite après toute modification. C’est déclaratif : rien ne la vérifie.
- **Branches hors besoin.** `Need:` n’est exigé que sur `need/*` ; ailleurs le hook ajoute `Need: none` et le check vérifie seulement que `intent/` n’est pas touché.
- **Volume.** `status` et `board` lisent les `prLimit` (300) PR les plus récentes ciblant `main`. Augmentez la valeur dans `.sdlc/config` si besoin.
- **Validation.** Le kit a été testé de bout en bout contre un GitHub simulé (PR, revues, fusions, releases, check CI réellement exécuté). Lancez `git sdlc setup --dry-run` puis vérifiez les rulesets créés dans *Settings → Rules* lors de la première installation.
