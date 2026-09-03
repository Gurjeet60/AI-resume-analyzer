from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.resume import Resume
from app.services.job_matcher import match_resume_to_job


router = APIRouter(
    prefix="/job-match",
    tags=["Job Match"],
)


class JobMatchRequest(BaseModel):
    job_description: str = Field(
        ...,
        min_length=50,
        max_length=20000,
    )


@router.post("/{resume_id}")
def match_resume(
    resume_id: int,
    request: JobMatchRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    resume = (
        db.query(Resume)
        .filter(
            Resume.id == resume_id,
            Resume.user_id == current_user.id,
        )
        .first()
    )

    if not resume:
        raise HTTPException(
            status_code=404,
            detail="Resume not found",
        )

    if not resume.extracted_text:
        raise HTTPException(
            status_code=400,
            detail="Resume text has not been extracted yet",
        )

    job_description = request.job_description.strip()

    if len(job_description) < 50:
        raise HTTPException(
            status_code=400,
            detail="Job description must contain at least 50 characters",
        )

    result = match_resume_to_job(
        resume_text=resume.extracted_text,
        job_description=job_description,
    )

    return {
        "resume_id": resume.id,
        "filename": resume.filename,
        "result": result,
    }