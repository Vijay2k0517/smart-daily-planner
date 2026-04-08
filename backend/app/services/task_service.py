from datetime import datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import and_, asc, case, desc, func, or_, select
from sqlalchemy.orm import Session

from app.models.subject import Subject
from app.models.task import Task, TaskPriority, TaskStatus
from app.models.user import User
from app.schemas.task import TaskCreate, TaskUpdate


def _priority_sort_case() -> case:
    return case(
        (Task.priority == TaskPriority.HIGH, 0),
        (Task.priority == TaskPriority.MEDIUM, 1),
        else_=2,
    )


def create_task(db: Session, current_user: User, payload: TaskCreate) -> Task:
    subject = db.scalar(select(Subject).where(Subject.id == payload.subject_id, Subject.user_id == current_user.id))
    if not subject:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subject not found")

    task = Task(**payload.model_dump())
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


def list_tasks(
    db: Session,
    current_user: User,
    page: int,
    page_size: int,
    subject_id: int | None,
    status_filter: TaskStatus | None,
    search: str | None,
) -> tuple[list[Task], int]:
    filters = [
        Subject.user_id == current_user.id,
        Task.deleted_at.is_(None),
    ]

    if subject_id is not None:
        filters.append(Task.subject_id == subject_id)
    if status_filter is not None:
        filters.append(Task.status == status_filter)
    if search:
        pattern = f"%{search.strip()}%"
        filters.append(or_(Task.title.ilike(pattern), Task.description.ilike(pattern)))

    base_query = select(Task).join(Subject, Subject.id == Task.subject_id).where(and_(*filters))
    count_query = select(func.count(Task.id)).join(Subject, Subject.id == Task.subject_id).where(and_(*filters))
    total = db.scalar(count_query) or 0

    tasks = db.scalars(
        base_query
        .order_by(asc(_priority_sort_case()), asc(Task.deadline), desc(Task.created_at))
        .offset((page - 1) * page_size)
        .limit(page_size)
    ).all()

    return tasks, total


def update_task(db: Session, current_user: User, task_id: int, payload: TaskUpdate) -> Task:
    task = _get_owned_task(db, current_user, task_id)
    if payload.subject_id is not None:
        subject = db.scalar(
            select(Subject).where(Subject.id == payload.subject_id, Subject.user_id == current_user.id)
        )
        if not subject:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subject not found")

    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(task, key, value)

    db.commit()
    db.refresh(task)
    return task


def complete_task(db: Session, current_user: User, task_id: int) -> Task:
    task = _get_owned_task(db, current_user, task_id)
    task.status = TaskStatus.COMPLETED
    db.commit()
    db.refresh(task)
    return task


def soft_delete_task(db: Session, current_user: User, task_id: int) -> None:
    task = _get_owned_task(db, current_user, task_id)
    task.deleted_at = datetime.utcnow()
    db.commit()


def reminders(db: Session, current_user: User) -> tuple[list[Task], list[Task]]:
    now = datetime.utcnow()
    day_end = now.replace(hour=23, minute=59, second=59, microsecond=999999)
    next_2_hours = now + timedelta(hours=2)

    common_filters = [
        Subject.user_id == current_user.id,
        Task.deleted_at.is_(None),
        Task.status == TaskStatus.PENDING,
    ]

    due_today = db.scalars(
        select(Task)
        .join(Subject, Subject.id == Task.subject_id)
        .where(and_(*common_filters, Task.deadline >= now, Task.deadline <= day_end))
        .order_by(asc(Task.deadline))
    ).all()

    due_next_2_hours = db.scalars(
        select(Task)
        .join(Subject, Subject.id == Task.subject_id)
        .where(and_(*common_filters, Task.deadline >= now, Task.deadline <= next_2_hours))
        .order_by(asc(Task.deadline))
    ).all()

    return due_today, due_next_2_hours


def _get_owned_task(db: Session, current_user: User, task_id: int) -> Task:
    task = db.scalar(
        select(Task)
        .join(Subject, Subject.id == Task.subject_id)
        .where(
            Task.id == task_id,
            Subject.user_id == current_user.id,
            Task.deleted_at.is_(None),
        )
    )
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return task
