import json
from sqlalchemy.orm import Session
from app.models.skill import Skill
from app.models.baseline import BaselineActivity

SKILLS_SEED_DATA = [
    # DLD / Spoken Language Track
    {
        "code": "dld_vocabulary",
        "name": "Vocabulary Breadth & Depth",
        "description": "Targeted word learning with phonological and semantic cues and retrieval practice.",
        "track": "dld_track",
        "domain": "vocabulary",
        "age_band_applicability": "all",
        "priority": "ESSENTIAL",
    },
    {
        "code": "dld_grammar",
        "name": "Morphosyntax & Grammar",
        "description": "Grammatical morphemes, verb tense agreement, and syntactic structures.",
        "track": "dld_track",
        "domain": "grammar",
        "age_band_applicability": "all",
        "priority": "ESSENTIAL",
    },
    {
        "code": "dld_sentence_formation",
        "name": "Sentence Formulation & Comprehension",
        "description": "Building and understanding complex sentence clauses and connecting ideas.",
        "track": "dld_track",
        "domain": "syntax",
        "age_band_applicability": "all",
        "priority": "ESSENTIAL",
    },
    {
        "code": "dld_listening_comprehension",
        "name": "Listening Comprehension",
        "description": "Following multi-step oral instructions, extracting central themes, and inferencing.",
        "track": "dld_track",
        "domain": "comprehension",
        "age_band_applicability": "all",
        "priority": "ESSENTIAL",
    },
    {
        "code": "dld_narrative_storytelling",
        "name": "Narrative Macrostructure & Retell",
        "description": "Story grammar elements: setting, initiating event, internal response, attempt, consequence.",
        "track": "dld_track",
        "domain": "narrative",
        "age_band_applicability": "all",
        "priority": "IMPORTANT",
    },
    {
        "code": "dld_pragmatics",
        "name": "Social Communication & Pragmatics",
        "description": "Contextual communicative intent, conversational repair, and perspective taking.",
        "track": "dld_track",
        "domain": "pragmatics",
        "age_band_applicability": "all",
        "priority": "IMPORTANT",
    },
    # Literacy & Reading / Dyslexia Track
    {
        "code": "dys_phonological_awareness",
        "name": "Phonological & Phonemic Awareness",
        "description": "Sound isolation, blending, segmenting, and phoneme manipulation.",
        "track": "dyslexia_track",
        "domain": "phonology",
        "age_band_applicability": "all",
        "priority": "ESSENTIAL",
    },
    {
        "code": "dys_phonics",
        "name": "Systematic Phonics & Grapheme Mapping",
        "description": "Explicit sound-symbol correspondence, vowel teams, and syllable types.",
        "track": "dyslexia_track",
        "domain": "phonics",
        "age_band_applicability": "all",
        "priority": "ESSENTIAL",
    },
    {
        "code": "dys_decoding",
        "name": "Word Recognition & Decoding",
        "description": "Regular decoding, multisyllabic word attack, and high-frequency orthographic recognition.",
        "track": "dyslexia_track",
        "domain": "decoding",
        "age_band_applicability": "all",
        "priority": "ESSENTIAL",
    },
    {
        "code": "dys_spelling",
        "name": "Spelling & Orthographic Patterns",
        "description": "Encoding phonemes into graphemes, morphological spelling rules, and word families.",
        "track": "dyslexia_track",
        "domain": "spelling",
        "age_band_applicability": "all",
        "priority": "IMPORTANT",
    },
    {
        "code": "dys_fluency",
        "name": "Reading Fluency & Automaticity",
        "description": "Accurate, paced reading in connected text with natural phrasing.",
        "track": "dyslexia_track",
        "domain": "fluency",
        "age_band_applicability": "all",
        "priority": "ESSENTIAL",
    },
    {
        "code": "dys_reading_comprehension",
        "name": "Text Comprehension & Strategy Use",
        "description": "Comprehension strategies, summarization, and text structure analysis.",
        "track": "dyslexia_track",
        "domain": "comprehension",
        "age_band_applicability": "all",
        "priority": "ESSENTIAL",
    },
]

