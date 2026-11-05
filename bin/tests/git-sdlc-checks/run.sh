#!/usr/bin/env bash
# Teste le détail des checks rouges de bin/git-sdlc (status, merge) avec un faux gh
# qui rejoue les JSON de fixtures/, dans un dépôt git temporaire.
# Références fixtures/attendu-*.txt : sorties de la version d'avant ce détail ; pour les
# régénérer, GIT_SDLC=<ancienne version> ATTENDU_ECRIRE=1 bash run.sh.
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
SDLC=${GIT_SDLC:-$repo_root/bin/git-sdlc}
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
command -v jq >/dev/null 2>&1 || { echo "FAIL jq introuvable : requis par le faux gh"; exit 1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

fail=0
ok() { echo "PASS $1"; }
ko() { echo "FAIL $1${2:+ : $2}"; fail=1; }
# verif <nom> <commande…> : PASS si la commande réussit.
verif() { local n=$1; shift; if "$@"; then ok "$n"; else ko "$n"; fi; }
a_ligne() { printf '%s\n' "$1" | grep -qxF -- "$2"; }
sans_appel() { ! grep -qE '^(pr checks|api) ' "$GH_LOG"; }
sans_merge() { ! grep -q '^pr merge' "$GH_LOG"; }

# Faux gh : journalise ses arguments et rejoue fixtures/ en appliquant --jq.
mkdir -p "$tmp/bin"
cat > "$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GH_LOG"
jqp=. rc=0 prev=""
for a in "$@"; do [ "$prev" != --jq ] || jqp=$a; prev=$a; done
case "$1 $2" in
  "pr list")   f=$GH_FIX/prs-$GH_CAS.json ;;
  "pr checks") [ -z "${GH_CHECKS_KO:-}" ] || { echo "unknown flag: --json" >&2; exit 1; }  # gh trop ancien
               [ -z "${GH_CHECKS_403:-}" ] || { echo "GraphQL: Resource not accessible by personal access token (repository.pullRequest)" >&2; exit 1; }
               f=$GH_FIX/checks-${GH_CHECKS:-$GH_CAS}.json; rc=1 ;;  # gh sort en 1 quand des checks échouent
  "api "*)     p=${2#repos/\{owner\}/\{repo\}/check-runs/}; p=${p%%\?*}; f=$GH_FIX/run-${p//\//-}.json ;;
  *) echo "faux gh : appel non prévu : $*" >&2; exit 3 ;;
esac
[ -f "$f" ] || { echo "HTTP 404: Not Found" >&2; exit 1; }
jq -r "$jqp" "$f" || exit 2
exit $rc
EOF
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH" GH_FIX=$here/fixtures GH_LOG=$tmp/gh.log GH_CAS=""

# Dépôt : intent et spec sur main, branche need/x-1/build poussée.
git init -q --bare -b main "$tmp/origin.git"
R=$tmp/depot
git init -q -b main "$R" && cd "$R" && git config user.email t@t && git config user.name t
mkdir -p requirements/x-1
printf '# Intent : x-1\n\nProduct-Owner: PO <po@example.com>\nParent: —\n' > requirements/x-1/intent.md
printf '# Spec : x-1\n' > requirements/x-1/spec.md
git add -A && git commit -qm base && git remote add origin "$tmp/origin.git" && git push -q origin main
git switch -q -c need/x-1/build && printf '# Plan : x-1\n' > requirements/x-1/plan.md
git add -A && git commit -qm plan && git push -q origin need/x-1/build && git switch -q main

# sdlc <cas> <arguments…> : lance git-sdlc ; sortie dans $OUT, erreurs dans $ERR, code dans $RC.
sdlc() {
  GH_CAS=$1; shift; : > "$GH_LOG"
  OUT=$("$SDLC" "$@" 2> "$tmp/err"); RC=$?
  ERR=$(cat "$tmp/err")
}
# reference <nom> : $OUT égale fixtures/attendu-<nom>.txt (ATTENDU_ECRIRE=1 : l'écrit d'abord).
reference() {
  [ -z "${ATTENDU_ECRIRE:-}" ] || printf '%s\n' "$OUT" > "$here/fixtures/attendu-$1.txt"
  [ "$OUT" = "$(cat "$here/fixtures/attendu-$1.txt" 2>/dev/null)" ]
}

