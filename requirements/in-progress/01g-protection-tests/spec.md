# Spec — Lot 1g : Protection des tests pendant un correctif

- **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** draft
- **Validation :** Tech lead

## Périmètre

Un hook Claude Code `PreToolUse`, déclaré dans `.claude/settings.json` à côté de ceux du lot 1f, qui demande la confirmation de l'humain avant que l'agent modifie ou supprime un fichier existant sous un dossier `tests/`, quand la branche courante commence par `bugfix/`. Le hook ne bloque pas : l'humain décide. La création d'un nouveau test reste libre. C'est la version contraignante de la consigne « corriger le code, pas le test » du lot 1e.

## Comportements

### Hook `PreToolUse` de protection des tests

- **C1.** Le hook ne joue que si la branche courante du dépôt de session commence par `bugfix/`. Sur toute autre branche, il laisse passer sans rien demander.
- **C2.** Un « test » est tout fichier dont le chemin, relatif à la racine du dépôt, contient un dossier `tests/` : scripts et fixtures.
- **C3.** Outils d'édition : un appel Edit ou Write qui vise un fichier existant sous `tests/` déclenche une demande de confirmation à l'humain.
- **C4.** Création : un appel Write qui vise un fichier qui n'existe pas encore sous `tests/` passe sans confirmation.
- **C5.** Commandes Bash : une commande dont le texte écrit sous `tests/` (modification ou suppression d'un fichier existant) déclenche une demande de confirmation. La détection se fait sur le texte de la commande, comme au lot 1f. Les chemins relatifs sont résolus à partir du champ `cwd` de l'entrée du hook, en suivant les `cd` de la commande, avant de tester s'ils sont sous `tests/`.
- **C6.** La demande de confirmation donne la raison : branche de correctif, fichier de test visé, rappel « pendant un correctif, corriger le code, pas le test ; si le changement de test est volontaire, le confirmer ».
- **C7.** Une modification hors de `tests/` passe sans confirmation, sur toute branche.
- **C8.** Le hook ne fait que lire (branche, existence du fichier, entrée de l'outil) : il ne modifie ni le dépôt ni sa configuration.
- **C9.** Le script du hook est dans `.claude/hooks/` et déclaré dans `.claude/settings.json`, comme ceux du lot 1f, sans modifier ces derniers.

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | Branche `fix/…` ou `hotfix/…` | Pas de confirmation : seul le préfixe `bugfix/` compte (C1) |
| L2 | HEAD détachée (aucune branche courante) | Pas de confirmation (C1) |
| L3 | Write sur un nouveau fichier sous `tests/` (test de non-régression) | Passe sans confirmation (C4) |
| L4 | Write qui écrase un fichier existant sous `tests/` | Confirmation demandée (C3) |
| L5 | Bash `rm`, `mv` ou `sed -i` sur un fichier existant sous `tests/` | Confirmation demandée (C5) |
| L6 | Script lancé par l'agent qui écrit sous `tests/` (par exemple un `run.sh`) | Non détecté, passe : risque accepté par l'intent |
| L7 | L'humain refuse la confirmation | L'outil ne s'exécute pas ; l'agent reçoit le refus |
| L8 | Fichier sous un dossier nommé `tests/` hors de `requirements/` | Concerné : tout dossier `tests/` compte (C2) |
| L9 | Commande Bash qui ne fait que lire sous `tests/` (`cat`, `bash run.sh`) | Voir « Points d'attention » |
| L10 | Bash qui crée un nouveau fichier sous `tests/` (`cat > tests/…/nouveau`) | Voir « Points d'attention » |
| L11 | Chemin relatif dans la commande Bash (`cd .claude/hooks/tests && sed -i … run.sh`, ou `cwd` déjà sous `tests/`) | Confirmation demandée : le chemin est résolu à partir de `cwd` et des `cd` (C5) |

## Contrats

- **Déclaration :** `.claude/settings.json`, entrée `PreToolUse` avec un matcher sur les outils Edit, Write et Bash ; script dans `.claude/hooks/`.
- **Entrée :** JSON de Claude Code sur stdin (nom de l'outil, chemin visé ou commande, `cwd`).
- **Branche :** nom de la branche courante du dépôt de session ; préfixe `bugfix/`.
- **Sortie, confirmation demandée :** décision de permission « demander » renvoyée à Claude Code, avec la raison de C6 ; l'humain voit la demande dans la session.
- **Sortie, rien à demander :** aucune sortie, code 0.

## Critères d'acceptation

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Modification par Edit ou Write sur `bugfix/` | Une session Claude Code sur une branche `bugfix/…` | L'agent modifie un fichier existant sous `tests/` avec Edit ou Write | Claude Code demande la confirmation de l'humain, avec la raison | Manuel |
| A2 | Modification ou suppression par Bash sur `bugfix/` | Une session sur une branche `bugfix/…` | L'agent lance une commande Bash qui modifie ou supprime un fichier existant sous `tests/` | Claude Code demande la confirmation de l'humain | Manuel |
| A3 | Création libre sur `bugfix/` | Une session sur une branche `bugfix/…` | L'agent crée un nouveau fichier sous `tests/` | Le fichier est créé sans confirmation | Manuel |
| A4 | Hors `tests/` sur `bugfix/` | Une session sur une branche `bugfix/…` | L'agent modifie un fichier hors de `tests/` | La modification passe sans confirmation | Manuel |
| A5 | Autre branche | Une session sur une branche qui ne commence pas par `bugfix/` | L'agent modifie un fichier existant sous `tests/` | La modification passe sans confirmation | Manuel |

## Limites connues

- **Hook chargé seulement depuis la racine du dépôt.** Claude Code ne lit `.claude/settings.json` que dans le dossier où la session est lancée (lot 1i). Une session lancée depuis un dossier parent, par exemple `/home/ocean/Projets`, ne charge pas le hook : sur une branche `bugfix/`, les tests restent modifiables sans confirmation. La levée de cette limite relève du lot 1i.

## Points d'attention

- **P1 — Création par Bash.** L'intent laisse la création libre, mais la détection Bash se fait sur le texte : `cat > tests/…/nouveau` ressemble à un écrasement. Vérifier l'existence du chemin visé n'est possible que si la commande le laisse extraire. À trancher : demander confirmation pour toute écriture Bash sous `tests/` (plus simple, contredit la création libre pour Bash), ou ne la demander que si le chemin extrait existe. Décideur : tech lead.
- **P2 — Lectures sous `tests/` (L9).** `bash requirements/…/tests/…/run.sh` cite un chemin sous `tests/` sans rien y écrire. La détection doit viser les opérations d'écriture (`rm`, `mv`, `cp`, `sed -i`, `tee`, `>`, `>>`…), pas la simple mention du chemin, sinon chaque lancement de test demandera confirmation. Décideur : tech lead.
- **P3 — Le relecteur ne voit rien.** L'intent dit que le relecteur « sait qu'une modification de test sur un correctif a été approuvée par un humain », mais aucun livrable ne trace la confirmation hors de la session (commit, PR). Décideur : PO (ajouter une trace, ou retirer ce bénéfice de « Pour qui »).
- **P4 — Modes de permission.** La demande de confirmation passe par le mécanisme de permission de Claude Code. Son comportement dans les modes qui approuvent automatiquement (mode auto, contournement des permissions) est à vérifier : si la demande y est sautée, la protection disparaît. Décideur : tech lead.
- **P5 — Tests du hook absents de l'intent.** L'intent ne liste pas de tests automatisés. Le lot 1f a décidé d'un `run.sh` qui teste ses scripts hors de Claude Code ; le même choix pour 1g n'est pas tranché. Décideur : tech lead (et PO pour l'ajouter en livrable).
- **P6 — Aucun skill de standards.** Aucun skill de conventions ou de sécurité n'existe dans `.claude/skills/`. Décideur : tech lead.

## Hors périmètre

- La consigne « corriger le code, pas le test » dans `CLAUDE.md` (lot 1e).
- Les modifications faites par l'humain, hors de Claude Code.
- Les branches autres que `bugfix/…` (dont `fix/` et `hotfix/`).
- Contrôle au commit ou en CI.
- La création de nouveaux fichiers sous `tests/`.
- Les écritures indirectes, par un script lancé par l'agent.

## Questions ouvertes

- Un fichier sous un dossier `tests/` situé hors du dépôt de session (par exemple un dépôt temporaire) est-il concerné ? L'intent parle d'`ai-factory` sans le préciser.
