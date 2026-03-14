## Summary

Add protobuf serialization of world state time series for the analytics pipeline. A new `WorldStateRecorder` QObject connects to `AnalyticsCore::metricProcessed` via signal/slot and serializes each `WorldStateSchema` snapshot into a `proto::AnalyticsEntry`, base64-encodes it, and appends one line per entry to a `.pb64` file. This is the ingest layer that feeds match data to the LLM analytics demo.

Key components:
- **Proto schema extensions** — `FieldZone` enum, 5 new Robot fields (zone, acceleration, has_ball, velocity_angle, distance_with_ball), 3 new WorldState fields (friendly_robots, opponent_robots, friendly_team) for perspective-aware analysis while keeping blue/yellow compat
- **ProtobufSerializer namespace** — free functions (`serializeRobot`, `serializeBall`, `serializeWorldState`, `serializeEntry`) with field-zone and team-color mapping
- **WorldStateRecorder** — QObject that receives signals at 10 Hz, writes newline-delimited base64 protobuf to `{uuid}_{ISO-timestamp}.pb64`, flushes every `ANALYTICS_FLUSH_INTERVAL` entries, destructor flush for safety

## Architecture

### Signal Chain: Data Flow from World State to Disk

```
WorldStateManager (180 Hz)
  │
  │  updateInternalWorldState()
  ▼
AnalyticsCore (QObject)
  │  QTimer(100ms) → tick() → process()
  │
  │  emit metricProcessed(WorldStateSchema)    ←── 10 Hz
  │
  ▼
WorldStateRecorder (QObject)                   ←── NEW (this MR)
  │  onMetricProcessed() slot
  │
  ├── ProtobufSerializer::serializeEntry()     ←── NEW (this MR)
  │     ├── serializeWorldState()
  │     │     ├── serializeBall()
  │     │     └── serializeRobot() × N
  │     └── wrap in proto::AnalyticsEntry
  │
  ├── SerializeToString() → binary bytes
  ├── QByteArray::toBase64() → base64 string
  ├── QFile::write(base64 + "\n")
  │
  └── flush every ANALYTICS_FLUSH_INTERVAL (10) entries
        └── destructor flush for remaining buffered entries

  ▼
{uuid}_{ISO-timestamp}.pb64 file
  │  one base64-encoded proto::AnalyticsEntry per line
  ▼
[Future: LLM analytics consumer]
```

### Component Ownership

```
ServiceContainer (app init)
  │
  ├── AnalyticsCore (existing)
  │     ├── QTimer (100ms tick)
  │     ├── WorldStateSchema (internal state)
  │     └── signal: metricProcessed(WorldStateSchema)
  │
  └── WorldStateRecorder (NEW)
        ├── QFile m_file          ← {uuid}_{ISO-timestamp}.pb64
        ├── qint64 m_entryCount   ← tracks entries for periodic flush
        ├── QUuid m_sessionId     ← unique per session/match
        └── bool m_healthy        ← false on I/O failure → all writes become no-ops

QObject::connect(analyticsCore, &AnalyticsCore::metricProcessed,
                 recorder,      &WorldStateRecorder::onMetricProcessed);
```

### C++ Schema → Proto Message Mapping

```
WorldStateSchema                    proto::AnalyticsEntry
  │                                   │
  ├── capture_time ──────────────────→ timestamp
  │                                   │
  └── (all fields) ─── serializeWorldState() ──→ world_state (proto::WorldState)
        │                                          │
        ├── capture_time ─────────────────────────→ capture_time
        ├── idWithBall ───────────────────────────→ robot_id_with_ball
        ├── teamWithBall ─── mapTeam() ──────────→ team_with_ball
        ├── friendlyTeam ─── mapTeam() ──────────→ friendly_team
        │
        ├── ball (BallSchema) ─── serializeBall() ──→ ball (proto::Ball)
        │     ├── x,y,z ────────────────────────────→ pos (Vector3)
        │     ├── velocityX,Y,Z ────────────────────→ vel (Vector3)
        │     ├── speed2D ──────────────────────────→ speed_2d
        │     └── zone ─── mapFieldZone() ─────────→ zone (FieldZone)
        │
        ├── friendly.robots[] ─── serializeRobot() ──→ friendly_robots[] + blue/yellow_robots[]
        └── opponent.robots[] ─── serializeRobot() ──→ opponent_robots[] + blue/yellow_robots[]
              │
              RobotSchema                             proto::Robot
              ├── robotId ───────────────────────────→ id
              ├── x, y ─────────────────────────────→ pos (Vector2)
              ├── angle ────────────────────────────→ angle
              ├── velocityX, velocityY ─────────────→ vel_xy (Vector2)
              ├── speed ────────────────────────────→ speed
              ├── distanceToBall ───────────────────→ dist_to_ball
              ├── zone ─── mapFieldZone() ─────────→ zone (FieldZone)      ← NEW
              ├── acceleration ─────────────────────→ acceleration (Vector2) ← NEW
              ├── hasBall ──────────────────────────→ has_ball              ← NEW
              ├── velocityAngle ────────────────────→ velocity_angle        ← NEW
              └── distanceWithBall ─────────────────→ distance_with_ball    ← NEW
```

