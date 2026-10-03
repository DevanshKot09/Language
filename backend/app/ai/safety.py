import re
from typing import Tuple


# Prohibited diagnostic claims / clinical diagnostic labels in learner-facing responses
PROHIBITED_DIAGNOSTIC_PATTERNS = [
    r"\byou have dld\b",
    r"\byou have dyslexia\b",
    r"\bdld diagnosis\b",
    r"\bdyslexia diagnosis\b",
    r"\bdld probability\b",
    r"\bdyslexia probability\b",
    r"\bclinical severity\b",
    r"\bclinical score\b",
    r"\bmedical diagnosis\b",
    r"\bpronunciation diagnosis\b",
    r"\breading disorder score\b",
    r"\bspeech disorder score\b",
    r"\bdiagnostic probability\b",
    r"\bmedical prediction\b",
    r"\bclinical treatment\b",
]

# Legitimate non-diagnostic safety disclaimers that should NOT be rejected
EXEMPT_SAFETY_PATTERNS = [
    r"not a (clinical|medical) diagnosis",
    r"is not a diagnosis",
    r"educational support, not diagnosis",
    r"non-diagnostic",
]


class AiSafetyValidator:
    """
    Centralized validation enforcing medical-safety boundaries on all AI outputs.
    Ensures no clinical diagnosis, medical predictions, or severity scoring reaches the learner.
    """

    @classmethod
    def validate_text(cls, text: str) -> Tuple[bool, str]:
        """
        Validates output string. Returns (is_safe, error_or_reason).
        """
        if not text:
            return True, ""

        normalized = text.lower()
        # Clean extra whitespace
        normalized = re.sub(r"\s+", " ", normalized).strip()

        # Check if text contains exempt educational/safety disclaimers
        for exempt in EXEMPT_SAFETY_PATTERNS:
            if re.search(exempt, normalized):
                # Temporarily mask the exempt phrase to inspect the remaining content
                normalized = re.sub(exempt, "[exempt_disclaimer]", normalized)

        # Check for prohibited clinical diagnostic concepts
        for pattern in PROHIBITED_DIAGNOSTIC_PATTERNS:
            if re.search(pattern, normalized):
                return False, f"Prohibited clinical/diagnostic pattern detected: {pattern}"

        return True, ""
