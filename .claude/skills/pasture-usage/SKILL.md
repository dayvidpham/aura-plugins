---
name: pasture-usage
description: Use when operating the Pasture task tracker from the command line — creating, reading, updating, and closing tasks; labels; dependencies; comments and timelines; agent/author attribution; and store/namespace selection. Covers the required --author flag, exit codes, and the gotchas we have hit in practice (write-lock contention, shell quoting, URI capture, two-dash vs slash IDs).
---

# Using Pasture

Pasture is the task tracker for this workspace. It keeps every task, comment,
label, dependency, and lifecycle event in one SQLite database with durable,
append-only audit history. Treat the store as durable: **never delete tasks or
audit rows** — correct the record by adding labels and attributed comments.

Entry points: `pasture task …` (generic task operations), `pasture epoch …`
(typed lifecycle decisions), `pasture hook …` (lifecycle hook events),
`pasture migrate` (schema migration), `pasture upgrade`.

## 1. Pick the store

Resolution order, first match wins:

1. `--db <path>` flag
2. `PASTURE_DB_PATH` environment variable
3. `$XDG_DATA_HOME/pasture/pasture.db`
4. `$HOME/.local/share/pasture/pasture.db` (default)

Use one store for the whole session. `--db` is a global flag accepted by every
subcommand.

## 2. Pick the namespace

The namespace scopes task IDs. It resolves as:

1. explicit `--namespace <uri>`
2. derived from the `origin` git remote
3. `file://<cwd>` when there is no git remote

- `create` derives the namespace automatically — you normally do **not** need to
  export `PASTURE_NAMESPACE`.
- `list` should get the namespace explicitly so results do not depend on cwd.
- `ready` and `blocked` do **not** scope by namespace — they accept only an exact
  `--label` filter. Check the full URI on every returned row before picking up
  work.

Convention for a scripted session:

```bash
export PASTURE_NAMESPACE=https://github.com/<owner>/<repo>
```

## 3. Core task commands

```bash
# Create. The id is a URI. Capture it; creation and labeling are separate writes.
TASK_URI=$(pasture task create "Short imperative title" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority medium \
  --description "Approved scope and acceptance cases" --format json \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')

pasture task show   "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
pasture task list   --namespace "$PASTURE_NAMESPACE" --status in_progress
pasture task update "$TASK_URI" --status in_progress --namespace "$PASTURE_NAMESPACE"
pasture task close  "$TASK_URI" --reason "Reviewed and verified" --namespace "$PASTURE_NAMESPACE"
```

Statuses are only `open`, `in_progress`, `closed`. There is no `blocked` status:
blockage is a live dependency edge plus a note or comment.

## 4. Labels

```bash
pasture task label add "$TASK_URI" pasture:work --namespace "$PASTURE_NAMESPACE"
```

Create + label is **not atomic**. If the label step fails, keep the URI and retry
only the label — never re-create the task (that is how duplicate tasks happen).

## 5. Dependencies

Work flows bottom-up, closure flows top-down. A parent stays open until its child
finishes.

```bash
pasture task dep add  "$PARENT_URI" --blocked-by "$CHILD_URI" --namespace "$PASTURE_NAMESPACE"
pasture task dep tree "$PARENT_URI" --kind all --namespace "$PASTURE_NAMESPACE"
```

Always `parent --blocked-by child`; never reverse the edge. Reference documents
(specs, proposals) go in the description, not in fake blocking edges.

## 6. Comments, attribution, and the `--author` flag

Every comment must carry an explicit `--author`. Pasture does not infer one.

```bash
pasture task comment add "$TASK_URI" "Progress: evidence and next step" \
  --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"

pasture task comments "$TASK_URI" --namespace "$PASTURE_NAMESPACE"  # chronological read
pasture task timeline "$TASK_URI" --namespace "$PASTURE_NAMESPACE"  # every event
```

Rules:

- Discover identities, never invent them:
  `pasture task agents list`, `pasture task agents show <ACTOR-ID>`.
  Never auto-register an actor or guess an ID mid-recovery.
- Quote a human's words **as evidence** under your own actor — do not forge a new
  author.
- The machine actor for automated runs is
  `pasture-system--00000000-0000-0000-0000-000000000000`.
- Other agents have their own registered actors; use the one the supervisor
  assigned.

## 7. Session recovery

At session start and after context compaction, recover from live state — never
trust a cached task list:

```bash
pasture task ready   --namespace "$PASTURE_NAMESPACE" --format json
pasture task blocked --namespace "$PASTURE_NAMESPACE"
pasture task list    --namespace "$PASTURE_NAMESPACE" --status in_progress
```

For each active task: `show`, `comments`, `timeline`. Separate reads are not an
atomic snapshot.

## 8. Gotchas we have actually hit

**Write-lock contention — `Error: Couldn't connect` (exit code 2).**
Every invocation opens the shared DB and runs a write-lock schema activation (up
to a 30 s budget). When lifecycle hooks are enabled, `pasture hook lifecycle …`
fires on many events and they contend for the same file. Symptom: intermittent
`SQLITE_BUSY … gave up after 30s`, with or without `--namespace`. It is a
connectivity/lock failure, **not** proof that there is no work.
- Retry the command.
- Find the holder: `lsof ~/.local/share/pasture/pasture.db` (or `fuser`).
- Do not report the store empty or broken from one failure.

**Exit codes:** `0` ok · `1` bad flags/args · `2` cannot open DB · `3` task or
workflow error (not found, cycle, gate rejected) · `4` config · `5`
storage/migration. Branch on the code, not on message text.

**Backticks inside double-quoted shell strings are command-substituted.** Do not
write `comment add "$U" "use \`pasture task\`"`. Use a single-quoted heredoc or
single quotes so the text survives verbatim.

**Capture the ID as JSON, not from human output.** Use `--format json` and parse
`.id`; or `grep '^ID'` when reading text output (namespace-aware). Legacy short
IDs are never valid operands — only full URIs.

**Run tracker writes from the repo whose namespace you mean.** Otherwise the
git-remote-derived namespace is the wrong repository and the task lands in the
wrong place.

**`ready`/`blocked` are not namespace-scoped.** Filter by the full URI yourself.

**URI format — two-dash vs slash.** Older stored IDs look like
`https://github.com/<owner>/<repo>--<uuid>`; the newer format joins with a slash:
`https://github.com/<owner>/<repo>/<uuid>`. Existing rows are **not** rewritten
retroactively, so an ID's format depends on when and with which build it was
created. Accept both; never assume one.

**`pasture migrate` is a schema migration**, not a data import. There is no
user-facing "import beads" command.

## 9. Installing in harnesses

Author once, install per harness (keep the `name:` frontmatter stable so the
skill triggers identically everywhere):

- Claude Code: `~/.claude/skills/pasture-usage/SKILL.md` (or project-local
  `.claude/skills/pasture-usage/SKILL.md`)
- OpenCode: `~/.config/opencode/skills/pasture-usage/SKILL.md`
- Codex: `~/.agents/skills/pasture-usage/SKILL.md`
