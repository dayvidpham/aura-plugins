"""Aura Protocol Engine — public API.

This package provides typed Python definitions for the Aura multi-agent protocol.
All definitions are derived from and validated against skills/protocol/schema.xml.

Public API (re-exported from submodules):

Enums:
    PhaseId      — 13 values: p1-p12 + complete
    Domain       — user, plan, impl
    RoleId       — epoch, architect, reviewer, supervisor, worker
    VoteType     — ACCEPT, REVISE
    SeverityLevel — BLOCKER, IMPORTANT, MINOR

Frozen Dataclasses:
    Transition          — single valid phase transition
    PhaseSpec           — complete phase specification
    ConstraintSpec      — protocol constraint (Given/When/Then)
    HandoffSpec         — actor-change handoff specification

Event Stub Types (frozen dataclasses):
    PhaseTransitionEvent
    ConstraintCheckEvent
    ReviewVoteEvent
    AuditEvent
    ToolPermissionRequest
    PermissionDecision

Canonical Lookup Dicts:
    PHASE_SPECS       — dict[PhaseId, PhaseSpec]   — all 12 phases
    CONSTRAINT_SPECS  — dict[str, ConstraintSpec]  — all C-* constraints
    HANDOFF_SPECS     — dict[str, HandoffSpec]     — all 6 handoffs
    PHASE_DOMAIN      — dict[PhaseId, Domain]      — phase-to-domain mapping

State Machine (from state_machine.py):
    EpochState          — mutable epoch runtime state
    TransitionRecord    — frozen, immutable audit entry for one transition
    TransitionError     — exception raised when a transition is invalid
    EpochStateMachine   — 12-phase epoch lifecycle state machine

Protocol Interfaces (runtime_checkable, from interfaces.py):
    ConstraintValidatorInterface
    TranscriptRecorder
    SecurityGate
    AuditTrail

A2A Content Types (frozen dataclasses, from interfaces.py):
    TextPart, FilePart, DataPart, Part (union), ToolCall

Model Identifier (from interfaces.py):
    ModelId — models.dev {provider}/{model} composite ID
"""

from aura_protocol.interfaces import (
    AuditTrail,
    ConstraintValidatorInterface,
    DataPart,
    FilePart,
    ModelId,
    Part,
    SecurityGate,
    TextPart,
    ToolCall,
    TranscriptRecorder,
)
from aura_protocol.state_machine import (
    EpochState,
    EpochStateMachine,
    TransitionError,
    TransitionRecord,
)
from aura_protocol.types import (
    CONSTRAINT_SPECS,
    HANDOFF_SPECS,
    PHASE_DOMAIN,
    PHASE_SPECS,
    AuditEvent,
    ConstraintCheckEvent,
    ConstraintSpec,
    Domain,
    HandoffSpec,
    PermissionDecision,
    PhaseId,
    PhaseSpec,
    PhaseTransitionEvent,
    ReviewVoteEvent,
    RoleId,
    SeverityLevel,
    ToolPermissionRequest,
    Transition,
    VoteType,
)

__all__ = [
    # Enums
    "PhaseId",
    "Domain",
    "RoleId",
    "VoteType",
    "SeverityLevel",
    # Frozen dataclasses
    "Transition",
    "PhaseSpec",
    "ConstraintSpec",
    "HandoffSpec",
    # Event stub types
    "PhaseTransitionEvent",
    "ConstraintCheckEvent",
    "ReviewVoteEvent",
    "AuditEvent",
    "ToolPermissionRequest",
    "PermissionDecision",
    # Canonical lookup dicts
    "PHASE_SPECS",
    "CONSTRAINT_SPECS",
    "HANDOFF_SPECS",
    "PHASE_DOMAIN",
    # Protocol interfaces
    "ConstraintValidatorInterface",
    "TranscriptRecorder",
    "SecurityGate",
    "AuditTrail",
    # A2A content types
    "TextPart",
    "FilePart",
    "DataPart",
    "Part",
    "ToolCall",
    # Model identifier
    "ModelId",
    # State machine
    "EpochState",
    "TransitionRecord",
    "TransitionError",
    "EpochStateMachine",
]
