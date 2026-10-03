import os
import json
import logging
from typing import Type, TypeVar
from pydantic import BaseModel
from app.ai.provider_interface import IAiProvider
from app.core.config import settings

logger = logging.getLogger(__name__)
T = TypeVar("T", bound=BaseModel)


class GeminiAiProvider(IAiProvider):
    """
    Google Gemini implementation using official google-genai SDK.
    Utilizes structured output with Pydantic response schemas.
    """

    def __init__(self, api_key: str = None, model: str = None):
        self._api_key = api_key or settings.GEMINI_API_KEY or os.getenv("GEMINI_API_KEY")
        self._model = model or settings.AI_MODEL or "gemini-2.5-flash"
        self._client = None

        if self._api_key:
            try:
                from google import genai
                self._client = genai.Client(api_key=self._api_key)
            except Exception as e:
                logger.warning(f"Could not initialize Google GenAI Client: {e}")

    @property
    def provider_name(self) -> str:
        return "gemini"

    async def generate_structured(
        self,
        prompt: str,
        response_schema: Type[T],
        temperature: float = 0.2,
    ) -> T:
        if not self._client:
            raise RuntimeError("Gemini Client not initialized or GEMINI_API_KEY not configured.")

        # Call google-genai client with response_schema
        response = self._client.models.generate_content(
            model=self._model,
            contents=prompt,
            config={
                "response_mime_type": "application/json",
                "response_schema": response_schema,
                "temperature": temperature,
                "max_output_tokens": settings.AI_MAX_OUTPUT_TOKENS,
            },
        )

        raw_text = response.text
        if not raw_text:
            raise ValueError("Empty response received from Gemini API")

        # Parse text into validated schema
        data = json.loads(raw_text)
        return response_schema.model_validate(data)
