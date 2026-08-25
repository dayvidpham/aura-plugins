#!/usr/bin/env bash
# Tests for scripts/release/assert-pasture-release-tag.sh.
#
# These invoke the REAL script by path — the same entry point gates.yml and
# release.yml call — against LOCAL Git repositories created here and reached
# through the script's PASTURE_TAG_REMOTE seam. No network is used: what is
# under test is the script's decision logic (does the tag exist, and does it
# point at the pinned revision), and `git ls-remote` answers identically for a
# local path and for an https remote.
#
# This suite needs `git`, which the flake's script sandbox does not provide, so
# it is gated by the release-scripts job in .github/workflows/gates.yml rather
# than by `nix flake check`.
#
#   scripts/release/assert-pasture-release-tag_test.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HERE
readonly ASSERT="${HERE}/assert-pasture-release-tag.sh"

failures=0
checks=0

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# make_remote <name> — a repository with one commit; prints its path.
make_remote() {
  local dir="${work}/$1"
  rm -rf "$dir"
  git init --quiet --bare "$dir"
  local tree="${work}/$1-tree"
  rm -rf "$tree"
  git init --quiet "$tree"
  git -C "$tree" -c user.email=t@t -c user.name=t commit --quiet --allow-empty -m 'first'
  git -C "$tree" push --quiet "$dir" HEAD:refs/heads/main
  printf '%s\n' "$dir"
}

# head_of <remote> — the commit the remote's main branch points at.
head_of() {
  git ls-remote "$1" refs/heads/main | awk '{print $1}'
}

# tag_annotated <remote> <tag> / tag_lightweight <remote> <tag>
tag_annotated() {
  local remote="$1" tag="$2"
  local tree="${remote}-tree"
  git -C "$tree" -c user.email=t@t -c user.name=t -c tag.gpgSign=false \
    tag -a "$tag" -m "$tag" HEAD
  git -C "$tree" push --quiet "$remote" "refs/tags/${tag}"
}
tag_lightweight() {
  local remote="$1" tag="$2"
  local tree="${remote}-tree"
  # update-ref rather than `git tag`, so a local tag.annotate or signing
  # setting cannot turn this fixture into an annotated tag.
  git -C "$tree" update-ref "refs/tags/${tag}" HEAD
  git -C "$tree" push --quiet "$remote" "refs/tags/${tag}"
}

# expect_ok <remote> <version> <revision>
expect_ok() {
  local remote="$1" version="$2" revision="$3"
  local output status
  checks=$((checks + 1))
  output="$(PASTURE_TAG_REMOTE="$remote" "$ASSERT" "$version" "$revision" 2>&1)"
  status=$?
  if [ "$status" -ne 0 ]; then
    printf 'FAIL %s %s: expected acceptance, got exit %d\n%s\n' "$version" "$revision" "$status" "$output"
    failures=$((failures + 1))
  fi
}

# expect_reject <label> <expected-substring-of-the-diagnosis> <remote> <args...>
#
# Asserts the rejection AND that the DIAGNOSIS — stderr only — names the reason.
# stdout carries the success trace, which names the tag and the revision, so
# matching the combined streams would let a success line satisfy a check for a
# rejection about the same values.
expect_reject() {
  local label="$1" want="$2" remote="$3"
  shift 3
  local status diagnosis
  local err="${work}/stderr"
  checks=$((checks + 1))
  PASTURE_TAG_REMOTE="$remote" "$ASSERT" "$@" > /dev/null 2> "$err"
  status=$?
  diagnosis="$(cat "$err")"
  if [ "$status" -eq 0 ]; then
    printf 'FAIL %s: expected rejection, got acceptance\n' "$label"
    failures=$((failures + 1))
    return
  fi
  if ! printf '%s\n' "$diagnosis" | grep -qF -- "$want"; then
    printf 'FAIL %s: diagnosis does not mention %q\n%s\n' "$label" "$want" "$diagnosis"
    failures=$((failures + 1))
    return
  fi
  if ! printf '%s\n' "$diagnosis" | grep -q '^error: .* failed in scripts/release/assert-pasture-release-tag.sh: '; then
    printf 'FAIL %s: diagnosis is not an actionable refusal from the script\n%s\n' "$label" "$diagnosis"
    failures=$((failures + 1))
    return
  fi
  if ! printf '%s\n' "$diagnosis" | grep -q '^  fix: '; then
    printf 'FAIL %s: diagnosis carries no fix line\n%s\n' "$label" "$diagnosis"
    failures=$((failures + 1))
  fi
}

readonly OTHER_REVISION='cccccccccccccccccccccccccccccccccccccccc'

