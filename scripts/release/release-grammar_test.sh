#!/usr/bin/env bash
# Table-driven tests for scripts/release/release-grammar.sh.
#
# These tests invoke the REAL script by path — the same entry point the
# workflows call — so a passing run proves the production grammar, not a copy
# of it. Run locally with:
#
#   scripts/release/release-grammar_test.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HERE
readonly GRAMMAR="${HERE}/release-grammar.sh"

failures=0
checks=0

# expect_ok <subcommand> <input> <expected-version> <expected-kind>
expect_ok() {
  local subcommand="$1" input="$2" want_version="$3" want_kind="$4"
  local output status
  checks=$((checks + 1))
  output="$("$GRAMMAR" "$subcommand" "$input" 2>&1)"
  status=$?
  if [ "$status" -ne 0 ]; then
    printf 'FAIL %s %q: expected success, got exit %d\n%s\n' \
      "$subcommand" "$input" "$status" "$output"
    failures=$((failures + 1))
    return
  fi
  # The output is appended verbatim to $GITHUB_OUTPUT by every caller, so its
  # exact shape is a security property, not a cosmetic one: three lines, no
  # more. A fourth line would mean a crafted input had smuggled an extra
  # workflow output past the grammar.
  local line_count
  line_count="$(printf '%s\n' "$output" | wc -l)"
  if [ "$line_count" -ne 3 ]; then
    printf 'FAIL %s %q: expected exactly 3 output lines, got %s:\n%s\n' \
      "$subcommand" "$input" "$line_count" "$output"
    failures=$((failures + 1))
    return
  fi
  local got_version got_tag got_kind
  got_version="$(printf '%s\n' "$output" | sed -n 's/^version=//p')"
  got_tag="$(printf '%s\n' "$output" | sed -n 's/^tag=//p')"
  got_kind="$(printf '%s\n' "$output" | sed -n 's/^kind=//p')"
  # tag= is what release-tag.yml actually passes to `git tag`, so it is pinned
  # here too: version= alone would leave the git-facing half of the contract
  # untested.
  if [ "$got_version" != "$want_version" ] \
     || [ "$got_tag" != "v${want_version}" ] \
     || [ "$got_kind" != "$want_kind" ]; then
    printf 'FAIL %s %q: want version=%s tag=v%s kind=%s, got version=%s tag=%s kind=%s\n' \
      "$subcommand" "$input" "$want_version" "$want_version" "$want_kind" \
      "$got_version" "$got_tag" "$got_kind"
    failures=$((failures + 1))
  fi
}

# expect_reject_fix <subcommand> <input> <expected-fix-substring>
#
# Stronger than expect_reject: pins the ACTUAL remedy text for a specific rule,
# so a refactor cannot silently degrade a precise diagnosis into a generic one
# while still technically emitting a "fix:" line.
expect_reject_fix() {
  local subcommand="$1" input="$2" want_fix="$3"
  local output status
  checks=$((checks + 1))
  output="$("$GRAMMAR" "$subcommand" "$input" 2>&1)"
  status=$?
  if [ "$status" -eq 0 ]; then
    printf 'FAIL %s %q: expected rejection, but it was accepted:\n%s\n' \
      "$subcommand" "$input" "$output"
    failures=$((failures + 1))
    return
  fi
  if ! printf '%s' "$output" | grep -qF -- "$want_fix"; then
    printf 'FAIL %s %q: rejection did not carry the expected remedy %q:\n%s\n' \
      "$subcommand" "$input" "$want_fix" "$output"
    failures=$((failures + 1))
  fi
}

# expect_reject <subcommand> <input>
expect_reject() {
  local subcommand="$1" input="$2"
  local output status
  checks=$((checks + 1))
  output="$("$GRAMMAR" "$subcommand" "$input" 2>&1)"
  status=$?
  if [ "$status" -eq 0 ]; then
    printf 'FAIL %s %q: expected rejection, but it was accepted:\n%s\n' \
      "$subcommand" "$input" "$output"
    failures=$((failures + 1))
    return
  fi
  # An actionable rejection must say what to do about it, not just "invalid".
  if ! printf '%s' "$output" | grep -q '  fix: '; then
    printf 'FAIL %s %q: rejection is not actionable (no fix: line):\n%s\n' \
      "$subcommand" "$input" "$output"
    failures=$((failures + 1))
  fi
}

