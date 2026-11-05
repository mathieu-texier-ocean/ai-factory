#!/usr/bin/env bash
# Teste git sdlc metrics dans des dépôts git temporaires, avec un gh factice (fixtures/gh)
# qui sert des réponses JSON écrites par chaque cas. jq requis.
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
sdlc="$repo_root/bin/git-sdlc"
command -v jq >/dev/null 2>&1 || { echo "FAIL jq introuvable : requis par le gh factice"; exit 1; }
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 TZ=UTC
export PATH="$here/fixtures:$PATH"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

fail=0
out="" err="" rc=0

# depot <nom> : nouveau dépôt avec un commit initial sur main ; y entre ; GH_DATA et GH_LOG propres.
depot() {
  mkdir -p "$tmp/$1/gh" && cd "$tmp/$1" && git init -q -b main repo && cd repo
  git config user.email t@t && git config user.name t
  export GH_DATA="$tmp/$1/gh" GH_LOG="$tmp/$1/gh.log"
  : > "$GH_LOG"
  commit_le 2026-01-01T00:00:00Z init
}
# commit_le <date ISO> <message> [<need> <stage>] : commite l'index (vide permis) à cette date
# d'auteur et de committer, avec les trailers Need: et Stage: s'ils sont donnés.
commit_le() {
  local msg=$2
  [ $# -lt 4 ] || msg=$(printf '%s\n\nNeed: %s\nStage: %s' "$2" "$3" "$4")
  GIT_AUTHOR_DATE=$1 GIT_COMMITTER_DATE=$1 git commit -q --allow-empty -m "$msg"
}
# lance <args…> : git sdlc dans le dépôt courant ; remplit out, err et rc.
lance() {
  out=$(bash "$sdlc" "$@" 2>"$tmp/err"); rc=$?
  err=$(cat "$tmp/err")
}
ok()   { echo "PASS $1"; }
ko()   { echo "FAIL $1"; printf '  rc=%s\n  stdout: %s\n  stderr: %s\n' "$rc" "$out" "$err"; fail=1; }
# verifie <nom> <condition…> : PASS si la commande shell réussit.
verifie() { local n=$1; shift; if "$@"; then ok "$n"; else ko "$n"; fi; }
contient() { printf '%s' "$1" | grep -qF -- "$2"; }

# ---------------------------------------------------------------- étape 1

depot vide
lance metrics --no-fetch
verifie "L11 aucun besoin : message et code 0" \
  eval '[ $rc -eq 0 ] && [ "$out" = "Aucun besoin sur la période." ]'

lance metrics --since 15/10/2026 --no-fetch
verifie "A7 --since mal formé : code 1, message, stdout vide" \
  eval '[ $rc -eq 1 ] && [ -z "$out" ] && [ "$err" = "git-sdlc : date invalide pour --since : 15/10/2026 (AAAA-MM-JJ)" ]'

lance metrics --since 2026-02-30 --no-fetch
verifie "L12 date inexistante refusée" eval '[ $rc -eq 1 ] && [ -z "$out" ] && contient "$err" "date invalide"'

lance metrics --since 2024-02-29 --no-fetch
verifie "L12 29 février d'une année bissextile accepté" eval '[ $rc -eq 0 ]'

lance metrics --bavard --no-fetch
verifie "option inconnue : code 1" eval '[ $rc -eq 1 ] && contient "$err" "option inconnue : --bavard"'

GH_FAIL=1 lance metrics --no-fetch
verifie "L14 gh non authentifié : code 1" eval '[ $rc -eq 1 ] && [ -z "$out" ] && contient "$err" "lecture des pull requests impossible"'

git remote add origin "$tmp/absent.git"
lance metrics
verifie "L13 fetch en échec : avertissement, calcul local" \
  eval '[ $rc -eq 0 ] && contient "$err" "fetch de origin impossible" && [ "$out" = "Aucun besoin sur la période." ]'
git remote remove origin

depot besoins
cat > "$GH_DATA/prs.json" <<'JSON'
[ {"number": 1, "headRefName": "need/b-pr/intent", "state": "OPEN", "createdAt": "2026-02-01T10:00:00Z",
   "mergedAt": null, "mergeCommit": null, "labels": [], "author": {"login": "jade"}},
  {"number": 2, "headRefName": "fix/hors-sdlc", "state": "MERGED", "createdAt": "2026-02-01T10:00:00Z",
   "mergedAt": "2026-02-02T10:00:00Z", "mergeCommit": {"oid": "abc"}, "labels": [], "author": {"login": "jade"}} ]
JSON
git branch need/b-branche/intent
mkdir -p requirements/b-dossier && echo "# Intent" > requirements/b-dossier/intent.md && git add -A
commit_le 2026-02-03T10:00:00Z "intent" b-dossier plan
git tag rejected/b-tag
lance metrics --porcelain --no-fetch
verifie "C2 besoins : PR, branche, dossier et tag rejected ; PR hors need/* ignorée" \
  eval '[ $rc -eq 0 ] && [ "$(printf "%s\n" "$out" | cut -f1,2 | tr "\t\n" ": ")" = "need:b-branche need:b-dossier need:b-pr need:b-tag " ]'

git config sdlc.prLimit 2
lance metrics --porcelain --no-fetch
verifie "L5 prLimit atteint : avertissement, code 0" eval '[ $rc -eq 0 ] && contient "$err" "2 PR lues, autant que prLimit"'
git config --unset sdlc.prLimit

before=$(git status --porcelain; git for-each-ref)
: > "$GH_LOG"
lance metrics --no-fetch
after=$(git status --porcelain; git for-each-ref)
verifie "A10 lecture seule : gh en lecture, état git inchangé" \
  eval '[ $rc -eq 0 ] && [ "$before" = "$after" ] && ! grep -qvE "^(pr list|release list|api graphql) " "$GH_LOG" && ! grep -qi mutation "$GH_LOG"'

exit $fail
