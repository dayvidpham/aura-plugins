"""Temporal workflow wrapper for the Aura epoch lifecycle.

Wraps EpochStateMachine with durable Temporal execution. Signals are used for
all state mutations (advance_phase, submit_vote); queries are used for reads
(current_state, available_transitions). Search attributes are updated on every
transition for forensic queryability.

Design rules:
- Workflow code MUST be deterministic: no I/O, no random, no datetime.now().
- Use workflow.now() for timestamps inside workflow code.
- Activities handle non-deterministic operations (constraint checks, recording).
- One workflow per epoch (not per phase) — sufficient for v1.

Key types (all frozen dataclasses):
    EpochInput          — workflow run() input
    EpochResult         — workflow run() return value
    PhaseAdvanceSignal  — advance_phase signal payload
    ReviewVoteSignal    — submit_vote signal payload

Search attribute keys:
    SA_EPOCH_ID — text key for epoch ID forensic lookup
    SA_PHASE    — keyword key for current phase
    SA_ROLE     — keyword key for current role
    SA_STATUS   — keyword key for workflow status
    SA_DOMAIN   — keyword key for phase domain

Activities:
    check_constraints(state, to_phase) -> list[ConstraintViolation]
    record_transition(record: TransitionRecord) -> None
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import timedelta

from temporalio import activity, workflow
from temporalio.common import SearchAttributeKey

from aura_protocol.constraints import ConstraintViolation, RuntimeConstraintChecker
from aura_protocol.state_machine import (
    EpochState,
    EpochStateMachine,
    TransitionError,
    TransitionRecord,
)
from aura_protocol.types import PhaseId, Transition, VoteType, PHASE_DOMAIN

# ─── Search Attribute Keys ────────────────────────────────────────────────────
# These keys are registered in the Temporal namespace and used for forensic
# querying: "find all workflows where AuraPhase='p9'" etc.

SA_EPOCH_ID: SearchAttributeKey = SearchAttributeKey.for_text("AuraEpochId")
SA_PHASE: SearchAttributeKey = SearchAttributeKey.for_keyword("AuraPhase")
SA_ROLE: SearchAttributeKey = SearchAttributeKey.for_keyword("AuraRole")
SA_STATUS: SearchAttributeKey = SearchAttributeKey.for_keyword("AuraStatus")
SA_DOMAIN: SearchAttributeKey = SearchAttributeKey.for_keyword("AuraDomain")


# ─── Signal / Query Types (frozen dataclasses) ────────────────────────────────


@dataclass(frozen=True)
class EpochInput:
    """Input for EpochWorkflow.run().

    epoch_id: globally unique epoch identifier (e.g. "aura-plugins-bj1")
    request_description: human-readable description of the work request
    """

    epoch_id: str
    request_description: str


@dataclass(frozen=True)
class EpochResult:
    """Return value of EpochWorkflow.run() when the epoch reaches COMPLETE.

    epoch_id: the epoch that completed
    final_phase: should always be PhaseId.COMPLETE
    transition_count: total number of phase transitions made
    constraint_violations_total: cumulative violations detected during the run
    """

    epoch_id: str
    final_phase: PhaseId
    transition_count: int
    constraint_violations_total: int


@dataclass(frozen=True)
class PhaseAdvanceSignal:
    """Signal payload for EpochWorkflow.advance_phase().

    to_phase: the target phase to advance to
    triggered_by: who or what triggered this transition (role or signal name)
    condition_met: the condition string from the transition table that was satisfied
    """

    to_phase: PhaseId
    triggered_by: str
    condition_met: str


@dataclass(frozen=True)
class ReviewVoteSignal:
    """Signal payload for EpochWorkflow.submit_vote().

    axis: review axis letter — must be "A", "B", or "C"
    vote: ACCEPT or REVISE
    reviewer_id: unique identifier for the reviewer agent
    """

    axis: str
    vote: VoteType
    reviewer_id: str


# ─── Activities ───────────────────────────────────────────────────────────────
# Activities handle non-deterministic operations so the workflow remains
# deterministic and replayable.


@activity.defn
async def check_constraints(
    state: EpochState, to_phase: PhaseId
) -> list[ConstraintViolation]:
    """Check protocol constraints for a proposed phase transition.

    Runs RuntimeConstraintChecker.check_transition() against the current state
    and the proposed to_phase. Returns a list of violations (empty = valid).

    This is an activity (not inline workflow code) because constraint checking
    may in future versions involve I/O (reading external beads state, etc.).
    Keeping it as an activity ensures the workflow remains deterministic.
    """
    checker = RuntimeConstraintChecker()
    return checker.check_transition(state, to_phase)


@activity.defn
async def record_transition(record: TransitionRecord) -> None:
    """Persist a transition record to the audit trail.

    In v1, this is a no-op stub — the transition record is already stored in
    EpochState.transition_history (in-memory within the workflow). In v2, this
    would write to a durable store (Beads task comment, database, etc.).

    This activity exists to:
    1. Enforce the design boundary: recording is non-deterministic (I/O)
    2. Provide an extension point for v2 persistence without changing the workflow
    """
    # v1 stub: transition is already recorded in EpochState.transition_history.
    # v2: write to beads/database/audit log here.
    logger = logging.getLogger(__name__)
    logger.info(
        "Transition recorded: %s -> %s (triggered_by=%s)",
        record.from_phase.value,
        record.to_phase.value,
        record.triggered_by,
    )


# ─── Workflow ─────────────────────────────────────────────────────────────────


@workflow.defn
class EpochWorkflow:
    """Durable Temporal workflow wrapping the 12-phase EpochStateMachine.

    Lifecycle:
        1. run() initializes the state machine and updates search attributes.
        2. run() loops, waiting for advance_phase or submit_vote signals.
        3. On advance_phase: constraints are checked (activity), then state
           machine advances, search attributes are updated atomically.
        4. On submit_vote: the vote is recorded in the state machine.
        5. When current_phase reaches COMPLETE, run() returns EpochResult.

    Signals:
        advance_phase(PhaseAdvanceSignal) — request a phase transition
        submit_vote(ReviewVoteSignal)     — record a reviewer vote

    Queries:
        current_state() -> EpochState    — snapshot of epoch runtime state
        available_transitions() -> list[Transition] — valid next transitions

    Design invariants:
        - No datetime.now() in workflow code (use workflow.now() instead)
        - No I/O in workflow code (all I/O goes through activities)
        - Signal handlers enqueue work; transitions happen in run() loop
        - Search attributes updated via upsert_search_attributes() on every
          transition to keep AuraPhase / AuraStatus always in sync
    """

    def __init__(self) -> None:
        # Pending signals are queued here and processed in the run() loop.
        self._pending_advance: list[PhaseAdvanceSignal] = []
        self._pending_votes: list[ReviewVoteSignal] = []
        # Cumulative violation count across all transitions.
        self._total_violations: int = 0
        # State machine — initialized in run().
        self._sm: EpochStateMachine | None = None

    # ── Run ───────────────────────────────────────────────────────────────────

    @workflow.run
    async def run(self, input: EpochInput) -> EpochResult:
        """Main workflow loop: initialize, process signals, advance through phases.

        Starts at P1_REQUEST and runs until COMPLETE. On each iteration:
        1. Drain any pending vote signals into the state machine.
        2. Process the next pending advance signal (if any):
           a. Check constraints via activity.
           b. Advance state machine.
           c. Persist transition record via activity.
           d. Upsert search attributes.
        3. Wait for the next signal (or exit if COMPLETE).
        """
        # Initialize the state machine.
        self._sm = EpochStateMachine(input.epoch_id)

        # Set initial search attributes.
        initial_phase = self._sm.state.current_phase
        initial_domain = PHASE_DOMAIN[initial_phase].value if initial_phase in PHASE_DOMAIN else ""
        workflow.upsert_search_attributes(
            [
                SA_EPOCH_ID.value_set(input.epoch_id),
                SA_PHASE.value_set(initial_phase.value),
                SA_ROLE.value_set(self._sm.state.current_role),
                SA_STATUS.value_set("running"),
                SA_DOMAIN.value_set(initial_domain),
            ]
        )

        # Main signal-driven loop.
        while self._sm.state.current_phase != PhaseId.COMPLETE:
            # Wait until there is something to process.
            await workflow.wait_condition(
                lambda: bool(self._pending_advance) or bool(self._pending_votes)
            )

            # 1. Drain all pending votes.
            while self._pending_votes:
                vote_signal = self._pending_votes.pop(0)
                self._sm.record_vote(vote_signal.axis, vote_signal.vote)

            # 2. Process the next advance signal.
            if not self._pending_advance:
                continue

            advance_signal = self._pending_advance.pop(0)

            # 2a. Check constraints (activity — non-deterministic allowed here).
            violations = await workflow.execute_activity(
                check_constraints,
                args=[self._sm.state, advance_signal.to_phase],
                start_to_close_timeout=timedelta(seconds=10),
            )
            self._total_violations += len(violations)

            # 2b. Advance state machine (pure, deterministic).
            # Use workflow.now() — deterministic time source inside workflow.
            try:
                record = self._sm.advance(
                    advance_signal.to_phase,
                    triggered_by=advance_signal.triggered_by,
                    condition_met=advance_signal.condition_met,
                )
            except TransitionError as e:
                # Invalid advance — stay in current phase and record the error
                # for query observability via current_state().last_error.
                self._sm.state.last_error = str(e)
                continue

            # Override the record timestamp to use workflow deterministic time.
            # TransitionRecord is frozen, so we recreate it with workflow.now().
            deterministic_record = TransitionRecord(
                from_phase=record.from_phase,
                to_phase=record.to_phase,
                timestamp=workflow.now(),
                triggered_by=record.triggered_by,
                condition_met=record.condition_met,
            )
            # Replace the last record in history with the deterministic-timestamp one.
            if self._sm.state.transition_history:
                self._sm.state.transition_history[-1] = deterministic_record

            # 2c. Record transition (activity — I/O boundary).
            await workflow.execute_activity(
                record_transition,
                args=[deterministic_record],
                start_to_close_timeout=timedelta(seconds=10),
            )

            # 2d. Upsert search attributes atomically with the transition.
            current = self._sm.state.current_phase
            domain_value = (
                PHASE_DOMAIN[current].value
                if current in PHASE_DOMAIN
                else ""
            )
            workflow.upsert_search_attributes(
                [
                    SA_PHASE.value_set(current.value),
                    SA_ROLE.value_set(self._sm.state.current_role),
                    SA_STATUS.value_set(
                        "complete" if current == PhaseId.COMPLETE else "running"
                    ),
                    SA_DOMAIN.value_set(domain_value),
                ]
            )

        return EpochResult(
            epoch_id=input.epoch_id,
            final_phase=self._sm.state.current_phase,
            transition_count=len(self._sm.state.transition_history),
            constraint_violations_total=self._total_violations,
        )

    # ── Signals ───────────────────────────────────────────────────────────────

    @workflow.signal
    def advance_phase(self, signal: PhaseAdvanceSignal) -> None:
        """Signal: request a phase transition.

        The signal is queued and processed in the next run() loop iteration.
        Transitions are not applied immediately in the signal handler to ensure
        deterministic ordering and proper activity scheduling.
        """
        self._pending_advance.append(signal)

    @workflow.signal
    def submit_vote(self, signal: ReviewVoteSignal) -> None:
        """Signal: record a reviewer vote.

        The vote is queued and applied before the next advance_phase processing
        in the run() loop. Votes affect available_transitions() immediately
        after drain.
        """
        self._pending_votes.append(signal)

    # ── Queries ───────────────────────────────────────────────────────────────

    @workflow.query
    def current_state(self) -> EpochState:
        """Query: return a snapshot of the current epoch runtime state.

        Returns the EpochState from the underlying state machine.
        The returned state is mutable — callers must not modify it.
        """
        if self._sm is None:
            # Workflow not yet initialized (query before run() starts).
            raise RuntimeError("Workflow not yet initialized — run() has not started.")
        return self._sm.state

    @workflow.query
    def available_transitions(self) -> list[Transition]:
        """Query: return the list of currently available phase transitions.

        Delegates to EpochStateMachine.available_transitions which applies
        all gate rules (consensus, BLOCKER, REVISE vote).
        """
        if self._sm is None:
            return []
        return self._sm.available_transitions
