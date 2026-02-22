"""Cross-project integration interfaces + A2A-compatible content types.

This module defines:
- Protocol interfaces (@runtime_checkable) for structural subtyping across repos:
    ConstraintValidatorInterface, TranscriptRecorder, SecurityGate, AuditTrail
- A2A content types (frozen dataclasses):
    TextPart, FilePart, DataPart, Part union, ToolCall
- Composite model identifier:
    ModelId (models.dev {provider}/{model} format)

Event stub types are defined in types.py and re-exported here for convenience.

Source of truth: skills/protocol/schema.xml
Ratified plan: aura-plugins-gmv (AC9, AC10)
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Protocol, runtime_checkable

from aura_protocol.types import (
    AuditEvent,
    ConstraintCheckEvent,
    PermissionDecision,
    PhaseId,
    PhaseTransitionEvent,
    ReviewVoteEvent,
    RoleId,
    ToolPermissionRequest,
)

if TYPE_CHECKING:
    # These modules are not yet implemented; use TYPE_CHECKING to avoid
    # circular runtime imports. The Protocol method signatures remain fully
    # type-checked while runtime import cost is zero.
    from aura_protocol.constraints import ConstraintViolation  # noqa: F401
    from aura_protocol.state_machine import EpochState  # noqa: F401


# ─── Protocol Interfaces ──────────────────────────────────────────────────────


@runtime_checkable
class ConstraintValidatorInterface(Protocol):
    """Any constraint validator must implement this.

    Structural subtyping: external projects can satisfy this without
    inheriting from any base class.

    AC9: isinstance(obj, ConstraintValidatorInterface) returns True for any
    object with a matching validate() signature.
    """

    def validate(self, state: EpochState) -> list[ConstraintViolation]:
        """Validate protocol constraints against the given epoch state.

        Args:
            state: Current epoch state to validate.

        Returns:
            List of constraint violations found. Empty list means all pass.
        """
        ...


@runtime_checkable
class TranscriptRecorder(Protocol):
    """Interface for unified-schema integration (transcript recording).

    Implementors live in unified-schema; we only define the contract here.
    External projects satisfy this via structural subtyping — no inheritance
    required.
    """

    async def record_phase_transition(self, event: PhaseTransitionEvent) -> None:
        """Record a phase transition event to the transcript."""
        ...

    async def record_constraint_check(self, event: ConstraintCheckEvent) -> None:
        """Record a constraint check event to the transcript."""
        ...

    async def record_review_vote(self, event: ReviewVoteEvent) -> None:
        """Record a review vote event to the transcript."""
        ...


@runtime_checkable
class SecurityGate(Protocol):
    """Interface for agentfilter integration (permission checking).

    Implementors live in agentfilter; we only define the contract here.
    """

    async def check_tool_permission(
        self, request: ToolPermissionRequest
    ) -> PermissionDecision:
        """Check whether the requested tool use is permitted.

        Args:
            request: Tool permission request containing tool name, input
                     summary, and requesting role.

        Returns:
            Permission decision (allowed/denied with optional reason).
        """
        ...


@runtime_checkable
class AuditTrail(Protocol):
    """Interface for the audit trail backend.

    v1: backed by Beads (bd CLI).
    v2+: backed by Temporal event history + search attributes.
    """

    async def record_event(self, event: AuditEvent) -> None:
        """Persist an audit event to the trail.

        Args:
            event: Audit event to record.
        """
        ...

    async def query_events(
        self,
        *,
        phase: PhaseId | None = None,
        role: RoleId | None = None,
    ) -> list[AuditEvent]:
        """Query recorded audit events with optional filters.

        Args:
            phase: Optional phase filter — only return events from this phase.
            role:  Optional role filter — only return events from this role.

        Returns:
            Matching audit events in chronological order.
        """
        ...


# ─── A2A Content Types ────────────────────────────────────────────────────────
# Minimal v1 subset of the A2A content type hierarchy.
# Full hierarchy is v2/v3 scope.


@dataclass(frozen=True)
class TextPart:
    """A2A TextPart — plain text content."""

    text: str


@dataclass(frozen=True)
class FilePart:
    """A2A FilePart — file content reference by URI."""

    file_uri: str
    mime_type: str | None = None


@dataclass(frozen=True)
class DataPart:
    """A2A DataPart — structured data payload."""

    data: dict


# Discriminated union type for all A2A content parts.
Part = TextPart | FilePart | DataPart


# ─── Tool Call ────────────────────────────────────────────────────────────────


@dataclass(frozen=True)
class ToolCall:
    """MCP-compatible tool call representation.

    Captures tool invocation input and optional output for audit/transcript
    purposes.
    """

    tool_name: str
    tool_input: dict
    tool_output: dict | None = None


# ─── Model Identifier ─────────────────────────────────────────────────────────


@dataclass(frozen=True)
class ModelId:
    """models.dev composite model identifier: {provider_id}/{model_id}.

    Examples:
        ModelId.parse("anthropic/claude-opus-4-6")
            → ModelId(provider="anthropic", model="claude-opus-4-6")
        ModelId.parse("openai/gpt-4o")
            → ModelId(provider="openai", model="gpt-4o")
        str(ModelId(provider="anthropic", model="claude-opus-4-6"))
            → "anthropic/claude-opus-4-6"

    AC10: parse() splits on the first "/" only; model names may contain "/"
    (e.g., org-scoped model names). Raises ValueError for strings without "/".
    """

    provider: str
    model: str

    def __str__(self) -> str:
        return f"{self.provider}/{self.model}"

    @classmethod
    def parse(cls, s: str) -> ModelId:
        """Parse a models.dev composite model ID string.

        Splits on the first "/" only, so model names containing "/" are
        handled correctly (e.g., "org/team/model" → provider="org",
        model="team/model").

        Args:
            s: String of the form "provider/model".

        Returns:
            ModelId with provider and model fields populated.

        Raises:
            ValueError: If s does not contain "/", or if provider or model
                        part is empty after splitting.
        """
        provider, sep, model = s.partition("/")
        if not sep or not provider or not model:
            raise ValueError(
                f"Invalid model ID: {s!r} — expected 'provider/model' format"
            )
        return cls(provider=provider, model=model)


# ─── Re-exports of Event Stub Types ──────────────────────────────────────────
# Event stub types are canonically defined in types.py and re-exported here
# so callers can import everything integration-related from one place.

__all__ = [
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
    # Event stub types (re-exported from types.py)
    "PhaseTransitionEvent",
    "ConstraintCheckEvent",
    "ReviewVoteEvent",
    "AuditEvent",
    "ToolPermissionRequest",
    "PermissionDecision",
]
