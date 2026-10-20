#!/usr/bin/env bash
# Teste scripts/ai-factory.sh (create, update) sur un faux clone d'ai-factory construit
# dans un dossier temporaire depuis fixtures/source/. Ni le dépôt courant ni le réseau ne sont touchés.
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
script="$repo_root/scripts/ai-factory.sh"
tmp=$(mktemp -d); trap 'chmod -R u+rwx "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
unset AI_FACTORY_DELEGUE

c="$tmp/c"; p="$tmp/p"; out="$tmp/out"; err="$tmp/err"
fail=0
# cas <nom> <commande…> : PASS si la commande réussit.
cas() {
  local nom=$1; shift
  if "$@"; then echo "PASS $nom"; else echo "FAIL $nom"; sed 's/^/  | /' "$out" "$err"; fail=1; fi
}

# Faux clone : les fixtures n'ont ni fichier caché ni intent.md (voir le plan du lot), renommés ici.
nouveau_clone() {
  rm -rf "$c"; mkdir -p "$c"; cp -R "$here/fixtures/source/." "$c/"
  mv "$c/claude" "$c/.claude"; mv "$c/gitignore" "$c/.gitignore"
  mkdir -p "$c/scripts"; cp "$script" "$c/scripts/ai-factory.sh"
  git -C "$c" init -q; git -C "$c" add -A; git -C "$c" commit -qm init
}
commit_clone() { git -C "$c" add -A && git -C "$c" commit -qm "${1:-évolution}"; }
create() { bash "$c/scripts/ai-factory.sh" create "$@" >"$out" 2>"$err"; }
maj() { (cd "$p" && bash scripts/ai-factory.sh update "$@") >"$out" 2>"$err"; }
# base : faux clone neuf et projet « demo » créé depuis lui.
base() { rm -rf "$p"; nouveau_clone; create "$p" demo; }
sha_clone() { git -C "$c" rev-parse HEAD; }
# empreinte_manifeste <chemin> : empreinte inscrite au manifeste du projet, vide si absent.
empreinte_manifeste() { awk -v f="$1" 'NR > 2 && substr($0, 67) == f { print substr($0, 1, 64) }' "$p/.ai-factory/manifeste"; }
empreinte() { sha256sum < "$1" | cut -d' ' -f1; }
# etat <dossier> : contenu et bits exécutables de tous les fichiers, hors .git/.
etat() {
  (cd "$1" && find . -path ./.git -prune -o -type f -print0 | LC_ALL=C sort -z | xargs -0 -r shasum -a 256
   find . -path ./.git -prune -o -type f -perm -u+x -print | LC_ALL=C sort)
}

# --- Création ---

base
t_liste_blanche() {
  [ -f "$p/.claude/skills/demo/SKILL.md" ] && [ -f "$p/hooks/pre-commit" ] && [ -f "$p/templates/exemple.md" ] \
    && [ -f "$p/.gitignore" ] && [ -f "$p/scripts/ai-factory.sh" ] \
    && [ ! -e "$p/requirements" ] && [ ! -e "$p/documents" ] && [ ! -e "$p/templates/projet" ] \
    && [ -x "$p/hooks/pre-commit" ] && [ ! -x "$p/templates/exemple.md" ]
}
cas "création : liste blanche copiée, exclusions, bit exécutable (C5, C19, L5)" t_liste_blanche
t_modeles() { grep -qx '# demo' "$p/CLAUDE.md" && grep -qx 'Contexte de demo, version 1.' "$p/CLAUDE.md" && grep -qx '# demo' "$p/README.md"; }
cas "création : CLAUDE.md et README.md avec le nom injecté (C10, C11)" t_modeles
t_manifeste() {
  local m="$p/.ai-factory/manifeste"
  [ "$(sed -n 1p "$m")" = "ai-factory $(sha_clone)" ] && [ "$(sed -n 2p "$m")" = "projet demo" ] \
    && sed 1,2d "$m" | awk '{ print substr($0, 67) }' | LC_ALL=C sort -c \
    && (cd "$p" && sed 1,2d .ai-factory/manifeste | shasum -a 256 -c >/dev/null) \
    && [ -n "$(empreinte_manifeste CLAUDE.md)" ] && [ -z "$(empreinte_manifeste .ai-factory/manifeste)" ]
}
cas "création : manifeste (SHA, projet, lignes triées, sha256sum -c) (C12, C13, C14)" t_manifeste
t_marche() { grep -qx '  git init' "$out" && grep -qx '  git config core.hooksPath hooks' "$out" && [ ! -e "$p/.git" ]; }
cas "création : marche à suivre affichée, aucun .git/ (C3, C20)" t_marche

