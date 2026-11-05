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
# ligne <type> <clé> [<clé 2>] : ligne --porcelain de $out dont les champs 1, 2 (et 3) valent ces clés.
ligne() { printf '%s\n' "$out" | awk -F'\t' -v t="$1" -v k="$2" -v s="${3:-}" '$1 == t && $2 == k && (s == "" || $3 == s)'; }
# fusion <date d'auteur> <date de fusion> <id> <stage> <fichier> : commit sur main, comme une
# fusion par rebase (date de committer = fusion), qui touche requirements/<id>/<fichier>.
fusion() {
  mkdir -p "requirements/$3" && echo "$1" >> "requirements/$3/$5" && git add -A
  GIT_AUTHOR_DATE=$1 GIT_COMMITTER_DATE=$2 git commit -q -m "$5" -m "$(printf 'Need: %s\nStage: %s' "$3" "$4")"
}
# besoin <id> <début> <fusion intent> [<début spec> <fusion spec> [<début plan> <fusion build>]]
besoin() {
  fusion "$2" "$3" "$1" plan intent.md
  [ $# -lt 5 ] || fusion "$4" "$5" "$1" design spec.md
  [ $# -lt 7 ] || fusion "$6" "$7" "$1" build plan.md
}


# Réponses GitHub à la forme réelle, écrites avec jq dans $GH_DATA.
# pr_gh <n> <branche> <création> <fusion> <auteur> : ajoute une PR fusionnée à prs.json.
pr_gh() {
  local f="$GH_DATA/prs.json"; [ -f "$f" ] || echo '[]' > "$f"
  jq --argjson n "$1" --arg b "$2" --arg c "$3" --arg m "$4" --arg a "$5" \
    '. + [{number: $n, headRefName: $b, state: "MERGED", createdAt: $c, mergedAt: $m,
           mergeCommit: {oid: "-"}, labels: [], author: {login: $a}}]' "$f" > "$f.t" && mv "$f.t" "$f"
}
# gql_pr <n> <création> [<ready for review>…] : nœud GraphQL de la PR, sans revue ni commit.
gql_pr() {
  local n=$1 c=$2; shift 2
  jq -n --argjson n "$n" --arg c "$c" --args '{number: $n, createdAt: $c,
    timelineItems: {nodes: [$ARGS.positional[] | {createdAt: .}]},
    reviews: {pageInfo: {hasNextPage: false, endCursor: null}, nodes: []},
    commits: {pageInfo: {hasNextPage: false, endCursor: null}, nodes: []}}' ${@+"$@"} > "$GH_DATA/pr-$n.json"
}
gql() { local f="$GH_DATA/pr-$1.json"; shift; jq "$@" "$f" > "$f.t" && mv "$f.t" "$f"; }
gql_revue()  { gql "$1" --arg t "$2" --arg a "$3" '.reviews.nodes += [{author: {login: $a}, submittedAt: $t}]'; }
gql_commit() { gql "$1" --arg t "$2" '.commits.nodes += [{commit: {oid: ("o" + $t), committedDate: $t,
  checkSuites: {pageInfo: {hasNextPage: false, endCursor: null}, nodes: []}}}]'; }
# gql_run <n> <démarrage> <conclusion> : run sdlc-conventions sur le dernier commit de la PR.
gql_run() { gql "$1" --arg t "$2" --arg c "$3" '.commits.nodes[-1].commit.checkSuites.nodes += [{checkRuns: {nodes: [{startedAt: $t, conclusion: $c}]}}]'; }

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
  eval '[ $rc -eq 0 ] && [ "$(printf "%s\n" "$out" | grep "^need" | cut -f1,2 | tr "\t\n" ": ")" = "need:b-branche need:b-dossier need:b-pr need:b-tag " ]'

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


# ---------------------------------------------------------------- étape 2

