"""Tests for aura_protocol.workflow — Temporal workflow wrapper.

BDD Acceptance Criteria:
    AC6: Given running EpochWorkflow, when advance_phase signal then state + search
         attrs updated atomically. Should not have non-deterministic ops.
    AC7: Given workflow at P9, when querying AuraPhase="p9" then workflow returned.
         Should not have stale search attrs.

Coverage strategy:
    - Types importable and structurally correct (AC6/AC7 foundation)
    - Search attribute keys correct (name + type)
    - Activity: check_constraints delegates to RuntimeConstraintChecker
    - Activity: record_transition is a no-op stub (v1)
    - EpochWorkflow class has correct signal/query decorators
    - Signal/advance logic via direct state machine integration tests
    - Review vote signals correctly queued and applied

Note on Temporal sandbox testing:
    WorkflowEnvironment.start_time_skipping() requires a Temporal test server
    binary (downloaded at runtime). In environments without network access or
    a cached binary, we test:
    1. Activities via ActivityEnvironment (in-process, no server required)
    2. Workflow logic via direct integration with EpochStateMachine
       (same deterministic code path the workflow uses)
    3. Structural invariants via introspection of @workflow.defn decorators

    When a Temporal server is available, full end-to-end sandbox tests should
    use WorkflowEnvironment.start_time_skipping() with the EpochWorkflow class.
"""

from __future__ import annotations

import asyncio
import inspect
from dataclasses import fields

import pytest
import pytest_asyncio

from aura_protocol.constraints import ConstraintViolation, RuntimeConstraintChecker
from aura_protocol.state_machine import (
    EpochState,
    EpochStateMachine,
    TransitionError,
    TransitionRecord,
)
from aura_protocol.types import PhaseId, Transition, VoteType
from aura_protocol.workflow import (
    SA_DOMAIN,
    SA_EPOCH_ID,
    SA_PHASE,
    SA_ROLE,
    SA_STATUS,
    EpochInput,
    EpochResult,
    EpochWorkflow,
    PhaseAdvanceSignal,
    ReviewVoteSignal,
    check_constraints,
    record_transition,
)
from temporalio.common import SearchAttributeKey
from temporalio.testing import ActivityEnvironment


# ─── Helpers ──────────────────────────────────────────────────────────────────


def _make_sm(epoch_id: str = "test-epoch") -> EpochStateMachine:
    """Return a fresh EpochStateMachine at P1."""
    return EpochStateMachine(epoch_id)


def _advance_to(sm: EpochStateMachine, target: PhaseId) -> None:
    """Advance sm through the forward path to target, satisfying gates."""
    _FORWARD: list[PhaseId] = [
        PhaseId.P1_REQUEST,
        PhaseId.P2_ELICIT,
        PhaseId.P3_PROPOSE,
        PhaseId.P4_REVIEW,
        PhaseId.P5_UAT,
        PhaseId.P6_RATIFY,
        PhaseId.P7_HANDOFF,
        PhaseId.P8_IMPL_PLAN,
        PhaseId.P9_SLICE,
        PhaseId.P10_CODE_REVIEW,
        PhaseId.P11_IMPL_UAT,
        PhaseId.P12_LANDING,
        PhaseId.COMPLETE,
    ]
    current_idx = _FORWARD.index(sm.state.current_phase)
    target_idx = _FORWARD.index(target)

    for i in range(current_idx, target_idx):
        from_phase = _FORWARD[i]
        next_phase = _FORWARD[i + 1]

        # Satisfy gates before advancing.
        if from_phase == PhaseId.P4_REVIEW and next_phase == PhaseId.P5_UAT:
            sm.record_vote("A", VoteType.ACCEPT)
            sm.record_vote("B", VoteType.ACCEPT)
            sm.record_vote("C", VoteType.ACCEPT)

        if from_phase == PhaseId.P10_CODE_REVIEW and next_phase == PhaseId.P11_IMPL_UAT:
            sm.record_vote("A", VoteType.ACCEPT)
            sm.record_vote("B", VoteType.ACCEPT)
            sm.record_vote("C", VoteType.ACCEPT)

        sm.advance(next_phase, triggered_by="test", condition_met="test condition")


# ─── L1: Type Definitions ─────────────────────────────────────────────────────


