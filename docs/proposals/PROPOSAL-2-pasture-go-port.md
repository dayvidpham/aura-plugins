# PROPOSAL-2: Pasture — Go Port of aura-protocol with ACP + Observability

---
references:
  request: aura-plugins-pv2ek
  urd: aura-plugins-jbnx3
  elicit: aura-plugins-usz42
  supersedes: aura-plugins-4vypg (PROPOSAL-1)
  research_golang: docs/research/golang-port.md
  research_acp: llm/research/agent-client-protocol-alignment.md
  research_xcompile: llm/research/static-cross-compilation-binary-distribution.md
  reference_repo: ~/dev/agent-data-leverage/develop
  review_A: aura-plugins-spp4o (REVISE — correctness)
  review_B: aura-plugins-gergi (REVISE — test quality)
  review_C: aura-plugins-8xhrw (ACCEPT — elegance)
---

## Changes from PROPOSAL-1

| # | Source | Severity | Issue | Resolution |
|---|--------|----------|-------|------------|
| 1 | A-BLOCKER-1 | BLOCKER | PhaseId type duplication (internal/types vs pkg/protocol) | Canonical PhaseId lives in pkg/protocol/. internal/types aliases: `type PhaseId = protocol.PhaseId`. Same for EventType. |
| 2 | A-BLOCKER-2 | BLOCKER | /pasture:install-cli skill has no structural placement | Added `skills/install-cli/SKILL.md` to project structure + S12 scope description |
| 3 | A-IMPORTANT-1 | IMPORTANT | S12 cannot run parallel with Waves 2-3 (depends S5+S8) | Wave schedule corrected: S12 → Wave 4 alone. S11 stays parallel with Waves 2-3. |
| 4 | A-IMPORTANT-2 | IMPORTANT | Hooks interface (R4/D7) has no structural representation | Added internal/hooks/ package with HookHandler interface |
| 5 | A-MINOR | MINOR | SemVer.Bump stringly-typed kind | Introduced BumpKind typed enum |
| 6 | B-F1 | IMPORTANT | 6/8 pasture-msg subcommands missing BDD | Added BDD scenarios for all 8 subcommands + exit code table |
| 7 | B-F2 | IMPORTANT | Config resolution priority has no BDD | Added config resolution BDD scenario |
| 8 | B-F3 | IMPORTANT | ACP adapter coverage absent | Added BDD scenarios for adapter_claude, adapter_opencode, HandleSessionEnd |
| 9 | B-F4 | MINOR | ACP back-pressure qualifier untestable | Replaced with concrete metric: 1000 updates/sec, no dropped events |
| 10 | B-F5 | IMPORTANT | 2/3 pasture-release features no BDD | Added BDD for sync-versions and release-order |
| 11 | B-F6 | IMPORTANT | Audit durability scenario unexecutable | Rewritten as executable kill-restart-query sequence |
| 12 | B-F7 | IMPORTANT | Coverage thresholds missing for key packages | Added thresholds for internal/temporal, internal/audit, internal/acp |
| 13 | C-note | MINOR | AuditTrail config field stringly-typed | PasturedConfig.AuditTrail now uses AuditTrailBackend enum |
| 14 | C-note | MINOR | Exec mixes concerns on PluginRegistry | Noted as acceptable for MVP; documented refactor path |
| 15 | B-R2-BLOCKER | BLOCKER | Exit code table swapped (1↔3) vs URD R2 | Aligned to URD: 1=validation, 2=connection, 3=workflow. All BDD scenarios updated. |
| 16 | UAT-1 | REVISION | internal/types/aliases.go indirection unnecessary | Removed aliases.go. Internal packages import pkg/protocol directly. |
| 17 | UAT-1 | REVISION | Hook event set incomplete | Added 5 events: HookSliceFailed, HookConstraintViolation, HookConnectionLost, HookSessionStarted, HookSessionEnded (12 total) |
| 18 | UAT-1 | REVISION | ACP adapter functions not extensible | Replaced standalone AdapterClaude/AdapterOpenCode with Adapter interface + registration |
| 19 | UAT-1 | REVISION | pasture repo not linked to aura-plugins | Add pasture as git submodule in aura-plugins repo |

## Problem Space

Port Python aura-protocol (aurad + aura-msg + aura-release) to Go as the new **Pasture** project, integrating ACP (Agent Client Protocol) for live agent observability, and establishing a polyrepo marketplace for Claude Code plugins.

**Axes:**
- **Parallelism:** High — pastured handles concurrent workflows (EpochWorkflow, SliceWorkflow, ReviewPhaseWorkflow). ACP client handles concurrent agent sessions. pasture-release may operate across multiple repos.
- **Distribution:** Distributed — pastured ↔ Temporal server ↔ pasture-msg. ACP client ↔ running agents via JSON-RPC.
- **Scale:** Moderate — single-team usage initially, but types must be stable for convergence with agent-data-leverage analytics pipeline.
- **Has-a / Is-a:** Pasture *has-a* Temporal client, *has-a* ACP client, *has-a* audit trail, *has-a* hooks manager. Pasture *is-a* multi-agent orchestration platform.