depot mediane
besoin m1 2026-03-01T10:00:00Z 2026-03-01T12:00:00Z
besoin m2 2026-03-02T10:00:00Z 2026-03-02T14:00:00Z
besoin m3 2026-03-03T10:00:00Z 2026-03-04T16:00:00Z
lance metrics --porcelain --no-fetch
verifie "A3 médiane impaire : 2 h, 4 h (même jour), 30 h → 4.0, n=3" \
  eval '[ "$(ligne agg delai_intent)" = "$(printf "agg\tdelai_intent\t—\t4.0\t3")" ] && [ "$(ligne need m2 | cut -f4)" = 4.0 ]'
besoin m4 2026-03-05T10:00:00Z 2026-03-05T20:00:00Z
lance metrics --porcelain --no-fetch
verifie "A3 médiane paire : + 10 h → 7.0, n=4" eval '[ "$(ligne agg delai_intent | cut -f4,5)" = "$(printf "7.0\t4")" ]'

depot incomplets
git switch -q -c need/en-cours/intent
mkdir -p requirements/en-cours && echo x > requirements/en-cours/intent.md && git add -A
commit_le 2026-04-01T10:00:00Z intent en-cours plan
git switch -q main
cat > "$GH_DATA/prs.json" <<'JSON'
[ {"number": 3, "headRefName": "need/rejete/intent", "state": "CLOSED", "createdAt": "2026-04-02T10:00:00Z",
   "mergedAt": null, "mergeCommit": null, "labels": [{"name": "sdlc:rejected"}], "author": {"login": "jade"}} ]
JSON
lance metrics --no-fetch
rc_lisible=$rc
lance metrics --porcelain --no-fetch
verifie "A4 besoin à l'étape intent : en cours, colonnes à —" \
  eval '[ $rc_lisible -eq 0 ] && [ "$(ligne need en-cours | cut -f3-)" = "$(printf "en cours\t—\t—\t—\t—\t—\t—\t—\t—")" ]'
verifie "A4 besoin rejeté par PR avant l'intent (L2) : rejeté, colonnes à —" \
  eval '[ "$(ligne need rejete | cut -f3-)" = "$(printf "rejeté\t—\t—\t—\t—\t—\t—\t—\t—")" ]'

depot rejet-tag
besoin accepte 2026-05-01T10:00:00Z 2026-05-01T12:00:00Z
git tag rejected/accepte
lance metrics --porcelain --no-fetch
verifie "A5 rejet par tag après l'intent (L3) : accepté, au numérateur de survie" \
  eval '[ "$(ligne need accepte | cut -f3)" = accepté ] && [ "$(ligne agg survie | cut -f4,5)" = "$(printf "1.00\t1")" ]'

depot fenetre
besoin ancien 2026-10-01T10:00:00Z 2026-10-01T12:00:00Z
besoin recent 2026-11-01T10:00:00Z 2026-11-01T12:00:00Z
lance metrics --since 2026-10-15 --porcelain --no-fetch
verifie "A6 --since : seul le besoin récent, n = 1" \
  eval '[ "$(ligne need ancien)" = "" ] && [ -n "$(ligne need recent)" ] && [ "$(ligne agg delai_intent | cut -f5)" = 1 ] && [ "$(ligne agg survie | cut -f5)" = 1 ]'

depot rejet-precoce
cat > "$GH_DATA/prs.json" <<'JSON'
[ {"number": 4, "headRefName": "need/precoce/intent", "state": "CLOSED", "createdAt": "2026-11-01T09:00:00Z",
   "mergedAt": null, "mergeCommit": null, "labels": [{"name": "sdlc:rejected"}], "author": {"login": "jade"}} ]
JSON
lance metrics --since 2026-10-15 --porcelain --no-fetch
verifie "A14 rejeté sans commit d'intent : retenu par la création de sa PR" \
  eval '[ "$(ligne need precoce | cut -f3)" = rejeté ] && [ "$(ligne agg survie | cut -f4,5)" = "$(printf "0.00\t1")" ]'
lance metrics --since 2026-11-02 --porcelain --no-fetch
verifie "A14 et écarté si sa PR est antérieure à --since" eval '[ -z "$(ligne need precoce)" ]'

