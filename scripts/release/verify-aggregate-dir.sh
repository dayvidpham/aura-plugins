#!/usr/bin/env bash
# Verify one aggregate release directory against the identity it claims.
#
# Used twice, deliberately, by .github/workflows/release.yml:
#
#   publish — over the directory the producer just built, BEFORE anything is
#             uploaded, so a directory that does not match the tag is never
#             published; and
#   smoke   — over a freshly downloaded copy of the PUBLISHED assets, so what
#             is actually retrievable is proven to be what was built.
#
# Both callers run the same code because a publication check and a post-publish
# check that can disagree are worse than either alone.
#
# The producer already verified its own output with Pasture's typed verifier.
# This script deliberately does NOT re-implement that; it re-derives, with
# independent tools, the four bindings that make the release safe to publish and
# that only the workflow knows:
#
#   1. the manifest's bytes match the .sha256 sidecar shipped beside it, and
#      that sidecar is a single line naming the manifest itself;
#   2. the manifest's version equals the tag without its leading "v", and its
#      schema is the one this pipeline knows how to publish;
#   3. the manifest's revisions match the exact Aura and Pasture commits the
#      run built from, and its declared installer compatibility range is the
#      one the workflow passed to the producer;
#   4. every component asset named by the manifest is present, is the only
#      thing present, is one of the nine canonical basenames for this version,
#      and hashes to the digest the manifest records.
#
# Usage:
#   verify-aggregate-dir.sh <dir> <version> <aura-revision> <pasture-revision> \
#     <channel> <installer-min> <installer-max>
#
# Exits 0 and prints a per-check trace on success; exits 1 with an actionable
# diagnosis on stderr otherwise.

set -euo pipefail

readonly PROGRAM_NAME="scripts/release/verify-aggregate-dir.sh"
readonly MANIFEST_ASSET="pasture-aggregate-manifest.json"
readonly CHECKSUM_ASSET="pasture-aggregate-manifest.json.sha256"
readonly EXPECTED_COMPONENTS=9
# The schema this pipeline knows how to publish. A manifest carrying any other
# schema may mean something different by the very fields checked below.
readonly EXPECTED_SCHEMA="pasture.aggregate-release/v1"
# The canonical cell matrix. The asset basenames are derived from it below
# rather than only counted, so a manifest that names nine internally consistent
# but wrong assets is refused.
readonly HARNESS_STEMS=(claude opencode codex)
readonly EXTENSIONS=(skills agents hooks)

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
${PROGRAM_NAME} — verify an aggregate release directory against its claimed identity.

Usage:
  ${PROGRAM_NAME} <dir> <version> <aura-revision> <pasture-revision> <channel> <installer-min> <installer-max>

  dir              directory holding the manifest, its .sha256 sidecar, and the
                   ${EXPECTED_COMPONENTS} component assets
  version          producer form, no leading v (for example 0.1.0 or 0.1.0-rc1)
  aura-revision    exact 40-character lowercase Aura commit
  pasture-revision exact 40-character lowercase Pasture commit
  channel          final | prerelease
  installer-min    lower bound of the installer compatibility range the
                   producer was asked to record
  installer-max    upper bound of that range
USAGE
}

