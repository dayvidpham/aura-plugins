#!/usr/bin/env bash
# Single source of the Aura aggregate-release version grammar.
#
# Every workflow that needs to decide "is this a release?" and "which version?"
# calls this script instead of embedding its own regex, so the release PR title
# gate, the tag-on-merge job, and the tag guard can never drift apart.
#
# The grammar is deliberately NARROWER than SemVer, and is the intersection of
# two independent constraints:
#
#   1. The release-PR ceremony:            release(vX.Y.Z[-rcN]): <summary>
#   2. The aggregate producer's parser:    pasture artifact.ParseVersion, which
#      rejects a leading "v", build metadata ("+..."), and leading zeros in any
#      numeric component.
#
# A version that passes here is therefore guaranteed to be accepted by
# `aura-aggregate-release --version`, which strips the leading "v".
#
# The same script also owns the SECOND version grammar the release pipeline
# depends on: the version the pinned Pasture binary reports about ITSELF, from
# which the published aggregate's installer compatibility range is derived. Both
# grammars answer the same question with the same vocabulary — "is this string a
# canonical release version, and which one?" — so they are kept in one place and
# proved by one suite.
#
# Usage:
#   release-grammar.sh parse-title             "release(v1.2.3-rc1): cut the first aggregate"
#   release-grammar.sh parse-tag               "v1.2.3-rc1"
#   release-grammar.sh installer-compatibility "pasture version v1.2.3"
#
# On success prints KEY=VALUE lines on stdout, suitable for appending straight
# to "$GITHUB_OUTPUT":
#
#   parse-title / parse-tag (three lines)
#     version=1.2.3-rc1      (producer form: no leading v)
#     tag=v1.2.3-rc1         (git tag form:  leading v)
#     kind=rc                (rc | final)
#
#   installer-compatibility (two lines)
#     installer_min=1.2.3    the pinned Pasture's own released version
#     installer_max=0.99.99  the open ceiling (see INSTALLER_CEILING below)
#
# On failure prints an actionable diagnosis to stderr and exits 1.

set -euo pipefail

readonly PROGRAM_NAME="scripts/release/release-grammar.sh"

# A canonical numeric component: 0, or a non-zero digit followed by more digits.
# Leading zeros are rejected because the producer rejects them.
#
# Width is bounded to 17 digits. The producer parses each numeric component with
# a 64-bit unsigned parser, so an unbounded pattern would let this grammar
# accept a version that the producer rejects at build time — after the tag is
# already permanent. Capping at 17 digits keeps every accepted value below
# 10^17, far inside uint64, so grammar-accepted is a strict subset of
# producer-accepted. The bound is deliberately CONSERVATIVE: the producer would
# accept some wider values, but no real release needs them, and the gate in
# .github/workflows/gates.yml proves the subset relation against the real
# producer binary rather than assuming it.
readonly NUMBER='(0|[1-9][0-9]{0,16})'
readonly RC_NUMBER='[1-9][0-9]{0,16}'
readonly TAG_PATTERN="^v${NUMBER}\.${NUMBER}\.${NUMBER}(-rc${RC_NUMBER})?$"
readonly TITLE_PATTERN="^release\(([^)]*)\): (.+)$"

# The shape `pasture --version` prints for a RELEASED build: the tag it was
# built from, and nothing else. A development build reports a different,
# deliberately distinguishable shape (a devel marker and/or a commit), and is
# refused by this pattern rather than by an enumeration of devel shapes — the
# assertion is "this binary is a tagged release", so anything that is not
# exactly a release version fails, whatever it looks like.
#
# Release candidates are excluded on purpose: installer_min is the floor an
# installer must meet to activate the aggregate, and a floor that only a
# prerelease installer satisfies would make the published aggregate
# unactivatable by every stable installer.
readonly PASTURE_VERSION_PATTERN="^pasture version v(${NUMBER}\.${NUMBER}\.${NUMBER})$"