ACTIVITIES_SEED_DATA = [
    # Child DLD activities
    {
        "skill_code": "dld_vocabulary",
        "track": "dld_track",
        "domain": "vocabulary",
        "age_band": "child",
        "activity_type": "vocabulary_choice",
        "instruction": "Look at the picture word and choose what it means.",
        "prompt": "A 'burrow' is a warm tunnel home built by animals.",
        "options": ["An animal's underground home", "A type of bird", "A tall tree", "A shiny rock"],
        "correct_answer": "An animal's underground home",
        "hint": "Rabbits and badgers dig these into the ground.",
        "difficulty": 1,
    },
    {
        "skill_code": "dld_grammar",
        "track": "dld_track",
        "domain": "grammar",
        "age_band": "child",
        "activity_type": "grammar_agreement",
        "instruction": "Choose the word that correctly finishes the sentence.",
        "prompt": "Yesterday, the children ____ to the community garden.",
        "options": ["walked", "walks", "walking", "will walk"],
        "correct_answer": "walked",
        "hint": "This happened yesterday in the past.",
        "difficulty": 1,
    },
    {
        "skill_code": "dld_sentence_formation",
        "track": "dld_track",
        "domain": "syntax",
        "age_band": "child",
        "activity_type": "grammar_agreement",
        "instruction": "Which sentence makes the most sense?",
        "prompt": "Choose the sentence that links the ideas together smoothly.",
        "options": [
            "We put on our coats because it was raining outside.",
            "Because it was raining we coats outside.",
            "Coats we put on it was raining.",
            "We put raining because on coats.",
        ],
        "correct_answer": "We put on our coats because it was raining outside.",
        "hint": "Look for the sentence with subject, verb, and connector.",
        "difficulty": 1,
    },
    # Teen / Adult DLD activities
    {
        "skill_code": "dld_vocabulary",
        "track": "dld_track",
        "domain": "vocabulary",
        "age_band": "teen",
        "activity_type": "vocabulary_choice",
        "instruction": "Determine the meaning of the target word from context.",
        "prompt": "The environmental researcher needed to 'corroborate' the laboratory findings with field observations.",
        "options": [
            "To confirm or support with evidence",
            "To dispute or contradict publicly",
            "To discard as obsolete",
            "To translate into another language",
        ],
        "correct_answer": "To confirm or support with evidence",
        "hint": "Think about verifying data using multiple sources.",
        "difficulty": 2,
    },
    {
        "skill_code": "dld_grammar",
        "track": "dld_track",
        "domain": "grammar",
        "age_band": "teen",
        "activity_type": "grammar_agreement",
        "instruction": "Select the sentence with accurate verb tense and clause agreement.",
        "prompt": "Choose the grammatically consistent sentence.",
        "options": [
            "Neither the manager nor the technicians were aware of the power outage.",
            "Neither the manager nor the technicians was aware of the power outage.",
            "Neither the manager nor the technicians being aware of the power outage.",
            "Neither the manager nor the technicians is aware of the power outage.",
        ],
        "correct_answer": "Neither the manager nor the technicians were aware of the power outage.",
        "hint": "With 'neither... nor...', the verb agrees with the closer subject.",
        "difficulty": 2,
    },
    {
        "skill_code": "dld_listening_comprehension",
        "track": "dld_track",
        "domain": "comprehension",
        "age_band": "all",
        "activity_type": "reading_comprehension",
        "instruction": "Read the passage and select the central theme.",
        "prompt": "While planning the transit project, engineers prioritized bus rapid lanes over wider highways to reduce carbon emissions and ease daily commutes.",
        "options": [
            "Prioritizing efficient public transit over private vehicle infrastructure",
            "Canceling all municipal transport investments",
            "Expanding six-lane highways across the city",
            "Banning bus transportation in residential zones",
        ],
        "correct_answer": "Prioritizing efficient public transit over private vehicle infrastructure",
        "hint": "Focus on the main goal mentioned in the passage.",
        "difficulty": 2,
    },
    # Child Dyslexia activities
    {
        "skill_code": "dys_phonological_awareness",
        "track": "dyslexia_track",
        "domain": "phonology",
        "age_band": "child",
        "activity_type": "sound_isolation",
        "instruction": "Listen to the sounds and blend them together.",
        "prompt": "Which word is made of the sounds: /c/ /a/ /t/?",
        "options": ["cat", "cot", "cut", "bat"],
        "correct_answer": "cat",
        "hint": "Put the three individual sounds together in order.",
        "difficulty": 1,
    },
    {
        "skill_code": "dys_phonics",
        "track": "dyslexia_track",
        "domain": "phonics",
        "age_band": "child",
        "activity_type": "phonics_mapping",
        "instruction": "Which letters make the 'sh' sound in the word 'ship'?",
        "prompt": "Select the consonant digraph that spells the /sh/ sound.",
        "options": ["sh", "ch", "th", "ph"],
        "correct_answer": "sh",
        "hint": "It begins words like shop, ship, and shell.",
        "difficulty": 1,
    },
    {
        "skill_code": "dys_decoding",
        "track": "dyslexia_track",
        "domain": "decoding",
        "age_band": "child",
        "activity_type": "decoding",
        "instruction": "Read and select the word that rhymes with 'light'.",
        "prompt": "Which word shares the same -ight spelling pattern and sound?",
        "options": ["bright", "late", "boat", "loot"],
        "correct_answer": "bright",
        "hint": "The -ight makes a long /i/ vowel sound.",
        "difficulty": 1,
    },
    # Teen / Adult Dyslexia activities
    {
        "skill_code": "dys_decoding",
        "track": "dyslexia_track",
        "domain": "decoding",
        "age_band": "teen",
        "activity_type": "decoding",
        "instruction": "Break the multisyllabic word into its correct syllable chunks.",
        "prompt": "How is the word 'unforgettable' divided into syllables?",
        "options": [
            "un - for - get - ta - ble",
            "unf - orge - ttab - le",
            "u - nfor - gett - able",
            "unfo - rget - table",
        ],
        "correct_answer": "un - for - get - ta - ble",
        "hint": "Identify the prefix 'un-' and suffix '-able'.",
        "difficulty": 2,
    },
    {
        "skill_code": "dys_fluency",
        "track": "dyslexia_track",
        "domain": "fluency",
        "age_band": "all",
        "activity_type": "decoding",
        "instruction": "Select the word that correctly fits the sentence flow and spelling.",
        "prompt": "The astronaut prepared for the long space voyage with great ____.",
        "options": ["diligence", "deligence", "dillegence", "dilligence"],
        "correct_answer": "diligence",
        "hint": "It has two 'i's and one 'l'.",
        "difficulty": 2,
    },
    {
        "skill_code": "dys_reading_comprehension",
        "track": "dyslexia_track",
        "domain": "comprehension",
        "age_band": "all",
        "activity_type": "reading_comprehension",
        "instruction": "Read the paragraph and answer the question.",
        "prompt": "Lighthouses historically used Fresnel lenses, which concentrate light into a parallel beam visible for miles across foggy waters, guiding ships safely toward harbor.",
        "options": [
            "They concentrate light into a powerful parallel beam",
            "They absorb light to keep ships hidden",
            "They emit acoustic radio signals only",
            "They generate electricity from ocean waves",
        ],
        "correct_answer": "They concentrate light into a powerful parallel beam",
        "hint": "Look back at the first phrase describing the lens action.",
        "difficulty": 2,
    },
]


