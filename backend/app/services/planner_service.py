from fastapi import HTTPException, status
from sqlalchemy import asc, select
from sqlalchemy.orm import Session

from app.models.study_plan import StudyPlan
from app.models.subject import Subject
from app.models.user import User
from app.schemas.study_plan import StudyPlanCreate


def create_study_plan(db: Session, current_user: User, payload: StudyPlanCreate) -> StudyPlan:
    subject = db.scalar(select(Subject).where(Subject.id == payload.subject_id, Subject.user_id == current_user.id))
    if not subject:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subject not found")

    study_plan = StudyPlan(**payload.model_dump())
    db.add(study_plan)
    db.commit()
    db.refresh(study_plan)
    return study_plan


def list_study_plans(db: Session, current_user: User) -> list[StudyPlan]:
    return db.scalars(
        select(StudyPlan)
        .join(Subject, Subject.id == StudyPlan.subject_id)
        .where(Subject.user_id == current_user.id)
        .order_by(asc(StudyPlan.date), asc(StudyPlan.start_time))
    ).all()


def delete_study_plan(db: Session, current_user: User, plan_id: int) -> None:
    plan = db.scalar(
        select(StudyPlan)
        .join(Subject, Subject.id == StudyPlan.subject_id)
        .where(StudyPlan.id == plan_id, Subject.user_id == current_user.id)
    )
    if not plan:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Study plan not found")

    db.delete(plan)
    db.commit()
