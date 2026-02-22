"""Tests for aura_protocol.state_machine — 12-phase epoch lifecycle state machine.

BDD Acceptance Criteria:
    AC1: Given epoch in P1, advance(p2) transitions and records; advance(p8) raises TransitionError.
    AC2: Given epoch in P4 with 2/3 ACCEPT, advance(p5) raises TransitionError (needs consensus).
    AC3: Given epoch in P4 with REVISE, available_transitions returns only [p3].
    AC4: Given epoch in P10 with blocker_count > 0, advance(p11) raises TransitionError.

Additional coverage:
    - Transition history recording
    - Valid sequential progression p1→p2→...→p12→complete
    - Invalid skip transitions rejected
    - Vote recording and clearing on phase change
    - record_blocker increment/decrement
    - has_consensus logic
    - validate_advance dry-run
    - COMPLETE sentinel behaviour
"""

from __future__ import annotations

import pytest

from aura_protocol.state_machine import (
    EpochState,
    EpochStateMachine,
    TransitionError,
    TransitionRecord,
)
from aura_protocol.types import PhaseId, VoteType


# ─── Helpers ──────────────────────────────────────────────────────────────────


def _make_sm(epoch_id: str = "test-epoch") -> EpochStateMachine:
    """Return a fresh EpochStateMachine starting at P1."""
    return EpochStateMachine(epoch_id)


def _advance_to(sm: EpochStateMachine, target: PhaseId) -> None:
    """Advance a state machine through all phases sequentially up to target.

    Only uses the first (forward) transition at each step.
    Populates required gates along the way:
    - At p4 (plan review): records 3 ACCEPT votes before advancing to p5.
    - At p10 (code review): records 3 ACCEPT votes before advancing to p11.
    """
    # Ordered sequence of forward phases (no branching — first transition only).
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
        frm = _FORWARD[i]
        nxt = _FORWARD[i + 1]

        # Populate consensus gate before p4→p5.
        if frm == PhaseId.P4_REVIEW and nxt == PhaseId.P5_UAT:
            sm.record_vote("A", VoteType.ACCEPT)
            sm.record_vote("B", VoteType.ACCEPT)
            sm.record_vote("C", VoteType.ACCEPT)

        # Populate consensus gate before p10→p11.
        if frm == PhaseId.P10_CODE_REVIEW and nxt == PhaseId.P11_IMPL_UAT:
            sm.record_vote("A", VoteType.ACCEPT)
            sm.record_vote("B", VoteType.ACCEPT)
            sm.record_vote("C", VoteType.ACCEPT)

        sm.advance(nxt, triggered_by="test", condition_met="test-condition")


# ─── AC1: State Machine Transitions ───────────────────────────────────────────


