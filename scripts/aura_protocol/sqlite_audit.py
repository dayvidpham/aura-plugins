"""SQLite-backed audit trail for aurad (SLICE-5).

SqliteAuditTrail implements the AuditTrail Protocol from interfaces.py using
an aiosqlite-backed SQLite database. This provides durable event persistence
across aurad restarts, unlike InMemoryAuditTrail which loses data on stop.

Schema (audit_events table):
    id          INTEGER PRIMARY KEY AUTOINCREMENT
    epoch_id    TEXT NOT NULL
    phase       TEXT NOT NULL   (PhaseId.value)
    role        TEXT NOT NULL   (RoleId.value)
    event_type  TEXT NOT NULL
    payload     TEXT NOT NULL   (JSON-serialized dict)
    timestamp   TEXT NOT NULL   (ISO-8601 UTC)

Usage:
    trail = SqliteAuditTrail(db_path=Path("~/.local/share/aura/audit.db"))
    await trail.record_event(event)
    events = await trail.query_events(epoch_id="ep-1")
"""

from __future__ import annotations

import json
import logging
from dataclasses import asdict
from datetime import UTC, datetime
from pathlib import Path
from typing import TYPE_CHECKING

from aura_protocol.types import AuditEvent, PhaseId, RoleId

logger = logging.getLogger(__name__)


def _ensure_schema(db_path: Path) -> None:
    """Create the audit_events table if it does not exist.

    This is a synchronous helper called at startup before the async worker
    loop starts. It uses the stdlib sqlite3 module (no aiosqlite) since it
    runs outside the event loop.

    Args:
        db_path: Path to the SQLite database file. Parent directories are
                 created if they do not exist.

    Creates:
        audit_events table with columns:
            id         INTEGER PRIMARY KEY AUTOINCREMENT
            epoch_id   TEXT NOT NULL
            phase      TEXT NOT NULL
            role       TEXT NOT NULL
            event_type TEXT NOT NULL
            payload    TEXT NOT NULL  (JSON)
            timestamp  TEXT NOT NULL  (ISO-8601 UTC)
    """
    import sqlite3

    db_path.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(str(db_path)) as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS audit_events (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                epoch_id   TEXT NOT NULL,
                phase      TEXT NOT NULL,
                role       TEXT NOT NULL,
                event_type TEXT NOT NULL,
                payload    TEXT NOT NULL,
                timestamp  TEXT NOT NULL
            )
        """)
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_epoch_id ON audit_events (epoch_id)"
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_phase ON audit_events (phase)"
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_role ON audit_events (role)"
        )
        conn.commit()
    logger.info("SqliteAuditTrail schema ensured at %s", db_path)


class SqliteAuditTrail:
    """SQLite-backed AuditTrail implementation (SLICE-5).

    Persists AuditEvent records to a SQLite database via aiosqlite so the
    aurad worker loop remains non-blocking. _ensure_schema() is called
    synchronously at startup before the async event loop starts.

    Implements: AuditTrail Protocol from aura_protocol.interfaces

    Args:
        db_path: Path to the SQLite database file.
    """

    def __init__(self, db_path: Path) -> None:
        self._db_path = db_path

    async def record_event(self, event: AuditEvent) -> None:
        """Persist an AuditEvent to the SQLite database.

        Args:
            event: AuditEvent frozen dataclass to record.

        Raises:
            RuntimeError: If aiosqlite is not installed or the DB is unavailable.
                          Where: SqliteAuditTrail.record_event at {db_path}
                          Why: aiosqlite write failed
                          Fix: Ensure aiosqlite is installed and DB path is writable.
        """
        ...

    async def query_events(
        self,
        *,
        epoch_id: str | None = None,
        phase: PhaseId | None = None,
        role: RoleId | None = None,
    ) -> list[AuditEvent]:
        """Query recorded audit events with optional filters.

        Args:
            epoch_id: Optional epoch filter.
            phase:    Optional phase filter (PhaseId enum member).
            role:     Optional role filter (RoleId enum member).

        Returns:
            Matching AuditEvent instances in chronological order (by id).

        Raises:
            RuntimeError: If the database is unavailable.
                          Where: SqliteAuditTrail.query_events at {db_path}
                          Fix: Ensure DB file exists (run _ensure_schema first).
        """
        ...
