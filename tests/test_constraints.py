"""Tests for aura_protocol.constraints — Runtime constraint validators.

BDD Acceptance Criteria:
    AC5: Given RuntimeConstraintChecker when checking violated state then
         returns ConstraintViolation list should not silently pass violations.

Coverage:
    - ConstraintViolation dataclass: frozen, fields, context dict
    - RuntimeConstraintChecker: DI constructor, default specs
    - check_state_constraints: aggregates 5 state-based checks, no short-circuit
    - check_transition_constraints: combines transition-specific checks
    - check_transition: backwards-compat alias for check_transition_constraints
    - check_review_consensus: C-review-consensus (p4/p10 must have 3 ACCEPT)
    - check_dep_direction: C-dep-direction (non-empty, distinct IDs)
    - check_severity_tree: C-severity-eager / C-severity-not-plan (p4/p10 rules)
    - check_handoff_required: C-handoff-skill-invocation (actor-change transitions)
    - check_blocker_gate: C-worker-gates (p10 with unresolved blockers)
    - check_audit_trail: C-audit-never-delete / C-audit-dep-chain
    - check_role_ownership: C-vertical-slices (known role check)
    - check_review_binary: C-review-binary (ACCEPT/REVISE only)
    - check_blocker_dual_parent: C-blocker-dual-parent
    - check_proposal_naming: C-proposal-naming
    - check_review_naming: C-review-naming
    - check_slice_has_leaf_tasks: C-slice-leaf-tasks
    - check_ure_verbatim: C-ure-verbatim
    - check_followup_timing: C-followup-timing
    - check_agent_commit: C-agent-commit
    - check_frontmatter_refs: C-frontmatter-refs
    - check_supervisor_no_impl: C-supervisor-no-impl
    - check_followup_lifecycle: C-followup-lifecycle
    - check_followup_leaf_adoption: C-followup-leaf-adoption
    - check_worker_gates: C-worker-gates
    - check_supervisor_explore_team: C-supervisor-explore-team
    - check_vertical_slices: C-vertical-slices
    - Edge cases: no violations returns empty list
    - Each violation has correct constraint_id
"""

from __future__ import annotations

import pytest

from aura_protocol.constraints import ConstraintViolation, RuntimeConstraintChecker
from aura_protocol.state_machine import EpochState, EpochStateMachine, TransitionRecord
from aura_protocol.types import (
    CONSTRAINT_SPECS,
    PhaseId,
    RoleId,
    VoteType,
)
from datetime import datetime, timezone


# ─── Helpers ──────────────────────────────────────────────────────────────────


def _make_state(
    phase: PhaseId = PhaseId.P1_REQUEST,
    epoch_id: str = "test-epoch",
    **kwargs,
) -> EpochState:
    """Return a fresh EpochState at the given phase."""
    return EpochState(epoch_id=epoch_id, current_phase=phase, **kwargs)


def _make_state_at_p4_with_votes(**votes: VoteType) -> EpochState:
    """Return an EpochState at P4_REVIEW with the given axis->vote mapping."""
    state = _make_state(phase=PhaseId.P4_REVIEW)
    state.review_votes.update(votes)
    return state


def _make_state_at_p10_with_votes(**votes: VoteType) -> EpochState:
    """Return an EpochState at P10_CODE_REVIEW with the given axis->vote mapping."""
    state = _make_state(phase=PhaseId.P10_CODE_REVIEW)
    state.review_votes.update(votes)
    return state


def _make_checker() -> RuntimeConstraintChecker:
    """Return a RuntimeConstraintChecker with canonical specs."""
    return RuntimeConstraintChecker()


def _all_accept_state(phase: PhaseId) -> EpochState:
    """Return an EpochState at the given phase with all 3 axes ACCEPT."""
    state = _make_state(phase=phase)
    state.review_votes = {"A": VoteType.ACCEPT, "B": VoteType.ACCEPT, "C": VoteType.ACCEPT}
    return state


# ─── ConstraintViolation Dataclass ────────────────────────────────────────────


class TestConstraintViolation:
    """ConstraintViolation is a frozen dataclass with constraint_id, message, context."""

    def test_construction_with_required_fields(self) -> None:
        v = ConstraintViolation(
            constraint_id="C-review-consensus",
            message="All 3 must ACCEPT",
        )
        assert v.constraint_id == "C-review-consensus"
        assert v.message == "All 3 must ACCEPT"
        assert v.context == {}

    def test_construction_with_context(self) -> None:
        v = ConstraintViolation(
            constraint_id="C-dep-direction",
            message="Parent ID required",
            context={"parent_id": "abc", "child_id": "def"},
        )
        assert v.context == {"parent_id": "abc", "child_id": "def"}

    def test_is_frozen(self) -> None:
        v = ConstraintViolation(constraint_id="C-test", message="test")
        with pytest.raises(Exception):
            v.constraint_id = "mutate"  # type: ignore[misc]

    def test_equality(self) -> None:
        v1 = ConstraintViolation(constraint_id="C-x", message="m", context={"k": "v"})
        v2 = ConstraintViolation(constraint_id="C-x", message="m", context={"k": "v"})
        assert v1 == v2

    def test_inequality_on_different_id(self) -> None:
        v1 = ConstraintViolation(constraint_id="C-x", message="m")
        v2 = ConstraintViolation(constraint_id="C-y", message="m")
        assert v1 != v2

    def test_constraint_id_field_name(self) -> None:
        """constraint_id must be the field name (not 'id') per spec."""
        v = ConstraintViolation(constraint_id="C-audit-never-delete", message="m")
        assert hasattr(v, "constraint_id")
        assert not hasattr(v, "id")

    def test_context_defaults_to_empty_dict(self) -> None:
        v = ConstraintViolation(constraint_id="C-x", message="m")
        assert isinstance(v.context, dict)
        assert len(v.context) == 0


# ─── RuntimeConstraintChecker Constructor ─────────────────────────────────────