### FieldZone Enum Mapping (+1 offset)

```
C++ WorldStateEventHelper::FieldZone     proto::FieldZone
(0-based, no "unknown")                  (0-based with UNKNOWN sentinel)

                                         FIELD_ZONE_UNKNOWN = 0  ← fallback
NEGATIVE_GOAL_AREA = 0  ── (+1) ──────→ NEGATIVE_GOAL_AREA = 1
NEGATIVE_THIRD     = 1  ── (+1) ──────→ NEGATIVE_THIRD     = 2
MIDFIELD           = 2  ── (+1) ──────→ MIDFIELD           = 3
POSITIVE_THIRD     = 3  ── (+1) ──────→ POSITIVE_THIRD     = 4
POSITIVE_GOAL_AREA = 4  ── (+1) ──────→ POSITIVE_GOAL_AREA = 5
OUT_OF_BOUNDS      = 5  ── (+1) ──────→ OUT_OF_BOUNDS      = 6

mapFieldZone(): proto_value = static_cast<int>(cpp_zone) + 1
                if !FieldZone_IsValid(proto_value) → FIELD_ZONE_UNKNOWN
```

### Wire Format: .pb64 File Layout

```
File: a1b2c3d4-e5f6-7890-abcd-ef1234567890_2026-03-13T12:00:00Z.pb64
┌─────────────────────────────────────────────────────────────────┐
│ CgkJAAAAAAAA8D8SHQoNCQAAAAAAAPA/EQAAAAAAAPA/EgwJ...  (line 1)  │ ← base64(proto::AnalyticsEntry)
│ CgkJAAAAAAAACEASHQoNCQAAAAAAABBAEQAAAAAAABBA...      (line 2)  │ ← base64(proto::AnalyticsEntry)
│ CgkJAAAAAAAAIkASHQoNCQAAAAAAACRAEQAAAAAAACRA...      (line 3)  │ ← base64(proto::AnalyticsEntry)
│ ...                                                             │
│ (one entry per line, newline-delimited)                         │
└─────────────────────────────────────────────────────────────────┘

To read:  for each line → base64_decode → proto::AnalyticsEntry::ParseFromString
To debug: wc -l file.pb64        → entry count
          head -1 file.pb64      → first entry
          tail -f file.pb64      → live stream
```

### Error Handling Flow

```
onMetricProcessed(metric)
  │
  ├── !m_healthy? → return (no-op)
  │
  ├── try:
  │     ├── serializeEntry(metric)
  │     ├── SerializeToString(&bytes)
  │     │     └── FAIL? → qWarning with field dump:
  │     │                   capture_time, idWithBall, friendlyTeam,
  │     │                   robot counts, ball pos,
  │     │                   entry.DebugString()
  │     │                 → return (skip entry)
  │     ├── toBase64() → write(base64)
  │     │     └── FAIL? → qWarning + m_healthy=false (recorder disabled)
  │     ├── write("\n")
  │     │     └── FAIL? → qWarning + m_healthy=false
  │     └── ++m_entryCount; flush if % ANALYTICS_FLUSH_INTERVAL == 0
  │
  └── catch(std::exception):
        → qWarning + skip entry (recorder stays healthy)
```

## Testing
- [x] Created tests
- [x] Updated tests
- [ ] Tested in simulation (integration tests)
- [ ] Tested in real robot (if applicable)
- [ ] No tests (reason):

### How to run

```bash
# Full test suite
./build/test/unit_tests

# Serializer round-trip tests (8 tests, 54 asserts)
./build/test/unit_tests -n "ProtobufSerializer"

# Recorder tests (6 features, 29 asserts)
./build/test/unit_tests -n "WorldStateRecorder"
```

### Test coverage