depot refusion
besoin re 2026-06-01T10:00:00Z 2026-06-01T12:00:00Z 2026-06-02T10:00:00Z 2026-06-03T12:00:00Z
fusion 2026-06-05T10:00:00Z 2026-06-05T12:00:00Z re plan intent.md
lance metrics --porcelain --no-fetch
verifie "A19 étape refusionnée : C5 et C9 depuis la première fusion, C8 compte la retouche" \
  eval '[ "$(ligne need re | cut -f4-6)" = "$(printf "2.0\t1\t48.0")" ]'

depot delais
besoin d 2026-07-01T10:00:00Z 2026-07-01T12:00:00Z 2026-07-01T13:00:00Z 2026-07-02T12:00:00Z 2026-07-03T10:00:00Z 2026-07-06T12:00:00Z
fusion 2026-07-04T10:00:00Z 2026-07-06T12:00:00Z d build spec.md
lance metrics --porcelain --no-fetch
verifie "C9, C11 et retouches de la spec (C10)" \
  eval '[ "$(ligne need d | cut -f3-8)" = "$(printf "accepté\t2.0\t0\t24.0\t1\t96.0")" ]'
cat > "$GH_DATA/prs.json" <<'JSON'
[ {"number": 5, "headRefName": "need/d/build", "state": "MERGED", "createdAt": "2026-07-03T10:00:00Z",
   "mergedAt": "2026-07-06T11:00:00Z", "mergeCommit": {"oid": "0000000000000000000000000000000000000000"},
   "labels": [], "author": {"login": "dina"}} ]
JSON
lance metrics --porcelain --no-fetch
verifie "C4 mergedAt de la PR, plus ancien que le commit de fusion, retenu" eval '[ "$(ligne need d | cut -f8)" = 95.0 ]'


# ---------------------------------------------------------------- étape 3

# SDLC_NOW fige « aujourd'hui » au 2026-08-20 à 15:00 UTC.
export SDLC_NOW=1787238000

depot releases
lance metrics --porcelain --no-fetch
verifie "L10 aucun tag, sans --since : fréquence à —" \
  eval '[ "$(ligne agg releases_par_semaine | cut -f4,5)" = "$(printf "—\t0")" ]'
lance metrics --since 2026-08-01 --porcelain --no-fetch
verifie "L10 aucun tag, avec --since : fréquence à 0.0" \
  eval '[ "$(ligne agg releases_par_semaine | cut -f4,5)" = "$(printf "0.0\t0")" ]'
besoin r 2026-08-01T10:00:00Z 2026-08-01T12:00:00Z 2026-08-02T10:00:00Z 2026-08-02T12:00:00Z 2026-08-03T10:00:00Z 2026-08-04T12:00:00Z
GIT_COMMITTER_DATE=2026-08-20T08:00:00Z git tag -a 26.08.20 -m livraison
lance metrics --porcelain --no-fetch
verifie "A17 un tag du jour, sans --since : fenêtre d'un jour, 7.0 (L19)" \
  eval '[ $rc -eq 0 ] && [ "$(ligne agg releases_par_semaine | cut -f4,5)" = "$(printf "7.0\t1")" ]'
lance metrics --since 2026-08-21 --porcelain --no-fetch
verifie "A17 --since dans le futur : 0.0, n=0" \
  eval '[ $rc -eq 0 ] && [ "$(ligne agg releases_par_semaine | cut -f4,5)" = "$(printf "0.0\t0")" ]'
lance metrics --porcelain --no-fetch
verifie "C19 date du tag annoté, sans release GitHub" eval '[ "$(ligne need r | cut -f9)" = 380.0 ]'
lance metrics --since 2026-08-07 --porcelain --no-fetch
verifie "C20 fenêtre de 14 jours, un tag : 0.5" eval '[ "$(ligne agg releases_par_semaine | cut -f4,5)" = "$(printf "0.5\t1")" ]'
cat > "$GH_DATA/releases.json" <<'JSON'
[ {"tagName": "26.08.20", "publishedAt": "2026-08-20T10:00:00Z"} ]
JSON
lance metrics --porcelain --no-fetch
verifie "C19 date de publication GitHub prioritaire" eval '[ "$(ligne need r | cut -f9)" = 382.0 ] && [ "$(ligne agg delai_build_release | cut -f4,5)" = "$(printf "382.0\t1")" ]'

