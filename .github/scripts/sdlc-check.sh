#!/usr/bin/env bash
# sdlc-check.sh — vérifie les conventions du SDLC sur une pull request.
#
# Lancé par .github/workflows/sdlc.yml (check requis « sdlc-conventions »).
# Remplace le hook serveur : le ruleset de main exige ce check avant toute fusion.
#
# Entrées (variables d’environnement) : BASE_SHA, HEAD_SHA, HEAD_REF
# Facultatif : SDLC_INTENT_DIR (intent)
#
# Règles :
#   need/<id>/intent  ne modifie que intent/<id>/intent.md (et intent/<id>/assets/)
#   need/<id>/spec    ne modifie que intent/<id>/spec.md (et assets) ; intent.md déjà sur main
#   need/<id>/build   contient intent/<id>/plan.md ; ne modifie ni intent.md ni spec.md ;
#                     spec.md déjà sur main ; ne touche aucun autre besoin
#   chaque commit (hors merges) porte Need: <id>
#   autre branche     ne touche pas intent/<id>/ (trailers non exigés)
#
# Testable en local :
#   BASE_SHA=$(git rev-parse main) HEAD_SHA=$(git rev-parse HEAD) \
#   HEAD_REF=$(git branch --show-current) bash .github/scripts/sdlc-check.sh
set -euo pipefail

: "${BASE_SHA:?BASE_SHA manquant}" "${HEAD_SHA:?HEAD_SHA manquant}" "${HEAD_REF:?HEAD_REF manquant}"
IDIR=${SDLC_INTENT_DIR:-intent}

errors=0
err() { printf '::error::%s\n' "$*"; errors=$((errors + 1)); }
ok()  { printf '✓ %s\n' "$*"; }

base=$(git merge-base "$BASE_SHA" "$HEAD_SHA")
files=$(git diff --name-only "$base" "$HEAD_SHA")

# Un seul git log : hash court et valeur de Need: de chaque commit (hors merges).
check_commits() {
  local expected=$1 c need n=0
  while IFS=$'\t' read -r c need; do
    [ -n "$c" ] || continue
    n=$((n + 1))
    if [ -z "$need" ]; then
      err "commit $c : trailer Need: manquant"
    elif [ "$need" != "$expected" ]; then
      err "commit $c : Need: « $need » au lieu de « $expected »"
    fi
  done < <(git log --no-merges --format='%h%x09%(trailers:key=Need,valueonly,separator=%x2C)' "$base..$HEAD_SHA")
  [ "$errors" -gt 0 ] || ok "trailers Need: présents sur $n commit(s)"
}

if [[ $HEAD_REF =~ ^need/([^/]+)/(intent|spec|build)$ ]]; then
  id=${BASH_REMATCH[1]}
  step=${BASH_REMATCH[2]}
  dir="$IDIR/$id"
  echo "Besoin $id · étape $step"
  check_commits "$id"

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case $step in
      intent|spec)
        case $f in "$dir/$step.md"|"$dir/assets/"*) ;; *) err "PR $step : $f hors périmètre (seul $dir/$step.md)" ;; esac ;;
      build)
        case $f in
          "$dir/intent.md"|"$dir/spec.md") err "PR build : $f ne change que par une PR intent/spec (fusion par le PO)" ;;
          "$IDIR/_template/"*|"$dir/"*) ;;
          "$IDIR/"*) err "PR build : $f appartient à un autre besoin" ;;
        esac ;;
    esac
  done <<<"$files"

  case $step in
    intent)
      git cat-file -e "$HEAD_SHA:$dir/intent.md" 2>/dev/null || err "$dir/intent.md absent" ;;
    spec)
      git cat-file -e "$BASE_SHA:$dir/intent.md" 2>/dev/null || err "intent.md pas encore fusionné : la spec attend l’intent accepté"
      git cat-file -e "$HEAD_SHA:$dir/spec.md" 2>/dev/null   || err "$dir/spec.md absent" ;;
    build)
      git cat-file -e "$BASE_SHA:$dir/spec.md" 2>/dev/null   || err "spec.md pas encore fusionnée : le build attend la spec acceptée"
      git cat-file -e "$HEAD_SHA:$dir/plan.md" 2>/dev/null   || err "$dir/plan.md absent : produisez le plan (plan mode) avant le code" ;;
  esac
elif [[ $HEAD_REF == need/* ]]; then
  err "branche $HEAD_REF : nom attendu need/<id>/intent, need/<id>/spec ou need/<id>/build"
else
  echo "Branche hors besoin : $HEAD_REF"
  while IFS= read -r f; do
    case $f in
      "$IDIR/_template/"*) ;;
      "$IDIR/"*) err "$f : un artefact de besoin ne change que sur une branche need/<id>/…" ;;
    esac
  done <<<"$files"
fi

if [ "$errors" -gt 0 ]; then
  printf '\n%d règle(s) du SDLC non respectée(s).\n' "$errors"
  exit 1
fi
ok "conventions du SDLC respectées"