## Engineering Tradeoffs

| Decision | Option A | Option B | Choice | Rationale |
|----------|----------|----------|--------|-----------|
| T1: CLI framework | Cobra + Viper | Kong (struct-based) | **Cobra + Viper** | First-class Viper integration, used by Temporal CLI, largest ecosystem |
| T2: Command dispatch | Cobra RunE directly | Command interface pattern | **Hybrid** (D4) | Cobra RunE → standalone handlers. Testable without Cobra. Upgrade path to full Command interface. |
| T3: Signal/query names | String literals | Shared constants package | **Shared constants** (D10) | Prevents name drift between pastured worker and pasture-msg client |
| T4: SQLite driver | mattn/go-sqlite3 (CGo) | modernc.org/sqlite (pure Go) | **modernc.org/sqlite** | Enables CGO_ENABLED=0 static cross-compilation for all platforms |
| T5: Config resolution | Manual priority chain | Viper automatic resolution | **Viper** | Handles CLI > env > YAML > defaults natively. Same pattern as reference repo. |
| T6: ACP integration layer | In internal/acp/ | In pkg/ (public) | **internal/acp/** | Keep ACP as internal implementation detail. Public types in pkg/protocol/ for convergence. |
| T7: Audit trail interface | Global singleton (Python pattern) | Dependency injection via struct | **DI via struct** | Go idiom. Pass AuditTrail to worker/handler constructors. More testable. |
| T8: Error model | fmt.Errorf wrapping | StructuredError type | **StructuredError** | Implements error interface + Report(io.Writer). errors.As() extraction. Testable output. |
| T9: Public types location | All in internal/ | pkg/protocol/ for convergence types | **pkg/protocol/** | Types that agent-data-leverage will eventually import should be in a public package. |
| T10: pasture-release language | Go (consistent) | Keep Python (proven) | **Go** | Full Go rewrite per user decision. Static binary, cross-compiled, consistent toolchain. |

## Project Structure

```
github.com/dayvidpham/pasture/
  cmd/
    pastured/
      main.go                    # Worker daemon entry point
    pasture-msg/
      main.go                    # CLI messaging tool entry point
      root.go                    # Cobra root command + global flags
      epoch.go                   # epoch group (start, cancel, terminate)
      query.go                   # query group (state)
      signal.go                  # signal group (vote, complete)
      phase.go                   # phase group (advance)
      session.go                 # session group (register)
    pasture-release/
      main.go                    # Release tool entry point
  internal/
    config/
      config.go                  # ConnectionConfig, PasturedConfig, PastureMsgConfig
      viper.go                   # Viper wiring (BindPFlag, BindEnv, SetDefault)
    errors/
      errors.go                  # StructuredError, ErrorCategory, Report(io.Writer)
    handlers/
      query.go                   # QueryState(ctx, conn, epochID, fmt) → (int, error)
      epoch.go                   # EpochStart, EpochCancel, EpochTerminate
      signal.go                  # SignalVote, SignalComplete
      phase.go                   # PhaseAdvance
      session.go                 # SessionRegister
    formatters/
      formatters.go              # FormatEpochState, FormatStartResult, FormatSignalResult
    hooks/
      hooks.go                   # HookHandler interface, HookEvent, HookManager
    types/
      enums.go                   # VoteType, ReviewAxis, Domain, RoleId, BumpKind, etc.
      signals.go                 # PhaseAdvanceSignal, ReviewVoteSignal, etc.
      queries.go                 # QueryStateResult, EpochState
      config_types.go            # AuditTrailBackend, OutputFormat, SliceMode
    temporal/
      constants.go               # Signal/query name constants (shared between cmd/pastured and cmd/pasture-msg)
      workflow.go                # EpochWorkflow function
      workflow_slice.go          # SliceWorkflow function
      workflow_review.go         # ReviewPhaseWorkflow function
      activities.go              # check_constraints, record_transition
      search_attributes.go       # EnsureSearchAttributes, _REQUIRED_SEARCH_ATTRIBUTES
      state_machine.go           # EpochStateMachine, EpochState, TransitionRecord
    audit/
      audit.go                   # AuditTrail interface
      memory.go                  # InMemoryAuditTrail
      sqlite.go                  # SqliteAuditTrail
      activities.go              # record_audit_event, query_audit_events (Temporal activities)
    acp/
      client.go                  # ACP Client implementation (implements acp.Client interface)
      indexer.go                 # SharedIndexer: []acp.SessionUpdate → []protocol.SessionEntry
      adapter.go                 # Adapter interface + registration (RegisterAdapter, GetAdapter)
      adapter_claude.go          # Claude JSONL Adapter implementation
      adapter_opencode.go        # OpenCode JSON Adapter implementation
    release/
      version.go                 # SemVer, BumpKind, VersionFile interface, discovery
      changelog.go               # Conventional commit parsing, changelog generation
      registry.go                # PluginRegistry, PluginEntry, MarketplaceEntry
      runner.go                  # RegistryRunner — exec/sync across registered repos (MVP: methods on PluginRegistry; refactor target)
      git.go                     # Git helpers (status, tag, commit)
  pkg/
    protocol/
      types.go                   # Public convergence types (PhaseId, EventType, AuditEvent)
      session_entry.go           # SessionEntry (aligned with agent-data-leverage pkg/schema)
  skills/
    install-cli/
      SKILL.md                   # /pasture:install-cli skill — OS/arch detection + binary fetch
  flake.nix
  go.mod
  go.sum
  Makefile
  .github/
    workflows/
      release.yml                # Cross-platform build + GitHub Releases
```

## Public Interfaces

### pkg/protocol — Convergence Types (CANONICAL)

```go
package protocol

// PhaseId represents an epoch lifecycle phase.
// This is the CANONICAL definition. internal/types aliases this type.
type PhaseId string

const (
    P1_Request     PhaseId = "p1_request"
    P2_Elicit      PhaseId = "p2_elicit"
    P3_Propose     PhaseId = "p3_propose"
    P4_Review      PhaseId = "p4_review"
    P5_PlanUat     PhaseId = "p5_plan_uat"
    P6_Ratify      PhaseId = "p6_ratify"
    P7_Handoff     PhaseId = "p7_handoff"
    P8_ImplPlan    PhaseId = "p8_impl_plan"
    P9_Slice       PhaseId = "p9_slice"
    P10_CodeReview PhaseId = "p10_code_review"
    P11_ImplUat    PhaseId = "p11_impl_uat"
    P12_Landing    PhaseId = "p12_landing"
    Complete       PhaseId = "complete"
)

// IsValid returns true if the PhaseId is a known value.
func (p PhaseId) IsValid() bool { /* ... */ }

