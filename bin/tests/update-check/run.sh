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

# --- vérification et avis ---
# Copies de git-sdlc à une version donnée.
mkdir -p "$tmp/bin"
for v in 26.11.05 26.11.12 26.11.13; do
  mkdir -p "$tmp/bin/$v" && sed "s/^VERSION=dev\$/VERSION=$v/" "$sdlc" > "$tmp/bin/$v/git-sdlc"
done
vieux=$tmp/bin/26.11.05/git-sdlc neuf=$tmp/bin/26.11.12/git-sdlc
SHA_REL=$(printf '%040d' 12) SHA_VIEUX=$(printf '%040d' 5)
contient() { printf '%s' "$1" | grep -qF -- "$2"; }
lignes() { if [ -z "$1" ]; then echo 0; else printf '%s\n' "$1" | wc -l | tr -d ' '; fi; }
appels() { grep -c "$1" "$GH_LOG"; }

# depot <nom> : nouveau dépôt avec un commit sur main ; y entre ; gh factice remis à zéro.
depot() {
  mkdir -p "$tmp/$1" && cd "$tmp/$1" && git init -q -b main repo && cd repo
  git config user.email t@t && git config user.name t
  git commit -q --allow-empty -m init
  export GH_LOG="$tmp/$1/gh.log" GH_TAG=26.11.12 GH_SHA=$SHA_REL
  unset GH_FAIL GH_AUTH GH_404 GH_SLEEP
  : > "$GH_LOG"
}
# manifeste <sha> [<tag>] : kit installé dans le dépôt courant.
manifeste() {
  mkdir -p .sdlc
  { echo "sdlc-kit $1"; echo "projet demo"; [ -z "${2:-}" ] || echo "tag $2"
    printf '%064d  REVIEW.md\n' 0; } > .sdlc/manifeste
}
# temoin <script> <args…> : sortie standard et code d'une exécution sans vérification.
temoin() {
  T_RC=0
  git config sdlc.updateCheck false
  T_OUT=$(bash "$@" 2>/dev/null) || T_RC=$?
  git config --unset sdlc.updateCheck
}

depot a6
temoin "$vieux" status
lance "$vieux" status
verifie "git-sdlc en retard : une ligne d'avis" [ "$(lignes "$(printf '%s\n' "$err" | grep 'disponible')")" = 1 ]
verifie "git-sdlc en retard : version installée et disponible" contient "$err" "git-sdlc : git-sdlc 26.11.05 installé, 26.11.12 disponible : "
verifie "git-sdlc en retard : mise à jour manuelle citée" contient "$err" "gh release download 26.11.12 -R ocean-shiftmove/ai-factory -p git-sdlc -O $vieux --clobber && chmod +x $vieux"
verifie "git-sdlc en retard : code et sortie standard inchangés (die de status)" [ "$rc" = "$T_RC" -a "$out" = "$T_OUT" -a "$rc" = 1 ]
verifie "git-sdlc en retard : avis avant l'erreur de la commande" sh -c "printf '%s\n' \"\$1\" | head -1 | grep -qF disponible" _ "$err"
temoin "$vieux" board --porcelain
lance "$vieux" board --porcelain
verifie "board --porcelain : sortie standard et code inchangés, avis sur stderr" [ "$rc" = "$T_RC" -a "$out" = "$T_OUT" -a "$rc" = 0 ]
verifie "board --porcelain : avis présent" contient "$err" "26.11.12 disponible"

depot a7
manifeste "$SHA_REL" 26.11.12
lance "$neuf" board
verifie "à jour : aucun avis" [ "$rc" = 0 -a -z "$err" ]

depot a8
manifeste "$SHA_VIEUX" 26.11.05
lance "$neuf" board
verifie "kit en retard : une seule ligne d'avis" [ "$(lignes "$err")" = 1 ]
verifie "kit en retard : version, release et deploy.sh update" contient "$err" "git-sdlc : kit du dépôt 26.11.05 installé, 26.11.12 disponible : <clone du kit au tag 26.11.12>/scripts/deploy.sh update $(pwd -P)"

depot l3
manifeste "$SHA_VIEUX" 26.11.05
lance "$vieux" board
verifie "les deux en retard : deux lignes d'avis" [ "$(lignes "$err")" = 2 ]

depot l4
manifeste "$SHA_REL" 26.11.12
lance "$sdlc" board
verifie "git-sdlc dev, kit à jour : aucun avis" [ "$rc" = 0 -a -z "$err" ]
depot l4b
lance "$sdlc" board
verifie "git-sdlc dev sans manifeste : aucune requête de release" [ "$(appels releases)" = 0 -a -z "$err" ]

