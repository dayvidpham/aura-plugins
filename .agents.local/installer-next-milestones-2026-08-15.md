# Installer Portfolio: Next Milestones

Original date: 2026-08-15
Last updated: 2026-08-21

> STATUS UPDATE 2026-08-21: Pasture #39 LANDED. PR pasture#99 merged to `main`
> as merge commit `be01293` (epic head `8aceff3` = `9d8a02d` + three residue
> commits). Aura `main` `02d02bd` bumps the pasture flake input and submodule
> pointer `64316a7 -> be01293` (intentional landing) and adds
> `aggregate-release/output_failures_test.go` (`485c1fe`). All historical
> `#39-SLICE-*-REVIEW-*` and Aura IP-1 review leaves were reconciled (closed
> with evidence; 34 previously unconfirmed findings re-verified RESOLVED by
> three independent Opus-5 read-only reviewers; residues fixed under
> `aura-plugins-rwmps5`, closed). Implementation UAT was NOT presented before
> merge — the user explicitly chose to land first. Still open on the epic:
> `opbgi6.8` global validation (gated on Aura IP-2 `yr93f9.2`) and the UAT.
> `internal/install/releasecatalog` has no production caller yet; the
> published-release verification in `opbgi6.8` is its first end-to-end proof.
> The stop boundary recorded 2026-08-15 on `opbgi6` was session-scoped and is
> lifted. `worker-mini-openai`/`reviewer-mini-openai` were unavailable in the
> landing session; `pasture:worker` subagents and independent Opus reviewers
> were used instead.

> STATUS UPDATE (2026-08-16): Pasture #39 global harness implementation (registry, release
> catalog, service, all three global controllers, and the CLI frontend) is
> COMPLETE and integrated on `epic/39-global-installer-delivery`. The
> interactive TUI was deferred by explicit user decision. Remaining #39 work is
> the global-validation slice, implementation UAT, and landing. This document
> has been updated in place to reflect the true state; superseded "next worker
> must..." guidance for already-finished slices has been replaced with the
> completed record.

## Objective

Complete the installer portfolio in this order:

1. Pasture #39 global installer. — global harness + CLI COMPLETE; validation, UAT, landing remain.
2. Aura #8 immutable nine-cell release publication. — IP-1 complete; IP-2 pending.
3. Pasture #96 project installer. — not started.

## Beads Roots and First Reads

Read these before taking any action. `bd show <id>` is the first stop for every
decision; the URD is the single source of truth for requirements.

Run first, in this order:

```bash
bd show aura-plugins-lrzbog     # URD: global multi-harness installation (authority for #39)
bd show aura-plugins-jdj2x      # RATIFIED_PROPOSAL for the installer/compiler portfolio
bd show aura-plugins-j303y0     # IMPL_PLAN: installer portfolio (scope + review-budget record)
bd show aura-plugins-opbgi6     # EPIC #39 global installer (integration points, status)
bd show aura-plugins-opbgi6.8   # #39 next open slice: global validation
```

Portfolio Beads roots:

