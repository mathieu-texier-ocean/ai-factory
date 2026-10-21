# Sous-intent — Jeu de test : huit contrôles de forme au commit

- **Parent :** —
- **Auteur :** Jeu de test · **Statut :** validé
- **Date :** 2026-10-21
- **Validation :** Tech lead
- **Dépend de :** —

## Problème

Des fichiers mal formés arrivent dans le dépôt : fichiers trop gros, fins de ligne Windows, tabulations dans le Markdown, BOM UTF-8, marqueurs de conflit non résolus, scripts sans bit exécutable, noms de fichiers avec espace, lignes de plus de 400 caractères.

## Pour qui

- **Développeur** : voit le refus et sa raison au commit.

## Pourquoi

Chaque défaut est découvert en revue, ou après le merge.

## Priorité

- **Niveau :** Basse (jeu de test)
- **Justification :** jeu de données du skill generation-plan.
- **Échéance :** aucune

## Résultat attendu

Huit contrôles indépendants dans `hooks/pre-commit`, un par défaut, chacun avec son message.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.

## Livrables

| Type | Élément |
|---|---|
| Hook | Contrôle de taille de fichier |
| Hook | Contrôle des fins de ligne |
| Hook | Contrôle des tabulations dans le Markdown |
| Hook | Contrôle du BOM UTF-8 |
| Hook | Contrôle des marqueurs de conflit |
| Hook | Contrôle du bit exécutable des scripts |
| Hook | Contrôle des espaces dans les noms de fichiers |
| Hook | Contrôle de la longueur des lignes |

## Critère d'acceptation

- [ ] Chacun des huit défauts est refusé au commit, avec un message qui nomme le fichier.
- [ ] Un fichier sans défaut est accepté.

## Contraintes

- Bash et git uniquement.

## Hors périmètre

- Correction automatique des fichiers.

## Questions ouvertes