# The open upper bound of the published installer compatibility range.
#
# The producer's manifest requires both bounds, but the CONSUMER — not this
# repository — owns the ceiling: an installer that cannot activate a
# pasture.aggregate-release/v1 manifest refuses it BY SCHEMA, which is the real
# upper guard. A numeric ceiling pinned to the version that happens to be
# current would instead make every aggregate uninstallable by every future
# installer, permanently, because the range is frozen into an immutable
# manifest.
#
# 0.99.99 is therefore an unreachable-in-practice sentinel rather than a claim
# about a specific installer: it says "no upper bound is asserted here". Making
# the bound formally optional, plus an explicit escape hatch for development
# builds, is tracked in the Pasture contract:
#   https://github.com/dayvidpham/pasture/issues/39
readonly INSTALLER_CEILING='0.99.99'

readonly GRAMMAR_HELP='the accepted grammar is release(vMAJOR.MINOR.PATCH): <summary> for a final release, or release(vMAJOR.MINOR.PATCH-rcN): <summary> for a release candidate — for example "release(v0.1.0): first immutable aggregate" or "release(v0.1.0-rc1): first aggregate candidate". Every numeric component must be canonical base-10 with no leading zero, N must be 1 or greater, no numeric component may exceed 17 digits, and build metadata (+...) is not accepted because the aggregate producer rejects it.'

# fail <what-went-wrong> <why> <impact> <how-to-fix>
fail() {
  local what="$1" why="$2" impact="$3" fix="$4"
  printf 'error: %s failed in %s: %s\n' "$what" "$PROGRAM_NAME" "$why" >&2
  printf '  impact: %s\n' "$impact" >&2
  printf '  fix: %s\n' "$fix" >&2
  exit 1
}

# emit_version <tag>
#
# Classifies an already-grammar-checked tag and writes the three output lines.
emit_version() {
  local tag="$1"
  local version="${tag#v}"
  local kind='final'
  case "$version" in
    *-rc*) kind='rc' ;;
  esac
  printf 'version=%s\n' "$version"
  printf 'tag=%s\n' "$tag"
  printf 'kind=%s\n' "$kind"
}

# reject_control_characters <value> <what> <source-description>
#
# POSIX regex matching treats a newline as an ordinary character, so an anchored
# pattern alone does NOT stop a multi-line value: ".+$" happily spans newlines.
# Every caller appends this script's stdout to $GITHUB_OUTPUT and feeds the PR
# title to `git tag -m`, so a multi-line value is refused outright rather than
# relied upon to be harmless downstream.
reject_control_characters() {
  local value="$1" what="$2" source="$3"
  if [[ "$value" =~ [[:cntrl:]] ]]; then
    fail "validating ${what}" \
      "${source} contains a control character such as a newline or tab" \
      "the value would be written into a workflow output and a Git tag message, where an embedded newline can inject content that was never reviewed" \
      "put the whole release marker on a single line with no tab or newline characters"
  fi
}

# require_tag_grammar <tag> <source-description>
require_tag_grammar() {
  local tag="$1" source="$2"
  if [[ ! "$tag" =~ $TAG_PATTERN ]]; then
    fail "validating the release version" \
      "${source} yielded \"${tag}\", which is not a canonical Aura aggregate release version" \
      "the release cannot be identified, so no immutable tag or aggregate manifest can be produced from it" \
      "$GRAMMAR_HELP"
  fi
}

parse_title() {
  local title="$1"
  if [ -z "$title" ]; then
    fail "validating the release PR title" \
      "the title is empty, so no release version could be read from it" \
      "the release PR cannot be classified and must not be merged" \
      "$GRAMMAR_HELP"
  fi
  reject_control_characters "$title" "the release PR title" "the title"
  if [[ ! "$title" =~ $TITLE_PATTERN ]]; then
    fail "validating the release PR title" \
      "the title \"${title}\" does not match release(<version>): <summary>" \
      "the release PR cannot be classified and must not be merged" \
      "$GRAMMAR_HELP"
  fi
  local tag="${BASH_REMATCH[1]}"
  local summary="${BASH_REMATCH[2]}"
  require_tag_grammar "$tag" "the release PR title \"${title}\""
  # Reject a blank-only summary; the tag message is built from the title.
  if [[ ! "$summary" =~ [^[:space:]] ]]; then
    fail "validating the release PR title" \
      "the summary after \"release(${tag}): \" is blank" \
      "the annotated tag would carry an empty message, losing the reason the release was cut" \
      "describe the release after the colon, for example \"release(${tag}): first immutable aggregate\""
  fi
  emit_version "$tag"
}

