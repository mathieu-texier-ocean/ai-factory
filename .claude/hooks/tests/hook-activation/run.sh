#!/usr/bin/env bash
# Teste les hooks Claude Code d'activation des hooks git (SessionStart, PreToolUse) dans un dépôt
# git temporaire, hors de Claude Code : entrée JSON simulée, code de sortie et message.
set -u
here=$(cd "$(dirname "$0")" && pwd)
scripts=$(cd "$here/../.." && pwd)
# Un core.hooksPath global ou système fausserait les cas « absent ».
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
depot=$tmp/depot

mkdir -p "$depot/hooks" "$depot/.claude/hooks" && cd "$depot" && git init -q .
cp "$scripts"/*.sh .claude/hooks/
export CLAUDE_PROJECT_DIR=$depot

fail=0
commande="git config core.hooksPath hooks"
# regle <valeur|-> : fixe core.hooksPath, ou le retire avec -.
regle() { if [ "$1" = - ]; then git config --unset core.hooksPath; else git config core.hooksPath "$1"; fi; }
# lance <script> <entrée> : remplit rc, out (stdout) et err (stderr).
lance() { out=$(printf '%s' "$2" | ".claude/hooks/$1" 2>"$tmp/err"); rc=$?; err=$(cat "$tmp/err"); }
bash_json() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"; }
verdict() { if [ "$2" -eq 0 ]; then echo "PASS $1"; else echo "FAIL $1 (rc=$rc) out=$out err=$err"; fail=1; fi; }

muet() { [ $rc -eq 0 ] && [ -z "$out" ] && [ -z "$err" ]; }
signale() {
  [ $rc -eq 0 ] && printf '%s' "$out" | grep -q '"systemMessage"' \
    && printf '%s' "$out" | grep -q '"additionalContext"' && printf '%s' "$out" | grep -qF "$commande"
}
bloque() { [ $rc -eq 2 ] && printf '%s' "$err" | grep -qF "ne sont pas actifs" && printf '%s' "$err" | grep -qF "$commande"; }

# session <nom> <valeur> <muet|signale>
session() { regle "$2"; lance session-hooks-git.sh '{"hook_event_name":"SessionStart"}'; $3; verdict "$1" $?; }
# commit <nom> <valeur> <commande bash> <muet|bloque>
commit() { regle "$2"; lance commit-hooks-git.sh "$(bash_json "$3")"; $4; verdict "$1" $?; }

session "session, absent : signalé (A1, C2, C4, L1)"    -              signale
session "session, actif : rien (A3, C3)"                hooks          muet
session "session, autre valeur : signalé (L2, C12)"     .git/hooks     signale
session "session, chemin absolu : rien (L8, C12)"       "$depot/hooks" muet
session "session, ./hooks : rien (C12)"                 ./hooks        muet

commit "commit, absent : refusé (A2, C6, L1)"           -     'git commit -m x'                      bloque
commit "commit, actif : passe (A3, C7)"                 hooks 'git commit -m x'                      muet
commit "commit enchaîné : refusé (L3)"                  -     'git add . && git commit -m x'         bloque
commit "--no-verify, actif : passe (L4)"                hooks 'git commit --no-verify -m x'          muet
commit "texte sans commit réel : refusé (L7)"           -     'grep -rn \"git commit\" .'            bloque
commit "autre commande : ignorée (C8)"                  -     'ls'                                   muet

regle -; lance commit-hooks-git.sh "$(bash_json 'git commit -m x')"; rc1=$rc
regle hooks; lance commit-hooks-git.sh "$(bash_json 'git commit -m x')"
[ $rc1 -eq 2 ] && muet; verdict "activation en cours de session : refusé puis passe (L5)" $?

regle -
lance session-hooks-git.sh '{}'; lance commit-hooks-git.sh "$(bash_json 'git commit -m x')"
! git config --get core.hooksPath >/dev/null; verdict "lecture seule : core.hooksPath toujours absent (C9)" $?
exit $fail
