#!/usr/bin/env bash
# Tests for scripts/release/verify-aggregate-dir.sh.
#
# These invoke the REAL verifier by path — the same entry point the publish and
# smoke jobs call — over synthetic aggregate directories built here. The
# fixtures are synthetic rather than produced by a real `pasture bundle export`
# run because this suite must stay hermetic and offline; what is under test is
# the verifier's own logic, and it reads nothing but JSON and file bytes.
#
# Real producer output is covered where it can be: .github/workflows/gates.yml
# builds the pinned Pasture, runs a real `pasture bundle export`, packages it
# with the real producer, and runs THIS verifier over the result — on every
# release PR, before any tag exists. That is the fixture no committed blob could
# honestly stand in for, since its bytes change with the pinned revision.
#
# The happy-path fixture is byte-shaped like a real producer output: the same
# manifest field names, the same canonical asset basenames, real sha256 digests,
# and a real sidecar. Each negative case is that fixture with exactly ONE
# property broken, so a passing check attributes the rejection to that property.
#
#   scripts/release/verify-aggregate-dir_test.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HERE
readonly VERIFY="${HERE}/verify-aggregate-dir.sh"

readonly VERSION='0.1.0'
readonly AURA_REVISION='1111111111111111111111111111111111111111'
readonly PASTURE_REVISION='2222222222222222222222222222222222222222'
readonly INSTALLER_MIN='0.1.0'
readonly INSTALLER_MAX='0.1.0'
readonly SCHEMA='pasture.aggregate-release/v1'

failures=0
checks=0

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# build_fixture <dir> <version> <channel>
#
# Writes a structurally complete aggregate directory: nine component archives
# with distinct contents, a manifest naming them with their true digests, and a
# matching sidecar.
build_fixture() {
  local dir="$1" version="$2" channel="$3"
  mkdir -p "$dir"
  local components='[]'
  local harness extension asset digest
  for harness in claude opencode codex; do
    for extension in skills agents hooks; do
      asset="pasture-${version}-${harness}-${extension}.tgz"
      printf 'synthetic %s %s payload\n' "$harness" "$extension" > "${dir}/${asset}"
      digest="sha256:$(sha256sum "${dir}/${asset}" | cut -d' ' -f1)"
      components="$(jq -c --arg a "$asset" --arg d "$digest" \
        '. + [{asset: $a, digest: $d}]' <<< "$components")"
    done
  done
  jq -n \
    --arg schema "$SCHEMA" \
    --arg version "$version" --arg channel "$channel" \
    --arg min "$INSTALLER_MIN" --arg max "$INSTALLER_MAX" \
    --arg aura "$AURA_REVISION" --arg pasture "$PASTURE_REVISION" \
    --argjson components "$components" \
    '{schema: $schema, version: $version, channel: $channel,
      compatibility: {installer_min: $min, installer_max: $max},
      revisions: {pasture: $pasture, aura: $aura}, components: $components}' \
    > "${dir}/pasture-aggregate-manifest.json"
  ( cd "$dir" && sha256sum pasture-aggregate-manifest.json > pasture-aggregate-manifest.json.sha256 )
}

# fixture <name> [version] [channel] — a fresh copy of the happy-path fixture.
fixture() {
  local dir="${work}/$1"
  rm -rf "$dir"
  build_fixture "$dir" "${2:-$VERSION}" "${3:-final}"
  printf '%s\n' "$dir"
}

# expect_ok <dir> [version] [channel]
expect_ok() {
  local dir="$1" version="${2:-$VERSION}" channel="${3:-final}"
  local output status
  checks=$((checks + 1))
  output="$("$VERIFY" "$dir" "$version" "$AURA_REVISION" "$PASTURE_REVISION" "$channel" \
    "$INSTALLER_MIN" "$INSTALLER_MAX" 2>&1)"
  status=$?
  if [ "$status" -ne 0 ]; then
    printf 'FAIL %s: expected acceptance, got exit %d\n%s\n' "$dir" "$status" "$output"
    failures=$((failures + 1))
  fi
}

