"""Shared pytest fixtures for aura_protocol test suite.

Provides common EpochStateMachine setup patterns used across multiple test files
to avoid repeated inline boilerplate and keep tests focused on behaviour.
"""

from __future__ import annotations

import pytest

from aura_protocol.state_machine import EpochStateMachine
from aura_protocol.types import PhaseId, VoteType


@pytest.fixture
def epoch_id() -> str:
    return "test-epoch-001"


@pytest.fixture
def sm(epoch_id: str) -> EpochStateMachine:
    return EpochStateMachine(epoch_id)


@pytest.fixture
def sm_at_p4(sm: EpochStateMachine) -> EpochStateMachine:
    """State machine advanced to P4 (review phase)."""
    sm.advance(PhaseId.P2_ELICIT, triggered_by="epoch", condition_met="ok")
    sm.advance(PhaseId.P3_PROPOSE, triggered_by="architect", condition_met="ok")
    sm.advance(PhaseId.P4_REVIEW, triggered_by="architect", condition_met="ok")
    return sm


@pytest.fixture
def sm_at_p4_with_consensus(sm_at_p4: EpochStateMachine) -> EpochStateMachine:
    """State machine at P4 with all 3 ACCEPT votes."""
    sm_at_p4.record_vote("A", VoteType.ACCEPT)
    sm_at_p4.record_vote("B", VoteType.ACCEPT)
    sm_at_p4.record_vote("C", VoteType.ACCEPT)
    return sm_at_p4