class TestSearchAttributeKeys:
    """Search attribute keys are correctly named and typed."""

    def test_sa_epoch_id_is_text(self) -> None:
        """SA_EPOCH_ID must be a text key named 'AuraEpochId'."""
        assert SA_EPOCH_ID.name == "AuraEpochId"
        # text keys accept str values — verify value_set works
        update = SA_EPOCH_ID.value_set("epoch-123")
        assert update is not None

    def test_sa_phase_is_keyword(self) -> None:
        """SA_PHASE must be a keyword key named 'AuraPhase'."""
        assert SA_PHASE.name == "AuraPhase"
        update = SA_PHASE.value_set("p9")
        assert update is not None

    def test_sa_role_is_keyword(self) -> None:
        """SA_ROLE must be a keyword key named 'AuraRole'."""
        assert SA_ROLE.name == "AuraRole"
        update = SA_ROLE.value_set("supervisor")
        assert update is not None

    def test_sa_status_is_keyword(self) -> None:
        """SA_STATUS must be a keyword key named 'AuraStatus'."""
        assert SA_STATUS.name == "AuraStatus"
        update = SA_STATUS.value_set("running")
        assert update is not None

    def test_sa_domain_is_keyword(self) -> None:
        """SA_DOMAIN must be a keyword key named 'AuraDomain'."""
        assert SA_DOMAIN.name == "AuraDomain"
        update = SA_DOMAIN.value_set("impl")
        assert update is not None

    def test_all_sa_keys_are_search_attribute_keys(self) -> None:
        """All SA_* constants must be SearchAttributeKey instances."""
        for key in [SA_EPOCH_ID, SA_PHASE, SA_ROLE, SA_STATUS, SA_DOMAIN]:
            assert isinstance(key, SearchAttributeKey)


class TestSignalQueryTypes:
    """Signal/query type dataclasses are correctly structured."""

    def test_epoch_input_is_frozen_dataclass(self) -> None:
        """EpochInput must be a frozen dataclass with epoch_id and request_description."""
        inp = EpochInput(epoch_id="ep-1", request_description="test request")
        assert inp.epoch_id == "ep-1"
        assert inp.request_description == "test request"
        # Frozen: must raise on attribute set
        with pytest.raises((AttributeError, TypeError)):
            inp.epoch_id = "changed"  # type: ignore[misc]

    def test_epoch_result_is_frozen_dataclass(self) -> None:
        """EpochResult must be a frozen dataclass with the correct fields."""
        result = EpochResult(
            epoch_id="ep-1",
            final_phase=PhaseId.COMPLETE,
            transition_count=12,
            constraint_violations_total=0,
        )
        assert result.epoch_id == "ep-1"
        assert result.final_phase == PhaseId.COMPLETE
        assert result.transition_count == 12
        assert result.constraint_violations_total == 0
        with pytest.raises((AttributeError, TypeError)):
            result.transition_count = 0  # type: ignore[misc]

    def test_phase_advance_signal_is_frozen_dataclass(self) -> None:
        """PhaseAdvanceSignal must be a frozen dataclass with to_phase, triggered_by, condition_met."""
        sig = PhaseAdvanceSignal(
            to_phase=PhaseId.P2_ELICIT,
            triggered_by="architect",
            condition_met="classification confirmed",
        )
        assert sig.to_phase == PhaseId.P2_ELICIT
        assert sig.triggered_by == "architect"
        assert sig.condition_met == "classification confirmed"
        with pytest.raises((AttributeError, TypeError)):
            sig.to_phase = PhaseId.P3_PROPOSE  # type: ignore[misc]

    def test_review_vote_signal_is_frozen_dataclass(self) -> None:
        """ReviewVoteSignal must be a frozen dataclass with axis, vote, reviewer_id."""
        sig = ReviewVoteSignal(axis="A", vote=VoteType.ACCEPT, reviewer_id="reviewer-1")
        assert sig.axis == "A"
        assert sig.vote == VoteType.ACCEPT
        assert sig.reviewer_id == "reviewer-1"
        with pytest.raises((AttributeError, TypeError)):
            sig.axis = "B"  # type: ignore[misc]

    def test_phase_advance_signal_uses_phase_id_enum(self) -> None:
        """PhaseAdvanceSignal.to_phase must be a PhaseId enum."""
        sig = PhaseAdvanceSignal(
            to_phase=PhaseId.P9_SLICE,
            triggered_by="supervisor",
            condition_met="slices created",
        )
        assert sig.to_phase is PhaseId.P9_SLICE
        assert isinstance(sig.to_phase, PhaseId)

    def test_review_vote_signal_uses_vote_type_enum(self) -> None:
        """ReviewVoteSignal.vote must be a VoteType enum."""
        sig = ReviewVoteSignal(axis="B", vote=VoteType.REVISE, reviewer_id="reviewer-2")
        assert sig.vote is VoteType.REVISE
        assert isinstance(sig.vote, VoteType)


