#!/usr/bin/env bash
# Crée un projet depuis un clone d'ai-factory (create), ou y répercute les évolutions
# d'ai-factory sans écraser les modifications locales (update).
# Aucune opération Git dans le projet ; dans le clone, des lectures seulement.
set -u

# Seul endroit qui décide de ce qui est copié dans un projet.
LISTE_BLANCHE=(.claude hooks scripts templates .gitignore)
EXCLUS=(templates/projet)
MODELES=(CLAUDE.md README.md)
SCRIPT=scripts/ai-factory.sh
MANIFESTE=.ai-factory/manifeste

erreur() { echo "scripts/ai-factory.sh : $*" >&2; }
refus() { erreur "$@"; exit 1; }
usage() {
  cat >&2 <<'FIN'
Usage :
  <clone ai-factory>/scripts/ai-factory.sh create <dossier cible> <nom du projet>
  scripts/ai-factory.sh update [--forcer] <chemin du clone ai-factory>   (depuis la racine du projet)
FIN
}

if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  refus "bash 4 ou plus requis (version actuelle : $BASH_VERSION)"
fi

TMPD=""
nettoyer() { [ -n "$TMPD" ] && rm -rf "$TMPD"; }
trap nettoyer EXIT

# Empreinte sha256 du contenu, lue sur l'entrée standard pour ne pas dépendre du nom.
empreinte() { local h; h=$(sha256sum < "$1") || return 1; echo "${h%% *}"; }

# trouver_racine <dossier> : SOURCE = racine du dépôt qui contient <dossier> (C37).
trouver_racine() {
  SOURCE=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || SOURCE=""
  [ -n "$SOURCE" ] || refus "$1 n'est pas dans un dépôt Git : ce n'est pas un clone d'ai-factory"
  git -C "$SOURCE" rev-parse -q --verify 'HEAD^{commit}' >/dev/null || refus "$SOURCE n'a aucun commit"
  SHA_SOURCE=$(git -C "$SOURCE" rev-parse HEAD)
}

# verifier_source : refuse un dépôt qui n'a pas les modèles de projet à HEAD (C7).
verifier_source() {
  local m
  if [ -e "$SOURCE/$MANIFESTE" ] || git -C "$SOURCE" cat-file -e "HEAD:$MANIFESTE" 2>/dev/null; then
    refus "$SOURCE est un projet (il contient $MANIFESTE), pas un clone d'ai-factory : indiquez le chemin du clone d'ai-factory"
  fi
  for m in "${MODELES[@]}"; do
    git -C "$SOURCE" cat-file -e "HEAD:templates/projet/$m" 2>/dev/null \
      || refus "$SOURCE n'est pas un clone d'ai-factory : templates/projet/$m absent à HEAD"
  done
}

# avertir_non_commite : le contenu est lu à HEAD, les modifications en cours sont ignorées (C4).
avertir_non_commite() {
  if [ -n "$(git -C "$SOURCE" status --porcelain --untracked-files=no -- "${LISTE_BLANCHE[@]}" templates/projet)" ]; then
    erreur "avertissement : modifications non commitées dans $SOURCE ignorées, contenu lu à HEAD ($SHA_SOURCE)"
  fi
}