class TestRuntimeConstraintCheckerConstructor:
    """Constructor accepts optional constraint_specs for DI."""

    def test_default_constructor_uses_canonical_specs(self) -> None:
        checker = RuntimeConstraintChecker()
        # Should work without error and use CONSTRAINT_SPECS
        assert checker is not None

    def test_custom_constraint_specs_accepted(self) -> None:
        from aura_protocol.types import ConstraintSpec
        custom = {
            "C-test": ConstraintSpec(
                id="C-test",
                given="test",
                when="testing",
                then="pass",
                should_not="fail",
            )
        }
        checker = RuntimeConstraintChecker(constraint_specs=custom)
        assert checker is not None

    def test_none_specs_uses_canonical(self) -> None:
        checker = RuntimeConstraintChecker(constraint_specs=None)
        # Should not raise
        state = _make_state()
        result = checker.check_review_consensus(state)
        assert isinstance(result, list)

    def test_custom_handoff_specs_accepted(self) -> None:
        from aura_protocol.types import HandoffSpec, RoleId
        custom_handoffs = {
            "h-test": HandoffSpec(
                id="h-test",
                source_role=RoleId.ARCHITECT,
                target_role=RoleId.SUPERVISOR,
                at_phase=PhaseId.P7_HANDOFF,
                content_level="summary-with-ids",
                required_fields=("request",),
            )
        }
        checker = RuntimeConstraintChecker(handoff_specs=custom_handoffs)
        assert checker is not None


# ─── AC5: check_state_constraints Aggregation ─────────────────────────────────


class TestAC5CheckStateConstraints:
    """AC5: Given violated state, check_state_constraints returns non-empty ConstraintViolation list."""

    def test_check_state_constraints_returns_list(self) -> None:
        checker = _make_checker()
        state = _make_state()
        result = checker.check_state_constraints(state)
        assert isinstance(result, list)

    def test_check_state_constraints_returns_violations_for_p4_without_consensus(self) -> None:
        """At p4 with no votes, check_state_constraints should include C-review-consensus violation."""
        checker = _make_checker()
        state = _make_state_at_p4_with_votes()  # no votes
        violations = checker.check_state_constraints(state)
        constraint_ids = {v.constraint_id for v in violations}
        assert "C-review-consensus" in constraint_ids

    def test_check_state_constraints_returns_violations_for_p10_with_blockers(self) -> None:
        """At p10 with blockers, check_state_constraints should include C-worker-gates violation."""
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW, blocker_count=2)
        violations = checker.check_state_constraints(state)
        constraint_ids = {v.constraint_id for v in violations}
        assert "C-worker-gates" in constraint_ids

    def test_check_state_constraints_returns_empty_for_clean_p1_state(self) -> None:
        """A fresh p1 state with no violations should return empty list."""
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P1_REQUEST)
        violations = checker.check_state_constraints(state)
        assert violations == []

    def test_check_state_constraints_does_not_short_circuit(self) -> None:
        """check_state_constraints must aggregate ALL violations — not stop at first."""
        checker = _make_checker()
        # p10 with blockers AND no consensus — should get both violations
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW, blocker_count=3)
        # no votes recorded
        violations = checker.check_state_constraints(state)
        constraint_ids = {v.constraint_id for v in violations}
        # Both C-review-consensus and C-worker-gates should appear
        assert "C-review-consensus" in constraint_ids
        assert "C-worker-gates" in constraint_ids

    def test_check_state_constraints_violations_have_non_empty_messages(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P4_REVIEW)
        violations = checker.check_state_constraints(state)
        for v in violations:
            assert v.message, f"Empty message in violation: {v.constraint_id}"

    def test_check_state_constraints_violations_have_valid_constraint_ids(self) -> None:
        """All violation constraint_ids must match a known C-* constraint."""
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P4_REVIEW, blocker_count=1)
        violations = checker.check_state_constraints(state)
        for v in violations:
            assert v.constraint_id in CONSTRAINT_SPECS, (
                f"Unknown constraint_id: {v.constraint_id!r}"
            )


# ─── check_transition_constraints ────────────────────────────────────────────


class TestCheckTransitionConstraints:
    """check_transition_constraints validates constraints for proposed phase transitions."""

    def test_p4_to_p5_without_consensus_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state_at_p4_with_votes(A=VoteType.ACCEPT)  # only 1 axis
        violations = checker.check_transition_constraints(state, PhaseId.P5_UAT)
        ids = {v.constraint_id for v in violations}
        assert "C-review-consensus" in ids

    def test_p4_to_p5_with_consensus_returns_no_consensus_violation(self) -> None:
        checker = _make_checker()
        state = _all_accept_state(PhaseId.P4_REVIEW)
        violations = checker.check_transition_constraints(state, PhaseId.P5_UAT)
        ids = {v.constraint_id for v in violations}
        assert "C-review-consensus" not in ids

    def test_p10_to_p11_without_consensus_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state_at_p10_with_votes(A=VoteType.ACCEPT, B=VoteType.ACCEPT)
        violations = checker.check_transition_constraints(state, PhaseId.P11_IMPL_UAT)
        ids = {v.constraint_id for v in violations}
        assert "C-review-consensus" in ids

    def test_p10_to_p11_with_consensus_returns_no_consensus_violation(self) -> None:
        checker = _make_checker()
        state = _all_accept_state(PhaseId.P10_CODE_REVIEW)
        violations = checker.check_transition_constraints(state, PhaseId.P11_IMPL_UAT)
        ids = {v.constraint_id for v in violations}
        assert "C-review-consensus" not in ids

    def test_p1_to_p2_returns_no_violations(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P1_REQUEST)
        violations = checker.check_transition_constraints(state, PhaseId.P2_ELICIT)
        assert violations == []

    def test_handoff_required_transition_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P7_HANDOFF)
        violations = checker.check_transition_constraints(state, PhaseId.P8_IMPL_PLAN)
        ids = {v.constraint_id for v in violations}
        assert "C-handoff-skill-invocation" in ids

    def test_same_actor_transition_returns_no_handoff_violation(self) -> None:
        checker = _make_checker()
        # p5→p6 and p6→p7 are same-actor (no handoff needed)
        state = _make_state(phase=PhaseId.P5_UAT)
        violations = checker.check_transition_constraints(state, PhaseId.P6_RATIFY)
        ids = {v.constraint_id for v in violations}
        assert "C-handoff-skill-invocation" not in ids

    def test_p10_to_p11_with_blockers_returns_blocker_gate_violation(self) -> None:
        """p10→p11 transition is blocked while blocker_count > 0."""
        checker = _make_checker()
        state = _all_accept_state(PhaseId.P10_CODE_REVIEW)
        state.blocker_count = 2
        violations = checker.check_transition_constraints(state, PhaseId.P11_IMPL_UAT)
        ids = {v.constraint_id for v in violations}
        assert "C-worker-gates" in ids

    def test_p10_to_p11_with_zero_blockers_no_blocker_gate_violation(self) -> None:
        """p10→p11 is not blocked when blocker_count is 0."""
        checker = _make_checker()
        state = _all_accept_state(PhaseId.P10_CODE_REVIEW)
        state.blocker_count = 0
        violations = checker.check_transition_constraints(state, PhaseId.P11_IMPL_UAT)
        ids = {v.constraint_id for v in violations}
        assert "C-worker-gates" not in ids

    def test_does_not_short_circuit(self) -> None:
        """check_transition_constraints must aggregate all transition violations."""
        checker = _make_checker()
        # p10→p11 with no consensus AND blockers: both violations should appear
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW, blocker_count=3)
        # no votes recorded
        violations = checker.check_transition_constraints(state, PhaseId.P11_IMPL_UAT)
        ids = {v.constraint_id for v in violations}
        assert "C-review-consensus" in ids
        assert "C-worker-gates" in ids

    def test_returns_list(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P1_REQUEST)
        result = checker.check_transition_constraints(state, PhaseId.P2_ELICIT)
        assert isinstance(result, list)


