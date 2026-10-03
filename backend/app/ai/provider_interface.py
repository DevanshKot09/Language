from abc import ABC, abstractmethod
from typing import Dict, Any, Type, TypeVar
from pydantic import BaseModel

T = TypeVar("T", bound=BaseModel)


class IAiProvider(ABC):
    """
    Abstract interface for AI model providers (Gemini, Local Models, Mocks).
    Prevents vendor lock-in and isolates provider SDKs.
    """

    @abstractmethod
    async def generate_structured(
        self,
        prompt: str,
        response_schema: Type[T],
        temperature: float = 0.2,
    ) -> T:
        """
        Generates structured output conforming strictly to the provided Pydantic model schema.
        """
        pass

    @property
    @abstractmethod
    def provider_name(self) -> str:
        pass
