import re


COMMON_SKILLS = {
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
    "rest api",
    "graphql",
}


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text.lower()).strip()


def detect_skills(text: str) -> list[str]:
    normalized = normalize_text(text)

    detected = []

    for skill in COMMON_SKILLS:
        if skill in normalized:
            detected.append(skill)

    return sorted(detected)


def detect_sections(text: str) -> dict:
    normalized = normalize_text(text)

    sections = {
        "contact": False,
        "summary": False,
        "skills": False,
        "experience": False,
        "education": False,
        "projects": False,
    }

    section_keywords = {
        "contact": [
            "email",
            "phone",
            "linkedin",
            "github",
        ],
        "summary": [
            "summary",
            "profile",
            "objective",
        ],
        "skills": [
            "skills",
            "technical skills",
            "technologies",
        ],
        "experience": [
            "experience",
            "work experience",
            "employment",
        ],
        "education": [
            "education",
            "academic",
            "university",
            "college",
        ],
        "projects": [
            "projects",
            "personal projects",
            "project experience",
        ],
    }

    for section, keywords in section_keywords.items():
        for keyword in keywords:
            if keyword in normalized:
                sections[section] = True
                break

    return sections


def calculate_score(
    text: str,
    skills: list[str],
    sections: dict,
) -> int:

    score = 0

    # Resume has meaningful content
    if len(text) >= 500:
        score += 15

    if len(text) >= 1000:
        score += 10

    # Skills
    if len(skills) >= 3:
        score += 10

    if len(skills) >= 7:
        score += 10

    # Sections
    section_weights = {
        "contact": 10,
        "summary": 10,
        "skills": 10,
        "experience": 15,
        "education": 10,
        "projects": 10,
    }

    for section, weight in section_weights.items():
        if sections.get(section):
            score += weight

    return min(score, 100)


def generate_suggestions(
    skills: list[str],
    sections: dict,
) -> list[str]:

    suggestions = []

    if not sections["summary"]:
        suggestions.append(
            "Add a professional summary at the beginning of the resume."
        )

    if not sections["skills"]:
        suggestions.append(
            "Add a dedicated technical skills section."
        )

    if not sections["experience"]:
        suggestions.append(
            "Add relevant work experience or internship experience."
        )

    if not sections["education"]:
        suggestions.append(
            "Add your education details."
        )

    if not sections["projects"]:
        suggestions.append(
            "Add relevant projects with technologies and measurable results."
        )

    if len(skills) < 5:
        suggestions.append(
            "Add more relevant technical skills and keywords."
        )

    if len(skills) >= 10:
        suggestions.append(
            "Good technical skill coverage. Focus on measurable achievements."
        )

    return suggestions


def analyze_resume(text: str) -> dict:

    skills = detect_skills(text)

    sections = detect_sections(text)

    score = calculate_score(
        text=text,
        skills=skills,
        sections=sections,
    )

    suggestions = generate_suggestions(
        skills=skills,
        sections=sections,
    )

    return {
        "score": score,
        "skills": skills,
        "sections": sections,
        "suggestions": suggestions,
    }