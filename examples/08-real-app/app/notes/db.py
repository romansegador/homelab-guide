"""The database connection and the app's one table.

DATABASE_URL comes from the Secret the database operator creates (key `uri`), so the app never sees
a password in its own configuration.
"""
import os

import psycopg

SCHEMA = """
CREATE TABLE IF NOT EXISTS notes (
    id         bigserial   PRIMARY KEY,
    body       text        NOT NULL,
    status     text        NOT NULL DEFAULT 'pending',
    words      integer,
    created_at timestamptz NOT NULL DEFAULT now(),
    done_at    timestamptz
)
"""


def connect() -> psycopg.Connection:
    return psycopg.connect(os.environ["DATABASE_URL"], autocommit=True)


def ensure_schema(conn: psycopg.Connection) -> None:
    """Create the table if it's missing. The API and the worker both call this when they start; the
    lock makes the second one wait instead of colliding with the first."""
    with conn.transaction():
        conn.execute("SELECT pg_advisory_xact_lock(8)")
        conn.execute(SCHEMA)
