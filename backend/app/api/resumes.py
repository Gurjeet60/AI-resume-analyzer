import os
import uuid
from pathlib import Path

from app.models.resume import Resume
from app.models.analysis import ResumeAnalysis

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session
from app.services.document_parser import extract_text

from app.core.database import get_db
from app.models import Resume, User
from app.core.security import get_current_user


router = APIRouter(
    prefix="/resumes",
    tags=["Resumes"],
)


UPLOAD_DIR = Path("uploads/resumes")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MB

ALLOWED_EXTENSIONS = {
    ".pdf",
    ".docx",
}


@router.post(
    "/upload",
    status_code=status.HTTP_201_CREATED,
)
async def upload_resume(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # 1. Validate filename
    if not file.filename:
        raise HTTPException(
            status_code=400,
            detail="Filename is required",
        )

    original_filename = file.filename

    # 2. Validate extension
    extension = Path(original_filename).suffix.lower()

    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail="Only PDF and DOCX files are allowed",
        )

    # 3. Read file
    file_content = await file.read()

    # 4. Validate file size
    if len(file_content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail="File size must be less than 5 MB",
        )

    if len(file_content) == 0:
        raise HTTPException(
            status_code=400,
            detail="Uploaded file is empty",
        )

    # 5. Generate unique filename
    unique_filename = f"{uuid.uuid4()}{extension}"

    file_path = UPLOAD_DIR / unique_filename

    # 6. Save file
    try:
        with open(file_path, "wb") as buffer:
            buffer.write(file_content)

    except OSError as exc:
        raise HTTPException(
            status_code=500,
            detail="Failed to save uploaded file",
        ) from exc

    # 7. Extract resume text
    try:
        extracted_text = extract_text(str(file_path))

    except Exception as exc:
        # Remove the uploaded file if parsing fails
        if file_path.exists():
            file_path.unlink()

        raise HTTPException(
            status_code=400,
            detail="Could not extract text from the uploaded resume",
        ) from exc


    if not extracted_text:
        if file_path.exists():
            file_path.unlink()

        raise HTTPException(
            status_code=400,
            detail="No readable text was found in the uploaded resume",
        )


    # 8. Create database record
    resume = Resume(
        user_id=current_user.id,
        filename=original_filename,
        file_path=str(file_path),
        extracted_text=extracted_text,
    )

    db.add(resume)
    db.commit()
    db.refresh(resume)

    return {
    "message": "Resume uploaded and processed successfully",
    "resume": {
        "id": resume.id,
        "filename": resume.filename,
        "user_id": resume.user_id,
        "file_path": resume.file_path,
        "text_preview": resume.extracted_text[:1000],
        "created_at": resume.created_at,
    },
}

@router.get("/")
def get_my_resumes(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    resumes = (
        db.query(Resume)
        .filter(Resume.user_id == current_user.id)
        .order_by(Resume.created_at.desc())
        .all()
    )

    result = []

    for resume in resumes:
        analysis = (
            db.query(ResumeAnalysis)
            .filter(ResumeAnalysis.resume_id == resume.id)
            .first()
        )

        result.append({
            "id": resume.id,
            "filename": resume.filename,
            "created_at": resume.created_at,
            "status": "analyzed" if analysis else "pending",
            "score": analysis.score if analysis else None,
        })

    return result

@router.delete("/{resume_id}")
def delete_resume(
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

    if analysis:
        db.delete(analysis)

    db.delete(resume)
    db.commit()

    return {
        "message": "Resume deleted successfully"
    }

    