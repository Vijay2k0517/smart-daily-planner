from pydantic import BaseModel, ConfigDict, Field


class SubjectCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)


class SubjectOut(BaseModel):
    id: int
    name: str

    model_config = ConfigDict(from_attributes=True)
