# Immutable aggregate release producer contract

`aura-aggregate-release` builds, but does not publish, one immutable aggregate
release directory for Pasture's closed three-harness by three-extension matrix.
The later publication workflow can upload the directory's eleven files without
rewriting them.

## Production API

```console
nix run .#aggregate-release -- \
  --version 1.2.0 \
  --installer-min 1.0.0 \
  --installer-max 1.9.9 \
  --pasture-revision <exact-40-character-commit> \
  --aura-revision <exact-40-character-commit> \
  --components ./components.json \
  --output-dir ./dist/1.2.0
```

The component-set document is strict JSON. Root and component-record field names
must match the documented lowercase spellings exactly; unknown, case-variant,
or duplicate fields are rejected. Artifact paths are relative to the document
unless absolute.

```json
{
  "schema": "aura.aggregate-components/v1",
  "components": [
    {
      "id": "claude-code/skills",
      "artifact": "build/claude-skills.tgz",
      "asset": "pasture-1.2.0-claude-skills.tgz",
      "bundle_id": "artifact.bundle.v1:sha256:<64 lowercase hex>"
    }
  ]
}
```

The array must contain exactly one record for every component returned by
Pasture's typed `artifact.ComponentIDs`. The `bundle_id` comes from the
corresponding Pasture target bundle. The `asset` is supplied explicitly and is
accepted only when Pasture's aggregate constructor recognizes it as the exact
canonical immutable basename. Aura does not recreate either identity.

## Frozen output

The producer:

- parses version, revisions, component IDs, and bundle IDs with Pasture's typed
  constructors and derives `final` versus `prerelease` from the typed version;
- obtains each harness's registered runtime contract from Pasture and validates
  supplied asset names through Pasture's aggregate constructor;
- computes each archive's digest with Pasture's typed digest function;
- binds every component and the aggregate to the same exact Aura and Pasture
  revisions and one inclusive installer compatibility range;
- marshals Pasture's typed aggregate manifest and emits Pasture's canonical
  checksum sidecar bytes; and
- atomically claims a new output directory and refuses to overwrite it.

There is no channel alias, latest-version lookup, fallback selection, per-cell
version input, catalog mutation, or publication operation in this producer.
The shipped Go producer is compiled against Pasture commit
`f5cbf4f92bb458eb0baff64f6adec603bcf0d74f`, pinned by source hash in
`flake.nix`. It runs the same commit's public `artifact.VerifyAggregate` before
freezing a completed directory. The normal `aggregate-release-test` flake check
builds and tests this direct typed production path; there is no optional or
skipping compatibility adapter.
