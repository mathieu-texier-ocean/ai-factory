# Sous-intent — Lot 0 : Mesure de référence

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** validé
- **Validation :** —
- **Dépend de :** —

## Problème

La référence de 10,7 jours n'est pas mesurée de façon reproductible. Sans mesure fiable au départ, le gain ÷2 ne pourra pas être démontré.

## Pour qui

- **Tech lead** : valide la référence publiée.
- **Lot 8 (Monitoring)** : reprend l'indicateur et sa méthode de calcul.
- **Projet IA Factory** : s'appuie sur la référence pour démontrer le gain ÷2.

## Pourquoi

Sans mesure fiable au départ, le gain ÷2 de l'intent parent (délai PR → production, référence 10,7 jours, cible ≈ 5 jours) ne pourra pas être démontré. Une référence mesurée de façon reproductible rend la comparaison défendable.

## Priorité

- **Niveau :** à définir par le PO
- **Justification :**
- **Échéance :** aucune

## Résultat attendu

- Extraction automatisée des dates de création et de merge des PR du dépôt pilote.
- Indicateur intent → mise en production, défini et calculable.
- Une valeur de référence documentée (source, période, périmètre).

## Critère de succès

- Les deux critères d'acceptation ci-dessous sont atteints.
- La référence documentée permet de comparer le délai PR → production du pilote à la cible de l'intent parent (≈ 5 jours, référence 10,7 jours).

## Livrables

- Script d'extraction versionné dans `ai-factory`.
- `docs/mesure-reference.md` : définitions, période, résultat.

## Critère d'acceptation

- [ ] Le script relancé deux fois sur la même période donne la même valeur.
- [ ] La référence est publiée et validée par le tech lead.

## Contraintes

- Démarrage sur un seul dépôt pilote.
- Source de vérité : Git (test sans Jira).
- Le script d'extraction est versionné dans `ai-factory` et reproductible : deux exécutions sur la même période donnent la même valeur.
- Aucune donnée sensible ni secret dans le contexte de l'agent.

## Hors périmètre

- Tableau de bord continu (lot 8).

## Questions ouvertes

- Priorité du lot : niveau, justification et échéance à définir par le PO.
- Validateur du lot : l'en-tête indique « — » alors que le critère d'acceptation prévoit la validation de la référence par le tech lead. À confirmer.
- Dépôt pilote : à nommer (il détermine le périmètre de l'extraction).