# expect_reject <label> <expected-substring-of-the-diagnosis> <args...>
#
# Asserts the rejection AND that the DIAGNOSIS — stderr only — names the broken
# property. Matching the combined streams was not an oracle: the verifier prints
# a "… ✓" trace to stdout naming every asset and field it accepts, so a check
# looking for an asset basename or a field path could be satisfied by the
# success trace of a completely different rejection. Deleting a check would then
# leave the suite green. stderr carries only the failure, so what is asserted
# here is what actually refused.
expect_reject() {
  local label="$1" want="$2"
  shift 2
  local diagnosis status
  local err="${work}/stderr"
  checks=$((checks + 1))
  "$VERIFY" "$@" > /dev/null 2> "$err"
  status=$?
  diagnosis="$(cat "$err")"
  if [ "$status" -eq 0 ]; then
    printf 'FAIL %s: expected rejection, got acceptance\n' "$label"
    failures=$((failures + 1))
    return
  fi
  if ! printf '%s\n' "$diagnosis" | grep -qF "$want"; then
    printf 'FAIL %s: diagnosis does not mention %q\n%s\n' "$label" "$want" "$diagnosis"
    failures=$((failures + 1))
    return
  fi
  # Every rejection must be the script's own actionable refusal, not an
  # incidental non-zero exit from a tool it called: a diagnosis has to name what
  # failed and how to fix it.
  if ! printf '%s\n' "$diagnosis" | grep -q "^error: .* failed in scripts/release/verify-aggregate-dir.sh: "; then
    printf 'FAIL %s: diagnosis is not an actionable refusal from the verifier\n%s\n' "$label" "$diagnosis"
    failures=$((failures + 1))
    return
  fi
  if ! printf '%s\n' "$diagnosis" | grep -q '^  fix: '; then
    printf 'FAIL %s: diagnosis carries no fix line\n%s\n' "$label" "$diagnosis"
    failures=$((failures + 1))
  fi
}

# reject_args <label> <want> <dir> [version] [channel] [aura] [pasture] [min] [max]
# — the common shape: one property broken, everything else the happy path.
reject_default() {
  local label="$1" want="$2" dir="$3"
  expect_reject "$label" "$want" \
    "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final "$INSTALLER_MIN" "$INSTALLER_MAX"
}

# ── Accepted ─────────────────────────────────────────────────────────────
expect_ok "$(fixture ok)"
expect_ok "$(fixture ok-rc '0.1.0-rc1' prerelease)" '0.1.0-rc1' prerelease

# ── Identity bindings ────────────────────────────────────────────────────
dir="$(fixture wrong-version)"
expect_reject 'version mismatch' '.version' \
  "$dir" '0.2.0' "$AURA_REVISION" "$PASTURE_REVISION" final "$INSTALLER_MIN" "$INSTALLER_MAX"

dir="$(fixture wrong-aura)"
expect_reject 'aura revision mismatch' '.revisions.aura' \
  "$dir" "$VERSION" '3333333333333333333333333333333333333333' "$PASTURE_REVISION" final \
  "$INSTALLER_MIN" "$INSTALLER_MAX"

dir="$(fixture wrong-pasture)"
expect_reject 'pasture revision mismatch' '.revisions.pasture' \
  "$dir" "$VERSION" "$AURA_REVISION" '3333333333333333333333333333333333333333' final \
  "$INSTALLER_MIN" "$INSTALLER_MAX"

# A release candidate published as a final release is a silent downgrade of the
# installer's opt-in guarantee, so the channel is checked like an identity.
dir="$(fixture rc-as-final '0.1.0-rc1' prerelease)"
expect_reject 'channel mismatch' '.channel' \
  "$dir" '0.1.0-rc1' "$AURA_REVISION" "$PASTURE_REVISION" final "$INSTALLER_MIN" "$INSTALLER_MAX"

# The compatibility range is what an installer consults to decide whether it may
# activate this aggregate at all. It is passed to the producer by the workflow,
# so it is re-derived here against what the workflow passed rather than taken on
# the producer's word.
dir="$(fixture wrong-installer-min)"
expect_reject 'compatibility minimum mismatch' '.compatibility.installer_min' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final '0.0.9' "$INSTALLER_MAX"

dir="$(fixture wrong-installer-max)"
expect_reject 'compatibility maximum mismatch' '.compatibility.installer_max' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final "$INSTALLER_MIN" '9.9.9'

# A manifest declaring a schema this pipeline does not know may mean something
# different by the very fields checked above.
dir="$(fixture wrong-schema)"
jq '.schema = "pasture.aggregate-release/v2"' "${dir}/pasture-aggregate-manifest.json" > "${dir}/m" \
  && mv "${dir}/m" "${dir}/pasture-aggregate-manifest.json"
( cd "$dir" && sha256sum pasture-aggregate-manifest.json > pasture-aggregate-manifest.json.sha256 )
reject_default 'unknown manifest schema' '.schema' "$dir"

# ── Byte-level integrity ─────────────────────────────────────────────────
dir="$(fixture tampered-manifest)"
sed -i 's/"final"/"beta"/' "${dir}/pasture-aggregate-manifest.json"
reject_default 'manifest does not match sidecar' 'checksum sidecar' "$dir"

# Manifest bytes altered WITHOUT touching any field the identity and inventory
# checks read: same version, channel, revisions, compatibility, and component
# digests, only re-indented. Every other check in this script accepts it; the
# sidecar comparison is the only thing that can refuse it, so deleting that
# check makes this case fail and nothing else does.
dir="$(fixture reindented-manifest)"
jq --indent 4 . "${dir}/pasture-aggregate-manifest.json" > "${dir}/m" \
  && mv "${dir}/m" "${dir}/pasture-aggregate-manifest.json"
reject_default 'manifest re-serialised without changing any checked field' 'checksum sidecar' "$dir"

