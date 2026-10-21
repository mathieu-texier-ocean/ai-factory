#!/usr/bin/env bash
# Teste le contrôle « intent validé » de hooks/pre-commit dans un dépôt git temporaire.
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

cd "$tmp" && git init -q . && git config user.email t@t && git config user.name t
mkdir templates hooks && cp "$repo_root/templates/intent.md" templates/ && cp "$repo_root/hooks/pre-commit" hooks/
git config core.hooksPath hooks
git add templates hooks && git -c core.hooksPath=/dev/null commit -qm init

fail=0
fx() { mkdir -p "$(dirname "$2")"; cp "$here/fixtures/$1" "$2"; }
# Commit sans hook de ce qui est stagé.
base() { git -c core.hooksPath=/dev/null commit -qm "${1:-état initial}" --allow-empty; }
# État initial commité sans hook : dépôt vidé (hors hook et modèle d'intent), puis l'intent donné
# dans <dossier> (lot par défaut), ou aucun avec -.
init() {
  local dir=${2:-lot}
  git ls-files -z | grep -zvxF -e hooks/pre-commit -e templates/intent.md | xargs -0 -r git rm -qf
  git clean -fdq; mkdir -p "$dir"
  [ "$1" = - ] || { fx "$1" "$dir/intent.md"; git add "$dir/intent.md"; }
  base
}
# attempt <nom> <attendu: pass|block> [texte attendu dans le message] : commite ce qui est stagé.
attempt() {
  local name=$1 expect=$2 msg=${3:-}
  out=$(git commit -qm "test" 2>&1); rc=$?
  if [ "$expect" = pass ] && [ $rc -eq 0 ]; then ok=1
  elif [ "$expect" = block ] && [ $rc -ne 0 ] && printf '%s' "$out" | grep -qF -- "$msg"; then ok=1
  else ok=0; fi
  git reset -q
  [ $ok -eq 1 ] && echo "PASS $name" || { echo "FAIL $name (rc=$rc) $out"; fail=1; }
}
# check <nom> <intent initial|-> <fichier stagé> <attendu> [message]
check() {
  init "$2"; fx spec-modele.md "$3"; git add "$3"
  attempt "$1" "$4" "${5:-}"
}

check "intent draft bloqué (A4, L1)"          intent-draft.md         lot/spec.md  block "lot/spec.md : intent non validé (statut : draft)"
check "intent absent bloqué (A5, L3)"         -                       lot/spec.md  block "lot/spec.md : intent absent (lot/intent.md)"
check "intent validé ligne seule (A6)"        intent-valide.md        lot/spec.md  pass
check "intent validé ligne auteur (A6, C18)"  intent-valide-auteur.md lot/spec.md  pass
check "casse Validé bloquée (L5)"             intent-statut-majuscule.md lot/spec.md  block "statut : Validé"
check "autre fichier ignoré (A7, L9)"         intent-draft.md         lot/notes.md pass

# Intent lu dans le commit en cours, sinon dans HEAD (lot 3b : remplace A11 et L4 du lot 3).
init intent-draft.md; fx intent-valide.md lot/intent.md; fx spec-modele.md lot/spec.md; git add lot
attempt "intent passé à validé dans le même commit accepté (lot 3b)" pass
init -; fx intent-draft.md lot/intent.md; fx spec-modele.md lot/spec.md; git add lot
attempt "intent draft dans le même commit bloqué (lot 3b)" block "lot/spec.md : intent non validé (statut : draft)"
init intent-valide.md; git rm -q lot/intent.md; fx spec-modele.md lot/spec.md; git add lot/spec.md
attempt "intent supprimé dans le commit de la spec (lot 3b)" block "lot/spec.md : intent absent (lot/intent.md)"
check "intent sans statut (lot 3b)"           intent-sans-statut.md   lot/spec.md  block "lot/spec.md : intent non validé (statut : absent)"
init intent-draft.md; fx intent-valide.md lot/intent.md; fx spec-valide.md lot/spec.md; fx spec-modele.md lot/plan.md; git add lot
attempt "intent validé, spec et plan dans le même commit (lot 3b, L6 du 4b)" pass

init intent-valide.md; fx spec-modele.md lot/spec.md; git add lot/spec.md; base spec
fx intent-draft.md lot/intent.md; git add lot/intent.md; base "intent draft"
printf '\nRévision.\n' >> lot/spec.md; git add lot/spec.md
attempt "modification de spec acceptée (A12, L10, L11)" pass

check "spec à la racine sans intent (C15)"   -                       spec.md      block "spec.md : intent absent (intent.md)"

init -; fx spec-modele.md templates/spec.md; git add templates/spec.md
attempt "modèle templates/spec.md ignoré (lot 1c C17, A6)" pass

init -; mkdir -p lot/templates; fx spec-modele.md lot/templates/spec.md; git add lot/templates/spec.md
attempt "spec sous lot/templates/ contrôlée (lot 1c L20)" block "lot/templates/spec.md : intent absent"

init -; fx spec-modele.md hooks/tests/x/fixtures/spec.md; git add hooks/tests/x
attempt "fixture hooks/tests/x/fixtures/ ignorée (lot 3b)" pass
init -; fx spec-modele.md tests/x/fixtures/spec.md; git add tests
attempt "fixture tests/x/fixtures/ à la racine ignorée (lot 3b)" pass

# Renommages (lot 3b).
init intent-valide.md; fx spec-modele.md lot/spec.md; git add lot/spec.md
fx intent-draft.md lot2/intent.md; git add lot2; base
git mv lot/spec.md lot2/spec.md
attempt "git mv vers un intent draft bloqué (lot 3b)" block "lot2/spec.md : intent non validé (statut : draft)"
init intent-valide.md; fx spec-modele.md lot/spec.md; git add lot/spec.md
fx intent-draft.md lot2/intent.md; git add lot2; base
git mv lot/spec.md lot2/spec.md; printf 'Contenu\nentièrement\nremplacé\n' > lot2/spec.md; git add lot2/spec.md
attempt "renommage sous le seuil de similarité bloqué (lot 3b)" block "lot2/spec.md : intent non validé (statut : draft)"
init intent-draft.md; fx spec-modele.md lot/brouillon.md; git add lot/brouillon.md; base
git mv lot/brouillon.md lot/spec.md
attempt "autre fichier renommé en spec.md bloqué (lot 3b)" block "lot/spec.md : intent non validé (statut : draft)"

# Chemins bruts (lot 3b).
init intent-valide.md "lot é x"; fx spec-modele.md "lot é x/spec.md"; git add "lot é x/spec.md"
attempt "dossier accentué avec espace, intent validé (lot 3b)" pass
init intent-draft.md "lot é x"; fx spec-modele.md "lot é x/spec.md"; git add "lot é x/spec.md"
attempt "dossier accentué avec espace, intent draft (lot 3b)" block "lot é x/spec.md : intent non validé (statut : draft)"
exit $fail