def seed_skills_and_activities(db: Session) -> None:
    """Populates initial skills and baseline activities idempotently."""
    skill_map = {}
    for s_data in SKILLS_SEED_DATA:
        existing = db.query(Skill).filter(Skill.code == s_data["code"]).first()
        if not existing:
            skill = Skill(
                code=s_data["code"],
                name=s_data["name"],
                description=s_data["description"],
                track=s_data["track"],
                domain=s_data["domain"],
                age_band_applicability=s_data["age_band_applicability"],
                priority=s_data["priority"],
                active=True,
            )
            db.add(skill)
            db.flush()
            skill_map[s_data["code"]] = skill.id
        else:
            skill_map[s_data["code"]] = existing.id

    for a_data in ACTIVITIES_SEED_DATA:
        skill_id = skill_map.get(a_data["skill_code"])
        if not skill_id:
            continue
        existing_act = (
            db.query(BaselineActivity)
            .filter(
                BaselineActivity.prompt == a_data["prompt"],
                BaselineActivity.skill_id == skill_id,
            )
            .first()
        )
        if not existing_act:
            activity = BaselineActivity(
                skill_id=skill_id,
                track=a_data["track"],
                domain=a_data["domain"],
                age_band=a_data["age_band"],
                activity_type=a_data["activity_type"],
                instruction=a_data["instruction"],
                prompt=a_data["prompt"],
                options_json=json.dumps(a_data["options"]),
                correct_answer=a_data["correct_answer"],
                hint=a_data.get("hint"),
                difficulty=a_data["difficulty"],
                active=True,
            )
            db.add(activity)

    db.commit()

    # Seed Phase 5 Practice Lessons and Exercises
    from app.core.learning_seeds import seed_learning_lessons_and_exercises
    seed_learning_lessons_and_exercises(db)

    # Seed Phase 10 Non-Punitive Milestone Achievements
    seed_achievements(db)