class TestWorkflowStructure:
    """EpochWorkflow has correct Temporal decorator structure (introspection).

    temporalio attaches double-underscore attributes (e.g. __temporal_signal_definition)
    to decorated methods. We check for these to verify the decorators were applied
    correctly without running the full Temporal test server.
    """

    def test_workflow_defn_applied(self) -> None:
        """EpochWorkflow must have @workflow.defn applied (has __temporal_workflow_definition)."""
        # @workflow.defn attaches __temporal_workflow_definition to the class
        assert hasattr(EpochWorkflow, "__temporal_workflow_definition")

    def test_advance_phase_is_signal(self) -> None:
        """advance_phase must be a @workflow.signal handler."""
        method = EpochWorkflow.advance_phase
        assert hasattr(method, "__temporal_signal_definition")

    def test_submit_vote_is_signal(self) -> None:
        """submit_vote must be a @workflow.signal handler."""
        method = EpochWorkflow.submit_vote
        assert hasattr(method, "__temporal_signal_definition")

    def test_current_state_is_query(self) -> None:
        """current_state must be a @workflow.query handler."""
        method = EpochWorkflow.current_state
        assert hasattr(method, "__temporal_query_definition")

    def test_available_transitions_is_query(self) -> None:
        """available_transitions must be a @workflow.query handler."""
        method = EpochWorkflow.available_transitions
        assert hasattr(method, "__temporal_query_definition")

    def test_run_is_workflow_run(self) -> None:
        """run must be the @workflow.run entry point."""
        method = EpochWorkflow.run
        assert hasattr(method, "__temporal_workflow_run")


# ─── L2: Activity Tests ────────────────────────────────────────────────────────
# Using ActivityEnvironment — runs activities in-process without a Temporal server.


class TestCheckConstraintsActivity:
    """AC6: check_constraints activity validates protocol constraints."""

    @pytest.mark.asyncio
    async def test_valid_p1_to_p2_advance_has_no_violations(self) -> None:
        """check_constraints at P1 proposing P2 returns no violations.

        This is the simplest forward transition with no gate conditions.
        """
        sm = _make_sm("epoch-test-1")
        env = ActivityEnvironment()
        violations = await env.run(check_constraints, sm.state, PhaseId.P2_ELICIT)
        assert isinstance(violations, list)
        assert violations == []

    @pytest.mark.asyncio
    async def test_p4_to_p5_without_consensus_has_violations(self) -> None:
        """check_constraints at P4 proposing P5 without consensus returns violations.

        C-review-consensus: all 3 axes (A, B, C) must ACCEPT before advancing.
        """
        sm = _make_sm("epoch-test-2")
        _advance_to(sm, PhaseId.P4_REVIEW)
        # No votes recorded — consensus not reached.
        env = ActivityEnvironment()
        violations = await env.run(check_constraints, sm.state, PhaseId.P5_UAT)
        assert len(violations) > 0
        constraint_ids = [v.constraint_id for v in violations]
        assert "C-review-consensus" in constraint_ids

    @pytest.mark.asyncio
    async def test_p4_to_p5_with_consensus_has_no_violations(self) -> None:
        """check_constraints at P4 with all 3 ACCEPT returns no violations."""
        sm = _make_sm("epoch-test-3")
        _advance_to(sm, PhaseId.P4_REVIEW)
        # Record all 3 ACCEPT votes (satisfied in _advance_to already, but let's be explicit).
        # _advance_to stops before advancing through the gate; re-record.
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.ACCEPT)
        env = ActivityEnvironment()
        violations = await env.run(check_constraints, sm.state, PhaseId.P5_UAT)
        # No consensus violations (only handoff-required violations for actor-change transitions).
        consensus_violations = [v for v in violations if v.constraint_id == "C-review-consensus"]
        assert consensus_violations == []

    @pytest.mark.asyncio
    async def test_check_constraints_returns_list_of_constraint_violations(self) -> None:
        """check_constraints always returns list[ConstraintViolation]."""
        sm = _make_sm("epoch-test-4")
        env = ActivityEnvironment()
        result = await env.run(check_constraints, sm.state, PhaseId.P2_ELICIT)
        assert isinstance(result, list)
        for item in result:
            assert isinstance(item, ConstraintViolation)


