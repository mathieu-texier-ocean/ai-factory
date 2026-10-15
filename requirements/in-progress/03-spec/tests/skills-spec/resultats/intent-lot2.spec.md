# Spec : Lot 2 — Étape Intent

<!-- Numéros C, L et A stables : une révision ajoute un nouveau numéro, elle ne renumérote jamais. Le lot 4 (plan) et le lot 7 (recette) s'y réfèrent. -->

- **Intent :** [intent.md](../intent-lot2/intent.md)
- **Auteur :** agent (skill `generation-spec`), depuis l'intent de Khaled KORIFI
- **Statut :** draft
- **Validation :** PO

## Périmètre

La spec couvre l'étape Intent de la chaîne IA Factory : le template `templates/intent.md`, le skill de rédaction d'intent, le hook qui vérifie la présence des sections obligatoires avant commit, et le skill de contrôle de taille qui applique les critères de découpage et propose des sous-intents. Elle couvre aussi la validation de l'intent par le PO, qui reste humaine. Les intents sont versionnés dans Git, sans donnée sensible ni secret dans le contexte de l'agent.

## Comportements

### Template `templates/intent.md`

- **C1.** Le template contient les sections Problème, Pour qui, Pourquoi, Priorité, Résultat attendu, Critère de succès, Contraintes, Hors périmètre et Questions ouvertes (intent, Livrables).
- **C2.** Le template est versionné dans Git, source de vérité des intents (intent, Contraintes).

### Skill de rédaction d'intent

- **C3.** À partir d'un besoin brut, le skill pose les questions correspondant aux informations manquantes pour remplir le template (intent, Livrables).
- **C4.** Le skill remplit le template et produit un `intent.md` dans lequel toutes les sections du template sont présentes (intent, Plan de test n° 1).
- **C5.** Le skill ne valide jamais l'intent qu'il produit : la validation reste celle du PO (intent, Contraintes).
- **C6.** Le skill n'introduit aucune donnée sensible ni aucun secret dans le contexte de l'agent (intent et parent, Contraintes).

### Hook de sections obligatoires

- **C7.** Avant commit, le hook vérifie la présence des sections obligatoires dans un `intent.md` (intent, Livrables).
- **C8.** Si une section obligatoire manque, le commit est bloqué et le message indique la section manquante (intent, Plan de test n° 2).
- **C9.** Si toutes les sections obligatoires sont présentes, le commit est accepté (intent, Plan de test n° 3).
- **C10.** Le hook ne valide pas l'intent : il contrôle la présence des sections, pas le contenu ni le statut de validation (intent, Contraintes : « Aucune brique n'a le droit de valider un intent »).

### Skill de contrôle de taille

- **C11.** Le skill évalue l'intent contre les signaux structurels 1 à 5 de la section « Critères de découpage » de l'intent : plusieurs problèmes, livrable orphelin, critères indépendants, dépendances hétérogènes, validations hétérogènes.
- **C12.** Le skill évalue les signaux de taille 6 à 8 : PR trop longue à relire, plan trop long, plusieurs démos. Ce sont des estimations (intent, « Signaux de taille, à estimer »).
- **C13.** Le signal 7 (plan trop long) se lit dans le `plan.md` produit au lot 4 : au-delà de 5 à 7 étapes ou en présence de branches parallèles, il renvoie l'intent en découpage (intent, Critères de découpage, signal 7).
- **C14.** Dès qu'au moins un signal est relevé, le skill le signale et propose un découpage en sous-intents (intent, Livrables et Critère d'acceptation n° 3).
- **C15.** Chaque sous-intent proposé apporte seul une valeur vérifiable. Un élément qui n'a d'intérêt que combiné à un autre reste avec lui (intent, garde-fou).
- **C16.** Sur un intent cohérent, le skill ne relève aucun signal et ne propose aucun découpage (intent, Plan de test n° 5).
- **C17.** La cible du découpage est un lot = un sous-intent = une PR (intent et parent, Contraintes).

### Validation par le PO