depot claude
lance metrics --porcelain --no-fetch
verifie "L15 sans CLAUDE.md : aucune ligne claude" eval '[ -z "$(printf "%s\n" "$out" | grep "^claude")" ]'
echo a > CLAUDE.md && git add CLAUDE.md && commit_le 2026-06-30T23:00:00Z "claude 1"
echo b >> CLAUDE.md && git add CLAUDE.md && commit_le 2026-07-01T01:00:00Z "claude 2"
echo c >> CLAUDE.md && git add CLAUDE.md && commit_le 2026-07-15T10:00:00Z "claude 3"
mkdir -p sous && echo x > sous/CLAUDE.md && git add sous && commit_le 2026-07-16T10:00:00Z "autre CLAUDE.md"
lance metrics --porcelain --no-fetch
verifie "C21 commits de CLAUDE.md à la racine, par mois" \
  eval '[ "$(printf "%s\n" "$out" | grep "^claude" | tr "\t\n" ":;")" = "claude:2026-06:1;claude:2026-07:2;" ]'
lance metrics --since 2026-07-02 --porcelain --no-fetch
verifie "C21 restreint à la fenêtre --since" eval '[ "$(printf "%s\n" "$out" | grep "^claude" | tr "\t\n" ":;")" = "claude:2026-07:1;" ]'
unset SDLC_NOW


# ---------------------------------------------------------------- étape 4

depot revues
besoin rv 2026-09-01T08:00:00Z 2026-09-01T09:00:00Z 2026-09-01T10:00:00Z 2026-09-02T10:00:00Z 2026-09-03T08:00:00Z 2026-09-03T18:00:00Z
pr_gh 11 need/rv/build 2026-09-03T08:00:00Z 2026-09-03T18:00:00Z dina
gql_pr 11 2026-09-03T08:00:00Z 2026-09-03T09:00:00Z 2026-09-03T10:00:00Z
gql_commit 11 2026-09-03T08:30:00Z
gql_commit 11 2026-09-03T11:00:00Z
gql_revue 11 2026-09-03T12:00:00Z lea
gql_commit 11 2026-09-03T13:00:00Z
gql_run 11 2026-09-03T13:01:00Z SUCCESS
lance metrics --porcelain --no-fetch
verifie "A11 deux commits après le brouillon, séparés par une revue : non, 2 cycles" \
  eval '[ "$(ligne pr rv build | cut -f5,6)" = "$(printf "non\t2")" ]'
verifie "L7 dernier « ready for review » retenu : C16 = 2.0, C17 = 8.0" \
  eval '[ "$(ligne pr rv build | cut -f8,9)" = "$(printf "2.0\t8.0")" ]'
verifie "C18 la ligne du besoin reprend la PR build" eval '[ "$(ligne need rv | cut -f10,11)" = "$(printf "non\t2")" ]'
verifie "A10 la requête GraphQL est une query" eval '! grep -qi mutation "$GH_LOG" && grep -q "^api graphql .*query=query" "$GH_LOG"'

depot ci
besoin ci 2026-09-01T08:00:00Z 2026-09-01T09:00:00Z
pr_gh 21 need/ci/intent 2026-09-01T08:00:00Z 2026-09-01T09:00:00Z jade
gql_pr 21 2026-09-01T08:00:00Z
gql_commit 21 2026-09-01T07:59:00Z
gql_run 21 2026-09-01T08:01:00Z FAILURE
gql_run 21 2026-09-01T08:05:00Z SUCCESS
pr_gh 22 need/ci/intent 2026-09-05T08:00:00Z 2026-09-05T09:00:00Z jade
gql_pr 22 2026-09-05T08:00:00Z
gql_commit 22 2026-09-05T07:59:00Z
gql_run 22 2026-09-05T08:01:00Z SUCCESS
pr_gh 23 need/ci/intent 2026-09-06T08:00:00Z 2026-09-06T09:00:00Z jade
gql_pr 23 2026-09-06T08:00:00Z
gql_commit 23 2026-09-06T07:59:00Z
gql_run 23 2026-09-06T08:01:00Z CANCELLED
gql_run 23 2026-09-06T08:02:00Z SUCCESS
pr_gh 24 need/ci/intent 2026-09-07T08:00:00Z 2026-09-07T09:00:00Z jade
gql_pr 24 2026-09-07T08:00:00Z
gql_commit 24 2026-09-07T07:59:00Z
lance metrics --porcelain --no-fetch
verifie "A12 premier run en échec puis en succès : non ; premier run en succès : oui" \
  eval '[ "$(ligne pr ci intent | cut -f4,7 | tr "\t\n" ":;")" = "21:non;22:oui;23:oui;24:—;" ]'