# ─── check_transition (backwards-compat alias) ────────────────────────────────


class TestCheckTransition:
    """check_transition is a backwards-compat alias for check_transition_constraints."""

    def test_p4_to_p5_without_consensus_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state_at_p4_with_votes(A=VoteType.ACCEPT)  # only 1 axis
        violations = checker.check_transition(state, PhaseId.P5_UAT)
        ids = {v.constraint_id for v in violations}
        assert "C-review-consensus" in ids

    def test_p4_to_p5_with_consensus_returns_no_consensus_violation(self) -> None:
        checker = _make_checker()
        state = _all_accept_state(PhaseId.P4_REVIEW)
        violations = checker.check_transition(state, PhaseId.P5_UAT)
        ids = {v.constraint_id for v in violations}
        assert "C-review-consensus" not in ids

    def test_p10_to_p11_without_consensus_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state_at_p10_with_votes(A=VoteType.ACCEPT, B=VoteType.ACCEPT)
        violations = checker.check_transition(state, PhaseId.P11_IMPL_UAT)
        ids = {v.constraint_id for v in violations}
        assert "C-review-consensus" in ids

    def test_p10_to_p11_with_consensus_returns_no_consensus_violation(self) -> None:
        checker = _make_checker()
        state = _all_accept_state(PhaseId.P10_CODE_REVIEW)
        violations = checker.check_transition(state, PhaseId.P11_IMPL_UAT)
        ids = {v.constraint_id for v in violations}
        assert "C-review-consensus" not in ids

    def test_p1_to_p2_returns_no_violations(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P1_REQUEST)
        violations = checker.check_transition(state, PhaseId.P2_ELICIT)
        assert violations == []

    def test_handoff_required_transition_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P7_HANDOFF)
        violations = checker.check_transition(state, PhaseId.P8_IMPL_PLAN)
        ids = {v.constraint_id for v in violations}
        assert "C-handoff-skill-invocation" in ids

    def test_same_actor_transition_returns_no_handoff_violation(self) -> None:
        checker = _make_checker()
        # p5→p6 and p6→p7 are same-actor (no handoff needed)
        state = _make_state(phase=PhaseId.P5_UAT)
        violations = checker.check_transition(state, PhaseId.P6_RATIFY)
        ids = {v.constraint_id for v in violations}
        assert "C-handoff-skill-invocation" not in ids

    def test_delegates_to_check_transition_constraints(self) -> None:
        """check_transition must produce the same result as check_transition_constraints."""
        checker = _make_checker()
        state = _make_state_at_p4_with_votes(A=VoteType.ACCEPT)
        assert checker.check_transition(state, PhaseId.P5_UAT) == \
            checker.check_transition_constraints(state, PhaseId.P5_UAT)


# ─── C-review-consensus ───────────────────────────────────────────────────────


class TestCheckReviewConsensus:
    """C-review-consensus: all 3 axes must ACCEPT in review phases."""

    def test_p4_no_votes_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P4_REVIEW)
        violations = checker.check_review_consensus(state)
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-review-consensus"

    def test_p4_partial_votes_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state_at_p4_with_votes(A=VoteType.ACCEPT, B=VoteType.ACCEPT)
        violations = checker.check_review_consensus(state)
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-review-consensus"

    def test_p4_with_revise_vote_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state_at_p4_with_votes(
            A=VoteType.ACCEPT, B=VoteType.ACCEPT, C=VoteType.REVISE
        )
        violations = checker.check_review_consensus(state)
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-review-consensus"

    def test_p4_all_accept_returns_empty(self) -> None:
        checker = _make_checker()
        state = _all_accept_state(PhaseId.P4_REVIEW)
        violations = checker.check_review_consensus(state)
        assert violations == []

    def test_p10_no_votes_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW)
        violations = checker.check_review_consensus(state)
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-review-consensus"

    def test_p10_all_accept_returns_empty(self) -> None:
        checker = _make_checker()
        state = _all_accept_state(PhaseId.P10_CODE_REVIEW)
        violations = checker.check_review_consensus(state)
        assert violations == []

    def test_non_review_phase_returns_empty(self) -> None:
        checker = _make_checker()
        for phase in (
            PhaseId.P1_REQUEST, PhaseId.P2_ELICIT, PhaseId.P3_PROPOSE,
            PhaseId.P5_UAT, PhaseId.P9_SLICE, PhaseId.P12_LANDING,
        ):
            state = _make_state(phase=phase)
            violations = checker.check_review_consensus(state)
            assert violations == [], f"Unexpected violation at {phase}"

    def test_violation_message_mentions_consensus(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P4_REVIEW)
        violations = checker.check_review_consensus(state)
        assert "consensus" in violations[0].message.lower() or "accept" in violations[0].message.lower()

    def test_violation_context_contains_phase(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P4_REVIEW)
        violations = checker.check_review_consensus(state)
        assert "phase" in violations[0].context
        assert violations[0].context["phase"] == "p4"