**ProtobufSerializer (8 tests):**
- Robot round-trip: all 13 fields survive serialize/parse
- Ball round-trip: all 7 numeric fields + zone field
- WorldState round-trip: friendly/opponent split, ball, timestamps
- FieldZone mapping: all 6 enum values map correctly with +1 offset
- Team mapping: BLUE friendlyTeam → friendly_robots = blue_robots
- Team mapping: YELLOW friendlyTeam → friendly_robots = yellow_robots
- Empty WorldState: zero robots + nullopt possession → valid entry
- AnalyticsEntry wrapper: timestamp + world_state populated

**WorldStateRecorder (6 features):**
- File creation on construction with valid directory (.pb64 naming)
- Bad directory yields unhealthy recorder (no-op writes)
- Signal-to-file: N direct slot calls produce N base64 lines
- Round-trip: each base64 line decodes to valid proto::AnalyticsEntry
- entryCount tracks successful writes
- AnalyticsCore → WorldStateRecorder integration via QObject::connect (N ticks → N lines)

## Requirements

These requirements were gathered through a structured elicitation with the feature requester.

### R1: New Serializer Class
A new QObject class receives the `AnalyticsCore::metricProcessed(WorldStateSchema)` signal via Qt6 slot. On each invocation, it serializes the WorldStateSchema into a `proto::AnalyticsEntry` (WorldState fields only for MVP) and appends it to an open file.

### R2: Proto Schema Extensions
Extend `analytics_log.proto`:
- `proto::WorldState` gains: `friendly_robots` (repeated Robot), `opponent_robots` (repeated Robot), `friendly_team` (Team). Existing blue/yellow fields kept for backwards compat.
- `proto::Robot` gains: optional FieldZone zone, optional Vector2 acceleration, optional bool has_ball, optional float velocity_angle, optional float distance_with_ball.
- `proto::Ball` gains: optional FieldZone zone.

### R3: Wire Format — Newline-Delimited Base64
Each AnalyticsEntry is serialized to binary, base64-encoded, and written as one line (terminated by newline). Corruption-resilient: reader skips to next newline on parse failure.

### R4: Continuous Append on AnalyticsCore Tick
Serialization and file append happen only on AnalyticsCore tick (100ms / 10Hz). Not tied to WorldStateManager tick rate.

### R5: File Naming
Output files named with UUID + timestamp components: `{uuid}_{ISO-timestamp}.pb64`. UUID identifies the match/session.

### R6: Error Resilience
If serialization of a single entry fails, log a warning (qWarning) and skip that entry. Never crash or stop recording.

### Key User Decisions (from elicitation)
| Question | Decision | Rationale |
|----------|----------|-----------|
| Snapshot scope | WorldState only | Nav commands being deprecated; AnalyticsEntry will be cleaned up later |
| Time series lifecycle | Continuous append to file | Serialize + append on AnalyticsCore tick only |
| Team mapping | Extend proto with friendly/opponent | Perspective-aware analysis; keep blue/yellow for backwards compat |
| Derived fields (zone, accel, hasBall) | Include in proto | Already computed; avoids duplicating logic in consumers |
| Wire format | Newline-delimited base64 | Corruption recovery (skip to next newline), debuggability (`head`, `wc -l`, `tail -f`), negligible overhead at 10Hz |
| File naming | UUID + ISO timestamp | UUID identifies match/session |
| Error handling | Skip + log | qWarning on failure, never crash |

## Changes

### Proto schema (`analytics_log.proto`)
- Added `FieldZone` enum (UNKNOWN through OUT_OF_BOUNDS, 7 values)
- Extended `Robot` message with 5 optional fields (zone, acceleration, has_ball, velocity_angle, distance_with_ball)
- Extended `WorldState` message with 3 fields (friendly_robots, opponent_robots, friendly_team)
- Added `optional FieldZone zone = 4` to `Ball` message

### Serializer (`src/serialization/`)
- New `ProtobufSerializer` namespace with 4 free functions (matching existing `JsonSerializer` pattern)
- `mapFieldZone()` helper: C++ enum (0-based) → proto enum (1-based, +1 offset)
- `mapTeam()` helper: C++ `Team::BLUE/YELLOW` → `proto::BLUE/YELLOW`
- Linked to `skynet_proto` library via CMakeLists.txt

### Recorder (`src/analytics/`)
- New `WorldStateRecorder` QObject class
- Constructor validates output directory (exists + writable), opens file, sets `m_healthy`
- `onMetricProcessed` slot: serialize → base64 → append line → periodic flush
- Periodic flush every `SkynetConstants::ANALYTICS_FLUSH_INTERVAL` (10) entries instead of every write
- Destructor flush to prevent data loss when entry count < flush interval
- Diagnostic error messages: dumps WorldStateSchema field values + `entry.DebugString()` on SerializeToString failure

