#!/usr/bin/env bash
# Teste le contrôle des credentials de .githooks/pre-commit dans un dépôt git temporaire.
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
fx="$here/fixtures"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

cd "$tmp" && git init -q . && git config user.email t@t && git config user.name t
mkdir -p intent/_template .githooks/lib
cp "$repo_root/intent/_template/intent.md" intent/_template/
cp "$repo_root/.githooks/pre-commit" .githooks/ && cp "$repo_root/.githooks/lib/credential.sh" .githooks/lib/
git config core.hooksPath .githooks
git add -A && git -c core.hooksPath=/dev/null commit -qm init
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
# Les valeurs sont lues dans les fixtures : aucune n'est écrite dans ce script.
absent() {
  if [ -z "$2" ]; then echo "FAIL $1 : valeur à chercher vide"; fail=1
  elif printf '%s' "$out" | grep -qF -- "$2"; then echo "FAIL $1 : « $2 » affiché"; fail=1
  else echo "PASS $1"; fi
}

msg="credential en clair"

cp_fx cle-privee.txt cle-privee.txt
essai "clé privée bloquée" block "cle-privee.txt : $msg (clé privée)" "Retirez la valeur" "révoquez-la" "credential-ok"

for f in aws github anthropic slack; do
  cp_fx "$f.txt" "$f.txt"
  essai "jeton $f bloqué" block "$f.txt : $msg (jeton fournisseur)"
done

cp_fx aws.txt aws.txt
essai "jeton AWS bloqué, valeur cachée" block "aws.txt : $msg"
absent "valeur jamais affichée" "$(grep -oE 'AKIA[A-Z0-9]+' "$fx/aws.txt")"

cp_fx affectation.txt affectation.txt
essai "affectation littérale bloquée" block "affectation.txt : $msg (affectation générique)"
absent "valeur d'affectation jamais affichée" "$(grep -m1 = "$fx/affectation.txt" | cut -d= -f2-)"

cp_fx affectation-guillemets.txt affectation-guillemets.txt
essai "affectation littérale entre guillemets bloquée" block "affectation-guillemets.txt : $msg (affectation générique)"

cp_fx affectation-reference.txt affectation-reference.txt
essai "affectation par référence acceptée" pass

cp_fx url.txt url.txt
essai "URL avec identifiants bloquée" block "url.txt : $msg (URL avec identifiants)"

cp_fx propre.txt propre.txt
essai "sans credential accepté" pass

cp_fx affectation.txt affectation.txt && sans_hook "état initial"
echo "ligne propre" >> affectation.txt && git add affectation.txt
essai "ligne déjà dans HEAD acceptée" pass

cp "$fx/aws.txt" aws.txt
cp_fx propre.txt propre.txt
essai "credential non indexé accepté" pass

cp_fx aws.txt aws.txt && sans_hook "état initial"
git rm -q aws.txt
essai "fichier supprimé accepté" pass

cp_fx aws.txt aws.txt
cp_fx url.txt url.txt
essai "deux fichiers, les deux nommés" block "aws.txt : $msg" "url.txt : $msg"

cp_fx annote.txt annote.txt
essai "ligne annotée acceptée" pass

cp_fx annote.txt annote.txt
cp_fx aws.txt aws.txt
essai "annotation + autre bloqué" block "aws.txt : $msg"
absent "fichier annoté non nommé" "annote.txt"

cp_fx binaire.bin binaire.bin
essai "binaire accepté" pass

cp_fx intent-incomplet.md intent/b/intent.md
cp_fx aws.txt aws.txt
essai "cumul avec le contrôle des intents" block "intent/b/intent.md : section(s) obligatoire(s) manquante(s)" "aws.txt : $msg"

cp_fx propre.txt a/propre.txt && sans_hook "état initial"
git mv a b && cat "$fx/affectation.txt" >> b/propre.txt && git add b/propre.txt
essai "renommé avec credential ajouté bloqué" block "b/propre.txt : $msg"

cat "$fx/affectation.txt" "$fx/propre.txt" > f.txt && mkdir a && mv f.txt a/ && git add a && sans_hook "état initial"
git mv a b
essai "renommé sans ajout accepté" pass

cp_fx aws.txt "dossier é/clé é.txt"
essai "nom accentué avec espace nommé en clair" block "dossier é/clé é.txt : $msg"

cp_fx aws.txt .githooks/tests/x/fixtures/aws.txt
essai "fixture sous .githooks/tests/<nom>/fixtures/ acceptée" pass

cp_fx aws.txt tests/x/fixtures/aws.txt
essai "fixture sous tests/<nom>/fixtures/ à la racine acceptée" pass

cp_fx aws.txt .githooks/tests/x/fixtures/aws.txt && sans_hook "état initial"
cat "$fx/slack.txt" >> .githooks/tests/x/fixtures/aws.txt && git add .githooks/tests/x/fixtures/aws.txt
essai "fixture modifiée acceptée" pass

cp_fx aws.txt fixtures/aws.txt
essai "fixtures/ hors d'un dossier tests/ contrôlé" block "fixtures/aws.txt : $msg"

cp_fx aws.txt tests/fixtures/aws.txt
essai "tests/fixtures/ sans dossier <nom> contrôlé" block "tests/fixtures/aws.txt : $msg"

cat "$fx/aws.txt" "$fx/propre.txt" > f.txt && mkdir -p tests/x/fixtures && mv f.txt tests/x/fixtures/ && git add tests && sans_hook "état initial"
mkdir doc && git mv tests/x/fixtures/f.txt doc/f.txt
essai "fixture déplacée hors de fixtures/ sans modification acceptée" pass

exit $fail