class TestAC1Transitions:
    """AC1: Given epoch in P1, advance(p2) → transitions; advance(p8) → TransitionError."""

    def test_advance_p1_to_p2_transitions(self) -> None:
        sm = _make_sm()
        assert sm.state.current_phase == PhaseId.P1_REQUEST

        record = sm.advance(
            PhaseId.P2_ELICIT,
            triggered_by="architect",
            condition_met="classification confirmed, research and explore complete",
        )

        assert sm.state.current_phase == PhaseId.P2_ELICIT
        assert isinstance(record, TransitionRecord)
        assert record.from_phase == PhaseId.P1_REQUEST
        assert record.to_phase == PhaseId.P2_ELICIT

    def test_advance_p1_to_p8_raises_transition_error(self) -> None:
        sm = _make_sm()
        with pytest.raises(TransitionError) as exc_info:
            sm.advance(
                PhaseId.P8_IMPL_PLAN,
                triggered_by="architect",
                condition_met="skipping phases",
            )
        assert exc_info.value.violations
        assert "p8" in exc_info.value.violations[0] or "p8" in str(exc_info.value)

    def test_invalid_skip_p1_to_p6_raises_transition_error(self) -> None:
        sm = _make_sm()
        with pytest.raises(TransitionError):
            sm.advance(PhaseId.P6_RATIFY, triggered_by="test", condition_met="skip")

    def test_transition_recorded_in_history(self) -> None:
        sm = _make_sm()
        assert sm.state.transition_history == []

        sm.advance(PhaseId.P2_ELICIT, triggered_by="architect", condition_met="done")

        assert len(sm.state.transition_history) == 1
        assert sm.state.transition_history[0].from_phase == PhaseId.P1_REQUEST
        assert sm.state.transition_history[0].to_phase == PhaseId.P2_ELICIT

    def test_completed_phases_updated(self) -> None:
        sm = _make_sm()
        sm.advance(PhaseId.P2_ELICIT, triggered_by="test", condition_met="done")

        assert PhaseId.P1_REQUEST in sm.state.completed_phases

    def test_current_phase_updated(self) -> None:
        sm = _make_sm()
        sm.advance(PhaseId.P2_ELICIT, triggered_by="test", condition_met="done")
        assert sm.state.current_phase == PhaseId.P2_ELICIT

    def test_transition_record_has_timestamp(self) -> None:
        sm = _make_sm()
        record = sm.advance(
            PhaseId.P2_ELICIT, triggered_by="test", condition_met="done"
        )
        assert record.timestamp is not None

    def test_transition_record_preserves_triggered_by(self) -> None:
        sm = _make_sm()
        record = sm.advance(
            PhaseId.P2_ELICIT, triggered_by="my-role", condition_met="done"
        )
        assert record.triggered_by == "my-role"

    def test_transition_record_preserves_condition_met(self) -> None:
        sm = _make_sm()
        record = sm.advance(
            PhaseId.P2_ELICIT, triggered_by="test", condition_met="my-condition"
        )
        assert record.condition_met == "my-condition"


# ─── AC2: Consensus Gate ──────────────────────────────────────────────────────


class TestAC2ConsensusGate:
    """AC2: Given epoch in P4 with 2/3 ACCEPT, advance(p5) → TransitionError."""

    def _sm_at_p4(self) -> EpochStateMachine:
        sm = _make_sm()
        _advance_to(sm, PhaseId.P4_REVIEW)
        return sm

    def test_advance_p4_to_p5_without_any_votes_raises(self) -> None:
        sm = self._sm_at_p4()
        with pytest.raises(TransitionError) as exc_info:
            sm.advance(
                PhaseId.P5_UAT,
                triggered_by="test",
                condition_met="premature",
            )
        assert exc_info.value.violations
        assert "consensus" in exc_info.value.violations[0].lower()

    def test_advance_p4_to_p5_with_2_of_3_accept_raises(self) -> None:
        sm = self._sm_at_p4()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        # C axis not voted

        with pytest.raises(TransitionError) as exc_info:
            sm.advance(
                PhaseId.P5_UAT,
                triggered_by="test",
                condition_met="2/3 ACCEPT",
            )
        assert exc_info.value.violations
        assert "consensus" in exc_info.value.violations[0].lower()

    def test_advance_p4_to_p5_with_all_3_accept_succeeds(self) -> None:
        sm = self._sm_at_p4()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.ACCEPT)

        record = sm.advance(
            PhaseId.P5_UAT, triggered_by="reviewer", condition_met="all 3 vote ACCEPT"
        )
        assert sm.state.current_phase == PhaseId.P5_UAT
        assert record.from_phase == PhaseId.P4_REVIEW
        assert record.to_phase == PhaseId.P5_UAT

    def test_advance_p4_to_p5_with_1_of_3_accept_raises(self) -> None:
        sm = self._sm_at_p4()
        sm.record_vote("A", VoteType.ACCEPT)
        # B and C not voted

        with pytest.raises(TransitionError):
            sm.advance(PhaseId.P5_UAT, triggered_by="test", condition_met="1/3 ACCEPT")

    def test_advance_p4_to_p5_with_revise_vote_raises(self) -> None:
        sm = self._sm_at_p4()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.REVISE)

        with pytest.raises(TransitionError):
            sm.advance(PhaseId.P5_UAT, triggered_by="test", condition_met="has revise")

    def test_validate_advance_returns_violations_for_missing_consensus(self) -> None:
        sm = self._sm_at_p4()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)

        violations = sm.validate_advance(PhaseId.P5_UAT)
        assert len(violations) == 1
        assert "consensus" in violations[0].lower()

    def test_validate_advance_returns_empty_when_consensus_met(self) -> None:
        sm = self._sm_at_p4()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.ACCEPT)

        violations = sm.validate_advance(PhaseId.P5_UAT)
        assert violations == []


