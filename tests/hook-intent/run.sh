#!/usr/bin/env bash
# Teste hooks/pre-commit dans un dépôt git temporaire.
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$here/../.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

cd "$tmp" && git init -q . && git config user.email t@t && git config user.name t
mkdir templates hooks && cp "$repo_root/templates/intent.md" templates/ && cp "$repo_root/hooks/pre-commit" hooks/
git config core.hooksPath hooks
git add templates hooks && git -c core.hooksPath=/dev/null commit -qm init

fail=0
# check <nom> <fixture> <fichier cible> <attendu: pass|block> [texte attendu dans le message]
check() {
  local name=$1 fixture=$2 target=$3 expect=$4 msg=${5:-}
  mkdir -p "$(dirname "$target")"; cp "$here/fixtures/$fixture" "$target"
  git add "$target"
  out=$(git commit -qm "test" 2>&1); rc=$?
  git reset -q; rm -f "$target"
  if [ "$expect" = pass ] && [ $rc -eq 0 ]; then ok=1
  elif [ "$expect" = block ] && [ $rc -ne 0 ] && printf '%s' "$out" | grep -q -- "$msg"; then ok=1
  else ok=0; fi
  [ $ok -eq 1 ] && echo "PASS $name" || { echo "FAIL $name (rc=$rc) $out"; fail=1; }
}

check "complet accepté (scénario 3)"        complet.md        lot/intent.md pass
check "sans Pourquoi bloqué (scénario 2)"   sans-pourquoi.md  lot/intent.md block "manquante(s) : Pourquoi"
check "titre mal orthographié bloqué (L4)"  titre-faute.md    lot/intent.md block "Pourquoi"
check "plusieurs manquantes toutes nommées" sans-deux.md      lot/intent.md block "Pourquoi, Contraintes"
check "sans Priorité bloqué"             sans-priorite.md  lot/intent.md block "manquante(s) : Priorité"
check "section vide acceptée (L3)"          section-vide.md   lot/intent.md pass
check "autre nom de fichier ignoré (L8)"    sans-pourquoi.md  lot/autre.md  pass
exit $fail