### Constants (`SkynetConstants.h`)
- Added `ANALYTICS_FLUSH_INTERVAL = 10` (co-located with `ANALYTICS_THROTTLE_MS` — flush cadence is ~1s at 100ms throttle)

### Public Interfaces

```cpp
// ProtobufSerializer (namespace, free functions)
namespace ProtobufSerializer {
  proto::Robot serializeRobot(const RobotSchema &rs);
  proto::Ball serializeBall(const BallSchema &bs);
  proto::WorldState serializeWorldState(const WorldStateSchema &wss);
  proto::AnalyticsEntry serializeEntry(const WorldStateSchema &wss);
}

// WorldStateRecorder (QObject)
class WorldStateRecorder : public QObject {
  Q_OBJECT
public:
  explicit WorldStateRecorder(const QString &outputDir, QObject *parent = nullptr);
  ~WorldStateRecorder();
  QString filePath() const;
  qint64 entryCount() const;
  bool isHealthy() const;
public slots:
  void onMetricProcessed(const WorldStateSchema &metric);
};

// Wiring (in main or app init)
auto recorder = new WorldStateRecorder(outputDir, &app);
QObject::connect(&analyticsCore, &AnalyticsCore::metricProcessed,
                 recorder, &WorldStateRecorder::onMetricProcessed);
```

## Blast Radius

- **Proto schema**: Additive only — new fields are `optional` or `repeated`, no existing field numbers changed. Fully backwards-compatible with existing proto consumers.
- **No existing behavior modified**: WorldStateRecorder is a new class; AnalyticsCore signal emission is unchanged. Recorder must be explicitly constructed and connected.
- **Build**: New sources added to `src/analytics/CMakeLists.txt` and `src/serialization/CMakeLists.txt`. Both link `skynet_proto` (already built by existing proto compilation).
- **File I/O**: Writes only to user-specified output directory. Unhealthy recorder is a complete no-op (no writes, no crashes).

## Checklist
- [x] All relevant unit tests are passing
- [x] Documentation updated (if applicable)
- [x] No debug logs or commented-out code

## Reviewer Notes

### Design decisions

| Decision | Option A | Option B | Chosen | Rationale |
|----------|----------|----------|--------|-----------|
| Wire format | Length-prefixed binary | Newline-delimited base64 | B | Corruption recovery (skip to next newline), tooling compat (`head`, `wc -l`, `tail -f`), negligible overhead at 10Hz |
| Team mapping | Map to blue/yellow only | Extend proto with friendly/opponent | B | Perspective-aware LLM analysis; blue/yellow kept for backwards compat |
| Derived fields | Recompute in consumer | Include in proto | B | Already computed in WorldStateSchema; avoids duplicating zone/accel logic in downstream consumers |
| Flush cadence | Every write | Every N entries | B | `ANALYTICS_FLUSH_INTERVAL=10` (~1s at 100ms throttle) balances I/O throughput vs data-loss window; destructor flush ensures no entries lost on shutdown |
| FieldZone mapping | Direct cast | +1 offset with validation | B | C++ `WorldStateEventHelper::FieldZone` starts at 0 (`NEGATIVE_GOAL_AREA=0`), proto starts at 1 (`FIELD_ZONE_UNKNOWN=0, NEGATIVE_GOAL_AREA=1`). `mapFieldZone` adds 1 and validates with `FieldZone_IsValid` |

### Problem space characterization
- **Parallelism**: None — single-threaded serialization on AnalyticsCore tick (Qt event loop)
- **Distribution**: Single process — serializer lives in same process as AnalyticsCore
- **Scale**: 10 Hz write rate, ~200-500 bytes per entry after base64 (~150-350 raw), indefinite duration
- **Relationships**: AnalyticsCore HAS-A timer and emits metrics; WorldStateRecorder HAS-A file handle and serializer logic; WorldStateRecorder IS-A QObject (for signal/slot)

### Areas requiring attention
- `serializeBall` now includes `zone` — verify this doesn't break any downstream proto consumers that don't expect a zone on Ball
- WorldStateRecorder destructor calls `m_file.flush()` — confirm QFile flush in destructor is safe in all Qt object tree teardown orderings
- Error message on SerializeToString failure uses `entry.DebugString()` which allocates — acceptable since this is an error path, but worth noting

