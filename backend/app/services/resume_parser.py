from pathlib import Path

from pypdf import PdfReader
from docx import Document


SUPPORTED_EXTENSIONS = {".pdf", ".docx"}


class ResumeParserError(Exception):
    """Raised when a resume cannot be parsed."""
    pass


def extract_text_from_pdf(file_path: str | Path) -> str:
    """
    Extract text from a PDF resume.
    """
    path = Path(file_path)

    if not path.exists():
        raise ResumeParserError(f"File not found: {path}")

    try:
        reader = PdfReader(str(path))

        pages = []

        for page in reader.pages:
            text = page.extract_text()

            if text:
                pages.append(text)

        return "\n\n".join(pages).strip()

    except Exception as exc:
        raise ResumeParserError(
            f"Failed to extract text from PDF: {exc}"
        ) from exc


def extract_text_from_docx(file_path: str | Path) -> str:
    """
    Extract text from a DOCX resume.
    """
    path = Path(file_path)

    if not path.exists():
        raise ResumeParserError(f"File not found: {path}")

    try:
        document = Document(str(path))

        paragraphs = [
            paragraph.text.strip()
            for paragraph in document.paragraphs
            if paragraph.text.strip()
        ]

        return "\n".join(paragraphs).strip()

    except Exception as exc:
        raise ResumeParserError(
            f"Failed to extract text from DOCX: {exc}"
        ) from exc


def extract_resume_text(file_path: str | Path) -> str:
    """
    Extract resume text based on the file extension.
    """
    path = Path(file_path)

    if not path.exists():
        raise ResumeParserError(f"File not found: {path}")

    extension = path.suffix.lower()

    if extension not in SUPPORTED_EXTENSIONS:
        raise ResumeParserError(
            f"Unsupported file type: {extension}. "
            f"Supported types: {', '.join(SUPPORTED_EXTENSIONS)}"
        )

    if extension == ".pdf":
        text = extract_text_from_pdf(path)

    elif extension == ".docx":
        text = extract_text_from_docx(path)

    else:
        raise ResumeParserError(
            f"Unsupported file type: {extension}"
        )

    if not text:
        raise ResumeParserError(
            "No readable text was found in the resume."
        )

    return text

