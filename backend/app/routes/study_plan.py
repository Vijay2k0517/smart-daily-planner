from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.study_plan import StudyPlanCreate, StudyPlanOut
from app.services.planner_service import create_study_plan, delete_study_plan, list_study_plans

router = APIRouter(prefix="/study-plan", tags=["Study Planner"])


@router.post("", response_model=StudyPlanOut, status_code=status.HTTP_201_CREATED)
def create_study_plan_endpoint(
    payload: StudyPlanCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> StudyPlanOut:
    plan = create_study_plan(db, current_user, payload)
    return StudyPlanOut.model_validate(plan)


@router.get("", response_model=list[StudyPlanOut])
def list_study_plan_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[StudyPlanOut]:
    plans = list_study_plans(db, current_user)
    return [StudyPlanOut.model_validate(item) for item in plans]


@router.delete("/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_study_plan_endpoint(
    plan_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    delete_study_plan(db, current_user, plan_id)
