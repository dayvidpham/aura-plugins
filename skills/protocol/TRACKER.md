# Pasture Tracker Reference

Canonical, supported `pasture task` recipes for the Aura protocol. Every active
operational example in this documentation set uses the verbs, flags, operands,
and identity semantics described here. Where an older document showed a legacy
tracker recipe, the replacement is listed in [Retired Operations](#retired-operations).

This reference targets the shipped Pasture CLI. Verify any flag against the
installed binary before use (`pasture task <verb> --help`).

---

## Scope and store

- All operational tracking runs through `pasture task`.
- Retained `.beads/` data is **legacy migration/archive evidence**, never a
  working tracker. The migration ledger owns the legacy-ID-to-successor-URI
  mapping; inspect a recorded successor before creating a duplicate.
- Store selection precedence: `--db` overrides `PASTURE_DB_PATH`; otherwise the
  configured default store is used.
- A failed query is a configuration/connectivity failure, not proof of no work.
  Report the command, the store path, and the repair step before continuing.

## Identity and namespace

Select the repository namespace explicitly so tasks land in the correct store
partition. For aura-plugins the namespace is:

```
https://github.com/dayvidpham/aura-plugins
```

Comment authors must **already be registered**. Machine automation uses the
pre-registered system actor; humans and agents use their own *real* registered
identity. Never silently register, guess, or impersonate an author, and never
invent an ID: every author is a value returned by `pasture task agents list` or
`pasture task agents show`.

```bash
set -euo pipefail
export PASTURE_NAMESPACE=https://github.com/dayvidpham/aura-plugins
# The pre-registered machine-automation actor:
export PASTURE_AUTHOR=pasture-system--00000000-0000-0000-0000-000000000000
```

For a human or agent author, bind the **actual** registered identity by name.
The JSON field is `agentId` (read the real output; do not guess the key):

```bash
pasture task agents list --namespace "$PASTURE_NAMESPACE"
pasture task agents show "$AGENT_ID" --namespace "$PASTURE_NAMESPACE"
export PASTURE_AUTHOR=$(pasture task agents list --namespace "$PASTURE_NAMESPACE" --format json \
  | jq -er '.[] | select(.name == "{{your registered author name}}") | .agentId')
```

## Operands: full URIs only

Task operands are **full task URIs** as returned by the tracker, for example
`https://github.com/dayvidpham/aura-plugins--01a12aa7-f2c9-76ac-9e05-15550f985d94`.
Never pass an unbound bare legacy ID. When a command returns JSON, bind the
exact returned identity before the next command:

```bash
TASK_URI=$(pasture task create "Implement the approved change" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority medium \
  --description "Approved scope and acceptance cases" --format json | jq -er '.id')
```

The JSON task key is lowercase `id` (also `title`, `status`, `type`, `priority`,
`phase`, `createdAt`, `updatedAt`). Do not guess the key — read the real output.

## Supported verbs

### Create

```
pasture task create TITLE [--description BODY] [--type TYPE] [--priority PRIORITY] [--phase PHASE]
```

- `TITLE` is **positional**. There is no `--title` flag.
- `--type`: `bug`, `feature`, `task`, `epic`, `chore` (default `task`).
- `--priority`: `critical`, `high`, `medium`, `low`, `backlog` (also `0..4` /
  `P0..P4`; default `medium`).
- `--phase`: `request`, `elicit`, `propose`, `review`, `plan_uat`, `ratify`,
  `handoff`, `impl_plan`, `worker_slices`, `code_review`, `impl_uat`, `landing`,
  `unscoped` (default `unscoped`).
- There is **no** `--labels`, `--design`, `--notes`, `--assignee`, or `--parent`
  flag on `create`. Put prior fields in the description body; add labels with a
  **separate** `label add` command (creation and labeling are non-atomic).

```bash
TASK_URI=$(pasture task create "URD: {{feature name}}" \
  --namespace "$PASTURE_NAMESPACE" --type task --priority high \
  --description "---
references:
  request: {{request-task-uri}}
  elicit: {{elicit-task-uri}}
---
## Requirements
{{structured requirements}}" --format json | jq -er '.id')
pasture task label add "$TASK_URI" aura:urd --namespace "$PASTURE_NAMESPACE"
pasture task label add "$TASK_URI" aura:p2-user:s2_2-urd --namespace "$PASTURE_NAMESPACE"
```

If the label step fails, keep `$TASK_URI` and retry **only** the label command.
Never re-run `create` — that duplicates the task.

### Read

```bash
pasture task show "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
pasture task list --namespace "$PASTURE_NAMESPACE" --status in_progress
pasture task list --namespace "$PASTURE_NAMESPACE" --label aura:p9-impl:s9-slice --status open
pasture task ready --namespace "$PASTURE_NAMESPACE" --label aura:p9-impl:s9-slice
pasture task blocked --namespace "$PASTURE_NAMESPACE"
pasture task comments "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
pasture task timeline "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
```

- `list` filters: `--label`, `--phase`, `--priority`, `--status`, `--type`, and
  `--namespace` scopes the returned collection.
- `ready` and `blocked` accept **one exact** `--label` only. They do **not**
  scope their results by namespace — inspect the full returned URIs before
  choosing repository work. There is no comma-separated label set.
- Reads are separate calls, not one atomic snapshot.

### Update

```
pasture task update ID [--title T] [--description D] [--notes N] [--status S] [--priority P] [--phase PH]
```

- Supported `--status`: `open`, `in_progress`, `closed`. There is no `blocked`
  or `done` status.
- Supported `--phase` values match `create`.
- There is no generic `--assignee`; use `task assignment` for supported owner
  changes. Labels use `task label`, not `--add-label`.

```bash
pasture task update "$TASK_URI" --status in_progress --namespace "$PASTURE_NAMESPACE"
pasture task update "$TASK_URI" --notes "Blocked: missing type definition; waiting on {{dependency-uri}}" \
  --namespace "$PASTURE_NAMESPACE"
```

A blocker is recorded as a note plus a `blocked_by` edge, not a status value.

### Comment

```
pasture task comment add ID BODY --author ACTOR
```

`--author` is **required**. Comments are append-only; never edit or delete them.

```bash
pasture task comment add "$TASK_URI" "Progress: evidence and next step" \
  --author "$PASTURE_AUTHOR" --namespace "$PASTURE_NAMESPACE"
```

### Label

```
pasture task label add ID LABEL
pasture task label list ID
```

Protocol audit recipes **add** labels and comments only. `label remove` exists in
the CLI but must not be used to erase audit history.

```bash
pasture task label add "$TASK_URI" aura:p6-plan:s6-ratify --namespace "$PASTURE_NAMESPACE"
```

### Dependencies

```
pasture task dep add SOURCE --blocked-by TARGET
pasture task dep add SOURCE --target TARGET --kind KIND
pasture task dep tree ID [--kind KIND]
```

- `--blocked-by` marks SOURCE as blocked by TARGET (TARGET must finish first).
- `--kind`: `blocked_by`, `derived_from`, `supersedes`, `discovered_from`.
- `tree --kind`: those four plus `all` (default `blocked_by`). Only `blocked_by`
  affects readiness.

**Direction is parent blocked-by child.** The parent stays open until the child
finishes; work flows bottom-up and closure flows top-down. Never invert.

```bash
pasture task dep add "$PARENT_URI" --blocked-by "$CHILD_URI" --namespace "$PASTURE_NAMESPACE"
pasture task dep tree "$PARENT_URI" --kind all --namespace "$PASTURE_NAMESPACE"
```

Reference documents (request, URD, proposal) go in description frontmatter
`references:`, never as fabricated blocking edges.

### Close

```
pasture task close ID [--reason TEXT]
```

- **Only the supervisor closes work**, after independent review and approval.
- Workers record evidence in comments and never close assigned tasks, and never
  close a task merely because "tests pass".

```bash
pasture task close "$CHILD_URI" --reason "Reviewed and verified; evidence in comments" \
  --namespace "$PASTURE_NAMESPACE"
```

### Agents

```bash
pasture task agents list --namespace "$PASTURE_NAMESPACE"
pasture task agents show "$ACTOR_ID" --namespace "$PASTURE_NAMESPACE"
pasture task agents register ...   # explicit, deliberate; never implicit
```

## Frontmatter references

Link reference documents inside the description, not with relation commands:

```bash
PROPOSAL_URI=$(pasture task create "PROPOSAL-1: Technical approach" \
  --namespace "$PASTURE_NAMESPACE" --type feature --priority high \
  --description "---
references:
  request: {{request-task-uri}}
  urd: {{urd-task-uri}}
---
## Proposal
..." --format json | jq -er '.id')
```

## Roles and closure ownership

| Role | Tracker behaviour |
|------|-------------------|
| Worker | Records progress and evidence as attributed comments; reports blockers; **never** closes assigned tasks |
| Reviewer | Adds attributed review comments and votes; **never** closes slices |
| Supervisor | Owns decomposition, assignment, and closure after review passes |
| Architect | Owns proposal, ratify, and handoff records |

## Retired operations

These legacy operations were invoked through the retired Beads tracker binary.
They have no direct Pasture verb. Use the replacement shown; do not invent a
`pasture task` verb to mirror them.

| Legacy verb | Status | Supported replacement |
|---|---|---|
| `ready` / `blocked` | mapped | `pasture task ready` / `pasture task blocked` (one exact `--label`) |
| `list` | mapped | `pasture task list` with explicit namespace and supported filters |
| `show <id>` | mapped | `pasture task show <full-uri>` |
| `create` | mapped | `pasture task create TITLE ...` (positional title); labels added separately |
| `update` | mapped | `pasture task update <full-uri>` (supported fields only) |
| `close` | mapped | `pasture task close <full-uri> --reason TEXT` (supervisor-only) |
| `comments add` | mapped | `pasture task comment add <full-uri> BODY --author ACTOR` |
| `comments` | mapped | `pasture task comments <full-uri>` |
| `label add/list` | mapped | `pasture task label add/list <full-uri> ...` |
| `dep add` | mapped | `pasture task dep add <parent> --blocked-by <child>` |
| `dep tree` | mapped | `pasture task dep tree <full-uri> --kind blocked_by` (or `all`) |
| `stats` / `count` | dropped | Derive counts locally from `pasture task list --format json` in one namespace |
| `search` | dropped | Read a scoped `pasture task list --format json` and filter locally |
| `sync` | dropped | Store writes are durable; Git history lands separately |
| `edit` | dropped | Use explicit `pasture task update --description` / `--notes` |
| `mol` | dropped | The task graph and dependencies already express the workflow |
| `doctor` | dropped | Use an explicit supported tracker read and repair guidance |
| `prime` | dropped | Session recovery uses Pasture context recovery; there is no `task prime` |
| `task <...>` | dropped | Use ordinary `pasture task` lifecycle and evidence operations |

## Recovery at session start

At session start and after compaction:

1. Select the store and repository namespace.
2. Re-read live state — never trust cached task rows.
3. Run the read-only recovery queries:

```bash
pasture task ready --namespace "$PASTURE_NAMESPACE" --format json
pasture task blocked --namespace "$PASTURE_NAMESPACE"
pasture task list --namespace "$PASTURE_NAMESPACE" --status in_progress
pasture task show "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
pasture task comments "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
pasture task timeline "$TASK_URI" --namespace "$PASTURE_NAMESPACE"
```

Recovery queries direct the reads; they do not inject cached rows, mutate state,
register agents, or interpolate secrets.

## Git safety

The tracker never installs or modifies Git hooks. Landing records attributed
tracker comments, commits with `git agent-commit`, and pushes only with explicit
approval; `git status` must then show the branch up to date with its remote.

## See Also

- [PROCESS.md](PROCESS.md) — step-by-step workflow execution
- [CONSTRAINTS.md](CONSTRAINTS.md) — coding standards and naming conventions
- [HANDOFF_TEMPLATE.md](HANDOFF_TEMPLATE.md) — handoff document template
