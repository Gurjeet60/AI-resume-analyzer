from pydantic import BaseModel, Field


class AIResumeAnalysis(BaseModel):
    summary: str = Field(
        description="A concise professional summary of the resume."
    )

    strengths: list[str] = Field(
        description="Specific strengths found in the actual resume."
    )

    weaknesses: list[str] = Field(
        description="Specific weaknesses or gaps found in the actual resume."
    )

    recommendations: list[str] = Field(
        description="Actionable recommendations for improving the resume."
    )

    ats_keywords: list[str] = Field(
        description="Important ATS keywords that are present or should be emphasized."
    )

    career_summary: str = Field(
        description="A concise assessment of the candidate's professional profile and career positioning."
    )