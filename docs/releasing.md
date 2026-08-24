# Releasing aura-plugins

Aura publishes **immutable aggregate plugin releases**. One release version
identifies one coherent set of Claude Code / OpenCode / Codex skills, agents,
and hooks, bound to the exact Aura and Pasture commits it was built from.

Two rules shape everything below:

- **A published version is permanent.** Tags and releases are never moved,
  overwritten, or deleted. A mistake is corrected by publishing the next
  version, not by editing the last one.
- **There is no moving alias.** No `pasture-stable` branch, tag, or "latest"
  pointer exists. Consumers select one exact version.

> **Status: the pipeline is not yet able to publish.** Tag creation and every
> gate are wired and live; asset publication is blocked on a Pasture-side
> component export verb. See [Pending: component export](#pending-component-export).

## The pipeline at a glance

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `.github/workflows/gates.yml` | `workflow_call` only | The full quality gate: `nix flake check -L` (which runs `hm-module-test` and `aggregate-release-test`), `nix build .#aggregate-release`, an assertion that the producer still exposes its seven-option contract, `nix build .#aura-swarm`, `nix run .#aura-swarm -- --help`, `shellcheck` + the release-grammar test suite, and `actionlint`. |
| `.github/workflows/release-pr.yml` | `pull_request` (opened/edited/synchronize/reopened) into `main` | On a `release(...)`-titled PR: validates the title grammar, asserts the author is a maintainer, refuses a version that is already released, then calls `gates.yml` in full. |
| `.github/workflows/release-tag.yml` | `pull_request` `closed` into `main` | When a `release(...)` PR **merges**: mints the immutable annotated tag with the release App token, refusing duplicate tags and unreachable commits. |
| `.github/workflows/release.yml` | `push` of a `v*` tag | Guards the tag (App actor, annotated, reachable from `main`), re-runs `gates.yml` against the tagged commit, then builds and publishes the aggregate. |

Only `release-tag.yml` ever creates a tag, and only the release App can push a
tag that fires `release.yml`. Together those two facts are what make "a release
can only come from a merged release PR" an enforced property rather than a
convention: a hand-pushed `v*` tag produces a failed run and no release.

## Version grammar

`scripts/release/release-grammar.sh` is the single source of the grammar. Every
workflow calls it rather than embedding its own regex, so the PR gate, the tag
job, and the tag guard cannot drift apart.

```
release(vMAJOR.MINOR.PATCH): <summary>          → final release
release(vMAJOR.MINOR.PATCH-rcN): <summary>      → release candidate
```

The grammar is intentionally narrower than SemVer, because it is the
intersection of the PR ceremony and what the aggregate producer's own parser
(`artifact.ParseVersion`) accepts:

- no leading zeros in any numeric component;
- no build metadata (`+...`);
- prereleases are `-rcN` only, with `N` ≥ 1;
- the summary after the colon must be non-empty — it becomes the annotated tag
  message, and is the durable record of *why* the release was cut.

Final releases are listed by default by the installer; release candidates are
visible only through explicit opt-in. The classification is derived from the
version itself, never configured separately.

Run the grammar suite locally:

```bash
scripts/release/release-grammar_test.sh
```

## One-time setup

### 1. The release GitHub App

Tag creation uses a GitHub App token, not the default `GITHUB_TOKEN`, for two
reasons: GitHub refuses to fire workflows for refs pushed with `GITHUB_TOKEN`
(its recursive-workflow guard), so a tag pushed that way would never trigger
publication; and an App token gives the tag a real bot identity that
`release.yml`'s actor guard can then require.

Pasture uses the same pattern and the same secret names, so the **same App can
be installed on both repositories** — see `pasture/.github/workflows/release.yml`,
which reads `RELEASE_APP_ID` and `RELEASE_APP_PRIVATE_KEY`. Reuse it rather than
creating a second App unless you want separate audit trails.

The App installation needs **`Contents: write`** on `aura-plugins`.

### 2. Repository secrets

Settings → Secrets and variables → Actions → *Secrets*:

| Secret | Value |
| --- | --- |
| `RELEASE_APP_ID` | The release App's numeric App ID. |
| `RELEASE_APP_PRIVATE_KEY` | The App's private key, full PEM including the header and footer lines. |

These are the only secrets the release pipeline needs. No values are recorded in
this repository.

### 3. Repository variables (the actor guard)

Settings → Secrets and variables → Actions → *Variables*:

| Variable | Value |
| --- | --- |
| `RELEASE_APP_BOT_LOGIN` | The App's bot login, e.g. `my-releaser[bot]`. |
| `RELEASE_APP_BOT_ID` | The bot user's numeric id. |

These are public identifiers, not secrets, which is why they are variables — the
guard's error message can name the expected identity when it refuses a tag.

They are configured rather than hardcoded because both values are specific to
the App installation. To read them off the first App-created tag:

```bash
gh api "repos/dayvidpham/aura-plugins/actions/runs?event=push" \
  --jq '.workflow_runs[0] | {actor: .actor.login, actor_id: .actor.id}'
```

Until both are set, `release.yml`'s guard **fails closed** — it refuses to
publish rather than accepting an unverified tag.

### 4. Branch protection

`main` should require the `validate release PR` and `gates (release PR)` checks,
so a release PR cannot be merged before the full gate set is green.

## Cutting a release

1. **Open the release PR.** Branch off current `main`. The PR may contain the
   changes being released, or be a marker commit — the gate set runs in full
   either way, precisely because a marker commit would otherwise trigger no
   path-filtered CI.

   Title it exactly:

   ```
   release(v0.1.0): first immutable aggregate release
   ```

2. **Watch the PR checks.** `validate release PR` confirms the title grammar,
   your maintainer role, and that the version is unused. `gates (release PR)`
   runs the full quality gate. Both must be green.

3. **Merge.** `release-tag.yml` then mints the annotated tag `v0.1.0` on the
   merge commit, after re-confirming the tag does not already exist locally or
   on the remote and that the merge commit is reachable from `main`.

4. **Publication runs automatically** from the tag: the guard verifies actor,
   annotation, and reachability; the gates re-run against the tagged commit;
   then the aggregate is built and published.

5. **Afterwards**, bump the aura-plugins entry in
   `.claude-plugin/marketplace.json` if the release should be offered through
   the marketplace.

Nothing in this flow requires a local tag, and no step should ever be performed
by hand. If a release must be re-attempted after a fixed infrastructure problem,
re-run the failed workflow from the Actions tab — the tag already exists and is
reused, never recreated.

## Pending: component export

`aggregate-release/` is a **packager, not a builder**. It takes nine
already-built component archives plus their identities and produces the
immutable, verified release directory: `pasture-aggregate-manifest.json`, its
`.sha256` sidecar, and the nine component assets, all frozen read-only.

What does not exist yet is the step that *builds* those nine archives. Each cell
must arrive with:

- an archive named exactly
  `pasture-<version>-<claude|opencode|codex>-<skills|agents|hooks>.tgz`, a name
  enforced by `artifact.ParseAggregateManifest`; and
- a `bundle_id` — "the exact BundleID emitted by the Pasture target bundle".

Aura cannot produce either correctly:

1. **Bundle ID derivation is Pasture-internal and harness-specific.** Canonical
   bundles are built by Pasture's `internal/target/{claudecode,opencode,codex}`
   packages, and the composition rules differ per harness — Claude Code assigns
   mode `0755` to `*.sh` and `0644` otherwise (because `embed.FS` discards the
   executable bit), while OpenCode assigns a flat `0644`. Mode is a manifest
   field, so it changes the derived bundle ID. Pasture exports only `artifact/`
   and `pkg/protocol`; `internal/target` cannot be imported, and no Pasture CLI
   verb emits component bundles.
2. **The component archive format is undefined.** Nothing in Pasture writes or
   reads such an archive; the aggregate verifier only checks the SHA-256 of the
   opaque asset bytes. Tar member paths, modes, ordering, and gzip determinism
   are unspecified.

Choosing either unilaterally in Aura would make Aura the derivation authority
for provenance that belongs to Pasture's target descriptors — and would freeze
that guess into a release that can never be overwritten.

The resolution is a Pasture-side verb (tracked as `aura-plugins-kcxbma`):

```bash
pasture install export-components --version X.Y.Z --out DIR
```

emitting the nine canonical archives plus a ready `aura.aggregate-components/v1`
component-set JSON with digests and bundle IDs. `release.yml` then pins the
Pasture revision containing that verb, runs it, and pipes the result straight
into `aura-aggregate-release` with its existing seven options — no re-derivation
anywhere in Aura.

Until then `release.yml`'s `build-components` job stops with an actionable error.
A tag cut today is valid and keeps its provenance; publication can be completed
later by re-running the workflow, because the tag is never recreated.

## Open items

- **Pasture revision pinning is currently split.** `flake.nix` pins
  `pastureAggregateContract` to `f5cbf4f92bb458eb0baff64f6adec603bcf0d74f` via
  `fetchzip`, while the `pasture` flake input and the `pasture` submodule were
  moved to `be01293`. A release binds one exact Pasture revision, so these must
  be reconciled — and the reconciled value is what `--pasture-revision` will
  carry — before the first release is published.
- The `publish` and `smoke` jobs land together with `build-components`, once the
  whole path can be exercised for real rather than written blind.
