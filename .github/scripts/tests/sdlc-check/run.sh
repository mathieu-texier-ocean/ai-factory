#!/usr/bin/env bash
# Teste .github/scripts/sdlc-check.sh dans un dépôt git temporaire : une branche par cas,
# lancée comme en CI (BASE_SHA, HEAD_SHA, HEAD_REF).
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
fx="$repo_root/.githooks/tests/hook-credential/fixtures"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

cd "$tmp" && git init -q -b main . && git config user.email t@t && git config user.name t
mkdir -p .github/scripts .githooks/lib templates intent/acc
cp "$repo_root/.github/scripts/sdlc-check.sh" .github/scripts/
cp "$repo_root/.githooks/lib/credential.sh" .githooks/lib/
cp "$repo_root/templates/intent.md" templates/
echo "# Intent acc" > intent/acc/intent.md && echo "# Spec acc" > intent/acc/spec.md
git add -A && git commit -qm init
main=$(git rev-parse main)

fail=0
out=""
# branche <nom> : nouvelle branche depuis main.
branche() { git switch -q -f -C "$1" "$main"; git clean -qfdx; }
# commit <need> : commite l'index avec le trailer Need: (vide = sans trailer).
commit() { if [ -n "$1" ]; then git commit -qm test -m "Need: $1"; else git commit -qm test; fi; }
# essai <nom> <attendu: pass|block> [texte attendu dans la sortie]... : lance le check sur la branche courante.
essai() {
  local name=$1 expect=$2 ok=1 rc t; shift 2
  out=$(BASE_SHA=$main HEAD_SHA=$(git rev-parse HEAD) HEAD_REF=$(git branch --show-current) \
    bash .github/scripts/sdlc-check.sh 2>&1); rc=$?
  if [ "$expect" = pass ]; then [ $rc -eq 0 ] || ok=0; else [ $rc -ne 0 ] || ok=0; fi
  for t in "$@"; do printf '%s' "$out" | grep -qF -- "$t" || ok=0; done
  [ $ok -eq 1 ] && echo "PASS $name" || { echo "FAIL $name (rc=$rc) $out"; fail=1; }
}
absent() {
  if [ -z "$2" ]; then echo "FAIL $1 : valeur à chercher vide"; fail=1
  elif printf '%s' "$out" | grep -qF -- "$2"; then echo "FAIL $1 : « $2 » affiché"; fail=1
  else echo "PASS $1"; fi
}

branche need/nouv/intent
mkdir -p intent/nouv && echo "# Intent" > intent/nouv/intent.md && git add -A && commit nouv
essai "PR intent conforme acceptée" pass "conventions du SDLC respectées"

branche need/nouv/intent
mkdir -p intent/nouv && echo "# Intent" > intent/nouv/intent.md && git add -A && commit ""
essai "commit sans Need: refusé" block "trailer Need: manquant"

branche need/nouv/spec
mkdir -p intent/nouv && echo "# Spec" > intent/nouv/spec.md && git add -A && commit nouv
essai "spec avant l'intent fusionné refusée" block "intent.md pas encore fusionné"

branche need/acc/build
echo "# Plan" > intent/acc/plan.md && git add -A && commit acc
essai "PR build conforme acceptée" pass "conventions du SDLC respectées"

branche need/acc/build
echo "# Plan" > intent/acc/plan.md && mkdir -p "intent/autre é" && echo x > "intent/autre é/note é.md" && git add -A && commit acc
essai "PR build : chemin accentué d'un autre besoin refusé" block "intent/autre é/note é.md appartient à un autre besoin"

branche need/acc/build
echo "# Plan" > intent/acc/plan.md && git mv intent/acc/spec.md intent/acc/ancienne-spec.md && git add -A && commit acc
essai "PR build : spec renommée refusée" block "intent/acc/spec.md ne change que par une PR intent/spec"

branche outillage
mkdir -p doc && git mv intent/acc/intent.md doc/intent.md && commit ""
essai "hors besoin : intent déplacé hors du dossier refusé" block "intent/acc/intent.md : un artefact de besoin"

branche outillage
cp "$fx/aws.txt" aws.txt && git add -A && commit ""
essai "credential en clair refusé" block "aws.txt : credential en clair (jeton fournisseur)"
absent "valeur jamais affichée" "$(grep -oE 'AKIA[A-Z0-9]+' "$fx/aws.txt")"

branche outillage
cp "$fx/annote.txt" annote.txt && cp "$fx/affectation-reference.txt" ref.txt && git add -A && commit ""
essai "ligne annotée et référence acceptées" pass "aucun credential en clair"

branche outillage
cp "$fx/aws.txt" aws.txt && git add -A && commit "" && git rm -q aws.txt && commit ""
essai "credential ajouté puis retiré dans la PR accepté" pass

branche need/acc/build
echo "# Plan" > intent/acc/plan.md && cp "$fx/url.txt" config.txt && git add -A && commit acc
essai "credential refusé aussi sur une PR need/*" block "config.txt : credential en clair (URL avec identifiants)"

exit $fail
