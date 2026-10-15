# Sous-intent — Lot 3 : Étape Spec

- **Parent :** [ia-factory.md](../../open/ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** validé
- **Validation :** Tech lead, PO en copie
- **Dépend de :** lot 2

## Problème

Le passage du besoin au technique se fait oralement ou partiellement, ce qui génère des reprises en revue.

## Résultat attendu

Un `spec.md` généré à partir d'un intent validé, décrivant comportements, cas limites et critères d'acceptation testables.

## Livrables

| Type     | Élément                                                                                  |
| -------- | ---------------------------------------------------------------------------------------- |
| Template | `templates/spec.md` (comportements, cas limites, contrats d'API, critères d'acceptation) |
| Skill    | Génération de spec : lit `intent.md`, produit `spec.md`                                  |
| Hook     | Refus de créer une spec si l'intent n'est pas validé                                     |

## Critère d'acceptation

- [ ] Une spec est générée depuis l'intent du lot 2.
- [ ] Les critères d'acceptation sont exploitables par le lot 7 (recette).
- [ ] Validée par le tech lead, PO en copie.

## Hors périmètre

- Découpage en tâches (lot 4).