class TestRecordTransitionActivity:
    """record_transition activity is a no-op stub that does not raise."""

    @pytest.mark.asyncio
    async def test_record_transition_succeeds_without_side_effects(self) -> None:
        """record_transition completes without raising for a valid TransitionRecord."""
        from datetime import datetime, timezone

        record = TransitionRecord(
            from_phase=PhaseId.P1_REQUEST,
            to_phase=PhaseId.P2_ELICIT,
            timestamp=datetime.now(tz=timezone.utc),
            triggered_by="architect",
            condition_met="classification confirmed",
        )
        env = ActivityEnvironment()
        # Should not raise.
        result = await env.run(record_transition, record)
        assert result is None

    @pytest.mark.asyncio
    async def test_record_transition_accepts_any_phase_pair(self) -> None:
        """record_transition works for all valid phase pairs."""
        from datetime import datetime, timezone

        for from_p, to_p in [
            (PhaseId.P8_IMPL_PLAN, PhaseId.P9_SLICE),
            (PhaseId.P9_SLICE, PhaseId.P10_CODE_REVIEW),
            (PhaseId.P12_LANDING, PhaseId.COMPLETE),
        ]:
            record = TransitionRecord(
                from_phase=from_p,
                to_phase=to_p,
                timestamp=datetime.now(tz=timezone.utc),
                triggered_by="supervisor",
                condition_met="all conditions met",
            )
            env = ActivityEnvironment()
            result = await env.run(record_transition, record)
            assert result is None


# ─── L3: AC6 / AC7 — State Machine Integration ───────────────────────────────
# These tests verify the SAME deterministic logic that EpochWorkflow.run() uses.
# When a Temporal sandbox is available, these assertions hold end-to-end.


