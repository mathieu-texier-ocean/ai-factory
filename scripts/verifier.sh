#!/usr/bin/env bash
# Lance tous les run.sh du dépôt (hors .git/) et résume le résultat.
# Échoue si l'un d'eux échoue, si aucun n'est trouvé ou hors de la racine du dépôt.
set -u

racine=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$racine" ]; then
  echo "scripts/verifier.sh : à lancer depuis la racine du dépôt : scripts/verifier.sh" >&2
  exit 1
fi
if [ "$(pwd -P)" != "$racine" ]; then
  echo "scripts/verifier.sh : à lancer depuis la racine du dépôt : cd $racine && scripts/verifier.sh" >&2
  exit 1
fi

runs=()
while IFS= read -r f; do runs+=("$f"); done < <(
  find . -name .git -prune -o -type f -name run.sh -print | sed 's|^\./||' | LC_ALL=C sort
)
if [ "${#runs[@]}" -eq 0 ]; then
  echo "scripts/verifier.sh : aucun run.sh trouvé dans le dépôt" >&2
  exit 1
fi

echecs=()
for f in "${runs[@]}"; do
  echo "== $f"
  bash "$f"; rc=$?
  if [ $rc -ne 0 ]; then
    echo "ÉCHEC $f (code $rc)"
    echecs+=("$f")
  else
    echo "OK $f"
  fi
done

echo
echo "${#runs[@]} run.sh lancés, ${#echecs[@]} en échec"
if [ "${#echecs[@]}" -gt 0 ]; then
  for f in "${echecs[@]}"; do echo "$f"; done
  exit 1
fi
exit 0
