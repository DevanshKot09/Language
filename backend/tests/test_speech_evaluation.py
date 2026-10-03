import pytest
from app.services.evaluator import ExerciseEvaluator


def test_speaking_practice_evaluation_success():
    result = ExerciseEvaluator.evaluate(
        exercise_type="speaking_practice",
        user_response="I went to the library and borrowed a book.",
        correct_answer_raw="spoken response",
        age_band="teen",
    )
    assert result.is_correct is True
    assert result.status == "correct"
    assert result.partial_score == 1.0
    assert "Accurate!" in result.feedback_message


def test_speaking_practice_evaluation_empty_response():
    result = ExerciseEvaluator.evaluate(
        exercise_type="speaking_practice",
        user_response="   ",
        correct_answer_raw="spoken response",
        age_band="child",
    )
    assert result.is_correct is False
    assert result.status == "incorrect"
    assert result.partial_score == 0.0


def test_reading_aloud_evaluation_non_diagnostic():
    result = ExerciseEvaluator.evaluate(
        exercise_type="reading_aloud",
        user_response="The quick brown fox jumps over the lazy dog.",
        correct_answer_raw="spoken text",
        age_band="adult",
    )
    assert result.is_correct is True
    assert result.status == "correct"
    # Verify no diagnostic or pronunciation score claims
    msg = result.feedback_message.lower()
    for forbidden in ["pronunciation", "clinical", "wcpm", "disorder", "dyslexia", "dld"]:
        assert forbidden not in msg
