# Golang Port Research: aura-msg + aurad

**Date:** 2026-03-09
**Scope:** Domain research for porting `bin/aura-msg` and `bin/aurad.py` from Python to Go.

---

## 1. Go CLI Frameworks

### Requirements from Current Python Code

The Python `aura-msg` uses argparse with a two-level subcommand pattern:
- `aura-msg <group> <subcommand> [flags]`
- Groups: `query`, `epoch`, `signal`, `phase`, `session`
- Subcommands: `state`, `start`, `cancel`, `terminate`, `vote`, `complete`, `advance`, `register`

This is a **group/subcommand** pattern (not flat subcommands), requiring two levels of nesting.

### Framework Comparison

| Criterion | Cobra | urfave/cli | Kong |
|-----------|-------|------------|------|
| Nested subcommands | Native, arbitrarily deep | Supported but reported issues with global flags at depth | Native via struct nesting |
| Flag inheritance | Parent flags inherited by children | Global flags can collide with subcommand flags | Struct embedding handles this cleanly |
| Help generation | Automatic, customizable | Automatic | Automatic from struct tags |
| Testability | Commands are structs with RunE funcs | App.Run accepts argv | kong.Parse accepts argv; struct is the test fixture |
| Code generation | `cobra-cli` scaffolding tool | None | None (struct *is* the schema) |
| Viper integration | First-class (same author) | Manual | Manual |
| Ecosystem size | Largest (kubectl, gh, docker) | Second largest | Smaller but growing |
| Maintenance | Active, well-maintained | Active (v3 in development) | Active, single maintainer |

### Recommendation: **Cobra**

**Rationale:**
- The two-level group/subcommand pattern (`aura-msg epoch start`) maps directly to Cobra's `rootCmd.AddCommand(epochCmd)` + `epochCmd.AddCommand(startCmd)` pattern.
- First-class Viper integration solves the config resolution chain (CLI > env > YAML > defaults) with minimal glue code.
- The `RunE` pattern (returning `error`) maps well to the existing exit-code-based error handling.
- Largest ecosystem means most documentation, examples, and community support.
- Used by Temporal's own CLI (`tctl` / `temporal`), so patterns are familiar to the Temporal ecosystem.

**Kong as alternative:** If the team prefers declarative struct-based CLI definition, Kong is a strong second choice. The entire CLI structure would be a single Go struct with tags, which is extremely readable and testable. However, it lacks Viper integration, so config resolution would need manual wiring.

