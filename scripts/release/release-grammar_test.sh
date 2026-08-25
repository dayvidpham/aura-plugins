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

# ── The pinned Pasture's own version, and the compatibility range ────────
#
# installer_min is derived from the pinned Pasture binary's self-reported
# version and is frozen into an immutable manifest, so both halves of the
# derivation are pinned here: WHICH reported versions are accepted, and WHAT
# the two emitted bounds are.

# expect_compat_ok <reported> <expected-min>
#
# Asserts the accepted derivation exactly: two lines, no more (the output is
# appended verbatim to $GITHUB_OUTPUT), the minimum taken from the reported
# version, and the ceiling equal to the open-ceiling constant.
expect_compat_ok() {
  local reported="$1" want_min="$2"
  local output status
  checks=$((checks + 1))
  output="$("$GRAMMAR" installer-compatibility "$reported" 2>&1)"
  status=$?
  if [ "$status" -ne 0 ]; then
    printf 'FAIL installer-compatibility %q: expected success, got exit %d\n%s\n' \
      "$reported" "$status" "$output"
    failures=$((failures + 1))
    return
  fi
  local line_count
  line_count="$(printf '%s\n' "$output" | wc -l)"
  if [ "$line_count" -ne 2 ]; then
    printf 'FAIL installer-compatibility %q: expected exactly 2 output lines, got %s:\n%s\n' \
      "$reported" "$line_count" "$output"
    failures=$((failures + 1))
    return
  fi
  local got_min got_max
  got_min="$(printf '%s\n' "$output" | sed -n 's/^installer_min=//p')"
  got_max="$(printf '%s\n' "$output" | sed -n 's/^installer_max=//p')"
  # The ceiling is asserted as a literal, not read back from the script: the
  # value is published into immutable manifests, so a change to it must break
  # this test and be made deliberately. It is the open ceiling — the manifest
  # SCHEMA is the real upper guard — so it is never the pinned Pasture version.
  if [ "$got_min" != "$want_min" ] || [ "$got_max" != '0.99.99' ]; then
    printf 'FAIL installer-compatibility %q: want installer_min=%s installer_max=0.99.99, got installer_min=%s installer_max=%s\n' \
      "$reported" "$want_min" "$got_min" "$got_max"
    failures=$((failures + 1))
    return
  fi
  # The ceiling must not track the floor, or the range would be closed at
  # whatever version happens to be pinned and every future installer would be
  # locked out of an aggregate it can activate perfectly well.
  if [ "$got_max" = "$got_min" ]; then
    printf 'FAIL installer-compatibility %q: the ceiling collapsed onto the floor (%s)\n' \
      "$reported" "$got_max"
    failures=$((failures + 1))
  fi
}

expect_compat_ok 'pasture version v0.1.0' '0.1.0'
expect_compat_ok 'pasture version v1.2.3' '1.2.3'
expect_compat_ok 'pasture version v10.0.99' '10.0.99'

# A development build must never become a published compatibility floor: it
# names no Pasture release, so the claim could never be checked by a consumer.
# These are shapes a devel build may plausibly print; none is enumerated by the
# script, which accepts only the released shape and refuses everything else.
expect_reject_fix installer-compatibility 'pasture version v0.1.0-devel' \
  'an aggregate cannot be cut against an untagged Pasture'
expect_reject_fix installer-compatibility 'pasture version v0.1.0-devel+9f3a2c1' \
  'an aggregate cannot be cut against an untagged Pasture'
expect_reject_fix installer-compatibility 'pasture version devel' \
  'an aggregate cannot be cut against an untagged Pasture'
expect_reject_fix installer-compatibility 'pasture version v0.1.0-9-g9f3a2c1' \
  'an aggregate cannot be cut against an untagged Pasture'
expect_reject_fix installer-compatibility 'pasture version unknown' \
  'an aggregate cannot be cut against an untagged Pasture'

# A release candidate is a real tag, but not a floor every stable installer can
# satisfy, so it is refused with the same remedy.
expect_reject_fix installer-compatibility 'pasture version v0.1.0-rc1' \
  'it must be a final release'

# Shapes that are not a released version for other reasons.
expect_reject installer-compatibility ''
expect_reject installer-compatibility 'pasture version 0.1.0'
expect_reject installer-compatibility 'v0.1.0'
expect_reject installer-compatibility '0.1.0'
expect_reject installer-compatibility 'pasture version v0.1'
expect_reject installer-compatibility 'pasture version v0.1.0 (linux/amd64)'
expect_reject installer-compatibility 'pasture version v01.1.0'
expect_reject installer-compatibility 'pasture version v0.1.0+build1'
expect_reject installer-compatibility 'pasture version v100000000000000000.0.0'
# Multi-line output: an anchored POSIX regex matches the end of the whole
# string, not of a line, so a smuggled second line cannot slip a third
# KEY=VALUE pair into $GITHUB_OUTPUT.
expect_reject installer-compatibility 'pasture version v0.1.0
installer_max=0.0.1'

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
