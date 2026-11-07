"""The worker: picks up pending notes one at a time and finishes them (here, it counts the words).

It uses the database as its queue: `FOR UPDATE SKIP LOCKED` lets several workers run side by side
without two of them taking the same note. Run it with `python -m notes.worker`.
"""
import signal
import time

import psycopg

from .db import connect, ensure_schema

stopping = False


def stop(*_):
    global stopping
    stopping = True


def work_one(conn: psycopg.Connection) -> bool:
    """Finish the oldest pending note. Returns False when there's nothing to do."""
    with conn.transaction():
        row = conn.execute(
            "SELECT id, body FROM notes WHERE status = 'pending' "
            "ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED"
        ).fetchone()
        if row is None:
            return False
        note_id, body = row
        time.sleep(1)  # stands in for real work: calling another service, resizing an image…
        words = len(body.split())
        conn.execute(
            "UPDATE notes SET status = 'done', words = %s, done_at = now() WHERE id = %s",
            (words, note_id),
        )
    print(f"note {note_id}: done, {words} words", flush=True)
    return True


def main():
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    while not stopping:
        try:
            with connect() as conn:
                ensure_schema(conn)
                print("worker ready", flush=True)
                while not stopping:
                    if not work_one(conn):
                        time.sleep(2)
        except psycopg.OperationalError as e:
            print(f"database unavailable, retrying in 5s: {e}", flush=True)
            time.sleep(5)
    print("worker stopped", flush=True)


if __name__ == "__main__":
    main()