// ParsePhaseId parses a phase string in any supported format
// (e.g., "p1", "1", "request", "p1_request", "P1_Request").
func ParsePhaseId(s string) (PhaseId, error) { /* ... */ }

// EventType classifies audit trail events.
type EventType string

const (
    EventPhaseTransition    EventType = "PhaseTransition"
    EventPhaseAdvance       EventType = "PhaseAdvance"
    EventVoteRecorded       EventType = "VoteRecorded"
    EventConstraintChecked  EventType = "ConstraintChecked"
    EventSliceStarted       EventType = "SliceStarted"
    EventSliceCompleted     EventType = "SliceCompleted"
    EventSessionRegistered  EventType = "SessionRegistered"
    EventReviewCycleStarted EventType = "ReviewCycleStarted"
)

// IsValid returns true if the EventType is a known value.
func (e EventType) IsValid() bool { /* ... */ }

// AuditEvent is an immutable audit trail entry.
type AuditEvent struct {
    EpochID   string    `json:"epochId"`
    Phase     PhaseId   `json:"phase"`
    Role      string    `json:"role"`
    EventType EventType `json:"eventType"`
    Payload   string    `json:"payload"`
    Timestamp int64     `json:"timestamp"`
}
```

### internal/types — Internal Enums

Internal packages import `pkg/protocol` directly for PhaseId, EventType, and AuditEvent.
No aliases or re-exports — `pkg/protocol` is the single canonical source.

```go
package types

// VoteType represents a review vote.
type VoteType string
const (
    VoteAccept VoteType = "Accept"
    VoteRevise VoteType = "Revise"
)
func (v VoteType) IsValid() bool { /* ... */ }

// ReviewAxis identifies the review dimension.
type ReviewAxis string
const (
    AxisCorrectness ReviewAxis = "Correctness"
    AxisTestQuality ReviewAxis = "TestQuality"
    AxisElegance    ReviewAxis = "Elegance"
)
func (a ReviewAxis) IsValid() bool { /* ... */ }

// OutputFormat for CLI output rendering.
type OutputFormat string
const (
    FormatJSON OutputFormat = "json"
    FormatText OutputFormat = "text"
)
func (f OutputFormat) IsValid() bool { /* ... */ }

// AuditTrailBackend selects the audit persistence implementation.
type AuditTrailBackend string
const (
    AuditBackendMemory AuditTrailBackend = "memory"
    AuditBackendSQLite AuditTrailBackend = "sqlite"
)
func (b AuditTrailBackend) IsValid() bool { /* ... */ }

// BumpKind specifies the semver component to increment.
type BumpKind string
const (
    BumpMajor BumpKind = "major"
    BumpMinor BumpKind = "minor"
    BumpPatch BumpKind = "patch"
)
func (k BumpKind) IsValid() bool { /* ... */ }
```

### internal/audit — Audit Trail Interface

```go
package audit

import "github.com/dayvidpham/pasture/pkg/protocol"