def seed_achievements(db: Session) -> None:
    from app.models.achievement import AchievementDefinition

    achievements_data = [
        {
            "code": "first_lesson",
            "title": "First Practice Step",
            "description": "Completed your first practice lesson.",
            "category": "learning",
            "icon_name": "school",
            "threshold": 1,
            "badge_tier": "bronze",
        },
        {
            "code": "five_lessons",
            "title": "Practice Momentum",
            "description": "Completed 5 learning lessons.",
            "category": "learning",
            "icon_name": "military_tech",
            "threshold": 5,
            "badge_tier": "silver",
        },
        {
            "code": "ten_lessons",
            "title": "Ten Lesson Journey",
            "description": "Completed 10 learning lessons.",
            "category": "learning",
            "icon_name": "workspace_premium",
            "threshold": 10,
            "badge_tier": "gold",
        },
        {
            "code": "twenty_five_lessons",
            "title": "Mastery Pathfinder",
            "description": "Completed 25 learning lessons across your curriculum.",
            "category": "learning",
            "icon_name": "stars",
            "threshold": 25,
            "badge_tier": "gold",
        },
        {
            "code": "three_skills_practiced",
            "title": "Skill Explorer",
            "description": "Practiced activities across 3 distinct skill areas.",
            "category": "skills",
            "icon_name": "explore",
            "threshold": 3,
            "badge_tier": "bronze",
        },
        {
            "code": "first_goal_completed",
            "title": "Goal Setter",
            "description": "Set and completed your first learning goal.",
            "category": "goals",
            "icon_name": "flag",
            "threshold": 1,
            "badge_tier": "silver",
        },
        {
            "code": "three_goals_completed",
            "title": "Goal Champion",
            "description": "Successfully completed 3 learning goals.",
            "category": "goals",
            "icon_name": "emoji_events",
            "threshold": 3,
            "badge_tier": "gold",
        },
        {
            "code": "consistent_practice_3d",
            "title": "Consistent Effort",
            "description": "Engaged in learning practice on 3 distinct days this week.",
            "category": "practice",
            "icon_name": "today",
            "threshold": 3,
            "badge_tier": "silver",
        },
    ]

    for ach in achievements_data:
        existing = db.query(AchievementDefinition).filter(AchievementDefinition.code == ach["code"]).first()
        if not existing:
            new_ach = AchievementDefinition(
                code=ach["code"],
                title=ach["title"],
                description=ach["description"],
                category=ach["category"],
                icon_name=ach["icon_name"],
                threshold=ach["threshold"],
                badge_tier=ach["badge_tier"],
            )
            db.add(new_ach)

    db.commit()