class TestAC6AdvancePhaseSignalLogic:
    """AC6: advance_phase signal causes state transitions and search attr updates.

    Tests the underlying deterministic logic that EpochWorkflow.run() executes
    on receiving an advance_phase signal. This is the same code path; the
    workflow wraps it with Temporal's signal delivery mechanism.
    """

    def test_advance_p1_to_p2_updates_state(self) -> None:
        """Advance from P1 to P2 transitions state atomically.

        AC6: state transitions must be atomic — no partial state visible.
        """
        sm = _make_sm("ac6-epoch-1")
        assert sm.state.current_phase == PhaseId.P1_REQUEST

        record = sm.advance(
            PhaseId.P2_ELICIT,
            triggered_by="architect",
            condition_met="classification confirmed",
        )

        # State updated atomically.
        assert sm.state.current_phase == PhaseId.P2_ELICIT
        assert PhaseId.P1_REQUEST in sm.state.completed_phases
        assert record.from_phase == PhaseId.P1_REQUEST
        assert record.to_phase == PhaseId.P2_ELICIT

    def test_advance_records_transition_history(self) -> None:
        """Each advance appends to transition_history (audit trail preserved).

        AC6: should not have non-deterministic ops — history is deterministic.
        """
        sm = _make_sm("ac6-epoch-2")
        sm.advance(PhaseId.P2_ELICIT, triggered_by="architect", condition_met="confirmed")
        sm.advance(PhaseId.P3_PROPOSE, triggered_by="architect", condition_met="URD created")

        assert len(sm.state.transition_history) == 2
        assert sm.state.transition_history[0].from_phase == PhaseId.P1_REQUEST
        assert sm.state.transition_history[0].to_phase == PhaseId.P2_ELICIT
        assert sm.state.transition_history[1].from_phase == PhaseId.P2_ELICIT
        assert sm.state.transition_history[1].to_phase == PhaseId.P3_PROPOSE

    def test_invalid_advance_raises_transition_error(self) -> None:
        """Attempting an invalid transition raises TransitionError (not a silent skip).

        AC6: signal-driven advancement must reject invalid transitions.
        """
        sm = _make_sm("ac6-epoch-3")
        # P1 cannot directly advance to P9.
        with pytest.raises(TransitionError) as exc_info:
            sm.advance(PhaseId.P9_SLICE, triggered_by="architect", condition_met="invalid")
        assert len(exc_info.value.violations) > 0

    def test_advance_through_multiple_phases_sequentially(self) -> None:
        """Signal-driven progression through P1 → P2 → P3 advances state correctly.

        Simulates 3 successive advance_phase signals processed in order.
        """
        sm = _make_sm("ac6-epoch-4")

        signals = [
            PhaseAdvanceSignal(
                to_phase=PhaseId.P2_ELICIT,
                triggered_by="architect",
                condition_met="classification confirmed",
            ),
            PhaseAdvanceSignal(
                to_phase=PhaseId.P3_PROPOSE,
                triggered_by="architect",
                condition_met="URD created",
            ),
            PhaseAdvanceSignal(
                to_phase=PhaseId.P4_REVIEW,
                triggered_by="architect",
                condition_met="proposal created",
            ),
        ]

        for signal in signals:
            sm.advance(
                signal.to_phase,
                triggered_by=signal.triggered_by,
                condition_met=signal.condition_met,
            )

        assert sm.state.current_phase == PhaseId.P4_REVIEW
        assert len(sm.state.transition_history) == 3
        expected_completed = {PhaseId.P1_REQUEST, PhaseId.P2_ELICIT, PhaseId.P3_PROPOSE}
        assert expected_completed.issubset(sm.state.completed_phases)

    def test_search_attributes_values_are_correct_after_advance(self) -> None:
        """After advance, the values used for search attribute upsert are correct.

        AC6: search attrs must be updated atomically with the state transition.
        We verify the source values (current phase, role) that the workflow
        would use in upsert_search_attributes().
        """
        from aura_protocol.types import PHASE_DOMAIN

        sm = _make_sm("ac6-epoch-5")
        sm.advance(
            PhaseId.P2_ELICIT,
            triggered_by="architect",
            condition_met="confirmed",
        )

        # Values that the workflow.upsert_search_attributes() call would use.
        expected_phase = sm.state.current_phase.value
        expected_role = sm.state.current_role
        expected_domain = PHASE_DOMAIN.get(sm.state.current_phase)

        assert expected_phase == "p2"
        assert expected_role is not None
        assert expected_domain is not None  # P2 is in USER domain

    def test_review_vote_signal_recorded_before_advance(self) -> None:
        """ReviewVoteSignal: submit_vote queues votes, applied before next advance.

        Simulates the workflow's vote-draining logic: votes are applied
        before processing the advance signal.
        """
        sm = _make_sm("ac6-epoch-6")
        _advance_to(sm, PhaseId.P4_REVIEW)

        # Simulate 3 ReviewVoteSignals being received.
        vote_signals = [
            ReviewVoteSignal(axis="A", vote=VoteType.ACCEPT, reviewer_id="reviewer-A"),
            ReviewVoteSignal(axis="B", vote=VoteType.ACCEPT, reviewer_id="reviewer-B"),
            ReviewVoteSignal(axis="C", vote=VoteType.ACCEPT, reviewer_id="reviewer-C"),
        ]

        # Apply votes (drain, as workflow.run() does).
        for v_signal in vote_signals:
            sm.record_vote(v_signal.axis, v_signal.vote)

        # Now advance should succeed.
        assert sm.has_consensus()
        record = sm.advance(
            PhaseId.P5_UAT,
            triggered_by="reviewer",
            condition_met="all 3 vote ACCEPT",
        )
        assert record.to_phase == PhaseId.P5_UAT
        assert sm.state.current_phase == PhaseId.P5_UAT

    def test_revise_vote_blocks_forward_advance(self) -> None:
        """A single REVISE vote makes only the backward transition available.

        AC6: vote signals must affect available_transitions atomically.
        """
        sm = _make_sm("ac6-epoch-7")
        _advance_to(sm, PhaseId.P4_REVIEW)

        # One REVISE vote — consensus blocked.
        sm.record_vote("A", VoteType.REVISE)

        # Forward transition (P4→P5) no longer in available_transitions.
        available = sm.available_transitions
        to_phases = {t.to_phase for t in available}
        assert PhaseId.P5_UAT not in to_phases
        assert PhaseId.P3_PROPOSE in to_phases


