# Spec — Lot 1c : Hook credential en clair

- **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **Validation :** Tech lead

## Périmètre

Ajouter à `hooks/pre-commit` un contrôle bloquant qui refuse un commit introduisant un credential en clair dans `ai-factory`, avec un message qui nomme le fichier, la raison et la façon de corriger. La détection est un contrôle maison dans le hook (décision du PO) ; gitleaks reste réservé à une éventuelle CI (lot 13). Le lot livre aussi les tests du contrôle, au format des lots 2 et 3, rangés à côté du hook dans `hooks/tests/hook-credential/` (règle du lot 1h).

## Comportements

### Contrôle « pas de credential en clair » dans `hooks/pre-commit`

- **C1.** Le contrôle s'ajoute aux deux contrôles existants (sections de l'intent, intent validé) sans changer leur comportement ni leurs messages.
- **C2.** Il ne lit que le contenu indexé pour le commit (`git diff --cached`), pas l'arbre de travail.
- **C3.** Il ne contrôle que les lignes ajoutées par le commit : une ligne déjà présente dans `HEAD` n'est pas signalée (les credentials déjà dans l'historique sont hors périmètre).
- **C4.** La détection repose sur des motifs écrits dans le hook (contrôle maison), sans outil externe à installer. Les familles reconnues sont listées en C13.
- **C5.** Si au moins une ligne ajoutée correspond à un motif, le commit est refusé (code de sortie ≠ 0).
- **C6.** Pour chaque détection, le message nomme le fichier, la raison (le type de credential reconnu) et la façon de corriger : retirer la valeur du fichier, la remplacer par une référence (variable d'environnement, gestionnaire de secrets), et la révoquer si elle est réelle.
- **C7.** Le message n'affiche jamais la valeur détectée : la sortie du hook entre dans le contexte de l'agent, qui ne doit contenir aucun secret (contrainte de l'intent et du parent).
- **C8.** Sans détection, le contrôle laisse passer, et les autres contrôles du hook décident seuls.
- **C9.** Les contrôles s'additionnent : un commit à la fois incomplet (intent) et porteur d'un credential reçoit les deux messages.

### Tests du contrôle

- **C10.** Un `run.sh` dans `hooks/tests/hook-credential/`, avec ses fixtures dans `fixtures/` (sur le modèle de `hooks/tests/hook-spec/run.sh`) crée un dépôt temporaire, y copie le hook et les fixtures, tente des commits et affiche une ligne `PASS` ou `FAIL` par cas. Il sort en erreur si un cas échoue. Son chemin ne dépend pas du lot : il reste valable quand le lot passe en `closed/` et dans un nouveau projet copié sans `requirements/`.
- **C11.** Les fixtures contiennent des credentials fictifs, jamais de vrais. Rangées sous `hooks/tests/hook-credential/fixtures/`, elles ne sont pas contrôlées (C16) et se commitent sans `--no-verify`.
- **C12.** Les `run.sh` des lots 2 et 3 restent au vert avec le hook modifié.

### Arbitrages du 2026-10-16

- **C13.** Familles de credentials reconnues : clés privées (`-----BEGIN … PRIVATE KEY-----`) ; jetons de fournisseurs à préfixe connu (AWS `AKIA…`, GitHub `ghp_` et `github_pat_`, Anthropic `sk-ant-`, Slack `xox…`) ; affectations génériques (`password=`, `secret=`, `token=`, `api_key=` suivis d'une valeur littérale ; une référence ou un gabarit, entre guillemets ou non, n'est pas une valeur littérale : `$VAR`, `${VAR}`, `<à renseigner>`) ; URL avec identifiants (`scheme://user:motdepasse@hôte`). La raison du message (C6) nomme la famille reconnue.
- **C14.** Une ligne ajoutée qui porte une annotation d'exception en commentaire n'est pas signalée. L'annotation ne vaut que pour sa ligne et ne désactive pas les autres contrôles du hook. Le texte exact du marqueur est fixé au build (proposition : `credential-ok`).
- **C15.** Les fichiers binaires indexés ne sont pas contrôlés : seuls les fichiers texte sont lus.

### Révision du 2026-10-19 : premier commit d'un nouveau projet

Constat de la recette : dans un nouveau projet copié d'`ai-factory`, le premier commit avec le hook actif était refusé (fixtures de credentials fictifs, et `templates/spec.md` pris pour une spec sans intent).

- **C16.** Le contrôle des credentials ignore les fichiers indexés sous un dossier `fixtures/` d'un dossier `tests/` (convention du lot 1h : `<dossier du livrable>/tests/<nom>/fixtures/`), à toute profondeur et à la racine. Un dossier `fixtures/` hors d'un dossier `tests/` reste contrôlé.
- **C17.** Le contrôle « intent validé » (lot 3) ignore les fichiers sous `templates/` à la racine du dépôt : `templates/spec.md` est le modèle, pas la spec d'un lot. Un `spec.md` sous un autre dossier `templates/` reste contrôlé.

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Fichier modifié qui contenait déjà un credential, sans toucher à cette ligne | Commit accepté (C3) |
| L2 | Credential ajouté puis retiré de l'index avant le commit | Commit accepté : seul l'index compte (C2) |
| L3 | Credential présent dans l'arbre de travail mais pas indexé | Commit accepté (C2) |
| L4 | Credential dans un fichier supprimé par le commit | Commit accepté : aucune ligne ajoutée (C3) |
| L5 | Deux fichiers porteurs de credentials | Commit refusé, les deux fichiers nommés (C6) |
| L6 | Modification d'une fixture du lot 1c contenant un credential fictif | Commit accepté : les fixtures ne sont pas contrôlées (C16) |
| L7 | Commit avec `--no-verify` | Aucun contrôle ne joue : hors portée du hook, et aucun rattrapage tant que le lot 13 est suspendu (P3) |
| L8 | Hooks non activés (`core.hooksPath` absent) | Aucun contrôle ne joue (lot 1f) |
| L9 | Faux positif (valeur d'exemple qui ressemble à un credential) | La ligne porte l'annotation d'exception et passe (C14) |
| L10 | Ligne annotée dans un commit qui contient aussi un credential non annoté | Commit refusé, seul le fichier non annoté est nommé (C14) |
| L11 | Fichier binaire indexé contenant un motif | Non contrôlé, commit accepté (C15) |
| L12 | Fichier renommé ou déplacé dans le commit, avec un credential ajouté | Commit refusé, le nouveau chemin nommé (C3) |
| L13 | Fichier renommé ou déplacé sans ligne ajoutée, alors qu'il contenait déjà un credential | Commit accepté : aucune ligne ajoutée (C3) |
| L14 | Nom de fichier avec accents ou espaces | Contrôlé comme les autres, chemin nommé en clair dans le message (C2, C6) |
| L15 | Affectation par une référence entre guillemets (`password="$DB_PASSWORD"`) | Commit accepté (C13) |
| L16 | Credential fictif sous `hooks/tests/<nom>/fixtures/` ou `tests/<nom>/fixtures/` | Commit accepté (C16) |
| L17 | Credential sous un dossier `fixtures/` qui n'est pas dans un dossier `tests/` (`fixtures/`, `tests/fixtures/`) | Commit refusé (C16) |
| L18 | Fixture déplacée hors de `fixtures/` sans modification | Commit accepté : aucune ligne ajoutée (C3, L13 ; voir P6) |
| L19 | Premier commit d'un nouveau projet copié sans `requirements/`, hook actif | Commit accepté (C16, C17) |
| L20 | `spec.md` sous `lot/templates/` sans intent | Commit refusé (C17) |

## Contrats

- **Entrée :** l'index git au moment du commit.
- **Sortie en cas de refus :** code ≠ 0 et, sur la sortie d'erreur, une ligne par détection au format des messages existants : `<chemin> : <raison>`, suivie de la façon de corriger. Aucune valeur détectée n'est affichée.
- **Sortie sans détection :** rien d'ajouté par ce contrôle ; le code de sortie dépend des autres contrôles.
- **Annotation d'exception :** marqueur en commentaire sur la ligne concernée (texte fixé au build, C14).
- **Tests :** `bash hooks/tests/hook-credential/run.sh`, depuis la racine du dépôt, lignes `PASS <nom>` / `FAIL <nom>`, code 0 si tout passe.

## Critères d'acceptation

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Un credential en clair est refusé, avec fichier, raison et correction | Un dépôt avec le hook actif | On commite un fichier contenant un credential fictif | Commit refusé ; le message nomme le fichier, la raison et la façon de corriger, sans afficher la valeur | Automatisé |
| A2 | Un commit sans credential passe | Un dépôt avec le hook actif | On commite un fichier sans credential | Commit accepté | Automatisé |
| A3 | Les tests existants restent au vert | Le hook modifié | On lance les `run.sh` des lots 2 et 3 | Toutes les lignes sont `PASS`, code 0 | Automatisé |
| A4 | Les tests du contrôle passent, au format des lots 2 et 3 | `hooks/tests/hook-credential/run.sh` | On le lance | Toutes les lignes sont `PASS`, code 0 ; structure `run.sh` + `fixtures/` comme les lots 2 et 3 | Automatisé |
| A5 | Le premier commit d'un nouveau projet passe | Une copie d'`ai-factory` sans `requirements/`, `git init`, hook actif | On fait le premier commit sans `--no-verify` | Commit accepté | Manuel |
| A6 | Le modèle de spec n'est pas pris pour une spec | Un dépôt avec le hook actif, sans intent | On commite `templates/spec.md` | Commit accepté ; un `spec.md` sous `lot/templates/` reste refusé | Automatisé |

## Points d'attention

- **P1 — Affectations génériques et faux positifs.** La famille `password=`, `token=`… (C13) signalera aussi des exemples de documentation. L'annotation (C14) les débloque, au prix d'un marqueur visible en revue. Décideur : tech lead.
- **P2 — Fixtures : annotation ou `--no-verify` ?** L'intent imposait de commiter les fixtures avec `--no-verify`, seules dans leur commit. L'annotation (C14) permettait de les commiter normalement, mais les tests auraient dû retirer le marqueur à la copie. Tranché le 2026-10-19 : ni l'un ni l'autre, les fixtures sont exclues par leur chemin (C16).
- **P6 — Ce que l'exclusion laisse passer.** Un vrai credential placé sous `tests/<nom>/fixtures/` n'est pas vu, et une fixture déplacée hors de ce dossier sans modification non plus (L18). Le trou est plus large qu'une annotation par ligne, mais il ne demande ni `--no-verify` ni marqueur. Risque accepté par le demandeur le 2026-10-19 ; décideur : tech lead.
- **P3 — Aucun rattrapage d'un `--no-verify`.** Pas de CI sur `ai-factory` : le lot 13 (gitleaks en CI) est suspendu tant qu'aucune CI n'existe. Un commit fait avec `--no-verify` ou sans hooks actifs n'est contrôlé nulle part. Décideur : PO.
- **P4 — Fixtures et lot 13.** Les fixtures du lot contiennent des credentials fictifs commités : un futur contrôle en CI (gitleaks) les signalera. La question est déjà ouverte dans le lot 13. Décideur : tech lead.
- **P5 — Aucun skill de standards sécurité.** Aucun skill de sécurité n'existe dans `.claude/skills/` pour encadrer les motifs ou le message. Décideur : tech lead.

## Hors périmètre

- Activation de `core.hooksPath` dans les clones (lot 1f).
- Hook Claude Code sur les éditions de l'agent.
- Contrôle en CI par gitleaks, qui rattrape un `--no-verify` (lot 13, si une CI existe).
- Credentials déjà présents dans l'historique git.
- Règles langue et historique (écartées pour l'instant).
- Skills métier et de standards (lots 2 à 7).

## Questions ouvertes

