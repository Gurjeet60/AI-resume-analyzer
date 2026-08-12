from sqlalchemy import Column, Integer, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship

from app.core.database import Base


class ResumeAnalysis(Base):
    __tablename__ = "resume_analysis"

    id = Column(Integer, primary_key=True, index=True)

    resume_id = Column(
        Integer,
        ForeignKey("resumes.id"),
        nullable=False,
        unique=True,
        index=True,
    )

    score = Column(Integer, nullable=False)

    skills = Column(JSON, nullable=False)

    sections = Column(JSON, nullable=False)

    suggestions = Column(JSON, nullable=False)

    resume = relationship(
        "Resume",
        back_populates="analysis",
    )