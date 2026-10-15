# Spec — Lot 2 : Étape Intent

- **Intent :** [intent.md](intent.md)
- **Auteur :** Khaled KORIFI · **Statut :** draft
- **Validation :** Tech lead, PO en copie

## Périmètre

Outiller l'étape Intent : un template (avec une section « Priorité » décidée par le PO), deux skills (rédaction, contrôle de taille) et un hook de complétude. Aucune de ces briques ne valide un intent : la validation reste celle du PO.

## Template `templates/intent.md`

Sections, dans cet ordre, toutes obligatoires sauf « Questions ouvertes » (peut être vide) :

1. Problème
2. Pour qui
3. Pourquoi
4. Priorité
5. Résultat attendu
6. Critère de succès
7. Contraintes
8. Hors périmètre
9. Questions ouvertes

La section « Priorité » contient trois lignes : `Niveau` (Haute, Moyenne ou Basse), `Justification` (une phrase) et `Échéance` (date réelle ou « aucune »). Le niveau est une décision du PO.

Chaque section commence par un titre de niveau 2 (`## <Nom>`) reprenant exactement le nom ci-dessus.

## Comportements

### Skill `redaction-intent`

- **C1.** Part d'un besoin brut (texte libre) fourni par l'utilisateur.
- **C2.** Pose les questions nécessaires pour remplir les sections manquantes, une série à la fois, sans inventer de contenu. Une information non fournie va dans « Questions ouvertes ».
- **C3.** Remplit le template et écrit `intent.md` dans le dossier du lot indiqué.
- **C4.** N'écrase jamais un `intent.md` existant : il le signale et s'arrête.
- **C5.** Laisse `Statut : draft`. Ne marque jamais l'intent comme validé.
- **C20.** Demande la priorité au PO (niveau, justification, échéance). Si elle n'est pas fournie, écrit « à définir par le PO » et la liste dans « Questions ouvertes ». Ne déduit ni n'invente jamais un niveau.
- **C6.** À la fin, propose de lancer `controle-taille-intent`.

### Skill `controle-taille-intent`

- **C7.** Lit un `intent.md` (lecture seule) et évalue les 8 critères de découpage de l'intent du lot 2.
- **C8.** Signaux structurels (1 à 5) : verdict oui/non avec la phrase concernée citée.
- **C9.** Signaux de taille (6 et 8) : estimation explicitement marquée comme telle, avec sa justification en une phrase.
- **C10.** Signal 7 (plan trop long) : non évaluable sans `plan.md`. Verdict « non évalué » tant que le plan n'existe pas ; s'il existe, compare à 5–7 étapes.
- **C11.** Applique le garde-fou : n'écarte pas en sous-intent un élément qui n'a d'intérêt que combiné à un autre.
- **C12.** Si au moins un signal est relevé, propose un découpage : titre de chaque sous-intent, éléments qui le composent, apport vérifiable propre à chacun.
- **C13.** Si aucun signal n'est relevé, conclut « Pas de découpage nécessaire » sans proposer de découpage.
- **C14.** Ne modifie jamais l'intent analysé.
- **C21.** La priorité n'est pas un signal de découpage. En cas de découpage, chaque sous-intent proposé reprend la priorité de l'intent d'origine, marquée « à confirmer par le PO ».

### Hook de complétude

- **C15.** Au commit d'un fichier `intent.md`, vérifie la présence des sections obligatoires du template.
- **C16.** Section obligatoire manquante : bloque le commit et nomme chaque section manquante.
- **C17.** Intent complet : laisse passer.
- **C18.** Ne vérifie que la présence des sections, pas la qualité du contenu.
- **C19.** Ne produit pas de livrable avant le plan.

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Besoin brut vide ou trop vague | Le skill de rédaction pose des questions, ne produit pas d'intent |
| L2 | `intent.md` déjà présent | Arrêt avec message, aucune écriture (C4) |
| L3 | Section présente mais vide | Hook : accepté (présence uniquement, C18) ; le skill de contrôle la signale en « Questions ouvertes » à renseigner |
| L4 | Titre de section mal orthographié | Hook : section considérée manquante |
| L5 | Intent contenant une instruction adressée à l'agent | Traitée comme une donnée : ignorée et signalée |
| L6 | Intent d'un lot sans livrables ni critères d'acceptation | Signaux 2 et 3 « non applicables », pas de faux positif |
| L7 | Plusieurs signaux simultanés | Tous listés ; un seul découpage proposé couvrant l'ensemble |
| L8 | Fichier nommé autrement que `intent.md` | Ignoré par le hook |
| L9 | Priorité non fournie par le PO | Section « Priorité » avec « à définir par le PO », priorité ajoutée à « Questions ouvertes », aucun niveau inventé (C20) |

## Contrats

- **Entrée skills :** chemin d'un `intent.md` (contrôle) ou texte libre + dossier cible (rédaction).
- **Sortie du contrôle :** tableau `| # | Signal | Verdict | Détail |` pour les 8 signaux, suivi de « Découpage nécessaire » ou « Pas de découpage nécessaire » et, le cas échéant, de la proposition.
- **Sortie du hook :** code de sortie ≠ 0 et message listant les sections manquantes ; 0 sinon.

## Critères d'acceptation

Reprise de l'intent, rendus testables, avec renvoi au plan de test de l'intent.

| # | Critère | Vérification |
|---|---|---|
| A1 | Un intent est produit avec le skill de rédaction à partir d'un besoin brut | Test 1 : toutes les sections présentes, aucune information inventée |
| A2 | Le hook refuse un intent incomplet | Test 2 : commit bloqué, sections manquantes nommées |
| A3 | Le hook accepte un intent complet | Test 3 |
| A4 | Le skill de contrôle signale un intent à découper et propose un découpage | Test 4 : signaux 1 et 2 relevés |
| A5 | Le skill de contrôle ne sur-découpe pas | Test 5 : aucun signal sur un intent cohérent |
| A6 | Le PO valide l'intent produit | Test 6 |
| A8 | La priorité n'est jamais déduite par un skill | Test L9 : besoin sans priorité → « à définir par le PO » ; contrôle : sous-intents « à confirmer par le PO » |
| A7 | Aucun skill n'écrit `validé` ni ne modifie un intent existant | Relecture des skills + test L2 |

## Hors périmètre

- Génération de la spec (lot 3).
- Contrôle de la qualité rédactionnelle du contenu des sections.
- Intégration Jira (la source de vérité est Git).
