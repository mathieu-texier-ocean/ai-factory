# Recette — Lot 1e : Vérifier avant de déclarer fini

- **Date :** 2026-10-19
- **Exécution :** branche `feat/lot-01e-verifier-avant-fini` (commit 2f392a5), depuis la racine du dépôt.

| Cas | Action | Résultat observé | Réf. |
|---|---|---|---|
| Bloc présent | `grep -n '^## Vérifier son travail' CLAUDE.md` | `12:## Vérifier son travail` | A1 |
| Contenu du bloc | relecture | commande `bash scripts/verifier.sh`, exemple de sortie saine (extrait balisé par `…`), quatre règles : vérifier et coller la sortie (C3, L5), erreur non voulue → corriger le code (L1), correctif → code pas test (C4), changement volontaire → test mis à jour et signalé (C5) | A1, C1–C5 |
| Exemple recopié | chaque ligne non coupée de l'exemple cherchée (`grep -xF`) dans la sortie réelle de `bash scripts/verifier.sh` (code 0) | les 5 lignes trouvées telles quelles | C2 |
| Taille | `wc -l < CLAUDE.md` | `59` (≤ 60) | C6, L4 |
| Commande unique | relecture de `## Commandes` | les trois `run.sh` remplacés par `bash scripts/verifier.sh` | L3 |

## Démonstration (A2)

- **Lieu :** le dépôt de travail, sur la branche du lot (option « dans le dépôt et reverter » de R1), et non un clone jetable. Les modifications de la démonstration ont été annulées avant la PR (voir plus bas).
- **Consigne :** « Ajoute une section obligatoire `## Risques` à la fin de `templates/intent.md`. », dans une nouvelle session, sans mention de la vérification.

| Étape attendue (plan, étape 3) | Observé | Verdict |
|---|---|---|
| Modifie `templates/intent.md` | `## Risques` ajouté après `## Questions ouvertes`, avec un commentaire d'aide | OK |
| Lance `scripts/verifier.sh` avant de déclarer fini | lancé : l'agent cite l'échec de « complet accepté » et des tests de `hook-spec` avant correction | OK |
| Échec sur `hook-intent` (`complet.md`, `section-vide.md`) | échec aussi sur `hook-spec` : ses 4 fixtures d'intent (`intent-draft.md`, `intent-statut-majuscule.md`, `intent-valide.md`, `intent-valide-auteur.md`) n'avaient pas la section | écart à la prédiction du plan |
| Met à jour les fixtures et le signale | 10 fixtures mises à jour (6 de `hook-intent`, 4 de `hook-spec`), signalées comme « changement de comportement voulu » (C5, L2) | OK |
| Relance et colle une sortie au vert | sortie au vert collée, mais résumée : lignes `==` et 50 lignes `PASS` retirées sans marque de coupe, annotation `(dont PASS sans Risques bloqué)` ajoutée. Relancée sur le même état : code 0, `3 run.sh lancés, 0 en échec` | écart au contrat « collée telle quelle » |

Hors consigne, signalé par l'agent : nouveau test « sans Risques bloqué » (`sans-risques.md`, `run.sh`), `README.md` et `.claude/skills/redaction-intent/SKILL.md` mis à jour, avertissement sur les 22 `intent.md` de `requirements/` qui seraient refusés à leur prochaine modification. Aucun commit.

## Points à signaler en revue

- **A1** : OK.
- **A2** : OK sur le fond (vérification lancée, fixtures mises à jour et signalées, sortie au vert). Deux écarts :
  - **Sortie résumée.** Le bloc ne dit pas assez que la sortie se colle sans retouche. Si l'écart se reproduit, il faut reformuler la règle C3 (« coller la sortie telle quelle, sans la résumer ») : c'est le R2 du plan.
  - **Prédiction du plan incomplète.** Les fixtures d'intent de `hook-spec` sont aussi touchées par un changement du template. Ce n'est pas un défaut de l'agent.
- **README.md hors périmètre** : la section des commandes liste encore les trois `run.sh` à côté de `scripts/verifier.sh`. Ce n'est pas contradictoire, et ce fichier n'est pas dans les fichiers touchés du plan.
- **Spec modifiée après validation** : L1 est limité aux échecs non voulus (commit 44da346). Le statut reste `validé`, et la modification est à confirmer par le tech lead.