### MVP scope vs end-vision
- **MVP (this MR)**: Serialize WorldStateSchema → proto::AnalyticsEntry (world_state field only). Continuous append to base64-newline-delimited file. UUID + timestamp naming. Error-resilient (skip + log).
- **Future**: Full AnalyticsEntry serialization after proto cleanup (nav commands being deprecated). Time series data consumed by LLM for match analysis. Potential file rotation / size management.

---

## Appendix: Full Design Provenance

<details>
<summary><strong>A1. REQUEST — Original Feature Request</strong></summary>

> Analytics core currently gathers world state from WorldStateManager at a fixed interval (~300ms) and emits a signal. The next step is to implement a new class that: (1) receives that signal via a Qt6 slot, (2) serializes the world state data into binary format using protobuf according to existing protobuf schemas, and (3) builds up a time series dataset from the serialized binary world state snapshots.

**Classification:**
- Scope: Medium — new class that bridges analytics signal to protobuf serialization
- Complexity: Medium — Qt6 signal/slot, protobuf schema conformance, time series accumulation
- Risk: Low — purely additive, no existing behavior modified
- Domain novelty: Low — standard serialization + time series pattern

**Exploration Summary:**

Signal chain: `WorldStateManager` → `AnalyticsCore::updateInternalWorldState` → `QTimer(100ms)` → `tick()` → `process()` → `emit metricProcessed(WorldStateSchema)`

Key mapping: WorldStateSchema → proto::WorldState
- WorldStateSchema has: capture_time, friendlyTeam, teamWithBall, idWithBall, BallSchema, TeamSchema(friendly), TeamSchema(opponent)
- proto::WorldState has: capture_time, blue_robots, yellow_robots, robot_id_with_ball, team_with_ball, ball
- Proto also defines: AnalyticsEntry (wraps WorldState + timestamp + nav commands + stats), AnalyticsLog (time series of entries)

Gap: No existing protobuf serializer. JsonSerializer exists as reference pattern. skynet_proto library compiles all .proto files already.

</details>

<details>
<summary><strong>A2. ELICIT — Requirements Elicitation (Q&A with requester)</strong></summary>

### Q1: Snapshot Scope
**Q:** The proto schema defines AnalyticsEntry (WorldState + timestamp + nav commands + match stats) and AnalyticsLog (repeated entries with start/end time). What scope should each serialized snapshot cover?

**Options:** (A) WorldState only — Serialize just the field state (robots, ball, possession). Nav commands and match stats added later. (B) Full AnalyticsEntry — Serialize world state + navigation commands + robot/event match stats all at once. (C) WorldState + nav commands — Serialize field state and navigation commands, but defer match stats.

**A:** WorldState only. *User notes: Will get rid of nav commands in the future. Will be modifying AnalyticsEntry to de-duplicate redundant and deprecated fields.*

### Q2: Time Series Lifecycle
**Q:** What triggers the start and end of a time series, and where does the accumulated data go?

**Options:** (A) Game state transitions — Start on RUNNING, stop on HALT/STOP, write to file. (B) Fixed window (rolling buffer) — Keep last N seconds in memory, snapshot on demand. (C) Manual start/stop API — Expose startRecording()/stopRecording(). (D) Continuous append to file — Append each serialized entry as it arrives, stream to disk.

**A:** Continuous append to file. *User notes: AnalyticsCore and the WorldStateManager tick at different rates. We should only serialize + append on AnalyticsCore tick.*

### Q3: Team Mapping
**Q:** WorldStateSchema splits teams into friendly/opponent, but proto::WorldState uses blue_robots/yellow_robots. How should the serializer handle this mapping?

**Options:** (A) Map back to blue/yellow — Use friendlyTeam to determine color mapping. (B) Friendly = blue always — Always write friendly as blue_robots regardless of actual color. (C) Add friendly/opponent to proto — Extend proto WorldState with friendly_robots/opponent_robots fields.

**A:** Add friendly/opponent to proto. Extend proto WorldState with friendly_robots, opponent_robots, and friendly_team fields. Keep blue/yellow for backwards compat.

### Q4: Derived Fields
**Q:** WorldStateSchema has derived fields (zone, acceleration, hasBall, distanceToBall) that proto Robot/Ball messages don't include. What should we do?

**Options:** (A) Serialize proto fields only — Only serialize what current proto supports, derived fields recomputed by consumers. (B) Extend proto with derived fields — Add zone, acceleration, hasBall etc. to proto messages. (C) Separate derived message — New proto message for derived analytics alongside raw WorldState.

