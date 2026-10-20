# Plan — Lot 1h : Livrables rangés à la racine

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** validé
- **Validation :** Tech lead
- **Base :** `main` (18e7ba1, spec du lot 1h validée).

## Prérequis

- `spec.md` commitée au statut `validé` : fait (18e7ba1).
- Une seule PR pour le lot (contrainte de l'intent). Chaque étape ci-dessous = un commit.
- `core.hooksPath` vaut `hooks` dans le clone de travail.
- Les deux `run.sh` passent à leur emplacement actuel avant de commencer (référence) : `bash requirements/closed/02-intent/tests/hook-intent/run.sh` et `bash requirements/closed/03-spec/tests/hook-spec/run.sh`.

## Arbitrages des points d'attention (2026-10-19)

- **P1 :** le dossier du lot 1h est exclu de la recherche des anciens chemins des tests : son intent et sa spec décrivent l'état d'avant.
- **P2 :** les deux renvois « sur le modèle de » du lot 1c (étape 2 du plan, C10 de la spec) sont corrigés ici. La recherche n'a pas d'autre exception que P1. La spec 1c garde son statut `validé` : seul un chemin change.
- **P4 :** le plan et la spec du lot 3 sont corrigés sans revalidation : seuls des chemins changent.
- **P6 :** le renvoi vers `ia-factory.md` est retiré du README sans remplacement.
- **P7 :** relève du lot 10, aucune action ici (voir R3).

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `requirements/open/01h-livrables-racine/` → `requirements/in-progress/01h-livrables-racine/` | déplacé | 1 |
| `requirements/open/ia-factory.md` | modifié (lien du lot 1h) | 1 |
| `requirements/closed/02-intent/tests/hook-intent/` → `hooks/tests/hook-intent/` | déplacé (`run.sh`, 6 fixtures) | 2 |
| `requirements/closed/03-spec/tests/hook-spec/` → `hooks/tests/hook-spec/` | déplacé (`run.sh`, 5 fixtures) | 2 |
| `requirements/in-progress/01a-contexte/plan.md` | modifié (2 commandes) | 3 |
| `requirements/closed/03-spec/plan.md`, `spec.md` | modifiés (chemins) | 3 |
| `requirements/in-progress/01c-hook-credential/plan.md`, `spec.md` | modifiés (renvois « sur le modèle de ») | 3 |
| `README.md` | modifié | 4 |
| `requirements/in-progress/01h-livrables-racine/validation.md` | nouveau | 5 |

Aucun hook ni skill modifié, aucun nouveau test (hors périmètre).

## Étapes

### 1. Passer le lot en cours

`git mv requirements/open/01h-livrables-racine requirements/in-progress/`, puis mettre à jour la ligne 1h du tableau des sous-intents de `ia-factory.md` : `[01h-livrables-racine/intent.md](../in-progress/01h-livrables-racine/intent.md)`.

Commit : `Lot 1h : passe le lot en cours`.

Couvre : convention du README (cycle d'un lot).

### 2. Déplacer les tests des hooks

```
mkdir -p hooks/tests
git mv requirements/closed/02-intent/tests/hook-intent hooks/tests/hook-intent
git mv requirements/closed/03-spec/tests/hook-spec hooks/tests/hook-spec
```

Le commit ne contient que ces renommages (C2, L2). Avant de committer :

- `git diff --cached -M --stat` : uniquement des `=>`, aucune ligne ajoutée ni retirée (C3) ;
- `git diff --cached --summary` : `rename … (100%)`, aucun `mode change` (mode `100755` des `run.sh` conservé) ;
- `bash hooks/tests/hook-intent/run.sh` et `bash hooks/tests/hook-spec/run.sh` : tout `PASS` (C3, L4 : lancer une fois depuis la racine, une fois depuis `/tmp`) ;
- `ls requirements/closed/02-intent/tests requirements/closed/03-spec/tests` : `skills-intent` et `skills-spec` seuls (C4).

Le README cite encore les anciens chemins jusqu'à l'étape 4 : état intermédiaire interne à la PR.

Commit : `Lot 1h : range les tests des hooks dans hooks/tests/`.

Couvre : C1 à C5, L3, L4.

### 3. Mettre à jour les références des lots

Remplacer les anciens chemins, sans autre changement de texte :

- plan 1a, section Commandes (étape 1) : `bash hooks/tests/hook-intent/run.sh` et `bash hooks/tests/hook-spec/run.sh` (C9) ;
- plan du lot 3 : `tests/hook-spec/…` → `hooks/tests/hook-spec/…` et `tests/hook-intent/…` → `hooks/tests/hook-intent/…` (tableau des fichiers, étape 2, non-régression, vérification, tests à écrire). `tests/skills-spec/` et `tests/skills-intent/` ne changent pas (C10) ;
- spec du lot 3, section Contrats : même remplacement (C10) ;
- plan 1c, étape 2 : `requirements/closed/02-intent/tests/hook-intent/run.sh` → `hooks/tests/hook-intent/run.sh` (P2) ;
- spec 1c, C10 : `tests/hook-spec/run.sh` → `hooks/tests/hook-spec/run.sh` (P2).

Puis : `git grep -nP '(?<!hooks/)tests/hook-(intent|spec)' -- ':!requirements/*/01h-livrables-racine/*'` ne renvoie que les lignes du README, traitées à l'étape 4.

Commit : `Lot 1h : met à jour les chemins des tests des hooks dans les lots`.

Couvre : C9, C10, P2, P4.

### 4. README

- Retirer la ligne « Vue d'ensemble, lots et critères de succès : [requirements/open/ia-factory.md](…) » (C13, P6).
- Ligne 9 : garder « Ce README couvre les étapes **Intent** (lot 2) et **Spec** (lot 3). », retirer la phrase « Les étapes suivantes sont décrites dans le dossier de leur lot (…) » (C13).
- Tableau « Ce que contient le dépôt » : remplacer les lignes `requirements/closed/02-intent/tests/` et `requirements/closed/03-spec/tests/` par `| hooks/tests/ | Tests des hooks git : sections de l'intent (hook-intent), intent validé (hook-spec) |` (C6).
- Mise en route, étape 3, et section « Vérifier » : `bash hooks/tests/hook-intent/run.sh` et `bash hooks/tests/hook-spec/run.sh` (C7).
- « Vérifier » : retirer les deux puces des jeux de données des skills, les remplacer par « La recette manuelle d'un skill (jeux de données, résultats) est consignée dans le dossier du lot qui l'a livré. » (C13).
- « Créer un intent », étape 1 : « les liens qui le citent (par exemple dans `ia-factory.md`) » → « les liens qui le citent (par exemple dans l'intent parent) » (C12 : ni `ia-factory.md`).
- Nouvelle section `## Ranger les livrables`, avant « Règles à respecter », avec les trois règles de C8 en puces.

Puis :

- `git grep -nP '(?<!hooks/)tests/hook-(intent|spec)' -- ':!requirements/*/01h-livrables-racine/*'` : aucune ligne (C11, A4) ;
- `git grep -nE 'requirements/(open|in-progress|closed)/([0-9]|ia-factory)' -- ':!requirements'` : aucune ligne (C12, A7) ;
- `git grep -n 'ia-factory.md' -- ':!requirements'` : aucune ligne.

Commit : `Lot 1h : documente le rangement des livrables hors de requirements/`.

Couvre : C6, C7, C8, C11 à C13, L8, L9.

### 5. Recette

Sur un clone propre de la branche (`git clone . "$tmp"`), lancer les critères et consigner commandes et sorties dans `validation.md` :

- A1 : `ls hooks/tests/hook-intent hooks/tests/hook-spec` ; `git log --follow --oneline` sur les deux `run.sh`, `fixtures/complet.md` et `fixtures/intent-valide.md` → des commits des lots 2 et 3.
- A2 : les deux `run.sh` → tout `PASS`, code 0.
- A3 : dans le clone, `git mv requirements/closed/03-spec requirements/closed/03-spec-x`, relancer les deux `run.sh` → tout `PASS`. Le clone est jeté ensuite.
- A4 et A7 : les deux recherches de l'étape 4 → aucune ligne.
- A5 : relecture du README par le tech lead, en PR.
- A6 : `ls requirements/closed/02-intent/tests requirements/closed/03-spec/tests`.
- A8 : la copie décrite dans les Contrats de la spec, depuis le clone, puis les deux `run.sh` → tout `PASS`. Vérifier aussi qu'aucun lien relatif du README ne pointe vers un fichier absent de la copie (C14).

Commit : `Lot 1h : consigne la recette`. Puis ouverture de la PR par l'humain, relue par le tech lead (A5).

Couvre : A1 à A8, C14, L10.

## Tests à écrire

- Aucun nouveau test (hors périmètre de l'intent) : les `run.sh` existants sont déplacés tels quels.
- Les critères `Automatisé` sont des commandes, lancées à l'étape 5 et consignées dans `validation.md`.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1 à C5 | 2 |
| C6 à C8 | 4 |
| C9, C10 | 3 |
| C11 à C13 | 4 |
| C14 | 5 |
| L1 | 5 (A3) |
| L2, L3, L4 | 2 |
| L5 | sans action : protection du lot 1g |
| L6 | R2 |
| L7 | P1, exclusion de la recherche |
| L8, L9 | 4 |
| L10 | 5 (A8) |
| L11 | sans action : copie faite depuis git |
| L12 | R1 |
| A1 à A8 | 5 |

## Risques

- **R1 — Lot 1a.** Sa branche `feat/lot-01a-contexte` cite les anciens chemins dans `CLAUDE.md` (section Commandes) et `README.md`. Son plan (étape 2, Architecture) prescrit aussi « `requirements/<état>/<NN-lot>/` (artefacts d'un lot et ses `tests/`) », contraire à C8. Le premier lot mergé impose un rebase à l'autre ; 1a doit reprendre les nouveaux chemins et la règle de rangement (L12, hors périmètre).
- **R2 — Lot 1b.** Sa spec (C2) découvre les `run.sh` dans les dossiers de lots : tant qu'elle n'est pas révisée, `scripts/verifier.sh` ignorerait `hooks/tests/` (L6).
- **R3 — Lot 10.** Il réécrira le README : il doit reprendre la section « Ranger les livrables » et la règle C12 (P7, décideur PO).
- **R4 — Commits non poussés.** `main` est en avance sur `origin/main` (lots 1a, 1g, 1h). La PR du lot 1h partira de commits encore locaux : à pousser par l'humain dans le bon ordre.

## Hors périmètre

Ceux de la spec : nouveaux tests, comportement des hooks et skills, commande unique de vérification (1b), révision des specs 1b, 1c (hors renvois P2) et 1f, jeux de données des skills, mécanisme de copie, `CLAUDE.md` du lot 1a, chemin périmé de `skills-intent/README.md`.
