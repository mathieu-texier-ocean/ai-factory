#!/usr/bin/env bash
# Teste le contrôle « plan à côté de son intent, amont validé » de hooks/pre-commit dans un dépôt git temporaire.
set -u
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$here" rev-parse --show-toplevel)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

cd "$tmp" && git init -q . && git config user.email t@t && git config user.name t
mkdir templates hooks && cp "$repo_root/templates/intent.md" templates/ && cp "$repo_root/hooks/pre-commit" hooks/
git config core.hooksPath hooks
git add templates hooks && git -c core.hooksPath=/dev/null commit -qm init

fail=0
# place <fixture:destination>... : copie et stage chaque fixture.
place() {
  local p
  for p in "$@"; do
    mkdir -p "$(dirname "${p#*:}")"; cp "$here/fixtures/${p%%:*}" "${p#*:}"; git add "${p#*:}"
  done
}
# init <fixture:destination>... : dépôt vidé (hors hook et modèle d'intent), puis état initial commité sans hook.
init() {
  git ls-files -z | grep -zvxF -e hooks/pre-commit -e templates/intent.md | xargs -0 -r git rm -qf
  git clean -fdq
  place "$@"
  git -c core.hooksPath=/dev/null commit -qm "état initial" --allow-empty
}
# attempt <nom> <attendu: pass|block> [texte attendu dans le message]... : commite ce qui est stagé.
attempt() {
  local name=$1 expect=$2 m; shift 2
  out=$(git commit -qm "test" 2>&1); rc=$?
  ok=0
  if [ "$expect" = pass ] && [ $rc -eq 0 ]; then ok=1
  elif [ "$expect" = block ] && [ $rc -ne 0 ]; then
    ok=1
    for m in "$@"; do printf '%s' "$out" | grep -qF -- "$m" || ok=0; done
  fi
  git reset -q
  [ $ok -eq 1 ] && echo "PASS $name" || { echo "FAIL $name (rc=$rc) $out"; fail=1; }
}
# check <nom> <attendu> <message|-> <état initial>... : état initial, puis commit d'un nouveau lot/plan.md.
check() {
  local name=$1 expect=$2 msg=$3; shift 3
  init "$@"; place plan-modele.md:lot/plan.md
  if [ "$msg" = - ]; then attempt "$name" "$expect"; else attempt "$name" "$expect" "$msg"; fi
}
iv=intent-valide.md:lot/intent.md
id=intent-draft.md:lot/intent.md

# Amont dans HEAD.
check "sans intent, spec validée (A1, L1)"   block "lot/plan.md : intent absent (lot/intent.md)" spec-valide.md:lot/spec.md
check "spec draft (A2)"                      block "lot/plan.md : spec non validée (statut : draft)" $iv spec-draft.md:lot/spec.md
check "spec validée (A3)"                    pass  - $iv spec-valide.md:lot/spec.md
check "intent draft, spec validée (L3)"      pass  - $id spec-valide.md:lot/spec.md
check "sans spec, intent draft (A8)"         block "lot/plan.md : intent non validé (statut : draft)" $id
check "sans spec, intent validé ligne seule (A9)"  pass - $iv
check "sans spec, intent validé ligne auteur (A9)" pass - intent-valide-auteur.md:lot/intent.md
check "casse Validé (L7)"                    block "lot/plan.md : intent non validé (statut : Validé)" intent-statut-majuscule.md:lot/intent.md
check "intent sans statut (L8)"              block "lot/plan.md : intent non validé (statut : absent)" intent-sans-statut.md:lot/intent.md
check "spec sans statut (L8)"                block "lot/plan.md : spec non validée (statut : absent)" $iv spec-sans-statut.md:lot/spec.md

init; place plan-modele.md:plan.md
attempt "plan à la racine sans intent (L2)" block "plan.md : intent absent (intent.md)"

# Amont dans le commit en cours : l'index prime sur HEAD.
init $iv spec-valide.md:lot/spec.md; place spec-draft.md:lot/spec.md plan-modele.md:lot/plan.md
attempt "spec repassée en draft dans le même commit (L4)" block "lot/plan.md : spec non validée (statut : draft)"
init $iv; place spec-draft.md:lot/spec.md plan-modele.md:lot/plan.md
attempt "spec draft et plan dans le même commit (A4)" block "lot/plan.md : spec non validée (statut : draft)"
init $iv; place spec-valide.md:lot/spec.md plan-modele.md:lot/plan.md
attempt "spec validée et plan dans le même commit (A5)" pass
init; place $id plan-modele.md:lot/plan.md
attempt "intent draft et plan dans le même commit (A6)" block "lot/plan.md : intent non validé (statut : draft)"
init; place $iv plan-modele.md:lot/plan.md
attempt "intent validé et plan dans le même commit (A7)" pass
init $id; place $iv plan-modele.md:lot/plan.md
attempt "intent passé à validé dans le même commit (L5)" pass
init $iv; git rm -q lot/intent.md; place plan-modele.md:lot/plan.md
attempt "intent supprimé dans le commit du plan (L20)" block "lot/plan.md : intent absent (lot/intent.md)"
init $iv spec-valide.md:lot/spec.md; git rm -q lot/spec.md; place plan-modele.md:lot/plan.md
attempt "spec supprimée, intent validé (L21)" pass
init $id spec-valide.md:lot/spec.md; git rm -q lot/spec.md; place plan-modele.md:lot/plan.md
attempt "spec supprimée, intent draft (L21)" block "lot/plan.md : intent non validé (statut : draft)"

# Renommages.
init $iv plan-modele.md:lot/plan.md intent-draft.md:lot2/intent.md; git mv lot/plan.md lot2/plan.md
attempt "git mv vers un amont draft (A10, L9)" block "lot2/plan.md : intent non validé (statut : draft)"
init $id plan-modele.md:lot/brouillon.md; git mv lot/brouillon.md lot/plan.md
attempt "autre fichier renommé en plan.md (L10)" block "lot/plan.md : intent non validé (statut : draft)"
init $iv plan-modele.md:lot/plan.md intent-draft.md:lot2/intent.md; git mv lot/plan.md lot2/plan.md
printf 'Contenu\nentièrement\nremplacé\n' > lot2/plan.md; git add lot2/plan.md
attempt "renommage sous le seuil de similarité (L11)" block "lot2/plan.md : intent non validé (statut : draft)"
init $id plan-modele.md:lot/plan.md; git mv lot/plan.md lot/notes.md
attempt "renommage sortant non contrôlé (L12)" pass
init $id plan-modele.md:lot/plan.md; git rm -q lot/plan.md
attempt "suppression non contrôlée (L12)" pass
init $id plan-modele.md:lot/plan.md; printf '\nRévision.\n' >> lot/plan.md; git add lot/plan.md
attempt "modification d'un plan commité (L13)" pass

# Exclusions et noms.
init; place plan-modele.md:templates/plan.md
attempt "modèle templates/plan.md ignoré (A11, L14)" pass
init; place plan-modele.md:hooks/tests/x/fixtures/plan.md
attempt "fixture hooks/tests/x/fixtures/ ignorée (A11, L16)" pass
init; place plan-modele.md:tests/x/fixtures/plan.md
attempt "fixture tests/x/fixtures/ à la racine ignorée (A11, L16)" pass
init; place plan-modele.md:lot/templates/plan.md
attempt "plan sous lot/templates/ contrôlé (L15)" block "lot/templates/plan.md : intent absent (lot/templates/intent.md)"
init; place plan-modele.md:a/Plan.md plan-modele.md:b/plan.MD plan-modele.md:c/mon-plan.md
attempt "Plan.md, plan.MD, mon-plan.md non contrôlés (L17)" pass
init "intent-valide.md:lot é x/intent.md"; place "plan-modele.md:lot é x/plan.md"
attempt "dossier accentué avec espace, intent validé (L18)" pass
init "intent-draft.md:lot é x/intent.md"; place "plan-modele.md:lot é x/plan.md"
attempt "dossier accentué avec espace, intent draft (L18)" block "lot é x/plan.md : intent non validé (statut : draft)"
init $id intent-draft.md:lot2/intent.md; place plan-modele.md:lot/plan.md plan-modele.md:lot2/plan.md
attempt "deux plans refusés, deux lignes (L19)" block "lot/plan.md : intent non validé (statut : draft)" "lot2/plan.md : intent non validé (statut : draft)"
exit $fail
