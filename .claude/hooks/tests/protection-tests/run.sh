#!/usr/bin/env bash
# Teste le hook Claude Code de protection des tests (PreToolUse sur Edit, Write, Bash) dans un dépôt
# git temporaire, hors de Claude Code : entrée JSON simulée, décision « ask » ou aucune sortie.
set -u
here=$(cd "$(dirname "$0")" && pwd)
hook=$(cd "$here/../.." && pwd)/protection-tests.sh
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
depot=$(mkdir -p "$tmp/depot" && cd "$tmp/depot" && pwd -P)

cd "$depot" && git init -q -b main .
mkdir -p tests/x a/b/tests "$tmp/tests"; echo a > "$tmp/tests/hors.sh"
echo a > tests/x/existant.sh; echo a > a/b/tests/c.sh; echo a > src.sh
git add . && git -c user.name=t -c user.email=t@t commit -qm init
export CLAUDE_PROJECT_DIR=$depot

fail=0
branche() { git checkout -q -B "$1"; }
# lance <entrée> : remplit rc et out.
lance() { out=$(printf '%s' "$1" | "$hook" 2>&1); rc=$?; }
outil() { printf '{"tool_name":"%s","cwd":"%s","tool_input":{"file_path":"%s"}}' "$1" "$depot" "$2"; }
bash_json() { printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"%s","description":"%s"}}' "${3:-$depot}" "$1" "${2:-}"; }
verdict() { if [ "$2" -eq 0 ]; then echo "PASS $1"; else echo "FAIL $1 (rc=$rc) out=$out"; fail=1; fi; }

muet() { [ $rc -eq 0 ] && [ -z "$out" ]; }
demande() { [ $rc -eq 0 ] && printf '%s' "$out" | grep -qF '"permissionDecision":"ask"'; }
raison() {
  demande && printf '%s' "$out" | grep -qF 'bugfix/a' && printf '%s' "$out" | grep -qF 'tests/x/existant.sh' \
    && printf '%s' "$out" | grep -qF 'corriger le code, pas le test'
}

# cas <nom> <attendu> <entrée>
cas() { lance "$3"; $2; verdict "$1" $?; }

branche bugfix/a
cas "Edit d'un test existant : demande avec la raison (A1, C3, C6)" raison  "$(outil Edit "$depot/tests/x/existant.sh")"
cas "Write qui écrase un test : demande (L4, C3)"                  demande "$(outil Write "$depot/tests/x/existant.sh")"
cas "Write d'un nouveau test : rien (A3, C4, L3)"                  muet    "$(outil Write "$depot/tests/x/nouveau.sh")"
cas "Edit hors tests/ : rien (A4, C7)"                             muet    "$(outil Edit "$depot/src.sh")"
cas "tests/ ailleurs dans le dépôt : demande (L8, C2)"             demande "$(outil Edit "$depot/a/b/tests/c.sh")"
cas "Edit d'un test hors du dépôt : rien (C2)"                     muet    "$(outil Edit "$tmp/tests/hors.sh")"
cas "rm : demande (A2, C5, L5)"                                    demande "$(bash_json 'rm -f tests/x/existant.sh')"
cas "mv : demande (L5)"                                            demande "$(bash_json 'mv tests/x/existant.sh /tmp/y')"
cas "sed -i : demande (L5)"                                        demande "$(bash_json 'sed -i s/a/b/ tests/x/existant.sh')"
cas "cp vers un test : demande (C5)"                               demande "$(bash_json 'cp src.sh tests/x/existant.sh')"
cas "redirection > : demande (C5)"                                 demande "$(bash_json 'echo b > tests/x/existant.sh')"
cas "tee -a : demande (C5)"                                        demande "$(bash_json 'echo b | tee -a tests/x/existant.sh')"
cas "glob sous tests/ : demande (C5)"                              demande "$(bash_json 'rm tests/x/*.sh')"
cas "création par Bash : rien (L10, P1)"                           muet    "$(bash_json 'cat > tests/x/nouveau.sh')"
cas "lecture par cat : rien (L9)"                                  muet    "$(bash_json 'cat tests/x/existant.sh')"
cas "lancement avec 2>/dev/null et >&2 : rien (L9, P2)"            muet    "$(bash_json 'bash tests/x/existant.sh 2>/dev/null >&2')"
cas "cp depuis un test : rien (L9)"                                muet    "$(bash_json 'cp tests/x/existant.sh /tmp/y')"
cas "cd puis chemin relatif : demande (L11)"                       demande "$(bash_json 'cd tests/x && rm existant.sh')"
cas "cwd sous tests/ : demande (L11)"                              demande "$(bash_json 'rm existant.sh' '' "$depot/tests/x")"
cas "cd .. hors de tests/ : rien (L11)"                            muet    "$(bash_json 'cd tests/x && cd ../.. && rm src.sh')"
cas "description qui cite tests/ : rien (C5)"                      muet    "$(bash_json 'ls' 'rm tests/x/existant.sh')"
cas "écriture hors tests/ : rien (C7)"                             muet    "$(bash_json 'echo b > src.sh')"

for b in feat/b fix/a hotfix/a; do
  branche "$b"
  cas "branche $b : rien (A5, C1, L1)" muet "$(outil Edit "$depot/tests/x/existant.sh")"
done
git checkout -q --detach
cas "HEAD détachée : rien (L2)" muet "$(outil Edit "$depot/tests/x/existant.sh")"

[ -z "$(git status --porcelain)" ] && [ -f tests/x/existant.sh ]
verdict "lecture seule : dépôt inchangé (C8)" $?
exit $fail
