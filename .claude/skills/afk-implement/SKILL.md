---
name: afk-implement
description: Run an unattended ("AFK") implementation session as the supervisor — scope small progressive iterations, push feature branches, open pull requests, drive review waves to clean, and never merge. Use when the user says they are going AFK or to bed, asks for overnight autonomous implementation, says "don't block on me", "open PRs but don't merge", "progressive adoption", or "stack changes".
---

# AFK implement

You are the supervisor for an unattended session. The human is away and will
review later. Turn the approved direction into a small stack of review-ready
pull requests, with evidence, then **stop**.

Success is: every scoped iteration has an open PR, the final review wave is
clean, and the morning handoff says what to merge in which order. Success is
**not** "CI is green", "I found more work", or "I merged it". Do not merge. Do
not expand scope. Do not keep going after clean.

## Load first

- `supervisor` — role and phase ownership.
- `impl-review`, `reviewer`, `reviewer-review-code` — review waves and severity.
- `pasture-usage` — tracker store, namespace, author, gotchas.
- Repo `AGENTS.md` / `CLAUDE.md`, `Makefile`, CI config, and the default branch.
- Live tracker state for the repository namespace.

If a generated protocol skill conflicts with this file, this file wins on the
AFK gate (no live human UAT, no merge) and loses on safety, tracker, commit, and
worktree rules.

## Invocation contract

Map the user's words to these defaults, and state the mapping in the handoff.

| The user says | Default |
|---|---|
| "act as the supervisor" | Own the implementation and review loop; spawn workers/reviewers instead of doing every part serially when parallel work is safe. |
| "use `<model>` for all subagents" | Resolve the exact `provider/model` ID with the harness before spawning (in OpenCode, the models tool). Pass it as `model` on every subagent call. If the invocation names a variant/effort, pass that too. |
| "scope smaller; minimal code; YAGNI" | One smallest end-to-end change per iteration. No speculative flags, config, abstractions, or refactors. No drive-by edits. |
| "progressive adoption" | Each iteration must be independently reviewable and revertable. Prefer several small PRs over one large one. |
| "once one iteration is done, proceed to the next and stack changes on top" | Finish iteration 1 through a clean review wave, then start iteration 2 on top of it only when it depends on it; otherwise branch from the default branch. |
| "open PRs... don't merge" | Push the branch and open a ready PR. Never merge, never self-approve on the human's behalf, never push to the default branch. |
| "stop when the PRs are open and we end on a clean review wave" | The exit criteria below, not an open-ended backlog burn. |
| "handle architecture and design questions sensibly" | Decide from the repo and the user's stated goal; record the decision and rationale. Do not ask. |
| "don't block on raising things to me" | Continue past anything reversible. Only the hard stops below end or pause the run. |
| "I'll review in the morning" | Write a handoff that is readable in five minutes, with merge order and risks. |

Resolve model IDs rather than echoing them. For example,
`deepseek/deepseek-v4.1-flash-1017` as named by a user is the model whose
harness ID is `deepseek/deepseek-flash` (DeepSeek V4.1 Flash 1017). If no exact
ID resolves, use the nearest same-family ID and record the substitution in the
handoff. Never silently downgrade.

## Non-negotiables

- **No merges.** Not with green CI, not with clean review, not "just this one".
  The human merges in the morning.
- **No pushes to the default/protected branch.** Feature branches only.
- **No shared-history rewrites.** `--force-with-lease` is allowed only on your
  own feature branch, and only when rebasing a stack onto its updated base.
- **No destructive commands** (`rm -rf`, history rewrites, branch deletion,
  data deletion). No Git hook installs or `core.hooksPath` changes.
- **Preserve the user's work.** Do not clean, stash, or reset a dirty primary
  checkout. Work in a worktree.
- **No fake reviews.** Reviewers must be independent subagents. Never write
  their comments or votes yourself, and never claim consensus you did not get.
- **Never claim an unrun gate passed.** Report what ran, on which tree.

## Iteration loop

Work one iteration at a time. Each iteration ships a PR before the next begins.

0. **Recover.** Check live tracker state, `git status`, local branches ahead of
   the base, existing worktrees, and open PRs. If the user said "work on this",
   the work may already exist locally: inventory it instead of restarting.