# ── Accepted: the tag exists and points at the pinned revision ───────────
remote="$(make_remote annotated)"
head="$(head_of "$remote")"
tag_annotated "$remote" v0.1.0
expect_ok "$remote" 0.1.0 "$head"

# A lightweight tag names its commit directly; the peeled-line preference must
# not make the script blind to it.
light="$(make_remote lightweight)"
light_head="$(head_of "$light")"
tag_lightweight "$light" v0.1.0
expect_ok "$light" 0.1.0 "$light_head"

# ── The tag does not exist ───────────────────────────────────────────────
# The floor names a Pasture release that was never cut. This is the state the
# repository is in until Pasture stamps and publishes its first release.
expect_reject 'unreleased floor' 'has no tag v0.2.0' "$remote" 0.2.0 "$head"

# A remote holding ONLY v0.1.0-rc1 is not a discriminating check that the
# lookup for v0.1.0 actually matched something: it must still refuse with the
# same no-tag diagnosis, not accept the neighbouring rc tag.
tag_annotated "$remote" v0.1.0-rc1
expect_reject 'remote holds only a neighbouring rc tag' 'has no tag v9.9.9' "$remote" 9.9.9 "$head"

# ── A benign stderr warning must not defeat the empty-refs diagnosis ─────
# `git ls-remote` can print a warning on stderr while still exiting 0 with no
# matching ref on stdout (for example a URL-redirect notice). Folding stdout
# and stderr together would leave that warning text sitting in the captured
# output, so the empty-refs branch never fires and the real diagnosis (no such
# tag) is lost. A fake `git` shadows the real one on PATH for this one case,
# emitting exactly that shape: a stderr warning, exit 0, empty stdout.
fake_git_dir="${work}/fake-git-bin"
mkdir -p "$fake_git_dir"
real_git="$(command -v git)"
cat >"${fake_git_dir}/git" <<EOF
#!/usr/bin/env bash
if [ "\$1" = "ls-remote" ]; then
  printf 'warning: redirecting to a canonical URL\n' >&2
  exit 0
fi
exec "${real_git}" "\$@"
EOF
chmod +x "${fake_git_dir}/git"
checks=$((checks + 1))
diagnosis="$(PATH="${fake_git_dir}:${PATH}" PASTURE_TAG_REMOTE="$remote" "$ASSERT" 0.3.0 "$head" 2>&1 1>/dev/null)"
status=$?
if [ "$status" -eq 0 ]; then
  printf 'FAIL benign stderr warning must not mask a missing tag: expected rejection, got acceptance\n'
  failures=$((failures + 1))
elif ! printf '%s\n' "$diagnosis" | grep -qF -- 'has no tag v0.3.0'; then
  printf 'FAIL benign stderr warning must not mask a missing tag: diagnosis does not mention %q\n%s\n' \
    'has no tag v0.3.0' "$diagnosis"
  failures=$((failures + 1))
fi

# ── The tag exists but the pin is a different commit ─────────────────────
# The dangerous case: the binary reports a released version, the release exists,
# and the components were built from something else.
expect_reject 'pinned revision is not the tagged commit' 'but this repository pins' \
  "$remote" 0.1.0 "$OTHER_REVISION"
expect_reject 'the remedy names the tagged commit to pin' "github:dayvidpham/pasture/${head}" \
  "$remote" 0.1.0 "$OTHER_REVISION"

# ── Unreachable remote ───────────────────────────────────────────────────
# Distinguished from "the tag does not exist": one is an infrastructure failure
# to retry, the other is a release defect to fix.
expect_reject 'remote cannot be reached' 'infrastructure failure' \
  "${work}/no-such-repository" 0.1.0 "$head"

# ── Rejected invocations ─────────────────────────────────────────────────
expect_reject 'version carries a leading v' 'not a canonical released version' \
  "$remote" v0.1.0 "$head"
expect_reject 'version is a release candidate' 'not a canonical released version' \
  "$remote" 0.1.0-rc1 "$head"
expect_reject 'revision is not a full revision' 'not a 40-character lowercase Git revision' \
  "$remote" 0.1.0 abc1234
expect_reject 'revision is upper case' 'not a 40-character lowercase Git revision' \
  "$remote" 0.1.0 "$(printf '%s' "$OTHER_REVISION" | tr 'a-f' 'A-F')"
expect_reject 'wrong argument count' 'expected exactly 2 arguments' "$remote" 0.1.0

if [ "$failures" -ne 0 ]; then
  printf '\n%d of %d checks FAILED\n' "$failures" "$checks"
  exit 1
fi
printf 'all %d assert-pasture-release-tag checks passed\n' "$checks"