verifie "A15 run annulé ignoré (L17) ; L9 sans run : —, hors de la part" \
  eval '[ "$(ligne agg ci_premier_passage intent | cut -f4,5)" = "$(printf "0.67\t3")" ]'
verifie "A19 PR intent refusionnée : une ligne pr par PR ; L6 PR créée hors brouillon" \
  eval '[ "$(ligne pr ci intent | wc -l | tr -d " ")" = 4 ] && [ "$(ligne pr ci intent | sed -n 1p | cut -f5,9)" = "$(printf "oui\t1.0")" ]'

depot brouillon
besoin br 2026-09-01T08:00:00Z 2026-09-01T09:00:00Z 2026-09-01T10:00:00Z 2026-09-02T10:00:00Z 2026-09-03T08:00:00Z 2026-09-03T18:00:00Z
pr_gh 31 need/br/build 2026-09-03T08:00:00Z 2026-09-03T18:00:00Z dina
gql_pr 31 2026-09-03T08:00:00Z 2026-09-03T10:00:00Z
gql_revue 31 2026-09-03T09:00:00Z lea
gql_revue 31 2026-09-03T11:00:00Z lea
gql_commit 31 2026-09-03T12:00:00Z
gql_revue 31 2026-09-03T12:30:00Z dina
gql_commit 31 2026-09-03T13:00:00Z
lance metrics --porcelain --no-fetch
verifie "A16 revue du brouillon et réponses de l'auteur ignorées : C16 = 1.0, 1 cycle" \
  eval '[ "$(ligne pr br build | cut -f6,8)" = "$(printf "1\t1.0")" ]'

depot pagination
besoin pg 2026-09-01T08:00:00Z 2026-09-01T09:00:00Z 2026-09-01T10:00:00Z 2026-09-02T10:00:00Z 2026-09-03T08:00:00Z 2026-09-03T18:00:00Z
pr_gh 41 need/pg/build 2026-09-03T08:00:00Z 2026-09-03T18:00:00Z dina
gql_pr 41 2026-09-03T08:00:00Z
gql_commit 41 2026-09-03T07:00:00Z
gql 41 '.commits.pageInfo = {hasNextPage: true, endCursor: "C1"}'
cat > "$GH_DATA/after-C1.json" <<'JSON'
{"data": {"repository": {"c41": {"commits": {"pageInfo": {"hasNextPage": false, "endCursor": null}, "nodes": [
  {"commit": {"oid": "o2", "committedDate": "2026-09-03T12:00:00Z", "checkSuites": {
    "pageInfo": {"hasNextPage": true, "endCursor": "S1"},
    "nodes": [{"checkRuns": {"nodes": [{"startedAt": "2026-09-03T12:01:00Z", "conclusion": "CANCELLED"}]}}]}}}]}}}}}
JSON
cat > "$GH_DATA/after-S1.json" <<'JSON'
{"data": {"repository": {"s_41": {"oid": "o2", "checkSuites": {"pageInfo": {"hasNextPage": false, "endCursor": null},
  "nodes": [{"checkRuns": {"nodes": [{"startedAt": "2026-09-03T12:02:00Z", "conclusion": "FAILURE"}]}}]}}}}}
JSON
lance metrics --porcelain --no-fetch
verifie "L18 commits et suites au-delà de leur borne : complétés par pagination" \
  eval '[ "$(ligne pr pg build | cut -f5-7)" = "$(printf "non\t1\tnon")" ] && [ "$(grep -c "after: " "$GH_LOG")" = 2 ]'


