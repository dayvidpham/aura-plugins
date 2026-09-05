---
name: tmux-capture-driver
description: Drive an interactive terminal program (Claude Code, Codex, OpenCode, or any TUI) from an agent through tmux, step by step, and prove each step by an observable artefact. Carries the send-keys rules that were measured to work, the trust-prompt sequences per program, turn-completion detection, bounded condition waits, non-interactive fallbacks, and the failure modes seen in practice. Use when an agent must operate a TUI it cannot attach to, obtain files or output that only an interactive session produces, or hand a partly driven tmux session to another agent.
---

# Drive a TUI through tmux and prove every step

An agent has no terminal of its own. tmux gives it one: a detached session that runs the
program, accepts keystrokes, and shows its screen on request. The protocol below turns that into
something reliable. Every rule here came from a failure that happened once.

## The five rules

1. **Read the pane before every keystroke.** `tmux capture-pane -p -t NAME` shows the screen.
   Menus, trust prompts and spinners change what a key does. A key sent blind goes to the wrong
   widget.
2. **Send text and Enter as two calls.** `tmux send-keys -t NAME -l 'the text'`, pause about one
   second, then `tmux send-keys -t NAME Enter`. Text and Enter in one call left the prompt typed
   but unsent in Claude Code. `-l` sends the text literally, so backticks, semicolons and `$`
   reach the program unchanged.
3. **Wait on a condition, never on time alone.** The condition is the artefact the step must
   produce: a file, or a pane line. Poll it in a bounded loop and report how long it took:
   `n=0; until [ -e "$FILE" ] || [ $n -ge 90 ]; do sleep 1; n=$((n+1)); done; echo "waited ${n}s"`.
   A step whose ceiling expired is a finding, not a retry.
4. **One session per program, environment set in the launching shell.** Start a shell in the
   session, export the variables there, then start the program. A hook or plugin the program
   spawns inherits that shell's environment, not the agent's.
5. **Record what you did.** After each session: the keys sent, the prompts sent, the menu choices
   taken, the pane text at each decision, and the artefacts listed with `ls -la`. Another agent
   or the user must be able to see what produced the artefacts.

## Session lifecycle

```bash
# Start: detached, sized, in the working directory.
tmux new-session -d -s NAME -x 180 -y 45 -c /path/to/project
# Environment and program, one line, then Enter (a shell command, so one call is fine here).
tmux send-keys -t NAME "export A=1 B=2; program" Enter
# Look.
tmux capture-pane -p -t NAME | grep -v '^\s*$' | tail -30
# Menus: move with Down/Up or type the item number, then Enter as a separate call.
tmux send-keys -t NAME Down; sleep 0.5; tmux send-keys -t NAME Enter
# Prompts: literal text, pause, Enter.
tmux send-keys -t NAME -l 'Run the shell command `ls -la` and tell me what you see.'; sleep 1
tmux send-keys -t NAME Enter
# End: the program's own quit command first, then remove the session.
tmux kill-session -t NAME
```

Sessions survive the agent's tool call, so a half-driven session can be handed to another agent
by name. Give the receiver the session name, the exact pane text, and the next expected artefact.

## Program-specific sequences (measured 2026-09-05)

**Claude Code (`claude`, v2.1.261).** Nested launches need `unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT`
in the launching shell. First screen in a new directory is the folder-trust prompt with "No, exit"
selected: `Down`, then `Enter`. A turn is running while the status line shows `esc to interrupt`;
wait for that text to disappear before the next prompt. Slash commands (`/compact`, `/exit`) are
typed like prompts: literal text, pause, Enter. `/compact` produces a summary and a fresh
session start; `/exit` ends the session and prints a resume line.

**Codex (`codex`, codex-cli 0.153.0).** First screen is the directory-trust prompt with "1. Yes,
continue" selected: `Enter`. If the project carries `.codex/hooks.json`, the next screen is
"Hooks need review" with three items; hooks run only after "2. Trust all and continue" (type `2`,
which moves the highlight, then `Enter`). Trust is written to `~/.codex/config.toml` per project
and persists. Hooks registered for startup run at the start of the first turn, not at process
start, so expect their artefacts after the first prompt. Command approvals appear as menus; read
the pane. Quit with `/quit`.

**OpenCode (`opencode`, 1.18.29).** No trust prompt. On first start in a directory with
`.opencode/plugins/`, it installs its plugin npm package into `.opencode/` before the prompt
appears; in practice about eight seconds. Non-interactive runs were seen to stall at "init"
twice for unknown reasons; a relaunch in the same directory recovered. Child processes the plugin
spawns inherit the TUI's stderr and draw over the screen until the next redraw. One Ctrl-C ends
the TUI and prints a resume line.

## Non-interactive fallbacks

These fire the same lifecycle hooks and are easier to script when no TUI-only step is needed:
`claude -p 'prompt'`, `codex exec 'prompt'` (only after the directory's hooks were trusted once
in the TUI; `exec` cannot grant trust), `opencode run 'prompt'`. They cannot do `/compact`, and
they cannot answer trust prompts.

## Failure modes seen

- Text typed but not submitted: text and Enter were in one `send-keys` call. Send `Enter` alone.
- Program refused to start inside an agent session: inherited `CLAUDECODE`; unset it.
- A long background poll was killed by the harness's low-memory guard. Keep waits short and
  bounded inside the tool call; do not rely on a detached poller to wake you.
- Two agents typing into one session interleave keystrokes. One driver per session; announce
  the handoff before the other agent touches it.
- A stalled program was recovered with `pkill -f <program>`, which killed EVERY instance of that
  program on the machine, including two other agents' live sessions mid-sitting (2026-09-05).
  Never kill by program name or pattern (`pkill -f`, `killall`). Read the pane, then kill only
  your own session (`tmux kill-session -t NAME`) or your own pane's process
  (`tmux list-panes -t NAME -F '#{pane_pid}'`, then `kill <pid>`).
- Several sittings at once share the host's log file and the live store's fault file. Filter
  every log line by your own project directory before drawing a conclusion. Judge "live store
  untouched" by a byte digest of its database before and after, never by the fault file, which
  grows from the surrounding agent session's own hooks.
- A capture listing taken while the host could still emit undercounted (717 listed, 720 on
  disk; the host had been killed while bootstrap events were still arriving). You cannot tell
  from outside whether emission has stopped, and stopping the host is not by itself the
  guarantee. Stop the host, then list, then count a second time; two agreeing reads of a
  stopped directory are the evidence. Three of four re-counts did not move, which is what a
  discriminating check looks like.
- Several live hosts at once starved the terminal redraw (hook stderr drawn into the screen)
  and one host was killed by the operating system under load. Run one live host at a time;
  check the load average before starting and wait, bounded, if it is high.

## Helper

`scripts/tmux-step.sh NAME 'text' /path/expected-file [ceiling-seconds]` sends the text and Enter
as two calls, waits on the file with a bounded loop, then prints the wait and the pane tail.
