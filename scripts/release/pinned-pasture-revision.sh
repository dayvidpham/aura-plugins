#!/usr/bin/env bash
# Read the pinned Pasture revision out of a flake.lock, refusing anything that
# is not an exact commit of the expected GitHub repository.
#
# One release binds exactly one Pasture revision, and that revision is stamped
# into an immutable aggregate manifest as `revisions.pasture`. Two workflows
# need it — gates.yml builds that Pasture before the tag exists, release.yml
# builds it again to export the component assets — so it is read here, once,
# rather than by two copies of the same jq that could drift.
#
# The node's identity is asserted, not only its rev: a `path:` input or a
# fork-owned one carries a valid-looking revision that would be published as
# though it were dayvidpham/pasture.
#
# Usage:
#   pinned-pasture-revision.sh [flake.lock]
#
# Prints the 40-character revision on stdout; exits 1 with an actionable
# diagnosis on stderr otherwise.

set -euo pipefail

readonly PROGRAM_NAME="scripts/release/pinned-pasture-revision.sh"
readonly EXPECTED_TYPE="github"
readonly EXPECTED_OWNER="dayvidpham"
readonly EXPECTED_REPO="pasture"

fail() {
  local what="$1" why="$2" impact="$3" fix="$4"
  printf 'error: %s failed in %s: %s\n' "$what" "$PROGRAM_NAME" "$why" >&2
  printf '  impact: %s\n' "$impact" >&2
  printf '  fix: %s\n' "$fix" >&2
  exit 1
}

main() {
  local lock="${1:-flake.lock}"

  [ -f "$lock" ] || fail "locating the flake lock file" \
    "\"${lock}\" is not a file" \
    "the pinned Pasture revision cannot be read, so no release may be built" \
    "run this from the repository root, or pass the path to flake.lock"

  local locked
  locked="$(jq -c '.nodes.pasture.locked // empty' "$lock" 2>/dev/null)" || locked=''
  [ -n "$locked" ] || fail "reading the pasture flake input" \
    "${lock} has no locked pasture input" \
    "nothing binds this release to a Pasture commit, so its component assets could not be traced to a source" \
    "add the pasture input to flake.nix and lock it with 'nix flake update pasture'"

  local key want got
  while read -r key want; do
    got="$(jq -r --arg k "$key" '.[$k] // ""' <<< "$locked")"
    if [ "$got" != "$want" ]; then
      fail "verifying the identity of the pasture flake input" \
        "${lock} records ${key}=\"${got}\" instead of \"${want}\" (locked node: ${locked})" \
        "the release would bind component assets to a Pasture source this pipeline cannot name, and publish them as though they came from ${EXPECTED_OWNER}/${EXPECTED_REPO}" \
        "point the pasture input at ${EXPECTED_TYPE}:${EXPECTED_OWNER}/${EXPECTED_REPO} in flake.nix and re-lock it with 'nix flake update pasture' on a release PR"
    fi
  done <<EOF
type $EXPECTED_TYPE
owner $EXPECTED_OWNER
repo $EXPECTED_REPO
EOF

  local revision
  revision="$(jq -r '.rev // ""' <<< "$locked")"
  if ! printf '%s' "$revision" | grep -Eq '^[0-9a-f]{40}$'; then
    fail "reading the pinned pasture revision" \
      "the locked pasture input has no exact 40-character lowercase commit revision (read: \"${revision}\")" \
      "the component assets could not be bound to a provable Pasture commit, so no release may be built" \
      "re-lock the input with 'nix flake update pasture' on a release PR so ${lock} records a concrete rev"
  fi

  printf '%s\n' "$revision"
}

main "$@"
