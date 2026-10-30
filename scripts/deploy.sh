#!/usr/bin/env bash
# Installe le kit dans un dépôt produit, existant ou non (install), ou y répercute les
# évolutions du kit sans écraser les modifications locales (update). Se lance depuis un
# clone du kit. Aucune opération Git dans le dépôt produit ; dans le clone, des lectures.
set -u

# Seul endroit qui décide de ce qui est copié dans un dépôt produit. Les dossiers tests/
# (tests du kit) sont toujours exclus.
LISTE_BLANCHE=(.claude .github .githooks .sdlc templates REVIEW.md)
EXCLUS=(templates/projet)
MODELES=(CLAUDE.md README.md)
MANIFESTE=.sdlc/manifeste

erreur() { echo "scripts/deploy.sh : $*" >&2; }
refus() { erreur "$@"; exit 1; }
usage() {
  cat >&2 <<'FIN'
Usage :
  <clone du kit>/scripts/deploy.sh install <dépôt produit> [<nom du projet>]
  <clone du kit>/scripts/deploy.sh update [--forcer] <dépôt produit>
FIN
}

TMPD=""
nettoyer() { [ -n "$TMPD" ] && rm -rf "$TMPD"; }
trap nettoyer EXIT

if command -v sha256sum >/dev/null 2>&1; then SHA256="sha256sum"; else SHA256="shasum -a 256"; fi
# Empreinte sha256 du contenu, lue sur l'entrée standard pour ne pas dépendre du nom.
empreinte() { local h; h=$($SHA256 < "$1") || return 1; echo "${h%% *}"; }

# resoudre <chemin> : chemin physique, même si la fin n'existe pas encore.
resoudre() {
  local d=$1 reste=""
  while [ ! -d "$d" ]; do reste="/$(basename -- "$d")$reste"; d=$(dirname -- "$d"); done
  echo "$(cd -- "$d" && pwd -P)$reste"
}

# trouver_source : SOURCE = racine du clone du kit qui contient ce script.
trouver_source() {
  local m
  SOURCE=$(git -C "$(dirname -- "$0")" rev-parse --show-toplevel 2>/dev/null) || SOURCE=""
  [ -n "$SOURCE" ] || refus "$(dirname -- "$0") n'est pas dans un dépôt Git : lancez le script depuis un clone du kit"
  git -C "$SOURCE" rev-parse -q --verify 'HEAD^{commit}' >/dev/null || refus "$SOURCE n'a aucun commit"
  SHA_SOURCE=$(git -C "$SOURCE" rev-parse HEAD)
  if git -C "$SOURCE" cat-file -e "HEAD:$MANIFESTE" 2>/dev/null; then
    refus "$SOURCE contient $MANIFESTE : c'est un dépôt produit, lancez le script depuis un clone du kit"
  fi
  for m in bin/git-sdlc "${MODELES[@]/#/templates/projet/}"; do
    git -C "$SOURCE" cat-file -e "HEAD:$m" 2>/dev/null \
      || refus "$SOURCE n'est pas un clone du kit : $m absent à HEAD"
  done
  if [ -n "$(git -C "$SOURCE" status --porcelain --untracked-files=no -- "${LISTE_BLANCHE[@]}" templates/projet)" ]; then
    erreur "avertissement : modifications non commitées dans $SOURCE ignorées, contenu lu à HEAD ($SHA_SOURCE)"
  fi
}

# verifier_cible <dossier> : refuse une cible fichier, illisible, ou dans le clone du kit.
verifier_cible() {
  local r
  [ -n "$1" ] || refus "dépôt produit vide"
  if [ -e "$1" ] || [ -L "$1" ]; then
    [ -d "$1" ] || refus "$1 existe et n'est pas un dossier"
    { [ -r "$1" ] && [ -w "$1" ] && [ -x "$1" ]; } || refus "$1 n'est pas accessible en lecture et écriture"
  fi
  r=$(resoudre "$1")
  case "$r/" in "$(cd -- "$SOURCE" && pwd -P)/"*) refus "$1 est dans le clone du kit" ;; esac
}

