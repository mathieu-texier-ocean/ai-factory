#!/usr/bin/env bash
# Teste le contrôle des credentials de hooks/pre-commit dans un dépôt git temporaire.
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
fx="$here/fixtures"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

cd "$tmp" && git init -q . && git config user.email t@t && git config user.name t
mkdir templates hooks && cp "$repo_root/templates/intent.md" templates/ && cp "$repo_root/hooks/pre-commit" hooks/
git config core.hooksPath hooks
git add templates hooks && git -c core.hooksPath=/dev/null commit -qm init
base=$(git rev-parse HEAD)

fail=0
out=""
# sans_hook <message> : commite l'index sans passer par le hook (état initial d'un cas).
sans_hook() { git -c core.hooksPath=/dev/null commit -qm "$1"; }
# cp_fx <fixture> <cible> : copie une fixture et l'indexe.
cp_fx() { mkdir -p "$(dirname "$2")"; cp "$fx/$1" "$2"; git add -- "$2"; }
# essai <nom> <attendu: pass|block> [texte attendu dans le message]... : tente le commit de l'index.
essai() {
  local name=$1 expect=$2 ok=1 rc t; shift 2
  out=$(git commit -qm test 2>&1); rc=$?
  if [ "$expect" = pass ]; then [ $rc -eq 0 ] || ok=0
  else
    [ $rc -ne 0 ] || ok=0
    for t in "$@"; do printf '%s' "$out" | grep -qF -- "$t" || ok=0; done
  fi
  [ $ok -eq 1 ] && echo "PASS $name" || { echo "FAIL $name (rc=$rc) $out"; fail=1; }
  git reset -q --hard "$base"; git clean -qfdx
}
# absent <nom> <texte> : le texte n'apparaît pas dans la sortie du dernier essai.
absent() {
  if printf '%s' "$out" | grep -qF -- "$2"; then echo "FAIL $1 : « $2 » affiché"; fail=1
  else echo "PASS $1"; fi
}

msg="credential en clair"

cp_fx cle-privee.txt cle-privee.txt
essai "clé privée bloquée (A1)" block "cle-privee.txt : $msg (clé privée)" "Retirez la valeur" "révoquez-la" "credential-ok"

for f in aws github anthropic slack; do
  cp_fx "$f.txt" "$f.txt"
  essai "jeton $f bloqué" block "$f.txt : $msg (jeton fournisseur)"
done

cp_fx aws.txt aws.txt
essai "jeton AWS bloqué, valeur cachée" block "aws.txt : $msg"
absent "valeur jamais affichée (C7)" "AKIAIOSFODNN7EXAMPLE"

cp_fx affectation.txt affectation.txt
essai "affectation littérale bloquée" block "affectation.txt : $msg (affectation générique)"
absent "valeur d'affectation jamais affichée (C7)" "fictif-0000-EXAMPLE"

cp_fx affectation-guillemets.txt affectation-guillemets.txt
essai "affectation littérale entre guillemets bloquée" block "affectation-guillemets.txt : $msg (affectation générique)"

cp_fx affectation-reference.txt affectation-reference.txt
essai "affectation par référence acceptée (L15)" pass

cp_fx url.txt url.txt
essai "URL avec identifiants bloquée" block "url.txt : $msg (URL avec identifiants)"

cp_fx propre.txt propre.txt
essai "sans credential accepté (A2)" pass

cp_fx affectation.txt affectation.txt && sans_hook "état initial"
echo "ligne propre" >> affectation.txt && git add affectation.txt
essai "ligne déjà dans HEAD acceptée (L1)" pass

cp "$fx/aws.txt" aws.txt
cp_fx propre.txt propre.txt
essai "credential non indexé accepté (L2, L3)" pass

cp_fx aws.txt aws.txt && sans_hook "état initial"
git rm -q aws.txt
essai "fichier supprimé accepté (L4)" pass

cp_fx aws.txt aws.txt
cp_fx url.txt url.txt
essai "deux fichiers, les deux nommés (L5)" block "aws.txt : $msg" "url.txt : $msg"

cp_fx annote.txt annote.txt
essai "ligne annotée acceptée (L9)" pass

cp_fx annote.txt annote.txt
cp_fx aws.txt aws.txt
essai "annotation + autre bloqué (L10)" block "aws.txt : $msg"
absent "fichier annoté non nommé (L10)" "annote.txt"

cp_fx binaire.bin binaire.bin
essai "binaire accepté (L11)" pass

cp_fx intent-incomplet.md lot/intent.md
cp_fx aws.txt aws.txt
essai "cumul avec le contrôle des intents (C9)" block "lot/intent.md : section(s) obligatoire(s) manquante(s)" "aws.txt : $msg"

cp_fx propre.txt a/propre.txt && sans_hook "état initial"
git mv a b && cat "$fx/affectation.txt" >> b/propre.txt && git add b/propre.txt
essai "renommé avec credential ajouté bloqué (L12)" block "b/propre.txt : $msg"

cat "$fx/affectation.txt" "$fx/propre.txt" > f.txt && mkdir a && mv f.txt a/ && git add a && sans_hook "état initial"
git mv a b
essai "renommé sans ajout accepté (L13)" pass

cp_fx aws.txt "dossier é/clé é.txt"
essai "nom accentué avec espace nommé en clair (L14)" block "dossier é/clé é.txt : $msg"

exit $fail