# preparer <nom> : écrit dans $TMPD/n les fichiers de la source et les modèles remplis,
# remplit MODE[chemin] (x ou -) et N[chemin] (empreinte) (C5, C10, C11, C22).
preparer() {
  local nom=$1 mode type objet chemin e garde contenu m
  declare -gA MODE=() N=()
  mkdir -p "$TMPD/n"
  while IFS=$'\t' read -r -d '' entete chemin; do
    read -r mode type objet <<<"$entete"
    [ "$type" = blob ] || continue
    garde=1
    for e in "${EXCLUS[@]}"; do
      case "$chemin" in "$e"|"$e"/*) garde=0 ;; esac
    done
    [ $garde -eq 1 ] || continue
    case "$mode" in
      100755) MODE[$chemin]=x ;;
      100644) MODE[$chemin]=- ;;
      *) erreur "avertissement : $chemin ignoré (mode $mode non géré)"; continue ;;
    esac
    mkdir -p "$TMPD/n/$(dirname -- "$chemin")"
    git -C "$SOURCE" cat-file blob "$objet" > "$TMPD/n/$chemin" || refus "lecture impossible : $chemin"
  done < <(git -C "$SOURCE" ls-tree -r -z HEAD -- "${LISTE_BLANCHE[@]}")

  for m in "${MODELES[@]}"; do
    # Le x final protège les retours à la ligne de fin de fichier.
    contenu=$(git -C "$SOURCE" cat-file blob "HEAD:templates/projet/$m"; printf x) || refus "lecture impossible : templates/projet/$m"
    contenu=${contenu%x}
    # Remplacement entre guillemets : « & » reste littéral (patsub_replacement, bash ≥ 5.2).
    printf '%s' "${contenu//"{{nom-projet}}"/"$nom"}" > "$TMPD/n/$m"
    MODE[$m]=-
  done

  for chemin in "${!MODE[@]}"; do
    N[$chemin]=$(empreinte "$TMPD/n/$chemin") || refus "empreinte impossible : $chemin"
  done
}

# ecrire_fichier <chemin> <destination> : copie la version préparée de <chemin> par un
# fichier temporaire, avec le bit exécutable de la source, puis renommage (C39).
ecrire_fichier() {
  local chemin=$1 dest=$2
  mkdir -p -- "$(dirname -- "$dest")" || return 1
  cp -- "$TMPD/n/$chemin" "$dest.tmp" || return 1
  # « -- » avant le mode : le chmod BSD (macOS) lit « -x » comme un mode, pas comme une option.
  if [ "${MODE[$chemin]}" = x ]; then chmod -- a+x "$dest.tmp"; else chmod -- a-x "$dest.tmp"; fi || return 1
  mv -f -- "$dest.tmp" "$dest"
}

# ecrire_manifeste <dossier projet> <sha> <nom> : réécrit le manifeste depuis F[] (C12 à C14).
ecrire_manifeste() {
  local dir=$1 sha=$2 nom=$3 chemin
  mkdir -p -- "$dir/.ai-factory" || return 1
  {
    echo "ai-factory $sha"
    echo "projet $nom"
    while IFS= read -r chemin; do
      [ -n "$chemin" ] && printf '%s  %s\n' "${F[$chemin]}" "$chemin"
    done < <(printf '%s\n' "${!F[@]}" | LC_ALL=C sort)
  } > "$dir/$MANIFESTE.tmp" && mv -f -- "$dir/$MANIFESTE.tmp" "$dir/$MANIFESTE"
}

cmd_create() {
  [ $# -eq 2 ] || { erreur "argument manquant"; usage; exit 1; }
  local cible=$1 nom=$2 chemin
  [ -n "$cible" ] || refus "dossier cible vide"
  [ -n "$nom" ] || refus "nom de projet vide"

  trouver_racine "$(dirname -- "$0")"
  if git -C "$SOURCE" cat-file -e "HEAD:$MANIFESTE" 2>/dev/null; then
    refus "$SOURCE contient $MANIFESTE : c'est un projet, pas ai-factory ; lancez create depuis un clone d'ai-factory"
  fi
  verifier_source

  if [ -e "$cible" ] || [ -L "$cible" ]; then
    [ -d "$cible" ] || refus "$cible existe et n'est pas un dossier"
    { [ -r "$cible" ] && [ -x "$cible" ]; } || refus "$cible n'est pas lisible"
    [ -z "$(ls -A -- "$cible")" ] || refus "$cible existe et n'est pas vide"
  fi

  avertir_non_commite
  TMPD=$(mktemp -d) || refus "dossier temporaire impossible"
  preparer "$nom"

  mkdir -p -- "$cible" || refus "création impossible : $cible"
  declare -gA F=()
  for chemin in "${!MODE[@]}"; do
    ecrire_fichier "$chemin" "$cible/$chemin" || refus "écriture impossible : $cible/$chemin"
    F[$chemin]=${N[$chemin]}
  done
  ecrire_manifeste "$cible" "$SHA_SOURCE" "$nom" || refus "écriture impossible : $cible/$MANIFESTE"

  cat <<FIN
Projet « $nom » créé dans $cible (ai-factory $SHA_SOURCE).
Marche à suivre (non exécutée) :
  cd $cible
  git init
  git config core.hooksPath hooks
Si votre .gitignore global ignore les dossiers cachés (.*/) : git add -f .claude .ai-factory
FIN
}

