# Spec — Jeu de test : huit contrôles de forme au commit

- **Intent :** [intent.md](intent.md)
- **Auteur :** Jeu de test
- **Statut :** validé
- **Validation :** Tech lead

## Périmètre

Huit contrôles de forme indépendants ajoutés à `hooks/pre-commit`. Aucun ne dépend d'un autre ; chacun a son message et ses tests.

## Comportements

### Contrôles

- **C1.** Fichier ajouté de plus de 1 Mo : refusé.
- **C2.** Ligne ajoutée terminée par `\r\n` : refusée.
- **C3.** Tabulation dans une ligne ajoutée d'un `.md` : refusée.
- **C4.** Fichier commençant par un BOM UTF-8 : refusé.
- **C5.** Ligne ajoutée commençant par `<<<<<<<`, `=======` ou `>>>>>>>` : refusée.
- **C6.** Fichier `.sh` ajouté sans bit exécutable : refusé.
- **C7.** Chemin ajouté contenant une espace : refusé.
- **C8.** Ligne ajoutée de plus de 400 caractères : refusée.
- **C9.** Chaque refus nomme le fichier et le contrôle en cause.

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Fichier binaire | Seuls C1, C6 et C7 s'appliquent |

## Contrats

Message : `<fichier> : <contrôle>`, code 1 si au moins un refus.

## Critères d'acceptation

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Défauts refusés | Un fichier par défaut (C1 à C8) | On commite chacun | Commit refusé, message qui nomme le fichier | Automatisé |
| A2 | Fichier sain accepté | Un fichier sans défaut | On le commite | Commit accepté | Automatisé |

## Points d'attention

Aucun.

## Hors périmètre

- Correction automatique des fichiers.

## Questions ouvertes
