# Spec — Lot 4b : Étape Plan, refus d'un plan sans amont validé

<!-- Numéros C, L et A stables : une révision ajoute un nouveau numéro, elle ne renumérote jamais. Le lot 4 (plan) et le lot 7 (recette) s'y réfèrent. -->

- **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER
- **Statut :** draft
- **Validation :** Tech lead

## Périmètre

Ajouter à `hooks/pre-commit` un contrôle bloquant sur l'arrivée d'un `plan.md` dans un dossier, par création ou par renommage : le plan doit être à côté d'un `intent.md`, et son amont doit être validé, la `spec.md` du dossier quand elle existe, sinon l'`intent.md`. L'intent et la spec sont lus dans le commit en cours quand ils en font partie, sinon dans `HEAD`. Le lot livre aussi les tests automatisés du contrôle dans `hooks/tests/hook-plan/`. Il ne touche ni au contenu du plan, ni aux plans déjà commités, ni aux contrôles existants.

## Comportements

### Hook `hooks/pre-commit` : plan à côté de son intent, spec validée, sinon intent validé

Ajouté à `hooks/pre-commit`, à la suite du contrôle « intent validé » du lot 3.

- **C1.** Contrôle chaque `plan.md` (nom de fichier exact) qui arrive dans le commit : ajouté (`A`) ou destination d'un renommage (`R`, par `git mv` ou détecté par git). Les chemins sont lus bruts (`-z`), sans les guillemets de `core.quotePath`, comme le contrôle credential.
- **C2.** Le dossier du plan est `<dossier>` (la racine du dépôt si le plan y est). L'intent attendu est `<dossier>/intent.md`, la spec `<dossier>/spec.md`.
- **C3.** L'intent et la spec sont lus dans l'index, c'est-à-dire l'état du dossier après le commit en cours : la version du commit en cours quand le fichier en fait partie, celle de `HEAD` sinon. Un fichier présent dans `HEAD` et supprimé dans le commit en cours est absent (tranché le 2026-10-21, voir C17).
- **C4.** Si `<dossier>/intent.md` n'est ni dans `HEAD` ni dans le commit en cours : bloque le commit et nomme l'intent attendu. Ce contrôle passe avant celui des statuts : une spec validée dans le dossier ne suffit pas (intent, Résultat attendu, 1er point).
- **C5.** Si `<dossier>/spec.md` est dans `HEAD` ou dans le commit en cours, seul son statut décide : `validé` laisse passer, toute autre valeur bloque le commit et affiche le statut trouvé. Le statut de l'intent n'est alors pas lu (intent, Résultat attendu, 2e point).
- **C6.** Sans spec, ni dans `HEAD` ni dans le commit en cours, le statut de `<dossier>/intent.md` décide : `validé` laisse passer, toute autre valeur bloque le commit et affiche le statut trouvé (intent, Résultat attendu, 3e point).
- **C7.** Le statut est lu avec le même motif que le contrôle du lot 3 : première occurrence de `**Statut :** <valeur>`, que le champ soit sur sa propre ligne ou sur celle de l'auteur. Seul `validé` exact passe.
- **C8.** Sont exclus du contrôle, d'après le chemin de destination : `templates/` à la racine (comme pour la spec) et les fixtures de tests `tests/<nom>/fixtures/` à toute profondeur, y compris `tests/` à la racine (comme pour le credential).
- **C9.** Ne contrôle ni le contenu ni la taille du plan, ni la modification d'un `plan.md` déjà commité (`M`), ni sa suppression, ni son renommage vers un autre nom que `plan.md`.
- **C10.** Chaque plan refusé donne une ligne sur la sortie d'erreur au format de [Contrats](#contrats). Le hook continue ses autres contrôles et sort en code 1 si au moins un contrôle a échoué ; les refus de plusieurs plans d'un même commit sont tous affichés.
- **C11.** Les contrôles existants (complétude de l'intent, intent validé avant la spec, credential) ne changent pas de comportement.
- **C12.** Bash et git uniquement, comme les contrôles existants.
- **C16.** Champ `**Statut :**` absent de la spec ou de l'intent qui décide : refus avec la valeur `absent` à la place du statut, par exemple `<plan> : spec non validée (statut : absent)` (question ouverte 1 de l'intent, tranchée le 2026-10-21).
- **C17.** Suppression dans le commit du plan : un `intent.md` supprimé donne le refus « intent absent » (C4) ; une `spec.md` supprimée laisse l'intent décider (C6), comme s'il n'y avait pas de spec (question ajoutée par la spec, tranchée le 2026-10-21).
- **C18.** Le contrôle de la spec du lot 3 n'est pas aligné sur la règle de ce lot : il garde la lecture de l'intent dans `HEAD` seulement. L'écart (P1) et les failles du lot 3 (P3) sont traités dans un lot dédié (question ouverte 2 de l'intent, tranchée le 2026-10-21).

