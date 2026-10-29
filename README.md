# Kit SDLC git + GitHub (v2)

Ce kit met en œuvre le *AI-native SDLC playbook* d’Anthropic avec git et GitHub. Chaque étape d’un besoin est une pull request vers `main`, relue sur GitHub ; sa fusion franchit la gate. Il répond à deux questions : qui travaille sur quoi, et à quelle étape en est chaque besoin. L’étape se déduit de l’état réel des branches, des PR et des tags ; elle n’est jamais saisie à la main.

## Ce qui change par rapport à la v1

| v1 (git seul) | v2 (GitHub) |
|---|---|
| hook serveur `pre-receive` | ruleset `sdlc-main` + check CI `sdlc-conventions` |
| `.sdlc/approvers` | droit d’écriture sur le dépôt (qui peut fusionner) |
| merge local signé avec `Approved-by:` | fusion de la PR par rebase ; l’auteur de la fusion vient de GitHub |
| notes `review` | revues et commentaires de PR |
| notes `tests` | checks GitHub Actions affichés par `git sdlc status` |
| tag annoté `release/*` | release GitHub sur un tag `YY.MM.DD[.V]` protégé |
| tag `rejected/<id>` | PR fermée avec l’étiquette `sdlc:rejected` |

## Contenu

| Fichier | Rôle |
|---|---|
| `bin/git-sdlc` | à placer dans le `PATH` de chaque poste : `git sdlc …` |
| `.github/workflows/sdlc.yml` | lance le check requis `sdlc-conventions` sur chaque PR |
| `.github/scripts/sdlc-check.sh` | règles du check : trailers, périmètre par étape, artefacts présents |
| `.githooks/commit-msg` | ajoute `Need:` et `Stage:` sur les branches `need/*`, `Need: none` ailleurs |
| `.sdlc/config` | réglages partagés (branche principale, équipe release, arguments de fusion…) |
| `intent/_template/intent.md` | gabarit copié par `git sdlc new` |
| `REVIEW.md` | consignes de revue, pour Claude comme pour les humains |

Prérequis : git 2.30+, bash 3.2+ (celui de macOS convient), GitHub CLI `gh` installé et authentifié (`gh auth login`) sur chaque poste. Les rulesets et les PR brouillon sur un dépôt privé dépendent de votre offre GitHub. Sans PR brouillon, le script se rabat sur une PR simple.

## Installation

**1. Dans le dépôt produit**, une seule fois, par un administrateur du dépôt :

```sh
cp -r .github .githooks .sdlc intent REVIEW.md /chemin/du/depot/
# Éditez .sdlc/config (releaseTeam), puis :
git add -A && git commit -m "Initialisation du SDLC" && git push
git sdlc setup --dry-run    # affiche ce qui va être configuré
git sdlc setup              # applique
```

`git sdlc setup` configure quatre choses :

- **Fusion** : par rebase uniquement (« Rebase and merge »), conformément à la méthode Kraken. Les commits de la PR sont rejoués sur `main` avec leurs trailers ; GitHub n’a pas de vrai fast-forward, les SHA changent. Les branches sont supprimées après fusion.
- **Étiquettes** : `sdlc:intent`, `sdlc:spec`, `sdlc:build`, `sdlc:incident` et `sdlc:rejected`.
- **Ruleset `sdlc-main`** :
  - PR obligatoire, sans approbation requise : la fusion est la gate ;
  - fils de discussion résolus ;
  - historique linéaire ;
  - check `sdlc-conventions` vert ;
  - ni push forcé ni suppression.
- **Ruleset `sdlc-release-tags`** : seuls l’équipe `releaseTeam` (à défaut, les admins) peuvent créer des tags de livraison `YY.MM.DD[.V]`, et personne ne peut les modifier ni les supprimer.

**2. Sur chaque poste** :