- **C18.** Le PO relit l'intent produit et le valide explicitement. Aucune brique (skill, hook) ne passe un intent à `validé` (intent, Contraintes et Critère d'acceptation n° 4).

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Commit d'un `intent.md` sans la section « Pourquoi » | Commit bloqué, message indiquant la section manquante (C8). |
| L2 | Commit d'un `intent.md` auquel il manque plusieurs sections | Commit bloqué (C8). Le message cite-t-il toutes les sections manquantes ou seulement la première ? Non défini par l'intent, voir Questions ouvertes. |
| L3 | Commit d'un `intent.md` dont une section obligatoire est présente mais vide | Non défini par l'intent : C7 ne parle que de présence. Voir Questions ouvertes. |
| L4 | Commit modifiant un intent existant d'un autre lot, qui n'a pas le format du template | Non défini : dépend de la question ouverte de l'intent sur la migration de l'existant (C7). |
| L5 | Besoin brut qui ne fournit pas une information du template | Le skill pose la question correspondante (C3). Ce qu'il écrit si l'utilisateur ne répond pas n'est pas défini, voir Questions ouvertes. |
| L6 | Demande au skill de rédaction de passer l'intent à `validé` | Le skill ne valide pas, la validation reste au PO (C5, C18). |
| L7 | Intent avec deux problèmes indépendants et un livrable orphelin | Signaux 1 et 2 relevés, découpage proposé (C11, C14). |
| L8 | Intent cohérent (ex. le lot 1) | Aucun signal, aucun découpage proposé (C16). |
| L9 | Élément de l'intent qui n'a d'intérêt que combiné à un autre | Il reste dans le même sous-intent que cet autre élément (C15). |
| L10 | Contrôle de taille d'un intent dont le `plan.md` du lot 4 n'existe pas encore | Le signal 7 ne peut pas être relevé, il arrive après coup (C13). La façon de le rapporter n'est pas définie, voir Questions ouvertes. |
| L11 | `plan.md` du lot 4 à 6 étapes, entre les bornes 5 et 7 | Non défini : l'intent donne une fourchette, pas un seuil (C13). Voir Questions ouvertes. |

## Contrats

- **`templates/intent.md`** : fichier Markdown versionné dans Git, une section par élément listé en C1. Le format exact de repérage d'une section (titre de niveau 2, libellé exact) n'est pas fixé par l'intent.
- **Skill de rédaction** : entrée, un besoin brut en texte libre et les réponses aux questions posées ; sortie, un `intent.md` conforme au template, dans un dossier versionné dans Git. Le statut écrit à la création n'est pas fixé par l'intent, hors interdiction de `validé` (C5).
- **Hook** : déclenché avant commit sur un `intent.md`. Sortie : commit accepté, ou commit bloqué avec un message nommant la ou les sections manquantes. Le type de hook, son installation, la sélection des fichiers contrôlés et le code de retour exact ne sont pas fixés par l'intent.
- **Skill de contrôle de taille** : entrée, un `intent.md` et, s'il existe, le `plan.md` du lot 4 ; sortie, la liste des signaux 1 à 8 évalués, les signaux de taille marqués comme estimations, et une proposition de sous-intents si au moins un signal est relevé. L'intent ne dit pas si la proposition est seulement affichée ou écrite sous forme de fichiers.

## Critères d'acceptation

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Un intent est produit avec le skill | Un besoin brut quelconque | On lance le skill de rédaction avec ce besoin | Les questions manquantes sont posées, un `intent.md` est écrit et contient toutes les sections du template (C1, C3, C4) | Manuel |
| A2 | Un intent est produit avec le skill | Un besoin brut et l'`intent.md` produit en A1 | On lit le statut de l'intent produit | L'intent n'est pas au statut `validé` (C5) | Manuel |
| A3 | Le hook refuse un intent incomplet | Un `intent.md` sans la section « Pourquoi », indexé dans Git | On lance `git commit` | Le commit est bloqué et le message indique la section « Pourquoi » manquante (C7, C8) | Automatisé |
| A4 | Le hook refuse un intent incomplet | Un `intent.md` complet, toutes sections présentes, indexé dans Git | On lance `git commit` | Le commit est accepté (C9) | Automatisé |
| A5 | Le skill de contrôle signale un intent présentant au moins un critère de découpage et propose un découpage | Un intent volontairement trop gros, avec 2 problèmes indépendants et un livrable orphelin | On lance le skill de contrôle de taille sur cet intent | Les signaux 1 et 2 sont relevés avec la phrase concernée, et un découpage en sous-intents est proposé (C11, C14) | Manuel |
| A6 | Le skill de contrôle signale un intent présentant au moins un critère de découpage et propose un découpage | Un intent cohérent (ex. le lot 1) | On lance le skill de contrôle de taille sur cet intent | Aucun signal relevé, aucun découpage proposé (C15, C16) | Manuel |
| A7 | Le PO valide l'intent | L'intent produit en A1 | Le PO le relit | Le PO donne une validation explicite, et c'est lui qui passe l'intent à `validé` (C18) | Humain |

