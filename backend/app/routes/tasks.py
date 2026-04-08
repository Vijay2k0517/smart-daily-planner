from fastapi import APIRouter, Depends, Query, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.task import TaskStatus
from app.models.user import User
from app.schemas.task import ReminderResponse, TaskCreate, TaskOut, TaskUpdate
from app.services.task_service import (
    complete_task,
    create_task,
    list_tasks,
    reminders,
    soft_delete_task,
    update_task,
)

router = APIRouter(prefix="/tasks", tags=["Tasks"])


class TaskListResponse(BaseModel):
    items: list[TaskOut]
    page: int
    page_size: int
    total: int


@router.post("", response_model=TaskOut, status_code=status.HTTP_201_CREATED)
def create_task_endpoint(
    payload: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskOut:
    task = create_task(db, current_user, payload)
    return TaskOut.model_validate(task)


@router.get("", response_model=TaskListResponse)
def get_tasks(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=100),
    subject_id: int | None = Query(default=None),
    status_filter: TaskStatus | None = Query(default=None, alias="status"),
    search: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskListResponse:
    tasks, total = list_tasks(db, current_user, page, page_size, subject_id, status_filter, search)
    return TaskListResponse(
        items=[TaskOut.model_validate(task) for task in tasks],
        page=page,
        page_size=page_size,
        total=total,
    )


@router.put("/{task_id}", response_model=TaskOut)
def update_task_endpoint(
    task_id: int,
    payload: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskOut:
    task = update_task(db, current_user, task_id, payload)
    return TaskOut.model_validate(task)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task_endpoint(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    soft_delete_task(db, current_user, task_id)


@router.patch("/{task_id}/complete", response_model=TaskOut)
def complete_task_endpoint(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskOut:
    task = complete_task(db, current_user, task_id)
    return TaskOut.model_validate(task)


@router.get("/reminders", response_model=ReminderResponse)
def reminders_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ReminderResponse:
    due_today, due_next_2_hours = reminders(db, current_user)
    return ReminderResponse(
        due_today=[TaskOut.model_validate(item) for item in due_today],
        due_next_2_hours=[TaskOut.model_validate(item) for item in due_next_2_hours],
    )