# preparer <nom> : écrit dans $TMPD/n les fichiers du kit à HEAD, avec leur bit exécutable,
# et les modèles remplis ; la liste triée des chemins va dans $TMPD/liste-n.
preparer() {
  local nom=$1 entete chemin mode type objet e contenu m marqueur="{{nom-projet}}"
  mkdir -p "$TMPD/n" || refus "dossier temporaire impossible"
  while IFS=$'\t' read -r -d '' entete chemin; do
    read -r mode type objet <<<"$entete"
    [ "$type" = blob ] || continue
    case "$chemin" in */tests/*) continue ;; esac
    for e in "${EXCLUS[@]}"; do
      case "$chemin" in "$e"|"$e"/*) continue 2 ;; esac
    done
    case "$mode" in
      100755|100644) ;;
      *) erreur "avertissement : $chemin ignoré (mode $mode non géré)"; continue ;;
    esac
    mkdir -p "$TMPD/n/$(dirname -- "$chemin")"
    git -C "$SOURCE" cat-file blob "$objet" > "$TMPD/n/$chemin" || refus "lecture impossible : $chemin"
    if [ "$mode" = 100755 ]; then chmod -- a+x "$TMPD/n/$chemin"; else chmod -- a-x "$TMPD/n/$chemin"; fi
    printf '%s\n' "$chemin"
  done < <(git -C "$SOURCE" ls-tree -r -z HEAD -- "${LISTE_BLANCHE[@]}") > "$TMPD/liste-n"

  for m in "${MODELES[@]}"; do
    # Le x final protège les retours à la ligne de fin de fichier.
    contenu=$(git -C "$SOURCE" cat-file blob "HEAD:templates/projet/$m"; printf x) || refus "lecture impossible : templates/projet/$m"
    contenu=${contenu%x}
    # Remplacement entre guillemets, hors de "…" : « & » reste littéral en bash ≥ 5.2
    # (patsub_replacement), et bash 3.2 ne garde pas les guillemets dans le résultat.
    contenu=${contenu//"$marqueur"/"$nom"}
    printf '%s' "$contenu" > "$TMPD/n/$m"
    chmod -- a-x "$TMPD/n/$m"
    printf '%s\n' "$m" >> "$TMPD/liste-n"
  done
}

# lire_manifeste <fichier> : ANCIEN, NOM_PROJET, et une empreinte par chemin dans $TMPD/m.
lire_manifeste() {
  local ligne chemin
  mkdir -p "$TMPD/m" || refus "dossier temporaire impossible"
  : > "$TMPD/liste-m"
  {
    IFS= read -r ligne; ANCIEN=${ligne#sdlc-kit }
    IFS= read -r ligne; NOM_PROJET=${ligne#projet }
    while IFS= read -r ligne; do
      [ -n "$ligne" ] || continue
      chemin=${ligne#*  }
      case "/$chemin/" in
        //|*/../*|*/./*|//*) refus "$1 : chemin refusé : $chemin" ;;
      esac
      [[ ${ligne%%  *} =~ ^[0-9a-f]{64}$ ]] || refus "$1 : ligne illisible : $ligne"
      mkdir -p "$TMPD/m/$(dirname -- "$chemin")" && printf '%s\n' "${ligne%%  *}" > "$TMPD/m/$chemin" \
        || refus "$1 : chemin illisible : $chemin"
      printf '%s\n' "$chemin" >> "$TMPD/liste-m"
    done
  } < "$1"
  [[ $ANCIEN =~ ^[0-9a-f]{40}$ ]] || refus "$1 illisible : première ligne attendue « sdlc-kit <SHA> »"
  [ -n "$NOM_PROJET" ] || refus "$1 illisible : deuxième ligne attendue « projet <nom> »"
}

# ecrire_fichier <chemin> <destination> : copie la version préparée par un fichier
# temporaire, avec le bit exécutable du kit, puis renommage.
ecrire_fichier() {
  local chemin=$1 dest=$2
  mkdir -p -- "$(dirname -- "$dest")" || return 1
  cp -- "$TMPD/n/$chemin" "$dest.tmp" || return 1
  # « -- » avant le mode : le chmod BSD (macOS) lit « -x » comme un mode, pas comme une option.
  if [ -x "$TMPD/n/$chemin" ]; then chmod -- a+x "$dest.tmp"; else chmod -- a-x "$dest.tmp"; fi || return 1
  mv -f -- "$dest.tmp" "$dest"
}

# appliquer <cible> : compare pour chaque chemin l'empreinte du manifeste (M), du dépôt
# produit (L) et du kit (N), agit, puis réécrit le manifeste. M est vide à l'install.
appliquer() {
  local cible=$1 chemin m l n f d
  remplaces=() ajoutes=() supprimes=() droits=() nouveaux=() absents=() sortis=()
  : > "$TMPD/f"
  proposer() {
    ecrire_fichier "$1" "$cible/$1.nouveau" || refus "écriture impossible : $cible/$1.nouveau"
    nouveaux+=("$1.nouveau")
  }
  garder() { printf '%s  %s\n' "$1" "$chemin" >> "$TMPD/f"; }

  while IFS= read -r chemin; do
    [ -n "$chemin" ] || continue
    f="$cible/$chemin" m="" n=""
    [ -f "$TMPD/m/$chemin" ] && m=$(cat "$TMPD/m/$chemin")
    [ -f "$TMPD/n/$chemin" ] && { n=$(empreinte "$TMPD/n/$chemin") || refus "empreinte impossible : $chemin"; }
    if [ -f "$f" ]; then l=$(empreinte "$f") || l="?"
    elif [ -e "$f" ] || [ -L "$f" ]; then l="?"
    else l=""; fi

    if [ -n "$m" ]; then
      if [ "$l" = "$m" ]; then                         # intact
        if [ -z "$n" ]; then
          rm -f -- "$f" || refus "suppression impossible : $f"; supprimes+=("$chemin")
          d=$(dirname -- "$chemin")    # dossiers devenus vides, jusqu'à la racine du dépôt
          while [ "$d" != . ] && rmdir -- "$cible/$d" 2>/dev/null; do d=$(dirname -- "$d"); done
        elif [ "$n" != "$m" ]; then
          ecrire_fichier "$chemin" "$f" || refus "écriture impossible : $f"; remplaces+=("$chemin"); garder "$n"
        else
          garder "$m"
          if [ -x "$TMPD/n/$chemin" ] && [ ! -x "$f" ]; then chmod -- a+x "$f" && droits+=("$chemin")
          elif [ ! -x "$TMPD/n/$chemin" ] && [ -x "$f" ]; then chmod -- a-x "$f" && droits+=("$chemin"); fi
        fi
      elif [ -z "$l" ]; then                           # supprimé dans le dépôt produit
        absents+=("$chemin")
        if [ -z "$n" ]; then sortis+=("$chemin")
        elif [ "$n" = "$m" ]; then garder "$m"
        else proposer "$chemin"; garder "$n"; fi
      else                                             # modifié dans le dépôt produit
        if [ -z "$n" ]; then sortis+=("$chemin")
        elif [ "$n" = "$m" ]; then garder "$m"
        elif [ "$l" = "$n" ]; then garder "$n"
        else proposer "$chemin"; garder "$n"; fi
      fi
    else                                               # nouveau fichier du kit
      if [ -z "$l" ]; then
        ecrire_fichier "$chemin" "$f" || refus "écriture impossible : $f"; ajoutes+=("$chemin")
      elif [ "$l" != "$n" ]; then proposer "$chemin"; fi
      garder "$n"
    fi
  done < <(LC_ALL=C sort -u "$TMPD/liste-m" "$TMPD/liste-n")

  # Le manifeste n'est réécrit qu'une fois tout le reste fait. Les lignes sont déjà
  # triées par chemin : la boucle suit l'ordre de sort -u.
  mkdir -p -- "$cible/$(dirname -- "$MANIFESTE")" \
    && { echo "sdlc-kit $SHA_SOURCE"; echo "projet $NOM_PROJET"; cat "$TMPD/f"; } > "$cible/$MANIFESTE.tmp" \
    && mv -f -- "$cible/$MANIFESTE.tmp" "$cible/$MANIFESTE" \
    || refus "écriture impossible : $cible/$MANIFESTE"
}

rubrique() {
  local titre=$1; shift
  [ $# -gt 0 ] || return 0
  echo "$titre :"
  printf '  %s\n' "$@"
}

# Tableaux éventuellement vides : « ${t[@]+…} » évite l'erreur de set -u en bash 3.2.
rapport() {
  rubrique "Remplacés" ${remplaces[@]+"${remplaces[@]}"}
  rubrique "Ajoutés" ${ajoutes[@]+"${ajoutes[@]}"}
  rubrique "Supprimés" ${supprimes[@]+"${supprimes[@]}"}
  rubrique "Droits alignés" ${droits[@]+"${droits[@]}"}
  rubrique ".nouveau écrits, à fusionner à la main puis supprimer" ${nouveaux[@]+"${nouveaux[@]}"}
  rubrique "Supprimés localement, non recréés" ${absents[@]+"${absents[@]}"}
  rubrique "Sortis du manifeste, devenus fichiers du dépôt" ${sortis[@]+"${sortis[@]}"}
}

cmd_install() {
  [ $# -eq 1 ] || [ $# -eq 2 ] || { erreur "argument manquant ou en trop"; usage; exit 1; }
  local cible=$1
  trouver_source
  verifier_cible "$cible"
  [ ! -e "$cible/$MANIFESTE" ] || refus "$cible/$MANIFESTE existe : le kit est déjà installé, utilisez update"
  if [ $# -eq 2 ]; then NOM_PROJET=$2; else NOM_PROJET=$(basename -- "$(resoudre "$cible")"); fi
  [ -n "$NOM_PROJET" ] || refus "nom de projet vide"

  TMPD=$(mktemp -d) || refus "dossier temporaire impossible"
  preparer "$NOM_PROJET"
  : > "$TMPD/liste-m"
  mkdir -p -- "$cible" || refus "création impossible : $cible"
  appliquer "$cible"

  echo "Kit installé dans $cible pour « $NOM_PROJET » (kit $SHA_SOURCE)."
  rapport
  cat <<FIN
Marche à suivre (non exécutée) :
  cd $cible
  git init                              # si ce n'est pas encore un dépôt
  # fusionner puis supprimer les .nouveau ; compléter CLAUDE.md et README.md
  git config core.hooksPath .githooks
  git add -A && git commit -m "Initialisation du SDLC" && git push
  cp $SOURCE/bin/git-sdlc ~/.local/bin/ && chmod +x ~/.local/bin/git-sdlc   # si absent, tout dossier du PATH
  git sdlc setup --dry-run && git sdlc setup
Si votre .gitignore global ignore les dossiers cachés (.*/) : git add -f .claude .github .githooks .sdlc
FIN
}

