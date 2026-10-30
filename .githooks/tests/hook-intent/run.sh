#!/usr/bin/env bash
# Teste le contrôle des sections d'intent de .githooks/pre-commit dans un dépôt git temporaire.
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

cd "$tmp" && git init -q . && git config user.email t@t && git config user.name t
mkdir -p templates .githooks/lib
cp "$repo_root/templates/intent.md" templates/
cp "$repo_root/.githooks/pre-commit" .githooks/ && cp "$repo_root/.githooks/lib/credential.sh" .githooks/lib/
git config core.hooksPath .githooks
git add -A && git -c core.hooksPath=/dev/null commit -qm init

fail=0
# check <nom> <fixture> <fichier cible> <attendu: pass|block> [texte attendu dans le message]
check() {
  local name=$1 fixture=$2 target=$3 expect=$4 msg=${5:-} ok base
  base=$(git rev-parse HEAD)
  mkdir -p "$(dirname "$target")"; cp "$here/fixtures/$fixture" "$target"
  git add -- "$target"
  out=$(git commit -qm test 2>&1); rc=$?
  git reset -q --hard "$base"; git clean -qfdx
  if [ "$expect" = pass ] && [ $rc -eq 0 ]; then ok=1
  elif [ "$expect" = block ] && [ $rc -ne 0 ] && printf '%s' "$out" | grep -qF -- "$msg"; then ok=1
  else ok=0; fi
  [ $ok -eq 1 ] && echo "PASS $name" || { echo "FAIL $name (rc=$rc) $out"; fail=1; }
}

check "complet accepté"                     complet.md       intent/b/intent.md pass
check "sans Pourquoi bloqué"                sans-pourquoi.md intent/b/intent.md block "manquante(s) : Pourquoi"
check "titre mal orthographié bloqué"       titre-faute.md   intent/b/intent.md block "Pourquoi"
check "plusieurs manquantes toutes nommées" sans-deux.md     intent/b/intent.md block "Pourquoi, Contraintes"
check "sans Priorité bloqué"                sans-priorite.md intent/b/intent.md block "manquante(s) : Priorité"
check "section vide acceptée"               section-vide.md  intent/b/intent.md pass
check "chemin accentué contrôlé"            sans-pourquoi.md "intent/b é/intent.md" block "intent/b é/intent.md : section"
check "autre nom de fichier ignoré"         sans-pourquoi.md intent/b/spec.md   pass
check "intent.md hors du dossier ignoré"    sans-pourquoi.md doc/x/intent.md    pass
check "gabarit lui-même ignoré"             sans-pourquoi.md templates/intent.md pass

git config sdlc.intentDir besoins
check "intentDir de la configuration suivi" sans-pourquoi.md besoins/b/intent.md block "manquante(s) : Pourquoi"
check "ancien dossier alors ignoré"         sans-pourquoi.md intent/b/intent.md pass
exit $fail