# ── Accepted titles ──────────────────────────────────────────────────────
expect_ok parse-title 'release(v0.1.0): first immutable aggregate'   0.1.0      final
expect_ok parse-title 'release(v0.1.0-rc1): first candidate'         0.1.0-rc1  rc
expect_ok parse-title 'release(v1.2.3): ship it'                     1.2.3      final
expect_ok parse-title 'release(v10.20.30-rc42): big numbers'         10.20.30-rc42 rc
expect_ok parse-title 'release(v0.0.0): zero components are canonical' 0.0.0    final
# Widest numeric component the producer's 64-bit parser can take (17 digits).
expect_ok parse-title 'release(v99999999999999999.0.0): widest accepted major' 99999999999999999.0.0 final
expect_ok parse-title 'release(v0.1.0-rc99999999999999999): widest accepted rc' 0.1.0-rc99999999999999999 rc

# ── Accepted tags ────────────────────────────────────────────────────────
expect_ok parse-tag 'v0.1.0'      0.1.0     final
expect_ok parse-tag 'v0.1.0-rc1'  0.1.0-rc1 rc
expect_ok parse-tag 'v10.20.30'   10.20.30  final

# ── Rejected titles ──────────────────────────────────────────────────────
expect_reject parse-title ''
expect_reject parse-title 'feat(release): not a release PR'
expect_reject parse-title 'release(v0.1.0)'                    # no summary
expect_reject parse-title 'release(v0.1.0): '                  # blank summary
expect_reject parse-title 'release(0.1.0): missing leading v'
expect_reject parse-title 'release(v0.1): not three components'
expect_reject parse-title 'release(v0.1.0.1): four components'
expect_reject parse-title 'release(v01.1.0): leading zero major'
expect_reject parse-title 'release(v0.01.0): leading zero minor'
expect_reject parse-title 'release(v0.1.00): leading zero patch'
expect_reject parse-title 'release(v0.1.0-rc0): rc must start at 1'
expect_reject parse-title 'release(v0.1.0-rc01): leading zero rc'
expect_reject parse-title 'release(v0.1.0-rc): rc needs a number'
expect_reject parse-title 'release(v0.1.0-beta1): only rc prereleases'
expect_reject parse-title 'release(v0.1.0+build1): build metadata rejected'
expect_reject parse-title 'release(pasture-stable): moving aliases are not releases'
expect_reject parse-title 'Release(v0.1.0): capitalised prefix'
# 18 digits would overflow the producer's 64-bit component parser, so the
# grammar must refuse it HERE rather than letting it through to a tag that the
# producer would then reject at build time.
expect_reject parse-title 'release(v100000000000000000.0.0): 18-digit major overflows'
expect_reject parse-title 'release(v0.1.0-rc100000000000000000): 18-digit rc overflows'
# A colon with no following space is not the release grammar.
expect_reject parse-title 'release(v0.1.0):no space after the colon'
# A newline in the title must never be accepted: the script's output is
# appended straight to $GITHUB_OUTPUT, so an accepted multi-line title would
# let a PR author inject arbitrary extra workflow outputs.
expect_reject_fix parse-title 'release(v0.1.0): summary
kind=final' 'single line'
expect_reject parse-title 'release(v0.1.0): summary
version=9.9.9'
expect_reject parse-tag 'v0.1.0
kind=final'

# ── Rejections must name the ACTUAL remedy, not a generic one ────────────
expect_reject_fix parse-title 'release(v0.1.0):    ' \
  'describe the release after the colon'
expect_reject_fix parse-title 'release(v01.1.0): leading zero major' \
  'no leading zero'
expect_reject_fix parse-title 'chore: not a release at all' \
  'the accepted grammar is release(vMAJOR.MINOR.PATCH): <summary>'

# ── Rejected tags ────────────────────────────────────────────────────────
expect_reject parse-tag ''
expect_reject parse-tag '0.1.0'
expect_reject parse-tag 'v0.1.0+build1'
expect_reject parse-tag 'v0.1.0-rc0'
expect_reject parse-tag 'pasture-stable'
expect_reject parse-tag 'v0.1.0 '
expect_reject parse-tag 'v100000000000000000.0.0'
expect_reject_fix parse-tag 'v0.1.0-beta1' \
  'release(vMAJOR.MINOR.PATCH-rcN)'

# ── Rejected invocations ─────────────────────────────────────────────────
checks=$((checks + 1))
if "$GRAMMAR" >/dev/null 2>&1; then
  printf 'FAIL: expected a bare invocation with no arguments to be rejected\n'
  failures=$((failures + 1))
fi
checks=$((checks + 1))
if "$GRAMMAR" parse-nothing 'v0.1.0' >/dev/null 2>&1; then
  printf 'FAIL: expected an unknown subcommand to be rejected\n'
  failures=$((failures + 1))
fi

if [ "$failures" -ne 0 ]; then
  printf '\n%d of %d checks FAILED\n' "$failures" "$checks"
  exit 1
fi
printf 'all %d release-grammar checks passed\n' "$checks"