// Trail is the pluggable audit persistence interface.
type Trail interface {
    RecordEvent(ctx context.Context, event protocol.AuditEvent) error
    QueryEvents(ctx context.Context, epochID string, phase *protocol.PhaseId, role *string) ([]protocol.AuditEvent, error)
}
```

### internal/temporal — Signal/Query Constants

```go
package temporal

// Signal names — shared between pastured (receiver) and pasture-msg (sender).
const (
    SignalAdvancePhase    = "advance_phase"
    SignalSubmitVote      = "submit_vote"
    SignalSliceProgress   = "slice_progress"
    SignalRegisterSession = "register_session"
)

// Query names — shared between pastured (handler) and pasture-msg (caller).
const (
    QueryCurrentState          = "current_state"
    QueryAvailableTransitions  = "available_transitions"
    QueryFullState             = "full_state"
)
```

### internal/handlers — Standalone Handler Functions

```go
package handlers

import (
    "context"
    "github.com/dayvidpham/pasture/internal/config"
    "github.com/dayvidpham/pasture/internal/types"
)

// QueryState queries the full state of an epoch workflow.
// Returns exit code and error. Does not depend on any CLI framework.
func QueryState(ctx context.Context, conn config.ConnectionConfig, epochID string, fmt types.OutputFormat) (int, error)

// EpochStart starts a new epoch workflow.
func EpochStart(ctx context.Context, conn config.ConnectionConfig, epochID string, description string, taskQueue string, fmt types.OutputFormat) (int, error)

// EpochCancel requests graceful cancellation of an epoch workflow.
func EpochCancel(ctx context.Context, conn config.ConnectionConfig, epochID string, fmt types.OutputFormat) (int, error)

// EpochTerminate immediately terminates an epoch workflow.
func EpochTerminate(ctx context.Context, conn config.ConnectionConfig, epochID string, reason string, fmt types.OutputFormat) (int, error)

// SignalVote sends a review vote signal to an epoch workflow.
func SignalVote(ctx context.Context, conn config.ConnectionConfig, epochID string, axis types.ReviewAxis, vote types.VoteType, reviewerID string, fmt types.OutputFormat) (int, error)

// SignalComplete sends a slice completion signal.
func SignalComplete(ctx context.Context, conn config.ConnectionConfig, epochID string, sliceID string, output *string, errMsg *string, fmt types.OutputFormat) (int, error)

// PhaseAdvance sends a phase advance signal.
func PhaseAdvance(ctx context.Context, conn config.ConnectionConfig, epochID string, toPhase types.PhaseId, triggeredBy string, condition string, fmt types.OutputFormat) (int, error)

// SessionRegister sends a session registration signal.
func SessionRegister(ctx context.Context, conn config.ConnectionConfig, epochID string, sessionID string, role string, modelHarness string, model string, fmt types.OutputFormat) (int, error)
```

### internal/errors — Structured Error Reporting

```go
package errors

import (
    "fmt"
    "io"
)

// Category classifies the error domain.
type Category string

const (
    CategoryConnection Category = "connection error"
    CategoryWorkflow   Category = "workflow error"
    CategoryValidation Category = "validation error"
    CategoryConfig     Category = "config error"
)

// StructuredError implements the error interface with actionable fields.
type StructuredError struct {
    Category Category
    What     string
    Why      string
    Impact   string
    Fix      string
}

func (e *StructuredError) Error() string {
    return fmt.Sprintf("%s: %s", e.Category, e.What)
}

// Report writes the full structured error to w (testable via bytes.Buffer).
func (e *StructuredError) Report(w io.Writer) {
    fmt.Fprintf(w, "%s: %s\n", e.Category, e.What)
    fmt.Fprintf(w, "  why: %s\n", e.Why)
    fmt.Fprintf(w, "  impact: %s\n", e.Impact)
    fmt.Fprintf(w, "  fix: %s\n", e.Fix)
}
```

### internal/config — Config Resolution

```go
package config

import "github.com/dayvidpham/pasture/internal/types"

// ConnectionConfig holds Temporal connection parameters (frozen after resolution).
type ConnectionConfig struct {
    Namespace     string `yaml:"namespace" mapstructure:"namespace"`
    TaskQueue     string `yaml:"task_queue" mapstructure:"task_queue"`
    ServerAddress string `yaml:"server_address" mapstructure:"server_address"`
}

// PasturedConfig holds the full pastured daemon configuration.
type PasturedConfig struct {
    Connection  ConnectionConfig      `yaml:"connection" mapstructure:"connection"`
    AuditTrail  types.AuditTrailBackend `yaml:"audit_trail" mapstructure:"audit_trail"`
    AuditDBPath string                `yaml:"audit_db_path" mapstructure:"audit_db_path"`
}

// PastureMsgConfig holds the pasture-msg CLI configuration.
type PastureMsgConfig struct {
    Connection    ConnectionConfig  `yaml:"connection" mapstructure:"connection"`
    DefaultFormat types.OutputFormat `yaml:"default_format" mapstructure:"default_format"`
}

