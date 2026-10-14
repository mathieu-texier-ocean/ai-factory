# Sous-intent — Lot 0 : Mesure de référence

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** —
- **Dépend de :** —

## Problème

La référence de 10,7 jours n'est pas mesurée de façon reproductible. Sans mesure fiable au départ, le gain ÷2 ne pourra pas être démontré.

## Résultat attendu

- Extraction automatisée des dates de création et de merge des PR du dépôt pilote.
- Indicateur intent → mise en production, défini et calculable.
- Une valeur de référence documentée (source, période, périmètre).

## Livrables

- Script d'extraction versionné dans `ai-factory`.
- `docs/mesure-reference.md` : définitions, période, résultat.

## Critère d'acceptation

- [ ] Le script relancé deux fois sur la même période donne la même valeur.
- [ ] La référence est publiée et validée par le tech lead.

## Hors périmètre

- Tableau de bord continu (lot 8).