# ─── C-dep-direction ──────────────────────────────────────────────────────────


class TestCheckDepDirection:
    """C-dep-direction: validate dependency direction inputs."""

    def test_valid_different_ids_returns_empty(self) -> None:
        checker = _make_checker()
        violations = checker.check_dep_direction("parent-123", "child-456")
        assert violations == []

    def test_same_ids_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_dep_direction("task-abc", "task-abc")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-dep-direction"

    def test_empty_parent_id_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_dep_direction("", "child-456")
        assert len(violations) >= 1
        ids = {v.constraint_id for v in violations}
        assert "C-dep-direction" in ids

    def test_empty_child_id_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_dep_direction("parent-123", "")
        assert len(violations) >= 1
        ids = {v.constraint_id for v in violations}
        assert "C-dep-direction" in ids

    def test_whitespace_only_parent_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_dep_direction("   ", "child-456")
        ids = {v.constraint_id for v in violations}
        assert "C-dep-direction" in ids

    def test_violation_context_contains_both_ids(self) -> None:
        checker = _make_checker()
        violations = checker.check_dep_direction("same", "same")
        ctx = violations[0].context
        assert "parent_id" in ctx
        assert "child_id" in ctx


# ─── C-severity-eager / C-severity-not-plan ───────────────────────────────────


class TestCheckSeverityTree:
    """C-severity-eager / C-severity-not-plan: severity tree rules."""

    def test_p4_returns_violation_for_severity_not_plan(self) -> None:
        """Plan review (p4) must NOT have severity trees."""
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P4_REVIEW)
        violations = checker.check_severity_tree(state)
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-severity-not-plan"

    def test_non_review_phase_returns_empty(self) -> None:
        checker = _make_checker()
        for phase in (
            PhaseId.P1_REQUEST, PhaseId.P2_ELICIT, PhaseId.P3_PROPOSE,
            PhaseId.P5_UAT, PhaseId.P8_IMPL_PLAN, PhaseId.P9_SLICE,
        ):
            state = _make_state(phase=phase)
            violations = checker.check_severity_tree(state)
            assert violations == [], f"Unexpected violation at {phase}"

    def test_p10_returns_empty(self) -> None:
        """p10 is the correct phase for severity trees — no violation from check_severity_tree."""
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW)
        violations = checker.check_severity_tree(state)
        # check_severity_tree doesn't mandate creation — it prevents severity trees in p4
        assert violations == []

    def test_severity_not_plan_violation_mentions_plan_review(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P4_REVIEW)
        violations = checker.check_severity_tree(state)
        assert "p4" in violations[0].message or "plan" in violations[0].message.lower()

    def test_severity_not_plan_violation_context_has_phase(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P4_REVIEW)
        violations = checker.check_severity_tree(state)
        assert violations[0].context.get("phase") == "p4"


# ─── C-handoff-skill-invocation ───────────────────────────────────────────────


class TestCheckHandoffRequired:
    """C-handoff-skill-invocation: actor-change transitions require handoff."""

    def test_p7_to_p8_requires_handoff(self) -> None:
        checker = _make_checker()
        violations = checker.check_handoff_required(PhaseId.P7_HANDOFF, PhaseId.P8_IMPL_PLAN)
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-handoff-skill-invocation"

    def test_p9_to_p10_requires_handoff(self) -> None:
        checker = _make_checker()
        violations = checker.check_handoff_required(PhaseId.P9_SLICE, PhaseId.P10_CODE_REVIEW)
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-handoff-skill-invocation"

    def test_p5_to_p6_same_actor_no_handoff(self) -> None:
        checker = _make_checker()
        violations = checker.check_handoff_required(PhaseId.P5_UAT, PhaseId.P6_RATIFY)
        assert violations == []

    def test_p6_to_p7_same_actor_no_handoff(self) -> None:
        checker = _make_checker()
        violations = checker.check_handoff_required(PhaseId.P6_RATIFY, PhaseId.P7_HANDOFF)
        assert violations == []

    def test_non_actor_change_transitions_no_handoff(self) -> None:
        checker = _make_checker()
        for from_p, to_p in (
            (PhaseId.P1_REQUEST, PhaseId.P2_ELICIT),
            (PhaseId.P2_ELICIT, PhaseId.P3_PROPOSE),
            (PhaseId.P3_PROPOSE, PhaseId.P4_REVIEW),
        ):
            violations = checker.check_handoff_required(from_p, to_p)
            assert violations == [], f"Unexpected handoff violation for {from_p} -> {to_p}"

    def test_violation_context_contains_from_and_to_phase(self) -> None:
        checker = _make_checker()
        violations = checker.check_handoff_required(PhaseId.P7_HANDOFF, PhaseId.P8_IMPL_PLAN)
        ctx = violations[0].context
        assert ctx.get("from_phase") == "p7"
        assert ctx.get("to_phase") == "p8"

    def test_violation_message_mentions_skill_invocation(self) -> None:
        checker = _make_checker()
        violations = checker.check_handoff_required(PhaseId.P7_HANDOFF, PhaseId.P8_IMPL_PLAN)
        msg = violations[0].message.lower()
        assert "skill" in msg or "handoff" in msg


# ─── C-worker-gates (blocker gate) ────────────────────────────────────────────


