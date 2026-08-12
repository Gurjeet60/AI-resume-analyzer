from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.resume import Resume
from app.services.analyzer import analyze_resume
from app.models.analysis import ResumeAnalysis


router = APIRouter(
    prefix="/analysis",
    tags=["Resume Analysis"],
)


@router.post("/{resume_id}")
def analyze_resume_endpoint(
    resume_id: int,
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

    existing_analysis = (
    db.query(ResumeAnalysis)
    .filter(
        ResumeAnalysis.resume_id == resume.id
    )
    .first()
)

    if existing_analysis:
        raise HTTPException(
            status_code=409,
            detail="Resume has already been analyzed",
        )

    analysis = analyze_resume(resume.extracted_text)

    analysis_record = ResumeAnalysis(
        resume_id=resume.id,
        score=analysis["score"],
        skills=analysis["skills"],
        sections=analysis["sections"],
        suggestions=analysis["suggestions"],
)

    db.add(analysis_record)
    db.commit()
    db.refresh(analysis_record)



    return {
        "resume_id": resume.id,
        "filename": resume.filename,
        "analysis": analysis,
    }

@router.get("/{resume_id}")
def get_resume_analysis(
    resume_id: int,
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

    analysis = (
        db.query(ResumeAnalysis)
        .filter(
            ResumeAnalysis.resume_id == resume.id
        )
        .first()
    )

    if not analysis:
        raise HTTPException(
            status_code=404,
            detail="Resume has not been analyzed yet",
        )

    return {
        "resume_id": resume.id,
        "filename": resume.filename,
        "analysis": {
            "id": analysis.id,
            "score": analysis.score,
            "skills": analysis.skills,
            "sections": analysis.sections,
            "suggestions": analysis.suggestions,
        },
    }