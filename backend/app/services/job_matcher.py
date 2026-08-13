import re


def normalize_text(text: str) -> str:
    if not text:
        return ""

    text = text.lower()
    text = re.sub(r"\s+", " ", text)

    return text.strip()


def extract_keywords(text: str) -> set[str]:
    """
    Extract useful technical/job keywords from a job description.
    """

    normalized = normalize_text(text)

    skills = {
        "python",
        "java",
        "javascript",
        "typescript",
        "react",
        "node.js",
        "fastapi",
        "django",
        "flask",
        "sql",
        "postgresql",
        "mysql",
        "mongodb",
        "docker",
        "kubernetes",
        "aws",
        "azure",
        "gcp",
        "git",
        "github",
        "linux",
        "terraform",
        "jenkins",
        "ansible",
        "redis",
        "graphql",
        "rest api",
        "html",
        "css",
        "tailwind",
        "next.js",
        "express",
        "spring",
        "c++",
        "c#",
        "php",
        "laravel",
        "go",
        "rust",
        "kotlin",
        "swift",
        "pandas",
        "numpy",
        "scikit-learn",
        "tensorflow",
        "pytorch",
        "machine learning",
        "deep learning",
        "data science",
        "power bi",
        "tableau",
    }

    detected = set()

    for skill in skills:
        pattern = (
            r"(?<![a-z0-9+#.])"
            + re.escape(skill)
            + r"(?![a-z0-9+#.])"
        )

        if re.search(pattern, normalized):
            detected.add(skill)

    return detected


def calculate_match_score(
    resume_text: str,
    job_description: str,
) -> dict:

    resume_keywords = extract_keywords(resume_text)
    job_keywords = extract_keywords(job_description)

    if not job_keywords:
        return {
            "match_score": 0,
            "matching_skills": [],
            "missing_skills": [],
            "resume_skills": sorted(resume_keywords),
            "job_skills": [],
        }

    matching_skills = resume_keywords.intersection(job_keywords)
    missing_skills = job_keywords - resume_keywords

    match_score = round(
        (len(matching_skills) / len(job_keywords)) * 100
    )

    return {
        "match_score": min(match_score, 100),
        "matching_skills": sorted(matching_skills),
        "missing_skills": sorted(missing_skills),
        "resume_skills": sorted(resume_keywords),
        "job_skills": sorted(job_keywords),
    }


def generate_match_suggestions(
    matching_skills: list[str],
    missing_skills: list[str],
    match_score: int,
) -> list[str]:

    suggestions = []

    if match_score < 40:
        suggestions.append(
            "Your resume has a low match with this job description. "
            "Consider tailoring your resume significantly."
        )

    elif match_score < 70:
        suggestions.append(
            "Your resume has a moderate match. Add relevant missing "
            "skills where you genuinely have experience."
        )

    else:
        suggestions.append(
            "Your resume has a strong technical match with this job."
        )

    if missing_skills:
        skills = ", ".join(missing_skills[:8])

        suggestions.append(
            f"Consider highlighting relevant experience with: {skills}."
        )

    if len(matching_skills) >= 5:
        suggestions.append(
            "Your resume already contains several keywords relevant "
            "to this position."
        )

    return suggestions


def match_resume_to_job(
    resume_text: str,
    job_description: str,
) -> dict:

    result = calculate_match_score(
        resume_text=resume_text,
        job_description=job_description,
    )

    suggestions = generate_match_suggestions(
        matching_skills=result["matching_skills"],
        missing_skills=result["missing_skills"],
        match_score=result["match_score"],
    )

    result["suggestions"] = suggestions

    return result