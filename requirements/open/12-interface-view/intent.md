# Intent : Interface web de conversation avec Claude

- **Auteur :** Nicola Ruivo
- **Statut :** draft
- **Date :** 2026-10-15
- **Validation :** PO
- **Dépend de :** —

## Problème

Interagir avec Claude sur le projet demande aujourd'hui d'utiliser Claude Code en ligne de commande. Les PO et autres profils non développeurs ne peuvent pas s'en servir sans connaissance en développement.

## Pour qui

Les PO et les autres profils non développeurs (recette, métier).

## Pourquoi

Sans interface, les PO ne rédigent pas eux-mêmes les artefacts de la chaîne (intent, spec) : ils dépendent d'un développeur.

## Priorité

- **Niveau :** Moyenne
- **Justification :** aucune
- **Échéance :** aucune

## Résultat attendu

Une interface web, simple d'utilisation, qui charge le dépôt `ai-factory` et ses skills, et permet de dialoguer avec Claude de façon conviviale.

## Critère de succès

Un PO sans connaissance en développement rédige un `intent.md` avec le skill `redaction-intent` depuis son navigateur, sans aide, et le fichier est écrit dans le dépôt.

## Contraintes

- Accessible sans connaissance en développement : pas de ligne de commande.

## Hors périmètre

- Commit depuis l'interface et application du hook `pre-commit` : lot 13.
- Création ou modification de skills et de hooks : l'interface utilise ceux qui existent.
- Ouverture à d'autres dépôts que `ai-factory`.
- Validation d'un intent : le passage en « validé » reste un geste manuel du PO, hors interface.

## Questions ouvertes

- Hébergement : sur le poste de chaque utilisateur ou sur un serveur interne partagé ?
