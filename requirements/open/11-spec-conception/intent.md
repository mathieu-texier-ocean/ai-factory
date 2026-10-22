# Intent : Production automatique de la spec depuis un intent validé

- **Auteur :** PHAN Van Khai
- **Statut :** validé
- **Date :** 2026-10-15
- **Validation :** PO
- **Dépend de :** lot 3 (génération de spec), lot 2 (statut `validé` de l'intent)

## Problème

Une fois un intent validé par le PO, rien ne déclenche la production de la spécification :

- la spec attend qu'un humain la demande, ce qui crée un temps mort entre deux étapes ;
- l'étape Spec peut être sautée : un intent validé passe alors au plan ou au code sans spec.

## Pour qui

- **Exprimé par :** PHAN Van Khai.
- **Validé par :** le PO.
- **Consommé par :** le tech lead, qui relit la spec, et les développeurs, qui implémentent à partir d'elle.

## Pourquoi

Le temps mort s'ajoute au délai PR → production, que l'IA Factory vise à diviser par deux (référence 10,7 jours, cible ≈ 5 jours, voir [ia-factory.md](../../../documents/ia-factory.md)). Une spec sautée génère des reprises en revue.

## Priorité

- **Niveau :** à définir par le PO
- **Justification :**
- **Échéance :** aucune

## Résultat attendu

Quand un `intent.md` passe à `Statut : validé`, Claude reprend automatiquement le fichier accepté et produit la spécification regroupant les exigences de conception, sans demande manuelle. La spec est proposée dans une PR, écrite à côté de l'intent (`<dossier du lot>/spec.md`), et relue par le tech lead selon la règle du lot 3. Si une spec existe déjà, Claude propose une mise à jour au lieu de l'écraser. Le contenu et la structure de la spec relèvent du lot 3.

## Critère de succès

- Un intent passé à `validé` produit son `spec.md` sans action manuelle.
- Un intent qui n'est pas `validé` (par exemple `draft`) ne déclenche rien.

## Critère d'acceptation

- [ ] Un intent passé à `validé` produit son `spec.md`, proposé dans une PR, sans action manuelle.
- [ ] Un intent qui n'est pas `validé` (par exemple `draft`) ne déclenche aucune production.
- [ ] Une spec existante n'est pas écrasée : une mise à jour est proposée pour relecture.
- [ ] La spec produite est au statut `draft`.

## Contraintes

- Seul le PO passe un intent à `validé` : l'automatisme réagit à ce statut, il ne le pose jamais.
- Une spec existante n'est jamais écrasée : la mise à jour est proposée pour relecture.
- S'appuie sur le template et le skill de génération de spec du lot 3.
- La spec produite automatiquement n'arrive jamais directement sur `main` : elle est proposée dans une PR, relue et validée par le tech lead (règle du lot 3), et reste en `draft` jusqu'à cette validation.
- Aucune donnée sensible ni secret dans le contexte de l'agent, y compris dans la configuration du déclencheur.
- Git reste la source de vérité des artefacts (voir [ia-factory.md](../../../documents/ia-factory.md)).

## Hors périmètre

- Contenu et structure de la spec (lot 3).
- Découpage en tâches (lot 4a).

## Questions ouvertes

- **Priorité :** niveau, justification et échéance éventuelle, à fixer par le PO.
- **Déclenchement :** par quel mécanisme (job CI après merge, hook git, commande) le passage à `validé` déclenche-t-il la production ?
- **Livrables :** à lister une fois le mécanisme de déclenchement choisi.
