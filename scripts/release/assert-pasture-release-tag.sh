#!/usr/bin/env bash
# Assert that the installer compatibility floor names a REAL published Pasture
# release, and that this repository is pinned to exactly that release.
#
# The published aggregate manifest declares installer_min: the lowest Pasture
# installer that may activate it. That value is derived from the pinned Pasture
# binary's own reported version (scripts/release/release-grammar.sh
# installer-compatibility), and it is frozen into an immutable manifest — it can
# never be corrected, only superseded. A floor naming a version that was never
# released is therefore a permanent, uncheckable claim.
#
# Two things are asserted against dayvidpham/pasture, in this order:
#
#   1. the tag vX.Y.Z EXISTS there — the floor names a published release; and
#   2. the revision this repository has pinned in flake.lock IS the commit that
#      tag points to — the assets in the release were built by that release, not
#      by some later or earlier commit that merely reports its version.
#
# (2) is what makes (1) meaningful. Without it a build could report v1.2.3 from
# a commit that is not v1.2.3, and the manifest would bind provenance to a
# revision no consumer can relate to the version it advertises.
#
# This is a NETWORK assertion (a single `git ls-remote` against a public
# repository, no authentication), which is why it lives here and is invoked by
# the workflows rather than by the hermetic verifier suite.
#
# Usage:
#   assert-pasture-release-tag.sh <version> <pinned-revision>
#
#     version           producer form, no leading v (for example 0.1.0)
#     pinned-revision   the 40-character lowercase revision from flake.lock
#
# Environment:
#   PASTURE_TAG_REMOTE  the remote to query. Defaults to the canonical
#                       repository; overridden only by this script's own test
#                       suite, which points it at a local repository so the
#                       assertion's logic can be proved without the network.
#
# Prints a trace on success; exits 1 with an actionable diagnosis on stderr.

set -euo pipefail

readonly PROGRAM_NAME="scripts/release/assert-pasture-release-tag.sh"
readonly DEFAULT_REMOTE='https://github.com/dayvidpham/pasture.git'

# fail <what-went-wrong> <why> <impact> <how-to-fix>
fail() {
  local what="$1" why="$2" impact="$3" fix="$4"
  printf 'error: %s failed in %s: %s\n' "$what" "$PROGRAM_NAME" "$why" >&2
  printf '  impact: %s\n' "$impact" >&2
  printf '  fix: %s\n' "$fix" >&2
  exit 1
}

usage() {
  cat >&2 <<USAGE
${PROGRAM_NAME} — prove the installer compatibility floor is a published Pasture release.

Usage:
  ${PROGRAM_NAME} <version> <pinned-revision>

  version          the floor in producer form, no leading v (for example 0.1.0)
  pinned-revision  the 40-character lowercase Pasture revision from flake.lock
USAGE
}

main() {
  if [ "$#" -ne 2 ]; then
    usage
    fail "parsing command-line arguments" \
      "expected exactly 2 arguments but received $#" \
      "the installer compatibility floor was not checked against any published Pasture release, so nothing may be produced or published from this run" \
      "invoke it as '${PROGRAM_NAME} <version> <pinned-revision>'"
  fi

  local version="$1" pinned="$2"
  local remote="${PASTURE_TAG_REMOTE:-$DEFAULT_REMOTE}"
  local tag="v${version}"

  if [[ ! "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    fail "validating the version argument" \
      "\"${version}\" is not a canonical released version of the form X.Y.Z with no leading v" \
      "no Pasture tag could be looked up, so the compatibility floor is unproven and nothing may be published" \
      "pass the installer_min value emitted by 'scripts/release/release-grammar.sh installer-compatibility', which is already in producer form"
  fi
  if [[ ! "$pinned" =~ ^[0-9a-f]{40}$ ]]; then
    fail "validating the pinned-revision argument" \
      "\"${pinned}\" is not a 40-character lowercase Git revision" \
      "the pinned revision could not be compared with the release tag, so nothing may be published" \
      "pass the revision emitted by 'scripts/release/pinned-pasture-revision.sh flake.lock'"
  fi

  local refs stderr_output stderr_file
  # stdout and stderr are captured SEPARATELY. A remote can print a benign
  # warning on stderr (for example a redirect notice) while still exiting 0
  # with no matching ref on stdout; folding both streams together (as a bare
  # `2>&1` would) makes that warning text land in $refs, so the empty-refs
  # check below never fires and the script misdiagnoses "no tag" as something
  # else entirely. stderr is therefore folded into the failure message ONLY,
  # never into $refs.
  #
  # Both the tag object and its peeled target are requested: an annotated tag
  # answers with two lines and only the peeled one names the commit, while a
  # lightweight tag answers with one line that already is the commit.
  stderr_file="$(mktemp)"
  if ! refs="$(git ls-remote --tags "$remote" "refs/tags/${tag}" "refs/tags/${tag}^{}" 2>"$stderr_file")"; then
    stderr_output="$(cat "$stderr_file")"
    rm -f "$stderr_file"
    fail "listing the Pasture release tags" \
      "'git ls-remote' against ${remote} failed: ${stderr_output}" \
      "whether ${tag} is a published Pasture release could not be determined, so nothing was produced or published; the release tag for this repository is unharmed and stays publishable" \
      "this is an infrastructure failure, not a release defect: confirm the runner has network access to ${remote} and re-run all jobs of this workflow"
  fi
  rm -f "$stderr_file"

  if [ -z "$refs" ]; then
    fail "resolving the Pasture release tag" \
      "${remote} has no tag ${tag}, although the pinned Pasture binary reports that version" \
      "the aggregate would declare an installer compatibility floor of ${version}, a Pasture release that does not exist, frozen into an immutable manifest that can never be corrected — only superseded — so nothing was produced or published" \
      "cut the Pasture release ${tag} first, then re-lock this repository's input with 'nix flake update pasture' on the release PR and cut the Aura release afterwards. Pasture is released before Aura precisely so this floor can be proven"
  fi

  local commit
  # Prefer the peeled line; fall back to the single line of a lightweight tag.
  commit="$(awk '$2 ~ /\^\{\}$/ {print $1; exit}' <<< "$refs")"
  if [ -z "$commit" ]; then
    commit="$(printf '%s\n' "$refs" | awk 'NR == 1 {print $1}')"
  fi

  if [ "$commit" != "$pinned" ]; then
    fail "binding the pinned Pasture revision to its release tag" \
      "${remote} resolves ${tag} to ${commit}, but this repository pins ${pinned}" \
      "the aggregate would advertise a compatibility floor of ${version} while its components were built from a different commit than the one that release names, and that mismatch is frozen into an immutable manifest — so nothing was produced or published" \
      "pin the tagged revision: run 'nix flake update pasture' on the release PR if ${tag} is the newest Pasture release, or 'nix flake lock --override-input pasture github:dayvidpham/pasture/${commit}' to pin ${tag} exactly, then re-run the release"
  fi

  printf 'pasture %s is published at %s, which is the revision pinned here ✓\n' "$tag" "$commit"
}

main "$@"