# ─── AC3: Revision Loop ───────────────────────────────────────────────────────


class TestAC3RevisionLoop:
    """AC3: Given epoch in P4 with REVISE, available_transitions → only p3."""

    def _sm_at_p4(self) -> EpochStateMachine:
        sm = _make_sm()
        _advance_to(sm, PhaseId.P4_REVIEW)
        return sm

    def test_at_p4_with_revise_only_p3_available(self) -> None:
        sm = self._sm_at_p4()
        sm.record_vote("A", VoteType.REVISE)

        targets = {t.to_phase for t in sm.available_transitions}
        assert targets == {PhaseId.P3_PROPOSE}

    def test_at_p4_with_revise_on_any_axis_only_p3_available(self) -> None:
        sm = self._sm_at_p4()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.REVISE)

        targets = {t.to_phase for t in sm.available_transitions}
        assert targets == {PhaseId.P3_PROPOSE}

    def test_at_p4_without_votes_no_forward_transition(self) -> None:
        """Without consensus and without REVISE, p5 is NOT available (no votes = not qualified)."""
        sm = self._sm_at_p4()
        # No votes recorded

        targets = {t.to_phase for t in sm.available_transitions}
        # p5 requires consensus (not reached), so only p3 (the non-gated transition) is available.
        assert PhaseId.P5_UAT not in targets

    def test_at_p4_with_all_accept_p5_available(self) -> None:
        sm = self._sm_at_p4()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.ACCEPT)

        targets = {t.to_phase for t in sm.available_transitions}
        # With consensus, p5 is available (and p3 is also a valid transition per spec).
        assert PhaseId.P5_UAT in targets

    def test_at_p10_with_revise_only_p9_available(self) -> None:
        sm = _make_sm()
        _advance_to(sm, PhaseId.P10_CODE_REVIEW)
        sm.record_vote("A", VoteType.REVISE)

        targets = {t.to_phase for t in sm.available_transitions}
        assert targets == {PhaseId.P9_SLICE}

    def test_advance_to_p3_from_p4_allowed_with_revise(self) -> None:
        sm = self._sm_at_p4()
        sm.record_vote("B", VoteType.REVISE)

        # Should not raise
        record = sm.advance(
            PhaseId.P3_PROPOSE, triggered_by="reviewer", condition_met="any reviewer votes REVISE"
        )
        assert record.to_phase == PhaseId.P3_PROPOSE
        assert sm.state.current_phase == PhaseId.P3_PROPOSE


# ─── AC4: BLOCKER Gate ────────────────────────────────────────────────────────


