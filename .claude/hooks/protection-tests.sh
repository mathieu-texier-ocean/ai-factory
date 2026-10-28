#!/usr/bin/env bash
# Hook Claude Code PreToolUse sur Edit, Write et Bash : sur une branche bugfix/, demande la confirmation
# de l'humain avant de modifier ou supprimer un fichier existant sous un dossier tests/. Lecture seule.
# Bash : détection sur le texte de tool_input.command, découpe naïve (guillemets, $(…), sh -c ignorés).
set -u
entree=$(cat)

# champ <nom> : première valeur chaîne "<nom>":"…" de l'entrée, échappements JSON décodés.
champ() {
  local motif='"'$1'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)"' s r= c i=0
  [[ $entree =~ $motif ]] || return 0
  s=${BASH_REMATCH[1]}
  while [ $i -lt ${#s} ]; do
    c=${s:i:1}
    if [ "$c" = '\' ]; then
      i=$((i + 1)); c=${s:i:1}
      case $c in n) c=$'\n' ;; t) c=$'\t' ;; esac
    fi
    r+=$c; i=$((i + 1))
  done
  printf '%s' "$r"
}

# absolu <chemin> <dossier> : chemin absolu, sans . ni .., résolu depuis le dossier s'il est relatif.
absolu() {
  local p=$1 part parts out=()
  case $p in /*) ;; '~'|'~/'*) p=$HOME${p#'~'} ;; *) p=$2/$p ;; esac
  IFS=/ read -ra parts <<< "$p"
  for part in "${parts[@]}"; do
    case $part in
      ''|.) ;;
      ..) [ ${#out[@]} -gt 0 ] && out=("${out[@]:0:${#out[@]}-1}") ;;
      *) out+=("$part") ;;
    esac
  done
  p=$(IFS=/; printf '/%s' "${out[*]}")
  # Dossier parent physique s'il existe, pour comparer à la racine malgré les liens symboliques.
  part=$(cd "${p%/*}/" 2>/dev/null && pwd -P) && p=${part%/}/${p##*/}
  printf '%s' "$p"
}

# relatif <chemin absolu> : chemin relatif à la racine ; échoue hors du dépôt.
relatif() { case $1 in "$racine"/*) printf '%s' "${1#"$racine"/}" ;; *) return 1 ;; esac; }

# protege <chemin absolu> : réussit pour un fichier existant (ou un motif glob) sous un dossier tests/.
protege() {
  local rel
  rel=$(relatif "$1") || return 1
  case /$rel/ in */tests/*) ;; *) return 1 ;; esac
  [ -e "$1" ] || [ -L "$1" ] && return 0
  case ${1##*/} in *[*?[]*) return 0 ;; esac
  return 1
}

json() { local s=${1//\\/\\\\}; s=${s//\"/\\\"}; printf '%s' "${s//$'\n'/\\n}"; }

demande() {
  local raison="Branche de correctif ($branche) : modification ou suppression d'un test existant, $(relatif "$1"). Pendant un correctif, corriger le code, pas le test ; si le changement de test est volontaire, le confirmer."
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$(json "$raison")"
  exit 0
}

cwd=$(champ cwd)
racine=${CLAUDE_PROJECT_DIR:-$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)}
racine=$(cd "${racine:-.}" 2>/dev/null && pwd -P) || exit 0
branche=$(git -C "$racine" symbolic-ref --short -q HEAD) || exit 0
case $branche in bugfix/*) ;; *) exit 0 ;; esac
dossier=${cwd:-$racine}

# cibles <segment> : cibles d'écriture d'une commande simple, une par ligne ; « cd » met à jour dossier.
cibles() {
  local mots m args=() sortie=() suivant= i
  read -ra mots <<< "$1"
  for m in "${mots[@]}"; do
    m=${m//\"/}; m=${m//\'/}
    if [ -n "$suivant" ]; then
      [ "$suivant" = '>' ] && sortie+=("$m")
      suivant=; continue
    fi
    if [[ $m =~ ^[0-9\&]*\>\>?\|?(.*)$ ]]; then
      if [ -z "${BASH_REMATCH[1]}" ]; then suivant='>'; else sortie+=("${BASH_REMATCH[1]}"); fi
      continue
    fi
    if [[ $m =~ ^[0-9]*\<(.*)$ ]]; then
      [ -z "${BASH_REMATCH[1]}" ] && suivant='<'
      continue
    fi
    args+=("$m")
  done
  for m in "${sortie[@]}"; do
    case $m in /dev/null|'&'*) ;; *) printf '%s\n' "$m" ;; esac
  done
  # Préfixes d'affectation (VAR=x cmd) ignorés.
  while [ ${#args[@]} -gt 0 ] && [[ ${args[0]} =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do args=("${args[@]:1}"); done
  [ ${#args[@]} -gt 0 ] || return 0
  local cmd=${args[0]} ops=() inplace= script=1
  args=("${args[@]:1}")
  for ((i = 0; i < ${#args[@]}; i++)); do
    case $cmd:${args[i]} in
      sed:-i*|sed:--in-place*) inplace=1 ;;
      sed:-e|sed:-f|sed:--expression|sed:--file) script=; i=$((i + 1)) ;;
      sed:-e*|sed:-f*|sed:--expression=*|sed:--file=*) script= ;;
      *:-*) ;;
      *) ops+=("${args[i]}") ;;
    esac
  done
  case $cmd in
    cd) [ ${#ops[@]} -gt 0 ] && [ "${ops[0]}" != - ] && printf 'cd\t%s\n' "${ops[0]}" ;;
    rm|mv|tee) [ ${#ops[@]} -gt 0 ] && printf '%s\n' "${ops[@]}" ;;
    cp) [ ${#ops[@]} -gt 0 ] && printf '%s\n' "${ops[${#ops[@]}-1]}" ;;
    sed) [ -n "$inplace" ] && [ ${#ops[@]} -gt ${script:-0} ] && printf '%s\n' "${ops[@]:${script:-0}}" ;;
  esac
  return 0
}

case $(champ tool_name) in
  Edit|Write)
    chemin=$(champ file_path)
    [ -n "$chemin" ] || exit 0
    chemin=$(absolu "$chemin" "$dossier")
    protege "$chemin" && demande "$chemin"
    ;;
  Bash)
    commande=$(champ command)
    commande=${commande//&&/$'\n'}; commande=${commande//||/$'\n'}
    commande=${commande//;/$'\n'}; commande=${commande//|/$'\n'}
    while IFS= read -r segment; do
      while IFS= read -r cible; do
        [ -n "$cible" ] || continue
        case $cible in
          cd$'\t'*) dossier=$(absolu "${cible#cd$'\t'}" "$dossier") ;;
          *) cible=$(absolu "$cible" "$dossier"); protege "$cible" && demande "$cible" ;;
        esac
      done < <(cibles "$segment")
    done <<< "$commande"
    ;;
esac
exit 0
