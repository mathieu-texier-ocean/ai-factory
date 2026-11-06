#!/usr/bin/env bash
# Teste scripts/release-asset.sh dans un dépôt git temporaire, avec un gh factice (fixtures/gh).
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
script="$repo_root/scripts/release-asset.sh"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export PATH="$here/fixtures:$PATH"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

fail=0
out="" err="" rc=0
lance() {
  out=$(bash "$script" "$@" 2>"$tmp/err"); rc=$?
  err=$(cat "$tmp/err")
}
ok() { echo "PASS $1"; }
ko() { echo "FAIL $1"; printf '  rc=%s\n  stdout: %s\n  stderr: %s\n' "$rc" "$out" "$err"; fail=1; }
verifie() { local n=$1; shift; if "$@"; then ok "$n"; else ko "$n"; fi; }
contient() { printf '%s' "$1" | grep -qF -- "$2"; }
# cas : journal, fichiers joints et fichier envoyé remis à zéro.
cas() {
  export GH_LOG="$tmp/gh.log" GH_ASSETS="$tmp/assets" GH_UPLOAD="$tmp/envoye" GH_FAIL=0
  : > "$GH_LOG"; : > "$GH_ASSETS"; rm -f "$GH_UPLOAD"
}

# Faux clone du kit : le vrai bin/git-sdlc, tagué.
K=$tmp/kit
mkdir -p "$K/bin" && cd "$K" && git init -q . && git config user.email t@t && git config user.name t
cp "$repo_root/bin/git-sdlc" bin/git-sdlc
git add -A && git commit -qm kit && git tag 26.11.05 && git tag 26.11.05.2 && git tag v1.0
sed 's/^VERSION=dev$/VERSION=autre/' "$repo_root/bin/git-sdlc" > bin/git-sdlc
git commit -qam sans-dev && git tag 26.11.06

cas; lance 26.11.05
verifie "tag YY.MM.DD : fichier joint" [ "$rc" = 0 -a -f "$GH_UPLOAD" ]
verifie "tag YY.MM.DD : envoyé sous le nom git-sdlc, à la release du tag" grep -qE '^release upload 26\.11\.05 .*/git-sdlc$' "$GH_LOG"
verifie "tag YY.MM.DD : exécutable" [ -x "$GH_UPLOAD" ]
verifie "tag YY.MM.DD : version affichée = tag" [ "$(bash "$GH_UPLOAD" version)" = 26.11.05 ]
verifie "tag YY.MM.DD : seule la ligne VERSION change" [ "$(diff "$repo_root/bin/git-sdlc" "$GH_UPLOAD" | grep -c '^[<>]')" = 2 ]

cas; lance 26.11.05.2
verifie "tag YY.MM.DD.V : fichier joint, version = tag" [ "$rc" = 0 -a "$(bash "$GH_UPLOAD" version)" = 26.11.05.2 ]

cas; printf 'notes.txt\ngit-sdlc\n' > "$GH_ASSETS"; lance 26.11.05
verifie "déjà joint : échec explicite, rien envoyé" [ "$rc" = 1 -a ! -e "$GH_UPLOAD" ]
verifie "déjà joint : message" contient "$err" "déjà joint"
verifie "déjà joint : aucun upload demandé" sh -c "! grep -q '^release upload' '$GH_LOG'"

cas; printf 'git-sdlc-old\n' > "$GH_ASSETS"; lance 26.11.05
verifie "autre fichier joint : git-sdlc joint quand même" [ "$rc" = 0 -a -f "$GH_UPLOAD" ]

cas; lance v1.0
verifie "tag hors format : code 0, aucun fichier, aucun appel à gh" [ "$rc" = 0 -a ! -e "$GH_UPLOAD" -a ! -s "$GH_LOG" ]
verifie "tag hors format : message" contient "$out" "aucun fichier joint"

cas; lance 26.11.06
verifie "VERSION=dev absent au tag : échec, rien envoyé" [ "$rc" = 1 -a ! -e "$GH_UPLOAD" ]

cas; GH_FAIL=1; lance 26.11.05
verifie "release illisible : échec, rien envoyé" [ "$rc" = 1 -a ! -e "$GH_UPLOAD" ]

cas; lance 26.11.09
verifie "tag absent du clone : échec, rien envoyé" [ "$rc" = 1 -a ! -e "$GH_UPLOAD" ]

cas; lance
verifie "sans argument : usage, code 2" [ "$rc" = 2 ]

verifie "workflow : déclenché par la publication de la release" grep -qE '^    types: \[published\]$' "$repo_root/.github/workflows/release.yml"
verifie "workflow : contents: write sur le seul job" sh -c "[ \$(grep -c 'contents: write' '$repo_root/.github/workflows/release.yml') = 1 ] && grep -qE '^  contents: read$' '$repo_root/.github/workflows/release.yml'"

exit $fail