main() {
  if [ "$#" -ne 7 ]; then
    usage
    fail "parsing command-line arguments" \
      "expected exactly 7 arguments but received $#" \
      "no aggregate directory was verified, so nothing may be published from this run" \
      "invoke it as '${PROGRAM_NAME} <dir> <version> <aura-revision> <pasture-revision> <channel> <installer-min> <installer-max>'"
  fi

  local dir="$1" version="$2" aura_revision="$3" pasture_revision="$4" channel="$5"
  local installer_min="$6" installer_max="$7"

  [ -d "$dir" ] || fail "locating the aggregate directory" \
    "\"${dir}\" is not a directory" \
    "the release contents cannot be examined and must not be published" \
    "pass the directory the producer's --output-dir created, or the directory the published assets were downloaded into"

  case "$channel" in
    final|prerelease) ;;
    *) fail "validating the expected channel" \
         "\"${channel}\" is neither final nor prerelease" \
         "the release channel cannot be checked, so a release candidate could be published as a final release" \
         "pass final for a vX.Y.Z tag or prerelease for a vX.Y.Z-rcN tag" ;;
  esac

  local manifest="${dir}/${MANIFEST_ASSET}"
  [ -f "$manifest" ] || fail "locating the aggregate manifest" \
    "${MANIFEST_ASSET} is missing from ${dir}" \
    "the release has no manifest, so nothing binds its assets to a version or to the commits they were built from" \
    "re-run the component build job; never publish a directory the producer did not write in full"
  [ -f "${dir}/${CHECKSUM_ASSET}" ] || fail "locating the manifest checksum sidecar" \
    "${CHECKSUM_ASSET} is missing from ${dir}" \
    "consumers could not detect a tampered or truncated manifest" \
    "re-run the component build job; the producer always emits the sidecar beside the manifest"

  # 1. The sidecar is exactly one line, and that line names the manifest.
  #    `sha256sum --check` reports success for a file whose every listed entry
  #    matched — including a sidecar that lists something else entirely, or an
  #    empty one — so its shape has to be asserted before its verdict means
  #    anything.
  local sidecar_lines sidecar_named
  sidecar_lines="$(wc -l < "${dir}/${CHECKSUM_ASSET}")"
  if [ "$sidecar_lines" != "1" ]; then
    fail "verifying the shape of the manifest checksum sidecar" \
      "${CHECKSUM_ASSET} holds ${sidecar_lines} lines instead of exactly one" \
      "a sidecar that lists no entry, or more than the manifest, cannot establish the manifest's identity: an empty one makes the checksum check vacuously succeed" \
      "re-run the component build job; the producer always writes '<64 lowercase hex>  ${MANIFEST_ASSET}' followed by a newline"
  fi
  sidecar_named="$(sed -n 's/^[0-9a-f]\{64\}[[:space:]][[:space:]*]\(.*\)$/\1/p' "${dir}/${CHECKSUM_ASSET}")"
  if [ "$sidecar_named" != "$MANIFEST_ASSET" ]; then
    fail "verifying the target of the manifest checksum sidecar" \
      "${CHECKSUM_ASSET} records a digest for \"${sidecar_named}\" rather than for ${MANIFEST_ASSET}" \
      "the sidecar vouches for some other file, so nothing published here would detect a tampered or truncated manifest" \
      "re-run the component build job from a clean directory; if a published release fails this check, treat the download as corrupt or tampered and do not install it"
  fi
  echo "checksum sidecar is a single line naming ${MANIFEST_ASSET} ✓"

  #    The manifest bytes match that sidecar. Run from inside the directory
  #    because the sidecar names the manifest by bare basename.
  ( cd "$dir" && sha256sum --check --strict --status "$CHECKSUM_ASSET" ) || fail \
    "verifying the manifest against its checksum sidecar" \
    "the sha256 of ${MANIFEST_ASSET} does not match the digest recorded in ${CHECKSUM_ASSET}" \
    "the manifest and its sidecar disagree, so the release bytes cannot be trusted and must not be published or installed" \
    "re-run the component build job from a clean directory; if a published release fails this check, treat the download as corrupt or tampered and do not install it"
  echo "manifest matches its checksum sidecar ✓"

  # A malformed manifest must be reported as such rather than as a mismatch.
  jq -e . "$manifest" > /dev/null 2>&1 || fail \
    "parsing the aggregate manifest" \
    "${manifest} is not valid JSON" \
    "the release identity cannot be read, so it must not be published or installed" \
    "re-run the component build job; a manifest that passed its sidecar check but is not valid JSON indicates a corrupt producer run"

  # 2/3. Identity bindings.
  local field expected actual
  while read -r field expected; do
    actual="$(jq -r "$field" "$manifest")"
    if [ "$actual" != "$expected" ]; then
      fail "verifying the manifest identity binding ${field}" \
        "the manifest says ${actual} but this release run bound ${expected}" \
        "publishing would freeze a false provenance claim into an immutable release that can never be corrected, only superseded" \
        "do not publish; re-run the component build job for tag v${version} and confirm the pinned Pasture revision, the tagged Aura commit, and the compatibility range passed to the producer are the ones intended"
    fi
    echo "manifest ${field} is ${actual} ✓"
    # Every row is re-derived here, including the two the producer alone would
    # otherwise attest to: a manifest whose schema or compatibility range does
    # not match what this run asked for is published bytes making a claim no
    # step in the pipeline checked.
  done <<EOF
