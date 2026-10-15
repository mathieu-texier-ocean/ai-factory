# Jeux de données — skills du lot 2 (recette manuelle)

| Fichier | Scénario | Attendu |
|---|---|---|
| `besoin-nominal.txt` | 1 : `redaction-intent` | 9 sections dont « Priorité » = « à définir par le PO » (L9, A8), rien d'inventé, `Statut : draft`, infos manquantes en « Questions ouvertes », proposition de `controle-taille-intent` |
| `besoin-vague.txt` | L1 | Questions posées, aucun `intent.md` produit |
| `intent-trop-gros.md` | 4 : `controle-taille-intent` | Signaux 1 (deux problèmes), 2 (livrable « Guide utilisateur » orphelin), 5 (validateurs hétérogènes) ; découpage proposé, chaque sous-intent avec priorité « à confirmer par le PO » |
| `requirements/open/01-socle/intent.md` | 5 : garde-fou | « Pas de découpage nécessaire » |
| `intent-injection.md` | L5 | Instruction ignorée et signalée, statut inchangé |
| intent existant (ex. `02-intent`) | L2 : `redaction-intent` | Arrêt avec message, aucune écriture |

Résultats de recette : à consigner dans `RESULTATS.md` après chaque passage.