# A sidecar regenerated over the altered bytes is self-consistent, so the
# comparison passes; the shape checks are what remain, and an empty sidecar
# makes `sha256sum --check` succeed vacuously.
dir="$(fixture empty-sidecar)"
: > "${dir}/pasture-aggregate-manifest.json.sha256"
reject_default 'sidecar lists nothing' 'instead of exactly one' "$dir"

dir="$(fixture two-line-sidecar)"
( cd "$dir" && sha256sum pasture-aggregate-manifest.json pasture-0.1.0-claude-skills.tgz \
  > pasture-aggregate-manifest.json.sha256 )
reject_default 'sidecar lists more than the manifest' 'instead of exactly one' "$dir"

# A sidecar vouching for some other file passes `sha256sum --check` and proves
# nothing about the manifest.
dir="$(fixture sidecar-names-another-file)"
( cd "$dir" && sha256sum pasture-0.1.0-claude-skills.tgz > pasture-aggregate-manifest.json.sha256 )
reject_default 'sidecar vouches for the wrong file' 'rather than for pasture-aggregate-manifest.json' "$dir"

dir="$(fixture tampered-component)"
printf 'tampered\n' > "${dir}/pasture-0.1.0-codex-hooks.tgz"
reject_default 'component bytes differ from manifest digest' 'pasture-0.1.0-codex-hooks.tgz' "$dir"

# A manifest whose sidecar was regenerated over corrupt bytes passes the
# checksum check and must then be rejected as unreadable, not misreported as a
# digest mismatch.
dir="$(fixture unparsable-manifest)"
printf 'not json at all\n' > "${dir}/pasture-aggregate-manifest.json"
( cd "$dir" && sha256sum pasture-aggregate-manifest.json > pasture-aggregate-manifest.json.sha256 )
reject_default 'manifest is not JSON' 'is not valid JSON' "$dir"

# ── Inventory ────────────────────────────────────────────────────────────
dir="$(fixture missing-asset)"
rm "${dir}/pasture-0.1.0-opencode-agents.tgz"
reject_default 'named component absent' 'pasture-0.1.0-opencode-agents.tgz' "$dir"

dir="$(fixture extra-file)"
printf 'unvouched\n' > "${dir}/README.txt"
reject_default 'unlisted file present' 'publication set' "$dir"

# Eight cells is a manifest that verifies internally but leaves a harness
# permanently uninstallable from this release.
dir="$(fixture eight-components)"
jq '.components |= .[0:8]' "${dir}/pasture-aggregate-manifest.json" > "${dir}/m" \
  && mv "${dir}/m" "${dir}/pasture-aggregate-manifest.json"
rm "${dir}/pasture-0.1.0-codex-hooks.tgz"
( cd "$dir" && sha256sum pasture-aggregate-manifest.json > pasture-aggregate-manifest.json.sha256 )
reject_default 'incomplete cell matrix' 'component inventory' "$dir"

# Nine components, nine files, every digest correct — and one cell renamed to a
# harness that does not exist. Counting cannot see this; deriving the expected
# basenames from the cell matrix can.
dir="$(fixture wrong-cell-name)"
mv "${dir}/pasture-0.1.0-codex-hooks.tgz" "${dir}/pasture-0.1.0-cursor-hooks.tgz"
jq '(.components[] | select(.asset == "pasture-0.1.0-codex-hooks.tgz") | .asset) = "pasture-0.1.0-cursor-hooks.tgz"' \
  "${dir}/pasture-aggregate-manifest.json" > "${dir}/m" \
  && mv "${dir}/m" "${dir}/pasture-aggregate-manifest.json"
( cd "$dir" && sha256sum pasture-aggregate-manifest.json > pasture-aggregate-manifest.json.sha256 )
reject_default 'component named for a harness that does not exist' 'component inventory' "$dir"

# ── Missing structure ────────────────────────────────────────────────────
dir="$(fixture no-manifest)"
rm "${dir}/pasture-aggregate-manifest.json"
reject_default 'manifest absent' 'pasture-aggregate-manifest.json is missing' "$dir"

dir="$(fixture no-sidecar)"
rm "${dir}/pasture-aggregate-manifest.json.sha256"
reject_default 'sidecar absent' 'pasture-aggregate-manifest.json.sha256 is missing' "$dir"

expect_reject 'directory absent' 'is not a directory' \
  "${work}/does-not-exist" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final \
  "$INSTALLER_MIN" "$INSTALLER_MAX"

# ── Invocation ───────────────────────────────────────────────────────────
dir="$(fixture bad-channel)"
expect_reject 'unknown channel' 'neither final nor prerelease' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" latest "$INSTALLER_MIN" "$INSTALLER_MAX"

expect_reject 'wrong argument count' 'expected exactly 7 arguments' \
  "$dir" "$VERSION"

if [ "$failures" -ne 0 ]; then
  printf '\n%d of %d checks FAILED\n' "$failures" "$checks"
  exit 1
fi
printf 'all %d verify-aggregate-dir checks passed\n' "$checks"