// Environment variable names.
const (
    EnvNamespace    = "TEMPORAL_NAMESPACE"
    EnvTaskQueue    = "TEMPORAL_TASK_QUEUE"
    EnvAddress      = "TEMPORAL_ADDRESS"
    EnvAuditTrail   = "PASTURE_AUDIT_TRAIL"
    EnvAuditDBPath  = "PASTURE_AUDIT_DB_PATH"
)

// DefaultConfigPath returns ~/.config/pasture/config.yaml
func DefaultConfigPath() string
```

### internal/hooks — Claude Code Hooks Interface

```go
package hooks

import (
    "context"
    "github.com/dayvidpham/pasture/pkg/protocol"
)

// HookEvent represents an event that can trigger hooks.
type HookEvent string

const (
    // Lifecycle events
    HookPhaseTransition HookEvent = "phase_transition"
    HookVoteRecorded    HookEvent = "vote_recorded"
    HookSliceStarted    HookEvent = "slice_started"
    HookSliceCompleted  HookEvent = "slice_completed"
    HookEpochStarted    HookEvent = "epoch_started"
    HookEpochCompleted  HookEvent = "epoch_completed"
    HookReviewCycle     HookEvent = "review_cycle"

    // Error/failure events (UAT-1 addition)
    HookSliceFailed          HookEvent = "slice_failed"
    HookConstraintViolation  HookEvent = "constraint_violation"
    HookConnectionLost       HookEvent = "connection_lost"

    // ACP session events (UAT-1 addition)
    HookSessionStarted  HookEvent = "session_started"
    HookSessionEnded    HookEvent = "session_ended"
)

// HookPayload carries the event data passed to hook handlers.
type HookPayload struct {
    Event   HookEvent          `json:"event"`
    EpochID string             `json:"epochId"`
    Phase   protocol.PhaseId   `json:"phase,omitempty"`
    Data    map[string]any     `json:"data,omitempty"`
}

// HookHandler processes lifecycle events from pastured.
// Implementations may write to Claude Code hooks files, send notifications,
// or forward events to external systems.
type HookHandler interface {
    // Handle processes a hook event. Implementations must be non-blocking.
    Handle(ctx context.Context, payload HookPayload) error

    // Events returns the set of events this handler subscribes to.
    Events() []HookEvent
}

// Manager dispatches hook events to registered handlers.
type Manager struct {
    handlers map[HookEvent][]HookHandler
}

// NewManager creates a hook manager with no registered handlers.
func NewManager() *Manager

// Register adds a handler for its declared events.
func (m *Manager) Register(h HookHandler)

// Dispatch sends a payload to all handlers registered for payload.Event.
func (m *Manager) Dispatch(ctx context.Context, payload HookPayload) error
```

### internal/acp — ACP Client + Shared Indexer

```go
package acp

import (
    acpsdk "github.com/coder/acp-go-sdk"
    "github.com/dayvidpham/pasture/pkg/protocol"
)

// SessionHandler processes live ACP session updates.
// Implementations handle indexing, storage, forwarding, etc.
type SessionHandler interface {
    HandleUpdate(ctx context.Context, update acpsdk.SessionUpdate) error
    HandleSessionEnd(ctx context.Context, sessionID string, reason acpsdk.StopReason) error
}

// Client connects to ACP-compatible agents and receives live session updates.
type Client struct {
    handler SessionHandler
    conn    *acpsdk.ClientSideConnection
}

// NewClient creates an ACP client that forwards session updates to the handler.
func NewClient(handler SessionHandler) *Client

// Connect connects to an ACP agent via stdio JSON-RPC.
func (c *Client) Connect(ctx context.Context, agentCmd string, agentArgs ...string) error

// SharedIndexer converts ACP SessionUpdate events into protocol.SessionEntry rows.
type SharedIndexer struct{}

// Index converts a batch of session updates into indexed entries.
func (idx *SharedIndexer) Index(updates []acpsdk.SessionUpdate) ([]protocol.SessionEntry, error)

// Adapter converts agent-specific transcript formats into ACP SessionUpdate events.
// Implementations are registered by format name for extensibility.
type Adapter interface {
    // Parse converts one record from the agent's native format into a SessionUpdate.
    Parse(record []byte) (acpsdk.SessionUpdate, error)

    // Format returns the adapter's format identifier (e.g., "claude-jsonl", "opencode-json").
    Format() string
}

// RegisterAdapter registers an Adapter by its Format() name.
func RegisterAdapter(a Adapter)

// GetAdapter returns the registered Adapter for the given format, or an error.
func GetAdapter(format string) (Adapter, error)
```

### internal/release — Version Management

```go
package release

import "github.com/dayvidpham/pasture/internal/types"

// VersionFile is the interface for files containing semver strings.
type VersionFile interface {
    Name() string
    Path() string
    Read() (string, error)
    Write(version string, dryRun bool) error
}

// SemVer represents a semantic version.
type SemVer struct {
    Major int
    Minor int
    Patch int
}