class TestCheckBlockerGate:
    """check_blocker_gate: p10 with unresolved blockers yields C-worker-gates violation."""

    def test_p10_with_blockers_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW, blocker_count=1)
        violations = checker.check_blocker_gate(state)
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-worker-gates"

    def test_p10_with_zero_blockers_returns_empty(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW, blocker_count=0)
        violations = checker.check_blocker_gate(state)
        assert violations == []

    def test_non_p10_with_blockers_returns_empty(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P9_SLICE, blocker_count=5)
        violations = checker.check_blocker_gate(state)
        assert violations == []

    def test_violation_context_contains_blocker_count(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW, blocker_count=3)
        violations = checker.check_blocker_gate(state)
        assert violations[0].context.get("blocker_count") == "3"

    def test_violation_message_mentions_blocker(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW, blocker_count=2)
        violations = checker.check_blocker_gate(state)
        assert "blocker" in violations[0].message.lower()


# ─── C-audit-never-delete / C-audit-dep-chain ─────────────────────────────────


class TestCheckAuditTrail:
    """C-audit-never-delete / C-audit-dep-chain: audit trail integrity."""

    def test_p2_with_empty_history_returns_violation(self) -> None:
        checker = _make_checker()
        # At p2 but no transitions recorded — audit trail problem
        state = _make_state(phase=PhaseId.P2_ELICIT)
        state.transition_history.clear()
        violations = checker.check_audit_trail(state)
        ids = {v.constraint_id for v in violations}
        assert "C-audit-never-delete" in ids

    def test_p1_with_empty_history_no_violation(self) -> None:
        checker = _make_checker()
        # At p1 (start), empty history is expected
        state = _make_state(phase=PhaseId.P1_REQUEST)
        violations = checker.check_audit_trail(state)
        ids = {v.constraint_id for v in violations}
        assert "C-audit-never-delete" not in ids

    def test_transition_record_missing_triggered_by_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P2_ELICIT)
        record = TransitionRecord(
            from_phase=PhaseId.P1_REQUEST,
            to_phase=PhaseId.P2_ELICIT,
            timestamp=datetime.now(tz=timezone.utc),
            triggered_by="",  # missing
            condition_met="test condition",
        )
        state.transition_history.append(record)
        violations = checker.check_audit_trail(state)
        ids = {v.constraint_id for v in violations}
        assert "C-audit-dep-chain" in ids

    def test_transition_record_missing_condition_met_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P2_ELICIT)
        record = TransitionRecord(
            from_phase=PhaseId.P1_REQUEST,
            to_phase=PhaseId.P2_ELICIT,
            timestamp=datetime.now(tz=timezone.utc),
            triggered_by="architect",
            condition_met="",  # missing
        )
        state.transition_history.append(record)
        violations = checker.check_audit_trail(state)
        ids = {v.constraint_id for v in violations}
        assert "C-audit-dep-chain" in ids

    def test_valid_history_returns_empty(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P2_ELICIT)
        record = TransitionRecord(
            from_phase=PhaseId.P1_REQUEST,
            to_phase=PhaseId.P2_ELICIT,
            timestamp=datetime.now(tz=timezone.utc),
            triggered_by="architect",
            condition_met="classification confirmed",
        )
        state.transition_history.append(record)
        violations = checker.check_audit_trail(state)
        assert violations == []


# ─── C-vertical-slices (role ownership) ───────────────────────────────────────


class TestCheckRoleOwnership:
    """check_role_ownership: validates role-phase consistency."""

    def test_valid_worker_role_returns_empty(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P9_SLICE, current_role=RoleId.WORKER)
        violations = checker.check_role_ownership(state)
        assert violations == []

    def test_valid_supervisor_role_returns_empty(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P8_IMPL_PLAN, current_role=RoleId.SUPERVISOR)
        violations = checker.check_role_ownership(state)
        assert violations == []

    def test_unknown_role_returns_violation(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P9_SLICE, current_role="unknown-role")
        violations = checker.check_role_ownership(state)
        assert len(violations) >= 1
        ids = {v.constraint_id for v in violations}
        assert "C-vertical-slices" in ids

    def test_all_valid_roles_return_empty(self) -> None:
        checker = _make_checker()
        for role in RoleId:
            state = _make_state(current_role=role)
            violations = checker.check_role_ownership(state)
            assert violations == [], f"Unexpected violation for role {role!r}"


# ─── C-review-binary ──────────────────────────────────────────────────────────


class TestCheckReviewBinary:
    """C-review-binary: votes must be ACCEPT or REVISE only."""

    def test_accept_vote_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_review_binary(VoteType.ACCEPT) == []

    def test_revise_vote_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_review_binary(VoteType.REVISE) == []

    def test_approve_vote_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_review_binary("APPROVE")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-review-binary"

    def test_approve_with_comments_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_review_binary("APPROVE_WITH_COMMENTS")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-review-binary"

    def test_request_changes_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_review_binary("REQUEST_CHANGES")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-review-binary"

    def test_reject_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_review_binary("REJECT")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-review-binary"

    def test_violation_context_contains_vote(self) -> None:
        checker = _make_checker()
        violations = checker.check_review_binary("APPROVE")
        assert violations[0].context.get("vote") == "APPROVE"

    def test_violation_message_mentions_accept_and_revise(self) -> None:
        checker = _make_checker()
        violations = checker.check_review_binary("APPROVE")
        msg = violations[0].message
        assert "ACCEPT" in msg and "REVISE" in msg


# ─── C-blocker-dual-parent ────────────────────────────────────────────────────


class TestCheckBlockerDualParent:
    """C-blocker-dual-parent: BLOCKER findings must have severity group AND slice as parents."""

    def test_valid_dual_parent_returns_empty(self) -> None:
        checker = _make_checker()
        violations = checker.check_blocker_dual_parent(
            "blocker-task-abc",
            severity_group_id="severity-group-1",
            slice_id="slice-3",
        )
        assert violations == []

    def test_missing_severity_group_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_blocker_dual_parent("blocker-abc", "", "slice-3")
        ids = {v.constraint_id for v in violations}
        assert "C-blocker-dual-parent" in ids

    def test_missing_slice_id_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_blocker_dual_parent("blocker-abc", "severity-group-1", "")
        ids = {v.constraint_id for v in violations}
        assert "C-blocker-dual-parent" in ids

    def test_same_severity_group_and_slice_id_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_blocker_dual_parent(
            "blocker-abc", "same-task", "same-task"
        )
        ids = {v.constraint_id for v in violations}
        assert "C-blocker-dual-parent" in ids

    def test_violation_message_mentions_dual_parent(self) -> None:
        checker = _make_checker()
        violations = checker.check_blocker_dual_parent("blocker-abc", "", "slice-3")
        assert any("severity" in v.message.lower() or "group" in v.message.lower() for v in violations)