parse_tag() {
  local tag="$1"
  if [ -z "$tag" ]; then
    fail "validating the release tag" \
      "the tag is empty, so no release version could be read from it" \
      "the tagged build cannot be classified and must not publish a release" \
      "$GRAMMAR_HELP"
  fi
  reject_control_characters "$tag" "the release tag" "the tag"
  require_tag_grammar "$tag" "the pushed tag"
  emit_version "$tag"
}

# installer_compatibility <pasture --version output>
#
# Derives the published aggregate's installer compatibility range from the
# pinned Pasture binary itself. The producer declares the FORMAT and the
# MINIMUM; the consumer owns the ceiling.
installer_compatibility() {
  local reported="$1"
  if [ -z "$reported" ]; then
    fail "deriving the installer compatibility range" \
      "the pinned Pasture binary printed nothing for --version" \
      "the aggregate's installer compatibility range cannot be derived, so nothing may be produced or published from this run" \
      "confirm the pinned Pasture revision builds a working 'pasture' binary and that 'pasture --version' prints 'pasture version vX.Y.Z'"
  fi
  # No separate control-character check is needed here: the pattern below is
  # anchored and admits only digits and dots after the prefix, and a POSIX
  # regex "$" matches the end of the whole string rather than a line, so a
  # multi-line or tab-bearing --version output cannot match it.
  if [[ ! "$reported" =~ $PASTURE_VERSION_PATTERN ]]; then
    fail "deriving the installer compatibility range" \
      "the pinned Pasture binary reported \"${reported}\", which is not a released version of the form 'pasture version vX.Y.Z'" \
      "the aggregate's installer_min would claim a compatibility floor that names no published Pasture release, and that claim is frozen into an immutable manifest that can never be corrected — only superseded — so nothing was produced or published" \
      "an aggregate cannot be cut against an untagged Pasture. Pin a RELEASED Pasture revision: cut the Pasture release first, then re-lock this repository's input with 'nix flake update pasture' on the release PR so the pinned build reports its tag instead of a development version. Release candidates are refused too: installer_min is the floor every installer must meet, so it must be a final release"
  fi
  printf 'installer_min=%s\n' "${BASH_REMATCH[1]}"
  printf 'installer_max=%s\n' "$INSTALLER_CEILING"
}

usage() {
  cat >&2 <<USAGE
${PROGRAM_NAME} — validate and classify an Aura aggregate release version.

Usage:
  ${PROGRAM_NAME} parse-title             "release(vX.Y.Z[-rcN]): <summary>"
  ${PROGRAM_NAME} parse-tag               "vX.Y.Z[-rcN]"
  ${PROGRAM_NAME} installer-compatibility "pasture version vX.Y.Z"

parse-title and parse-tag print version=, tag=, and kind= on stdout;
installer-compatibility prints installer_min= and installer_max=. Each exits 1
with an actionable diagnosis on stderr when its input does not match the
grammar it enforces.
USAGE
}

main() {
  if [ "$#" -ne 2 ]; then
    usage
    fail "parsing command-line arguments" \
      "expected exactly one subcommand and one value but received $# argument(s)" \
      "no release version was classified" \
      "invoke it as '${PROGRAM_NAME} parse-title \"<pr title>\"', '${PROGRAM_NAME} parse-tag \"<tag>\"', or '${PROGRAM_NAME} installer-compatibility \"<pasture --version output>\"'"
  fi
  case "$1" in
    parse-title) parse_title "$2" ;;
    parse-tag)   parse_tag "$2" ;;
    installer-compatibility) installer_compatibility "$2" ;;
    *)
      usage
      fail "selecting a subcommand" \
        "\"$1\" is not a known subcommand" \
        "no release version was classified" \
        "use parse-title, parse-tag, or installer-compatibility"
      ;;
  esac
}

main "$@"