### Sources
- [Go CLI Comparison (GitHub)](https://github.com/gschauer/go-cli-comparison)
- [Kong README](https://github.com/alecthomas/kong)
- [Cobra: Building Multi-Level CLIs in Go](https://dev.to/frasnym/getting-started-with-cobra-creating-multi-level-command-line-interfaces-in-golang-2j3k)
- [Building Deep Nested CLI with Cobra](https://dev.to/frasnym/building-a-deep-nested-cli-application-with-cobra-in-golang-55hj)
- [Matt Turner: Choosing a Go CLI Library](https://mt165.co.uk/blog/golang-cli-library/)

---

## 2. Temporal Go SDK

### Key Differences from Python SDK

| Aspect | Python SDK | Go SDK |
|--------|-----------|--------|
| Workflow definition | `@workflow.defn` class with `@workflow.run` method | Plain function `func MyWorkflow(ctx workflow.Context, input MyInput) error` |
| Activity definition | `@activity.defn` decorated function | Plain function registered on worker |
| Signal handling | `@workflow.signal` method decorator | `workflow.GetSignalChannel(ctx, "signalName")` + `Receive()` |
| Query handling | `@workflow.query` method decorator | `workflow.SetQueryHandler(ctx, "queryName", handlerFunc)` |
| Worker registration | `Worker(client, task_queue, workflows=[...], activities=[...])` | `w := worker.New(c, taskQueue, opts)` then `w.RegisterWorkflow(fn)` / `w.RegisterActivity(fn)` |
| Async model | `asyncio` / `await` | Goroutines / channels (native concurrency) |
| Search attributes | `SearchAttributeKey` typed API | `temporal.NewSearchAttributes()` typed API |
| Client connect | `await Client.connect(addr, namespace=ns)` | `client.Dial(client.Options{HostPort: addr, Namespace: ns})` |
| Signal from client | `await handle.signal(WorkflowClass.signal_method, payload)` | `c.SignalWorkflow(ctx, workflowID, runID, signalName, payload)` |
| Query from client | `await handle.query(WorkflowClass.query_method)` | `resp, err := c.QueryWorkflow(ctx, workflowID, runID, queryName)` |
| Cancel from client | `await handle.cancel()` | `c.CancelWorkflow(ctx, workflowID, runID)` |
| Terminate from client | `await handle.terminate(reason=r)` | `c.TerminateWorkflow(ctx, workflowID, runID, reason)` |
| Start workflow | `await client.start_workflow(WF.run, input, id=id, task_queue=tq)` | `c.ExecuteWorkflow(ctx, opts, workflowFn, input)` |

### Migration Notes

1. **No decorator magic:** Go workflows/activities are plain functions. Registration is explicit via `worker.RegisterWorkflow()` and `worker.RegisterActivity()`.
2. **Signal channels vs decorators:** Python uses `@workflow.signal` which auto-wires a method as a signal handler. Go requires explicit `workflow.GetSignalChannel(ctx, name)` calls and manual `Receive()` loops, typically inside a `workflow.Go()` goroutine or a `Selector`.
3. **Query handlers:** In Go, call `workflow.SetQueryHandler(ctx, "queryName", func() (Result, error) { ... })` at workflow start. The handler function must return two values: a serializable result and an error.
4. **Typed search attributes:** Both SDKs now support typed search attributes. Go uses `temporal.NewSearchAttributes(temporal.NewSearchAttributeKeyKeyword("key").ValueSet("val"))`.
5. **Error model:** Go SDK uses `temporal.NewApplicationError()` for workflow failures, vs Python's `ApplicationError`. Go's `error` interface integrates naturally.

### Sources
- [Temporal Go SDK: Workflow Message Passing](https://docs.temporal.io/develop/go/message-passing)
- [Temporal Go SDK: Core Application](https://docs.temporal.io/develop/go/core-application)
- [Temporal Go SDK: client package](https://pkg.go.dev/go.temporal.io/sdk/client)
- [Temporal Go SDK: worker package](https://pkg.go.dev/go.temporal.io/sdk/worker)
- [Temporal Go SDK: workflow package](https://pkg.go.dev/go.temporal.io/sdk/workflow)
- [Temporal samples-go](https://github.com/temporalio/samples-go)

---

## 3. Command Pattern in Go

### Current Python Pattern

The Python `aura-msg` uses a dispatch dict mapping `(CmdGroup, SubCommand)` tuples to async handler functions:

```python
dispatch = {
    (CmdGroup.Query, SubCommand.State): _cmd_query_state,
    (CmdGroup.Signal, SubCommand.Vote): _cmd_signal_vote,
    ...
}
key = (CmdGroup(args.group), SubCommand(args.subcommand))
handler = dispatch.get(key)
sys.exit(asyncio.run(handler(args, config, fmt)))
```

### Go Command Pattern Design

**Option A: Cobra RunE (recommended for initial port)**

Each subcommand gets a `RunE` function that receives parsed flags and returns an error. Cobra handles dispatch automatically. This is the simplest mapping from the current Python code.

```go
// cmd/auramsg/epoch.go
var epochStartCmd = &cobra.Command{
    Use:   "start",
    Short: "Start a new epoch",
    RunE: func(cmd *cobra.Command, args []string) error {
        epochID, _ := cmd.Flags().GetString("epoch-id")
        // ... handler logic
    },
}

func init() {
    epochCmd.AddCommand(epochStartCmd)
    epochStartCmd.Flags().String("epoch-id", "", "Epoch ID")
    epochStartCmd.MarkFlagRequired("epoch-id")
}
```

**Option B: Command interface (for future extensibility)**

If the user anticipates "more commands and flags eventually" and wants a formal Command pattern:

```go
// internal/command/command.go
type Command interface {
    Execute(ctx context.Context, cfg *config.Config, fmt OutputFormat) (int, error)
}

// Each handler implements Command
type QueryStateCmd struct {
    EpochID string
}

func (c *QueryStateCmd) Execute(ctx context.Context, cfg *config.Config, fmt OutputFormat) (int, error) {
    // ... implementation
}
```

The Cobra `RunE` functions would construct the appropriate Command struct and call `Execute()`. This separates CLI parsing from business logic, making handlers independently testable.

**Option C: Hybrid (recommended for the "may need to refactor" case)**

Start with Cobra RunE for dispatch, but extract handler logic into standalone functions with explicit parameters (no cobra.Command dependency). This is essentially what the Python code does with `_cmd_query_state(args, config, fmt)`.

```go
// internal/handlers/query.go
func QueryState(ctx context.Context, conn *config.ConnectionConfig, epochID string, fmt OutputFormat) (int, error) {
    // ... pure business logic, no CLI framework dependency
}
```

### Recommendation

Start with **Option C** (hybrid). The Cobra `RunE` functions handle flag extraction and call standalone handler functions. This gives:
- Zero-cost migration path from current Python handlers
- Testable handlers without Cobra dependency
- Easy refactor to full Command interface later if needed

### Sources
- [Command Pattern in Go (refactoring.guru)](https://refactoring.guru/design-patterns/command/go/example)
- [Command Pattern in Go (Soham Kamani)](https://www.sohamkamani.com/golang/command-pattern/)
- [Writing Go CLIs With Just Enough Architecture](https://blog.carlana.net/post/2020/go-cli-how-to-and-advice/)
- [Command Design Pattern in Go (DEV)](https://dev.to/tomassirio/command-design-pattern-in-go-3lpl)

---

## 4. Config Resolution in Go

### Current Python Pattern

Priority chain: CLI > env > YAML > defaults. Implemented via `resolve_connection()` with explicit DI of `cli_args`, `env_dict`, `yaml_section` dicts.

### Viper (Recommended)

Viper natively supports the exact priority chain needed:

1. `viper.Set()` / CLI flags (via `cmd.Flags()` bound to Viper)
2. Environment variables (`viper.AutomaticEnv()` or `viper.BindEnv()`)
3. Config file (YAML via `viper.SetConfigFile()`)
4. Defaults (`viper.SetDefault()`)

**Mapping to current config:**

```go
// Defaults
viper.SetDefault("namespace", "default")
viper.SetDefault("task_queue", "aura")
viper.SetDefault("server_address", "localhost:7233")

// Env vars
viper.BindEnv("namespace", "TEMPORAL_NAMESPACE")
viper.BindEnv("task_queue", "TEMPORAL_TASK_QUEUE")
viper.BindEnv("server_address", "TEMPORAL_ADDRESS")

// YAML config file
viper.SetConfigFile(configPath)
viper.ReadInConfig() // silent fail if missing

// CLI flags (bound via Cobra)
viper.BindPFlag("namespace", cmd.Flags().Lookup("namespace"))
```

**Frozen config structs:** Use `viper.Unmarshal(&config)` into Go structs. Go structs are value types and can be made effectively immutable by not exporting fields + providing only getter methods, or simply by convention.

### Alternative: Manual Resolution

The current Python pattern is simple enough (~20 lines) that it could be ported directly without Viper. A manual `resolve()` function with explicit priority checking is more transparent and has zero dependencies.

### Recommendation

**Use Viper** for `aurad` (more config knobs: audit_trail, audit_db_path, connection params). For `aura-msg`, Viper is also appropriate since it shares the same config file and connection resolution logic.

### Sources
- [Viper (GitHub)](https://github.com/spf13/viper)
- [Guide to Configuration Management in Go with Viper](https://dev.to/kittipat1413/a-guide-to-configuration-management-in-go-with-viper-5271)
- [Go Configuration Mastery: Production Patterns with Viper](https://backendbytes.com/articles/go-configuration-viper-patterns/)
- [How to Build a CLI Tool in Go with Cobra and Viper](https://www.buanacoding.com/2025/10/how-to-build-a-cli-tool-in-go-with-cobra-and-viper.html)

---

## 5. Structured Error Reporting in Go

### Current Python Pattern

```python
class ErrorCategory(StrEnum):
    Connection = "connection error"
    Workflow = "workflow error"
    Validation = "validation error"

def report_error(category, *, what, why, impact, fix):
    print(f"{category}: {what}", file=sys.stderr)
    print(f"  why: {why}", file=sys.stderr)
    print(f"  impact: {impact}", file=sys.stderr)
    print(f"  fix: {fix}", file=sys.stderr)
```

### Go Equivalent

**Custom error type with structured fields:**

```go
// internal/errors/errors.go
type Category string

const (
    CategoryConnection Category = "connection error"
    CategoryWorkflow   Category = "workflow error"
    CategoryValidation Category = "validation error"
)

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

func (e *StructuredError) Report(w io.Writer) {
    fmt.Fprintf(w, "%s: %s\n", e.Category, e.What)
    fmt.Fprintf(w, "  why: %s\n", e.Why)
    fmt.Fprintf(w, "  impact: %s\n", e.Impact)
    fmt.Fprintf(w, "  fix: %s\n", e.Fix)
}
```

**Advantages over Python version:**
- Implements `error` interface, so it can be returned from functions and checked with `errors.As()`.
- The `Report()` method takes an `io.Writer` for testability (not hardcoded to stderr).
- `errors.As(&target)` allows callers to extract the structured fields for programmatic handling.

### Sources
- [Structured Errors in Go](https://southcla.ws/structured-errors-in-go)
- [Custom Errors in Go: A Practical Guide](https://leapcell.io/blog/custom-errors-in-go-a-practical-guide)
- [Go by Example: Custom Errors](https://gobyexample.com/custom-errors)
- [Popular Error Handling Techniques in Go (JetBrains)](https://www.jetbrains.com/guide/go/tutorials/handle_errors_in_go/error_technique/)

---

## 6. Output Formatting in Go

### Current Python Pattern

`OutputFormat` enum (`Json`/`Text`) passed to formatter functions that switch on format and return strings.

### Go Equivalent

```go
type OutputFormat string

const (
    FormatJSON OutputFormat = "json"
    FormatText OutputFormat = "text"
)

// Pattern: format functions take OutputFormat and return string
func FormatSignalResult(success bool, fmt OutputFormat) string {
    switch fmt {
    case FormatJSON:
        data, _ := json.Marshal(map[string]bool{"success": success})
        return string(data)
    default:
        if success {
            return "Signal delivered successfully"
        }
        return "Signal delivery failed"
    }
}
```

**JSON output:** Use `encoding/json` with `json.MarshalIndent(data, "", "  ")` for pretty-printed JSON (matches current Python `indent=2`).

**Text output:** Use `fmt.Sprintf` or `strings.Builder` for line-based text output.

**Template-based (future):** If more output formats are needed later (e.g., table, YAML), consider a `Formatter` interface:

```go
type Formatter interface {
    FormatEpochState(result *QueryStateResult) string
    FormatStartResult(workflowID, runID string) string
    FormatSignalResult(success bool) string
}
```

This would allow adding new formats without modifying existing formatters.

### Sources
- [Go by Example: JSON](https://gobyexample.com/json)
- [GitHub CLI formatting docs](https://cli.github.com/manual/gh_help_formatting)

---

## 7. Go Project Structure

### Recommended Layout

```
aura-protocol-go/
  cmd/
    aura-msg/
      main.go              # Minimal: cobra root command + os.Exit
    aurad/
      main.go              # Minimal: config parse + worker start
  internal/
    config/
      config.go            # ConnectionConfig, AuradConfig, AuraMsgConfig
      resolve.go           # Priority chain resolution (or Viper wiring)
    errors/
      errors.go            # StructuredError, ErrorCategory, Report()
    handlers/
      query.go             # QueryState handler
      epoch.go             # EpochStart, EpochCancel, EpochTerminate
      signal.go            # SignalVote, SignalComplete
      phase.go             # PhaseAdvance
      session.go           # SessionRegister
    formatters/
      formatters.go        # FormatEpochState, FormatStartResult, FormatSignalResult
    types/
      types.go             # CmdGroup, SubCommand, OutputFormat, VoteType, etc.
    temporal/
      workflow.go          # EpochWorkflow, SliceWorkflow, ReviewPhaseWorkflow
      activities.go        # check_constraints, record_transition, etc.
      signals.go           # Signal/query type definitions
  go.mod
  go.sum
```

**Key principles:**
- `cmd/` contains only `main.go` files with minimal wiring code.
- `internal/` prevents external import of implementation details.
- `handlers/` contains pure business logic functions (no Cobra dependency).
- `temporal/` isolates all Temporal SDK types and workflow definitions.
- Two separate binaries (`aura-msg` and `aurad`) share code via `internal/`.

### Sources
- [golang-standards/project-layout](https://github.com/golang-standards/project-layout)
- [Organizing a Go Module (official docs)](https://go.dev/doc/modules/layout)
- [No Nonsense Guide to Go Package Layout](https://laurentsv.com/blog/2024/10/19/no-nonsense-go-package-layout.html)
- [Go Project Structure: Practices & Patterns](https://www.glukhov.org/post/2025/12/go-project-structure)

---

## 8. Prior Art

### Temporal's Own CLI

Temporal's official CLI tool (`temporal` command, formerly `tctl`) is written in Go and uses Cobra. It provides subcommands for workflow management, namespace operations, and cluster administration. This is the most direct prior art -- it wraps the Temporal Go SDK with a CLI interface for operations like starting, signaling, querying, and terminating workflows.

Repository: [temporalio/cli](https://github.com/temporalio/cli)

### temporalio/samples-go

The official Go samples repository includes examples of:
- Worker setup with `worker.New()`, `RegisterWorkflow()`, `RegisterActivity()`
- Signal and query handling patterns
- Search attribute usage
- Child workflow orchestration

Repository: [temporalio/samples-go](https://github.com/temporalio/samples-go)

### Key Takeaway

The `temporal` CLI itself is the best reference architecture. It demonstrates:
- Cobra command structure for Temporal operations
- Client connection management
- Signal/query dispatch from CLI to Temporal server
- Output formatting (JSON, text, table)

---

## Summary: Migration Mapping

| Python Component | Go Equivalent | Notes |
|-----------------|---------------|-------|
| `argparse` + subparsers | Cobra commands | Two-level nesting: root -> group -> subcommand |
| `resolve_*_config()` | Viper + Cobra flag binding | `viper.BindPFlag()` + `viper.BindEnv()` + `viper.SetDefault()` |
| `ErrorCategory` StrEnum | `Category` const string type | Go iota-based or string const |
| `report_error()` | `StructuredError.Report(io.Writer)` | Implements `error` interface for composability |
| `OutputFormat` StrEnum | `OutputFormat` string const | Switch-based formatting |
| `format_*()` functions | `Format*()` functions | Same pattern, `encoding/json` for JSON |
| `asyncio.run(handler(...))` | Direct function call (Go is not async) | No async runtime needed |
| `temporalio.client.Client.connect()` | `client.Dial(opts)` | Blocking, returns `(Client, error)` |
| `handle.signal(WF.method, payload)` | `c.SignalWorkflow(ctx, id, "", name, payload)` | String-based signal name |
| `handle.query(WF.method)` | `c.QueryWorkflow(ctx, id, "", name)` | Returns `converter.EncodedValue` |
| `Worker(client, tq, workflows, activities)` | `worker.New(c, tq, opts)` + `Register*()` | Explicit registration calls |
| `@workflow.defn` class | Plain function | No decorators in Go |
| `@workflow.signal` method | `workflow.GetSignalChannel()` + `Receive()` | Manual channel wiring |
| `@workflow.query` method | `workflow.SetQueryHandler()` | Called at workflow start |

### Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Signal/query name drift between Go client (aura-msg) and Go worker (aurad) | High | Define signal/query names as shared constants in `internal/temporal/signals.go` |
| Loss of type safety in signal dispatch (Python uses typed method refs) | Medium | Use typed signal/query wrappers or code generation |
| Config file format change breaking existing YAML configs | Low | Keep same YAML schema; Viper reads YAML natively |
| Two-binary build complexity | Low | Standard Go multi-binary pattern via `cmd/` |
| Temporal SDK version compatibility | Low | Pin SDK version in `go.mod`; Go module system handles this |
