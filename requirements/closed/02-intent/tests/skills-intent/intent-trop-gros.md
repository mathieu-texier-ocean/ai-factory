# Intent : Refonte rapports et export comptable

- **Statut :** draft
- **Validation :** PO, puis blocage automatique par la CI

## Problème

Les rapports de tournée sont lents à générer (plus de 30 s). Par ailleurs, l'export comptable mensuel contient des doublons de factures.

## Pour qui

Exploitants (rapports) et service comptabilité (export).

## Pourquoi

Perte de temps quotidienne et erreurs de facturation.

## Priorité

- **Niveau :** Haute
- **Justification :** Test.
- **Échéance :** aucune

## Résultat attendu

Rapports générés en moins de 5 s et export comptable sans doublon.

## Livrables

| Type | Élément |
|---|---|
| Code | Optimisation de la requête de rapport |
| Code | Dédoublonnage de l'export |
| Doc | Guide utilisateur du nouvel export |

## Critère d'acceptation

- [ ] Un rapport standard se génère en moins de 5 s.
- [ ] L'export d'un mois test ne contient aucun doublon.

## Critère de succès

Baisse des tickets support liés aux rapports et à l'export.

## Contraintes

Aucune donnée client dans les jeux de test.

## Hors périmètre

Refonte de l'interface.

## Questions ouvertes

Aucune.
