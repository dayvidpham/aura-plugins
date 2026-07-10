#!/usr/bin/env bash
# PreToolUse hook: block destructive git operations for worker agents on
# shared worktrees.
#
# Why this exists:
#   The /aura:worker skill prose forbids destructive git ops on shared
#   worktrees (git reset --hard, git checkout HEAD -- <path>, git stash
#   pop/apply, git clean -fd, git branch -D). The rule has been broken
#   twice in real epics with real data loss (S4 wipe; W5 wipe of W3 mid
#   Phase 10 — see aura-plugins-0sfqy). This hook is the runtime backstop.
#
# Behaviour:
#   - Reads the PreToolUse JSON event from stdin.
#   - Activates only when tool_name == "Bash" AND AURA_ROLE == "worker".
#     For other roles or tools, exits 0 silently (no-op).
#   - When the Bash command matches a forbidden pattern, prints a
#     plain-language error to stderr and exits 2 (blocking error).
#   - Provides an env-var escape hatch: set BYPASS_GIT_DISCIPLINE=1 in the
#     environment of the agent session to skip enforcement entirely
#     (intended for "I'm alone on this branch" cases — must be justified
#     in a bd comment).
#
# Hooks must NOT block on transient failure: if jq is missing or the
# input cannot be parsed, the hook exits 0 (allow) rather than 2
# (block) — failing open is the right choice for a backstop because
# the skill prose remains the primary authority.
#
# Historical test coverage lived in the retired Python test suite.

set -uo pipefail

# ── Escape hatch ──────────────────────────────────────────────────────────────
# Worker can bypass this hook for a single command by exporting
# BYPASS_GIT_DISCIPLINE=1 (e.g. resolving a merge conflict on a branch
# they alone own). Bypass must be recorded in a bd comment.
if [[ "${BYPASS_GIT_DISCIPLINE:-0}" == "1" ]]; then
    exit 0
fi

# ── Read PreToolUse event from stdin ──────────────────────────────────────────
input=$(cat)

# Tool name and command extraction. If jq is unavailable or the JSON is
# malformed, fall back to allow (exit 0) — see "fail open" note above.
if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)
if [[ "$tool_name" != "Bash" ]]; then
    exit 0
fi

# ── Role gating ───────────────────────────────────────────────────────────────
# This hook only enforces against worker agents. Supervisors, architects,
# reviewers, and the human user driving the harness are unaffected.
role="${AURA_ROLE:-}"
if [[ "$role" != "worker" ]]; then
    exit 0
fi

# ── Extract the bash command ──────────────────────────────────────────────────
command_str=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
if [[ -z "$command_str" ]]; then
    exit 0
fi

# ── Pattern detection ─────────────────────────────────────────────────────────
# Each pattern MUST be a regex matched against the full command string.
# We deliberately use word-boundary-ish anchors (^|[ \t;&|]) so that a
# substring like "echo 'git reset --hard'" doesn't accidentally match,
# while real invocations and pipelines (e.g. "true && git reset --hard")
# do.
#
# matched_label is the human-readable name of the violated rule.
matched_label=""
matched_pattern=""

# Helper: match pattern against command_str. Sets matched_label and
# matched_pattern on first hit, and returns 0 (true) once matched.
_match() {
    local label="$1"
    local pattern="$2"
    if [[ -z "$matched_label" ]] && [[ "$command_str" =~ $pattern ]]; then
        matched_label="$label"
        matched_pattern="$pattern"
    fi
}

# git reset --hard (any args)
_match "git reset --hard"             '(^|[[:space:]]|;|&|\|)git[[:space:]]+reset[[:space:]]+--hard($|[[:space:]])'

# git checkout HEAD -- <path>  (also covers `git checkout HEAD~N -- ...`)
_match "git checkout HEAD -- <path>"  '(^|[[:space:]]|;|&|\|)git[[:space:]]+checkout[[:space:]]+HEAD[~^0-9]*[[:space:]]+--[[:space:]]'