# --- status, checks rouges (A1, A2, A6–A9, L1–L6, L9) ---
sdlc rouges status x-1
verif "status rouges : code 0" [ "$RC" -eq 0 ]
verif "status rouges : détail juste sous « checks rouges » (C1)" \
  [ "$(printf '%s\n' "$OUT" | grep -A1 -xF '  checks       rouges' | tail -n1)" = "    sdlc-conventions  FAILURE  Trailer Need absent sur 1 commit  https://github.com/o/r/actions/runs/1/job/101" ]
verif "check Actions : raison = 1re annotation failure du log, pas la plus récente (A1, A9, L9)" \
  a_ligne "$OUT" "    sdlc-conventions  FAILURE  Trailer Need absent sur 1 commit  https://github.com/o/r/actions/runs/1/job/101"
verif "check run avec titre : raison = titre (A6)" \
  a_ligne "$OUT" "    tests  FAILURE  3 tests en échec  https://github.com/o/r/runs/102"
verif "statut de commit : description sur une ligne (A7, L5)" \
  a_ligne "$OUT" "    ci/ext  ERROR  Build cassé  https://ci.example/9"
verif "check sans lien ni raison : nom et conclusion (L2, L4)" a_ligne "$OUT" "    annule  CANCELLED"
verif "raison illisible : ligne sans raison (A8, L6, C8)" \
  a_ligne "$OUT" "    injoignable  TIMED_OUT  https://github.com/o/r/actions/runs/1/job/104"
l=$(printf '%s\n' "$OUT" | sed -n 's/^    long  FAILURE  //p')
verif "raison longue : 120 caractères, terminée par …" \
  [ "$(printf '%s' "$l" | jq -R length)" = 120 -a "${l%…}" != "$l" ]
git config sdlc.checkReasonMax 20
sdlc rouges status x-1
l=$(printf '%s\n' "$OUT" | sed -n 's/^    long  FAILURE  //p')
verif "checkReasonMax = 20 : raison coupée à 20 caractères" [ "$(printf '%s' "$l" | jq -R length)" = 20 ]
git config sdlc.checkReasonMax 0
sdlc rouges status x-1
l=$(printf '%s\n' "$OUT" | sed -n 's/^    long  FAILURE  //p')
verif "checkReasonMax = 0 : raison entière" [ "$(printf '%s' "$l" | jq -R length)" = 200 ]
git config sdlc.checkReasonMax abc
sdlc verts status x-1
verif "checkReasonMax invalide sans check rouge : rien signalé" [ -z "$ERR" ]
sdlc rouges status x-1
l=$(printf '%s\n' "$OUT" | sed -n 's/^    long  FAILURE  //p')
verif "checkReasonMax invalide : 120 retenu et signalé" \
  [ "$(printf '%s' "$l" | jq -R length)" = 120 -a "$(printf '%s\n' "$ERR" | grep -c 'checkReasonMax invalide')" = 1 ]
git config --unset sdlc.checkReasonMax
sdlc rouges status x-1
verif "checks verts et en cours non détaillés (L1)" \
  [ "$(printf '%s\n' "$OUT" | grep -cE '^    (lint|vert) ')" = 0 ]