# ─── C-proposal-naming ────────────────────────────────────────────────────────


class TestCheckProposalNaming:
    """C-proposal-naming: proposal titles must follow PROPOSAL-{N}: pattern."""

    def test_valid_proposal_1_title_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_proposal_naming("PROPOSAL-1: Some description") == []

    def test_valid_proposal_10_title_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_proposal_naming("PROPOSAL-10: Another proposal") == []

    def test_missing_number_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_proposal_naming("PROPOSAL: Bad title")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-proposal-naming"

    def test_lowercase_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_proposal_naming("proposal-1: lower case")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-proposal-naming"

    def test_impl_plan_title_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_proposal_naming("IMPL_PLAN: Not a proposal")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-proposal-naming"

    def test_violation_context_contains_title(self) -> None:
        checker = _make_checker()
        title = "BAD TITLE"
        violations = checker.check_proposal_naming(title)
        assert violations[0].context.get("title") == title


# ─── C-review-naming ──────────────────────────────────────────────────────────


class TestCheckReviewNaming:
    """C-review-naming: review task titles must follow {SCOPE}-REVIEW-{axis}-{round} pattern."""

    def test_valid_review_title_axis_a_round_1(self) -> None:
        checker = _make_checker()
        assert checker.check_review_naming("PROPOSAL-1-REVIEW-A-1: Description") == []

    def test_valid_review_title_axis_b_round_2(self) -> None:
        checker = _make_checker()
        assert checker.check_review_naming("SLICE-3-REVIEW-B-2: Something") == []

    def test_valid_review_title_axis_c(self) -> None:
        checker = _make_checker()
        assert checker.check_review_naming("IMPL-REVIEW-C-1: description") == []

    def test_numeric_reviewer_id_instead_of_axis_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_review_naming("PROPOSAL-1-REVIEW-1-1: Bad axis")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-review-naming"

    def test_missing_round_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_review_naming("PROPOSAL-1-REVIEW-A: No round")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-review-naming"

    def test_violation_context_contains_title(self) -> None:
        checker = _make_checker()
        bad_title = "BAD-REVIEW-1-1: Numeric axis"
        violations = checker.check_review_naming(bad_title)
        assert violations[0].context.get("title") == bad_title


# ─── C-slice-leaf-tasks ───────────────────────────────────────────────────────


class TestCheckSliceLeafTasks:
    """C-slice-leaf-tasks: every slice must have leaf tasks."""

    def test_with_leaf_tasks_returns_empty(self) -> None:
        checker = _make_checker()
        violations = checker.check_slice_has_leaf_tasks(
            "slice-3",
            ["leaf-l1", "leaf-l2", "leaf-l3"],
        )
        assert violations == []

    def test_empty_leaf_list_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_slice_has_leaf_tasks("slice-3", [])
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-slice-leaf-tasks"

    def test_violation_context_contains_slice_id(self) -> None:
        checker = _make_checker()
        violations = checker.check_slice_has_leaf_tasks("my-slice-abc", [])
        assert violations[0].context.get("slice_id") == "my-slice-abc"

    def test_violation_message_mentions_leaf_tasks(self) -> None:
        checker = _make_checker()
        violations = checker.check_slice_has_leaf_tasks("slice-1", [])
        assert "leaf" in violations[0].message.lower()


# ─── C-ure-verbatim ───────────────────────────────────────────────────────────


class TestCheckUreVerbatim:
    """C-ure-verbatim: user interview records must include question, options, response."""

    def test_complete_record_returns_empty(self) -> None:
        checker = _make_checker()
        violations = checker.check_ure_verbatim(
            question="What is your preference?",
            options=["Option A: Use library X", "Option B: Use library Y"],
            response="Option A: Use library X because it is simpler.",
        )
        assert violations == []

    def test_missing_question_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_ure_verbatim("", ["Option A"], "Option A")
        ids = {v.constraint_id for v in violations}
        assert "C-ure-verbatim" in ids

    def test_empty_options_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_ure_verbatim("Question?", [], "My answer")
        ids = {v.constraint_id for v in violations}
        assert "C-ure-verbatim" in ids

    def test_missing_response_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_ure_verbatim("Question?", ["Option A"], "")
        ids = {v.constraint_id for v in violations}
        assert "C-ure-verbatim" in ids

    def test_all_missing_returns_3_violations(self) -> None:
        checker = _make_checker()
        violations = checker.check_ure_verbatim("", [], "")
        assert len(violations) == 3

    def test_violation_context_contains_field_name(self) -> None:
        checker = _make_checker()
        violations = checker.check_ure_verbatim("", ["Option A"], "answer")
        fields = [v.context.get("field") for v in violations]
        assert "question" in fields


# ─── C-followup-timing ────────────────────────────────────────────────────────


class TestCheckFollowupTiming:
    """C-followup-timing: follow-up epic must be created immediately when findings exist."""

    def test_no_findings_no_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_followup_timing(
            has_important_or_minor=False, followup_created=False
        )
        assert violations == []

    def test_findings_with_followup_created_no_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_followup_timing(
            has_important_or_minor=True, followup_created=True
        )
        assert violations == []

    def test_findings_without_followup_created_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_followup_timing(
            has_important_or_minor=True, followup_created=False
        )
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-followup-timing"

    def test_violation_message_mentions_blocker_gate(self) -> None:
        checker = _make_checker()
        violations = checker.check_followup_timing(True, False)
        msg = violations[0].message.lower()
        assert "blocker" in msg or "followup" in msg or "epic" in msg


# ─── C-agent-commit ───────────────────────────────────────────────────────────


