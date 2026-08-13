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
    "ruby",
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


SECTION_KEYWORDS = {
    "contact": [
        "email",
        "phone",
        "mobile",
        "linkedin",
        "github",
        "contact",
    ],
    "summary": [
        "summary",
        "professional summary",
        "profile",
        "objective",
        "career objective",
        "about me",
    ],
    "skills": [
        "skills",
        "technical skills",
        "technical expertise",
        "technologies",
        "technology",
        "competencies",
    ],
    "experience": [
        "experience",
        "work experience",
        "professional experience",
        "employment",
        "work history",
        "internship",
    ],
    "education": [
        "education",
        "academic",
        "academic background",
        "university",
        "college",
        "degree",
        "bachelor",
        "master",
    ],
    "projects": [
        "projects",
        "personal projects",
        "academic projects",
        "project experience",
        "key projects",
    ],
}


ACTION_VERBS = {
    "built",
    "developed",
    "created",
    "designed",
    "implemented",
    "engineered",
    "managed",
    "led",
    "optimized",
    "automated",
    "deployed",
    "configured",
    "improved",
    "integrated",
    "maintained",
    "delivered",
    "develop",
    "build",
    "design",
    "implement",
    "manage",
    "lead",
    "optimize",
    "automate",
}


def normalize_text(text: str) -> str:
    """
    Normalize resume text for consistent analysis.
    """
    if not text:
        return ""

    text = text.lower()

    # Normalize common punctuation/separators.
    text = re.sub(r"[•▪●]", " ", text)
    text = re.sub(r"[/|]", " ", text)

    # Collapse whitespace.
    text = re.sub(r"\s+", " ", text)

    return text.strip()


def contains_keyword(text: str, keyword: str) -> bool:
    """
    Match complete words where possible.

    This prevents things such as:
        'go' matching 'google'
        'sql' matching unrelated text
    """
    keyword = keyword.lower().strip()

    if not keyword:
        return False

    pattern = r"(?<![a-z0-9+#.])" + re.escape(keyword) + r"(?![a-z0-9+#.])"

    return re.search(pattern, text) is not None


def detect_skills(text: str) -> list[str]:
    """
    Detect technical skills from the resume.
    """
    normalized = normalize_text(text)

    detected = []

    for skill in COMMON_SKILLS:
        if contains_keyword(normalized, skill):
            detected.append(skill)

    return sorted(detected)


def detect_sections(text: str) -> dict[str, bool]:
    """
    Detect important resume sections.
    """
    normalized = normalize_text(text)

    sections = {
        "contact": False,
        "summary": False,
        "skills": False,
        "experience": False,
        "education": False,
        "projects": False,
    }

    for section, keywords in SECTION_KEYWORDS.items():
        for keyword in keywords:
            if contains_keyword(normalized, keyword):
                sections[section] = True
                break

    return sections


def count_action_verbs(text: str) -> int:
    """
    Count unique action verbs used in the resume.
    """
    normalized = normalize_text(text)

    return sum(
        1
        for verb in ACTION_VERBS
        if contains_keyword(normalized, verb)
    )


def count_numbers(text: str) -> int:
    """
    Detect numbers that may represent measurable achievements.

    Examples:
        20%
        50 users
        $1000
        3 years
    """
    if not text:
        return 0

    matches = re.findall(
        r"\b\d+(?:\.\d+)?(?:%|[kKmMbB])?\b",
        text,
    )

    return len(matches)


def calculate_score(
    text: str,
    skills: list[str],
    sections: dict[str, bool],
) -> int:
    """
    Calculate a deterministic resume quality score.

    Maximum = 100 points.
    """

    normalized = normalize_text(text)

    if not normalized:
        return 0

    score = 0

    # ---------------------------------------------------------
    # 1. Resume content length - 15 points
    # ---------------------------------------------------------

    word_count = len(normalized.split())

    if word_count >= 300:
        score += 5

    if word_count >= 500:
        score += 5

    if word_count >= 700:
        score += 5

    # ---------------------------------------------------------
    # 2. Technical skills - 20 points
    # ---------------------------------------------------------

    skill_count = len(skills)

    if skill_count >= 3:
        score += 5

    if skill_count >= 5:
        score += 5

    if skill_count >= 8:
        score += 5

    if skill_count >= 12:
        score += 5

    # ---------------------------------------------------------
    # 3. Resume structure - 30 points
    # ---------------------------------------------------------

    section_weights = {
        "contact": 5,
        "summary": 5,
        "skills": 5,
        "experience": 7,
        "education": 4,
        "projects": 4,
    }

    for section, weight in section_weights.items():
        if sections.get(section, False):
            score += weight

    # ---------------------------------------------------------
    # 4. Action verbs - 15 points
    # ---------------------------------------------------------

    action_verb_count = count_action_verbs(normalized)

    if action_verb_count >= 2:
        score += 5

    if action_verb_count >= 4:
        score += 5

    if action_verb_count >= 6:
        score += 5

    # ---------------------------------------------------------
    # 5. Measurable achievements - 10 points
    # ---------------------------------------------------------

    number_count = count_numbers(normalized)

    if number_count >= 2:
        score += 5

    if number_count >= 5:
        score += 5

    # ---------------------------------------------------------
    # 6. Basic content quality - 10 points
    # ---------------------------------------------------------

    if sections.get("experience") and sections.get("education"):
        score += 5

    if sections.get("projects") and sections.get("skills"):
        score += 5

    return min(score, 100)


