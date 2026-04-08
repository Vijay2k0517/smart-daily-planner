from sqlalchemy import and_, func, select
from sqlalchemy.orm import Session

from app.models.study_plan import StudyPlan
from app.models.subject import Subject
from app.models.task import Task, TaskStatus
from app.models.user import User


def calculate_progress(db: Session, current_user: User) -> dict[str, float | int]:
    total_tasks = db.scalar(
        select(func.count(Task.id))
        .join(Subject, Subject.id == Task.subject_id)
        .where(and_(Subject.user_id == current_user.id, Task.deleted_at.is_(None)))
    ) or 0

    completed_tasks = db.scalar(
        select(func.count(Task.id))
        .join(Subject, Subject.id == Task.subject_id)
        .where(
            and_(
                Subject.user_id == current_user.id,
                Task.deleted_at.is_(None),
                Task.status == TaskStatus.COMPLETED,
            )
        )
    ) or 0

    duration_seconds = db.scalar(
        select(func.sum(func.strftime("%s", StudyPlan.end_time) - func.strftime("%s", StudyPlan.start_time)))
        .join(Subject, Subject.id == StudyPlan.subject_id)
        .where(Subject.user_id == current_user.id)
    ) or 0

    study_hours = round(float(duration_seconds) / 3600, 2)
    completion_percentage = round((completed_tasks / total_tasks) * 100, 2) if total_tasks else 0.0

    return {
        "completed_tasks": int(completed_tasks),
        "total_tasks": int(total_tasks),
        "completion_percentage": completion_percentage,
        "study_hours": study_hours,
    }
