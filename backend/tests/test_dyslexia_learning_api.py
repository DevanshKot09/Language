import pytest
from fastapi.testclient import TestClient


def setup_learner(client: TestClient, token: str, age_band: str = "child", support_focus: str = "dyslexia_track"):
    headers = {"Authorization": f"Bearer {token}"}
    client.post(
        "/api/v1/auth/sync",
        headers=headers,
        json={"email": f"{token}@lingua.ai", "role": "learner"},
    )
    client.put(
        "/api/v1/profile/",
        headers=headers,
        json={
            "display_name": "Literacy Learner",
            "age_band": age_band,
            "support_focus": support_focus,
        },
    )
    return headers


def test_dyslexia_lessons_retrieval_and_filtering(client: TestClient):
    """Verify that querying Dyslexia lessons returns only dyslexia track lessons."""
    headers = setup_learner(client, "valid_token_dys_user_1", age_band="all", support_focus="dyslexia_track")

    # 1. Fetch Dyslexia track lessons
    response = client.get("/api/v1/lessons?track=dyslexia_track", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 10

    for lesson in data:
        assert lesson["track"] in ("dyslexia_track", "both_track")
        assert "dld" not in lesson["id"].lower()


def test_dyslexia_lessons_age_band_adaptation(client: TestClient):
    """Verify that Child, Teen, and Adult receive distinct age-appropriate Dyslexia lessons."""
    headers = setup_learner(client, "valid_token_dys_age_user", age_band="all", support_focus="dyslexia_track")

    # Child Dyslexia lessons
    res_child = client.get("/api/v1/lessons?track=dyslexia_track&age_band=child", headers=headers)
    assert res_child.status_code == 200
    child_lessons = res_child.json()
    assert len(child_lessons) >= 4
    for l in child_lessons:
        assert l["age_band"] in ("child", "all")
        assert l["difficulty"] in (1, 2)

    # Teen Dyslexia lessons
    res_teen = client.get("/api/v1/lessons?track=dyslexia_track&age_band=teen", headers=headers)
    assert res_teen.status_code == 200
    teen_lessons = res_teen.json()
    assert len(teen_lessons) >= 4
    for l in teen_lessons:
        assert l["age_band"] in ("teen", "all")
        assert l["difficulty"] in (1, 2, 3)

    # Adult Dyslexia lessons
    res_adult = client.get("/api/v1/lessons?track=dyslexia_track&age_band=adult", headers=headers)
    assert res_adult.status_code == 200
    adult_lessons = res_adult.json()
    assert len(adult_lessons) >= 4
    for l in adult_lessons:
        assert l["age_band"] in ("adult", "all")
        assert l["difficulty"] in (2, 3, 4)


def test_dyslexia_phonological_and_phonics_evaluation(client: TestClient):
    """Verify that phonological awareness and phonics exercises evaluate deterministically."""
    headers = setup_learner(client, "valid_token_dys_phono", age_band="child", support_focus="dyslexia_track")

    # Fetch child phonological lesson
    detail_res = client.get("/api/v1/lessons/lesson-dys-001", headers=headers)
    assert detail_res.status_code == 200
    lesson = detail_res.json()
    assert lesson["title"] == "Rhyme & Syllable Discovery"

    # Start lesson
    start_res = client.post("/api/v1/lessons/lesson-dys-001/start", headers=headers)
    assert start_res.status_code == 200

    exercises = lesson["exercises"]
    assert len(exercises) >= 3
    ex1 = exercises[0]
    assert ex1["exercise_type"] == "phonological_awareness"

    # Correct response for rhyming
    correct_payload = {
        "response": "run",
        "attempt_number": 1,
        "hint_used": False,
        "time_spent_ms": 2500,
    }
    att_res = client.post(f"/api/v1/exercises/{ex1['id']}/attempt", json=correct_payload, headers=headers)
    assert att_res.status_code == 200
    att_data = att_res.json()
    assert att_data["is_correct"] is True
    assert att_data["status"] == "correct"
    assert att_data["partial_score"] == 1.0


def test_dyslexia_word_building_and_spelling_evaluation(client: TestClient):
    """Verify that word building with letter tiles and spelling selection evaluate deterministically."""
    headers = setup_learner(client, "valid_token_dys_speller", age_band="child", support_focus="dyslexia_track")

    detail_res = client.get("/api/v1/lessons/lesson-dys-004", headers=headers)
    assert detail_res.status_code == 200
    lesson = detail_res.json()
    assert lesson["title"] == "Building Simple Words"

    exercises = lesson["exercises"]
    ex_wb = [e for e in exercises if e["exercise_type"] == "word_building"][0]

    # Submit letter tile array
    wb_payload = {
        "response": ["s", "h", "i", "p"],
        "attempt_number": 1,
        "hint_used": False,
        "time_spent_ms": 3000,
    }
    wb_res = client.post(f"/api/v1/exercises/{ex_wb['id']}/attempt", json=wb_payload, headers=headers)
    assert wb_res.status_code == 200
    wb_data = wb_res.json()
    assert wb_data["is_correct"] is True
    assert wb_data["status"] == "correct"

    # Also test spelling multiple choice
    ex_sp = [e for e in exercises if e["exercise_type"] == "spelling"][0]
    sp_payload = {
        "response": "a",
        "attempt_number": 1,
        "hint_used": False,
        "time_spent_ms": 2000,
    }
    sp_res = client.post(f"/api/v1/exercises/{ex_sp['id']}/attempt", json=sp_payload, headers=headers)
    assert sp_res.status_code == 200
    sp_data = sp_res.json()
    assert sp_data["is_correct"] is True


def test_dyslexia_reading_passage_and_comprehension(client: TestClient):
    """Verify that reading passages and comprehension questions evaluate accurately."""
    headers = setup_learner(client, "valid_token_dys_reader", age_band="child", support_focus="dyslexia_track")

    detail_res = client.get("/api/v1/lessons/lesson-dys-005", headers=headers)
    assert detail_res.status_code == 200
    lesson = detail_res.json()

    ex = lesson["exercises"][0]
    assert ex["exercise_type"] == "reading_passage"
    assert "passage" in ex["content"]

    reading_payload = {
        "response": "His friendly puppy Milo",
        "attempt_number": 1,
        "hint_used": False,
        "time_spent_ms": 4000,
    }
    r_res = client.post(f"/api/v1/exercises/{ex['id']}/attempt", json=reading_payload, headers=headers)
    assert r_res.status_code == 200
    assert r_res.json()["is_correct"] is True


def test_dyslexia_non_diagnostic_safety_guard(client: TestClient):
    """Verify that Dyslexia lessons and exercises never contain clinical diagnostic claims."""
    headers = setup_learner(client, "valid_token_dys_safety", age_band="all", support_focus="dyslexia_track")

    response = client.get("/api/v1/lessons?track=dyslexia_track", headers=headers)
    assert response.status_code == 200
    lessons = response.json()

    forbidden_clinical_terms = [
        "you have dyslexia",
        "diagnosed with dyslexia",
        "dyslexia severity",
        "dyslexia probability",
        "dyslexia score",
        "reading disorder score",
    ]

    for lesson in lessons:
        text_corpus = f"{lesson['title']} {lesson['description']}".lower()
        for forbidden in forbidden_clinical_terms:
            assert forbidden not in text_corpus, f"Found forbidden term '{forbidden}' in lesson {lesson['id']}"

        # Fetch detail and inspect exercises
        det = client.get(f"/api/v1/lessons/{lesson['id']}", headers=headers).json()
        for ex in det.get("exercises", []):
            ex_corpus = f"{ex['prompt']} {ex['instruction']} {ex.get('explanation', '')}".lower()
            for forbidden in forbidden_clinical_terms:
                assert forbidden not in ex_corpus, f"Found forbidden term '{forbidden}' in exercise {ex['id']}"