**A:** Extend proto with derived fields. *User notes: Already derived and computed, just need to include in the message.*

### Q5: Wire Format
**Q:** For the continuous file append: how should individual AnalyticsEntry messages be framed in the file so a reader can parse them back?

**Options:** (A) Length-prefixed — Varint length prefix before each entry, standard protobuf streaming. (B) Single AnalyticsLog wrapper — Accumulate in memory, write one message on close. (C) Newline-delimited base64 — Base64-encode each entry, one per line.

**A:** Newline-delimited base64. *User chose (C) after discussing trade-offs: ~33% size overhead is negligible at 10Hz; corruption recovery (skip to next newline) and debuggability (head, wc -l, tail -f) are significant advantages.*

### Q6: Catch-all
**Q:** Is there anything else about this feature we haven't covered?

**A:** File naming convention + Error resilience. *User notes: Create a UUID for the match, and also include a timestamp-based component to the filename. Skip and log on serialization failure.*

</details>

<details>
<summary><strong>A3. URD — User Requirements Document</strong></summary>

### Requirements

**R1: New Serializer Class** — A new QObject class receives the `AnalyticsCore::metricProcessed(WorldStateSchema)` signal via Qt6 slot. On each invocation, it serializes the WorldStateSchema into a `proto::AnalyticsEntry` (WorldState fields only for MVP) and appends it to an open file.

**R2: Proto Schema Extensions** — Extend analytics_log.proto: `proto::WorldState` gains friendly_robots (repeated Robot), opponent_robots (repeated Robot), friendly_team (Team). Existing blue/yellow fields kept for backwards compat. `proto::Robot` gains: optional FieldZone zone, optional Vector2 acceleration, optional bool has_ball, optional float velocity_angle, optional float distance_with_ball.

**R3: Wire Format — Newline-Delimited Base64** — Each AnalyticsEntry is serialized to binary, base64-encoded, and written as one line (terminated by newline). Corruption-resilient: reader skips to next newline on parse failure.

**R4: Continuous Append on AnalyticsCore Tick** — Serialization and file append happen only on AnalyticsCore tick (100ms / 10Hz). Not tied to WorldStateManager tick rate.

**R5: File Naming** — Output files named with UUID + timestamp components (e.g., `{uuid}_{ISO-timestamp}.pb64`). UUID identifies the match/session.

**R6: Error Resilience** — If serialization of a single entry fails, log a warning (qWarning) and skip that entry. Never crash or stop recording.

### Priorities
1. Proto schema extensions (R2) — must be done first, generates new C++ code
2. Serializer class with signal/slot wiring (R1, R4)
3. Wire format + file I/O (R3, R5)
4. Error handling (R6)

### Design Choices
- Friendly/opponent in proto rather than only blue/yellow — supports perspective-aware analysis
- Derived fields in proto rather than recomputed — already computed, avoids duplication of logic in consumers
- Base64 newline-delimited rather than length-prefixed — corruption recovery + tooling compatibility at negligible size cost
- WorldState only for MVP — nav commands being deprecated, AnalyticsEntry will be cleaned up

### MVP Goals
- Serialize WorldStateSchema → proto::AnalyticsEntry (world_state field populated)
- Continuous append to base64-newline-delimited file
- UUID + timestamp file naming
- Error-resilient (skip + log)

### End-Vision Goals
- Full AnalyticsEntry serialization (after proto cleanup)
- Time series data consumed by LLM for match analysis
- Potential file rotation / size management

</details>

<details>
<summary><strong>A4. PROPOSAL — Ratified Technical Design (3rd revision, accepted by 3 reviewers)</strong></summary>

### Problem Space

**Axes:**
- Parallelism: None — single-threaded serialization on AnalyticsCore tick (Qt event loop)
- Distribution: Single process — serializer lives in same process as AnalyticsCore
- Scale: 10 Hz write rate, ~200-500 bytes per entry after base64 (~150-350 raw), indefinite duration
- Has-a: AnalyticsCore HAS-A timer and emits metrics; new Recorder HAS-A file handle and serializer logic
- Is-a: Recorder IS-A QObject (for signal/slot)

### Engineering Tradeoffs