1. **Choose the next iteration.** Follow the user's named scope first. Otherwise
   prefer, in order: a failing test or reproduction, a correctness bug, the
   smallest missing piece of the approved feature, then cleanup that unblocks
   the feature. Do not invent new product scope.
2. **Plan in one paragraph.** Change, files, test, acceptance case, risk,
   base branch. If it does not fit in a paragraph, it is too big — split it.
3. **Worktree.** Use the repository's naming and isolation convention
   (`<repo>-<issue#>--<type>--<words>`, branch = directory name). Never work in
   the primary checkout.
4. **Implement.** Reproduce or write the failing test first when practical, then
   the smallest production change that satisfies it. Keep the diff inside the
   iteration's boundary.
5. **Verify.** Run the repository's declared gates for the touched surface, then
   the full gate if cheap. Go repos: `make fmt`, `make lint`, `make test-race`,
   `make build` (or the documented equivalents). Record exact commands and
   outcomes.
6. **Commit.** Atomic commit with `git agent-commit -m "<conventional>"`. Stage
   only files this iteration owns. Reference the acceptance case in the body.
7. **Push and open the PR.** Ready (not draft) so CI runs. Fill the PR shape
   below.
8. **Review wave.** Spawn three independent reviewers in parallel with the
   resolved model. Fix blockers and importants, re-review. Repeat up to three
   cycles.
9. **Record evidence.** Comment the commit, PR URL, gate results, and review
   rounds on the iteration's tracker task. Then, and only then, start the next
   iteration.

### Resuming existing work

When feature branches already exist: map each branch/worktree to an iteration,
run gates on each, push, and open the missing PRs. Preserve unfinished work and
original failure evidence. Do not rebase someone else's branch or delete a
worktree you did not create; ask is not available, so leave it alone and note it.

## PR shape

- Title: conventional commit style, scoped to the change.
- Body, in this order:
  1. **What / why** — one paragraph.
  2. **Scope boundary** — what this PR deliberately does *not* do.
  3. **Acceptance** — the Given/When/Then case, or the observed before/after.
  4. **Verification** — exact commands and results, including CI status.
  5. **Stack** — `1 of 3`, base branch, and merge order, or `standalone`.
  6. **Decisions** — choice, rationale, alternatives, reversibility.
  7. **Known gaps** — residual findings, flaky tests, unverified paths.
- If blocked, mark the PR draft and put the blocker and the exact next action in
  the body. Do not leave a broken PR presented as ready.
- Never merge or close the PR. Leave review state and merge order for the human.

## Stacking

- Branch from the previous iteration only when the change depends on it.
  Otherwise branch from the default branch to keep each PR independently
  adoptable.
- Name the base branch in the PR body and in the handoff. Merge order is
  bottom-up.
- When the base moves, rebase only your own branches and push with
  `--force-with-lease`. Re-run gates after every rebase.
- Prefer not stacking. If two iterations touch the same files, they are probably
  one iteration.

## Review wave

Spawn three reviewers in parallel, each with the same inputs but a distinct
axis:

| Axis | Ask |
|---|---|
| A — Correctness | Does the diff do what the PR claims, without breaking existing behavior? Edge cases, error paths, data loss, concurrency. |
| B — Tests | Do tests exercise the production path (not a test-only export)? Do they cover failure cases and the acceptance case? Would they catch a regression? Are they flaky? |
| C — Elegance / YAGNI | Is the complexity proportional? Any speculative abstraction, unused flag, duplicated logic, or scope creep? Is there a materially smaller change? |

Give each reviewer: the PR URL, `base...head` diff, acceptance case, repo gate
commands, and the scope boundary. Require findings as
`severity (blocker|important|minor) — file:line — problem — concrete fix`, and a
binary vote: `ACCEPT` or `REVISE`.

A **clean wave** is all three `ACCEPT` with zero blocker and zero important
findings. Minor findings are fixed if trivial, otherwise recorded as follow-up.

- Fix blockers and importants in the same branch, commit atomically, push, and
  re-run the wave. Max three cycles per PR.
- If a blocker survives three cycles, mark the PR draft, write the exact blocker
  and attempted fixes, and move to independent work. Do not merge.
