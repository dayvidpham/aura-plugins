# PROPOSAL-1: Pasture — Go Port of aura-protocol with ACP + Observability

---
references:
  request: aura-plugins-pv2ek
  urd: aura-plugins-jbnx3
  elicit: aura-plugins-usz42
  research_golang: docs/research/golang-port.md
  research_acp: llm/research/agent-client-protocol-alignment.md
  research_xcompile: llm/research/static-cross-compilation-binary-distribution.md
  reference_repo: ~/dev/agent-data-leverage/develop
---

## Problem Space

Port Python aura-protocol (aurad + aura-msg + aura-release) to Go as the new **Pasture** project, integrating ACP (Agent Client Protocol) for live agent observability, and establishing a polyrepo marketplace for Claude Code plugins.

**Axes:**
- **Parallelism:** High — pastured handles concurrent workflows (EpochWorkflow, SliceWorkflow, ReviewPhaseWorkflow). ACP client handles concurrent agent sessions. pasture-release may operate across multiple repos.
- **Distribution:** Distributed — pastured ↔ Temporal server ↔ pasture-msg. ACP client ↔ running agents via JSON-RPC.
- **Scale:** Moderate — single-team usage initially, but types must be stable for convergence with agent-data-leverage analytics pipeline.
- **Has-a / Is-a:** Pasture *has-a* Temporal client, *has-a* ACP client, *has-a* audit trail. Pasture *is-a* multi-agent orchestration platform.

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
    types/
      enums.go                   # PhaseId, VoteType, ReviewAxis, Domain, RoleId, etc.
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
      adapter_claude.go          # Claude JSONL → []acp.SessionUpdate
      adapter_opencode.go        # OpenCode JSON → []acp.SessionUpdate
    release/
      version.go                 # SemVer, VersionFile interface, discovery
      changelog.go               # Conventional commit parsing, changelog generation
      registry.go                # PluginRegistry, PluginEntry, MarketplaceEntry
      git.go                     # Git helpers (status, tag, commit)
  pkg/
    protocol/
      types.go                   # Public convergence types (PhaseId, EventType, AuditEvent)
      session_entry.go           # SessionEntry (aligned with agent-data-leverage pkg/schema)
  flake.nix
  go.mod
  go.sum
  Makefile
  .github/
    workflows/
      release.yml                # Cross-platform build + GitHub Releases
```

## Public Interfaces

### pkg/protocol — Convergence Types

```go
package protocol

// PhaseId represents an epoch lifecycle phase.
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

type Category string

