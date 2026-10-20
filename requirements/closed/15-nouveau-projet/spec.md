# Spec : Déployer ai-factory dans un nouveau projet

<!-- Numéros C, L et A stables : une révision ajoute un nouveau numéro, elle ne renumérote jamais. Le lot 4 (plan) et le lot 7 (recette) s'y réfèrent. -->

- **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu Texier
- **Statut :** validé
- **Validation :** Tech lead

## Périmètre

Un script bash d'ai-factory, copié dans chaque projet, qui crée un nouveau projet à partir d'un clone d'ai-factory puis y répercute les évolutions ultérieures. La copie suit une liste blanche. `CLAUDE.md` et `README.md` sont produits depuis des modèles. Un manifeste garde le SHA d'origine et l'empreinte de chaque fichier copié, pour qu'une mise à jour n'écrase jamais une modification locale. Le script ne fait aucune opération Git dans le projet.

## Comportements

### Script et commandes

- **C1.** Le script est `scripts/ai-factory.sh`. Il a deux commandes : `create` (création d'un projet) et `update` (répercussion des évolutions). Voir « Contrats ».
- **C2.** Le script n'utilise que bash et des outils standards (`git`, `sha256sum`, `find`, `ls`, `sed`, `mkdir`, `mktemp`, `cp`, `mv`, `rm`, `chmod`). Il n'installe rien.
- **C3.** Le script ne fait aucune opération Git dans le projet : ni `git init`, ni `add`, ni commit. Dans le clone d'ai-factory, il ne fait que des lectures (`git rev-parse`, `git ls-tree`, `git cat-file`, `git merge-base`, `git status`).

### Source copiée

- **C4.** La source est le commit `HEAD` du clone d'ai-factory. Le contenu de chaque fichier est lu à ce commit, pas dans l'arbre de travail : le SHA du manifeste décrit exactement ce qui a été copié. Les modifications non commitées du clone sont ignorées, et le script le signale.
- **C5.** Les fichiers copiés sont les fichiers suivis par Git à `HEAD` qui relèvent de la liste blanche : `.claude/`, `hooks/`, `scripts/` (le script compris), `templates/` sauf `templates/projet/`, et `.gitignore`. Rien d'autre n'est copié, notamment `requirements/`, `documents/`, `.obsidian/`, `CLAUDE.md` et `README.md` d'ai-factory.
- **C6.** La liste blanche est écrite dans le script, à un seul endroit. Ajouter un dossier à la copie revient à modifier cette liste.
- **C7.** Le script refuse une source qui n'est pas un clone d'ai-factory : dossier hors d'un dépôt Git, ou dépôt sans `templates/projet/CLAUDE.md` et `templates/projet/README.md` à `HEAD`.

### Modèles `CLAUDE.md` et `README.md`

- **C8.** `templates/projet/CLAUDE.md` et `templates/projet/README.md` sont les modèles des fichiers du projet. Ils sont exclus de la copie (C5).
- **C9.** Les sections communes (commandes, vérification, conventions, cycle des lots) y sont remplies. Les sections propres au projet (architecture, erreurs fréquentes) sont vides, avec un commentaire guide.
- **C10.** Le marqueur `{{nom-projet}}` des modèles est remplacé par le nom du projet, tel quel, sans interprétation de ses caractères.
- **C11.** Les fichiers produits, `CLAUDE.md` et `README.md` à la racine du projet, sont traités comme des fichiers copiés : ils figurent au manifeste avec l'empreinte de la version produite, et suivent les règles de mise à jour (C21 à C29).

### Manifeste

- **C12.** Le manifeste est `.ai-factory/manifeste`, dans le projet. Format dans « Contrats ».
- **C13.** Il contient le SHA du commit source, le nom du projet, puis une ligne par fichier géré : empreinte sha256 et chemin relatif à la racine du projet.
- **C14.** Le manifeste n'est pas listé dans lui-même. Il est réécrit en entier à la fin d'une création ou d'une mise à jour réussie, jamais en cours de route.

### Création (`create`)

- **C15.** Lancée depuis un clone d'ai-factory, avec le dossier cible et le nom du projet. La source est le dépôt qui contient le script lancé.
- **C16.** Elle refuse, sans rien écrire, un dossier cible existant et non vide. Un dossier cible absent est créé, ses parents compris ; un dossier vide est accepté.
- **C17.** Elle refuse, sans rien écrire, un nom de projet vide.
- **C18.** Elle refuse, sans rien écrire, une source qui contient `.ai-factory/manifeste` à `HEAD` : c'est un projet, pas ai-factory.
- **C19.** Elle copie les fichiers de C5, produit `CLAUDE.md` et `README.md` (C10), puis écrit le manifeste (C13).
- **C20.** En fin d'exécution, elle affiche la marche à suivre, sans l'exécuter : `cd <cible>`, `git init`, `git config core.hooksPath hooks`.

### Mise à jour (`update`)

- **C21.** Lancée depuis la racine du projet, avec le chemin d'un clone d'ai-factory. Elle refuse, sans rien écrire, un dossier sans `.ai-factory/manifeste` et une source qui ne vérifie pas C7.
- **C22.** Pour chaque chemin présent au manifeste ou dans la nouvelle source, le script compare trois empreintes : celle du manifeste (M), celle du fichier du projet (L) et celle de la nouvelle source (N). `CLAUDE.md` et `README.md` sont reproduits depuis les nouveaux modèles avec le nom du manifeste avant le calcul de N.
- **C23.** Fichier intact (L = M) : il est remplacé par la nouvelle version si elle diffère, supprimé si elle n'existe plus. Le manifeste suit.
- **C24.** Fichier modifié localement (L ≠ M), inchangé dans ai-factory (N = M) : il est conservé, le manifeste ne change pas.
- **C25.** Fichier modifié localement et changé dans ai-factory (L ≠ M, N ≠ M) : le fichier est conservé, la nouvelle version est écrite en `<fichier>.nouveau`, et le manifeste prend N. Le conflit n'est donc proposé qu'une fois par version d'ai-factory. Si L = N, rien n'est écrit et le manifeste prend N.
- **C26.** Fichier modifié localement et supprimé dans ai-factory : il est conservé et sort du manifeste ; il devient un fichier du projet.
- **C27.** Fichier du manifeste absent du projet (supprimé localement) : il n'est pas recréé et sa ligne reste au manifeste, pour que la suppression soit respectée aux mises à jour suivantes. Si ai-factory l'a changé (N ≠ M), la nouvelle version est écrite en `<fichier>.nouveau` et le manifeste prend N. S'il a aussi été supprimé dans ai-factory, sa ligne sort du manifeste.
- **C28.** Nouveau fichier d'ai-factory (absent du manifeste) : s'il est absent du projet, il est copié et ajouté au manifeste. S'il existe dans le projet avec un autre contenu, le fichier du projet est conservé, la version d'ai-factory est écrite en `<fichier>.nouveau`, et le chemin entre au manifeste avec N : il sera ensuite traité comme un fichier modifié localement. S'il existe avec le même contenu, il entre au manifeste sans rien écrire.
- **C29.** Un renommage dans ai-factory est traité comme la suppression de l'ancien chemin (C23, C26, C27) et l'ajout du nouveau (C28).
- **C30.** En fin d'exécution, le script liste, par catégorie : fichiers remplacés, ajoutés, supprimés, droits alignés (C39), `.nouveau` écrits, fichiers supprimés localement non recréés, fichiers sortis du manifeste. Il affiche l'ancien et le nouveau SHA.
- **C31.** Si le SHA de la source est celui du manifeste et qu'aucun modèle ne change, le script le dit et ne modifie rien.
- **C32.** La mise à jour de `scripts/ai-factory.sh` lui-même n'altère pas l'exécution en cours : le fichier n'est remplacé qu'après tous les autres, par renommage.

### Arbitrages du 2026-10-20

- **C34.** `update` refuse, sans rien écrire, une source dont le `HEAD` ne descend pas du SHA du manifeste : clone plus ancien, branche divergente, ou SHA inconnu du clone. Le message donne les deux SHA. L'option `--forcer` passe outre : le script affiche un avertissement puis applique les règles C22 à C32.
- **C35.** Le `.gitignore` d'ai-factory, copié dans le projet (C5), contient `*.nouveau` : un fichier de conflit n'est pas commité par erreur.

- **C36.** Le texte de `templates/projet/CLAUDE.md` et `templates/projet/README.md` est écrit dans ce lot, à partir du `CLAUDE.md` et du `README.md` d'ai-factory. Il ne cite ni ai-factory comme projet courant, ni un lot, ni un fichier précis de `requirements/`.

### Arbitrages de la revue du 2026-10-20

- **C37.** La source est ramenée à la racine de son dépôt (`git rev-parse --show-toplevel`) avant toute lecture : un sous-dossier du clone d'ai-factory vaut le clone entier. Toutes les commandes Git de C3 partent de cette racine.
- **C38.** `update` est toujours exécuté par la version du script de la source. Le script du projet vérifie C21, extrait `HEAD:scripts/ai-factory.sh` de la source dans un fichier temporaire et l'exécute avec les mêmes arguments ; c'est cette version qui applique C22 à C34, avec sa liste blanche. La version déléguée ne délègue pas une seconde fois. Une source sans `scripts/ai-factory.sh` à `HEAD` est refusée, sans rien écrire.
- **C39.** Tout fichier écrit dans le projet (remplacé, ajouté, `.nouveau`) prend le bit exécutable de la source. Un fichier intact (L = M) dont le bit exécutable diffère de celui de la source est aligné sur elle, même si son contenu n'a pas changé. Le manifeste ne garde que le contenu : le bit exécutable d'un fichier modifié localement (L ≠ M) n'est pas touché.
- **C40.** `create` refuse, sans rien écrire, une cible qui existe sans être un dossier, et un dossier cible non lisible ou non traversable.

### Tests

- **C33.** Les tests automatisés du script sont dans `scripts/tests/ai-factory/` (`run.sh` et `fixtures/`), lancés par `scripts/verifier.sh`. Ils construisent un faux clone d'ai-factory dans un dossier temporaire et ne touchent ni le dépôt courant ni le réseau.

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Dossier cible existant et non vide, même avec un seul fichier caché | Refus, rien n'est écrit (C16) |
| L2 | Dossier cible existant et vide | Création acceptée (C16) |
| L3 | `create` lancé depuis un projet déjà créé (copie du script) | Refus : la source contient `.ai-factory/manifeste` (C18) |
| L4 | Clone d'ai-factory avec des modifications non commitées dans la liste blanche | Ignorées, contenu lu à `HEAD`, avertissement affiché (C4) |
| L5 | Fichier non suivi par Git dans un dossier de la liste blanche (ex. `.claude/settings.local.json`) | Non copié (C5) |
| L6 | Nom de projet contenant `/`, `&` ou `\` | Injecté tel quel dans les modèles (C10) |
| L7 | `update` lancé hors de la racine du projet, ou sans manifeste | Refus, rien n'est écrit (C21) |
| L8 | Un `<fichier>.nouveau` existe déjà, d'une mise à jour précédente | Remplacé par la nouvelle version proposée, et listé (C25, C30) |
| L9 | Le projet a modifié puis restauré un fichier à l'identique (L = M) | Traité comme intact, remplacé (C23) |
| L10 | Le projet a déjà appliqué la même modification qu'ai-factory (L = N) | Rien n'est écrit, le manifeste prend N (C25) |
| L11 | Clone d'ai-factory plus ancien que le SHA du manifeste | Refus, rien n'est écrit ; avec `--forcer`, avertissement puis mêmes règles (C34) |
| L12 | `CLAUDE.md` complété dans le projet, modèle changé dans ai-factory | `CLAUDE.md` conservé, `CLAUDE.md.nouveau` écrit (C11, C25) |
| L13 | Mise à jour interrompue en cours de route | Le manifeste n'est pas réécrit (C14) : relancer la mise à jour reprend depuis l'ancien manifeste (voir P5) |
| L14 | Le script lui-même a changé dans ai-factory | Remplacé en dernier, par renommage (C32) |
| L15 | SHA du manifeste absent du clone (clone superficiel, commit non récupéré) ou branche divergente | Refus, rien n'est écrit ; avec `--forcer`, avertissement puis mêmes règles (C34) |
| L16 | `git status` dans le projet après une mise à jour avec conflits | Les `<fichier>.nouveau` n'apparaissent pas : ils sont ignorés (C35) ; seul le rapport de C30 les liste |
| L17 | `update` avec un sous-dossier du clone (ex. `<clone>/scripts`) | Même résultat qu'avec la racine du clone ; aucun fichier supprimé à tort (C37) |
| L18 | Dossier ajouté à la liste blanche dans ai-factory | Copié dès la première mise à jour, par la version déléguée (C38) |
| L19 | Fichier rendu exécutable dans ai-factory sans changement de contenu | Aligné dans le projet s'il est intact, listé en « droits alignés » (C39, C30) |
| L20 | Cible de `create` qui est un fichier ordinaire | Refus, rien n'est écrit (C40) |
| L21 | Cible de `create` qui est un dossier non lisible ou non traversable | Refus, rien n'est écrit (C40) |

## Contrats

- **Script :** `scripts/ai-factory.sh` ; tests : `scripts/tests/ai-factory/run.sh`.
- **Création :** `<clone ai-factory>/scripts/ai-factory.sh create <dossier cible> <nom du projet>`.
- **Mise à jour :** depuis la racine du projet, `scripts/ai-factory.sh update [--forcer] <chemin du clone ai-factory>`.
- **Codes de retour :** 0 si l'opération est faite, `.nouveau` écrits compris ; 1 en cas de refus (C7, C16 à C18, C21, C34, C38, C40) ou d'argument manquant, avec un message sur la sortie d'erreur et aucun fichier écrit ; 2 pour une commande inconnue, avec l'usage.
- **Manifeste `.ai-factory/manifeste` :**

  ```
  ai-factory <SHA de 40 caractères>
  projet <nom du projet>
  <sha256>  <chemin relatif>
  …
  ```

  Les lignes de fichiers suivent le format de `sha256sum`, triées par chemin (`LC_ALL=C`).
- **Modèles :** `templates/projet/CLAUDE.md`, `templates/projet/README.md`, marqueur `{{nom-projet}}`.
- **Fichier de conflit :** `<chemin>.nouveau`, à côté du fichier concerné.

## Critères d'acceptation

<!-- Écart au skill generation-spec : les lignes A partent des deux « Critères de succès » de l'intent, qui n'a pas de section « Critère d'acceptation » (décision de l'auteur du 2026-10-20, voir P1). -->

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | `verifier.sh` passe dans un projet créé, sans `requirements/` | Un clone d'ai-factory, un dossier cible absent | On lance `scripts/ai-factory.sh create <cible> demo`, puis dans `<cible>` `git init`, `git config core.hooksPath hooks` et `bash scripts/verifier.sh` | Le projet n'a ni `requirements/`, ni `documents/`, ni `.obsidian/` ; `verifier.sh` sort en 0 avec 0 run.sh en échec | Automatisé |
| A2 | Un fichier intact est mis à jour | Un projet créé ; un fichier de `hooks/` modifié et commité dans ai-factory | On lance `update` depuis le projet | Le fichier du projet a le nouveau contenu ; le manifeste porte le nouveau SHA et la nouvelle empreinte | Automatisé |
| A3 | Une modification locale n'est pas écrasée | Un projet dont `CLAUDE.md` est complété ; le modèle `templates/projet/CLAUDE.md` modifié et commité dans ai-factory | On lance `update` | `CLAUDE.md` est inchangé ; `CLAUDE.md.nouveau` contient le nouveau modèle avec le nom du projet ; le rapport le liste | Automatisé |
| A4 | Une suppression locale est respectée | Un projet où un skill de `.claude/skills/` a été supprimé ; ce skill modifié dans ai-factory | On lance `update` deux fois de suite | Le skill n'est pas recréé ; un `.nouveau` est écrit à la première exécution seulement ; le rapport le liste | Automatisé |
| A5 | Un fichier supprimé dans ai-factory ne détruit pas une modification locale | Un projet avec un fichier A intact et un fichier B modifié localement ; A et B supprimés dans ai-factory | On lance `update` | A est supprimé du projet ; B est conservé et sort du manifeste | Automatisé |
| A6 | Un fichier du projet n'est pas écrasé par un nouveau fichier d'ai-factory | Un projet qui a créé `templates/x.md` ; `templates/x.md` ajouté avec un autre contenu dans ai-factory | On lance `update` | `templates/x.md` est inchangé ; `templates/x.md.nouveau` est écrit ; le chemin entre au manifeste | Automatisé |
| A7 | Les lots en cours du projet ne sont pas touchés | Un projet avec un dossier `requirements/open/01-x/` | On lance `update` | `requirements/` est identique avant et après | Automatisé |

## Points d'attention

- **P1. Critères d'acceptation absents de l'intent.** Le template d'intent n'a pas de section « Critère d'acceptation », et le skill `generation-spec` interdit de dériver les lignes A du « Critère de succès ». Tranché le 2026-10-20 : écart accepté pour ce lot, A1 à A7 partent des deux critères de succès ; la mise en cohérence du template et des skills fait l'objet du lot 16.
- **P2. `verifier.sh` exige un dépôt Git.** `scripts/verifier.sh` refuse de tourner hors d'un dépôt Git, alors que le script ne fait aucune opération Git (intent, « Hors périmètre »). Tranché le 2026-10-20 : le critère « `verifier.sh` passe dans un projet créé » s'entend après la marche à suivre de C20, exécutée par l'humain ; A1 l'inclut.
- **P3. Nom du script, des commandes et du marqueur.** `scripts/ai-factory.sh`, `create`, `update` et `{{nom-projet}}` ne viennent pas de l'intent. Tranché le 2026-10-20 : noms retenus.
- **P4. Retour à une version plus ancienne.** Une mise à jour depuis un clone plus ancien que le SHA du manifeste reviendrait en arrière sans avertissement. Tranché le 2026-10-20 : refus, sauf `--forcer` (C34).
- **P5. Mise à jour interrompue.** Le manifeste n'étant réécrit qu'à la fin (C14), une interruption laisse des fichiers déjà remplacés dont l'empreinte diffère de l'ancien manifeste : à la relance, ils passent pour modifiés localement et produisent des `.nouveau` superflus, sans perte de données. Tranché le 2026-10-20 : risque accepté, pas de journal de reprise.
- **P6. Fichiers `.nouveau` et Git.** Rien n'empêchait de commiter un `<fichier>.nouveau` par erreur. Tranché le 2026-10-20 : `*.nouveau` dans le `.gitignore` livré (C35). Revers : les `.nouveau` n'apparaissent plus dans `git status`, seul le rapport de C30 rappelle la fusion à faire.
- **P7. Livrable « tests » absent de l'intent.** C33 découle de la convention de `CLAUDE.md` (tests d'un livrable dans `<dossier du livrable>/tests/<nom>/`), pas de l'intent. Tranché le 2026-10-20 : la convention suffit, l'intent n'est pas modifié.
- **P8. Aucun skill de standards.** Aucun skill de conventions n'existe dans `.claude/skills/` ; les choix de format (manifeste au format `sha256sum`, codes de retour) ne s'appuient sur aucun standard d'équipe. Tranché le 2026-10-20 : les choix de cette spec font foi pour ce lot ; le skill « Conventions de l'équipe » prévu au lot 5 couvrira ce manque.
- **P9. Contenu des modèles.** Le texte des sections communes des modèles recoupe le lot 10 (README d'ai-factory). Tranché le 2026-10-20 : les modèles sont écrits dans ce lot (C36) ; le lot 10 les reprendra pour rester cohérent.
- **P10. Questions ouvertes de l'intent.** Tranchées le 2026-10-20 : priorité haute retenue sans confirmation du PO ; le lot n'est pas ajouté au tableau des sous-intents de `requirements/open/ia-factory.md`.
- **P11. Bit exécutable modifié localement.** Le manifeste ne garde que le contenu (C13) : un `chmod` local sur un fichier intact est écrasé à la mise à jour suivante (C39). Tranché le 2026-10-20 : risque accepté, le format `sha256sum` du manifeste est conservé.
- **P12. Code exécuté depuis la source.** Avec C38, `update` exécute le script du clone, pas celui du projet. Tranché le 2026-10-20 : même confiance que pour les fichiers copiés depuis ce clone ; c'est ce qui garantit qu'une évolution de la liste blanche ou des règles arrive dès la première mise à jour.

## Hors périmètre

- Opérations Git dans le projet : `git init`, commit initial, création du dépôt distant (intent).
- Équiper un dépôt existant qui n'a pas été créé par le script (intent).
- Fusion automatique d'un `.nouveau` : elle reste humaine.
- Mise à jour depuis le réseau : la source est toujours un clone local.

## Questions ouvertes

Aucune. Les deux questions reprises de l'intent sont tranchées (P10).