verif "lien d'un CI externe : pas d'appel à l'API des check runs (L3)" \
  [ "$(a_ligne "$OUT" "    ext  FAILURE  https://ci.example/runs/102" && echo o)$(grep -c '^api .*/102$' "$GH_LOG")" = o0 ]
verif "raison : caractère de contrôle retiré, antislash intact" a_ligne "$OUT" "    echap  FAILURE  a [31mb C:\build"
verif "une ligne par check rouge (A2)" [ "$(printf '%s\n' "$OUT" | grep -c '^    [^ ]')" = 8 ]
verif "status rouges : rien sur la sortie d'erreur" [ -z "$ERR" ]

# --- PR en brouillon : le détail s'affiche aussi (L7) ---
export GH_CHECKS=rouges
sdlc brouillon status x-1
verif "PR en brouillon : détail affiché (L7)" \
  a_ligne "$OUT" "    sdlc-conventions  FAILURE  Trailer Need absent sur 1 commit  https://github.com/o/r/actions/runs/1/job/101"
unset GH_CHECKS

# --- gh sans pr checks --json : signalé, status se termine normalement ---
export GH_CHECKS_KO=1
sdlc rouges status x-1
verif "gh trop ancien : code 0" [ "$RC" -eq 0 ]
verif "gh trop ancien : « checks rouges » affiché" a_ligne "$OUT" "  checks       rouges"
verif "gh trop ancien : signalé sur la sortie d'erreur" \
  a_ligne "$ERR" "git-sdlc : PR #7 : détail des checks rouges illisible (gh pr checks --json : gh à mettre à jour)"
unset GH_CHECKS_KO

# --- autre erreur de gh : son message, pas « gh à mettre à jour » ---
export GH_CHECKS_403=1
sdlc rouges status x-1
verif "erreur gh : code 0" [ "$RC" -eq 0 ]
verif "erreur gh : première ligne de gh signalée" \
  a_ligne "$ERR" "git-sdlc : PR #7 : détail des checks rouges illisible (GraphQL: Resource not accessible by personal access token (repository.pullRequest))"
unset GH_CHECKS_403

# --- gh pr checks ne voit aucun check rouge : dit tel quel ---
export GH_CHECKS=vide
sdlc rouges status x-1
verif "aucun check rouge selon gh : signalé tel quel" \
  a_ligne "$ERR" "git-sdlc : PR #7 : aucun check rouge selon gh pr checks"
unset GH_CHECKS

# --- seule la dernière exécution d'un check compte (exécution annulée puis relancée) ---
sdlc relance status x-1
verif "relance : annulée puis réussie = verts" a_ligne "$OUT" "  checks       verts"
verif "relance : ni gh pr checks ni gh api" sans_appel
export GH_CHECKS=rouges
sdlc relance-rouge status x-1
verif "relance : réussie puis en échec = rouges" a_ligne "$OUT" "  checks       rouges"
unset GH_CHECKS

# --- sans check rouge : sortie inchangée, aucun appel de plus (A3, C5) ---
for cas in verts en-cours aucun; do
  sdlc "$cas" status x-1
  verif "status $cas : sortie identique à la référence (A3)" reference "status-$cas"
  verif "status $cas : ni gh pr checks ni gh api (C5)" sans_appel
done

# --- porcelain et board inchangés (A5, C6, L8) ---
sdlc rouges status x-1 --porcelain
verif "status --porcelain : sortie identique à la référence (A5)" reference porcelain-rouges
verif "status --porcelain : ni gh pr checks ni gh api" sans_appel
sdlc rouges board
# board passe par column, dont la sortie dépend de la locale : pas de référence figée.
verif "board : aucun détail de check (L8)" [ "$(printf '%s\n' "$OUT" | grep -c 'sdlc-conventions')" = 0 ]
verif "board : ni gh pr checks ni gh api (L8)" sans_appel

# --- merge refusé : même détail sur la sortie d'erreur (A4, C7) ---
sdlc rouges merge x-1 build
verif "merge rouges : code 1" [ "$RC" -eq 1 ]
verif "merge rouges : message actuel en tête" \
  [ "$(printf '%s\n' "$ERR" | head -n1)" = "git-sdlc : PR #7 : checks rouges" ]
verif "merge rouges : détail sur la sortie d'erreur (A4)" \
  a_ligne "$ERR" "  sdlc-conventions  FAILURE  Trailer Need absent sur 1 commit  https://github.com/o/r/actions/runs/1/job/101"
verif "merge rouges : gh pr merge jamais appelé" sans_merge

exit $fail
