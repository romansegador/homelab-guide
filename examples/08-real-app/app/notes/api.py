"""The API: list notes and add new ones. A new note is saved as `pending`; the worker finishes it."""
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from pydantic import BaseModel, Field

from .db import connect, ensure_schema

# Set when the image is built (sha-<commit> or the release version), so you can see what's running.
VERSION = os.environ.get("APP_VERSION", "dev")


@asynccontextmanager
async def lifespan(app: FastAPI):
    with connect() as conn:
        ensure_schema(conn)
    yield


app = FastAPI(lifespan=lifespan)


class NoteIn(BaseModel):
    body: str = Field(min_length=1, max_length=500)


@app.get("/api/health")
def health():
    return {"status": "ok", "version": VERSION}


@app.get("/api/notes")
def list_notes():
    with connect() as conn:
        rows = conn.execute(
            "SELECT id, body, status, words, created_at FROM notes ORDER BY id DESC LIMIT 20"
        ).fetchall()
    return [
        {"id": r[0], "body": r[1], "status": r[2], "words": r[3], "created_at": r[4].isoformat()}
        for r in rows
    ]


@app.post("/api/notes", status_code=201)
def add_note(note: NoteIn):
    with connect() as conn:
        (note_id,) = conn.execute(
            "INSERT INTO notes (body) VALUES (%s) RETURNING id", (note.body,)
        ).fetchone()
    return {"id": note_id, "status": "pending"}
