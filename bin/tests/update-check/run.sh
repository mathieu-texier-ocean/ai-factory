#!/usr/bin/env bash
# Teste la version de git-sdlc et la vérification des mises à jour du kit, dans des dépôts
# git temporaires, avec un gh factice (fixtures/gh).
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
sdlc="$repo_root/bin/git-sdlc"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export PATH="$here/fixtures:$PATH"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

fail=0
out="" err="" rc=0

# lance <script> <args…> : remplit out, err et rc.
lance() {
  local s=$1; shift
  out=$(bash "$s" "$@" 2>"$tmp/err"); rc=$?
  err=$(cat "$tmp/err")
}
ok()   { echo "PASS $1"; }
ko()   { echo "FAIL $1"; printf '  rc=%s\n  stdout: %s\n  stderr: %s\n' "$rc" "$out" "$err"; fail=1; }
# verifie <nom> <condition…> : PASS si la commande shell réussit.
verifie() { local n=$1; shift; if "$@"; then ok "$n"; else ko "$n"; fi; }

# --- version ---
cd "$repo_root"
lance "$sdlc" version
verifie "version : dev dans le dépôt du kit" [ "$rc" = 0 -a "$out" = dev -a -z "$err" ]
lance "$sdlc" --version
verifie "--version : synonyme de version" [ "$rc" = 0 -a "$out" = dev ]
cd "$tmp"
lance "$sdlc" version
verifie "version : hors dépôt git, sans gh" [ "$rc" = 0 -a "$out" = dev ]
verifie "version : une seule ligne VERSION= dans le script" [ "$(grep -c '^VERSION=' "$sdlc")" = 1 ]

exit $fail
