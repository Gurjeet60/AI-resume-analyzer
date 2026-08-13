from sqlalchemy import Column, Integer, JSON, ForeignKey, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class ResumeAnalysis(Base):
    __tablename__ = "resume_analysis"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    resume_id = Column(
        Integer,
        ForeignKey("resumes.id"),
        unique=True,
        nullable=False,
    )

    score = Column(
        Integer,
        nullable=False,
    )

    skills = Column(
        JSON,
        nullable=False,
    )

    sections = Column(
        JSON,
        nullable=False,
    )

    suggestions = Column(
        JSON,
        nullable=False,
    )

    # AI-generated analysis

    ai_summary = Column(
        Text,
        nullable=True,
    )

    ai_strengths = Column(
        JSON,
        nullable=True,
    )

    ai_weaknesses = Column(
        JSON,
        nullable=True,
    )

    ai_recommendations = Column(
        JSON,
        nullable=True,
    )

    ats_keywords = Column(
        JSON,
        nullable=True,
    )

    career_summary = Column(
        Text,
        nullable=True,
    )

    resume = relationship(
        "Resume",
        back_populates="analysis",
    )