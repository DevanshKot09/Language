import json
from typing import Any, Dict, List, Optional, Tuple


class EvaluationResult:
    def __init__(
        self,
        status: str,  # "correct", "partially_correct", "incorrect"
        is_correct: bool,
        partial_score: float,
        feedback_message: str,
        explanation: Optional[str] = None,
    ):
        self.status = status
        self.is_correct = is_correct
        self.partial_score = partial_score
        self.feedback_message = feedback_message
        self.explanation = explanation

    def to_dict(self) -> Dict[str, Any]:
        return {
            "status": self.status,
            "is_correct": self.is_correct,
            "partial_score": self.partial_score,
            "feedback_message": self.feedback_message,
            "explanation": self.explanation,
        }


class ExerciseEvaluator:
    """
    Deterministic evaluation engine for all supported LINGUA AI exercise types.
    Non-diagnostic: never generates clinical labels or disorder severity estimates.
    Provides encouraging, age-adaptive, educational feedback.
    """

    @classmethod
    def evaluate(
        cls,
        exercise_type: str,
        user_response: Any,
        correct_answer_raw: str,
        explanation: Optional[str] = None,
        feedback_config_raw: Optional[str] = None,
        age_band: str = "all",
    ) -> EvaluationResult:
        # Normalize age band
        age_band = age_band.lower() if age_band else "all"

        # Parse correct answer
        parsed_correct = cls._parse_json_or_str(correct_answer_raw)
        feedback_config = cls._parse_json_or_dict(feedback_config_raw)

        evaluator_method = getattr(cls, f"_evaluate_{exercise_type}", cls._evaluate_generic)
        status, is_correct, partial_score = evaluator_method(user_response, parsed_correct)

        feedback_msg = cls._generate_feedback(status, age_band, feedback_config)

        return EvaluationResult(
            status=status,
            is_correct=is_correct,
            partial_score=partial_score,
            feedback_message=feedback_msg,
            explanation=explanation,
        )

    @classmethod
    def _evaluate_generic(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        norm_resp = cls._normalize_str(user_response)
        norm_corr = cls._normalize_str(correct)
        if norm_resp == norm_corr:
            return "correct", True, 1.0
        return "incorrect", False, 0.0

    @classmethod
    def _evaluate_multiple_choice(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        norm_resp = cls._normalize_str(user_response)
        norm_corr = cls._normalize_str(correct)
        if norm_resp == norm_corr:
            return "correct", True, 1.0
        return "incorrect", False, 0.0

    @classmethod
    def _evaluate_sentence_completion(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_multiple_choice(user_response, correct)

    @classmethod
    def _evaluate_spelling_selection(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_multiple_choice(user_response, correct)

    @classmethod
    def _evaluate_reading_passage(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_multiple_choice(user_response, correct)

    @classmethod
    def _evaluate_listening_comprehension(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_multiple_choice(user_response, correct)

    @classmethod
    def _evaluate_social_communication(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_multiple_choice(user_response, correct)

    @classmethod
    def _evaluate_phonological_awareness(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_multiple_choice(user_response, correct)

    @classmethod
    def _evaluate_phonics(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_multiple_choice(user_response, correct)

    @classmethod
    def _evaluate_decoding(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_multiple_choice(user_response, correct)

    @classmethod
    def _evaluate_spelling(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_multiple_choice(user_response, correct)

    @classmethod
    def _evaluate_reading_comprehension(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_multiple_choice(user_response, correct)

    @classmethod
    def _evaluate_speaking_practice(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        """
        Evaluates learner's spoken response text (or typed alternative).
        Non-diagnostic: does NOT score pronunciation, accent, or clinical fluency.
        Checks for substantive engagement with the prompt (non-empty response).
        """
        resp_str = str(user_response or "").strip()
        if len(resp_str) >= 2:
            return "correct", True, 1.0
        return "incorrect", False, 0.0

    @classmethod
    def _evaluate_speaking(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_speaking_practice(user_response, correct)

    @classmethod
    def _evaluate_reading_aloud(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        return cls._evaluate_speaking_practice(user_response, correct)

    @classmethod
    def _evaluate_word_building(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        """
        Evaluates constructing words from letter/sound tiles.
        Accepts list of tiles (e.g. ['c', 'a', 't']) or concatenated string ('cat').
        """
        if isinstance(user_response, list):
            resp_str = "".join(str(item).strip() for item in user_response)
        else:
            resp_str = str(user_response or "").replace(" ", "").strip()

        if isinstance(correct, list):
            corr_str = "".join(str(item).strip() for item in correct)
        else:
            corr_str = str(correct or "").replace(" ", "").strip()

        norm_resp = resp_str.lower()
        norm_corr = corr_str.lower()

        if norm_resp == norm_corr and len(norm_corr) > 0:
            return "correct", True, 1.0

        # Partial matching if prefix/suffix matches
        if len(norm_corr) > 0 and len(norm_resp) > 0:
            matches = sum(1 for r, c in zip(norm_resp, norm_corr) if r == c)
            score = round(matches / len(norm_corr), 2)
            if score >= 0.5:
                return "partially_correct", False, score

        return "incorrect", False, 0.0

    @classmethod
    def _evaluate_word_order(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        """
        Evaluates rearranged words or tokens.
        Accepts list of tokens or space-delimited string.
        Supports partial score if significant portion matches.
        """
        resp_tokens = cls._to_token_list(user_response)
        corr_tokens = cls._to_token_list(correct)

        if not resp_tokens or not corr_tokens:
            return "incorrect", False, 0.0

        if resp_tokens == corr_tokens:
            return "correct", True, 1.0

        # Calculate matching tokens in identical positions
        matches = sum(1 for r, c in zip(resp_tokens, corr_tokens) if r == c)
        total = len(corr_tokens)
        score = round(matches / total, 2) if total > 0 else 0.0

        if score >= 0.5:
            return "partially_correct", False, score
        return "incorrect", False, score

    @classmethod
    def _evaluate_narrative_sequencing(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        """
        Evaluates ordering of narrative sequence events.
        """
        resp_items = cls._to_token_list(user_response)
        corr_items = cls._to_token_list(correct)

        if not resp_items or not corr_items:
            return "incorrect", False, 0.0

        if resp_items == corr_items:
            return "correct", True, 1.0

        matches = sum(1 for r, c in zip(resp_items, corr_items) if r == c)
        total = len(corr_items)
        score = round(matches / total, 2) if total > 0 else 0.0

        if score >= 0.5:
            return "partially_correct", False, score
        return "incorrect", False, score

    @classmethod
    def _evaluate_matching(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        """
        Evaluates key-value matching pairs.
        Accepts dict {key: val} or list of [key, val] pairs.
        """
        resp_dict = cls._to_dict(user_response)
        corr_dict = cls._to_dict(correct)

        if not resp_dict or not corr_dict:
            return "incorrect", False, 0.0

        total = len(corr_dict)
        matches = sum(1 for k, v in corr_dict.items() if cls._normalize_str(resp_dict.get(k)) == cls._normalize_str(v))

        if matches == total:
            return "correct", True, 1.0
        elif matches > 0:
            score = round(matches / total, 2)
            return "partially_correct", False, score
        return "incorrect", False, 0.0

    @classmethod
    def _evaluate_text_input(cls, user_response: Any, correct: Any) -> Tuple[str, bool, float]:
        norm_resp = cls._normalize_str(user_response)
        norm_corr = cls._normalize_str(correct)
        if norm_resp == norm_corr:
            return "correct", True, 1.0
        return "incorrect", False, 0.0

    @classmethod
    def _generate_feedback(cls, status: str, age_band: str, config: Dict[str, Any]) -> str:
        # Check custom configuration first
        if config:
            custom_msg = config.get(status)
            if custom_msg:
                return custom_msg

        # Age-adaptive encouraging feedback
        if age_band == "child":
            if status == "correct":
                return "Wonderful job! You found the right answer."
            elif status == "partially_correct":
                return "Great effort! You got parts of it right. Let's look again at the rest."
            else:
                return "Good try! Look closely at the clue and give it another try."
        elif age_band == "teen":
            if status == "correct":
                return "Accurate! You mastered this concept."
            elif status == "partially_correct":
                return "Good progress. Check the order or remaining items and refine your answer."
            else:
                return "Not quite yet. Check the hint and test another option."
        else:  # Adult or all
            if status == "correct":
                return "Correct. Excellent application of this language structure."
            elif status == "partially_correct":
                return "Partially correct. Review the remaining elements and refine your response."
            else:
                return "Not quite. Check the guidance and give it another try."

    @staticmethod
    def _normalize_str(val: Any) -> str:
        if val is None:
            return ""
        if isinstance(val, (dict, list)):
            return json.dumps(val, sort_keys=True).strip().lower()
        return str(val).strip().lower()

    @staticmethod
    def _parse_json_or_str(raw: Any) -> Any:
        if isinstance(raw, str):
            try:
                return json.loads(raw)
            except Exception:
                return raw
        return raw

    @staticmethod
    def _parse_json_or_dict(raw: Any) -> Dict[str, Any]:
        if isinstance(raw, dict):
            return raw
        if isinstance(raw, str):
            try:
                parsed = json.loads(raw)
                if isinstance(parsed, dict):
                    return parsed
            except Exception:
                return {}
        return {}

    @classmethod
    def _to_token_list(cls, val: Any) -> List[str]:
        if isinstance(val, list):
            return [cls._normalize_str(x) for x in val if x is not None]
        if isinstance(val, str):
            # Try parsing as JSON list
            try:
                parsed = json.loads(val)
                if isinstance(parsed, list):
                    return [cls._normalize_str(x) for x in parsed if x is not None]
            except Exception:
                pass
            # Split by whitespace
            return [cls._normalize_str(w) for w in val.split() if w]
        return []

    @classmethod
    def _to_dict(cls, val: Any) -> Dict[str, Any]:
        if isinstance(val, dict):
            return {cls._normalize_str(k): cls._normalize_str(v) for k, v in val.items()}
        if isinstance(val, list):
            res = {}
            for item in val:
                if isinstance(item, (list, tuple)) and len(item) >= 2:
                    res[cls._normalize_str(item[0])] = cls._normalize_str(item[1])
                elif isinstance(item, dict) and "key" in item and "value" in item:
                    res[cls._normalize_str(item["key"])] = cls._normalize_str(item["value"])
            return res
        if isinstance(val, str):
            try:
                parsed = json.loads(val)
                return cls._to_dict(parsed)
            except Exception:
                pass
        return {}
