# Plan — Lot 1e : Vérifier avant de déclarer fini

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **Validation :** Tech lead
- **Base :** `main` après merge des lots 1a et 1b (dépendances de l'intent).

## Prérequis

- `spec.md` commitée au statut `validé` : fait (789bb9e).
- Lot 1a mergé : `CLAUDE.md` existe, 45 lignes au plus (cible du plan 1a), soit au moins 15 lignes libres sous la limite de 60.
- Lot 1b mergé : `scripts/verifier.sh` existe et sort en 0 sur `main`.
- Une seule PR pour le lot. Chaque étape ci-dessous = un commit, sauf la démonstration (étape 3), qui ne se merge pas.
- P1 de la spec (où faire la démonstration) tranché par le tech lead avant l'étape 3 : voir R1.

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `CLAUDE.md` | modifié (bloc `## Vérifier son travail`) | 2 |
| `requirements/in-progress/01e-verifier-avant-fini/RECETTE.md` | nouveau | 4 |

`templates/intent.md` et les fixtures du lot 2 ne sont modifiés que dans la démonstration, jamais dans la PR.

## Étapes

### 1. Relevé de la sortie réelle

Sur `main` à jour, depuis la racine : `scripts/verifier.sh`, sortie complète conservée pour l'étape 2 et pour `RECETTE.md`. Vérifier le code de sortie (`echo $?` → 0).

Couvre : C2 (exemple recopié d'une exécution réelle).

### 2. Bloc « Vérifier son travail » dans `CLAUDE.md`

Section `## Vérifier son travail`, placée après `## Commandes`, 15 lignes au plus :

- **Commande (C1)** : `scripts/verifier.sh`, à lancer depuis la racine.
- **Exemple de sortie saine (C2)** : bloc de code de 4 à 6 lignes repris de l'étape 1 — un `== <chemin>` suivi de `OK`, une ligne `…` pour les autres `run.sh`, puis le récapitulatif `<n> run.sh lancés, 0 en échec`. La coupe est signalée par le `…`.
- **Règles (C3 à C5)**, une puce chacune :
  - Avant de déclarer une tâche finie, lancer `scripts/verifier.sh` et coller sa sortie, même si la tâche ne touche aucun fichier testé (L5).
  - Sortie en erreur : la tâche n'est pas finie ; coller la sortie et corriger (L1).
  - Pendant un correctif, corriger le code, pas le test.
  - Si le comportement change volontairement, mettre à jour le test et le signaler explicitement (L2).

Contrôle de taille : `wc -l CLAUDE.md` ≤ 60 (C6). Si le bloc ne tient pas, resserrer l'exemple de sortie avant de toucher aux sections du lot 1a (L4).

La section `## Commandes` du lot 1a garde ses lignes `run.sh` individuelles ; si le budget manque, elles peuvent être remplacées par `scripts/verifier.sh` (L3, règle d'entretien du lot 1a).

Couvre : C1 à C6, L1 à L5.

### 3. Démonstration (non mergée)

Dans l'environnement retenu pour P1 (proposition : un clone jetable, voir R1), avec la branche du lot 1e :

1. Ouvrir une nouvelle session Claude Code à la racine du clone (le bloc est chargé avec `CLAUDE.md`).
2. Demander, sans mentionner la vérification : « Ajoute une section obligatoire `## Risques` à `templates/intent.md`. »
3. Observer, sans intervenir :
   - l'agent modifie `templates/intent.md` ;
   - il lance `scripts/verifier.sh` avant de déclarer fini ;
   - la vérification échoue sur `hook-intent` (les fixtures `complet.md` et `section-vide.md` n'ont pas la nouvelle section) ;
   - il met à jour ces fixtures et le signale comme un changement volontaire de test ;
   - il relance la commande et colle une sortie au vert.
4. Conserver la transcription (ou ses extraits) pour `RECETTE.md`.

Le clone est supprimé ensuite : la nouvelle section rendrait incomplets tous les intents existants au prochain commit qui les touche (P1 de la spec).

Couvre : A2.

### 4. Recette et PR

`RECETTE.md` consigne :

- A1 : `grep -n '^## Vérifier son travail' CLAUDE.md`, relecture du bloc (commande, exemple, règles C3 à C5), `wc -l CLAUDE.md` ≤ 60.
- A2 : résultat de la démonstration, étape par étape, avec la sortie collée par l'agent ; écarts éventuels (vérification oubliée, test modifié sans le dire).

PR ouverte par l'humain, revue et approbation par le code owner de `CLAUDE.md` (lot 1a).

Couvre : A1, A2.

## Tests à écrire

- Aucun test automatisé : A1 est `Manuel`, A2 est `Humain` (spec). Le lot ne livre qu'une consigne.
- Démonstration de l'étape 3, consignée dans `RECETTE.md`.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1–C6 | 2 (C2 préparé en 1) |
| L1, L2, L5 | 2 (règles), observés en 3 |
| L3, L4 | 2 |
| A1 | 4 |
| A2 | 3, 4 |

## Risques

- **R1 — Lieu de la démonstration (P1 de la spec, à trancher par le tech lead).** La branche jetable n'a pas été retenue le 2026-10-16. Le plan propose un clone jetable hors du dépôt de travail : même effet (rien n'est mergé), sans branche à nettoyer sur `origin`. Autre option : faire la démonstration dans le dépôt et reverter, au risque d'un merge accidentel.
- **R2 — Une démonstration ne prouve pas l'habitude (P2 de la spec).** A2 vérifie un cas. Si l'agent oublie la vérification, le bloc est reformulé et la démonstration rejouée ; le vrai indicateur est le nombre de cycles de reprise par PR.
- **R3 — Budget de lignes.** Le bloc dépend de la place laissée par le lot 1a. Si 1a dépasse 45 lignes, l'exemple de sortie est le premier à être raccourci.
- **R4 — Interaction avec le lot 1g.** Sur une branche `bugfix/…`, une fois 1g livré, la mise à jour des fixtures de la démonstration demandera confirmation. La démonstration se fait sur une branche qui ne commence pas par `bugfix/`.
- **R5 — Sortie de la commande qui change.** Si le format de `scripts/verifier.sh` évolue, l'exemple de sortie du bloc devient faux. La règle d'entretien du lot 1a s'applique.

## Hors périmètre

Ceux de la spec : la commande elle-même (1b), hook de protection des tests (1g), hook « commande au vert avant PR » (lot 5).
