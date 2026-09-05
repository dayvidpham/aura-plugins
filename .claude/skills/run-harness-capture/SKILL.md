---
name: run-harness-capture
description: Run a live capture sitting that records raw lifecycle-hook payloads from real Claude Code, Codex and OpenCode sessions through pasture's capture sink, so the bytes can be cleared into fixtures. Carries the kit rules (a binary and transports generated with the version roots moved), the three environment variables, the dry run, per-harness setup and trigger recipes with expected file names, the fault line that is expected, the report format for the clearance step, and the safety rules (live sessions only, never the live store, nothing committed before clearance, nothing pushed before the user's ACCEPT). Use when a pin bump or a coverage slice needs authentic host payloads, or when the user says to run the captures.
---

# Run a live harness capture sitting

pasture proves each hook event with a fixture captured from a real host session. A sitting is
the set of live sessions that produce those raw bytes. The sitting itself is short (about ten
minutes per harness). Most of the work is in the setup, the proof that each step fired, and the
report the clearance step needs. Mechanics for driving the TUIs are in `tmux-capture-driver`.

## What a capture is

When `PASTURE_CAPTURE_DIR` is set, the pasture hook binary writes the raw host payload to
`<dir>/<harness>_<snake_event>_<host_version>.<n>.json` before it evaluates anything, and prints
once on stderr: `pasture: capture mode is recording this session to <dir>`. The directory must be
absolute, must exist, and must be outside every git repository; pasture never creates it and
refuses with one warning otherwise. The version in the file name comes from the `--host-version`
argument the transport passes; a wrong or missing value produces a false or `unknown` name.

## Preconditions

1. **A kit.** A pasture binary plus the generated transports (Claude `hooks/hooks.json`, Codex
   `.codex/hooks.json` and `.codex/hooks/events/*.sh`, OpenCode
   `.opencode/plugins/pasture-lifecycle.ts`) built in a throwaway archive copy of the branch head
   with the version roots moved to the installed host versions, then `make generate`. Never
   hand-edit a generated file; never build the kit in the live worktree. Record the head SHA, the
   root edits, the diff of the transports against the head (version strings only), and the SHA-256
   of the binary and every transport file. The clearance step proves the committed transports equal
   these bytes.
2. **Host versions probed now**: `claude --version`, `codex --version`, `opencode --version`.
   Paste them into the report. A host that moved since the kit was built is a stop.
3. **Directories outside every repository**, for example under
   `~/.local/share/pasture-captures/`: one capture dir per harness, `dryrun`, `scratch`, and one
   throwaway project dir per harness. Copy the kit's transports into the project dirs and verify
   their digests there.

## Environment, in every capture shell

```bash
unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT          # only when launched from inside an agent session
export PASTURE_BIN=<kit binary>                  # "$PASTURE_BIN" --version prints "pasture version devel"
export PASTURE_DB_PATH=<base>/scratch/pasture.db  # a fresh database; the live store is never a test bed
export PASTURE_CAPTURE_DIR=<base>/<harness>      # absolute, exists, outside any repository
```

Set these only in the shell that runs the capture session. Any other shell with them set would
record its sessions too.

**Expected fault line.** On a fresh database each hook prints one long fail-open fault ending in
`Lifecycle ingress cannot resolve Pasture's persisted system identity`. That is the known identity
bootstrap defect. The host proceeds and the capture is written before that step. It is not a
capture failure.

## Dry run before the first session

```bash
printf '%s' '{"session_id":"dry-run","hook_event_name":"SessionStart","source":"startup"}' \
  | PASTURE_CAPTURE_DIR=<base>/dryrun "$PASTURE_BIN" hook lifecycle --harness claude-code --event SessionStart --host-version <claude version>
ls <base>/dryrun    # expect claude-code_session_start_<v>.1.json and the notice line once
```

Delete the dryrun directory's contents afterwards. Hand-piped bytes are never fixtures.

## Per-harness recipes (measured at 2.1.261 / 0.153.0 / 1.18.29)

**Claude Code, 8 events, about 10 minutes.** The transport reads
`--host-version "${CLAUDE_CODE_VERSION:-unknown}"`, so export
`CLAUDE_CODE_VERSION="$(claude --version | cut -d' ' -f1)"` in the capture shell or every file is
named `unknown`. Start `claude` in the project dir (which holds README.md and NOTES.md), accept
the folder trust. Then:

| Step | Prompt or command | Files produced |
|---|---|---|
| launch | (none) | `session_start.1` |
| read | `Read the file README.md in this directory and tell me its first line.` | `pre_tool_use`, `post_tool_use`, `post_tool_batch` |
| fail | `Read the file does-not-exist.txt in this directory.` | `post_tool_use_failure` (plus pre/post/batch) |
| compact | `/compact` | `pre_compact`, `post_compact`, and a second `session_start` (source compact) |
| exit | `/exit` | `session_end` |

Claude may satisfy a "Read" prompt with a Bash call (`head`, `cat`); the payload is then a
Bash-tool payload. Say so in the report. One tool call also fires PostToolBatch, so no separate
parallel-call prompt is needed for that event.

**Codex, 2 events, about 10 minutes.** Start `codex` in the project dir holding the kit's
`.codex/`. Accept the directory trust, then choose "Trust all and continue" on the hooks review;
hooks run only when trusted, and `codex exec` cannot grant trust. At 0.153.0 the SessionStart
hook is queued at session construction and runs at the start of the FIRST TURN, not at process
startup (core/src/session/session.rs and core/src/session/turn.rs at tag rust-v0.153.0), so no
file appears until the first prompt; do not relaunch waiting for one. Prompt
``Run the shell command `ls -la` and tell me what you see.``: `session_start` appears about one
second after Enter and `pre_tool_use` a few seconds later. No approval prompt appeared (the
read-only sandbox ran `ls -la` without asking). `/quit`.

**OpenCode, 2 events, about 10 minutes.** Start `opencode` in the project dir holding the kit's
`.opencode/plugins/pasture-lifecycle.ts`. First start installs the plugin npm package into
`.opencode/`; wait. The first prompt creates the session (`session_created`); the prompt
`Run ls -la in the shell and describe the output.` produces `tool_execute_before`. If the TUI shows
no prompt after about ninety seconds, quit and relaunch in the same directory; if it stalls again,
`opencode run '<prompt>'` in the same shell is a proven fallback. Record which path ran. One
Ctrl-C ends the TUI. Cosmetic: the hook's stderr (the notice and the fault line) is drawn inside
the TUI until the next redraw, because the plugin's child process inherits the TUI's stderr; the
capture is not affected.

## Rules

- **Live sessions only.** Real host binaries producing real payloads. No hand-piped JSON, no
  copies from another tool's data directory.
- **Never touch the live store** (`~/.local/share/pasture`). The scratch database exists for this.
- **Nothing is committed before the clearance procedure**, and nothing captured reaches a remote
  before the user's verbatim ACCEPT is written into CLEARANCE.md. Private first.
- **Version re-check before every session.** A moved host is a stop and a report, not a capture.
- **Who drives.** The plan default is that the user drives the sessions; an agent drives them only
  when the user rules so, and the report says who drove.
- **Extra files are expected** (`.2`, `.3` for repeated pre/post events). Missing stems are the
  finding. Never delete a numbered file; the clearance step selects. Where several authentic
  files exist for one event, clearance prefers the smallest and records the sizes not chosen
  (one OpenCode system-prompt capture was 99 KB, cleared into 99 KB of placeholder).
- **A citation proves the code exists, not that a trigger reaches it.** One recipe inferred a
  trigger from a publish site; a guard one layer up resolved the bad argument to a default and
  the event never fired. Give every row a second trigger when one exists. A trigger that does
  not fire is a measurement; nobody concludes an event is unreachable from one failed trigger.
- **Pair events by the host's per-operation identifier** at the finest scope the event carries
  (Claude prompt_id, Codex turn_id then tool_use_id, OpenCode session then call or message and
  part id), never by field values or arrival order. An identifier that every file in the batch
  shares pairs nothing. State the scope and value for every pair the record asserts.

## Report, for the clearance step

Post one comment on the capture task, per harness: the `--version` line taken immediately before
the session; who drove and how (TUI through tmux, or a non-interactive mode); the exact prompts
and the trust or approval choices; `ls -la <capture dir>` verbatim; anything unexpected (stalls,
relaunches, a Read satisfied by Bash, a missing stem). Then message the clearance owner. The
clearance procedure (inventory, home-path and free-text substitution, digest recompute, secret
scan, CLEARANCE.md) is documented in pasture's AGENTS.md under "Capturing host payloads and
clearing them into fixtures"; it starts from this report.