rm -rf "$p"; create "$p" 'a/b & c\d'
t_nom() { grep -qxF '# a/b & c\d' "$p/CLAUDE.md" && grep -qxF 'projet a/b & c\d' "$p/.ai-factory/manifeste"; }
cas "création : nom a/b & c\\d injecté tel quel (L6)" t_nom

t_non_vide() { rm -rf "$p"; mkdir "$p"; touch "$p/.cache"; create "$p" demo; [ $? -eq 1 ] && [ "$(ls -A "$p")" = .cache ]; }
cas "refus : cible non vide (fichier caché seul), code 1, rien écrit (C16, L1)" t_non_vide
t_vide() { rm -rf "$p"; mkdir "$p"; create "$p" demo && [ -f "$p/.ai-factory/manifeste" ]; }
cas "cible vide acceptée (L2)" t_vide
t_cible_fichier() { rm -rf "$p"; touch "$p"; create "$p" demo; [ $? -eq 1 ] && [ -f "$p" ] && [ ! -s "$p" ]; }
cas "refus : cible fichier ordinaire, code 1 (C40, L20)" t_cible_fichier
rm -f "$p"
if [ "$(id -u)" -eq 0 ]; then
  echo "SKIP refus : cible illisible (C40, L21) — root lit tout"
else
  t_cible_illisible() { mkdir -p "$p"; chmod 000 "$p"; create "$p" demo; local rc=$?; chmod 755 "$p"; [ $rc -eq 1 ] && [ -z "$(ls -A "$p")" ]; }
  cas "refus : cible illisible, code 1, rien écrit (C40, L21)" t_cible_illisible
  rm -rf "$p"
fi
t_nom_vide() { create "$p" ""; [ $? -eq 1 ] && [ ! -e "$p" ]; }
cas "refus : nom vide, code 1 (C17)" t_nom_vide
t_sans_modeles() { git -C "$c" rm -rq templates/projet && commit_clone; create "$p" demo; [ $? -eq 1 ] && [ ! -e "$p" ] && grep -q "templates/projet" "$err"; }
cas "refus : source sans templates/projet/ (C7)" t_sans_modeles
t_source_projet() {
  base; git -C "$p" init -q && git -C "$p" add -A && git -C "$p" commit -qm projet
  bash "$p/scripts/ai-factory.sh" create "$tmp/p2" demo >"$out" 2>"$err"
  [ $? -eq 1 ] && [ ! -e "$tmp/p2" ] && grep -q "c'est un projet" "$err"
}
cas "refus : create depuis un projet (C18, L3)" t_source_projet
t_maj_source_projet() {
  base; git -C "$p" init -q && git -C "$p" add -A && git -C "$p" commit -qm projet
  maj "$p"
  [ $? -eq 1 ] && grep -q "est un projet" "$err" && grep -q "chemin du clone d'ai-factory" "$err"
}
cas "refus : update avec le projet comme source, message explicite" t_maj_source_projet
# Manifeste présent mais non suivi par Git (.gitignore global « .*/ ») : le dossier de travail fait foi.
t_maj_source_projet_non_suivi() {
  base; git -C "$p" init -q && git -C "$p" add -A && git -C "$p" rm -rq --cached .ai-factory && git -C "$p" commit -qm projet
  maj "$p"
  [ $? -eq 1 ] && grep -q "est un projet" "$err"
}
cas "refus : update avec un projet dont le manifeste n'est pas suivi" t_maj_source_projet_non_suivi
t_non_commite() {
  rm -rf "$p"; nouveau_clone
  printf '{}\n' > "$c/.claude/settings.local.json"; printf 'modifié\n' >> "$c/templates/exemple.md"
  create "$p" demo && [ ! -e "$p/.claude/settings.local.json" ] && ! grep -q modifié "$p/templates/exemple.md" \
    && grep -q "non commitées" "$err"
}
cas "non suivi non copié ; non commité ignoré avec avertissement (C4, L4, L5)" t_non_commite
t_commande() { bash "$script" inconnue >"$out" 2>"$err"; [ $? -eq 2 ] && grep -q Usage "$err"; }
cas "commande inconnue : code 2 et usage (Contrats)" t_commande
t_sans_argument() { bash "$script" create "$p" >"$out" 2>"$err"; [ $? -eq 1 ]; }
cas "argument manquant : code 1 (Contrats)" t_sans_argument