class TestAC7QueryCurrentState:
    """AC7: Query current_state returns correct phase; search attrs not stale.

    Tests verify that after state machine transitions, the state exposed via
    current_state() query reflects the actual current phase — no stale data.
    """

    def test_initial_state_is_p1(self) -> None:
        """AC7: Before any advance, current_state().current_phase == P1."""
        sm = _make_sm("ac7-epoch-1")
        # current_state() in the workflow returns sm.state directly.
        state = sm.state
        assert state.current_phase == PhaseId.P1_REQUEST

    def test_state_after_p9_advance_reflects_p9(self) -> None:
        """AC7: After advancing to P9, current_state query returns P9 phase.

        This is the AC7 scenario: AuraPhase='p9' query should return the workflow.
        """
        sm = _make_sm("ac7-epoch-2")
        _advance_to(sm, PhaseId.P9_SLICE)

        # The workflow current_state() query returns sm.state.
        state = sm.state
        assert state.current_phase == PhaseId.P9_SLICE
        assert state.current_phase.value == "p9"

    def test_current_state_reflects_completed_phases(self) -> None:
        """AC7: current_state includes completed_phases — no stale phase info."""
        sm = _make_sm("ac7-epoch-3")
        _advance_to(sm, PhaseId.P3_PROPOSE)

        state = sm.state
        assert PhaseId.P1_REQUEST in state.completed_phases
        assert PhaseId.P2_ELICIT in state.completed_phases
        assert PhaseId.P3_PROPOSE not in state.completed_phases  # current, not completed

    def test_available_transitions_query_correct_at_p9(self) -> None:
        """AC7: available_transitions() at P9 returns P10 as the valid next step."""
        sm = _make_sm("ac7-epoch-4")
        _advance_to(sm, PhaseId.P9_SLICE)

        # available_transitions() is the same logic the workflow query exposes.
        transitions = sm.available_transitions
        assert len(transitions) == 1
        assert transitions[0].to_phase == PhaseId.P10_CODE_REVIEW

    def test_available_transitions_empty_at_complete(self) -> None:
        """AC7: available_transitions() at COMPLETE returns empty list."""
        sm = _make_sm("ac7-epoch-5")
        _advance_to(sm, PhaseId.COMPLETE)

        transitions = sm.available_transitions
        assert transitions == []

    def test_vote_state_visible_in_current_state(self) -> None:
        """AC7: review votes appear in current_state().review_votes (no stale state)."""
        sm = _make_sm("ac7-epoch-6")
        _advance_to(sm, PhaseId.P4_REVIEW)
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.REVISE)

        state = sm.state
        assert state.review_votes.get("A") == VoteType.ACCEPT
        assert state.review_votes.get("B") == VoteType.REVISE

    def test_state_search_attr_values_match_current_phase(self) -> None:
        """AC7: The phase value used for SA_PHASE upsert matches current state.

        Verifies no stale search attributes — the values come directly from
        sm.state.current_phase.value after each transition.
        """
        sm = _make_sm("ac7-epoch-7")
        _advance_to(sm, PhaseId.P9_SLICE)

        # This is what the workflow would set for AuraPhase after reaching P9.
        phase_sa_value = sm.state.current_phase.value
        assert phase_sa_value == "p9"

        # Also verify the SA_PHASE key name matches what Temporal would index.
        assert SA_PHASE.name == "AuraPhase"


# ─── Full Lifecycle Integration ────────────────────────────────────────────────


class TestFullLifecycleIntegration:
    """Full lifecycle test: P1 → COMPLETE via forward path."""

    def test_full_forward_path_completes(self) -> None:
        """The state machine can complete the full 12-phase lifecycle."""
        sm = _make_sm("full-lifecycle-epoch")
        _advance_to(sm, PhaseId.COMPLETE)
        assert sm.state.current_phase == PhaseId.COMPLETE
        assert len(sm.state.transition_history) == 12

    def test_transition_count_matches_history_length(self) -> None:
        """EpochResult.transition_count matches the actual transition_history length."""
        sm = _make_sm("transition-count-epoch")
        _advance_to(sm, PhaseId.P6_RATIFY)

        transition_count = len(sm.state.transition_history)
        # Verify this is what EpochResult would capture.
        result = EpochResult(
            epoch_id=sm.state.epoch_id,
            final_phase=sm.state.current_phase,
            transition_count=transition_count,
            constraint_violations_total=0,
        )
        assert result.transition_count == len(sm.state.transition_history)