depot l5
lance "$neuf" board
verifie "sans manifeste : seul git-sdlc vérifié, à jour" [ "$(appels releases/latest)" = 1 -a -z "$err" ]

depot a13
manifeste "$SHA_REL"
lance "$neuf" board
verifie "manifeste sans tag au SHA de la release : aucun avis" [ -z "$err" ]
verifie "manifeste sans tag : SHA du tag demandé" [ "$(appels 'repos/ocean-shiftmove/ai-factory/commits/26.11.12')" = 1 ]

depot a14
manifeste "$SHA_VIEUX"
lance "$neuf" board
verifie "manifeste sans tag, SHA antérieur : avis nommant la release" contient "$err" "kit du dépôt ${SHA_VIEUX:0:12} installé, 26.11.12 disponible"

depot l8
manifeste "$SHA_VIEUX" 26.11.13
lance "$tmp/bin/26.11.13/git-sdlc" board
verifie "installé plus récent que la release : aucun avis" [ -z "$err" ]

depot l9
export GH_TAG=26.11.05.2
lance "$vieux" board
verifie "26.11.05 installé, 26.11.05.2 publié : avis" contient "$err" "26.11.05 installé, 26.11.05.2 disponible"
export GH_TAG=26.11.05.10
manifeste "$SHA_VIEUX" 26.11.05.2
lance "$tmp/bin/26.11.12/git-sdlc" board
verifie "26.11.05.2 installé, 26.11.05.10 publié : avis pour le kit seul" [ "$(lignes "$err")" = 1 ]
verifie "26.11.05.2 < 26.11.05.10 numériquement" contient "$err" "kit du dépôt 26.11.05.2 installé, 26.11.05.10 disponible"

depot a5
mkdir -p .sdlc && printf '[sdlc]\n\tkitRepo = autre/kit\n' > .sdlc/config
lance "$vieux" board
verifie "sdlc.kitRepo de .sdlc/config interrogé" [ "$(appels 'repos/autre/kit/releases/latest')" = 1 ]
verifie "sdlc.kitRepo cité dans l'avis" contient "$err" "-R autre/kit "
git config sdlc.kitRepo local/kit
lance "$vieux" board
verifie "sdlc.kitRepo : git config l'emporte sur .sdlc/config" [ "$(appels 'repos/local/kit/releases/latest')" = 1 ]
git config --unset sdlc.kitRepo; rm .sdlc/config
lance "$vieux" board
verifie "sans sdlc.kitRepo : ocean-shiftmove/ai-factory" [ "$(appels 'repos/ocean-shiftmove/ai-factory/releases/latest')" = 1 ]

depot a10
export GH_FAIL=1
temoin "$vieux" status
lance "$vieux" status
verifie "GitHub injoignable : avis vérification impossible" contient "$err" "git-sdlc : vérification des mises à jour impossible (GitHub injoignable"
verifie "GitHub injoignable : code et sortie standard inchangés" [ "$rc" = "$T_RC" -a "$out" = "$T_OUT" ]
lance "$vieux" board --porcelain
verifie "GitHub injoignable : la commande s'exécute (board, code 0)" [ "$rc" = 0 -a "$out" = "Aucun besoin en cours." ]

depot a11
export GH_404=1
lance "$vieux" board
verifie "dépôt du kit introuvable : avis vérification impossible" contient "$err" "vérification des mises à jour impossible (ocean-shiftmove/ai-factory ou sa dernière release introuvable)"
verifie "dépôt du kit introuvable : corps d'erreur de gh non affiché, code 0" [ "$rc" = 0 -a "$(lignes "$err")" = 1 ]

depot auth
export GH_AUTH=1
lance "$vieux" board
verifie "gh non authentifié : avis vérification impossible" contient "$err" "impossible (gh non authentifié)"

depot format
export GH_TAG=v1.0
lance "$vieux" board
verifie "dernière release hors format : vérification impossible" contient "$err" "hors du format YY.MM.DD[.V]"

depot a12
manifeste "$SHA_VIEUX" 26.11.05
git config sdlc.updateCheck false
lance "$vieux" board
verifie "sdlc.updateCheck false : aucun appel de release, aucun avis" [ "$(appels releases)" = 0 -a -z "$err" -a "$rc" = 0 ]

depot sans
for c in help version --version inconnue; do lance "$vieux" "$c"; done
verifie "help, version, usage invalide : aucune vérification" [ "$(appels releases)" = 0 ]

exit $fail