```sh
cp bin/git-sdlc ~/.local/bin/ && chmod +x ~/.local/bin/git-sdlc   # tout dossier du PATH
gh auth login
git config core.hooksPath .githooks                                 # dans chaque clone
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
git sdlc claim 2026-10-28-claims-status spec
#   … spec.md, push, git sdlc ready … ; Paul relit et fusionne

# Dev (Dina) : plan mode, puis code
git sdlc claim 2026-10-28-claims-status build
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

Toutes ces actions restent possibles dans l’interface GitHub. `git sdlc` lit l’état réel des PR : une PR fusionnée dans le navigateur apparaît comme gate franchi dans `board`.

## Branches et trailer `Stage:`

Le trailer `Stage:` porte l’étape du cycle du playbook, pas le nom de la branche. Le hook `commit-msg` et `git sdlc` appliquent cette correspondance :

| Branche | Fichier produit | `Stage:` |
|---|---|---|
| `need/<id>/intent` | `intent/<id>/intent.md` | `plan` |
| `need/<id>/spec` | `intent/<id>/spec.md` | `design` |
| `need/<id>/build` | `intent/<id>/plan.md`, puis le code | `build` |

Un commit d’intent porte donc `Stage: plan`. Le fichier `plan.md`, lui, relève de l’étape build : c’est le plan d’implémentation produit en plan mode avant le code. Les valeurs `test`, `deploy` et `maintain` sont acceptées par le hook pour les commits saisis à la main ; aucune branche ne les produit.

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

1. PR fermée avec `sdlc:rejected` → **Rejeté**.
2. PR build fusionnée dont le dernier commit est contenu dans un tag `YY.MM.DD[.V]` → **Livré** ; sinon **Prêt à livrer**.
3. PR build ouverte → son état ci-dessus.
4. PR spec fusionnée → **Spec acceptée** ; sinon PR spec ouverte.
5. PR intent fusionnée → **Intent accepté** ; sinon PR intent ouverte.

`status` affiche aussi les preuves : chaque gate franchi (date, PR, auteur de la fusion), l’état des checks, et les incidents enfants (`Parent: <id>`).

## La revue par Claude

`REVIEW.md` est écrit pour être lu par Claude comme par les humains. Deux intégrations décrites dans le playbook s’y branchent sans modifier le kit :

- **Code Review géré** : un administrateur l’active et choisit les dépôts ; la revue suit `REVIEW.md`. Documentation : https://code.claude.com/docs/en/code-review
- **claude-code-action** dans vos propres Actions : un commentaire `@claude` sur la PR demande une correction, poussée sur la branche. Documentation : https://code.claude.com/docs/en/github-actions

Dans les deux cas, Claude commente ; il ne fusionne pas. La gate reste la fusion, faite par un humain.

## À indiquer dans CLAUDE.md

```markdown
## SDLC
- Travaille uniquement sur la branche need/<id>/<étape> en cours ; jamais sur main.
- Chaque commit se termine par les trailers `Need: <id>` et `Stage: <étape>` (intent → plan, spec → design, build → build).
- En build, commence par intent/<id>/plan.md (plan mode) ; s’il change, mets-le à jour dans la même PR.
- Ne modifie pas intent.md ni spec.md dans une PR build : ils ont leurs propres PR.
- N’exécute jamais git sdlc merge, gh pr merge ni git sdlc release : ce sont des gates humains.
- Pour une revue, suis REVIEW.md.
```

## Points d’attention

- **Séparation des tâches.** Sans approbation requise, GitHub laisse toute personne ayant le droit d’écriture fusionner, y compris l’auteur de la PR. Le rôle (PO pour intent et spec, tech lead pour le build) et « l’auteur ne fusionne pas sa propre PR » sont des conventions : `status` les rend visibles, rien ne les impose. Réservez le droit d’écriture en conséquence.
- **Hooks client.** `commit-msg` se contourne avec `--no-verify`. Le check `sdlc-conventions`, requis par le ruleset, refait les mêmes vérifications côté GitHub.
- **Mode de fusion.** Seul le rebase garde les trailers `Need:`/`Stage:` sur chaque commit ; un squash les fusionnerait au gré du message. `setup` désactive squash et merge commit. `git sdlc merge` appelle `gh pr merge --rebase --delete-branch` (clé `mergeArgs` de `.sdlc/config`) : la branche distante et la branche locale sont supprimées. L’auteur de la fusion n’est connu que par l’API GitHub : sans elle (hors ligne, PR au-delà de `prLimit`), `status` retrouve l’étape par les trailers mais pas qui l’a fusionnée.
- **Recette.** La checklist de la PR build demande une recette validée, refaite après toute modification. C’est déclaratif : rien ne la vérifie.
- **Branches hors besoin.** `Need:` n’est exigé que sur `need/*` ; ailleurs le hook ajoute `Need: none` et le check vérifie seulement que `intent/` n’est pas touché.
- **Volume.** `status` et `board` lisent les `prLimit` (300) PR les plus récentes ciblant `main`. Augmentez la valeur dans `.sdlc/config` si besoin.
- **Validation.** Le kit a été testé de bout en bout contre un GitHub simulé (PR, revues, fusions, releases, check CI réellement exécuté). Lancez `git sdlc setup --dry-run` puis vérifiez les rulesets créés dans *Settings → Rules* lors de la première installation.
