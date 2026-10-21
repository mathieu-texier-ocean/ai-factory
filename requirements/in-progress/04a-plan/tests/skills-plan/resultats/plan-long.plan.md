# Plan : Jeu de test : huit contrôles de forme au commit

<!-- Un lot = un plan = une PR ; une étape = un commit. Le plan est accepté avant tout code. S'il est modifié une fois validé, il repasse en draft. -->

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** Agent (skill generation-plan), à compléter par le développeur · **Statut :** draft
- **À risque :** non
- **Validation :** Développeur
- **Base :** non précisée par le développeur (arbre de travail observé : `feat/lot-4a-plan`, `9d10950`)

## Prérequis

- Spec `validé` et commitée (`spec.md`, commit `f56435d`) ; intent `validé`.
- Une seule PR pour le lot.
- Base de départ : à confirmer par le développeur.
- Lots dont celui-ci dépend : aucun (`Dépend de : —`).

## Fichiers touchés

| Fichier | Nature | Étape |
|---|---|---|
| `hooks/pre-commit` | modifié | 1, 2, 3, 4, 5, 6, 7, 8 |
| `hooks/tests/hook-forme/run.sh` | nouveau (étape 1), modifié ensuite | 1, 2, 3, 4, 5, 6, 7, 8 |
| `hooks/tests/hook-forme/fixtures/` (un fichier par défaut, plus un fichier sain) | nouveau | 1, 2, 3, 4, 5, 6, 7, 8 |

## Étapes

<!-- Une étape par contrôle, à la demande du développeur. Avertissement émis : 8 étapes (> 7) et étapes indépendantes entre elles ; le développeur maintient le plan tel quel. -->

### 1. Contrôle de taille de fichier

Ajoute à `hooks/pre-commit` le refus d'un fichier ajouté de plus de 1 Mo, message `<fichier> : <contrôle>`, code 1. Crée `hooks/tests/hook-forme/run.sh` (dépôt git temporaire, sur le modèle de `hooks/tests/hook-spec/run.sh`) avec le cas sain et le cas « fichier > 1 Mo », binaire compris.

Couvre : C1, C9, L1, A1, A2.

### 2. Contrôle des fins de ligne

Refus d'une ligne ajoutée terminée par `\r\n` ; fichiers binaires exclus.

Couvre : C2, C9, L1, A1, A2.

### 3. Contrôle des tabulations dans le Markdown

Refus d'une tabulation dans une ligne ajoutée d'un `.md` ; fichiers binaires exclus.

Couvre : C3, C9, L1, A1, A2.

### 4. Contrôle du BOM UTF-8

Refus d'un fichier commençant par un BOM UTF-8 ; fichiers binaires exclus.

Couvre : C4, C9, L1, A1, A2.

### 5. Contrôle des marqueurs de conflit

Refus d'une ligne ajoutée commençant par `<<<<<<<`, `=======` ou `>>>>>>>` ; fichiers binaires exclus.

Couvre : C5, C9, L1, A1, A2.

### 6. Contrôle du bit exécutable des scripts

Refus d'un fichier `.sh` ajouté sans bit exécutable (mode lu dans l'index) ; s'applique aussi aux binaires.

Couvre : C6, C9, L1, A1, A2.

### 7. Contrôle des espaces dans les noms de fichiers

Refus d'un chemin ajouté contenant une espace ; s'applique aussi aux binaires.

Couvre : C7, C9, L1, A1, A2.

### 8. Contrôle de la longueur des lignes

Refus d'une ligne ajoutée de plus de 400 caractères ; fichiers binaires exclus.

Couvre : C8, C9, L1, A1, A2.

## Tests à écrire

- Automatisés : `hooks/tests/hook-forme/run.sh`, enrichi à chaque étape. Par contrôle : un fichier porteur du défaut, commit refusé, code 1, message `<fichier> : <contrôle>` (A1, C9) ; un fichier sain accepté (A2) ; un fichier binaire soumis à C1, C6 et C7 seulement (L1).
- Commande, depuis la racine : `bash scripts/verifier.sh` (lance aussi `hooks/tests/hook-intent`, `hook-spec`, `hook-credential`, pour vérifier que les contrôles existants ne régressent pas).
- Manuel : aucun prévu.

## Couverture de la spec

| Réf. | Étape |
|---|---|
| C1 | 1 |
| C2 | 2 |
| C3 | 3 |
| C4 | 4 |
| C5 | 5 |
| C6 | 6 |
| C7 | 7 |
| C8 | 8 |
| C9 | 1, 2, 3, 4, 5, 6, 7, 8 |
| L1 | 1, 2, 3, 4, 5, 6, 7, 8 |
| A1 | 1, 2, 3, 4, 5, 6, 7, 8 |
| A2 | 1, 2, 3, 4, 5, 6, 7, 8 |

## Risques

- **Ce que le changement peut casser** (développeur) : un contrôle trop strict peut bloquer des commits légitimes.
- **Étape la plus risquée** (développeur) : le contrôle des fins de ligne (étape 2). Parade : ne lire que les lignes ajoutées de l'index (`git diff --cached`), exclure les binaires (L1), et tester avec un fixture CRLF et un fichier sain. Parade non discutée avec le développeur : à confirmer.
- **Taille et découpage** : 8 étapes (au-delà de 7) et étapes indépendantes entre elles ; l'intent est peut-être à découper. Le développeur maintient le plan tel quel.
- **Questions restées sans réponse** (relevées à la lecture du code, non posées au développeur, joignable seulement sur les questions prévues) :
  - Les fixtures de `hooks/tests/hook-forme/fixtures/` portent les défauts (CRLF, tabulation, BOM, marqueurs, lignes longues, espace dans le nom) : le hook les refusera au commit du lot, sauf exclusion de `tests/<nom>/fixtures/` comme pour le contrôle de credential. La spec ne le prévoit pas.
  - Fixture de C1 (> 1 Mo) : commité ou généré par `run.sh` ? Non tranché.
  - C5 : une ligne `=======` sert aussi de soulignement de titre Markdown (setext) ; elle serait refusée. Non tranché.
  - Mise à jour des lignes `hooks/pre-commit` de `CLAUDE.md` et `README.md`, qui énumèrent les contrôles : non prévue par la spec, non tranchée.
- **Options écartées** (développeur) : un outil externe comme pre-commit (Python), écarté : bash et git seulement.

## Hors périmètre

- Correction automatique des fichiers.
