# Spec — Lot 1e : Vérifier avant de déclarer fini

- **Intent :** [intent.md](intent.md)
- **Auteur :** Mathieu TEXIER · **Statut :** validé
- **Validation :** Tech lead

## Périmètre

Ajouter à `CLAUDE.md` (lot 1a) un bloc « Vérifier son travail » qui donne la commande de vérification du lot 1b, un exemple de sortie saine et la règle de conduite de l'agent : lancer la commande avant de déclarer fini et coller la sortie. C'est une consigne, pas un blocage : aucun hook ne l'impose.

## Comportements

### Bloc « Vérifier son travail » dans `CLAUDE.md`

- **C1.** Le bloc donne la commande du lot 1b, telle qu'elle s'exécute depuis la racine.
- **C2.** Il montre un exemple de sortie saine de cette commande (tous les tests au vert, code 0), recopié d'une exécution réelle.
- **C3.** Il pose la règle : avant de déclarer une tâche finie, l'agent lance la commande et colle sa sortie dans sa réponse.
- **C4.** Il pose la règle de correctif : pendant un correctif, l'agent corrige le code, pas le test.
- **C5.** Il pose la règle de changement volontaire : si le comportement change volontairement, l'agent met à jour le test et le signale explicitement.
- **C6.** Le bloc garde `CLAUDE.md` sous une page, soit 60 lignes au plus (contrainte du lot 1a).

## Cas limites

| # | Cas | Comportement attendu |
|---|---|---|
| L1 | La commande sort en erreur sans changement volontaire de comportement | L'agent ne déclare pas la tâche finie ; il colle la sortie et corrige le code (C3, C4) |
| L2 | Un test échoue parce que le comportement a changé volontairement | L'agent met à jour le test et le signale (C5) |
| L3 | La commande du lot 1b change de nom ou d'emplacement | Le bloc est mis à jour par PR, comme toute commande de `CLAUDE.md` (lot 1a) |
| L4 | L'ajout du bloc ferait dépasser 60 lignes | Le bloc ou une section de `CLAUDE.md` est resserré (C6) |
| L5 | Tâche qui ne touche à aucun fichier testé | La règle s'applique quand même : la commande est lancée et sa sortie collée (C3) |

## Contrats

- **Fichier :** `CLAUDE.md` à la racine, bloc ajouté sous un titre de niveau 2 « Vérifier son travail ».
- **Dépendances :** commande du lot 1b (existante au moment du build), `CLAUDE.md` du lot 1a.
- **Sortie attendue de l'agent :** la sortie de la commande, collée telle quelle, avant toute déclaration « fini ».

## Critères d'acceptation

| # | Critère | Étant donné | Quand | Alors | Type |
|---|---|---|---|---|---|
| A1 | Le bloc donne la commande, un exemple de sortie saine et la règle | `CLAUDE.md` après merge du lot | On relit le bloc « Vérifier son travail » | La commande, un exemple de sortie saine et les trois règles (C3 à C5) y figurent | Manuel |
| A2 | L'agent vérifie avant de déclarer fini, met à jour les fixtures en le signalant et colle la sortie | Une session Claude Code sur `ai-factory`, `CLAUDE.md` avec le bloc | On demande à l'agent d'ajouter une section obligatoire à `templates/intent.md` | L'agent lance la commande avant de déclarer fini, met à jour les fixtures concernées en le signalant, et colle une sortie au vert | Humain |

## Points d'attention

- **P1 — La démonstration modifie le template.** Ajouter une section obligatoire à `templates/intent.md` rend incomplets tous les intents existants au prochain commit qui les touche. Faire la démonstration sur une branche jetable, non mergée, n'a pas été retenu le 2026-10-16 : où la faire reste à trancher. Décideur : tech lead.
- **P2 — Une démonstration ne prouve pas l'habitude.** A2 vérifie un cas. Le critère de succès (moins de cycles de reprise) ne se mesurera qu'à l'usage. Décideur : PO.
- **P3 — Pas de CI.** Le PO a confirmé l'absence de CI sur `ai-factory` ; le lot 13 est suspendu tant qu'aucune CI n'existe. Le valideur « CI » du lot 5 dans `ia-factory.md` en suppose toujours une. Décideur : PO.
- **P4 — Aucun skill de standards.** Aucun skill de conventions n'existe dans `.claude/skills/`. Décideur : tech lead.

## Hors périmètre

- La commande de vérification elle-même (lot 1b).
- Hook qui bloque l'édition des tests pendant un correctif (nouveau sous-lot 1g).
- Hook « commande au vert avant ouverture de PR » (lot 5) : 1e est une consigne, pas un blocage.

## Questions ouvertes