func ParseSemVer(s string) (SemVer, error)
func (v SemVer) Bump(kind types.BumpKind) SemVer
func (v SemVer) String() string

// PluginRegistry manages plugin entries across marketplaces.
type PluginRegistry struct {
    Marketplaces []MarketplaceEntry
}

func (r *PluginRegistry) Load(path string) error
func (r *PluginRegistry) Save(path string, dryRun bool) error
func (r *PluginRegistry) FindPlugin(name string, cwd string) (*PluginEntry, *MarketplaceEntry)

// Exec runs a command in each registered repo's directory.
// MVP: lives on PluginRegistry for simplicity.
// Refactor target: extract to RegistryRunner when concerns grow.
func (r *PluginRegistry) Exec(cmd string, args ...string) error

// SyncVersions ensures all marketplace version references are consistent.
func (r *PluginRegistry) SyncVersions(dryRun bool) error

// ReleaseOrder returns plugins in topological dependency order for release.
func (r *PluginRegistry) ReleaseOrder() ([]PluginEntry, error)

// DiscoverVersionFiles finds all version-bearing files under root.
func DiscoverVersionFiles(root string) ([]VersionFile, error)
```

### skills/install-cli — /pasture:install-cli Skill

```markdown
# /pasture:install-cli

Claude Code skill for automated Pasture binary installation.

## Behavior
1. Detect OS (linux/darwin) and architecture (amd64/arm64) via `uname -s` and `uname -m`
2. Resolve latest release tag from GitHub API: `gh api repos/dayvidpham/pasture/releases/latest`
3. Download platform-appropriate static binary from GitHub Releases
4. Install to user-local bin (e.g., ~/.local/bin/ or ~/go/bin/)
5. Verify binary: `pastured --version`

## Platforms
| OS | Arch | Binary suffix |
|----|------|---------------|
| linux | x86_64 | linux-amd64 |
| linux | aarch64 | linux-arm64 |
| darwin | x86_64 | darwin-amd64 |
| darwin | arm64 | darwin-arm64 |