| Decision | Option A | Option B | Chosen | Rationale |
|----------|----------|----------|--------|-----------|
| Wire format | Length-prefixed binary | Newline-delimited base64 | B | Corruption recovery, tooling compat, negligible overhead at 10Hz |
| Team mapping | Map to blue/yellow | Extend proto with friendly/opponent | B | Perspective-aware analysis; blue/yellow kept for compat |
| Derived fields | Recompute in consumer | Include in proto | B | Already computed; avoids duplicating zone/accel logic |
| Serializer location | In analytics lib | New serialization lib | A | Tight coupling to AnalyticsCore signal; co-locate |

### Slice Decomposition

**Slice 1: Proto Schema Extensions** — Extend analytics_log.proto: Add FieldZone enum (mirrors WorldStateEventHelper::FieldZone). Extend Robot message: optional FieldZone zone, optional Vector2 acceleration, optional bool has_ball, optional float velocity_angle, optional float distance_with_ball. Extend WorldState message: repeated Robot friendly_robots, repeated Robot opponent_robots, optional Team friendly_team. Verify skynet_proto builds with extended schemas.

**Slice 2: Protobuf Serializer (namespace ProtobufSerializer)** — Free functions in namespace (matching JsonSerializer pattern): serializeRobot, serializeBall, serializeWorldState, serializeEntry. Test fixtures for all 13 RobotSchema + 8 BallSchema fields (including derived fields that existing TestUtils::makeRobot does not populate).

**Slice 3: WorldStateRecorder (QObject)** — Connects to AnalyticsCore::metricProcessed via slot. On each signal: serialize → base64 encode → append line to file. File opened on construction with name: {uuid}_{ISO-timestamp}.pb64. Constructor validates output directory (exists + writable). If file open fails, log qWarning and set m_healthy=false. When m_healthy is false, onMetricProcessed is a no-op. Integration test: AnalyticsCore → WorldStateRecorder end-to-end with QSignalSpy.

### BDD Acceptance Criteria

**Given** AnalyticsCore emits metricProcessed with a WorldStateSchema **When** WorldStateRecorder receives the signal **Then** a new base64-encoded line is appended to the output file **Should Not** block the Qt event loop or crash on malformed data

**Given** a WorldStateSchema with friendlyTeam=BLUE **When** serialized to proto::WorldState **Then** friendly_robots contains the blue team robots and opponent_robots contains yellow **Should Not** lose the blue/yellow distinction (blue_robots/yellow_robots also populated)

**Given** a WorldStateSchema with derived fields (zone, acceleration, hasBall) **When** serialized to proto::Robot **Then** the optional zone, acceleration, has_ball, velocity_angle, distance_with_ball fields are set **Should Not** omit derived fields that are present in the schema

**Given** serialization of one entry fails **When** WorldStateRecorder handles the error **Then** a qWarning is logged and the entry is skipped **Should Not** crash, stop recording, or corrupt the file

**Given** WorldStateRecorder is constructed with an output directory **When** the file is created **Then** the filename matches pattern {uuid}_{ISO-timestamp}.pb64 **Should Not** overwrite existing files

**Given** WorldStateRecorder is constructed with a non-existent or unwritable output directory **When** construction completes **Then** a qWarning is logged and isHealthy() returns false; subsequent onMetricProcessed calls are no-ops **Should Not** throw, abort, or crash

**Given** a WorldStateSchema with zero robots and teamWithBall = std::nullopt **When** serialized **Then** friendly_robots and opponent_robots are empty, team_with_ball is unset, entry is still valid base64 **Should Not** crash, emit invalid protobuf, or skip the entry

**Given** a round-trip test serializes a fully-populated WorldStateSchema **When** the proto bytes are parsed back **Then** every field is asserted: all 13 RobotSchema fields, all 8 BallSchema fields, and all WorldStateSchema top-level fields **Should Not** silently skip any field assertion

**Given** AnalyticsCore is wired to WorldStateRecorder via signal/slot **When** tick() is called N times **Then** output file contains exactly N base64 lines, each parseable as proto::AnalyticsEntry **Should Not** drop signals, produce extra lines, or leave file empty

### Validation Checklist
- [x] Proto compiles with new fields (skynet_proto builds)
- [x] ProtobufSerializer round-trips: serialize then parse back — assert every field
- [x] WorldStateRecorder produces valid base64 lines parseable as AnalyticsEntry
- [x] File naming includes UUID and ISO timestamp
- [x] Serialization failure skips entry with qWarning (no crash)
- [x] Team mapping: friendly/opponent correctly populated based on friendlyTeam
- [x] Derived fields (zone, acceleration, hasBall) present in serialized Robot
- [x] File I/O failure handled gracefully with qWarning — recorder becomes no-op
- [x] Empty WorldState serializes to valid base64 entry
- [x] Test fixtures populate all RobotSchema and BallSchema fields including derived ones
- [x] Integration test: AnalyticsCore → WorldStateRecorder signal/slot → file output end-to-end

