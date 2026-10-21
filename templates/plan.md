# Plan : <titre>

<!-- Un lot = un plan = une PR ; une étape = un commit. Le plan est accepté avant tout code. S'il est modifié une fois validé, il repasse en draft. -->

- **Spec :** [spec.md](spec.md) · **Intent :** [intent.md](intent.md)
- **Auteur :** <nom> · **Statut :** draft
- **À risque :** <oui | non>
- **Validation :** <développeur, ou tech lead si à risque>
- **Base :** <branche et commit de départ>

<!-- Sans spec, retirer le lien Spec. « À risque » est renseigné par le développeur d'après ce que le changement peut casser : oui → validation par le tech lead, non → par le développeur. -->

## Prérequis

<!-- Amont validé et commité (spec, sinon intent), une seule PR pour le lot, base de départ, lots dont celui-ci dépend. -->

## Fichiers touchés

<!-- Nature : nouveau | modifié | supprimé. Étape : numéro de l'étape qui touche le fichier. -->

| Fichier | Nature | Étape |
|---|---|---|
| <chemin> | <nouveau \| modifié \| supprimé> | <n> |

## Étapes

<!-- Numérotées dans l'ordre d'exécution. Une étape = un commit. Chaque étape cite les numéros C, L et A de la spec qu'elle couvre. Au-delà de 7 étapes, ou avec des étapes indépendantes, l'intent est peut-être à découper. -->

### 1. <titre>

Couvre : <C, L, A>.

## Tests à écrire

<!-- Tests qui prouvent le changement (automatisés et manuels), avec la commande qui les lance. -->

## Couverture de la spec

<!-- Chaque numéro C, L et A de la spec rattaché à au moins une étape. « Sans objet » s'il n'y a pas de spec. -->

| Réf. | Étape |
|---|---|
| <C1–Cn> | <n> |

## Risques

<!-- Ce que le changement peut casser, l'étape la plus risquée, et la parade prévue. Une question restée sans réponse reste visible ici. Puis les options écartées. -->

## Hors périmètre

<!-- Ce que le plan ne fait volontairement pas. -->
