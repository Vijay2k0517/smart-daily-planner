from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.task import TaskPriority, TaskStatus


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None
    subject_id: int
    priority: TaskPriority = TaskPriority.MEDIUM
    deadline: datetime


class TaskUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = None
    subject_id: int | None = None
    priority: TaskPriority | None = None
    deadline: datetime | None = None
    status: TaskStatus | None = None


class TaskOut(BaseModel):
    id: int
    title: str
    description: str | None
    subject_id: int
    priority: TaskPriority
    deadline: datetime
    status: TaskStatus
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ReminderResponse(BaseModel):
    due_today: list[TaskOut]
    due_next_2_hours: list[TaskOut]