</details>

<details>
<summary><strong>A5. IMPL_PLAN — Implementation Plan (vertical slices with integration points)</strong></summary>

### Vertical Slices (3 slices, linear dependency)

**SLICE-1: Proto Schema Extensions** — Extend analytics_log.proto with FieldZone enum, Robot fields 7-11, WorldState fields 7-9. Verify skynet_proto builds. Files owned: `src/network/protocol/proto/analytics_log.proto`. Integration point (outbound): Produces proto::FieldZone, proto::Robot (extended), proto::WorldState (extended), proto::AnalyticsEntry — consumed by SLICE-2.

**SLICE-2: ProtobufSerializer Namespace** — Free functions: serializeRobot, serializeBall, serializeWorldState, serializeEntry. Test fixtures for all 13 RobotSchema + 8 BallSchema fields (including derived). Round-trip test asserting every field. Files owned: `src/serialization/ProtobufSerializer.h`, `src/serialization/ProtobufSerializer.cpp`, `src/serialization/CMakeLists.txt`, `test/serialization/test_protobuf_serializer.cpp`. Integration point (inbound): Depends on SLICE-1 proto types. Integration point (outbound): Produces `ProtobufSerializer::serializeEntry()` — consumed by SLICE-3.

**SLICE-3: WorldStateRecorder QObject** — Qt6 slot onMetricProcessed, base64 append, UUID+timestamp file naming, isHealthy(). Integration test: AnalyticsCore → WorldStateRecorder end-to-end with QSignalSpy. Files owned: `src/analytics/WorldStateRecorder.h`, `src/analytics/WorldStateRecorder.cpp`, `src/analytics/CMakeLists.txt`, `test/analytics/test_world_state_recorder.cpp`. Integration point (inbound): Depends on SLICE-2 `ProtobufSerializer::serializeEntry()`.

### Horizontal Layer Integration Points

| Integration Point | Owning Slice | Consuming Slices | Shared Contract | Merge Timing |
|-------------------|-------------|-------------------|-----------------|--------------|
| Proto types (FieldZone, Robot ext, WorldState ext) | SLICE-1 | SLICE-2, SLICE-3 | analytics_log.proto generated headers | SLICE-1 must merge before SLICE-2 starts |
| ProtobufSerializer::serializeEntry() | SLICE-2 | SLICE-3 | ProtobufSerializer.h namespace API | SLICE-2 must merge before SLICE-3 starts |

### Codebase Context

Existing patterns followed:
- JsonSerializer: namespace with free serialize() overloads in src/serialization/
- AnalyticsCore signal: `void metricProcessed(const WorldStateSchema &metric)` at AnalyticsCore.h:46
- Schemas at src/analytics/schemas/: RobotSchema (13 fields), BallSchema (8 fields + zone), WorldStateSchema, TeamSchema
- FieldZone enum: WorldStateEventHelper::FieldZone (6 values, no zero — proto needs FIELD_ZONE_UNKNOWN=0)
- Tests: boost-ut BDD (feature/scenario/given/when/then), test/ directory
- TestUtils::makeRobot(id, x, y, vx, vy) and TestUtils::makeBall(x, y, z) — do NOT populate derived fields
- skynet_analytics: STATIC lib, links skynet_worldstate, skynet_shared, Qt6::Core
- skynet_proto: STATIC lib via protobuf_generate() in src/network/protocol/proto/CMakeLists.txt

</details>

<details>
<summary><strong>A6. UAT — User Acceptance Testing</strong></summary>

### Round 1: REVISE
Three fixes required:
1. **Add zone field to proto Ball message** — `optional FieldZone zone = 4` was missing from proto Ball; BallSchema::zone was not being serialized in ProtobufSerializer::serializeBall
2. **Periodic flush** — `m_file.flush()` was called every entry; changed to every `SkynetConstants::ANALYTICS_FLUSH_INTERVAL` (10) entries (~1s at 100ms throttle) with destructor flush for safety
3. **Better SerializeToString error message** — Generic "verify fields are populated" replaced with diagnostic dump of WorldStateSchema field values + `entry.DebugString()` showing which proto fields are missing

### Round 2: ACCEPT
All 3 fixes applied and verified. User confirmed ready for final review before landing.

</details>