## Fallback
If GitHub Releases are unavailable, suggest: `go install github.com/dayvidpham/pasture/cmd/pastured@latest`
```

## Implementation Slices

| Slice | Scope | Dependencies | Estimated Size |
|-------|-------|-------------|----------------|
| S1: Project scaffold | go.mod, flake.nix, Makefile, cmd/ stubs, CI skeleton | None | Small |
| S2: Types + constants | pkg/protocol/, internal/types/, internal/temporal/constants.go | S1 | Small |
| S3: Config + errors | internal/config/, internal/errors/ | S1 | Small |
| S4: Formatters + hooks | internal/formatters/, internal/hooks/ | S2, S3 | Small |
| S5: Handlers + pasture-msg | internal/handlers/, cmd/pasture-msg/ | S2, S3, S4 | Medium |
| S6: Temporal workflows | internal/temporal/workflow*.go, state_machine.go, activities.go | S2 | Large |
| S7: Audit trail | internal/audit/ | S2, S6 | Medium |
| S8: pastured daemon | cmd/pastured/ | S3, S6, S7 | Medium |
| S9: ACP types + indexer + adapters | internal/acp/indexer.go, adapter_claude.go, adapter_opencode.go | S2 | Medium |
| S10: ACP live client | internal/acp/client.go | S9 | Medium |
| S11: pasture-release | internal/release/, cmd/pasture-release/ | S1 | Large |
| S12: Distribution + install-cli | flake.nix (buildGoModule), .github/workflows/release.yml, skills/install-cli/, Makefile targets | S5, S8, S11 | Small |

**Wave schedule:**
- Wave 1: S1, S2, S3 (foundation — parallel)
- Wave 2: S4, S5, S6, S7 (core — parallel, depends on Wave 1)
- Wave 3: S8, S9, S10 (integration — parallel, depends on Wave 2)
- Wave 3.5: S11 (pasture-release — can start after Wave 1, runs parallel with Waves 2-3)
- Wave 4: S12 (distribution — depends on S5, S8, S11; must wait for Waves 2-3 and S11)

Note: S11 (pasture-release) is independent of Waves 2-3 and can run in parallel. S12 (Distribution) depends on S5 and S8 from Waves 2-3, so it must wait until those complete.

## Validation Checklist

- [ ] `go build ./cmd/pastured && go build ./cmd/pasture-msg && go build ./cmd/pasture-release` succeeds
- [ ] `CGO_ENABLED=0 go build ./...` succeeds (pure Go, no CGo deps)
- [ ] `go test ./...` passes with coverage thresholds met (see Coverage Thresholds below)
- [ ] pastured connects to Temporal, registers all workflows/activities, handles SIGINT gracefully
- [ ] pasture-msg all 8 subcommands work against a running pastured
- [ ] Signal/query names match between pastured and pasture-msg (shared constants)
- [ ] Config resolution: CLI > env > YAML > defaults (Viper chain, exercised in test)
- [ ] Structured errors print actionable what/why/impact/fix to stderr
- [ ] JSON and text output formats match Python output for all formatters
- [ ] ACP client connects to a Claude Code agent via `claude-agent-acp` adapter
- [ ] SharedIndexer converts SessionUpdate → SessionEntry correctly
- [ ] ACP adapters (Claude JSONL, OpenCode JSON) produce valid SessionUpdate events
- [ ] pasture-release discovers version files, bumps, generates changelog, commits, tags
- [ ] pasture-release registry exec runs command across all registered repos
- [ ] pasture-release registry sync-versions detects and fixes version drift
- [ ] pasture-release registry release-order returns topological sort
- [ ] Nix flake builds all 3 binaries
- [ ] GitHub Actions produces static binaries for 4 platforms
- [ ] `go install github.com/dayvidpham/pasture/cmd/pastured@latest` works
- [ ] /pasture:install-cli skill detects OS/arch and fetches correct binary

### Coverage Thresholds

| Package | Minimum Coverage |
|---------|-----------------|
| internal/handlers | 80% |
| internal/formatters | 80% |
| internal/config | 80% |
| internal/types (IsValid/Parse functions) | 90% |
| internal/temporal | 70% |
| internal/audit | 75% |
| internal/acp | 70% |
| internal/errors | 90% |
| internal/hooks | 80% |
| internal/release | 75% |
| pkg/protocol | 90% |

## BDD Acceptance Criteria

### pastured

**Given** a running Temporal server **when** `pastured --namespace test --task-queue pasture` is started **then** it registers EpochWorkflow, SliceWorkflow, ReviewPhaseWorkflow and 4 activities, auto-registers 6 search attributes, and blocks until SIGINT **should not** exit on transient connection errors.

**Given** pastured is running **when** a client sends `advance_phase` signal with invalid phase **then** check_constraints activity returns constraint violations **should not** advance the phase.

**Given** pastured with `--audit-trail sqlite --audit-db-path /tmp/test.db` **when** a phase transition occurs **then** an AuditEvent is persisted to SQLite with correct epoch_id, phase, event_type, timestamp. **When** pastured is killed (SIGKILL) and restarted with the same db path **then** all previously recorded events are queryable via QueryEvents **should not** lose events across process restarts.

### pasture-msg — All 8 Subcommands

**Exit code contract:**

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | Validation error (bad input) |
| 2 | Connection error |
| 3 | Workflow/application error |

**Given** a running pastured **when** `pasture-msg epoch start --epoch-id E1` is run **then** it starts an EpochWorkflow with id E1, prints workflow ID and run ID in the requested format, exits 0 **should not** start a duplicate workflow (exits 3 with StructuredError category=workflow).

**Given** a running epoch E1 **when** `pasture-msg epoch cancel --epoch-id E1` is run **then** it sends a cancellation request to the workflow, prints confirmation, exits 0 **should not** crash if the workflow is already cancelled (exits 3 with descriptive error).

**Given** a running epoch E1 **when** `pasture-msg epoch terminate --epoch-id E1 --reason "test"` is run **then** it immediately terminates the workflow with the given reason, prints confirmation, exits 0 **should not** leave the workflow in an inconsistent state.

**Given** a running epoch E1 in p4_review **when** `pasture-msg signal vote --epoch-id E1 --axis Correctness --vote Accept --reviewer-id R1` is run **then** it sends a ReviewVoteSignal with the correct axis, vote type, and reviewer ID, exits 0 **should not** accept an invalid axis name (exits 1 with category=validation).

**Given** a running epoch E1 in p9_slice **when** `pasture-msg signal complete --epoch-id E1 --slice-id S1` is run **then** it sends a slice completion signal with nil output and nil errMsg, exits 0 **should not** require output or errMsg flags (they are optional).

**Given** a running epoch E1 **when** `pasture-msg phase advance --epoch-id E1 --to-phase p2_elicit --triggered-by architect --condition "classification confirmed"` is run **then** it sends a PhaseAdvanceSignal, exits 0 **should not** accept an invalid phase string (exits 1 with category=validation, fix text listing valid phases).

**Given** a running epoch E1 **when** `pasture-msg session register --epoch-id E1 --session-id S1 --role supervisor --model-harness claude-code --model opus-4` is run **then** it sends a session registration signal, exits 0 **should not** accept empty session-id or role (exits 1).

**Given** a running epoch E1 **when** `pasture-msg query state --epoch-id E1 --format json` is run **then** it returns JSON with current_phase, completed_phases, votes, active_slices **should not** crash on workflows in terminal state (returns last known state).

**Given** no Temporal server running **when** any pasture-msg command is run **then** it prints a StructuredError with category=connection, what="cannot connect to Temporal", fix="ensure Temporal server is running at <address>", and exits 2 **should not** print a raw stack trace.

### Config Resolution

**Given** a YAML config file at `~/.config/pasture/config.yaml` with `namespace: yaml-ns` **and** environment variable `TEMPORAL_NAMESPACE=env-ns` **and** CLI flag `--namespace cli-ns` **when** config is resolved **then** the effective namespace is `cli-ns` (CLI wins). **When** the CLI flag is omitted **then** the effective namespace is `env-ns` (env wins over YAML). **When** both CLI and env are omitted **then** the effective namespace is `yaml-ns` (YAML wins over default). **When** all three are omitted **then** the effective namespace is `default` (Viper default) **should not** silently ignore any config source.

### ACP Client

**Given** a Claude Code session via `claude-agent-acp` **when** the ACP client connects **then** it receives SessionUpdate notifications and converts them to SessionEntry rows via SharedIndexer. **When** processing 1000 updates in sequence **then** all 1000 are indexed with no dropped entries **should not** silently drop updates.

**Given** an ACP agent that sends ToolCallUpdate **when** the SharedIndexer processes it **then** the resulting SessionEntry has correct ToolKind, ToolCallID, ToolInput, ToolOutput fields populated **should not** leave ToolKind as nil when the ACP update provides it.

**Given** an ACP agent session that terminates **when** HandleSessionEnd is called with a StopReason **then** the handler records the final session state (reason, timestamp, total updates received) **should not** panic or leak goroutines on session termination.

### ACP Adapters

**Given** a registered Claude JSONL adapter **when** Parse is called with a transcript line containing an assistant message with tool use **then** the resulting SessionUpdate has ContentBlock with correct role, ToolCallID, and content **should not** produce an empty ContentBlock for valid JSONL input.

**Given** a registered OpenCode JSON adapter **when** Parse is called with a session record containing a completed tool call **then** the resulting SessionUpdate has ToolCallUpdate with ToolKind, ToolInput, and ToolOutput populated **should not** silently discard fields that are present in the input.

**Given** malformed input (invalid JSON, missing required fields) **when** any adapter's Parse is called **then** it returns a descriptive error with the byte offset or line number of the failure **should not** panic on malformed input.

**Given** an unregistered format name **when** GetAdapter is called **then** it returns an error listing available formats **should not** return nil without an error.

### pasture-release

**Given** a repo with pyproject.toml, plugin.json, and marketplace.json **when** `pasture-release patch` is run **then** all version files are bumped consistently, changelog is generated, git commit and tag are created **should not** leave version drift.

**Given** a plugin registry with 3 repos **when** `pasture-release registry exec "git status"` is run **then** git status is executed in each registered repo's directory and output is displayed per-repo **should not** fail silently if a repo path doesn't exist (prints StructuredError with fix text).

**Given** a plugin registry where repo A is at v1.2.0 and repo B references A at v1.1.0 **when** `pasture-release registry sync-versions` is run **then** repo B's reference is updated to v1.2.0 **should not** downgrade any version reference.

**Given** a plugin registry with dependency chain A→B→C **when** `pasture-release registry release-order` is run **then** it returns [C, B, A] (leaves first) **should not** produce a cycle or duplicate entry.

### Hooks

**Given** a HookManager with a handler registered for HookPhaseTransition **when** Dispatch is called with a HookPhaseTransition payload **then** the handler's Handle method is called with the correct payload **should not** block the caller if the handler is slow (non-blocking contract).

**Given** a HookManager with no handlers registered for HookVoteRecorded **when** Dispatch is called with a HookVoteRecorded payload **then** no error is returned and no handler is invoked **should not** panic on unsubscribed events.

### Distribution

**Given** the pasture repo **when** `nix build .#pastured` is run **then** a static binary is produced **should not** require CGo or external C libraries.