cmd_update() {
  local args=("$@") forcer=0
  if [ "${1:-}" = --forcer ]; then forcer=1; shift; fi
  [ $# -eq 1 ] || { erreur "argument manquant"; usage; exit 1; }
  [ -f "$MANIFESTE" ] || refus "$MANIFESTE absent : à lancer depuis la racine d'un projet créé par scripts/ai-factory.sh create"
  trouver_racine "$1"
  verifier_source

  # La version du script de la source applique la mise à jour, avec sa liste blanche (C38).
  if [ -z "${AI_FACTORY_DELEGUE:-}" ]; then
    git -C "$SOURCE" cat-file -e "HEAD:$SCRIPT" 2>/dev/null || refus "$SOURCE n'a pas $SCRIPT à HEAD"
    local delegue rc
    delegue=$(mktemp) || refus "fichier temporaire impossible"
    git -C "$SOURCE" cat-file blob "HEAD:$SCRIPT" > "$delegue" || { rm -f "$delegue"; refus "lecture impossible : $SCRIPT"; }
    AI_FACTORY_DELEGUE=1 bash "$delegue" update "${args[@]}"; rc=$?
    rm -f "$delegue"
    exit $rc
  fi

  local ancien="" nom="" ligne chemin m l n
  declare -A M=()
  {
    IFS= read -r ligne; ancien=${ligne#ai-factory }
    IFS= read -r ligne; nom=${ligne#projet }
    while IFS= read -r ligne; do
      [ -n "$ligne" ] && M[${ligne#*  }]=${ligne%%  *}
    done
  } < "$MANIFESTE"
  [[ $ancien =~ ^[0-9a-f]{40}$ ]] || refus "$MANIFESTE illisible : première ligne attendue « ai-factory <SHA> »"

  if ! git -C "$SOURCE" cat-file -e "$ancien^{commit}" 2>/dev/null \
     || ! git -C "$SOURCE" merge-base --is-ancestor "$ancien" HEAD; then
    if [ $forcer -eq 0 ]; then
      refus "le HEAD de $SOURCE ($SHA_SOURCE) ne descend pas de la version installée ($ancien) ; --forcer pour passer outre"
    fi
    erreur "avertissement : --forcer : $SHA_SOURCE ne descend pas de $ancien, mise à jour appliquée quand même"
  fi

  avertir_non_commite
  TMPD=$(mktemp -d) || refus "dossier temporaire impossible"
  preparer "$nom"

  if [ "$SHA_SOURCE" = "$ancien" ] && [ "${N[CLAUDE.md]}" = "${M[CLAUDE.md]-}" ] && [ "${N[README.md]}" = "${M[README.md]-}" ]; then
    echo "Déjà à jour (ai-factory $ancien) : rien n'est modifié."
    exit 0
  fi

  declare -gA F=()
  local remplaces=() ajoutes=() supprimes=() droits=() nouveaux=() absents=() sortis=() script_differe=0
  proposer() { ecrire_fichier "$1" "$1.nouveau" || refus "écriture impossible : $1.nouveau"; nouveaux+=("$1.nouveau"); }
  remplacer() {
    if [ "$1" = "$SCRIPT" ]; then script_differe=1; return; fi
    ecrire_fichier "$1" "$1" || refus "écriture impossible : $1"
  }

  while IFS= read -r chemin; do
    [ -n "$chemin" ] || continue
    m=${M[$chemin]-} n=${N[$chemin]-}
    if [ -f "$chemin" ]; then l=$(empreinte "$chemin") || l="?"
    elif [ -e "$chemin" ] || [ -L "$chemin" ]; then l="?"
    else l=""; fi

    if [ -n "$m" ]; then
      if [ "$l" = "$m" ]; then                         # intact (C23)
        if [ -z "$n" ]; then
          rm -f -- "$chemin" || refus "suppression impossible : $chemin"; supprimes+=("$chemin")
        elif [ "$n" != "$m" ]; then
          remplacer "$chemin"; remplaces+=("$chemin"); F[$chemin]=$n
        else
          F[$chemin]=$m
          if [ "${MODE[$chemin]}" = x ] && [ ! -x "$chemin" ]; then chmod -- a+x "$chemin" && droits+=("$chemin")
          elif [ "${MODE[$chemin]}" = - ] && [ -x "$chemin" ]; then chmod -- a-x "$chemin" && droits+=("$chemin"); fi
        fi
      elif [ -z "$l" ]; then                           # supprimé localement (C27)
        absents+=("$chemin")
        if [ -z "$n" ]; then sortis+=("$chemin")
        elif [ "$n" = "$m" ]; then F[$chemin]=$m
        else proposer "$chemin"; F[$chemin]=$n; fi
      else                                             # modifié localement (C24 à C26)
        if [ -z "$n" ]; then sortis+=("$chemin")
        elif [ "$n" = "$m" ]; then F[$chemin]=$m
        elif [ "$l" = "$n" ]; then F[$chemin]=$n
        else proposer "$chemin"; F[$chemin]=$n; fi
      fi
    else                                               # nouveau fichier d'ai-factory (C28)
      if [ -z "$l" ]; then
        ecrire_fichier "$chemin" "$chemin" || refus "écriture impossible : $chemin"; ajoutes+=("$chemin")
      elif [ "$l" != "$n" ]; then proposer "$chemin"; fi
      F[$chemin]=$n
    fi
  done < <({ printf '%s\n' "${!M[@]}"; printf '%s\n' "${!N[@]}"; } | LC_ALL=C sort -u)

  # Le script en cours est remplacé en dernier, par renommage (C32).
  if [ $script_differe -eq 1 ]; then
    ecrire_fichier "$SCRIPT" "$SCRIPT" || refus "écriture impossible : $SCRIPT"
  fi
  ecrire_manifeste . "$SHA_SOURCE" "$nom" || refus "écriture impossible : $MANIFESTE"

  echo "ai-factory : $ancien -> $SHA_SOURCE"
  rubrique() {
    local titre=$1; shift
    [ $# -gt 0 ] || return 0
    echo "$titre :"
    printf '  %s\n' "$@"
  }
  rubrique "Remplacés" "${remplaces[@]}"
  rubrique "Ajoutés" "${ajoutes[@]}"
  rubrique "Supprimés" "${supprimes[@]}"
  rubrique "Droits alignés" "${droits[@]}"
  rubrique ".nouveau écrits, à fusionner à la main puis supprimer" "${nouveaux[@]}"
  rubrique "Supprimés localement, non recréés" "${absents[@]}"
  rubrique "Sortis du manifeste, devenus fichiers du projet" "${sortis[@]}"
}

case "${1:-}" in
  create) shift; cmd_create "$@" ;;
  # mettre-a-jour : ancien nom, encore émis par la délégation des projets déjà créés.
  update|mettre-a-jour) shift; cmd_update "$@" ;;
  "") erreur "commande manquante"; usage; exit 1 ;;
  *) erreur "commande inconnue : $1"; usage; exit 2 ;;
esac
