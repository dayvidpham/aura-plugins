"""Tests for hooks/scripts/git-discipline.sh — PreToolUse hook that blocks
destructive git operations for worker agents on shared worktrees.

Background:
    The /aura:worker skill prose forbids destructive git operations on
    shared worktrees because peer-worker work can be silently destroyed.
    This rule was violated twice in real epics with real data loss
    (S4 wipe; W5 wipe of W3 during Phase 10 — see aura-plugins-0sfqy).
    The git-discipline.sh PreToolUse hook is the runtime backstop.

BDD Acceptance Criteria:
    AC-G1: Given AURA_ROLE != "worker", when the hook receives any Bash
           command (including forbidden ones), then it exits 0 (allow).
    AC-G2: Given AURA_ROLE == "worker" and a benign git command (status,
           log, diff, add by name), when the hook runs, then it exits 0.
    AC-G3: Given AURA_ROLE == "worker" and a forbidden command (git
           reset --hard, git checkout HEAD -- <path>, git stash pop,
           git stash apply, git clean -fd, git branch -D, git restore
           --source=HEAD, git rebase --abort), when the hook runs, then
           it exits 2 (block) and emits a plain-language error.
    AC-G4: Given BYPASS_GIT_DISCIPLINE=1, when the hook receives a
           forbidden command, then it exits 0 (escape hatch honoured).
    AC-G5: Given tool_name != "Bash" (e.g. Read/Edit/Write), when the
           hook runs, then it exits 0 (no-op for non-Bash tools).
    AC-G6: Given pipelines, command chains, and quoting variations,
           when a forbidden git invocation appears, then it is detected
           and blocked; benign substrings inside echo/grep arguments
           are not falsely matched.
    AC-G7: Given the hook blocks, when emitting the error, then the
           error follows the project plain-language convention (Error:
           top line, Problem/Reason/Where/Impact/How to fix labels,
           numbered fix steps).

Coverage strategy:
    The hook script is invoked via subprocess with synthetic PreToolUse
    JSON on stdin and the relevant env vars set. Exit code and stderr
    are asserted directly. No mocking of the script itself — it is the
    system under test.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest

# ─── Constants ─────────────────────────────────────────────────────────────────

HOOK_SCRIPT = (
    Path(__file__).parent.parent / "hooks" / "scripts" / "git-discipline.sh"
)
BASH = shutil.which("bash") or "bash"


# ─── Helpers ───────────────────────────────────────────────────────────────────


def _run_hook(
    *,
    tool_name: str = "Bash",
    command: str = "",
    role: str | None = "worker",
    bypass: bool = False,
    extra_env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess:
    """Invoke git-discipline.sh with a synthetic PreToolUse event on stdin.

    The PreToolUse JSON shape mirrors what Claude Code sends in production
    (see hook-development SKILL.md): tool_name + tool_input.command for
    Bash, tool_name + tool_input.file_path for Read/Edit/Write, etc.
    """
    payload: dict[str, object] = {"tool_name": tool_name}
    if tool_name == "Bash":
        payload["tool_input"] = {"command": command}
    else:
        payload["tool_input"] = {"file_path": command} if command else {}

    env: dict[str, str] = {
        "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
    }
    if role is not None:
        env["AURA_ROLE"] = role
    if bypass:
        env["BYPASS_GIT_DISCIPLINE"] = "1"
    if extra_env:
        env.update(extra_env)

    return subprocess.run(
        [BASH, str(HOOK_SCRIPT)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        env=env,
        timeout=10,
    )


# ─── Sanity ────────────────────────────────────────────────────────────────────


class TestHookScriptInstallation:
    """The hook script must exist and be executable so that Claude Code
    can invoke it from the hooks.json registration."""

    def test_hook_script_exists(self) -> None:
        assert HOOK_SCRIPT.exists(), (
            f"Hook script not found at {HOOK_SCRIPT}. The PreToolUse "
            f"registration in hooks/hooks.json points here, so the script "
            f"must be present in the source repo."
        )

    def test_hook_script_is_executable(self) -> None:
        assert os.access(HOOK_SCRIPT, os.X_OK), (
            f"Hook script is not executable: {HOOK_SCRIPT}. Run "
            f"`chmod +x {HOOK_SCRIPT}` and recommit."
        )

    def test_hook_registered_in_hooks_json(self) -> None:
        """hooks.json registers git-discipline.sh as a Bash PreToolUse hook."""
        hooks_json = Path(__file__).parent.parent / "hooks" / "hooks.json"
        config = json.loads(hooks_json.read_text())
        pre_tool_use = config.get("hooks", {}).get("PreToolUse", [])
        assert pre_tool_use, "hooks.json missing PreToolUse registration"
        commands = [
            h["command"]
            for entry in pre_tool_use
            for h in entry.get("hooks", [])
            if h.get("type") == "command"
        ]
        assert any("git-discipline.sh" in c for c in commands), (
            f"git-discipline.sh not registered in hooks.json PreToolUse. "
            f"Found commands: {commands}"
        )


# ─── AC-G1: role gating ────────────────────────────────────────────────────────


class TestRoleGating:
    """AC-G1: hook only enforces against worker agents."""

    @pytest.mark.parametrize(
        "role",
        ["supervisor", "architect", "reviewer", "user", ""],
    )
    def test_non_worker_roles_allow_destructive_ops(self, role: str) -> None:
        """Supervisors, architects, reviewers, and unset role all bypass."""
        result = _run_hook(command="git reset --hard HEAD", role=role)
        assert result.returncode == 0, (
            f"Expected exit 0 for role={role!r} (non-worker), got "
            f"{result.returncode}. stderr={result.stderr!r}"
        )

    def test_role_unset_allows_destructive_ops(self) -> None:
        """If AURA_ROLE is not in the environment at all, allow."""
        result = _run_hook(command="git reset --hard HEAD", role=None)
        assert result.returncode == 0, (
            f"Expected exit 0 when AURA_ROLE unset, got {result.returncode}. "
            f"stderr={result.stderr!r}"
        )


# ─── AC-G2: benign commands ────────────────────────────────────────────────────


class TestBenignCommandsAllowed:
    """AC-G2: workers can run normal/safe git commands without being blocked."""

    @pytest.mark.parametrize(
        "command",
        [
            "git status",
            "git status --short",
            "git log",
            "git log --oneline -10",
            "git diff",
            "git diff --staged",
            "git show HEAD",
            "git add cmd/feature/list.go",
            "git add pkg/feature/service.go pkg/feature/types.go",
            "git restore --staged cmd/feature/list.go",
            "git restore cmd/feature/list.go",
            "git agent-commit -m 'feat: x'",
            "git fetch",
            "git pull --rebase",
            "git branch",
            "git branch -a",
            "git stash list",
            "git stash show",
            "ls -la",
            "echo hello",
            "make test",
            "go test ./...",
        ],
    )
    def test_benign_command_allowed(self, command: str) -> None:
        result = _run_hook(command=command, role="worker")
        assert result.returncode == 0, (
            f"Benign command {command!r} should be allowed, got exit "
            f"{result.returncode}. stderr={result.stderr!r}"
        )


# ─── AC-G3: forbidden commands blocked ─────────────────────────────────────────


class TestForbiddenCommandsBlocked:
    """AC-G3: each forbidden git operation is detected and blocked
    with a plain-language error and exit code 2."""

    @pytest.mark.parametrize(
        ("command", "expected_label_substring"),
        [
            # git reset --hard variants
            ("git reset --hard", "git reset --hard"),
            ("git reset --hard HEAD", "git reset --hard"),
            ("git reset --hard HEAD~1", "git reset --hard"),
            ("git reset --hard origin/main", "git reset --hard"),
            # git checkout HEAD -- <path>
            ("git checkout HEAD -- foo.go", "git checkout HEAD"),
            (
                "git checkout HEAD -- internal/tasks/free_floating.go",
                "git checkout HEAD",
            ),
            ("git checkout HEAD~1 -- foo.go", "git checkout HEAD"),
            # git restore --source=HEAD (modern equivalent)
            ("git restore --source=HEAD foo.go", "git restore"),
            ("git restore --source HEAD foo.go", "git restore"),
            # git stash pop / apply
            ("git stash pop", "git stash pop"),
            ("git stash apply", "git stash apply"),
            ("git stash apply stash@{0}", "git stash apply"),
            # git clean -fd / -fdx / -dfx
            ("git clean -fd", "git clean"),
            ("git clean -fdx", "git clean"),
            ("git clean -dfx", "git clean"),
            ("git clean -df", "git clean"),
            # git branch -D
            ("git branch -D feature/test", "git branch"),
            ("git branch -Df feature/test", "git branch"),
            # git rebase --abort
            ("git rebase --abort", "git rebase --abort"),
        ],
    )
    def test_forbidden_command_blocked(
        self, command: str, expected_label_substring: str
    ) -> None:
        result = _run_hook(command=command, role="worker")
        assert result.returncode == 2, (
            f"Forbidden command {command!r} should be blocked with exit 2, "
            f"got {result.returncode}. stderr={result.stderr!r}"
        )
        # The error names which rule was violated, so the worker can act.
        assert expected_label_substring in result.stderr, (
            f"Error message should mention {expected_label_substring!r} "
            f"so the worker knows which rule fired. stderr={result.stderr!r}"
        )


# ─── AC-G4: escape hatch ───────────────────────────────────────────────────────


class TestEscapeHatch:
    """AC-G4: BYPASS_GIT_DISCIPLINE=1 lets the worker run a single
    forbidden command (intended for "I'm alone on this branch" cases)."""

    @pytest.mark.parametrize(
        "command",
        [
            "git reset --hard HEAD",
            "git stash pop",
            "git clean -fd",
            "git checkout HEAD -- foo.go",
            "git branch -D feature/test",
        ],
    )
    def test_bypass_flag_allows_forbidden_command(self, command: str) -> None:
        result = _run_hook(command=command, role="worker", bypass=True)
        assert result.returncode == 0, (
            f"With BYPASS_GIT_DISCIPLINE=1, forbidden command {command!r} "
            f"should be allowed, got exit {result.returncode}. "
            f"stderr={result.stderr!r}"
        )

    def test_bypass_zero_is_not_bypass(self) -> None:
        """BYPASS_GIT_DISCIPLINE=0 (any value other than '1') does not bypass."""
        result = _run_hook(
            command="git reset --hard HEAD",
            role="worker",
            extra_env={"BYPASS_GIT_DISCIPLINE": "0"},
        )
        assert result.returncode == 2, (
            f"BYPASS_GIT_DISCIPLINE=0 should NOT bypass, got exit "
            f"{result.returncode}. stderr={result.stderr!r}"
        )


# ─── AC-G5: non-Bash tools ─────────────────────────────────────────────────────


class TestNonBashToolsAllowed:
    """AC-G5: hook is a no-op for tools other than Bash."""

    @pytest.mark.parametrize("tool", ["Read", "Edit", "Write", "Glob", "Grep"])
    def test_non_bash_tool_is_noop(self, tool: str) -> None:
        # Even if the file_path *contained* "git reset --hard" text, the
        # hook should not look at non-Bash tools.
        result = _run_hook(tool_name=tool, command="git reset --hard", role="worker")
        assert result.returncode == 0, (
            f"Non-Bash tool {tool} should be no-op, got exit "
            f"{result.returncode}. stderr={result.stderr!r}"
        )


# ─── AC-G6: command-shape edge cases ───────────────────────────────────────────


class TestCommandShapeEdgeCases:
    """AC-G6: pipelines and chains containing forbidden commands ARE
    detected; benign text containing the forbidden words is NOT
    falsely matched."""

    @pytest.mark.parametrize(
        "command",
        [
            # Forbidden command appears after a chain operator
            "true && git reset --hard HEAD",
            "false || git reset --hard HEAD",
            "git status; git reset --hard HEAD",
            "echo go && git stash pop",
            "git fetch && git reset --hard origin/main",
        ],
    )
    def test_pipeline_with_forbidden_command_blocked(self, command: str) -> None:
        result = _run_hook(command=command, role="worker")
        assert result.returncode == 2, (
            f"Pipeline {command!r} contains a forbidden git op and must be "
            f"blocked, got exit {result.returncode}. stderr={result.stderr!r}"
        )

    @pytest.mark.parametrize(
        "command",
        [
            # Benign substring matches: forbidden tokens appearing inside
            # quoted echo/grep arguments must NOT trigger the block. The
            # hook recognises that `'git reset --hard'` (preceded by a
            # quote, not whitespace/chain-operator) is not a real
            # invocation.
            "echo 'do not run git reset --hard'",
            "grep 'git stash pop' README.md",
            "echo 'git clean -fd is forbidden'",
        ],
    )
    def test_benign_text_containing_forbidden_words_allowed(
        self, command: str
    ) -> None:
        # The hook uses word-boundary regexes that anchor on whitespace
        # or chain operators (^|space|tab|;|&|\|). Forbidden tokens
        # inside single-quoted arguments are preceded by `'`, not by an
        # anchor, so they do not match.
        #
        # KNOWN over-match (deliberate, conservative): bare shell
        # comments like `make build  # do not run git reset --hard later`
        # WILL be blocked. This is the correct tradeoff for a backstop —
        # if you genuinely need such a comment, set
        # BYPASS_GIT_DISCIPLINE=1. We do NOT add such cases here because
        # they should remain blocked.
        result = _run_hook(command=command, role="worker")
        assert result.returncode == 0, (
            f"Benign command {command!r} (forbidden token only inside "
            f"quoted arg) should be allowed, got exit "
            f"{result.returncode}. stderr={result.stderr!r}"
        )

    def test_bare_shell_comment_with_forbidden_token_is_conservatively_blocked(
        self,
    ) -> None:
        """Document and lock in the deliberate over-match: a bare shell
        comment containing a forbidden token IS blocked. This is the
        correct conservative behaviour for a backstop hook — workers
        should use BYPASS_GIT_DISCIPLINE=1 if they hit this edge case.
        """
        result = _run_hook(
            command="make build  # do not run git reset --hard after this",
            role="worker",
        )
        assert result.returncode == 2, (
            "Bare comments containing forbidden tokens are deliberately "
            "blocked (conservative backstop). If this assertion fails, "
            "either the hook regex was loosened or the conservative "
            "policy was reversed — update the policy doc accordingly."
        )


# ─── AC-G7: error message conforms to plain-language convention ────────────────


class TestErrorMessagePlainLanguage:
    """AC-G7: blocking errors must be readable by non-specialists.
    The format is set by the project memory note
    feedback_plain_language_errors.md (Phase 11 UAT)."""

    @pytest.fixture
    def blocked_stderr(self) -> str:
        result = _run_hook(command="git reset --hard HEAD", role="worker")
        assert result.returncode == 2, "test setup expected a block"
        return result.stderr

    def test_top_line_starts_with_Error(self, blocked_stderr: str) -> None:
        first_line = blocked_stderr.lstrip().splitlines()[0]
        assert first_line.startswith("Error:"), (
            f"Top line should start with 'Error:' per plain-language "
            f"convention (no internal jargon like ValidationError:). "
            f"Got: {first_line!r}"
        )

    @pytest.mark.parametrize(
        "label",
        ["Problem:", "Reason:", "Where:", "Impact:", "How to fix:"],
    )
    def test_has_required_plain_language_label(
        self, blocked_stderr: str, label: str
    ) -> None:
        assert label in blocked_stderr, (
            f"Plain-language error must include the {label!r} label. "
            f"Full stderr:\n{blocked_stderr}"
        )

    def test_how_to_fix_is_numbered(self, blocked_stderr: str) -> None:
        """How to fix steps are numbered (1., 2., 3.) per the convention."""
        for n in (1, 2, 3):
            assert f"{n}." in blocked_stderr, (
                f"How to fix should have a step '{n}.' (numbered "
                f"alternatives, not parallel prose). Full stderr:\n"
                f"{blocked_stderr}"
            )

    def test_mentions_bd_comments_coordination(self, blocked_stderr: str) -> None:
        """The error must point the worker at the correct coordination
        path (bd comments add) instead of letting them improvise."""
        assert "bd comments add" in blocked_stderr, (
            "Error must instruct worker to coordinate via 'bd comments "
            "add' instead of unilaterally resolving via destructive ops. "
            f"Full stderr:\n{blocked_stderr}"
        )

    def test_mentions_bypass_escape_hatch(self, blocked_stderr: str) -> None:
        """Workers must be told the escape hatch exists so legitimate
        cases (alone on branch, merge conflict resolution) aren't stuck."""
        assert "BYPASS_GIT_DISCIPLINE" in blocked_stderr, (
            "Error must document the BYPASS_GIT_DISCIPLINE=1 escape "
            "hatch for legitimate forbidden-op cases. "
            f"Full stderr:\n{blocked_stderr}"
        )

    def test_references_incident_context(self, blocked_stderr: str) -> None:
        """The error references the incident finding so reviewers can
        trace the rule back to its origin."""
        assert "aura-plugins-0sfqy" in blocked_stderr, (
            "Error must reference the originating finding "
            "(aura-plugins-0sfqy) for traceability. "
            f"Full stderr:\n{blocked_stderr}"
        )