### Tests `hooks/tests/hook-plan/`

- **C13.** `hooks/tests/hook-plan/run.sh`, sur le modèle de `hooks/tests/hook-spec/run.sh` : dépôt git temporaire, copie de `hooks/pre-commit` et de `templates/intent.md`, un scénario par ligne `PASS`/`FAIL` citant les numéros `A` et `L` couverts, code de sortie non nul si un scénario échoue.
- **C14.** Les fixtures (intents `draft` et `validé`, statut sur sa propre ligne et sur celle de l'auteur, specs `draft` et `validé`, plan modèle) sont dans `hooks/tests/hook-plan/fixtures/`. Les intents de fixture contiennent toutes les sections obligatoires, pour que le contrôle de complétude ne masque pas le résultat quand un intent est commité avec le plan.
- **C15.** `run.sh` est découvert et lancé par `bash scripts/verifier.sh`, sans modification du script.

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Dossier sans `intent.md`, avec une `spec.md` validée | Refusé, intent attendu nommé (C4) |
| L2 | `plan.md` à la racine du dépôt, sans `intent.md` à la racine | Refusé, intent attendu `intent.md` (C2, C4) |
| L3 | Intent `draft` dans `HEAD`, spec `validé` dans le dossier | Accepté : la spec décide seule (C5) |
| L4 | Spec `validé` dans `HEAD`, repassée en `draft` dans le même commit que le plan | Refusé, statut `draft` : la version du commit en cours prime (C3, C5) |
| L5 | Intent `draft` dans `HEAD`, passé à `validé` dans le même commit que le plan, sans spec | Accepté (C3, C6). Diffère du contrôle de la spec du lot 3 (voir P1) |
| L6 | Spec créée en `validé` dans le même commit que le plan, intent `draft` dans `HEAD` | Le contrôle du plan passe (C5), mais le commit est refusé par le contrôle de la spec du lot 3 (voir P2) |
| L7 | Statut écrit `Validé`, `valide` ou `validée` | Refusé, statut trouvé affiché tel quel (C7) |
| L8 | Champ `**Statut :**` absent de la spec ou de l'intent | Refusé, statut affiché `absent` (C16) |
| L9 | `git mv` d'un `plan.md` d'un dossier validé vers un dossier dont l'amont n'est pas validé | Refusé (C1) |
| L10 | Renommage d'un autre fichier (`brouillon.md`) en `plan.md` | Contrôlé comme une création (C1) |
| L11 | Renommage avec modification sous le seuil de similarité de git | Vu comme suppression + ajout, contrôlé comme une création (C1) |
| L12 | Renommage de `plan.md` vers un autre nom, ou suppression | Non contrôlé (C9) |
| L13 | Modification d'un `plan.md` déjà commité, amont repassé en `draft` | Accepté (C9) |
| L14 | `templates/plan.md` à la racine | Accepté sans intent (C8) |
| L15 | `plan.md` sous `<lot>/templates/` (pas à la racine) | Contrôlé (C8) |
| L16 | `plan.md` sous `tests/<nom>/fixtures/` ou `<chemin>/tests/<nom>/fixtures/` | Accepté sans intent (C8) |
| L17 | Fichier nommé `Plan.md`, `plan.MD` ou `mon-plan.md` | Non contrôlé : nom exact `plan.md` (C1) |
| L18 | Dossier dont le nom contient un accent ou une espace | Contrôlé normalement, pas de faux « intent absent » (C1) |
| L19 | Deux `plan.md` refusés dans le même commit | Deux lignes de refus, commit refusé (C10) |
| L20 | `intent.md` présent dans `HEAD` et supprimé dans le commit du plan | Refusé, « intent absent » (C3, C17) |
| L21 | `spec.md` présente dans `HEAD` et supprimée dans le commit du plan | L'intent décide : accepté s'il est `validé`, refusé sinon (C3, C17) |

## Contrats

Entrée : l'index git au moment de `git commit` (fichiers ajoutés et renommés, lus avec `git diff --cached -z -M`), `HEAD` pour les fichiers absents de l'index.

Sortie, une ligne par plan refusé sur la sortie d'erreur, `<plan>` étant le chemin du plan depuis la racine du dépôt :

| Cas | Message |
|---|---|
| Intent absent (C4) | `<plan> : intent absent (<dossier>/intent.md)` |
| Spec non validée (C5) | `<plan> : spec non validée (statut : <valeur>)` |
| Intent non validé, sans spec (C6) | `<plan> : intent non validé (statut : <valeur>)` |

Formats repris du contrôle de la spec du lot 3. Statut absent : `<valeur>` vaut `absent` (C16). À la racine, `<dossier>/intent.md` s'écrit `intent.md`.

Code de retour du hook : `0` si tous les contrôles passent, `1` sinon (commit refusé).

`hooks/tests/hook-plan/run.sh` : une ligne `PASS <scénario>` ou `FAIL <scénario> (rc=<code>) <sortie>` par scénario ; code de sortie `0` si tout passe, non nul sinon.

## Critères d'acceptation

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Plan sans intent refusé, même avec une spec validée | Un dossier avec une `spec.md` `validé` commitée, sans `intent.md` | On commite un nouveau `plan.md` dans ce dossier | Commit refusé, message « `<dossier>/plan.md : intent absent (<dossier>/intent.md)` » | Automatisé |
| A2 | Plan refusé sur une spec non validée | Un intent `validé` et une spec `draft` commités | On commite un nouveau `plan.md` | Commit refusé, message « spec non validée (statut : draft) » | Automatisé |
| A3 | Plan accepté sur une spec validée | Un intent `validé` et une spec `validé` commités | On commite un nouveau `plan.md` | Commit accepté | Automatisé |
| A4 | Spec et plan dans le même commit, spec en `draft` | Un intent `validé` commité, sans spec | On commite ensemble une nouvelle `spec.md` `draft` et un nouveau `plan.md` | Commit refusé, message « `<dossier>/plan.md : spec non validée (statut : draft)` » | Automatisé |
| A5 | Spec et plan dans le même commit, spec `validé` | Un intent `validé` commité, sans spec | On commite ensemble une nouvelle `spec.md` `validé` et un nouveau `plan.md` | Commit accepté | Automatisé |
| A6 | Intent et plan dans le même commit, intent en `draft` | Un dossier vide, sans spec | On commite ensemble un nouvel `intent.md` `draft` complet et un nouveau `plan.md` | Commit refusé, message « intent non validé (statut : draft) » | Automatisé |
| A7 | Intent et plan dans le même commit, intent `validé` | Un dossier vide, sans spec | On commite ensemble un nouvel `intent.md` `validé` complet et un nouveau `plan.md` | Commit accepté | Automatisé |
| A8 | Sans spec, plan refusé sur un intent non validé | Un intent `draft` commité, sans spec | On commite un nouveau `plan.md` | Commit refusé, message « intent non validé (statut : draft) » | Automatisé |
| A9 | Sans spec, plan accepté sur un intent validé | Un intent `validé` commité, statut sur sa propre ligne puis sur la ligne de l'auteur | On commite un nouveau `plan.md` | Commit accepté dans les deux cas | Automatisé |
| A10 | Renommage vers un amont non validé refusé | Un `plan.md` commité dans un dossier validé, et un second dossier avec un intent `draft` sans spec | On fait `git mv` du plan vers le second dossier et on commite | Commit refusé, message « intent non validé (statut : draft) » | Automatisé |
| A11 | Modèle et fixtures acceptés sans intent | Aucun `intent.md` dans le dépôt | On commite `templates/plan.md`, puis `hooks/tests/x/fixtures/plan.md` et `tests/x/fixtures/plan.md` | Les trois commits sont acceptés | Automatisé |
| A12 | Contrôles existants au vert | Le hook modifié | On lance `bash scripts/verifier.sh` | `hooks/tests/hook-intent`, `hook-spec`, `hook-credential` et `hook-plan` sont `OK`, code 0 | Automatisé |
| A13 | Message lisible | Les commits refusés de A1, A2 et A8 | On lit chaque message | Il nomme le plan et, selon le cas, l'intent attendu ou le statut trouvé | Manuel |
| A14 | Spec validée | Cette spec | Revue du tech lead | Validation explicite, statut passé à `validé` par un humain | Humain |

Les cas limites L3, L4, L7, L8, L10, L13, L15, L17, L18, L19, L20 et L21 ont aussi un scénario dans `hooks/tests/hook-plan/run.sh`. L6 n'en a pas : il relève du contrôle du lot 3 (P2).

## Points d'attention

- **P1 — Règle différente de celle du lot 3.** Ici l'intent est lu dans le commit en cours quand il en fait partie (L5) ; le contrôle de la spec du lot 3 lit l'intent dans `HEAD` seulement, et refuse un intent validé dans le même commit que la spec (lot 3, C14 et A11). Tranché le 2026-10-21 : les deux règles cohabitent, l'alignement du lot 3 part dans un lot dédié (C18). Reste à ouvrir ce lot. Décideur : tech lead.
- **P2 — A5 suppose un intent validé dans `HEAD`.** Une spec créée dans le même commit que le plan passe aussi par le contrôle du lot 3, qui exige un intent `validé` dans `HEAD`. Le critère de l'intent « accepté si elle est `validé` » ne vaut donc, pour le commit entier, que si l'intent est déjà validé et commité ; avec un intent `draft` dans `HEAD`, le plan passe ce contrôle mais le commit est refusé (L6). Décideur : tech lead (lié à P1).
- **P3 — Le contrôle de la spec du lot 3 est contournable par renommage et se trompe sur les chemins accentués.** Il ne lit que les ajouts (`--diff-filter=A`) et sans `-z` : un `git mv` d'une `spec.md` donne un `R` et n'est pas contrôlé, et un dossier accentué arrive entre guillemets et produit un faux « intent absent » (constaté avec git 2.51). Ce lot couvre ces deux cas pour le plan (C1) sans corriger le lot 3 : la correction va dans le lot dédié de C18. Décideur : tech lead.
- **P4 — Liens cassés vers ce lot.** Le dossier est dans `requirements/in-progress/`, mais le `Parent` de l'intent pointe vers `../ia-factory.md` (le parent est dans `requirements/open/`), et la table de l'intent parent pointe vers `04b-hook-plan/intent.md` sous `open/`. Même erreur pour le lot 4a. Ni l'intent ni le parent ne sont modifiés par cette spec. Décideur : auteur de l'intent.
- **P5 — `templates/plan.md` n'existe pas encore.** Il est livré par le lot 4a ; A11 utilise un plan modèle de fixture copié à ce chemin dans le dépôt de test, comme `hook-spec` le fait pour `templates/spec.md`.
- **P6 — Lecture du statut : arbre de travail pour le skill du 4a, commit pour ce hook.** Le skill du lot 4a lit le statut dans l'arbre de travail, ce hook dans l'index ou `HEAD`. Un plan produit par le skill sur un amont validé mais non stagé sera refusé au commit. Cohérent avec le rôle de contrôle bloquant, à signaler dans la doc du skill. Décideur : tech lead.
- **P7 — Le statut `validé` est déclaratif.** Comme pour le lot 3, le hook vérifie un mot, pas l'identité de celui qui l'a écrit ; la garantie repose sur la revue de PR et les code owners. Décideur : tech lead.
- **P8 — Aucun skill de standards** (sécurité, conventions) n'existe dans `.claude/skills/` ; la spec n'est contrainte que par l'intent, le parent et les conventions de `CLAUDE.md`.

## Hors périmètre

- Template et skill de production du plan (lot 4a).
- Contrôle du contenu ou de la taille du plan.
- Contrôle des modifications, suppressions et renommages sortants d'un plan existant.
- Correction du contrôle de la spec du lot 3 (renommage, chemins accentués, intent du même commit) : voir P1 et P3.
- Correction des liens `Parent` et de la table de l'intent parent (P4).

## Questions ouvertes

Aucune : les trois questions sont tranchées le 2026-10-21 (C16, C17, C18).
