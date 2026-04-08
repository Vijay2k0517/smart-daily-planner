from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, model_validator


class StudyPlanCreate(BaseModel):
    subject_id: int
    start_time: datetime
    end_time: datetime
    date: date

    @model_validator(mode="after")
    def validate_time_range(self) -> "StudyPlanCreate":
        if self.end_time <= self.start_time:
            raise ValueError("end_time must be greater than start_time")
        return self


class StudyPlanOut(BaseModel):
    id: int
    subject_id: int
    start_time: datetime
    end_time: datetime
    date: date

    model_config = ConfigDict(from_attributes=True)