# ---------------------------------------------------------------- étape 5

# Besoin livré : intent en 5 h, spec 3,5 j plus tard, build relu et retouché, release, CLAUDE.md.
utf8=$(locale -a 2>/dev/null | grep -iE '^(C|en_US)\.utf-?8$' | sed -n 1p)
export SDLC_NOW=1792152000   # 2026-10-16T12:00:00Z
depot livre
echo a > CLAUDE.md && git add CLAUDE.md && commit_le 2026-09-20T10:00:00Z "claude"
besoin liv 2026-10-01T09:00:00Z 2026-10-01T14:00:00Z 2026-10-01T15:00:00Z 2026-10-05T02:00:00Z 2026-10-05T03:00:00Z 2026-10-06T03:00:00Z
GIT_COMMITTER_DATE=2026-10-07T03:00:00Z git tag -a 26.10.07 -m livraison
pr_gh 1 need/liv/intent 2026-10-01T09:30:00Z 2026-10-01T14:00:00Z jade
gql_pr 1 2026-10-01T09:30:00Z
gql_commit 1 2026-10-01T09:00:00Z
gql_run 1 2026-10-01T09:31:00Z SUCCESS
gql_revue 1 2026-10-01T11:00:00Z paul
pr_gh 2 need/liv/spec 2026-10-01T15:00:00Z 2026-10-05T02:00:00Z jade
gql_pr 2 2026-10-01T15:00:00Z 2026-10-02T09:00:00Z
gql_commit 2 2026-10-01T15:00:00Z
gql_run 2 2026-10-02T09:01:00Z FAILURE
gql_commit 2 2026-10-02T10:00:00Z
gql_run 2 2026-10-02T10:01:00Z SUCCESS
gql_revue 2 2026-10-03T09:00:00Z paul
pr_gh 3 need/liv/build 2026-10-05T03:00:00Z 2026-10-06T03:00:00Z dina
gql_pr 3 2026-10-05T03:00:00Z 2026-10-05T05:00:00Z
gql_commit 3 2026-10-05T03:00:00Z
gql_run 3 2026-10-05T05:01:00Z SUCCESS
gql_revue 3 2026-10-05T06:00:00Z lea
gql_commit 3 2026-10-05T07:00:00Z
gql_revue 3 2026-10-05T09:00:00Z lea
lance metrics --porcelain --no-fetch
porcelain=$out
verifie "A2 valeurs égales à la sortie attendue" eval '[ "$porcelain" = "$(cat "$here/fixtures/livre.attendu")" ]'
lance metrics --porcelain --no-fetch
verifie "A8 deux appels successifs identiques" eval '[ "$out" = "$porcelain" ]'
verifie "A8 TSV sans en-tête ni alignement, colonnes du contrat" \
  eval '[ -z "$(printf "%s\n" "$out" | awk -F"\t" "
    (\$1 == \"need\" && NF != 11) || (\$1 == \"pr\" && NF != 9) || (\$1 == \"agg\" && NF != 5) ||
    (\$1 == \"claude\" && NF != 3) || \$1 !~ /^(need|pr|agg|claude)\$/ || /  /")" ]'
LC_ALL=$utf8 lance metrics --no-fetch
verifie "A1 sortie lisible : un tableau par niveau, chaque indicateur C5 à C21" eval '(
  for t in Besoins "PR fusionnées" Agrégats "INTENT → SPEC" "RETOUCHES SPEC" "BUILD → RELEASE" "1ER PASSAGE" \
           "CI 1ER PASSAGE" "1RE REVUE" "DURÉE REVUE" "Survie des intents" "Releases par semaine" \
           "Corrections de CLAUDE.md" 2026-09; do contient "$out" "$t" || exit 1; done )'
verifie "C23 durées en heures sous 48 h, en jours au-delà" \
  eval '[ "$(printf "%s\n" "$out" | awk "\$1 == \"liv\"" | head -1 | tr -s " ")" = "liv accepté 5 h 0 3,5 j 0 25 h 24 h non 1" ]'
unset SDLC_NOW

exit $fail
