from pydantic import BaseModel


class ProgressOut(BaseModel):
    completed_tasks: int
    total_tasks: int
    completion_percentage: float
    study_hours: float