| Purpose | Beads ID |
|---|---|
| Portfolio IMPL_PLAN | `aura-plugins-j303y0` |
| Pasture #39 epic (global installer) | `aura-plugins-opbgi6` |
| Pasture #39 next open slice (global validation) | `aura-plugins-opbgi6.8` (leaf `opbgi6.8.1`) |
| Pasture #96 epic (project installer) | `aura-plugins-yos54n` |
| Aura #8 integration epic | `aura-plugins-yr93f9` |
| Aura #8 IP-2 (publish release + projection evidence) | `aura-plugins-yr93f9.2` |
| Global installer URD (authority for #39) | `aura-plugins-lrzbog` |
| Project installer URD (authority for #96) | `aura-plugins-re8ksm` |
| Aura projection/release URD (authority for #8) | `aura-plugins-8httug` |
| Ratified proposal | `aura-plugins-jdj2x` |
| Deferred: Bubble Tea installer TUI | `aura-plugins-vjplx5` |

Reviewer authority order is always: URD, ratified proposal, slice acceptance,
leaf assignment, then prior review comments. Prior comments never expand scope
beyond the URD. Every reviewer prompt MUST include the exact `bd show` commands
for the governing URD, ratified proposal, slice, and leaf. For #39 that is:
`bd show aura-plugins-lrzbog`; `bd show aura-plugins-jdj2x`;
`bd show <slice-id>`; `bd show <leaf-id>`.

## Non-Negotiable Constraints

- For all future implementation/fix rounds, use `worker-mini-openai`; for all future review/re-review rounds, use `reviewer-mini-openai`.
- Before every review/re-review wave, the supervisor runs all applicable focused/full race tests, builds, vet/lint, generation-drift, and Nix gates centrally on the exact commit under review.
- Pass the exact commands, outcomes, commit hash, and any isolated-flake evidence to every reviewer. Reviewers must not rerun checks; they focus on code inspection, behavioral correctness, test-oracle quality, maintainability, and acceptance evidence.
- Every reviewer prompt MUST include the exact `bd show` commands for the governing URD, ratified proposal, slice, and leaf. Authority order is URD, ratified proposal, slice acceptance, leaf assignment, then prior review comments. Prior comments cannot expand scope beyond the URD (the URD requires bounded representative validation and forbids exhaustive cross-products).
- Use fresh workers and reviewers; do not resume completed worker sessions.
- Run parallel agents in separate worktrees with exclusive file ownership.
- Never install, enable, or modify Git hooks, `core.hooksPath`, `.git/hooks`, or private host trust state.
- Use `git agent-commit` for commits.
- Preserve unrelated Aura root changes, especially `.claude/skills/tui-components/SKILL.md`.
- Do not update the Aura Pasture submodule pointer until intentional landing.
- Do not add installer-state migration or compatibility code except the explicitly required Claude v0.0.4 monolith migration.
- Existing generated skills remain unchanged unless a canonical target snapshot is intentionally regenerated and drift-tested.

## Current Integration Baseline

Pasture #39 epic worktree:

```text
/home/minttea/codebases/dayvidpham/aura-plugins/pasture/worktree/39--global-installer-delivery
branch: epic/39-global-installer-delivery
HEAD: 9d8a02d
remote state: synced with origin/epic/39-global-installer-delivery (pushed)
worktree: clean
```

Pasture `main` remains at `6fcdc45`; the epic is NOT yet merged to main.

`9d8a02d` contains the full global harness plus CLI:

- Shared registry (`opbgi6.1`, closed).
- Immutable aggregate release catalog (`opbgi6.2`, closed).
- Installer service with the reviewed bounded group-action and central DirectFile policy API (`opbgi6.3`, closed; shared API repair `aura-plugins-dio89g` closed).
- Claude global controller with the exact v0.0.4 monolith migration (`opbgi6.4`, closed at `f31fc15`).
- OpenCode global controller (`opbgi6.5`, closed; hooks at `~/.config/opencode/plugins/pasture-hooks.ts`).
- Codex global controller (`opbgi6.6`, closed at `5c27573`).
- CLI frontend (`opbgi6.7`, closed) — see below.
- Registry `status` empty-store fix (`9232eb3`) and the human-facing install/uninstall grammar (`9d8a02d`).

Final gate evidence at each integration point (full `go test -race ./...`, CGO-disabled build, `go vet`, `nix flake check --no-build`, `nix build .#pasture`, and `make generate` zero drift) passed; A/B/C `reviewer-mini-openai` waves accepted each slice or were explicitly dispositioned.

## Completed: Global Harness Controllers

OpenCode (`opbgi6.5` / leaf `opbgi6.5.1`): integrated at `9b2aa3c`; final implementation before service integration `727be8d`; A/B/C accepted; closed.

Claude (`opbgi6.4` / leaf `opbgi6.4.1`): stateless bounded GroupReconciler against the reviewed service API; exact v0.0.4 monolith migration; strict codecs; truthful partial-result facts; integrated at `f31fc15`. Axis B raised bounded test-completeness gaps that the user classified as non-blocking test debt; only the Axis A duplicate-diagnostic defect was fixed before integration. Closed.

Codex (`opbgi6.6` / leaf `opbgi6.6.1`): central DirectFile policy binding; skills `~/.agents/skills`, agents `~/.codex/agents`, hooks default off with typed pending-trust; integrated at `5c27573e`. A/B/C `0/0/0`. Closed.

## Completed: CLI Frontend (TUI Deferred)

Slice `opbgi6.7` and leaves `opbgi6.7.1` + `aura-plugins-8p4kxv` are closed. The interactive Bubble Tea TUI was DEFERRED by explicit user decision; its design and UAT are tracked on `aura-plugins-vjplx5`. Future TUI must use `charmbracelet/bubbletea` and may use `~/dev/peasant-labs/develop` as design inspiration after separate design/UAT.

Delivered CLI production surfaces (integrated through `9d8a02d`):

- `pasture install` and `pasture install <harness>` — print help (interactive TUI deferred; lone harness is ambiguous).
- `pasture install <harness> <extension>...` — ensure exactly the named cells; unnamed siblings on the same harness are never read or mutated (additive, attempt-all, per-cell reporting).
- `pasture uninstall <harness> <extension>...` — top-level sibling verb; remove exactly the named cells; only Pasture-managed cells are removed, exact external installs preserved.
- `pasture install status [--json]` — read-only confirmed inventory; treats an absent registry file or any absent parent directory as an empty store (`9232eb3`).
- `pasture install plan` — read-only normalization of saved preferences.
- Hidden scripting surfaces retained for Home Manager/automation: `pasture install apply-selection --desired FILE`, `pasture install apply-cell`.

Harness words: `claude` (alias for `claude-code`), `opencode`, `codex`. Extensions: `skills`, `agents`, `hooks`. Each named cell routes through the same typed installer service via `ApplyCell(enabled=true|false)`.

## Milestone 4 (NEXT): Aura Immutable Release Publication

Task: `aura-plugins-yr93f9.2` (Aura #8 IP-2), open.

Deliver:

- Pure-Nix nine-cell projection.
- One immutable aggregate GitHub Release through the protected release pipeline.
- Exact repository revision, manifest, checksum, component, and artifact binding evidence.
- No moving stable alias.
- Home Manager writes no Pasture installer inventory.
- Exact projections are recognized as external/declarative.

Aura IP-1 is already complete at `3a62e73afb3a800015e3aa71ffa07f1ecd5cf72f` against Pasture release-catalog source `f5cbf4f92bb458eb0baff64f6adec603bcf0d74f`.

## Milestone 5: Global Validation

Tasks:

- Slice: `aura-plugins-opbgi6.8` (open).
- Delivery leaf: `aura-plugins-opbgi6.8.1`.

Validate the built production binary and published aggregate release from unrelated temporary roots:

- Bounded nine-cell isolation.
- Skills-only byte identity.
- Idempotence.
- Exact external/declarative preservation.
- First-failure stop and retry convergence.
- Claude v0.0.4 migration matrix.
- No network and no real home in ordinary tests.
- Published-release verification.

This milestone depends on Aura IP-2 publication. The reviewed frontend integration it also depended on is now complete.

## Milestone 6: Pasture #39 UAT and Landing

- Present implementation UAT to the user.
- Resolve or explicitly disposition remaining #39 review findings. NOTE: most open `#39-SLICE-*-REVIEW-*` Beads tasks are historical review-record leaves from superseded/accepted-with-risk rounds, not active work; reconcile or close them as part of landing.
- Close remaining #39 slices (only `opbgi6.8` remains).
- Run full race/build/Nix/generation gates at the epic merge point.
- Open a PR to land `epic/39-global-installer-delivery` into Pasture `main`; the epic is already pushed to origin.
- Do not update the Aura submodule pointer until the Pasture landing is intentional.

## Milestone 7: Pasture #96 Project Installer

After the global service/frontend contracts stabilize (now done), continue:

1. Project foundation and canonical project-root ownership.
2. Project reconciler.
3. Claude project controller.
4. OpenCode project controller.
5. Codex project controller.
6. Project commands and unified status/projects list.
7. Project validation, UAT, and landing.

Project installer epic: `aura-plugins-yos54n` (open).

## Deferred / Tracked-But-Not-Started

- `aura-plugins-vjplx5` — interactive Bubble Tea installer TUI (design + UAT), deferred by user.
- `#38 -> #40 -> #41` compiler chain — cross-harness in-skill tool-name translation (e.g. Claude `Task` -> per-harness native call). CONFIRMED by source profiling: the typed `internal/codegen/ir` Document/Compile/Operation/TargetLiteral/InvokeTool/Capability surface is fully implemented and unit-tested, legacy `RuntimeDialect`/`RuntimeLiteral` string projection is removed, and per-harness native-call lowering tables exist in `internal/runtime/profiles.go`; BUT skill-body emission still runs the legacy `text/template` path (`skills.go` -> `EmitHarness`) with zero production consumers of `ir.Compile`, so skill bodies ship Claude tool vocabulary verbatim into OpenCode/Codex. Not a #39 gate.

## Accepted Residual Risks

Do not represent these previously accepted service findings as fixed unless separately addressed:

- Invalid/wrong-key post-mutation fact persistence outside the repaired group/policy boundary.
- DirectFile partial `CreatedDirs` loss and EACCES misclassification.
- Generic group placement limitations.
- Contradictory ordinary activator facts.
- Duplicate legacy DirectFile authority outside the central production composition.
- Incomplete generic persistence/fault-output oracle coverage.

The reviewed service repair fixed the API blockers needed by Claude and Codex; it did not silently broaden scope to every accepted historical finding.

## Standard Validation

Supervisor-owned gates, run centrally on the exact commit under review (use
`nix develop --command ...` when Go/tooling is not on PATH).

Pasture (from the relevant Pasture worktree):

```bash
nix develop --command env CGO_ENABLED=1 go test -race ./...
nix develop --command go vet ./...
nix develop --command env CGO_ENABLED=0 go build ./...
nix develop --command make generate
git diff --exit-code       # zero generation drift
git diff --check
git status --short --branch
nix flake check --no-build
nix build .#pasture --no-link
```

Aura (from the Aura root):

```bash
nix flake check --no-build
nix build .#aura-swarm --no-link
nix run .#aura-swarm -- --help
nix build .#checks.x86_64-linux.hm-module-test --no-link
```

Record exact commands, pass/fail output, and the commit HEAD, then pass that
evidence to `reviewer-mini-openai` agents and instruct them not to rerun checks.

## Immediate Next Action

1. Decide landing timing for #39: either land the completed global installer + CLI to Pasture `main` now (Milestone 6), or complete Aura IP-2 (Milestone 4) and Global Validation (Milestone 5) first, then land the portfolio together.
2. If landing now: open a Pasture PR from `epic/39-global-installer-delivery`, require CI + independent review + implementation UAT, then merge; update the Aura submodule pointer only as part of that intentional landing.
3. Reconcile the historical `#39-SLICE-*-REVIEW-*` Beads leaves during landing so `bd` reflects the true accepted state.
4. Keep using `worker-mini-openai` / `reviewer-mini-openai` with centralized supervisor gates and URD-first reviewer authority for any remaining fix/review rounds.
