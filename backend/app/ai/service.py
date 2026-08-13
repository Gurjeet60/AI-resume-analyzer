from __future__ import annotations

from typing import Optional

from openai import OpenAI

from app.ai.prompts import SYSTEM_PROMPT, USER_PROMPT_TEMPLATE
from app.ai.schemas import AIResumeAnalysis
from app.core.config import settings


class AIService:
    def __init__(self) -> None:
        self.model = settings.OPENAI_MODEL

        self.client: Optional[OpenAI] = (
            OpenAI(api_key=settings.OPENAI_API_KEY)
            if settings.OPENAI_API_KEY
            else None
        )

    @property
    def enabled(self) -> bool:
        return self.client is not None

    def analyze_resume(
        self,
        resume_text: str,
        score: int,
        skills: list[str],
        sections: dict[str, bool],
    ) -> Optional[AIResumeAnalysis]:

        if not self.client:
            return None

        prompt = USER_PROMPT_TEMPLATE.format(
            score=score,
            skills=", ".join(skills)
            if skills
            else "None detected",
            sections=", ".join(
                key
                for key, value in sections.items()
                if value
            )
            or "No sections detected",
            resume_text=resume_text[:30000],
        )

        response = self.client.responses.parse(
            model=self.model,
            input=[
                {
                    "role": "system",
                    "content": SYSTEM_PROMPT,
                },
                {
                    "role": "user",
                    "content": prompt,
                },
            ],
            text_format=AIResumeAnalysis,
        )

        return response.output_parsed