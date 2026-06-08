------------------------

## Error Message is Confusing

Needs more clarifications around constraints and context. Error message is too terse, confusing for unaffilliated users.

Below is a log from a Claude Code Opus 4.8 session.

<log>
● Bash(cd /home/minttea/codebases/dayvidpham/aura-plugins/worktree/aura-protocol
      bd comments add aura-plugins-1iowf "$(cat <<'EOF'
      ## Impl UAT (component-by-component, real output)
      ### Component 1 (reconciliation + preview) — REVISE — FIX-NOW (verbatim choice): "Full roster incl. 'consistent' lines"
      Real dry-run shows ONLY drifted plugins (aura 0.10.2>0.8.2) + count; consistent (pasture, agentfilter) omitted. User wants the FULL roster: print every registered plugin, consistent ones as "<name>  plugin.json X  ==
      marketplace X   consistent" (matches PROPOSAL-5 canonical example). FIX-NOW: update printReconcilePreview to emit consistent rows + add/extend a test asserting a consistent row renders. No additional feedback; reconciliation
      logic correct (caught aura drift, pasture consistent).
      EOF
      )" 2>&1 | grep -viE "beads.role|bd init" | head -1
      echo "=== Component 2 demo: non-TTY behavior (real, safe — should error, no writes) ==="
      cd pasture
      nix develop --command bash -c 'go run ./cmd/pasture-release registry sync-versions 2>&1; echo "EXIT=$?"' 2>&1 | tail -8)
  ⎿  Comment added to aura-plugins-1iowf
     === Component 2 demo: non-TTY behavior (real, safe — should error, no writes) ===
     Pasture dev shell (Go go1.24.13)
     Reconciling registered plugins (plugin.json  ⟷  marketplace entry):
        aura  plugin.json 0.10.2  >  marketplace 0.8.2   → UPDATE marketplace entry → 0.10.2
     1 change(s) pending
     Error: workflow error: refusing to prompt on a non-interactive terminal — pass --non-interactive to apply, or --dry-run to preview
     exit status 1
     EXIT=1
  ⎿  Allowed by auto mode classifier

● Impl UAT — Component 2 of 3: confirmation / non-TTY safety (real behavior shown):
  $ pasture-release registry sync-versions          # non-TTY, no flags, drift pending
  Reconciling registered plugins (plugin.json  ⟷  marketplace entry):
     aura  plugin.json 0.10.2  >  marketplace 0.8.2   → UPDATE marketplace entry → 0.10.2
  1 change(s) pending
  Error: workflow error: refusing to prompt on a non-interactive terminal — pass --non-interactive to apply, or --dry-run to preview
  exit status 1
  Exactly as specified: previews, then refuses (non-zero exit, zero writes/pulls). --dry-run previews safely; --non-interactive would apply; an interactive TTY would show [y/N].

● User answered Claude's questions:
  ⎿  · The confirmation/safety behavior as built (real output above): non-TTY + drift + no flags → actionable error + exit 1, zero writes; --dry-run previews; --non-interactive applies; interactive TTY prompts [y/N] over all pending
     changes. Does this match intent? → Matches as built
     · Any related concern on the confirmation / flags / exit codes? → The error message is messy:

          Error: workflow error: refusing to prompt on a non-interactive terminal — pass --non-interactive to apply, or --dry-run to preview

     should just be 'Error: refusing to run `registry sync-versions` on a non-interactive terminal (non-TTY), command needs user confirmation by default. Re-run command with `--non-interactive` flag to run on non-TTY with no
     confirmations, or run with `--dry-run` to preview changes.'
     · ACCEPT this component (confirmation + non-TTY safety)? → REVISE

</log>

----------------------

# Test Quality and Focus

Is there any other speedups we can get? Evaluate the longest-running modules that are remaining. Are there any badly designed tests? Any unecessarily redundant tests? For unit tests, we want core functionality, invariants, sanity checks, domain checks, and fuzz testing. These unit tests shouldn't be busy-work made to boost test coverage: it should be testing real functionalities of the system that are ACTUALLY INFORMATIVE when they fail or succeed like an experiment, and tell us WHICH important attributes of the system have changed as a result of a modification. Our unit tests should be designed so that they do NOT break all the time whenever anything changes: that would introduce unfeasible amounts of developer friction and add to our test times. In this vein, integration tests and e2e tests should tell us the overall system is working as intended, and the flows of information and state are operating correctly (including checking of incorrect and invalid states).

Our tests still take forever to run. This is a report from the latest test run.

<logs>
agent-data-leverage/perf--cmd-peasant-test-speed [perf--cmd-peasant-test-speed]
 I  -> make check                                                                                              minttea@desktop
# TODO: David - running golangci-lint deferred until we can properly fix its errors
# Use go vet for now
# golangci-lint run ./...
go vet ./...
cd pkg/schema && go build ./...
cd pkg/schema && go vet ./...
cd pkg/schema && go test -race ./...
ok      github.com/peasant-labs/peasant/pkg/schema    (cached)
ok      github.com/peasant-labs/peasant/pkg/schema/migrations/village    (cached)
ok      github.com/peasant-labs/peasant/pkg/schema/openapi    (cached)
ok      github.com/peasant-labs/peasant/pkg/schema/validate    (cached)
ast-grep scan --config sgconfig.yml .
warning[no-untyped-string-const]: Untyped string constant "codexRoleDeveloper". If this represents a provider, format, channel, message type, role, or redaction level, give it a typed definition (e.g., const X Provider = "...").

    ┌─ internal/ingest/codex_indexer.go:283:1
    │
283 │ const codexRoleDeveloper = "developer"
    │ ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    │
    = Untyped string constants can be accidentally mixed with other string values. If this is a format template or error message, it may be left as-is.

go test -race ./...
?       github.com/peasant-labs/peasant    [no test files]
ok      github.com/peasant-labs/peasant/cmd/peasant    24.824s
ok      github.com/peasant-labs/peasant/cmd/schema-gen    (cached)
?       github.com/peasant-labs/peasant/internal/animation    [no test files]
ok      github.com/peasant-labs/peasant/internal/annotations    3.980s
ok      github.com/peasant-labs/peasant/internal/api    (cached)
ok      github.com/peasant-labs/peasant/internal/auth    (cached)
ok      github.com/peasant-labs/peasant/internal/config    1.052s
ok      github.com/peasant-labs/peasant/internal/defaults    (cached)
ok      github.com/peasant-labs/peasant/internal/e2e    1.055s
ok      github.com/peasant-labs/peasant/internal/export    4.631s
ok      github.com/peasant-labs/peasant/internal/ingest    12.559s
ok      github.com/peasant-labs/peasant/internal/metrics    4.085s
ok      github.com/peasant-labs/peasant/internal/mock    1.042s
ok      github.com/peasant-labs/peasant/internal/perf    (cached)
ok      github.com/peasant-labs/peasant/internal/push    1.120s
ok      github.com/peasant-labs/peasant/internal/salt    (cached)
ok      github.com/peasant-labs/peasant/internal/store    29.214s
?       github.com/peasant-labs/peasant/internal/store/storetest    [no test files]
ok      github.com/peasant-labs/peasant/internal/testutil    1.031s
?       github.com/peasant-labs/peasant/internal/transcript    [no test files]
ok      github.com/peasant-labs/peasant/internal/tui    1.037s
ok      github.com/peasant-labs/peasant/internal/tui/ftue    (cached)
ok      github.com/peasant-labs/peasant/internal/tui/search    (cached)
ok      github.com/peasant-labs/peasant/pkg/redact    1.578s


</logs>


