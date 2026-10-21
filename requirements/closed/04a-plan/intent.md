# Sous-intent — Lot 4a : Étape Plan, production du plan

- **Parent :** [ia-factory.md](../../open/ia-factory.md)
- **Auteur :** Khaled KORIFI · **Statut :** validé
- **Date :** 2026-10-16
- **Validation :** Développeur, tech lead si le changement est à risque
- **Dépend de :** lot 3, lot 4b (intent validé, pour le critère d'acceptation sur son plan)
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
| Skill | Production du plan : séance en plan mode qui lit `spec.md` si elle existe et exige qu'elle soit `validé`, se replie sur `intent.md` validé seulement quand il n'y a pas de spec, et refuse en disant pourquoi sinon (statut lu dans l'arbre de travail) ; lit aussi le code, interroge le développeur (ce que le changement peut casser, étape la plus risquée, options écartées), puis écrit `plan.md` en `draft` et le complète au fil des réponses ; s'il modifie un plan `validé`, il le repasse en `draft` ; avertit, sans bloquer, quand le plan dépasse 5 à 7 étapes ou a des branches parallèles : l'intent est peut-être à découper |

## Critère d'acceptation

- [ ] Le plan du lot 4a, écrit en plan mode sans le skill (qui n'existe pas encore) et conforme à `templates/plan.md`, est commité à côté de son intent et de sa spec.
- [ ] Le skill produit le `plan.md` du lot 4b, conforme à `templates/plan.md` et assez complet pour qu'un développeur qui n'a pas vu la conversation l'implémente.
- [ ] Chaque étape du plan correspond à un commit de la PR du lot.
- [ ] Le plan est validé par le développeur, ou par le tech lead si le changement est à risque.

## Contraintes

- Un lot = un sous-intent = un plan = une PR ; une étape du plan = un commit.
- Le plan est accepté avant tout code.
- Quand l'implémentation s'écarte du plan, `plan.md` est mis à jour dans le même commit ; un plan `validé` modifié repasse en `draft` et doit être revalidé. La conformité est contrôlée en revue (lot 6).
- Le skill lit le statut avec le même motif que le hook du lot 3 : première occurrence de `**Statut :** <valeur>`, seul `validé` exact passe.
- Source de vérité : Git. Aucune donnée sensible ni secret dans le contexte de l'agent.

## Hors périmètre

- Refus par hook d'un plan sans amont validé (lot 4b).
- Génération du code (lot 5).
- Contrôle de conformité du diff au plan (lot 6).
- Refus d'un plan trop long : la taille ne donne qu'un avertissement du skill (reprend le signal 7 retiré par le lot 14).
- Déclenchement automatique du plan à la validation de la spec.

## Questions ouvertes

- Critère qui classe un changement « à risque » et fait passer la validation au tech lead : à trancher par le tech lead.
- Plan mode sur `ai-factory`, qui contient peu de code : le skill s'appuie sur les skills, hooks et tests existants. À confirmer à l'usage.