class TestAC4BlockerGate:
    """AC4: Given epoch in P10 with blockers > 0, advance(p11) → TransitionError."""

    def _sm_at_p10(self) -> EpochStateMachine:
        sm = _make_sm()
        _advance_to(sm, PhaseId.P10_CODE_REVIEW)
        return sm

    def test_advance_p10_to_p11_with_blocker_raises(self) -> None:
        sm = self._sm_at_p10()
        sm.record_blocker()  # 1 unresolved blocker
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.ACCEPT)

        with pytest.raises(TransitionError) as exc_info:
            sm.advance(
                PhaseId.P11_IMPL_UAT,
                triggered_by="test",
                condition_met="has blockers",
            )
        assert exc_info.value.violations
        assert "blocker" in exc_info.value.violations[0].lower()

    def test_advance_p10_to_p11_with_resolved_blockers_succeeds(self) -> None:
        sm = self._sm_at_p10()
        sm.record_blocker()   # +1 → count = 1
        sm.record_blocker(resolved=True)  # -1 → count = 0
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.ACCEPT)

        record = sm.advance(
            PhaseId.P11_IMPL_UAT,
            triggered_by="supervisor",
            condition_met="all BLOCKERs resolved",
        )
        assert record.to_phase == PhaseId.P11_IMPL_UAT

    def test_advance_p10_to_p11_without_blockers_and_with_consensus_succeeds(self) -> None:
        sm = self._sm_at_p10()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.ACCEPT)

        record = sm.advance(
            PhaseId.P11_IMPL_UAT,
            triggered_by="supervisor",
            condition_met="all BLOCKERs resolved, all 3 ACCEPT",
        )
        assert record.to_phase == PhaseId.P11_IMPL_UAT

    def test_blocker_count_increments(self) -> None:
        sm = self._sm_at_p10()
        assert sm.state.blocker_count == 0
        sm.record_blocker()
        assert sm.state.blocker_count == 1
        sm.record_blocker()
        assert sm.state.blocker_count == 2

    def test_blocker_count_decrements_on_resolved(self) -> None:
        sm = self._sm_at_p10()
        sm.record_blocker()
        sm.record_blocker()
        sm.record_blocker(resolved=True)
        assert sm.state.blocker_count == 1

    def test_blocker_count_clamped_at_zero(self) -> None:
        sm = self._sm_at_p10()
        sm.record_blocker(resolved=True)  # already at 0
        assert sm.state.blocker_count == 0

    def test_p11_not_in_available_when_blockers_present(self) -> None:
        sm = self._sm_at_p10()
        sm.record_blocker()

        targets = {t.to_phase for t in sm.available_transitions}
        assert PhaseId.P11_IMPL_UAT not in targets

    def test_validate_advance_returns_blocker_violation(self) -> None:
        sm = self._sm_at_p10()
        sm.record_blocker()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.ACCEPT)

        violations = sm.validate_advance(PhaseId.P11_IMPL_UAT)
        assert len(violations) == 1
        assert "blocker" in violations[0].lower()


# ─── Transition History Recording ─────────────────────────────────────────────


class TestTransitionHistory:
    """History must record every transition in order."""

    def test_empty_history_on_init(self) -> None:
        sm = _make_sm()
        assert sm.state.transition_history == []

    def test_history_grows_with_each_advance(self) -> None:
        sm = _make_sm()
        sm.advance(PhaseId.P2_ELICIT, triggered_by="a", condition_met="c")
        sm.advance(PhaseId.P3_PROPOSE, triggered_by="a", condition_met="c")
        assert len(sm.state.transition_history) == 2

    def test_history_records_correct_from_and_to(self) -> None:
        sm = _make_sm()
        sm.advance(PhaseId.P2_ELICIT, triggered_by="a", condition_met="c")
        rec = sm.state.transition_history[0]
        assert rec.from_phase == PhaseId.P1_REQUEST
        assert rec.to_phase == PhaseId.P2_ELICIT

    def test_history_is_in_order(self) -> None:
        sm = _make_sm()
        sm.advance(PhaseId.P2_ELICIT, triggered_by="a", condition_met="c")
        sm.advance(PhaseId.P3_PROPOSE, triggered_by="a", condition_met="c")
        assert sm.state.transition_history[0].to_phase == PhaseId.P2_ELICIT
        assert sm.state.transition_history[1].to_phase == PhaseId.P3_PROPOSE

    def test_failed_advance_does_not_add_to_history(self) -> None:
        sm = _make_sm()
        with pytest.raises(TransitionError):
            sm.advance(PhaseId.P8_IMPL_PLAN, triggered_by="a", condition_met="c")
        assert sm.state.transition_history == []


