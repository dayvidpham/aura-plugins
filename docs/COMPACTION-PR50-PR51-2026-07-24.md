# Compaction Report: Pasture PRs #50 and #51

Date: 2026-07-24

## Scope

This report preserves the current state of the Pasture PR #50/#51 repair work,
the relevant Beads audit chain, the Codex target decision, temporary worktrees,
and the remaining implementation and integration sequence.

## GitHub State

| PR | Purpose | Base | GitHub head | State |
|---|---|---|---|---|
| [#50](https://github.com/dayvidpham/pasture/pull/50) | Selectable OpenCode agent models | `feat/codex-codegen` at `0138438` | `bbad87a` | Open; GitHub reports clean against stale base |
| [#51](https://github.com/dayvidpham/pasture/pull/51) | Immutable gated release candidates | `feat/codex-codegen` at `0138438` | `92b0d54` | Open; conflicting |
| [#52](https://github.com/dayvidpham/pasture/pull/52) | Codex skills and custom agents | `main` | `597d1ce` | Open; separate Codex output proposal |

The current `origin/feat/codex-codegen` is `a4e43a50`, six commits ahead of the
PR bases. Those commits contain the reviewed Provenance/task integration line.
Neither PR #50 nor #51 has been pushed or updated with the local repair branches.
No merge has been performed.

## Beads Map

There are no Beads tasks whose titles literally contain GitHub PR `#50` or
`#51`. The mapping is by implementation scope. Beads Proposal 50 is not the
same identifier as GitHub PR #50.

Exact searches also found no matching Beads issue text for `pasture#50`,
`pasture#51`, `pasture #50`, or `pasture #51`. Repository text searches found
no such strings either. The scoped mapping below is therefore the available
audit trail unless a separate external tracker is referenced.

### PR #50: OpenCode Variants

- `aura-plugins-jdj2x` - `FOLLOWUP_PROPOSAL-50`, the ratified parent proposal.
- `aura-plugins-fxwwv` - `FOLLOWUP_IMPL_PLAN: Proposal 50 delivery`, the implementation plan.
- `aura-plugins-fbtjx` - Proposal 50 architect-to-supervisor handoff; its coordinated tracker is Pasture issue #44.
- `aura-plugins-9ycr7` - `FOLLOWUP_SLICE-7: OpenCode agent model variants`.
- `aura-plugins-ygqc4` - typed OpenCode variant contract and deterministic emitter.
- `aura-plugins-1etkr` - Anthropic model catalog.
- `aura-plugins-kkrwe` - OpenAI model catalog.
- `aura-plugins-ev7l7` - generated output and inventory integration.
- `aura-plugins-kbr72` - first combined promotion/OpenCode review wave; closed after clean re-review.
- `aura-plugins-o33a8` - second combined activation/promotion/agent-rendering review wave; closed after clean re-review.
- `aura-plugins-qnhu7` - open Codex-specific wording leaf, intentionally gated on the Codex adapter/installer contract.
- `aura-plugins-j76rn` - final Proposal 50 implementation UAT, still open.

The four current PR #50 review blockers are recorded in the GitHub review
comment rather than separate Beads blocker tasks:

- OpenCode read permission rules may override protected `.env` behavior: `internal/codegen/opencode_agent.go`, `internal/codegen/opencode_agent_test.go`, and the OpenCode agent template.
- Primary OpenCode agents lack native `question` permission: `internal/codegen/opencode_agent.go` and generated frontmatter tests.
- Generated OpenCode agent/skill instructions use `pasture:{role}` while emitted skills have bare names: `internal/codegen/agents.go`, `internal/codegen/skills.go`, and target-specific skill/agent rendering.
- `install-cli` uses raw `uname -m` values instead of release names `amd64`/`arm64`: `internal/codegen/templates/install_cli_body.md` and generated install skills.

Review: [PR #50 review comment](https://github.com/dayvidpham/pasture/pull/50#pullrequestreview-4777609778).

### PR #51: Promotion

- `aura-plugins-ypk74` - `LEAF S6.1: Aggregate Aura marketplace and Pasture promotion (#9)`, the implementation owner for the Pasture promotion code. The `#9` reference is the Aura issue, not Pasture PR #9.
- `aura-plugins-iwoh4` - S6.1 three-axis review wave; closed after clean re-review.
- `aura-plugins-kbr72` - combined promotion/OpenCode review wave.
- `aura-plugins-o33a8` - combined atomic activation/promotion/agent-rendering review wave.
- `aura-plugins-b7ign` - open S6 follow-up leaf for deferred promotion residuals.
- `aura-plugins-6fa1d` - open integration review for `feat/codex-codegen@a4e43a5`.
- `aura-plugins-2o1d3` - open S3 integration task for the current `feat/codex-codegen` line.

The current PR #51 blocker is recorded in the GitHub review comment:

- Mandatory race gates cannot run in the advertised Nix environments because the promotion app lacks a Go/cgo-capable toolchain and the development shell exports `CGO_ENABLED=0`: `internal/promotion/promote.go`, `internal/effects/gitpusher.go`, `cmd/pasture-release/promote.go`, and `flake.nix`.

The hardcoded three-component projection in `internal/promotion/projection.go`
is a residual evolution risk, not the current blocking fix. It is consistent
with the current fixed Claude target descriptor and belongs in follow-up work.

Review: [PR #51 review comment](https://github.com/dayvidpham/pasture/pull/51#pullrequestreview-4777609779).

### Downstream Codex Tasks

- `aura-plugins-c4q1k` - early Codex skills/agents through Home Manager slice.
- `aura-plugins-6ft9w` - early Codex/Aura implementation leaf, still open/in progress in Beads.
- `aura-plugins-w1nzr` and `aura-plugins-y28g3` - broader native-output planning and Codex target work.

The user-confirmed Codex contract is recorded on `aura-plugins-c4q1k`,
`aura-plugins-6ft9w`, and `aura-plugins-c4q1k` comments:

- Pasture skills: `.agents/skills` -> Home Manager `~/.agents/skills`.
- Pasture custom agents: `.codex/agents` -> Home Manager `~/.codex/agents`.
- Do not create a second compatibility skill tree.
- Keep the rest of the existing Codex target infrastructure.

## Correct Codex Consolidation

`feat/codex-codegen` already contains the substantive Codex target from
`5688ca2`, including:

- `internal/codegen/codex.go`
- `internal/codegen/codex_agent.go`
- `internal/codegen/codex_manifest.go`
- Codex runtime-contract/native-operation validation
- `CodexTargetDescriptor`, package identities, artifact bundles, manifests, and digests
- deterministic target validation and tests
- Codex hooks/verbatim support-tree plumbing

PR #52 must therefore be ported as an output-contract correction, not merged
as a second `HarnessCodex` implementation:

- Change the skill root from `.codex/skills` to `.agents/skills`.
- Keep `.codex/agents` for custom-agent TOMLs.
- Retain the artifact, descriptor, manifest, runtime, validation, and test infrastructure.
- Update component roots, partitioning, inventories, generated outputs, and Aura consumers together.
- Keep direct Home Manager consumption separate from any optional packaging/manifest representation.

## Temporary Worktrees

### PR #50

- Path: `/tmp/opencode/pasture-pr50`
- Branch: `fix/pr50-blockers`
- HEAD: `a091a8c`
- Base: `a4e43a50`
- Status: clean, local only, not pushed.
- The branch is a rebased local copy of PR #50. Its tree delta from the original PR head is the newer base integration line; it does not yet contain the four blocker repairs.

Relevant PR #50 source files include:

- `internal/codegen/agents.go`
- `internal/codegen/skills.go`
- `internal/codegen/opencode_agent.go`
- `internal/codegen/opencode_agent_test.go`
- `internal/codegen/opencode_skill_test.go`
- `internal/codegen/opencode_verbatim.go`
- `internal/codegen/templates/opencode_agent.go.tmpl`
- `internal/codegen/templates/install_cli_body.md`
- generated `.opencode/agent/**`, `.opencode/skill/**`, Claude assets, `skills/**`, `agents/**`, and `schema.xml`

### PR #51

- Path: `/tmp/opencode/pasture-pr51`
- Branch: `pr-51-blocker-fix`
- HEAD: `dba5493`
- Base: `a4e43a50`
- Status: clean, local only, not pushed.
- The branch is a rebased local copy of PR #51. It does not yet contain the cgo/race-gate environment repair.

Relevant PR #51 source files include:

- `internal/effects/gitpusher.go`
- `internal/effects/gitpusher_test.go`
- `internal/promotion/promote.go`
- `internal/promotion/promote_integration_test.go`
- `internal/promotion/projection.go`
- `cmd/pasture-release/promote.go`
- `cmd/pasture-release/promote_cli_test.go`
- `flake.nix`
- `internal/testutil/fixtures.go`

### Other Relevant Worktrees

- Pasture PR #52: `/home/minttea/codebases/dayvidpham/pasture/feat--codex-assets`, branch `feat/codex-assets`, HEAD `597d1ce`, clean and pushed.
- Aura Home Manager projection: `/home/minttea/codebases/dayvidpham/aura-plugins/worktree/codex-home-manager`, branch `feat/codex-home-manager`, HEAD `461b569`, clean and local only.

## Repair Plan

1. Consolidate the Codex target on current `feat/codex-codegen` while retaining its packaging/runtime/validation infrastructure and adopting `.agents/skills` plus `.codex/agents`.
2. Regenerate and test the combined Codex/Claude/OpenCode inventories. Generated artifacts remain committed; CI codegen drift remains authoritative.
3. Rebase PR #50 onto the consolidated base and implement all four OpenCode/install-cli blockers. Preserve Claude rendering and translate only actual target-specific skill invocations.
4. Regenerate all affected OpenCode, Claude, schema, and Codex artifacts and run production-emitter tests.
5. Rebase PR #51 onto the resulting #50/base line. Add an injected environment-overlay command runner, force mandatory race gates to use `CGO_ENABLED=1`, and provide Go plus a C compiler in the promotion Nix runtime. Keep normal release builds `CGO_ENABLED=0`.
6. Recalculate the final Nix vendor hash from the final dependency tree.
7. Run full Go normal/race/vet/build gates, Nix checks/builds, codegen drift, and relevant production CLI tests.
8. Push updated PR branches only after local verification. Do not merge without explicit user authorization.
9. After Pasture lands, update Aura `flake.lock` to the exact landed Pasture revision and then publish the Aura projection branch if requested.

Implementation dispatch policy: use `general` subagents acting as workers, with
the first prompt line `Skill(/pasture:worker)`. Do not use the `worker`
subagent type, because its generated agent definition selects a different model.

## Remaining Work

- Port PR #52's paths into the existing Codex target; PR #52 must not be merged verbatim.
- Implement and test the four PR #50 blockers.
- Implement and test the PR #51 cgo-capable race-gate environment.
- Resolve PR #51's GitHub conflict and update both PR bases from `0138438`.
- Decide whether the existing Codex manifest/hooks package representation needs a separate downstream contract test after the direct Home Manager path change.
- Resolve the open Codex-specific wording leaf `aura-plugins-qnhu7` only after the Codex adapter/installer contract is ready.
- Wire Aura's `nix/hm-module-test.nix` into the flake checks and update `flake.lock` after the final Pasture revision lands.
- Run fresh independent reviews of the repaired PRs.
- Complete Proposal 50 implementation UAT `aura-plugins-j76rn` before landing.

## Non-Goals

- Do not replace the existing Codex target with PR #52's parallel implementation.
- Do not merge PRs during this repair phase.
- Do not modify Provenance/runtime work outside the PR/base integration required for rebasing.
- Do not install or modify Git hooks.
- Do not run `aura-swarm`; use general subagents and direct project gates.