# --- Mise à jour ---

t_a2() {
  base; printf '#!/bin/sh\nexit 0 # v2\n' > "$c/hooks/pre-commit"; commit_clone
  maj "$c" && grep -q v2 "$p/hooks/pre-commit" && [ "$(sed -n 1p "$p/.ai-factory/manifeste")" = "ai-factory $(sha_clone)" ] \
    && [ "$(empreinte_manifeste hooks/pre-commit)" = "$(empreinte "$c/hooks/pre-commit")" ] \
    && grep -q "ai-factory : .* -> $(sha_clone)" "$out" && grep -qx 'Remplacés :' "$out"
}
cas "mise à jour : fichier intact remplacé, manifeste au nouveau SHA ; rapport (A2, C23, C30)" t_a2
t_a3() {
  base; printf 'Architecture locale.\n' >> "$p/CLAUDE.md"; local avant; avant=$(empreinte "$p/CLAUDE.md")
  printf '# {{nom-projet}}\n\nContexte de {{nom-projet}}, version 2.\n' > "$c/templates/projet/CLAUDE.md"; commit_clone
  maj "$c" && [ "$(empreinte "$p/CLAUDE.md")" = "$avant" ] && grep -qx 'Contexte de demo, version 2.' "$p/CLAUDE.md.nouveau" \
    && grep -qx '  CLAUDE.md.nouveau' "$out"
}
cas "mise à jour : CLAUDE.md complété conservé, CLAUDE.md.nouveau avec le nom (A3, C25, L12)" t_a3
t_a4() {
  base; rm "$p/.claude/skills/demo/SKILL.md"
  printf 'Version 2.\n' >> "$c/.claude/skills/demo/SKILL.md"; commit_clone
  maj "$c" && [ ! -e "$p/.claude/skills/demo/SKILL.md" ] && [ -f "$p/.claude/skills/demo/SKILL.md.nouveau" ] \
    && grep -qx '  .claude/skills/demo/SKILL.md' "$out" || return 1
  rm "$p/.claude/skills/demo/SKILL.md.nouveau"; printf 'Version 2.\n' >> "$c/templates/exemple.md"; commit_clone
  maj "$c" && [ ! -e "$p/.claude/skills/demo/SKILL.md" ] && [ ! -e "$p/.claude/skills/demo/SKILL.md.nouveau" ] \
    && [ -n "$(empreinte_manifeste .claude/skills/demo/SKILL.md)" ]
}
cas "mise à jour : skill supprimé non recréé, .nouveau à la 1re exécution seulement (A4, C27)" t_a4
t_a5() {
  base; printf 'local\n' >> "$p/hooks/pre-commit"
  git -C "$c" rm -q templates/exemple.md hooks/pre-commit && commit_clone
  maj "$c" && [ ! -e "$p/templates/exemple.md" ] && grep -qx local "$p/hooks/pre-commit" \
    && [ -z "$(empreinte_manifeste hooks/pre-commit)" ] && [ -z "$(empreinte_manifeste templates/exemple.md)" ]
}
cas "mise à jour : intact supprimé en amont supprimé ; modifié conservé et sorti du manifeste (A5, C23, C26)" t_a5
t_a6() {
  base; printf 'projet\n' > "$p/templates/x.md"; printf 'amont\n' > "$c/templates/x.md"; commit_clone
  maj "$c" && grep -qx projet "$p/templates/x.md" && grep -qx amont "$p/templates/x.md.nouveau" \
    && [ "$(empreinte_manifeste templates/x.md)" = "$(empreinte "$c/templates/x.md")" ]
}
cas "mise à jour : collision templates/x.md, .nouveau, chemin entré au manifeste (A6, C28)" t_a6
t_a7() {
  base; mkdir -p "$p/requirements/open/01-x"; printf 'lot en cours\n' > "$p/requirements/open/01-x/intent.txt"
  local avant; avant=$(etat "$p/requirements")
  printf 'Version 2.\n' >> "$c/templates/exemple.md"; commit_clone
  maj "$c" && [ "$(etat "$p/requirements")" = "$avant" ]
}
cas "mise à jour : requirements/ du projet inchangé (A7)" t_a7
t_renommage() {
  base; git -C "$c" mv templates/exemple.md templates/renomme.md && commit_clone
  maj "$c" && [ ! -e "$p/templates/exemple.md" ] && [ -f "$p/templates/renomme.md" ] \
    && [ -z "$(empreinte_manifeste templates/exemple.md)" ] && [ -n "$(empreinte_manifeste templates/renomme.md)" ]
}
cas "mise à jour : renommage = suppression + ajout (C29)" t_renommage
t_l10() {
  base; printf 'même\n' >> "$p/templates/exemple.md"; printf 'même\n' >> "$c/templates/exemple.md"; commit_clone
  maj "$c" && [ ! -e "$p/templates/exemple.md.nouveau" ] && [ "$(empreinte_manifeste templates/exemple.md)" = "$(empreinte "$c/templates/exemple.md")" ]
}
cas "mise à jour : L = N, rien écrit, manifeste à N (L10)" t_l10
t_l8() {
  base; printf 'local\n' >> "$p/templates/exemple.md"
  printf 'v2\n' >> "$c/templates/exemple.md"; commit_clone; maj "$c" || return 1
  printf 'v3\n' >> "$c/templates/exemple.md"; commit_clone
  maj "$c" && grep -qx v3 "$p/templates/exemple.md.nouveau" && grep -qx '  templates/exemple.md.nouveau' "$out"
}
cas "mise à jour : .nouveau existant remplacé et listé (L8)" t_l8
t_l9() {
  base; cp "$p/templates/exemple.md" "$tmp/sauve"; printf 'essai\n' >> "$p/templates/exemple.md"; cp "$tmp/sauve" "$p/templates/exemple.md"
  printf 'v2\n' >> "$c/templates/exemple.md"; commit_clone
  maj "$c" && grep -qx v2 "$p/templates/exemple.md" && [ ! -e "$p/templates/exemple.md.nouveau" ]
}
cas "mise à jour : restauré à l'identique traité comme intact (L9)" t_l9
t_c31() {
  base; local avant; avant=$(etat "$p")
  maj "$c" && grep -q "Déjà à jour" "$out" && [ "$(etat "$p")" = "$avant" ]
}
cas "mise à jour : déjà à jour, rien écrit (C31)" t_c31
t_c34() {
  base; local x; x=$(sha_clone)
  printf 'v2\n' >> "$c/templates/exemple.md"; commit_clone; maj "$c" || return 1
  local y; y=$(sha_clone); git -C "$c" checkout -q "$x"
  local avant; avant=$(etat "$p")
  maj "$c"; [ $? -eq 1 ] && grep -q "$x" "$err" && grep -q "$y" "$err" && [ "$(etat "$p")" = "$avant" ] || return 1
  maj --forcer "$c" && grep -q avertissement "$err" && ! grep -qx v2 "$p/templates/exemple.md" \
    && [ "$(sed -n 1p "$p/.ai-factory/manifeste")" = "ai-factory $x" ]
}
cas "mise à jour : clone plus ancien refusé (code 1), accepté avec --forcer (C34, L11)" t_c34
t_sha_inconnu() {
  base; sed -i.bak "1s/.*/ai-factory $(printf '0%.0s' {1..40})/" "$p/.ai-factory/manifeste"
  local avant; avant=$(etat "$p")
  maj "$c"; [ $? -eq 1 ] && [ "$(etat "$p")" = "$avant" ]
}
cas "mise à jour : SHA du manifeste inconnu du clone refusé (C34, L15)" t_sha_inconnu
t_sans_manifeste() { base; rm -rf "$p/.ai-factory"; maj "$c"; [ $? -eq 1 ] && grep -q "manifeste absent" "$err"; }
cas "mise à jour : sans manifeste refusé (C21, L7)" t_sans_manifeste
t_sous_dossier() {
  base; printf '#!/bin/sh\nexit 0 # v2\n' > "$c/hooks/pre-commit"; commit_clone
  local n; n=$(sed 1,2d "$p/.ai-factory/manifeste" | wc -l)
  maj "$c/scripts" && grep -q v2 "$p/hooks/pre-commit" && [ -f "$p/.claude/skills/demo/SKILL.md" ] && [ -f "$p/CLAUDE.md" ] \
    && [ "$(sed 1,2d "$p/.ai-factory/manifeste" | wc -l)" -eq "$n" ] && ! grep -qx 'Supprimés :' "$out"
}
cas "mise à jour depuis <clone>/scripts : comme depuis la racine, rien supprimé (C37, L17)" t_sous_dossier
t_liste_blanche_etendue() {
  base; sed -i.bak 's/^LISTE_BLANCHE=(\(.*\))$/LISTE_BLANCHE=(\1 outils)/' "$c/scripts/ai-factory.sh"
  grep -q '^LISTE_BLANCHE=(.* outils)$' "$c/scripts/ai-factory.sh" || return 1
  mkdir -p "$c/outils"; printf 'outil\n' > "$c/outils/a.md"; commit_clone
  maj "$c" && [ -f "$p/outils/a.md" ] && grep -q '^LISTE_BLANCHE=(.* outils)$' "$p/scripts/ai-factory.sh" \
    && [ -n "$(empreinte_manifeste outils/a.md)" ]
}
cas "mise à jour : dossier ajouté à la liste blanche copié dès la 1re exécution (C38, L18)" t_liste_blanche_etendue
t_source_sans_script() {
  base; git -C "$c" rm -q scripts/ai-factory.sh && commit_clone
  local avant; avant=$(etat "$p")
  maj "$c"; [ $? -eq 1 ] && grep -q "scripts/ai-factory.sh" "$err" && [ "$(etat "$p")" = "$avant" ]
}
cas "mise à jour : source sans scripts/ai-factory.sh refusée, rien écrit (C38)" t_source_sans_script
t_droits() {
  base; printf 'local\n' >> "$p/.claude/skills/demo/SKILL.md"
  chmod +x "$c/templates/exemple.md" "$c/.claude/skills/demo/SKILL.md"; printf 'v2\n' >> "$c/.claude/skills/demo/SKILL.md"; commit_clone
  maj "$c" && [ -x "$p/templates/exemple.md" ] && grep -qx '  templates/exemple.md' "$out" && grep -qx 'Droits alignés :' "$out" \
    && [ ! -x "$p/.claude/skills/demo/SKILL.md" ] && [ -x "$p/.claude/skills/demo/SKILL.md.nouveau" ]
}
cas "mise à jour : bit exécutable aligné sur l'intact, modifié non touché, .nouveau au mode source (C39, L19)" t_droits
t_script_remplace() {
  base; printf '# évolution du script\n' >> "$c/scripts/ai-factory.sh"; printf 'v2\n' >> "$c/templates/exemple.md"; commit_clone
  maj "$c" && cmp -s "$c/scripts/ai-factory.sh" "$p/scripts/ai-factory.sh" && [ -x "$p/scripts/ai-factory.sh" ] \
    && grep -qx v2 "$p/templates/exemple.md" && [ "$(sed -n 1p "$p/.ai-factory/manifeste")" = "ai-factory $(sha_clone)" ] \
    && [ ! -e "$p/scripts/ai-factory.sh.tmp" ]
}
cas "mise à jour : script remplacé en dernier, exécution menée à son terme (C32, L14)" t_script_remplace
t_interrompue() {
  base; cp "$p/.ai-factory/manifeste" "$tmp/ancien"
  printf '#!/bin/sh\nexit 0 # v2\n' > "$c/hooks/pre-commit"; commit_clone
  maj "$c" || return 1
  cp "$tmp/ancien" "$p/.ai-factory/manifeste"
  maj "$c" && grep -q v2 "$p/hooks/pre-commit" && [ "$(empreinte_manifeste hooks/pre-commit)" = "$(empreinte "$c/hooks/pre-commit")" ]
}
cas "mise à jour interrompue (manifeste non réécrit) : la relance aboutit, aucune perte (C14, L13)" t_interrompue
t_gitignore() {
  base; git -C "$p" init -q; touch "$p/hooks/pre-commit.nouveau"
  ! git -C "$p" status --porcelain | grep -q nouveau
}
cas "*.nouveau ignoré par git status dans un projet initialisé (C35, L16)" t_gitignore

# --- A1 : verifier.sh passe dans un projet créé depuis le dépôt courant ---

if [ -d "$repo_root/templates/projet" ]; then
  t_a1() {
    local a1="$tmp/a1"
    bash "$script" create "$a1" demo >"$out" 2>"$err" || return 1
    (cd "$a1" && git init -q && git config core.hooksPath hooks && bash scripts/verifier.sh) >"$out" 2>"$err" || return 1
    [ ! -e "$a1/requirements" ] && [ ! -e "$a1/documents" ] && [ ! -e "$a1/.obsidian" ] && grep -q ' 0 en échec$' "$out"
  }
  cas "A1 : create depuis le dépôt courant (HEAD), puis verifier.sh dans le projet → code 0 (A1)" t_a1
else
  echo "SKIP A1 : pas de templates/projet/ (projet créé, pas ai-factory)"
fi

exit $fail