# ─── Full Sequential Progression ──────────────────────────────────────────────


class TestSequentialProgression:
    """Valid p1→p2→...→p12→complete progresses through all phases."""

    def test_full_forward_progression_reaches_complete(self) -> None:
        sm = _make_sm()
        _advance_to(sm, PhaseId.COMPLETE)
        assert sm.state.current_phase == PhaseId.COMPLETE

    def test_full_progression_records_12_transitions(self) -> None:
        sm = _make_sm()
        _advance_to(sm, PhaseId.COMPLETE)
        # p1→p2, p2→p3, ..., p12→complete = 12 transitions
        assert len(sm.state.transition_history) == 12

    def test_full_progression_completes_all_12_phases(self) -> None:
        sm = _make_sm()
        _advance_to(sm, PhaseId.COMPLETE)
        expected = {p for p in PhaseId if p != PhaseId.COMPLETE}
        assert sm.state.completed_phases == expected

    def test_no_transition_from_complete(self) -> None:
        sm = _make_sm()
        _advance_to(sm, PhaseId.COMPLETE)
        with pytest.raises(TransitionError) as exc_info:
            sm.advance(PhaseId.P1_REQUEST, triggered_by="test", condition_met="restart")
        assert exc_info.value.violations
        assert "COMPLETE" in exc_info.value.violations[0]

    def test_available_transitions_empty_at_complete(self) -> None:
        sm = _make_sm()
        _advance_to(sm, PhaseId.COMPLETE)
        assert sm.available_transitions == []


# ─── Vote Recording and Clearing ──────────────────────────────────────────────


class TestVoteRecording:
    """Votes are phase-scoped and clear on transition."""

    def test_record_vote_stores_vote(self) -> None:
        sm = _make_sm()
        sm.record_vote("A", VoteType.ACCEPT)
        assert sm.state.review_votes["A"] == VoteType.ACCEPT

    def test_record_vote_overwrites_previous(self) -> None:
        sm = _make_sm()
        sm.record_vote("A", VoteType.REVISE)
        sm.record_vote("A", VoteType.ACCEPT)
        assert sm.state.review_votes["A"] == VoteType.ACCEPT

    def test_votes_cleared_after_transition(self) -> None:
        sm = _make_sm()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.advance(PhaseId.P2_ELICIT, triggered_by="test", condition_met="done")
        assert sm.state.review_votes == {}

    def test_invalid_axis_raises_value_error(self) -> None:
        sm = _make_sm()
        with pytest.raises(ValueError):
            sm.record_vote("X", VoteType.ACCEPT)

    def test_record_all_3_axes(self) -> None:
        sm = _make_sm()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.REVISE)
        sm.record_vote("C", VoteType.ACCEPT)
        assert len(sm.state.review_votes) == 3

    def test_has_consensus_false_with_no_votes(self) -> None:
        sm = _make_sm()
        assert sm.has_consensus() is False

    def test_has_consensus_false_with_partial_votes(self) -> None:
        sm = _make_sm()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        assert sm.has_consensus() is False

    def test_has_consensus_false_with_revise(self) -> None:
        sm = _make_sm()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.REVISE)
        assert sm.has_consensus() is False

    def test_has_consensus_true_with_all_accept(self) -> None:
        sm = _make_sm()
        sm.record_vote("A", VoteType.ACCEPT)
        sm.record_vote("B", VoteType.ACCEPT)
        sm.record_vote("C", VoteType.ACCEPT)
        assert sm.has_consensus() is True


# ─── State Property ───────────────────────────────────────────────────────────