cmd_update() {
  local forcer=0
  if [ "${1:-}" = --forcer ]; then forcer=1; shift; fi
  [ $# -eq 1 ] || { erreur "argument manquant ou en trop"; usage; exit 1; }
  local cible=$1
  trouver_source
  verifier_cible "$cible"
  [ -f "$cible/$MANIFESTE" ] || refus "$cible/$MANIFESTE absent : le kit n'y a pas été installé par scripts/deploy.sh install"

  TMPD=$(mktemp -d) || refus "dossier temporaire impossible"
  lire_manifeste "$cible/$MANIFESTE"
  if ! git -C "$SOURCE" cat-file -e "$ANCIEN^{commit}" 2>/dev/null \
     || ! git -C "$SOURCE" merge-base --is-ancestor "$ANCIEN" HEAD; then
    if [ $forcer -eq 0 ]; then
      refus "le HEAD de $SOURCE ($SHA_SOURCE) ne descend pas de la version installée ($ANCIEN) ; --forcer pour passer outre"
    fi
    erreur "avertissement : --forcer : $SHA_SOURCE ne descend pas de $ANCIEN, mise à jour appliquée quand même"
  fi
  preparer "$NOM_PROJET"

  local m deja=0
  if [ "$SHA_SOURCE" = "$ANCIEN" ]; then
    deja=1
    for m in "${MODELES[@]}"; do
      [ "$(empreinte "$TMPD/n/$m")" = "$(cat "$TMPD/m/$m" 2>/dev/null)" ] || deja=0
    done
  fi
  if [ $deja -eq 1 ]; then
    echo "Déjà à jour (kit $ANCIEN) : rien n'est modifié."
    exit 0
  fi

  appliquer "$cible"
  echo "Kit : $ANCIEN -> $SHA_SOURCE"
  rapport
}

case "${1:-}" in
  install) shift; cmd_install "$@" ;;
  update) shift; cmd_update "$@" ;;
  "") erreur "commande manquante"; usage; exit 1 ;;
  *) erreur "commande inconnue : $1"; usage; exit 2 ;;
esac
