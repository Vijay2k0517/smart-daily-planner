from datetime import date as dt_date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class StudyPlan(Base):
    __tablename__ = "study_plans"
    __table_args__ = (Index("ix_study_plans_subject_date", "subject_id", "date"),)

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    subject_id: Mapped[int] = mapped_column(ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False)
    start_time: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    end_time: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    date: Mapped[dt_date] = mapped_column(Date, nullable=False, index=True)

    subject = relationship("Subject", back_populates="study_plans")
