from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.resume import Resume
from app.models.analysis import ResumeAnalysis
from app.services.analyzer import analyze_resume
from app.ai.service import AIService


router = APIRouter(
    prefix="/analysis",
    tags=["Resume Analysis"],
)


ai_service = AIService()


@router.post("/{resume_id}")
def analyze_resume_endpoint(
    resume_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    # ---------------------------------------------------------
    # 1. Find resume
    # ---------------------------------------------------------

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

    # ---------------------------------------------------------
    # 2. Make sure text was extracted
    # ---------------------------------------------------------

    if not resume.extracted_text:
        raise HTTPException(
            status_code=400,
            detail="Resume text has not been extracted yet",
        )

    # ---------------------------------------------------------
    # 3. Check if analysis already exists
    # ---------------------------------------------------------

    existing_analysis = (
        db.query(ResumeAnalysis)
        .filter(
            ResumeAnalysis.resume_id == resume.id
        )
        .first()
    )

    if existing_analysis:
        return {
            "resume_id": resume.id,
            "filename": resume.filename,
            "analysis": {
                "score": existing_analysis.score,
                "skills": existing_analysis.skills,
                "sections": existing_analysis.sections,
                "suggestions": existing_analysis.suggestions,

                "ai": {
                    "enabled": ai_service.enabled,
                    "summary": existing_analysis.ai_summary,
                    "strengths": existing_analysis.ai_strengths,
                    "weaknesses": existing_analysis.ai_weaknesses,
                    "recommendations": existing_analysis.ai_recommendations,
                    "ats_keywords": existing_analysis.ats_keywords,
                    "career_summary": existing_analysis.career_summary,
                },
            },
        }

    # ---------------------------------------------------------
    # 4. Run deterministic analyzer
    # ---------------------------------------------------------

    result = analyze_resume(
        resume.extracted_text
    )

    score = result["score"]
    skills = result["skills"]
    sections = result["sections"]
    suggestions = result["suggestions"]

    # ---------------------------------------------------------
    # 5. Run AI analysis
    # ---------------------------------------------------------

    ai_result = None

    if ai_service.enabled:
        try:
            ai_result = ai_service.analyze_resume(
                resume_text=resume.extracted_text,
                score=score,
                skills=skills,
                sections=sections,
            )

        except Exception as exc:
            print(
                f"AI resume analysis failed: {exc}"
            )

    # ---------------------------------------------------------
    # 6. Create database record
    # ---------------------------------------------------------

    analysis_record = ResumeAnalysis(
        resume_id=resume.id,

        # Deterministic analysis
        score=score,
        skills=skills,
        sections=sections,
        suggestions=suggestions,

        # AI analysis
        ai_summary=(
            ai_result.summary
            if ai_result
            else None
        ),

        ai_strengths=(
            ai_result.strengths
            if ai_result
            else None
        ),

        ai_weaknesses=(
            ai_result.weaknesses
            if ai_result
            else None
        ),

        ai_recommendations=(
            ai_result.recommendations
            if ai_result
            else None
        ),

        ats_keywords=(
            ai_result.ats_keywords
            if ai_result
            else None
        ),

        career_summary=(
            ai_result.career_summary
            if ai_result
            else None
        ),
    )

    db.add(analysis_record)
    db.commit()
    db.refresh(analysis_record)

    # ---------------------------------------------------------
    # 7. Return complete analysis
    # ---------------------------------------------------------

    return {
        "resume_id": resume.id,
        "filename": resume.filename,

        "analysis": {
            "score": analysis_record.score,
            "skills": analysis_record.skills,
            "sections": analysis_record.sections,
            "suggestions": analysis_record.suggestions,

            "ai": {
                "enabled": ai_service.enabled,
                "summary": analysis_record.ai_summary,
                "strengths": analysis_record.ai_strengths,
                "weaknesses": analysis_record.ai_weaknesses,
                "recommendations": analysis_record.ai_recommendations,
                "ats_keywords": analysis_record.ats_keywords,
                "career_summary": analysis_record.career_summary,
            },
        },
    }


@router.get("/{resume_id}")
def get_resume_analysis(
    resume_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    # ---------------------------------------------------------
    # 1. Find resume
    # ---------------------------------------------------------

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

    # ---------------------------------------------------------
    # 2. Find analysis
    # ---------------------------------------------------------

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

    # ---------------------------------------------------------
    # 3. Return analysis
    # ---------------------------------------------------------

    return {
        "resume_id": resume.id,
        "filename": resume.filename,

        "analysis": {
            "score": analysis.score,
            "skills": analysis.skills,
            "sections": analysis.sections,
            "suggestions": analysis.suggestions,

            "ai": {
                "enabled": ai_service.enabled,
                "summary": analysis.ai_summary,
                "strengths": analysis.ai_strengths,
                "weaknesses": analysis.ai_weaknesses,
                "recommendations": analysis.ai_recommendations,
                "ats_keywords": analysis.ats_keywords,
                "career_summary": analysis.career_summary,
            },
        },
    }