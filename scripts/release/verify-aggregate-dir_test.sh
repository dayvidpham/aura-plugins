#!/usr/bin/env bash
# Tests for scripts/release/verify-aggregate-dir.sh.
#
# These invoke the REAL verifier by path — the same entry point the publish and
# smoke jobs call — over synthetic aggregate directories built here. The
# fixtures are synthetic rather than produced by a real `pasture bundle export`
# run because this suite must stay hermetic and offline; what is under test is
# the verifier's own logic, and it reads nothing but JSON and file bytes.
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
    --arg version "$version" --arg channel "$channel" \
    --arg aura "$AURA_REVISION" --arg pasture "$PASTURE_REVISION" \
    --argjson components "$components" \
    '{schema: "pasture.aggregate-release/v1", version: $version, channel: $channel,
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
  output="$("$VERIFY" "$dir" "$version" "$AURA_REVISION" "$PASTURE_REVISION" "$channel" 2>&1)"
  status=$?
  if [ "$status" -ne 0 ]; then
    printf 'FAIL %s: expected acceptance, got exit %d\n%s\n' "$dir" "$status" "$output"
    failures=$((failures + 1))
  fi
}

# expect_reject <label> <expected-substring-of-the-diagnosis> <args...>
#
# Asserts both the rejection AND that the diagnosis names the broken property,
# so a verifier that rejects everything for the wrong reason cannot pass.
expect_reject() {
  local label="$1" want="$2"
  shift 2
  local output status
  checks=$((checks + 1))
  output="$("$VERIFY" "$@" 2>&1)"
  status=$?
  if [ "$status" -eq 0 ]; then
    printf 'FAIL %s: expected rejection, got acceptance\n%s\n' "$label" "$output"
    failures=$((failures + 1))
    return
  fi
  if ! printf '%s\n' "$output" | grep -qF "$want"; then
    printf 'FAIL %s: diagnosis does not mention %q\n%s\n' "$label" "$want" "$output"
    failures=$((failures + 1))
    return
  fi
  # Every rejection must tell the operator what to do; an unactionable refusal
  # in the middle of a release is what this whole pipeline exists to avoid.
  if ! printf '%s\n' "$output" | grep -q '^  fix: '; then
    printf 'FAIL %s: diagnosis carries no fix line\n%s\n' "$label" "$output"
    failures=$((failures + 1))
  fi
}

# ── Accepted ─────────────────────────────────────────────────────────────
expect_ok "$(fixture ok)"
expect_ok "$(fixture ok-rc '0.1.0-rc1' prerelease)" '0.1.0-rc1' prerelease

# ── Identity bindings ────────────────────────────────────────────────────
dir="$(fixture wrong-version)"
expect_reject 'version mismatch' '.version' \
  "$dir" '0.2.0' "$AURA_REVISION" "$PASTURE_REVISION" final

dir="$(fixture wrong-aura)"
expect_reject 'aura revision mismatch' '.revisions.aura' \
  "$dir" "$VERSION" '3333333333333333333333333333333333333333' "$PASTURE_REVISION" final

dir="$(fixture wrong-pasture)"
expect_reject 'pasture revision mismatch' '.revisions.pasture' \
  "$dir" "$VERSION" "$AURA_REVISION" '3333333333333333333333333333333333333333' final

# A release candidate published as a final release is a silent downgrade of the
# installer's opt-in guarantee, so the channel is checked like an identity.
dir="$(fixture rc-as-final '0.1.0-rc1' prerelease)"
expect_reject 'channel mismatch' '.channel' \
  "$dir" '0.1.0-rc1' "$AURA_REVISION" "$PASTURE_REVISION" final

# ── Byte-level integrity ─────────────────────────────────────────────────
dir="$(fixture tampered-manifest)"
sed -i 's/"final"/"beta"/' "${dir}/pasture-aggregate-manifest.json"
expect_reject 'manifest does not match sidecar' 'checksum sidecar' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final

dir="$(fixture tampered-component)"
printf 'tampered\n' > "${dir}/pasture-0.1.0-codex-hooks.tgz"
expect_reject 'component bytes differ from manifest digest' 'pasture-0.1.0-codex-hooks.tgz' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final

# A manifest whose sidecar was regenerated over corrupt bytes passes the
# checksum check and must then be rejected as unreadable, not misreported as a
# digest mismatch.
dir="$(fixture unparsable-manifest)"
printf 'not json at all\n' > "${dir}/pasture-aggregate-manifest.json"
( cd "$dir" && sha256sum pasture-aggregate-manifest.json > pasture-aggregate-manifest.json.sha256 )
expect_reject 'manifest is not JSON' 'is not valid JSON' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final

# ── Inventory ────────────────────────────────────────────────────────────
dir="$(fixture missing-asset)"
rm "${dir}/pasture-0.1.0-opencode-agents.tgz"
expect_reject 'named component absent' 'pasture-0.1.0-opencode-agents.tgz' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final

dir="$(fixture extra-file)"
printf 'unvouched\n' > "${dir}/README.txt"
expect_reject 'unlisted file present' 'publication set' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final

# Eight cells is a manifest that verifies internally but leaves a harness
# permanently uninstallable from this release.
dir="$(fixture eight-components)"
jq '.components |= .[0:8]' "${dir}/pasture-aggregate-manifest.json" > "${dir}/m" \
  && mv "${dir}/m" "${dir}/pasture-aggregate-manifest.json"
rm "${dir}/pasture-0.1.0-codex-hooks.tgz"
( cd "$dir" && sha256sum pasture-aggregate-manifest.json > pasture-aggregate-manifest.json.sha256 )
expect_reject 'incomplete cell matrix' 'component inventory' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final

# ── Missing structure ────────────────────────────────────────────────────
dir="$(fixture no-manifest)"
rm "${dir}/pasture-aggregate-manifest.json"
expect_reject 'manifest absent' 'pasture-aggregate-manifest.json is missing' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final

dir="$(fixture no-sidecar)"
rm "${dir}/pasture-aggregate-manifest.json.sha256"
expect_reject 'sidecar absent' 'pasture-aggregate-manifest.json.sha256 is missing' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final

expect_reject 'directory absent' 'is not a directory' \
  "${work}/does-not-exist" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" final

# ── Invocation ───────────────────────────────────────────────────────────
dir="$(fixture bad-channel)"
expect_reject 'unknown channel' 'neither final nor prerelease' \
  "$dir" "$VERSION" "$AURA_REVISION" "$PASTURE_REVISION" latest

expect_reject 'wrong argument count' 'expected exactly 5 arguments' \
  "$dir" "$VERSION"

if [ "$failures" -ne 0 ]; then
  printf '\n%d of %d checks FAILED\n' "$failures" "$checks"
  exit 1
fi
printf 'all %d verify-aggregate-dir checks passed\n' "$checks"