class TestStateProperty:
    """state property returns the EpochState instance."""

    def test_state_returns_epoch_state(self) -> None:
        sm = _make_sm("epoch-abc")
        state = sm.state
        assert isinstance(state, EpochState)
        assert state.epoch_id == "epoch-abc"
        assert state.current_phase == PhaseId.P1_REQUEST

    def test_epoch_id_preserved(self) -> None:
        sm = EpochStateMachine("my-epoch-id")
        assert sm.state.epoch_id == "my-epoch-id"


# ─── validate_advance Dry-Run ─────────────────────────────────────────────────


class TestValidateAdvance:
    """validate_advance is a non-mutating dry run."""

    def test_valid_transition_returns_empty(self) -> None:
        sm = _make_sm()
        violations = sm.validate_advance(PhaseId.P2_ELICIT)
        assert violations == []

    def test_invalid_transition_returns_violations(self) -> None:
        sm = _make_sm()
        violations = sm.validate_advance(PhaseId.P8_IMPL_PLAN)
        assert len(violations) == 1

    def test_does_not_mutate_state(self) -> None:
        sm = _make_sm()
        sm.validate_advance(PhaseId.P2_ELICIT)
        assert sm.state.current_phase == PhaseId.P1_REQUEST
        assert sm.state.transition_history == []

    def test_from_complete_returns_violation(self) -> None:
        sm = _make_sm()
        _advance_to(sm, PhaseId.COMPLETE)
        violations = sm.validate_advance(PhaseId.P1_REQUEST)
        assert violations
        assert "COMPLETE" in violations[0]


# ─── last_error Field ─────────────────────────────────────────────────────────


class TestLastError:
    """EpochState.last_error tracks errors and clears on successful advance."""

    def test_last_error_starts_as_none(self) -> None:
        sm = _make_sm()
        assert sm.state.last_error is None

    def test_last_error_is_none_after_successful_advance(self) -> None:
        sm = _make_sm()
        sm.advance(PhaseId.P2_ELICIT, triggered_by="test", condition_met="ok")
        assert sm.state.last_error is None


# ─── Dependency Injection ─────────────────────────────────────────────────────


class TestDependencyInjection:
    """Custom specs can be injected for testing minimal state machines."""

    def test_custom_specs_used(self) -> None:
        from aura_protocol.types import PhaseSpec, RoleId, Transition

        # Minimal 2-phase spec: p1 → p2 → complete
        custom_specs = {
            PhaseId.P1_REQUEST: PhaseSpec(
                id=PhaseId.P1_REQUEST,
                number=1,
                domain=__import__("aura_protocol.types", fromlist=["Domain"]).Domain.USER,
                name="Test Request",
                owner_roles=frozenset({RoleId.EPOCH}),
                transitions=(
                    Transition(
                        to_phase=PhaseId.P2_ELICIT,
                        condition="test condition",
                    ),
                ),
            ),
            PhaseId.P2_ELICIT: PhaseSpec(
                id=PhaseId.P2_ELICIT,
                number=2,
                domain=__import__("aura_protocol.types", fromlist=["Domain"]).Domain.USER,
                name="Test Elicit",
                owner_roles=frozenset({RoleId.EPOCH}),
                transitions=(
                    Transition(
                        to_phase=PhaseId.COMPLETE,
                        condition="done",
                    ),
                ),
            ),
        }

        sm = EpochStateMachine("di-test", specs=custom_specs)
        sm.advance(PhaseId.P2_ELICIT, triggered_by="test", condition_met="test condition")
        sm.advance(PhaseId.COMPLETE, triggered_by="test", condition_met="done")
        assert sm.state.current_phase == PhaseId.COMPLETE

    def test_default_specs_are_phase_specs(self) -> None:
        from aura_protocol.types import PHASE_SPECS
        sm = _make_sm()
        # The machine starts at p1 and p2 must be in PHASE_SPECS
        assert PhaseId.P1_REQUEST in PHASE_SPECS
        violations = sm.validate_advance(PhaseId.P2_ELICIT)
        assert violations == []
