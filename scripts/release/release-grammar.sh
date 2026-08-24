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
# Usage:
#   release-grammar.sh parse-title "release(v1.2.3-rc1): cut the first aggregate"
#   release-grammar.sh parse-tag   "v1.2.3-rc1"
#
# On success prints, on stdout, three KEY=VALUE lines suitable for appending
# straight to "$GITHUB_OUTPUT":
#   version=1.2.3-rc1      (producer form: no leading v)
#   tag=v1.2.3-rc1         (git tag form:  leading v)
#   kind=rc                (rc | final)
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

usage() {
  cat >&2 <<USAGE
${PROGRAM_NAME} — validate and classify an Aura aggregate release version.

Usage:
  ${PROGRAM_NAME} parse-title "release(vX.Y.Z[-rcN]): <summary>"
  ${PROGRAM_NAME} parse-tag   "vX.Y.Z[-rcN]"

Prints version=, tag=, and kind= on stdout; exits 1 with an actionable
diagnosis on stderr when the input does not match the release grammar.
USAGE
}

main() {
  if [ "$#" -ne 2 ]; then
    usage
    fail "parsing command-line arguments" \
      "expected exactly one subcommand and one value but received $# argument(s)" \
      "no release version was classified" \
      "invoke it as '${PROGRAM_NAME} parse-title \"<pr title>\"' or '${PROGRAM_NAME} parse-tag \"<tag>\"'"
  fi
  case "$1" in
    parse-title) parse_title "$2" ;;
    parse-tag)   parse_tag "$2" ;;
    *)
      usage
      fail "selecting a subcommand" \
        "\"$1\" is not a known subcommand" \
        "no release version was classified" \
        "use parse-title or parse-tag"
      ;;
  esac
}

main "$@"