const (
    CategoryConnection Category = "connection error"
    CategoryWorkflow   Category = "workflow error"
    CategoryValidation Category = "validation error"
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

// ConnectionConfig holds Temporal connection parameters (frozen after resolution).
type ConnectionConfig struct {
    Namespace     string `yaml:"namespace" mapstructure:"namespace"`
    TaskQueue     string `yaml:"task_queue" mapstructure:"task_queue"`
    ServerAddress string `yaml:"server_address" mapstructure:"server_address"`
}

// PasturedConfig holds the full pastured daemon configuration.
type PasturedConfig struct {
    Connection  ConnectionConfig `yaml:"connection" mapstructure:"connection"`
    AuditTrail  string           `yaml:"audit_trail" mapstructure:"audit_trail"`   // "memory" | "sqlite"
    AuditDBPath string           `yaml:"audit_db_path" mapstructure:"audit_db_path"`
}

// PastureMsgConfig holds the pasture-msg CLI configuration.
type PastureMsgConfig struct {
    Connection    ConnectionConfig `yaml:"connection" mapstructure:"connection"`
    DefaultFormat string           `yaml:"default_format" mapstructure:"default_format"` // "json" | "text"
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
```

### internal/release — Version Management

```go
package release

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
func (v SemVer) Bump(kind string) SemVer  // "major" | "minor" | "patch"
func (v SemVer) String() string

// PluginRegistry manages plugin entries across marketplaces.
type PluginRegistry struct {
    Marketplaces []MarketplaceEntry
}

func (r *PluginRegistry) Load(path string) error
func (r *PluginRegistry) Save(path string, dryRun bool) error
func (r *PluginRegistry) FindPlugin(name string, cwd string) (*PluginEntry, *MarketplaceEntry)
func (r *PluginRegistry) Exec(cmd string, args ...string) error          // NEW: run across all repos
func (r *PluginRegistry) SyncVersions(dryRun bool) error                 // NEW: sync marketplace versions
func (r *PluginRegistry) ReleaseOrder() ([]PluginEntry, error)           // NEW: topological sort

// DiscoverVersionFiles finds all version-bearing files under root.
func DiscoverVersionFiles(root string) ([]VersionFile, error)
```

## Implementation Slices (Suggested)

| Slice | Scope | Dependencies | Estimated Size |
|-------|-------|-------------|----------------|
| S1: Project scaffold | go.mod, flake.nix, Makefile, cmd/ stubs, CI skeleton | None | Small |
| S2: Types + constants | pkg/protocol/, internal/types/, internal/temporal/constants.go | S1 | Small |
| S3: Config + errors | internal/config/, internal/errors/ | S1 | Small |
| S4: Formatters | internal/formatters/ | S2, S3 | Small |
| S5: Handlers + pasture-msg | internal/handlers/, cmd/pasture-msg/ | S2, S3, S4 | Medium |
| S6: Temporal workflows | internal/temporal/workflow*.go, state_machine.go, activities.go | S2 | Large |
| S7: Audit trail | internal/audit/ | S2, S6 | Medium |
| S8: pastured daemon | cmd/pastured/ | S3, S6, S7 | Medium |
| S9: ACP types + indexer | internal/acp/indexer.go, adapter_*.go | S2 | Medium |
| S10: ACP live client | internal/acp/client.go | S9 | Medium |
| S11: pasture-release | internal/release/, cmd/pasture-release/ | S1 | Large |
| S12: Distribution | flake.nix (buildGoModule), .github/workflows/release.yml, Makefile targets | S5, S8, S11 | Small |

**Wave schedule:**
- Wave 1: S1, S2, S3 (foundation — parallel)
- Wave 2: S4, S5, S6, S7 (core — parallel, depends on Wave 1)
- Wave 3: S8, S9, S10 (integration — parallel, depends on Wave 2)
- Wave 4: S11, S12 (release tooling + distribution — parallel, depends on Wave 1)

Note: Wave 4 can run in parallel with Waves 2-3 since pasture-release is independent.

## Validation Checklist

- [ ] `go build ./cmd/pastured && go build ./cmd/pasture-msg && go build ./cmd/pasture-release` succeeds
- [ ] `CGO_ENABLED=0 go build ./...` succeeds (pure Go, no CGo deps)
- [ ] `go test ./...` passes with >80% coverage on handlers, formatters, config, types
- [ ] pastured connects to Temporal, registers all workflows/activities, handles SIGINT gracefully
- [ ] pasture-msg all 8 subcommands work against a running pastured
- [ ] Signal/query names match between pastured and pasture-msg (shared constants)
- [ ] Config resolution: CLI > env > YAML > defaults (Viper chain)
- [ ] Structured errors print actionable what/why/impact/fix to stderr
- [ ] JSON and text output formats match Python output for all formatters
- [ ] ACP client connects to a Claude Code agent via `claude-agent-acp` adapter
- [ ] SharedIndexer converts SessionUpdate → SessionEntry correctly
- [ ] pasture-release discovers version files, bumps, generates changelog, commits, tags
- [ ] pasture-release registry exec runs command across all registered repos
- [ ] Nix flake builds all 3 binaries
- [ ] GitHub Actions produces static binaries for 4 platforms
- [ ] `go install github.com/dayvidpham/pasture/cmd/pastured@latest` works

## BDD Acceptance Criteria

### pastured

**Given** a running Temporal server **when** `pastured --namespace test --task-queue pasture` is started **then** it registers EpochWorkflow, SliceWorkflow, ReviewPhaseWorkflow and 4 activities, auto-registers 6 search attributes, and blocks until SIGINT **should not** exit on transient connection errors.

**Given** pastured is running **when** a client sends `advance_phase` signal with invalid phase **then** check_constraints activity returns constraint violations **should not** advance the phase.

**Given** pastured with `--audit-trail sqlite` **when** a phase transition occurs **then** an AuditEvent is persisted to SQLite with correct epoch_id, phase, event_type, timestamp **should not** lose events on process restart.

### pasture-msg

**Given** a running pastured **when** `pasture-msg epoch start --epoch-id E1` is run **then** it starts an EpochWorkflow with id E1, prints workflow ID and run ID, exits 0 **should not** start a duplicate workflow.

**Given** a running epoch **when** `pasture-msg query state --epoch-id E1 --format json` is run **then** it returns JSON with current_phase, completed_phases, votes **should not** crash on workflows in terminal state.

**Given** no Temporal server running **when** any pasture-msg command is run **then** it prints a StructuredError with category=connection, actionable fix text, and exits 2 **should not** print a raw stack trace.

### ACP Client

**Given** a Claude Code session via `claude-agent-acp` **when** the ACP client connects **then** it receives SessionUpdate notifications and converts them to SessionEntry rows via SharedIndexer **should not** drop updates during high throughput.

**Given** an ACP agent that sends ToolCallUpdate **when** the SharedIndexer processes it **then** the resulting SessionEntry has correct ToolKind, ToolCallID, ToolInput, ToolOutput fields populated **should not** leave ToolKind as nil when the ACP update provides it.

### pasture-release

**Given** a repo with pyproject.toml, plugin.json, and marketplace.json **when** `pasture-release patch` is run **then** all version files are bumped consistently, changelog is generated, git commit and tag are created **should not** leave version drift.

**Given** a plugin registry with 3 repos **when** `pasture-release registry exec "git status"` is run **then** git status is executed in each registered repo's directory **should not** fail silently if a repo path doesn't exist.

### Distribution

**Given** the pasture repo **when** `nix build .#pastured` is run **then** a static binary is produced **should not** require CGo or external C libraries.

**Given** a GitHub release tag **when** CI runs **then** 4 static binaries (linux-x86_64, linux-aarch64, darwin-x86_64, darwin-arm64) are uploaded as release assets **should not** require manual binary building.

## Key Risk Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Signal/query name drift | High | Shared constants in internal/temporal/constants.go. Compile-time enforcement. |
| ACP SDK breaking changes | Medium | Pin acp-go-sdk version in go.mod. Zero transitive deps means low blast radius. |
| Type divergence with agent-data-leverage | Medium | Public types in pkg/protocol/ with same JSON tags and naming. Plan convergence after MVP. |
| Temporal Go SDK differences from Python | Medium | Reference temporalio/samples-go and temporalio/cli for idiomatic patterns. |
| modernc.org/sqlite performance vs CGo | Low | Benchmarked to be within 10-20% of CGo sqlite3 for typical workloads. Audit trail is low-volume. |
