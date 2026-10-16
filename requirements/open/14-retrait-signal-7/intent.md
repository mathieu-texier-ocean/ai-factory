# Sous-intent — Lot 14 : Retrait du signal 7 du contrôle de taille

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **Date :** 2026-10-16
- **Validation :** PO
- **Dépend de :** —

## Problème

Le skill `controle-taille-intent` évalue un signal 7, « plan trop long », qui lit le `plan.md` du dossier de l'intent. Or le plan est produit après la spec, donc après la validation de l'intent et le contrôle de sa taille. Le signal est presque toujours « non évalué », et il mêle la taille de l'intent à celle du plan.

## Pour qui

- **PO** : lance le contrôle de taille avant de valider un intent.
- **Auteur d'un intent** : lit le verdict du contrôle et découpe si besoin.
- **Lot 4a (plan)** : ne porte plus de contrainte de taille liée au découpage de l'intent.

## Pourquoi

Un signal qui ne peut pas être évalué au moment du contrôle brouille le verdict, et il fait remonter dans l'étape Intent une information qui n'existe qu'à l'étape Plan.

## Priorité

- **Niveau :** à définir par le PO
- **Justification :**
- **Échéance :** aucune

## Résultat attendu

`controle-taille-intent` évalue les signaux 1 à 6 et 8, sans lire de `plan.md`. Le README annonce 7 signaux.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.

## Livrables

| Type | Élément |
|---|---|
| Skill | `.claude/skills/controle-taille-intent/SKILL.md` : retrait du signal 7 et de la lecture de `plan.md` |
| Doc | `README.md` : nombre de signaux évalués par le contrôle de taille |

## Critère d'acceptation

- [ ] Sur un intent dont le dossier contient un `plan.md`, le contrôle de taille ne lit pas le plan et n'affiche pas de ligne pour le signal 7.
- [ ] Le README et le skill annoncent le même nombre de signaux.

## Contraintes

- Les numéros des signaux restent stables : 1 à 6 puis 8, avec un trou au 7, comme les numéros C, L et A des specs.
- Les artefacts des lots fermés (`requirements/closed/`) ne sont pas modifiés : ils restent l'historique.

## Hors périmètre

- Tout contrôle de la taille d'un `plan.md` (lot 4 et suivants).
- Les autres signaux du contrôle de taille.

## Questions ouvertes

- Priorité du lot : niveau, justification et échéance à définir par le PO.
