#!/usr/bin/env bash
# Joint à la release <tag> du kit le fichier git-sdlc : le bin/git-sdlc du tag, sa variable
# VERSION égale au tag. C'est ce fichier qu'un poste installe. Lancé par
# .github/workflows/release.yml dans un clone qui contient le tag, gh authentifié.
# Propre au kit : scripts/deploy.sh ne copie ni ce script ni le workflow.
set -euo pipefail

erreur() { echo "scripts/release-asset.sh : $*" >&2; }

[ $# -eq 1 ] || { erreur "usage : scripts/release-asset.sh <tag>"; exit 2; }
tag=$1
if ! [[ $tag =~ ^[0-9]{2}\.[0-9]{2}\.[0-9]{2}(\.[0-9]+)?$ ]]; then
  echo "Tag $tag hors du format YY.MM.DD[.V] : aucun fichier joint."
  exit 0
fi

noms=$(gh release view "$tag" --json assets --jq '.assets[].name') \
  || { erreur "release $tag illisible"; exit 1; }
if printf '%s\n' "$noms" | grep -qx git-sdlc; then
  erreur "git-sdlc est déjà joint à la release $tag : rien n'est remplacé"
  exit 1
fi

dir=$(mktemp -d); trap 'rm -rf "$dir"' EXIT
git show "refs/tags/$tag:bin/git-sdlc" > "$dir/source" 2>/dev/null \
  || { erreur "bin/git-sdlc introuvable au tag $tag"; exit 1; }
n=$(grep -c '^VERSION=dev$' "$dir/source" || true)
[ "$n" = 1 ] || { erreur "bin/git-sdlc au tag $tag : ligne VERSION=dev attendue une fois, trouvée $n fois"; exit 1; }
sed "s/^VERSION=dev\$/VERSION=$tag/" "$dir/source" > "$dir/git-sdlc"
chmod +x "$dir/git-sdlc"
gh release upload "$tag" "$dir/git-sdlc"
echo "git-sdlc $tag joint à la release $tag."
