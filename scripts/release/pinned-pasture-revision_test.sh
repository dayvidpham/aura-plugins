#!/usr/bin/env bash
# Tests for scripts/release/pinned-pasture-revision.sh.
#
# These invoke the REAL script by path — the same entry point gates.yml and
# release.yml call — over synthetic lock files, plus the repository's own
# flake.lock, so the check that gates every release is exercised against the
# thing it actually reads.
#
#   scripts/release/pinned-pasture-revision_test.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HERE
readonly SCRIPT="${HERE}/pinned-pasture-revision.sh"
# The repository's real lock file. Overridable because the nix check runs this
# suite from a store copy of scripts/release/ alone, where the repository tree
# is not reachable — but it is never optional: the case below is the only one
# that exercises the lock every release actually reads.
readonly REPO_LOCK="${AURA_FLAKE_LOCK:-${HERE}/../../flake.lock}"

readonly REV='0123456789abcdef0123456789abcdef01234567'

failures=0
checks=0

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# lock <name> <locked-node-json>
lock() {
  local path="${work}/$1.lock"
  jq -n --argjson locked "$2" '{nodes: {pasture: {locked: $locked}}}' > "$path"
  printf '%s\n' "$path"
}

readonly GOOD="{\"type\":\"github\",\"owner\":\"dayvidpham\",\"repo\":\"pasture\",\"rev\":\"${REV}\"}"

expect_revision() {
  local label="$1" path="$2" want="$3"
  local output status
  checks=$((checks + 1))
  output="$("$SCRIPT" "$path" 2>/dev/null)"
  status=$?
  if [ "$status" -ne 0 ]; then
    printf 'FAIL %s: expected the revision, got exit %d\n' "$label" "$status"
    failures=$((failures + 1))
    return
  fi
  if [ "$output" != "$want" ]; then
    printf 'FAIL %s: printed %q, want %q\n' "$label" "$output" "$want"
    failures=$((failures + 1))
  fi
}

# expect_reject <label> <substring-of-the-diagnosis> <path>
#
# The diagnosis is read from stderr alone: stdout carries the revision, and a
# check that matched both streams could be satisfied by the very value the
# script is supposed to have refused to print.
expect_reject() {
  local label="$1" want="$2" path="$3"
  local diagnosis status
  checks=$((checks + 1))
  "$SCRIPT" "$path" > "${work}/stdout" 2> "${work}/stderr"
  status=$?
  diagnosis="$(cat "${work}/stderr")"
  if [ "$status" -eq 0 ]; then
    printf 'FAIL %s: expected rejection, got acceptance (%s)\n' "$label" "$(cat "${work}/stdout")"
    failures=$((failures + 1))
    return
  fi
  if [ -s "${work}/stdout" ]; then
    printf 'FAIL %s: refused, but still printed a revision on stdout: %s\n' "$label" "$(cat "${work}/stdout")"
    failures=$((failures + 1))
  fi
  if ! grep -qF "$want" <<< "$diagnosis"; then
    printf 'FAIL %s: diagnosis does not mention %q\n%s\n' "$label" "$want" "$diagnosis"
    failures=$((failures + 1))
    return
  fi
  if ! grep -q '^  fix: ' <<< "$diagnosis"; then
    printf 'FAIL %s: diagnosis carries no fix line\n%s\n' "$label" "$diagnosis"
    failures=$((failures + 1))
  fi
}

expect_revision 'canonical github pin' "$(lock good "$GOOD")" "$REV"

# The repository's own lock is what every release actually reads.
checks=$((checks + 1))
revision_output="$("$SCRIPT" "$REPO_LOCK")"
if ! grep -Eq '^[0-9a-f]{40}$' <<< "$revision_output"; then
  printf 'FAIL repository flake.lock (%s): the pinned pasture revision could not be read\n' "$REPO_LOCK"
  failures=$((failures + 1))
fi

expect_reject 'input is a local path override' 'type' \
  "$(lock path-input "{\"type\":\"path\",\"owner\":\"dayvidpham\",\"repo\":\"pasture\",\"rev\":\"${REV}\"}")"
expect_reject 'input is a fork' 'owner' \
  "$(lock fork "{\"type\":\"github\",\"owner\":\"someone-else\",\"repo\":\"pasture\",\"rev\":\"${REV}\"}")"
expect_reject 'input is a different repository' 'repo' \
  "$(lock other-repo "{\"type\":\"github\",\"owner\":\"dayvidpham\",\"repo\":\"not-pasture\",\"rev\":\"${REV}\"}")"
expect_reject 'no revision' '40-character' \
  "$(lock no-rev '{"type":"github","owner":"dayvidpham","repo":"pasture"}')"
expect_reject 'branch instead of a revision' '40-character' \
  "$(lock branch '{"type":"github","owner":"dayvidpham","repo":"pasture","rev":"main"}')"
expect_reject 'uppercase revision' '40-character' \
  "$(lock uppercase "{\"type\":\"github\",\"owner\":\"dayvidpham\",\"repo\":\"pasture\",\"rev\":\"${REV^^}\"}")"

printf '{"nodes":{"nixpkgs":{"locked":{}}}}\n' > "${work}/no-pasture.lock"
expect_reject 'no pasture input at all' 'no locked pasture input' "${work}/no-pasture.lock"

expect_reject 'lock file missing' 'is not a file' "${work}/does-not-exist.lock"

if [ "$failures" -ne 0 ]; then
  printf '\n%d of %d checks FAILED\n' "$failures" "$checks"
  exit 1
fi
printf 'all %d pinned-pasture-revision checks passed\n' "$checks"