class TestCheckAgentCommit:
    """C-agent-commit: commits must use 'git agent-commit'."""

    def test_agent_commit_command_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_agent_commit("git agent-commit -m 'feat: something'") == []

    def test_git_commit_command_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_agent_commit("git commit -m 'feat: something'")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-agent-commit"

    def test_unrelated_command_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_agent_commit("git push origin main") == []

    def test_violation_message_mentions_agent_commit(self) -> None:
        checker = _make_checker()
        violations = checker.check_agent_commit("git commit -m 'bad'")
        assert "agent-commit" in violations[0].message

    def test_violation_context_contains_command(self) -> None:
        checker = _make_checker()
        cmd = "git commit -m 'bad'"
        violations = checker.check_agent_commit(cmd)
        assert violations[0].context.get("command") == cmd


# ─── C-frontmatter-refs ───────────────────────────────────────────────────────


class TestCheckFrontmatterRefs:
    """C-frontmatter-refs: task descriptions must use YAML frontmatter for cross-task refs."""

    def test_valid_frontmatter_with_all_keys_returns_empty(self) -> None:
        checker = _make_checker()
        desc = "---\nreferences:\n  urd: abc-123\n  request: def-456\n---\n## Content"
        violations = checker.check_frontmatter_refs(desc, ["urd", "request"])
        assert violations == []

    def test_missing_key_returns_violation(self) -> None:
        checker = _make_checker()
        desc = "---\nreferences:\n  urd: abc-123\n---\n## Content"
        violations = checker.check_frontmatter_refs(desc, ["urd", "request"])
        ids = {v.constraint_id for v in violations}
        assert "C-frontmatter-refs" in ids

    def test_no_frontmatter_returns_violations_for_all_keys(self) -> None:
        checker = _make_checker()
        desc = "## Content without frontmatter"
        violations = checker.check_frontmatter_refs(desc, ["urd", "request"])
        assert len(violations) == 2

    def test_empty_required_keys_returns_empty(self) -> None:
        checker = _make_checker()
        desc = "## Any description"
        violations = checker.check_frontmatter_refs(desc, [])
        assert violations == []

    def test_violation_context_contains_missing_key(self) -> None:
        checker = _make_checker()
        desc = "## No frontmatter"
        violations = checker.check_frontmatter_refs(desc, ["urd"])
        assert violations[0].context.get("missing_key") == "urd"


# ─── C-supervisor-no-impl ─────────────────────────────────────────────────────


class TestCheckSupervisorNoImpl:
    """C-supervisor-no-impl: supervisor must not implement code directly."""

    def test_worker_doing_impl_no_violation(self) -> None:
        checker = _make_checker()
        assert checker.check_supervisor_no_impl("worker", "file_edit") == []

    def test_supervisor_doing_file_edit_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_supervisor_no_impl("supervisor", "file_edit")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-supervisor-no-impl"

    def test_supervisor_doing_file_write_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_supervisor_no_impl("supervisor", "file_write")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-supervisor-no-impl"

    def test_supervisor_doing_coordination_no_violation(self) -> None:
        checker = _make_checker()
        assert checker.check_supervisor_no_impl("supervisor", "beads_update") == []

    def test_architect_doing_impl_no_violation(self) -> None:
        checker = _make_checker()
        assert checker.check_supervisor_no_impl("architect", "file_edit") == []

    def test_violation_context_contains_role_and_action(self) -> None:
        checker = _make_checker()
        violations = checker.check_supervisor_no_impl("supervisor", "code_change")
        ctx = violations[0].context
        assert ctx.get("role") == "supervisor"
        assert ctx.get("action_type") == "code_change"


# ─── C-followup-lifecycle ─────────────────────────────────────────────────────


class TestCheckFollowupLifecycle:
    """C-followup-lifecycle: follow-up tasks must use FOLLOWUP_* prefix."""

    def test_followup_ure_title_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_followup_lifecycle("FOLLOWUP_URE: Scope findings") == []

    def test_followup_urd_title_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_followup_lifecycle("FOLLOWUP_URD: Requirements") == []

    def test_followup_proposal_title_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_followup_lifecycle("FOLLOWUP_PROPOSAL-1: Technical plan") == []

    def test_followup_impl_plan_title_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_followup_lifecycle("FOLLOWUP_IMPL_PLAN: Plan tasks") == []

    def test_followup_slice_title_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_followup_lifecycle("FOLLOWUP_SLICE-3: Fix naming") == []

    def test_followup_epic_title_returns_empty(self) -> None:
        checker = _make_checker()
        assert checker.check_followup_lifecycle("FOLLOWUP: Findings from code review") == []

    def test_bare_ure_without_prefix_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_followup_lifecycle("URE: No prefix")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-followup-lifecycle"

    def test_slice_without_prefix_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_followup_lifecycle("SLICE-3: Missing FOLLOWUP prefix")
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-followup-lifecycle"

    def test_violation_context_contains_title(self) -> None:
        checker = _make_checker()
        bad_title = "URE: Bad title"
        violations = checker.check_followup_lifecycle(bad_title)
        assert violations[0].context.get("title") == bad_title


# ─── C-followup-leaf-adoption ─────────────────────────────────────────────────


class TestCheckFollowupLeafAdoption:
    """C-followup-leaf-adoption: IMPORTANT/MINOR leaf tasks must have dual parents."""

    def test_valid_dual_parent_returns_empty(self) -> None:
        checker = _make_checker()
        violations = checker.check_followup_leaf_adoption(
            "leaf-abc",
            severity_group_id="sev-group-123",
            followup_slice_id="followup-slice-456",
        )
        assert violations == []

    def test_missing_severity_group_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_followup_leaf_adoption("leaf-abc", "", "followup-slice-456")
        ids = {v.constraint_id for v in violations}
        assert "C-followup-leaf-adoption" in ids

    def test_missing_followup_slice_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_followup_leaf_adoption("leaf-abc", "sev-group-123", "")
        ids = {v.constraint_id for v in violations}
        assert "C-followup-leaf-adoption" in ids

    def test_violation_context_contains_leaf_task_id(self) -> None:
        checker = _make_checker()
        violations = checker.check_followup_leaf_adoption("leaf-xyz", "", "followup-slice")
        assert violations[0].context.get("leaf_task_id") == "leaf-xyz"


# ─── C-worker-gates ───────────────────────────────────────────────────────────


