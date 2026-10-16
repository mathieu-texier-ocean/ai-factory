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
fx() { cp "$here/fixtures/$1" "$2"; }
# État initial commité sans hook : lot/ vidé, puis l'intent donné (ou aucun avec -).
init() {
  git rm -rqf --ignore-unmatch lot spec.md; rm -rf lot spec.md; mkdir lot
  [ "$1" = - ] || { fx "$1" lot/intent.md; git add lot/intent.md; }
  git -c core.hooksPath=/dev/null commit -qm "état initial" --allow-empty
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
  init "$2"; fx spec.md "$3"; git add "$3"
  attempt "$1" "$4" "${5:-}"
}

check "intent draft bloqué (A4, L1)"          intent-draft.md         lot/spec.md  block "lot/spec.md : intent non validé (statut : draft)"
check "intent absent bloqué (A5, L3)"         -                       lot/spec.md  block "lot/spec.md : intent absent (lot/intent.md)"
check "intent validé ligne seule (A6)"        intent-valide.md        lot/spec.md  pass
check "intent validé ligne auteur (A6, C18)"  intent-valide-auteur.md lot/spec.md  pass
check "casse Validé bloquée (L5)"             intent-statut-majuscule.md lot/spec.md  block "statut : Validé"
check "autre fichier ignoré (A7, L9)"         intent-draft.md         lot/notes.md pass

init intent-draft.md; fx intent-valide.md lot/intent.md; fx spec.md lot/spec.md; git add lot
attempt "validé dans le même commit bloqué (A11, L4)" block "lot/spec.md : intent non validé (statut : draft)"

init intent-valide.md; fx spec.md lot/spec.md; git add lot/spec.md; git -c core.hooksPath=/dev/null commit -qm spec
fx intent-draft.md lot/intent.md; git add lot/intent.md; git -c core.hooksPath=/dev/null commit -qm "intent draft"
printf '\nRévision.\n' >> lot/spec.md; git add lot/spec.md
attempt "modification de spec acceptée (A12, L10, L11)" pass

check "spec à la racine sans intent (C15)"   -                       spec.md      block "spec.md : intent absent (intent.md)"
exit $fail
