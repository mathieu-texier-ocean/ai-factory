#!/usr/bin/env bash
# Teste scripts/deploy.sh contre un faux clone du kit, dans un dossier temporaire.
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
tmp=$(mktemp -d); trap 'chmod -R u+rwx "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
if command -v sha256sum >/dev/null 2>&1; then sha() { sha256sum "$@"; }; else sha() { shasum -a 256 "$@"; }; fi

fail=0
ok() { echo "PASS $1"; }
ko() { echo "FAIL $1${2:+ : $2}"; fail=1; }
# verif <nom> <commande…> : PASS si la commande réussit.
verif() { local n=$1; shift; if "$@"; then ok "$n"; else ko "$n"; fi; }
ecrire() { mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" > "$1"; }
manif() { grep -F "  $2" "$1/.sdlc/manifeste" | cut -d' ' -f1; }

# Faux clone du kit : la liste blanche, des tests et des fichiers propres au kit.
K=$tmp/kit
mkdir -p "$K" && cd "$K" && git init -q . && git config user.email t@t && git config user.name t
ecrire bin/git-sdlc 'echo sdlc'; chmod +x bin/git-sdlc
ecrire .claude/settings.json '{}'
ecrire .claude/skills/demo/SKILL.md 'skill v1'
ecrire .claude/skills/autre/SKILL.md 'autre v1'
ecrire .claude/hooks/tests/h/run.sh 'exit 0'
ecrire .githooks/pre-commit 'exit 0'; chmod +x .githooks/pre-commit
ecrire .githooks/lib/a.sh 'a v1'
ecrire .githooks/lib/b.sh 'b v1'
ecrire .github/workflows/sdlc.yml 'on: pull_request'
ecrire .sdlc/config '[sdlc]'
ecrire templates/intent.md 'gabarit'
ecrire templates/projet/CLAUDE.md '# {{nom-projet}}
modèle v1'
ecrire templates/projet/README.md '# {{nom-projet}}
readme modèle v1'
ecrire REVIEW.md 'revue'
ecrire README.md 'readme du kit'
ecrire scripts/verify.sh 'exit 0'
mkdir -p scripts && cp "$repo_root/scripts/deploy.sh" scripts/ && chmod +x scripts/deploy.sh
git add -A && git commit -qm base
BASE=$(git rev-parse HEAD)
D=$K/scripts/deploy.sh

# kit_commit <message> : commite l'état courant du faux clone.
kit_commit() { git -C "$K" add -A && git -C "$K" commit -qm "$1"; }
# scenario <nom> : faux clone remis à la base, nouveau dépôt produit $P installé.
scenario() {
  git -C "$K" reset -q --hard "$BASE"; git -C "$K" clean -qfdx
  P=$tmp/p-$1; "$D" install "$P" demo > /dev/null 2>&1 || ko "$1 : install préalable"
}

# --- install dans un dossier absent ---
out=$("$D" install "$tmp/neuf" demo 2>&1); rc=$?
P=$tmp/neuf
verif "install : code 0" [ $rc -eq 0 ]
verif "install : liste blanche copiée" [ -f "$P/.claude/skills/demo/SKILL.md" -a -f "$P/.githooks/lib/a.sh" -a -f "$P/.github/workflows/sdlc.yml" -a -f "$P/.sdlc/config" -a -f "$P/templates/intent.md" -a -f "$P/REVIEW.md" ]
verif "install : bin, scripts du kit non copiés" [ ! -e "$P/bin" -a ! -e "$P/scripts" ]
verif "install : README.md produit depuis le modèle, pas celui du kit" [ "$(cat "$P/README.md")" = "$(printf '# demo\nreadme modèle v1')" ]
verif "install : tests et templates/projet exclus" [ ! -e "$P/.claude/hooks/tests" -a ! -e "$P/templates/projet" ]
verif "install : bit exécutable repris" [ -x "$P/.githooks/pre-commit" -a ! -x "$P/REVIEW.md" ]
verif "install : CLAUDE.md produit avec le nom" [ "$(head -1 "$P/CLAUDE.md")" = "# demo" ]
verif "install : manifeste, SHA et nom" [ "$(sed -n 1,2p "$P/.sdlc/manifeste")" = "$(printf 'sdlc-kit %s\nprojet demo' "$BASE")" ]
verif "install : manifeste vérifiable par sha256" sh -c "cd '$P' && tail -n +3 .sdlc/manifeste | $(command -v sha256sum >/dev/null && echo sha256sum || echo 'shasum -a 256') -c --status"
verif "install : manifeste trié, sans lui-même" sh -c "tail -n +3 '$P/.sdlc/manifeste' | cut -c67- > '$tmp/c'; LC_ALL=C sort -c '$tmp/c' && ! grep -qx .sdlc/manifeste '$tmp/c'"
verif "install : marche à suivre affichée, aucun .git" sh -c "printf '%s' \"\$1\" | grep -qF 'git config core.hooksPath .githooks' && [ ! -e '$P/.git' ]" _ "$out"
verif "install : git-sdlc copié depuis le clone avant setup" sh -c "printf '%s\n' \"\$1\" | awk -v c=\"cp \$2/bin/git-sdlc \" 'index(\$0, c) { cp = NR } /git sdlc setup/ { s = NR } END { exit !(cp && s && cp < s) }'" _ "$out" "$(git -C "$K" rev-parse --show-toplevel)"

"$D" install "$tmp/nom" 'a/b & c\d' > /dev/null 2>&1
verif "install : nom avec / & \\ injecté tel quel" [ "$(head -1 "$tmp/nom/CLAUDE.md")" = '# a/b & c\d' ]
"$D" install "$tmp/mon-projet" > /dev/null 2>&1
verif "install : nom par défaut = nom du dossier" [ "$(head -1 "$tmp/mon-projet/CLAUDE.md")" = "# mon-projet" ]

# --- install dans un dépôt existant ---
P=$tmp/existant
ecrire "$P/.claude/settings.json" '{"permissions":{}}'
ecrire "$P/CLAUDE.md" 'mon claude'
ecrire "$P/REVIEW.md" 'revue'
ecrire "$P/src/app.c" 'int main;'
out=$("$D" install "$P" demo 2>&1); rc=$?
verif "existant : code 0" [ $rc -eq 0 ]
verif "existant : fichiers du dépôt conservés" [ "$(cat "$P/.claude/settings.json")" = '{"permissions":{}}' -a "$(cat "$P/CLAUDE.md")" = 'mon claude' -a "$(cat "$P/src/app.c")" = 'int main;' ]
verif "existant : .nouveau écrits pour les collisions" [ "$(cat "$P/.claude/settings.json.nouveau")" = '{}' -a "$(head -1 "$P/CLAUDE.md.nouveau")" = '# demo' ]
verif "existant : contenu identique sans .nouveau" [ ! -e "$P/REVIEW.md.nouveau" ]
verif "existant : collisions au manifeste avec l'empreinte du kit" [ "$(manif "$P" .claude/settings.json)" = "$(printf '{}\n' | sha | cut -d' ' -f1)" ]
verif "existant : src hors manifeste" sh -c "! grep -qF src/ '$P/.sdlc/manifeste'"
verif "existant : rapport des .nouveau" sh -c "printf '%s' \"\$1\" | grep -qF '  .claude/settings.json.nouveau'" _ "$out"

# --- refus de install ---
refuse() { # refuse <nom> <code attendu> <commande…>
  local n=$1 c=$2; shift 2
  "$@" > /dev/null 2>&1; local rc=$?
  if [ $rc -eq "$c" ]; then ok "$n"; else ko "$n" "code $rc"; fi
}
refuse "refus : déjà installé" 1 "$D" install "$tmp/neuf" demo
ecrire "$tmp/fichier" x
refuse "refus : cible fichier ordinaire" 1 "$D" install "$tmp/fichier" demo
refuse "refus : cible dans le clone du kit" 1 "$D" install "$K/sous" demo
verif "refus : rien écrit dans le kit" [ ! -e "$K/sous" ]
refuse "refus : nom vide" 1 "$D" install "$tmp/vide" ''
verif "refus : nom vide, rien écrit" [ ! -e "$tmp/vide" ]
refuse "refus : commande inconnue, code 2" 2 "$D" deploie "$tmp/x"
refuse "refus : argument manquant" 1 "$D" install
if [ "$(id -u)" = 0 ]; then echo "SKIP refus : cible illisible (root)"; else
  mkdir "$tmp/ferme" && chmod 000 "$tmp/ferme"
  refuse "refus : cible illisible" 1 "$D" install "$tmp/ferme" demo
  chmod 755 "$tmp/ferme"
fi
mkdir -p "$tmp/pas-kit" && cp "$D" "$tmp/pas-kit/" && git -C "$tmp/pas-kit" init -q && git -C "$tmp/pas-kit" add -A && git -C "$tmp/pas-kit" -c user.email=t@t -c user.name=t commit -qm x
refuse "refus : source qui n'est pas le kit" 1 "$tmp/pas-kit/deploy.sh" install "$tmp/pk" demo
cp -r "$K" "$tmp/kit-produit" && ecrire "$tmp/kit-produit/.sdlc/manifeste" x && kit_commit_p() { git -C "$tmp/kit-produit" add -A && git -C "$tmp/kit-produit" commit -qm p; } && kit_commit_p
refuse "refus : source qui est un dépôt produit" 1 "$tmp/kit-produit/scripts/deploy.sh" install "$tmp/kp" demo

# --- non commité dans le kit ---
ecrire "$K/.claude/settings.local.json" '{}'
ecrire "$K/REVIEW.md" 'revue modifiée'
out=$("$D" install "$tmp/nc" demo 2>&1)
verif "fichier non suivi non copié" [ ! -e "$tmp/nc/.claude/settings.local.json" ]
verif "modification non commitée ignorée, signalée" sh -c "[ \"\$(cat '$tmp/nc/REVIEW.md')\" = revue ] && printf '%s' \"\$1\" | grep -qF 'non commitées'" _ "$out"

# --- update ---
scenario intact
ecrire "$K/.githooks/lib/a.sh" 'a v2'; kit_commit v2
out=$("$D" update "$P" 2>&1); rc=$?
verif "update : fichier intact remplacé" [ $rc -eq 0 -a "$(cat "$P/.githooks/lib/a.sh")" = 'a v2' ]
verif "update : manifeste au nouveau SHA et à la nouvelle empreinte" [ "$(head -1 "$P/.sdlc/manifeste")" = "sdlc-kit $(git -C "$K" rev-parse HEAD)" -a "$(manif "$P" .githooks/lib/a.sh)" = "$(printf 'a v2\n' | sha | cut -d' ' -f1)" ]
verif "update : rapport, SHA et catégorie" sh -c "printf '%s' \"\$1\" | grep -qF '$BASE -> ' && printf '%s' \"\$1\" | grep -qx 'Remplacés :'" _ "$out"

scenario claude
printf 'ma ligne\n' >> "$P/CLAUDE.md"; avant=$(cat "$P/CLAUDE.md")
ecrire "$K/templates/projet/CLAUDE.md" '# {{nom-projet}}
modèle v2'; kit_commit v2
"$D" update "$P" > /dev/null 2>&1
verif "update : CLAUDE.md complété conservé, .nouveau avec le nom" [ "$(cat "$P/CLAUDE.md")" = "$avant" -a "$(cat "$P/CLAUDE.md.nouveau")" = "$(printf '# demo\nmodèle v2')" ]

scenario supprime
rm -r "$P/.claude/skills/demo"
ecrire "$K/.claude/skills/demo/SKILL.md" 'skill v2'; kit_commit v2
out=$("$D" update "$P" 2>&1)
verif "update : supprimé localement non recréé, .nouveau" [ ! -e "$P/.claude/skills/demo/SKILL.md" -a -f "$P/.claude/skills/demo/SKILL.md.nouveau" ]
rm "$P/.claude/skills/demo/SKILL.md.nouveau"
ecrire "$K/README.md" 'autre'; kit_commit v3
"$D" update "$P" > /dev/null 2>&1
verif "update : pas de .nouveau à la 2e exécution" [ ! -e "$P/.claude/skills/demo/SKILL.md.nouveau" ]

scenario amont
ecrire "$P/.githooks/lib/b.sh" 'b local'
git -C "$K" rm -q .githooks/lib/a.sh .githooks/lib/b.sh; kit_commit suppr
"$D" update "$P" > /dev/null 2>&1
verif "update : supprimé en amont, intact supprimé" [ ! -e "$P/.githooks/lib/a.sh" ]
verif "update : supprimé en amont, modifié conservé hors manifeste" sh -c "[ \"\$(cat '$P/.githooks/lib/b.sh')\" = 'b local' ] && ! grep -qF .githooks/lib/b.sh '$P/.sdlc/manifeste'"

scenario collision
ecrire "$P/templates/x.md" 'du projet'
ecrire "$P/src/app.c" 'int main;'
ecrire "$K/templates/x.md" 'du kit'; kit_commit x
"$D" update "$P" > /dev/null 2>&1
verif "update : collision conservée, .nouveau, au manifeste" [ "$(cat "$P/templates/x.md")" = 'du projet' -a "$(cat "$P/templates/x.md.nouveau")" = 'du kit' -a -n "$(manif "$P" templates/x.md)" ]
verif "update : fichiers du dépôt intacts" [ "$(cat "$P/src/app.c")" = 'int main;' ]

scenario renomme
git -C "$K" mv .claude/skills/autre .claude/skills/renomme; kit_commit mv
"$D" update "$P" > /dev/null 2>&1
verif "update : renommage = suppression + ajout" [ ! -e "$P/.claude/skills/autre" -a -f "$P/.claude/skills/renomme/SKILL.md" ]

scenario egal
ecrire "$P/.githooks/lib/a.sh" 'a v2'
ecrire "$P/.githooks/lib/b.sh" 'b tmp'; ecrire "$P/.githooks/lib/b.sh" 'b v1'
ecrire "$P/.claude/settings.json.nouveau" 'ancien'
ecrire "$P/.claude/settings.json" 'local'
ecrire "$K/.githooks/lib/a.sh" 'a v2'; ecrire "$K/.githooks/lib/b.sh" 'b v2'; ecrire "$K/.claude/settings.json" '{"v":2}'; kit_commit v2
"$D" update "$P" > /dev/null 2>&1
verif "update : L = N, rien écrit, manifeste suit" [ ! -e "$P/.githooks/lib/a.sh.nouveau" -a "$(manif "$P" .githooks/lib/a.sh)" = "$(printf 'a v2\n' | sha | cut -d' ' -f1)" ]
verif "update : restauré à l'identique traité comme intact" [ "$(cat "$P/.githooks/lib/b.sh")" = 'b v2' ]
verif "update : .nouveau existant remplacé" [ "$(cat "$P/.claude/settings.json.nouveau")" = '{"v":2}' ]

scenario ajour
avant=$(cat "$P/.sdlc/manifeste")
out=$("$D" update "$P" 2>&1)
verif "update : déjà à jour, rien modifié" sh -c "printf '%s' \"\$1\" | grep -qF 'Déjà à jour' && [ \"\$(cat '$P/.sdlc/manifeste')\" = \"\$2\" ]" _ "$out" "$avant"

scenario ancien
ecrire "$K/REVIEW.md" 'revue v2'; kit_commit v2
"$D" update "$P" > /dev/null 2>&1
git -C "$K" reset -q --hard "$BASE"
refuse "update : kit plus ancien refusé" 1 "$D" update "$P"
verif "update : refus, rien écrit" [ "$(cat "$P/REVIEW.md")" = 'revue v2' ]
out=$("$D" update --forcer "$P" 2>&1)
verif "update : --forcer, avertissement et retour arrière" sh -c "printf '%s' \"\$1\" | grep -qF 'avertissement : --forcer' && [ \"\$(cat '$P/REVIEW.md')\" = revue ]" _ "$out"
sed "1s/.*/sdlc-kit $(printf '%040d' 0)/" "$P/.sdlc/manifeste" > "$tmp/m" && cp "$tmp/m" "$P/.sdlc/manifeste"
refuse "update : SHA inconnu refusé" 1 "$D" update "$P"

refuse "update : sans manifeste refusé" 1 "$D" update "$tmp/existant-pas"
scenario chemin
printf '%064d  ../dehors\n' 0 >> "$P/.sdlc/manifeste"
refuse "update : chemin hors du dépôt refusé" 1 "$D" update "$P"

scenario droits
ecrire "$P/.githooks/lib/b.sh" 'b local'
chmod +x "$K/.githooks/lib/a.sh" "$K/.githooks/lib/b.sh"; kit_commit x
out=$("$D" update "$P" 2>&1)
verif "update : bit exécutable aligné sur fichier intact" sh -c "[ -x '$P/.githooks/lib/a.sh' ] && printf '%s' \"\$1\" | grep -qx 'Droits alignés :'" _ "$out"
verif "update : fichier modifié, droits non touchés" [ ! -x "$P/.githooks/lib/b.sh" ]

# --- de bout en bout : le kit réel installé dans un dépôt, commit avec ses hooks ---
R=$tmp/reel
mkdir -p "$R" && cd "$repo_root" && git ls-files -z -- bin scripts .claude .github .githooks .sdlc templates REVIEW.md \
  | while IFS= read -r -d '' f; do [ -e "$f" ] && mkdir -p "$R/$(dirname "$f")" && cp -p "$f" "$R/$f"; done
mkdir -p "$R/templates/projet" "$R/scripts" && cp "$repo_root/templates/projet/CLAUDE.md" "$repo_root/templates/projet/README.md" "$R/templates/projet/" && cp -p "$repo_root/scripts/deploy.sh" "$R/scripts/"
cd "$R" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t -c core.hooksPath=/dev/null commit -qm kit
Q=$tmp/produit
mkdir -p "$Q" && git -C "$Q" init -q && ecrire "$Q/src/app.c" 'int main;'
"$R/scripts/deploy.sh" install "$Q" produit > /dev/null 2>&1
cd "$Q" && git config user.email t@t && git config user.name t && git config core.hooksPath .githooks
verif "bout en bout : commit accepté par les hooks du kit installé" sh -c 'git add -A && git commit -qm init && git log -1 --format=%B | grep -qx "Need: none"'
verif "bout en bout : CLAUDE.md et README.md produits, sans tests du kit" [ "$(head -1 "$Q/CLAUDE.md")" = "# produit" -a "$(head -1 "$Q/README.md")" = "# produit" -a -z "$(git -C "$Q" ls-files '*/tests/*')" ]
exit $fail