# git restore --source=HEAD <path>  (modern equivalent of the above)
_match "git restore --source=HEAD"    '(^|[[:space:]]|;|&|\|)git[[:space:]]+restore[[:space:]]+(--source=HEAD|--source[[:space:]]+HEAD)'

# git stash pop
_match "git stash pop"                '(^|[[:space:]]|;|&|\|)git[[:space:]]+stash[[:space:]]+pop($|[[:space:]])'

# git stash apply
_match "git stash apply"              '(^|[[:space:]]|;|&|\|)git[[:space:]]+stash[[:space:]]+apply($|[[:space:]])'

# git clean -fd  (also -fdx, -dfx, -df, -xdf, etc.; require f and d in the flag bundle)
_match "git clean -fd"                '(^|[[:space:]]|;|&|\|)git[[:space:]]+clean[[:space:]]+(-[a-zA-Z]*f[a-zA-Z]*d[a-zA-Z]*|-[a-zA-Z]*d[a-zA-Z]*f[a-zA-Z]*)($|[[:space:]])'

# git branch -D <name>  (capital D = force-delete)
_match "git branch -D"                '(^|[[:space:]]|;|&|\|)git[[:space:]]+branch[[:space:]]+(-D|--delete[[:space:]]+--force|-[a-zA-Z]*D[a-zA-Z]*)($|[[:space:]])'

# git rebase --abort
# NOTE: this is "soft-forbidden" — only dangerous when peers depend on
# the branch. We deny it the same way as the others; the worker can use
# the BYPASS_GIT_DISCIPLINE escape hatch when they are alone on the
# branch (the typical legitimate case).
_match "git rebase --abort"           '(^|[[:space:]]|;|&|\|)git[[:space:]]+rebase[[:space:]]+--abort($|[[:space:]])'

if [[ -z "$matched_label" ]]; then
    # Benign git command (status, log, diff, add by name, agent-commit, etc.) — allow.
    exit 0
fi

# ── Block: emit a plain-language error and exit 2 ─────────────────────────────
# Format follows the project-wide convention in
# /home/minttea/.claude/projects/.../memory/feedback_plain_language_errors.md:
# short top line, vertical-aligned labels (Problem / Reason / Where /
# Impact / How to fix), numbered fix steps with concrete commands.

cat >&2 <<EOF
Error: This destructive git operation is blocked for worker agents.

  Problem:   You tried to run \`${matched_label}\`, which would discard
             uncommitted work in this worktree — including changes by
             other workers running in parallel against the same tree.
  Reason:    Workers share the worktree. Destructive git operations
             here have already caused two real incidents during recent
             epics (aura-plugins-0sfqy: S4 wipe; W5 wipe of W3 during
             Phase 10 fix wave).
  Where:     Worker pre-tool-use git-discipline hook
             (hooks/scripts/git-discipline.sh).
  Impact:    Your command was blocked. Nothing in the worktree changed.
             You still need to decide how to proceed (see "How to fix").
  How to fix:
    1. If you wanted to discard your own staged changes only, use the
       safe per-file form (does not affect peer worker work):
         git restore --staged <specific-files>
       or, to drop your unstaged edits to a specific file:
         git restore <specific-files>
    2. If unexpected files in the worktree are blocking your fix,
       they are almost certainly peer-worker work-in-progress.
       Do NOT clean them up. Post a coordination comment on your
       slice task and wait for supervisor direction:
         bd comments add <your-task-id> "Blocked: peer-worker changes present in <files>; need supervisor coordination."
    3. If you genuinely need to run this command (for example,
       resolving a merge conflict on a branch where you are the only
       worker), bypass this hook for that single command by setting:
         BYPASS_GIT_DISCIPLINE=1 ${matched_label} <args>
       and record in a \`bd comments add\` why the bypass was needed.
    4. Full rationale and the list of all forbidden ops is in the
       \`/aura:worker\` skill under "Shared-Worktree Git Discipline".

EOF

exit 2
