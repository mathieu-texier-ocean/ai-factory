# Sous-intent — Lot 4a : Étape Plan, production du plan

- **Parent :** [ia-factory.md](../ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Date :** 2026-10-16
- **Validation :** Développeur, tech lead si le changement est à risque
- **Dépend de :** lot 3
- **Origine :** découpage du lot 4 (Étape Plan)

## Problème

Sans plan écrit, la façon de réaliser un changement (fichiers touchés, ordre du travail, tests, risques) reste dans la tête de celui qui code. Le relecteur ne la découvre que dans le diff fini, quand corriger le tir coûte une reprise de la PR.

## Pour qui

- **Développeur** : conduit la séance de plan avec l'agent et valide le plan des changements courants.
- **Tech lead** : valide le plan des changements à risque.
- **Agent** : lit l'intent, la spec si elle existe et le code, interroge le développeur, puis écrit le plan.
- **Lot 5 (code + tests)** : implémente le plan, une étape après l'autre.
- **Lot 6 (revue PR)** : compare le diff au plan.

## Pourquoi

La revue de code est l'un des deux goulots du délai PR → production (≈ 10,7 jours). Relire la conception avant le code ramène une correction au coût d'un document modifié, au lieu d'un cycle de reprise sur la PR.

## Priorité

- **Niveau :** Haute (proposé par l'auteur, à confirmer par le PO)
- **Justification :** les lots 5 et 6 consomment le plan.
- **Échéance :** aucune

## Résultat attendu

Un `plan.md` accepté avant tout code et versionné dans le dossier du lot, à côté de `intent.md` et de `spec.md` quand elle existe. Il donne les fichiers touchés, les étapes ordonnées (une étape = un commit), les tests qui prouvent le changement, les risques et, quand une spec existe, la couverture de ses numéros C, L et A.

Il est assez complet pour qu'un développeur qui n'a pas vu la conversation puisse implémenter le changement à partir du plan seul.

## Critère de succès

- Les critères d'acceptation ci-dessous sont atteints.
- Le lot contribue aux indicateurs de l'intent parent : nombre de cycles de reprise par PR et temps jusqu'à la première revue.

## Livrables

| Type | Élément |
|---|---|
| Template | `templates/plan.md` (en-tête, fichiers touchés, étapes, tests, risques, couverture de la spec) |
| Skill | Production du plan : séance en plan mode qui lit `spec.md` validée, ou à défaut `intent.md` validé, et le code, interroge le développeur (ce que le changement peut casser, étape la plus risquée, options écartées), puis écrit `plan.md` en `draft` sans écraser un plan existant |

## Critère d'acceptation

- [ ] Le plan du lot 4a, écrit à la main en plan mode et conforme à `templates/plan.md`, est commité à côté de son intent et de sa spec.
- [ ] Le skill, relancé sur la spec du lot 4a, produit un plan comparable au plan manuel ; les écarts sont consignés dans la PR.
- [ ] Chaque étape du plan correspond à un commit de la PR du lot.
- [ ] Le plan est validé par le développeur, ou par le tech lead si le changement est à risque.

## Contraintes

- Un lot = un sous-intent = un plan = une PR ; une étape du plan = un commit.
- Le plan est accepté avant tout code.
- Quand l'implémentation s'écarte du plan, `plan.md` est mis à jour dans le même commit. La conformité est contrôlée en revue (lot 6).
- Le skill lit le statut avec le même motif que le hook du lot 3 : première occurrence de `**Statut :** <valeur>`, seul `validé` exact passe.
- Source de vérité : Git. Aucune donnée sensible ni secret dans le contexte de l'agent.

## Hors périmètre

- Refus par hook d'un plan sans amont validé (lot 4b).
- Génération du code (lot 5).
- Contrôle de conformité du diff au plan (lot 6).
- Taille du plan comme signal de découpage de l'intent (retiré par le lot 14).
- Déclenchement automatique du plan à la validation de la spec.

## Questions ouvertes

- Critère qui classe un changement « à risque » et fait passer la validation au tech lead : à trancher par le tech lead.
- Plan mode sur `ai-factory`, qui contient peu de code : le skill s'appuie sur les skills, hooks et tests existants. À confirmer à l'usage.