**Given** a GitHub release tag **when** CI runs **then** 4 static binaries (linux-x86_64, linux-aarch64, darwin-x86_64, darwin-arm64) are uploaded as release assets **should not** require manual binary building.

**Given** a user running `/pasture:install-cli` in Claude Code **when** the skill detects linux/amd64 **then** it downloads the `pasture-linux-amd64` binary from the latest GitHub release, installs to ~/.local/bin/, and verifies with `pastured --version` **should not** fail if `go` is not installed (binary is self-contained).

## Key Risk Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Signal/query name drift | High | Shared constants in internal/temporal/constants.go. Compile-time enforcement. |
| ACP SDK breaking changes | Medium | Pin acp-go-sdk version in go.mod. Zero transitive deps means low blast radius. |
| Type divergence with agent-data-leverage | Medium | Public types in pkg/protocol/ with same JSON tags and naming. Plan convergence after MVP. |
| Temporal Go SDK differences from Python | Medium | Reference temporalio/samples-go and temporalio/cli for idiomatic patterns. |
| modernc.org/sqlite performance vs CGo | Low | Benchmarked to be within 10-20% of CGo sqlite3 for typical workloads. Audit trail is low-volume. |
| PhaseId type confusion | Medium | Canonical in pkg/protocol/, type alias in internal/types. Single source of truth, no conversion needed. |
| Hook handler blocking | Medium | HookHandler.Handle contract requires non-blocking. Manager.Dispatch runs handlers concurrently with context timeout. |
