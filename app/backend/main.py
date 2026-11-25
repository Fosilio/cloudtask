import os
from contextlib import asynccontextmanager

import psycopg
from psycopg.rows import dict_row
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field


def get_connection():
    return psycopg.connect(
        host=os.environ["DB_HOST"],
        port=5432,
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=5,
        row_factory=dict_row
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    with get_connection() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id SERIAL PRIMARY KEY,
                title VARCHAR(200) NOT NULL,
                completed BOOLEAN NOT NULL DEFAULT FALSE,
                created_at TIMESTAMPTZ DEFAULT NOW()
            )
        """)

    yield


app = FastAPI(
    title="CloudTask API",
    version="1.0.0",
    lifespan=lifespan
)


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)


class TaskUpdate(BaseModel):
    completed: bool


@app.get("/health")
def health():
    with get_connection() as conn:
        conn.execute("SELECT 1")

    return {
        "status": "healthy",
        "database": "connected"
    }


@app.get("/tasks")
def get_tasks():
    with get_connection() as conn:
        return conn.execute("""
            SELECT * FROM tasks
            ORDER BY id DESC
        """).fetchall()


@app.post("/tasks", status_code=201)
def create_task(task: TaskCreate):
    with get_connection() as conn:
        return conn.execute("""
            INSERT INTO tasks (title)
            VALUES (%s)
            RETURNING *
        """, (task.title,)).fetchone()


@app.patch("/tasks/{task_id}")
def update_task(task_id: int, task: TaskUpdate):
    with get_connection() as conn:
        result = conn.execute("""
            UPDATE tasks
            SET completed = %s
            WHERE id = %s
            RETURNING *
        """, (task.completed, task_id)).fetchone()

        if result is None:
            raise HTTPException(404, "Task not found")

        return result


@app.delete("/tasks/{task_id}")
def delete_task(task_id: int):
    with get_connection() as conn:
        result = conn.execute("""
            DELETE FROM tasks
            WHERE id = %s
            RETURNING id
        """, (task_id,)).fetchone()

        if result is None:
            raise HTTPException(404, "Task not found")

        return {"deleted": True}