.schema $EXPECTED_SCHEMA
.version $version
.channel $channel
.revisions.aura $aura_revision
.revisions.pasture $pasture_revision
.compatibility.installer_min $installer_min
.compatibility.installer_max $installer_max
EOF

  # 4. Component inventory and per-asset digests. The expectation is the nine
  #    canonical basenames for THIS version, derived from the cell matrix, not
  #    a count: a manifest naming nine mutually consistent but wrong assets —
  #    a stale version in the basenames, a duplicated cell, a cell that does
  #    not exist — is internally coherent and still unusable.
  local expected_components actual_components
  expected_components="$(
    for harness in "${HARNESS_STEMS[@]}"; do
      for extension in "${EXTENSIONS[@]}"; do
        printf 'pasture-%s-%s-%s.tgz\n' "$version" "$harness" "$extension"
      done
    done | sort
  )"
  actual_components="$(jq -r '.components[].asset' "$manifest" | sort)"
  if [ "$expected_components" != "$actual_components" ]; then
    fail "verifying the component inventory" \
      "the manifest names [$(echo "$actual_components" | tr '\n' ' ')] instead of the ${EXPECTED_COMPONENTS} canonical assets for ${version} [$(echo "$expected_components" | tr '\n' ' ')]" \
      "the aggregate would omit, duplicate, or misname an installation cell, so some harness could never be installed from this release" \
      "do not publish; re-run the component build job and confirm the export emitted every harness/extension cell for this exact version"
  fi
  echo "manifest names the ${EXPECTED_COMPONENTS} canonical component assets for ${version} ✓"

  local asset digest actual_digest
  while read -r asset digest; do
    [ -f "${dir}/${asset}" ] || fail "locating a component asset" \
      "${asset} is named by the manifest but is missing from ${dir}" \
      "the release would advertise a component that cannot be downloaded" \
      "do not publish; re-run the component build job, or if a published release fails this check, re-download and then treat the release as incomplete"
    actual_digest="sha256:$(sha256sum "${dir}/${asset}" | cut -d' ' -f1)"
    if [ "$actual_digest" != "$digest" ]; then
      fail "verifying a component asset digest" \
        "${asset} hashes to ${actual_digest} but the manifest records ${digest}" \
        "the bytes do not match the identity the manifest binds them to, so installing them would activate content that was never verified" \
        "do not publish; re-run the component build job from a clean directory, and if a published release fails this check, treat the download as corrupt or tampered and do not install it"
    fi
    echo "component ${asset} matches its manifest digest ✓"
  done < <(jq -r '.components[] | "\(.asset) \(.digest)"' "$manifest")

  # Nothing beyond the manifest, the sidecar, and the named components. An
  # extra file in the publication set is content nothing in the manifest
  # vouches for.
  local expected_files
  expected_files="$( { printf '%s\n%s\n' "$MANIFEST_ASSET" "$CHECKSUM_ASSET"; jq -r '.components[].asset' "$manifest"; } | sort )"
  local actual_files
  actual_files="$(find "$dir" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort)"
  if [ "$expected_files" != "$actual_files" ]; then
    fail "verifying the publication set" \
      "the directory contents differ from the manifest's own inventory; expected [$(echo "$expected_files" | tr '\n' ' ')] but found [$(echo "$actual_files" | tr '\n' ' ')]" \
      "an unlisted file would be published as part of an immutable release without the manifest vouching for its bytes, or a listed file is absent" \
      "do not publish; re-run the component build job into a new empty output directory and upload only what the producer wrote"
  fi
  echo "publication set contains exactly the manifest, its sidecar, and the ${EXPECTED_COMPONENTS} named components ✓"

  echo "aggregate ${version} (${channel}) verified in ${dir}"
}

main "$@"
