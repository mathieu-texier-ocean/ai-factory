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
- **C11.** Les fixtures contiennent des credentials fictifs, jamais de vrais. Elles sont commitées avec `--no-verify`, dans un commit qui ne contient qu'elles.
- **C12.** Les `run.sh` des lots 2 et 3 restent au vert avec le hook modifié.

### Arbitrages du 2026-10-16

- **C13.** Familles de credentials reconnues : clés privées (`-----BEGIN … PRIVATE KEY-----`) ; jetons de fournisseurs à préfixe connu (AWS `AKIA…`, GitHub `ghp_` et `github_pat_`, Anthropic `sk-ant-`, Slack `xox…`) ; affectations génériques (`password=`, `secret=`, `token=`, `api_key=` suivis d'une valeur littérale ; une référence ou un gabarit, entre guillemets ou non, n'est pas une valeur littérale : `$VAR`, `${VAR}`, `<à renseigner>`) ; URL avec identifiants (`scheme://user:motdepasse@hôte`). La raison du message (C6) nomme la famille reconnue.
- **C14.** Une ligne ajoutée qui porte une annotation d'exception en commentaire n'est pas signalée. L'annotation ne vaut que pour sa ligne et ne désactive pas les autres contrôles du hook. Le texte exact du marqueur est fixé au build (proposition : `credential-ok`).
- **C15.** Les fichiers binaires indexés ne sont pas contrôlés : seuls les fichiers texte sont lus.

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Fichier modifié qui contenait déjà un credential, sans toucher à cette ligne | Commit accepté (C3) |
| L2 | Credential ajouté puis retiré de l'index avant le commit | Commit accepté : seul l'index compte (C2) |
| L3 | Credential présent dans l'arbre de travail mais pas indexé | Commit accepté (C2) |
| L4 | Credential dans un fichier supprimé par le commit | Commit accepté : aucune ligne ajoutée (C3) |
| L5 | Deux fichiers porteurs de credentials | Commit refusé, les deux fichiers nommés (C6) |
| L6 | Modification d'une fixture du lot 1c contenant un credential fictif | Commit refusé : la fixture se recommite avec `--no-verify`, seule dans son commit (C11) |
| L7 | Commit avec `--no-verify` | Aucun contrôle ne joue : hors portée du hook, et aucun rattrapage tant que le lot 13 est suspendu (P3) |
| L8 | Hooks non activés (`core.hooksPath` absent) | Aucun contrôle ne joue (lot 1f) |
| L9 | Faux positif (valeur d'exemple qui ressemble à un credential) | La ligne porte l'annotation d'exception et passe (C14) |
| L10 | Ligne annotée dans un commit qui contient aussi un credential non annoté | Commit refusé, seul le fichier non annoté est nommé (C14) |
| L11 | Fichier binaire indexé contenant un motif | Non contrôlé, commit accepté (C15) |
| L12 | Fichier renommé ou déplacé dans le commit, avec un credential ajouté | Commit refusé, le nouveau chemin nommé (C3) |
| L13 | Fichier renommé ou déplacé sans ligne ajoutée, alors qu'il contenait déjà un credential | Commit accepté : aucune ligne ajoutée (C3) |
| L14 | Nom de fichier avec accents ou espaces | Contrôlé comme les autres, chemin nommé en clair dans le message (C2, C6) |
| L15 | Affectation par une référence entre guillemets (`password="$DB_PASSWORD"`) | Commit accepté (C13) |

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

## Points d'attention

- **P1 — Affectations génériques et faux positifs.** La famille `password=`, `token=`… (C13) signalera aussi des exemples de documentation. L'annotation (C14) les débloque, au prix d'un marqueur visible en revue. Décideur : tech lead.
- **P2 — Fixtures : annotation ou `--no-verify` ?** L'intent impose de commiter les fixtures avec `--no-verify`, seules dans leur commit. L'annotation (C14) permettrait de les commiter normalement, sans sauter les contrôles des lots 2 et 3, mais contredit la lettre de l'intent. Décideur : tech lead.
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