## Points d'attention

- **Aucun skill de standards** dans `.claude/skills/` (seuls `redaction-intent`, `controle-taille-intent` et `generation-spec` sont présents). La sécurité (contrainte « aucune donnée sensible ni secret », C6) et les conventions (format des sections lu par le hook, C7) ne sont couvertes par aucun standard. Décideur attendu : tech lead.
- **Template vs signaux de découpage.** La liste des sections du template dans l'intent (Livrables) ne contient ni « Livrables » ni « Critère d'acceptation », alors que le signal 2 (livrable orphelin) et le signal 5 (validations hétérogènes) s'appuient sur ces informations. L'intent lui-même contient en plus « Livrables », « Critères de découpage », « Critère d'acceptation » et « Plan de test ». Sources : intent, Livrables (template) et Critères de découpage. Décideur attendu : PO.
- **Validation de la spec.** Le skill `generation-spec` reprend la validation de l'intent (`PO`), mais pose que la validation d'une spec est celle du tech lead, PO en copie, comme la ligne du lot 3 dans le parent. Sources : intent (Validation : PO) et parent (Sous-intents, lot 3). Décideur attendu : tech lead et PO.
- **Statut du parent.** L'intent est `validé` alors que le parent `ia-factory.md` est encore `draft`. Sources : intent et parent (en-têtes). Décideur attendu : PO.
- **Critère de succès non testable dans le lot.** La contribution au délai PR → production divisé par deux (≈ 5 jours, référence 10,7 jours) est un indicateur du parent, mesuré hors de ce lot. Aucune ligne `A` ne le couvre.
- **Signaux 6 et 7 imprécis.** « Quelques centaines de lignes » et « 5 à 7 étapes » sont des fourchettes, pas des seuils : le résultat du contrôle de taille sur ces signaux n'est pas reproductible tel quel (L11).
- **Contournement du hook.** L'intent ne dit pas si un commit qui contourne le hook côté poste local est acceptable, ni si un contrôle équivalent doit exister côté dépôt. Décideur attendu : tech lead.

## Hors périmètre

- Génération de la spec (lot 3).
- Plan, découpage en tâches et code (lots 4 et suivants).
- Contrôle du contenu des sections par le hook : il ne vérifie que leur présence.

## Questions ouvertes

- Priorité du lot : niveau, justification et échéance à définir par le PO.
- Les intents des autres lots n'ont pas le format du template : à migrer maintenant, au fil de l'eau, ou règle assouplie pour l'existant ?
- Hook : quelles sections exactes sont obligatoires (les 9 du template, ou un sous-ensemble) et comment une section est-elle reconnue (libellé et niveau de titre) ?
- Hook : une section présente mais vide est-elle acceptée (L3) ?
- Hook : quand plusieurs sections manquent, le message les liste-t-il toutes (L2) ?
- Hook : type de hook, installation, fichiers contrôlés (tout fichier `intent.md` indexé, ou seulement certains dossiers) et code de retour.
- Skill de rédaction : que doit-il écrire quand l'utilisateur ne fournit pas une information demandée (L5), et quel statut écrit-il à la création ?
- Skill de contrôle : la proposition de découpage est-elle seulement affichée, ou écrite sous forme de fichiers de sous-intents ?
- Skill de contrôle : comment rapporter le signal 7 quand le `plan.md` n'existe pas encore (L10) ?
- Skill de contrôle : quels seuils exacts pour les signaux 6 (« quelques centaines de lignes ») et 7 (« 5 à 7 étapes ») (L11) ?
