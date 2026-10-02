#!/usr/bin/env bash
# One protocol step: send literal text and Enter as two calls, wait on the expected artefact
# with a bounded loop, then show the wait and the pane tail.
# Usage: tmux-step.sh SESSION 'text' EXPECTED_FILE [CEILING_SECONDS=90] [PAUSE_SECONDS=1]
set -u
SESSION="${1:?tmux session name}"
TEXT="${2:?text to send (use '' for Enter only)}"
FILE="${3:?expected file}"
CEIL="${4:-90}"
PAUSE="${5:-1}"

if [ -n "$TEXT" ]; then
  tmux send-keys -t "$SESSION" -l "$TEXT"
  sleep "$PAUSE"
fi
tmux send-keys -t "$SESSION" Enter

n=0
until [ -e "$FILE" ] || [ "$n" -ge "$CEIL" ]; do sleep 1; n=$((n+1)); done
if [ -e "$FILE" ]; then
  echo "ARRIVED after ${n}s: $FILE"
  rc=0
else
  echo "CEILING ${CEIL}s EXPIRED without: $FILE"
  rc=1
fi
echo "--- pane tail ($SESSION)"
tmux capture-pane -p -t "$SESSION" | grep -v '^\s*$' | tail -20
exit "$rc"
