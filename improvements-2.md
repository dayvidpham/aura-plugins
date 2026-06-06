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
