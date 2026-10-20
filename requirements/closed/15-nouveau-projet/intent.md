# Intent : Déployer ai-factory dans un nouveau projet

- **Auteur :** Mathieu Texier
- **Statut :** validé
- **Date :** 2026-10-20
- **Validation :** Tech lead
- **Dépend de :** —

## Problème

Le projet « activation en masse » doit démarrer avec l'outillage ai-factory, mais aucun moyen outillé ne permet de peupler un nouveau dépôt à partir d'ai-factory. `CLAUDE.md` et `README.md` décrivent ai-factory lui-même, et `requirements/` ne doit pas être copié.

## Pour qui

- Développeur qui démarre un nouveau projet : il lance le script.
- Tech lead : il valide le lot.

## Pourquoi

Sans ce lot, le projet « activation en masse » ne peut pas démarrer sur la chaîne ai-factory, et les évolutions ultérieures d'ai-factory (hooks, skills) ne lui parviendraient pas.

## Priorité

- **Niveau :** Haute (proposé par l'auteur, retenu sans confirmation du PO le 2026-10-20)
- **Justification :** Un projet concret, « activation en masse », attend l'outillage.
- **Échéance :** aucune

## Résultat attendu

- Un script shell, rangé dans `scripts/`, qui copie l'outillage ai-factory dans un dossier cible pour créer un nouveau projet. À la création, il refuse un dossier cible existant et non vide, sans rien copier.
- La copie suit une liste blanche explicite : `.claude/`, `hooks/`, `scripts/` (script compris), `templates/` sauf `templates/projet/`, `.gitignore`. Tout le reste est exclu tant qu'on ne l'ajoute pas à la liste, notamment `requirements/`, `documents/` et `.obsidian/`.
- `CLAUDE.md` et `README.md` sont produits depuis des modèles rangés dans `templates/projet/`, exclus de la copie. Les sections communes (commandes, vérification, conventions, cycle des lots) arrivent remplies, le script y injecte le nom du projet, et les sections propres au projet (architecture, erreurs fréquentes) arrivent vides avec un commentaire guide.
- Le script ne fait aucune opération Git. En fin de copie, il affiche la marche à suivre : `git init`, puis `git config core.hooksPath hooks`.
- Le même script répercute dans un projet déjà créé les évolutions ultérieures d'ai-factory. Il est lancé depuis le projet, avec le chemin d'un clone d'ai-factory.
- À chaque copie, le script écrit dans le projet un manifeste, `.ai-factory/manifeste` : le SHA d'ai-factory utilisé, puis l'empreinte sha256 de chaque fichier copié.
- À la mise à jour, une empreinte différente de celle du manifeste signale un fichier modifié localement. Un fichier intact est remplacé. Un fichier modifié localement et changé dans ai-factory est conservé, la nouvelle version est déposée à côté (`<fichier>.nouveau`) et le script liste ces fichiers en fin d'exécution pour fusion humaine.
- Cas limites de la mise à jour, tous listés en fin d'exécution :
  - fichier du manifeste supprimé dans le projet : il n'est pas recréé. Si ai-factory l'a modifié depuis, sa nouvelle version est déposée en `<fichier>.nouveau` pour décision humaine ;
  - fichier supprimé dans ai-factory : supprimé du projet s'il est intact, conservé s'il a été modifié localement. Un renommage est traité comme une suppression suivie d'un ajout ;
  - nouveau fichier d'ai-factory déjà présent dans le projet hors manifeste : le fichier du projet est conservé, la version d'ai-factory est déposée en `<fichier>.nouveau`.

## Critère de succès

- Dans un projet créé par le script, `bash scripts/verifier.sh` passe, sans `requirements/` présent.
- Une évolution d'ai-factory est répercutée dans un projet existant sans écraser ses modifications locales (`CLAUDE.md` complété, lots en cours).

## Contraintes

- Bash et outils standards uniquement : aucune dépendance à installer (pas de Python, cookiecutter, copier…).
- Aucune donnée sensible ni secret dans les fichiers copiés.

## Hors périmètre

- Opérations Git : `git init`, commit initial, création du dépôt distant.
- Équiper un dépôt existant qui n'a pas été créé par le script (ex. oceanv3).

## Questions ouvertes

Aucune. Tranchées le 2026-10-20 :

- Priorité : pas de confirmation du PO, le niveau haute est retenu.
- Le lot n'est pas ajouté au tableau des sous-intents de `requirements/open/ia-factory.md`.
