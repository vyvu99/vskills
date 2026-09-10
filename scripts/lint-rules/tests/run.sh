#!/usr/bin/env bash
# Fixture test runner for scripts/lint-rules/rules/*-candidate.sh
#
# For each scripts/lint-rules/tests/<rule-id>/ dir: invokes the matching
# rules/<rule-id>.sh directly against its bad.<ext> fixture (expect >=1 hit)
# and good.<ext> fixture (expect 0 hits). Bypasses production run.sh's
# filter_files_by_scope gate on purpose — this tests rule *logic* in
# isolation; fixture filenames are chosen per-rule to satisfy that rule's
# own filename gate, so the same condition production would check is still
# exercised (just not through filter_files_by_scope itself).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/../rules"
FAIL=0

# Runs one rule script against one fixture file (cwd = fixture's dir so
# filename-gate regexes in the rule see the same relative path production
# would pass) and prints PASS/FAIL based on hit count vs expectation.
check_fixture() {
  local rule_id="$1" kind="$2" rule_script="$3" fixture_dir="$4" fixture_name="$5" expect="$6"
  local hits
  hits=$(cd "$fixture_dir" && bash "$rule_script" "$fixture_name" 2>/dev/null | grep -c .)
  if { [[ "$expect" == "some" && "$hits" -ge 1 ]] || [[ "$expect" == "none" && "$hits" -eq 0 ]]; }; then
    printf 'PASS  %s [%s]  (%s hit(s))\n' "$rule_id" "$kind" "$hits"
  else
    local expected_desc="0 hits"; [[ "$expect" == "some" ]] && expected_desc=">=1 hit"
    printf 'FAIL  %s [%s]  expected %s, got %s hit(s)\n' "$rule_id" "$kind" "$expected_desc" "$hits"
    FAIL=1
  fi
}

for dir in "$SCRIPT_DIR"/*/; do
  rule_id="$(basename "$dir")"
  rule_script="$RULES_DIR/$rule_id.sh"
  if [[ ! -f "$rule_script" ]]; then
    echo "SKIP  $rule_id (no matching rule script at $rule_script)"
    FAIL=1
    continue
  fi

  bad_file=$(find "$dir" -maxdepth 1 -type f -name 'bad*' | head -1)
  good_file=$(find "$dir" -maxdepth 1 -type f -name 'good*' | head -1)
  bad_name=$(basename "$bad_file")
  good_name=$(basename "$good_file")

  if [[ "$rule_id" == "shared-constant-maybe-redefined-candidate" ]]; then
    # This rule resolves packages/shared relative to `git rev-parse
    # --show-toplevel` at invocation time, not the scanned file — so it
    # must run inside a throwaway git repo with a fake shared package,
    # or it silently no-ops (0 hits) regardless of fixture content.
    sandbox=$(mktemp -d)
    git -C "$sandbox" init -q
    mkdir -p "$sandbox/packages/shared/src" "$sandbox/app"
    cp "$dir/shared-constants.ts" "$sandbox/packages/shared/src/constants.ts"
    cp "$bad_file" "$sandbox/app/$bad_name"
    cp "$good_file" "$sandbox/app/$good_name"
    check_fixture "$rule_id" bad "$rule_script" "$sandbox/app" "$bad_name" some
    check_fixture "$rule_id" good "$rule_script" "$sandbox/app" "$good_name" none
    rm -rf "$sandbox"
    continue
  fi

  check_fixture "$rule_id" bad "$rule_script" "$dir" "$bad_name" some
  check_fixture "$rule_id" good "$rule_script" "$dir" "$good_name" none
done

exit $FAIL