# ─── Failure-mode handling ─────────────────────────────────────────────────────


class TestFailureModes:
    """The hook must fail open (allow) on transient failures so that a
    broken hook never permanently blocks the worker. The skill prose
    remains the primary authority — the hook is a backstop."""

    def test_malformed_json_does_not_block(self) -> None:
        """If stdin isn't valid JSON, exit 0 (allow) — failing closed
        would brick the worker on every Bash call."""
        env = {
            "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
            "AURA_ROLE": "worker",
        }
        result = subprocess.run(
            [BASH, str(HOOK_SCRIPT)],
            input="this is not json {",
            capture_output=True,
            text=True,
            env=env,
            timeout=10,
        )
        assert result.returncode == 0, (
            f"Malformed JSON should fail open (exit 0), got "
            f"{result.returncode}. stderr={result.stderr!r}"
        )

    def test_empty_stdin_does_not_block(self) -> None:
        """Empty stdin should fail open."""
        env = {
            "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
            "AURA_ROLE": "worker",
        }
        result = subprocess.run(
            [BASH, str(HOOK_SCRIPT)],
            input="",
            capture_output=True,
            text=True,
            env=env,
            timeout=10,
        )
        assert result.returncode == 0, (
            f"Empty stdin should fail open (exit 0), got "
            f"{result.returncode}. stderr={result.stderr!r}"
        )
