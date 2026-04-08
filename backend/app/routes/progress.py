from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.progress import ProgressOut
from app.services.progress_service import calculate_progress

router = APIRouter(prefix="/progress", tags=["Progress Tracker"])


@router.get("", response_model=ProgressOut)
def get_progress(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ProgressOut:
    result = calculate_progress(db, current_user)
    return ProgressOut(**result)