- After the final iteration, run one **cross-stack** wave over all open PRs (or
  the cumulative diff): conflicting assumptions, duplicated helpers, merge-order
  breakage. This is the wave that must end clean before you stop.
- Reviewers are ephemeral. If the harness cannot spawn them, stop and report —
  do not substitute self-review and call it clean.

## Decisions

Precedence, highest first:

1. The user's explicit request and the repo's documented invariants.
2. Existing repo conventions (naming, error style, test patterns, gates).
3. The smallest, most reversible option.
4. A prototype behind no public API.

For every non-obvious choice, record in the PR body: the decision, why, the
alternatives considered, and how to reverse it. If two options are plausible and
reversible, pick the smaller one and keep moving. Do not stop to ask.

Reasonable autonomy includes: naming, file placement, test shape, helper
extraction, error wording, choosing between equivalent libraries already in the
repo, and splitting or merging iterations.

## Hard stops

Stop the current line of work, leave a clear note, and continue only with
independent iterations when one of these is true:

- Credentials, permissions, a paid resource, or a secret is required.
- The action is irreversible or destructive: rewriting shared history, deleting
  data or branches, installing/altering Git hooks, force-pushing a shared branch.
- It reaches production: deploy, release, publish, tag, or migrate live data.
- Product intent is genuinely ambiguous and both options change user-facing
  behavior irreversibly.
- The change is security-sensitive and there is no safe default.

Not hard stops: failing tests, flaky tests, CI infrastructure outages, merge
conflicts inside your own stack, missing documentation, an unavailable model
(fall back and record), or an unpleasant design tradeoff.

## Verification and evidence

- Discover gates from `AGENTS.md` / `CLAUDE.md` / `Makefile` / CI. Run the
  narrow gate while iterating, the full gate before calling a PR ready.
- Docs-only changes still run docs/link/frontmatter checks.
- If CI cannot run, say so explicitly and report local results instead. Never
  claim green from a job that did not execute.
- Keep the tree quiescent while verifying. Record the commit SHA the results
  apply to.

## Tracking

- One tracker task per iteration, linked to the parent scope. Labels and
  comments are additive; never delete audit history.
- Comment: branch, commit SHA, PR URL, gate results, review rounds and votes.
- Workers report evidence and never close their own tasks. Close only after the
  clean wave, and only for work you supervised and verified.
- If the tracker is unavailable, report the store path, failed operation, and
  repair needed, then continue with Git and PR evidence. A broken query is not
  proof of no work.

## Morning handoff

Write `.agents.local/afk-<YYYY-MM-DD>.md` (or the repo's existing handoff
directory) and repeat the essentials in the final message:

1. **State** — why the run stopped, what is ready, what is not.
2. **PR table** — link, one-line summary, base, stack position, CI, review
   wave result, recommended merge order.
3. **Decisions** — choice and rationale for each non-obvious call.
4. **Risks** — residual findings, unverified paths, flaky or skipped gates.
5. **Scope boundary** — what you deliberately did not do.
6. **First three checks** — the fastest way for the human to validate the work.

No "done" or "shipped" language for unmerged work. Say "open, review clean,
awaiting merge".

## Exit criteria

Stop the session when all of these are true:

- Every scoped iteration has an open PR, or is explicitly marked draft with a
  hard-stop reason.
- The final cross-stack review wave is clean: three `ACCEPT`, zero blockers,
  zero importants — or the three-cycle budget is exhausted and the residual
  findings are recorded.
- The morning handoff is written and names the merge order.
- No merge occurred, the default branch is untouched, and no unrelated work was
  modified.

Then stop and report. Do not start new scope, do not "while I'm here" anything,
and do not wait or poll for the human.

## Anti-patterns

- Merging because CI is green, or because the user seemed to want speed.
- One giant PR that cannot be adopted progressively.
- Silencing, skipping, or deleting a failing test to reach green.
- Refactoring adjacent code because it was "right there".
- Asking the user a question mid-run and idling; or worse, blocking forever.
- Calling a wave clean without independent reviewers or without reading their
  findings.
- Expanding the backlog instead of stopping at the approved scope.
- Leaving a red or draft PR described as ready in the handoff.