def generate_suggestions(
    text: str,
    skills: list[str],
    sections: dict[str, bool],
) -> list[str]:
    """
    Generate deterministic improvement suggestions.
    """

    normalized = normalize_text(text)

    suggestions: list[str] = []

    word_count = len(normalized.split())
    action_verb_count = count_action_verbs(normalized)
    number_count = count_numbers(normalized)

    # ---------------------------------------------------------
    # Structure suggestions
    # ---------------------------------------------------------

    if not sections["contact"]:
        suggestions.append(
            "Add clear contact information including email, phone, "
            "LinkedIn, or GitHub."
        )

    if not sections["summary"]:
        suggestions.append(
            "Add a concise professional summary describing your "
            "experience, strengths, and career goals."
        )

    if not sections["skills"]:
        suggestions.append(
            "Add a dedicated technical skills section with relevant "
            "technologies and tools."
        )

    if not sections["experience"]:
        suggestions.append(
            "Add relevant work experience, internships, or practical "
            "professional experience."
        )

    if not sections["education"]:
        suggestions.append(
            "Add your education details, degree, institution, and "
            "relevant academic information."
        )

    if not sections["projects"]:
        suggestions.append(
            "Add relevant projects and describe the technologies used "
            "and the results achieved."
        )

    # ---------------------------------------------------------
    # Skills suggestions
    # ---------------------------------------------------------

    if len(skills) < 3:
        suggestions.append(
            "Include more relevant technical skills and job-specific "
            "keywords to improve ATS matching."
        )
    elif len(skills) < 6:
        suggestions.append(
            "Consider adding more relevant technical skills that match "
            "the roles you are targeting."
        )

    # ---------------------------------------------------------
    # Achievement suggestions
    # ---------------------------------------------------------

    if action_verb_count < 3:
        suggestions.append(
            "Use stronger action verbs such as developed, implemented, "
            "optimized, automated, designed, or delivered."
        )

    if number_count < 3:
        suggestions.append(
            "Add measurable achievements using numbers, percentages, "
            "time saved, revenue, users, or performance improvements."
        )

    # ---------------------------------------------------------
    # Resume length
    # ---------------------------------------------------------

    if word_count < 300:
        suggestions.append(
            "Your resume appears short. Add relevant experience, "
            "projects, achievements, and technical details where appropriate."
        )

    elif word_count > 1500:
        suggestions.append(
            "Your resume is quite long. Consider removing repetitive "
            "or less relevant information."
        )

    # ---------------------------------------------------------
    # Positive feedback
    # ---------------------------------------------------------

    if (
        len(skills) >= 10
        and sections["experience"]
        and sections["projects"]
    ):
        suggestions.append(
            "Strong technical coverage. Focus on measurable achievements "
            "and tailoring keywords to each target job."
        )

    # Keep the response manageable.
    return suggestions[:8]


def analyze_resume(text: str) -> dict:
    """
    Complete deterministic resume analysis.
    """

    if not text or not text.strip():
        return {
            "score": 0,
            "skills": [],
            "sections": {
                "contact": False,
                "summary": False,
                "skills": False,
                "experience": False,
                "education": False,
                "projects": False,
            },
            "suggestions": [
                "No readable resume content was found."
            ],
        }

    skills = detect_skills(text)

    sections = detect_sections(text)

    score = calculate_score(
        text=text,
        skills=skills,
        sections=sections,
    )

    suggestions = generate_suggestions(
        text=text,
        skills=skills,
        sections=sections,
    )

    return {
        "score": score,
        "skills": skills,
        "sections": sections,
        "suggestions": suggestions,
    }