class TestCheckWorkerGates:
    """C-worker-gates: worker completion requires quality gates to pass."""

    def test_all_gates_pass_returns_empty(self) -> None:
        checker = _make_checker()
        violations = checker.check_worker_gates(
            has_todos=False, tests_pass=True, typecheck_pass=True
        )
        assert violations == []

    def test_tests_failing_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_worker_gates(
            has_todos=False, tests_pass=False, typecheck_pass=True
        )
        ids = {v.constraint_id for v in violations}
        assert "C-worker-gates" in ids

    def test_typecheck_failing_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_worker_gates(
            has_todos=False, tests_pass=True, typecheck_pass=False
        )
        ids = {v.constraint_id for v in violations}
        assert "C-worker-gates" in ids

    def test_has_todos_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_worker_gates(
            has_todos=True, tests_pass=True, typecheck_pass=True
        )
        ids = {v.constraint_id for v in violations}
        assert "C-worker-gates" in ids

    def test_all_gates_fail_returns_3_violations(self) -> None:
        checker = _make_checker()
        violations = checker.check_worker_gates(
            has_todos=True, tests_pass=False, typecheck_pass=False
        )
        assert len(violations) == 3

    def test_violation_context_contains_gate_name(self) -> None:
        checker = _make_checker()
        violations = checker.check_worker_gates(False, False, True)
        assert any(v.context.get("gate") == "tests" for v in violations)


# ─── C-supervisor-explore-team ────────────────────────────────────────────────


class TestCheckSupervisorExploreTeam:
    """C-supervisor-explore-team: supervisor must have explore team at p8."""

    def test_p8_with_explore_team_returns_empty(self) -> None:
        checker = _make_checker()
        violations = checker.check_supervisor_explore_team(
            PhaseId.P8_IMPL_PLAN, has_explore_team=True
        )
        assert violations == []

    def test_p8_without_explore_team_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_supervisor_explore_team(
            PhaseId.P8_IMPL_PLAN, has_explore_team=False
        )
        assert len(violations) == 1
        assert violations[0].constraint_id == "C-supervisor-explore-team"

    def test_non_p8_phase_returns_empty_regardless_of_explore_team(self) -> None:
        checker = _make_checker()
        for phase in (
            PhaseId.P1_REQUEST, PhaseId.P9_SLICE, PhaseId.P10_CODE_REVIEW
        ):
            violations = checker.check_supervisor_explore_team(phase, has_explore_team=False)
            assert violations == [], f"Unexpected violation at {phase}"

    def test_violation_context_contains_phase(self) -> None:
        checker = _make_checker()
        violations = checker.check_supervisor_explore_team(PhaseId.P8_IMPL_PLAN, False)
        assert violations[0].context.get("phase") == "p8"


# ─── C-vertical-slices ────────────────────────────────────────────────────────


class TestCheckVerticalSlices:
    """C-vertical-slices: each production code path must have exactly one owner."""

    def test_single_owner_returns_empty(self) -> None:
        checker = _make_checker()
        violations = checker.check_vertical_slices(
            "scripts/aura_protocol/constraints.py",
            ["worker-3"],
        )
        assert violations == []

    def test_no_owner_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_vertical_slices(
            "scripts/aura_protocol/constraints.py",
            [],
        )
        ids = {v.constraint_id for v in violations}
        assert "C-vertical-slices" in ids

    def test_multiple_owners_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_vertical_slices(
            "scripts/aura_protocol/constraints.py",
            ["worker-1", "worker-2"],
        )
        ids = {v.constraint_id for v in violations}
        assert "C-vertical-slices" in ids

    def test_empty_production_code_path_returns_violation(self) -> None:
        checker = _make_checker()
        violations = checker.check_vertical_slices("", ["worker-1"])
        ids = {v.constraint_id for v in violations}
        assert "C-vertical-slices" in ids

    def test_violation_context_contains_path_and_count(self) -> None:
        checker = _make_checker()
        violations = checker.check_vertical_slices("some/path.py", [])
        ctx = violations[0].context
        assert "production_code_path" in ctx or "owner_count" in ctx


# ─── Cross-constraint Integration ─────────────────────────────────────────────


class TestCrossConstraintIntegration:
    """Integration tests verifying that check_state_constraints aggregates multiple constraint violations."""

    def test_p4_with_no_votes_check_state_constraints_is_non_empty(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P4_REVIEW)
        violations = checker.check_state_constraints(state)
        # AC5: should NOT silently pass
        assert violations, "check_state_constraints should return violations for p4 without consensus"

    def test_p10_with_blockers_and_no_consensus_check_state_constraints_is_non_empty(self) -> None:
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW, blocker_count=2)
        violations = checker.check_state_constraints(state)
        assert violations, "check_state_constraints should return violations for p10 with blockers"

    def test_all_violations_have_constraint_id_in_specs(self) -> None:
        """Every constraint_id in a violation must be a known C-* constraint."""
        checker = _make_checker()
        # Create a state with multiple potential violations
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW, blocker_count=1)
        violations = checker.check_state_constraints(state)
        for v in violations:
            assert v.constraint_id in CONSTRAINT_SPECS, (
                f"Violation has unknown constraint_id: {v.constraint_id!r}. "
                f"Known IDs: {sorted(CONSTRAINT_SPECS.keys())}"
            )

    def test_clean_p1_state_produces_no_violations(self) -> None:
        """A fresh p1 state should not produce any violations."""
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P1_REQUEST)
        violations = checker.check_state_constraints(state)
        assert violations == [], f"Unexpected violations for clean p1 state: {violations}"

    def test_check_state_constraints_aggregates_not_short_circuits(self) -> None:
        """check_state_constraints must return violations from multiple checks, not just the first."""
        checker = _make_checker()
        state = _make_state(phase=PhaseId.P10_CODE_REVIEW, blocker_count=5)
        # p10 has both C-review-consensus (no votes) and C-worker-gates (blockers)
        violations = checker.check_state_constraints(state)
        constraint_ids = {v.constraint_id for v in violations}
        # At least both must appear
        assert len(constraint_ids) >= 2, (
            f"Expected multiple violation types; got only: {constraint_ids}"
        )
