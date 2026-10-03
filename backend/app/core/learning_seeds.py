import json
from typing import Dict, Any, List
from sqlalchemy.orm import Session

from app.models.skill import Skill
from app.models.learning import Lesson, Exercise


LESSONS_SEED_DATA = [
    # --- DLD TRACK LESSONS ---
    {
        "id": "lesson-dld-001",
        "skill_code": "dld_vocabulary",
        "title": "Everyday Action Words",
        "description": "Learn and practice vivid action verbs with meaningful context and visual associations.",
        "track": "dld_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 1,
        "estimated_effort_minutes": 5,
        "exercises": [
            {
                "exercise_type": "multiple_choice",
                "instruction": "Read the question and select the best meaning.",
                "prompt": "What does the action word 'explore' mean?",
                "content": {
                    "options": [
                        "To look around and discover new things",
                        "To sleep quietly in bed",
                        "To hide away in a dark room",
                        "To eat a quick afternoon snack",
                    ]
                },
                "correct_answer": "To look around and discover new things",
                "explanation": "'Explore' means traveling around a place to learn about it.",
                "hints": ["Think about explorers traveling to new lands or parks."],
                "difficulty": 1,
                "sequence_order": 1,
            },
            {
                "exercise_type": "sentence_completion",
                "instruction": "Pick the word that completes the sentence smoothly.",
                "prompt": "The curious squirrel decided to ____ up the oak tree.",
                "content": {
                    "options": ["climb", "sleep", "melt", "spill"]
                },
                "correct_answer": "climb",
                "explanation": "Squirrels use their sharp claws to climb tree trunks.",
                "hints": ["Which action makes sense for moving up a tall tree?"],
                "difficulty": 1,
                "sequence_order": 2,
            },
            {
                "exercise_type": "matching",
                "instruction": "Match each action word with what it means.",
                "prompt": "Connect each action word to its definition.",
                "content": {
                    "pairs": [
                        {"key": "soar", "value": "to fly high in the air"},
                        {"key": "sprint", "value": "to run very fast"},
                        {"key": "whisper", "value": "to speak very softly"},
                    ]
                },
                "correct_answer": {
                    "soar": "to fly high in the air",
                    "sprint": "to run very fast",
                    "whisper": "to speak very softly",
                },
                "explanation": "Matching action words to their actions builds deeper word comprehension.",
                "hints": ["Eagles soar, runners sprint, and secrets are whispered."],
                "difficulty": 1,
                "sequence_order": 3,
            },
        ],
    },
    {
        "id": "lesson-dld-002",
        "skill_code": "dld_grammar",
        "title": "Past Tense and Action Stories",
        "description": "Practice verb endings that tell us when an action happened in the past.",
        "track": "dld_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 2,
        "estimated_effort_minutes": 5,
        "exercises": [
            {
                "exercise_type": "multiple_choice",
                "instruction": "Choose the sentence that describes something already finished in the past.",
                "prompt": "Which sentence tells us what happened yesterday?",
                "content": {
                    "options": [
                        "Yesterday, Maya walked to school with her brother.",
                        "Maya is walking right now to school.",
                        "Tomorrow, Maya will walk to school.",
                        "Maya walk to school every morning.",
                    ]
                },
                "correct_answer": "Yesterday, Maya walked to school with her brother.",
                "explanation": "The '-ed' ending in 'walked' signals that the action happened in the past.",
                "hints": ["Look for the '-ed' ending and the time word 'yesterday'."],
                "difficulty": 1,
                "sequence_order": 1,
            },
            {
                "exercise_type": "sentence_completion",
                "instruction": "Select the correct past tense verb.",
                "prompt": "Last night, Chef Marco ____ a warm pot of vegetable soup.",
                "content": {
                    "options": ["cooked", "cooks", "cooking", "will cook"]
                },
                "correct_answer": "cooked",
                "explanation": "'Cooked' is the regular past tense form of 'cook'.",
                "hints": ["Since this happened last night, pick the past tense verb."],
                "difficulty": 1,
                "sequence_order": 2,
            },
            {
                "exercise_type": "multiple_choice",
                "instruction": "Select the sentence with correct verb agreement.",
                "prompt": "Choose the sentence where the subject and verb match.",
                "content": {
                    "options": [
                        "The two puppies were playing in the grass.",
                        "The two puppies was playing in the grass.",
                        "The two puppies is playing in the grass.",
                        "The two puppies being playing in the grass.",
                    ]
                },
                "correct_answer": "The two puppies were playing in the grass.",
                "explanation": "When there are two or more subjects (puppies), we use 'were' in the past tense.",
                "hints": ["'Two puppies' is plural, so we use 'were' instead of 'was'."],
                "difficulty": 1,
                "sequence_order": 3,
            },
        ],
    },
    {
        "id": "lesson-dld-003",
        "skill_code": "dld_sentence_formation",
        "title": "Building Connected Sentences",
        "description": "Construct clear, expressive sentences with subjects, verbs, and connecting words.",
        "track": "dld_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 3,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "word_order",
                "instruction": "Arrange the words into a complete, meaningful sentence.",
                "prompt": "Build a sentence about playing outside.",
                "content": {
                    "tokens": ["The", "children", "built", "a", "tall", "sandcastle."]
                },
                "correct_answer": ["The", "children", "built", "a", "tall", "sandcastle."],
                "explanation": "Sentences start with a capital letter subject ('The children') and verb ('built').",
                "hints": ["Start with 'The children' who are doing the action."],
                "difficulty": 1,
                "sequence_order": 1,
            },
            {
                "exercise_type": "word_order",
                "instruction": "Put these words in order to explain why something happened.",
                "prompt": "Assemble the cause-and-effect sentence.",
                "content": {
                    "tokens": ["We", "wore", "warm", "boots", "because", "it", "snowed."]
                },
                "correct_answer": ["We", "wore", "warm", "boots", "because", "it", "snowed."],
                "explanation": "'Because' joins what we did with the reason why.",
                "hints": ["Start with 'We wore warm boots'."],
                "difficulty": 1,
                "sequence_order": 2,
            },
            {
                "exercise_type": "sentence_completion",
                "instruction": "Choose the best connector word.",
                "prompt": "Elena grabbed her raincoat ____ the dark clouds looked heavy.",
                "content": {
                    "options": ["because", "or", "but", "although"]
                },
                "correct_answer": "because",
                "explanation": "'Because' introduces the cause of her grabbing the raincoat.",
                "hints": ["Which word explains the reason?"],
                "difficulty": 1,
                "sequence_order": 3,
            },
        ],
    },
    {
        "id": "lesson-dld-004",
        "skill_code": "dld_narrative_storytelling",
        "title": "Story Steps & Sequence",
        "description": "Identify story grammar: setting, initiating problem, action, and resolution.",
        "track": "dld_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 4,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "narrative_sequencing",
                "instruction": "Arrange the story steps in the order they happened.",
                "prompt": "Order the story events from start to finish.",
                "content": {
                    "events": [
                        {"id": "step_1", "text": "First, Sam found a tiny lost kitten shivering by the porch."},
                        {"id": "step_2", "text": "Next, he brought warm milk and made a soft cardboard bed."},
                        {"id": "step_3", "text": "Finally, the kitten purred happily and fell asleep safely."},
                    ]
                },
                "correct_answer": ["step_1", "step_2", "step_3"],
                "explanation": "Stories follow a timeline: problem happens first, helpful action next, resolution last.",
                "hints": ["Look for sequence clue words: First, Next, Finally."],
                "difficulty": 1,
                "sequence_order": 1,
            },
            {
                "exercise_type": "multiple_choice",
                "instruction": "Identify the story's initiating problem.",
                "prompt": "What was the main problem that started Sam's story?",
                "content": {
                    "options": [
                        "A lost kitten needed warmth and shelter",
                        "Sam lost his homework",
                        "The cardboard box was too small",
                        "The kitten ran up an oak tree",
                    ]
                },
                "correct_answer": "A lost kitten needed warmth and shelter",
                "explanation": "The story began because the kitten was lost and cold outside.",
                "hints": ["What made Sam act in the first step?"],
                "difficulty": 1,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-005",
        "skill_code": "dld_vocabulary",
        "title": "Academic Vocabulary in Context",
        "description": "Master high-utility academic vocabulary used in secondary coursework and communication.",
        "track": "dld_track",
        "age_band": "teen",
        "difficulty": 2,
        "sequence_order": 5,
        "estimated_effort_minutes": 7,
        "exercises": [
            {
                "exercise_type": "multiple_choice",
                "instruction": "Determine the precise meaning of the target academic word.",
                "prompt": "The lead researcher needed to 'corroborate' the lab findings with field observations.",
                "content": {
                    "options": [
                        "To confirm or support with evidence",
                        "To dismiss as irrelevant",
                        "To publicly contradict",
                        "To simplify for beginners",
                    ]
                },
                "correct_answer": "To confirm or support with evidence",
                "explanation": "'Corroborate' means providing corroborating evidence or confirmation.",
                "hints": ["Think of confirming hypothesis data with real-world observations."],
                "difficulty": 2,
                "sequence_order": 1,
            },
            {
                "exercise_type": "sentence_completion",
                "instruction": "Select the appropriate academic term.",
                "prompt": "The student presented a well-supported ____ to explain the shift in climate patterns.",
                "content": {
                    "options": ["hypothesis", "rumor", "obstacle", "distraction"]
                },
                "correct_answer": "hypothesis",
                "explanation": "In scientific inquiry, a 'hypothesis' is a testable proposition or explanation.",
                "hints": ["Which word represents an educated scientific explanation?"],
                "difficulty": 2,
                "sequence_order": 2,
            },
            {
                "exercise_type": "word_order",
                "instruction": "Arrange the tokens into an academic sentence structure.",
                "prompt": "Formulate a formal statement about evidence.",
                "content": {
                    "tokens": ["The", "scientists", "gathered", "empirical", "data", "to", "support", "their", "findings."]
                },
                "correct_answer": ["The", "scientists", "gathered", "empirical", "data", "to", "support", "their", "findings."],
                "explanation": "Clear academic sentences place the active agent first followed by the methodology.",
                "hints": ["Start with 'The scientists gathered empirical data'."],
                "difficulty": 2,
                "sequence_order": 3,
            },
        ],
    },
    {
        "id": "lesson-dld-006",
        "skill_code": "dld_listening_comprehension",
        "title": "Following Two-Step Directions",
        "description": "Practice listening to oral instructions, identifying order words, and recalling key steps.",
        "track": "dld_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 6,
        "estimated_effort_minutes": 5,
        "exercises": [
            {
                "exercise_type": "listening_comprehension",
                "instruction": "Listen to the instruction and select the first step.",
                "prompt": "Listen carefully to the teacher's direction.",
                "content": {
                    "transcript": "Before you open your lunchbox, wash your hands with soap and water.",
                    "question": "What should you do first?",
                    "options": [
                        "Wash hands with soap and water",
                        "Open your lunchbox",
                        "Eat an apple",
                        "Pack your backpack",
                    ],
                },
                "correct_answer": "Wash hands with soap and water",
                "explanation": "The word 'Before' tells us that washing hands must happen before opening the lunchbox.",
                "hints": ["Listen for the word 'Before' at the start of the sentence."],
                "difficulty": 1,
                "sequence_order": 1,
            },
            {
                "exercise_type": "listening_comprehension",
                "instruction": "Listen and identify where the object belongs.",
                "prompt": "Listen to the classroom cleanup instructions.",
                "content": {
                    "transcript": "Put the red folder inside your desk, then bring your drawing book to the front table.",
                    "question": "Where does the red folder belong?",
                    "options": [
                        "Inside your desk",
                        "On the front table",
                        "In your locker",
                        "Under the chair",
                    ],
                },
                "correct_answer": "Inside your desk",
                "explanation": "The instruction states clearly: 'Put the red folder inside your desk'.",
                "hints": ["Focus on the first part of the direction about the red folder."],
                "difficulty": 1,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-007",
        "skill_code": "dld_vocabulary",
        "title": "Everyday Word Categories",
        "description": "Strengthen semantic categorization and word relationships.",
        "track": "dld_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 7,
        "estimated_effort_minutes": 5,
        "exercises": [
            {
                "exercise_type": "multiple_choice",
                "instruction": "Identify which word belongs in the category.",
                "prompt": "Which animal belongs in the category: 'Animals that swim'?",
                "content": {
                    "options": ["Dolphin", "Cheetah", "Eagle", "Giraffe"],
                },
                "correct_answer": "Dolphin",
                "explanation": "Dolphins live and swim in ocean waters.",
                "hints": ["Which of these animals lives in the ocean?"],
                "difficulty": 1,
                "sequence_order": 1,
            },
            {
                "exercise_type": "matching",
                "instruction": "Connect each item to its category.",
                "prompt": "Match each word to what kind of thing it is.",
                "content": {
                    "pairs": [
                        {"key": "Apple", "value": "Fruit"},
                        {"key": "Sedan", "value": "Vehicle"},
                        {"key": "Jacket", "value": "Clothing"},
                    ]
                },
                "correct_answer": {
                    "Apple": "Fruit",
                    "Sedan": "Vehicle",
                    "Jacket": "Clothing",
                },
                "explanation": "Categorizing items builds organized semantic memory pathways.",
                "hints": ["Think about what you wear, what you eat, and what travels on roads."],
                "difficulty": 1,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-008",
        "skill_code": "dld_grammar",
        "title": "Conjunctions and Complex Clauses",
        "description": "Combine independent and subordinate clauses to communicate nuanced relationships.",
        "track": "dld_track",
        "age_band": "teen",
        "difficulty": 2,
        "sequence_order": 8,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "sentence_completion",
                "instruction": "Select the conjunction that expresses contrast.",
                "prompt": "The team continued their biology lab experiment ____ the electricity in the school building flickered.",
                "content": {
                    "options": ["although", "because", "so", "unless"],
                },
                "correct_answer": "although",
                "explanation": "'Although' introduces a concessive clause contrasting the power flicker with continuing work.",
                "hints": ["Which word shows that the experiment continued despite the interruption?"],
                "difficulty": 2,
                "sequence_order": 1,
            },
            {
                "exercise_type": "multiple_choice",
                "instruction": "Select the grammatically accurate complex sentence.",
                "prompt": "Which sentence correctly connects two related ideas?",
                "content": {
                    "options": [
                        "Because heavy rain flooded the access road, the soccer match was postponed until Saturday.",
                        "Rain flooded the road so then the match postponed Saturday.",
                        "Flooded access road match postponed because raining.",
                        "The soccer match postponed because heavy rain flooded.",
                    ],
                },
                "correct_answer": "Because heavy rain flooded the access road, the soccer match was postponed until Saturday.",
                "explanation": "Starting with a dependent clause followed by a comma creates a well-formed complex sentence.",
                "hints": ["Look for complete subjects, active/passive verbs, and clear clause transitions."],
                "difficulty": 2,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-009",
        "skill_code": "dld_sentence_formation",
        "title": "Sentence Combining & Expansion",
        "description": "Practice expanding simple statements into cohesive, descriptive sentences.",
        "track": "dld_track",
        "age_band": "teen",
        "difficulty": 2,
        "sequence_order": 9,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "word_order",
                "instruction": "Arrange the tokens into a complete compound sentence.",
                "prompt": "Construct a sentence describing field research.",
                "content": {
                    "tokens": ["While", "conducting", "field", "research,", "the", "students", "discovered", "a", "rare", "wildflower."]
                },
                "correct_answer": ["While", "conducting", "field", "research,", "the", "students", "discovered", "a", "rare", "wildflower."],
                "explanation": "Adverbial clauses beginning with 'While' set the temporal context for the main action.",
                "hints": ["Start with 'While conducting field research,'."],
                "difficulty": 2,
                "sequence_order": 1,
            },
            {
                "exercise_type": "sentence_completion",
                "instruction": "Choose the most precise transition phrase.",
                "prompt": "The student historian cross-referenced several manuscripts, ____ confirming the authentic date of the charter.",
                "content": {
                    "options": ["thereby", "whereas", "however", "instead"],
                },
                "correct_answer": "thereby",
                "explanation": "'Thereby' indicates that the action led directly to the result.",
                "hints": ["Which word means 'as a result of that'?"],
                "difficulty": 2,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-010",
        "skill_code": "dld_listening_comprehension",
        "title": "Classroom Instructions & Central Ideas",
        "description": "Extract critical details, deadlines, and requirements from academic spoken discourse.",
        "track": "dld_track",
        "age_band": "teen",
        "difficulty": 2,
        "sequence_order": 10,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "listening_comprehension",
                "instruction": "Listen and identify student responsibilities.",
                "prompt": "Listen to the chemistry teacher's laboratory announcement.",
                "content": {
                    "transcript": "For tomorrow's chemistry lab, you must review chapter 4, print the safety protocol sheet, and wear closed-toe shoes. Safety goggles will be provided at your lab bench.",
                    "question": "Which item do students need to bring themselves?",
                    "options": [
                        "The printed safety protocol sheet",
                        "Safety goggles",
                        "A microscope",
                        "Chemical test tubes",
                    ],
                },
                "correct_answer": "The printed safety protocol sheet",
                "explanation": "Safety goggles are provided at the bench, while students must print the protocol sheet themselves.",
                "hints": ["Listen for what is provided versus what students must bring."],
                "difficulty": 2,
                "sequence_order": 1,
            },
            {
                "exercise_type": "listening_comprehension",
                "instruction": "Listen for deadline distinctions.",
                "prompt": "Listen to the high school library announcement.",
                "content": {
                    "transcript": "The deadline for regular book loans has been extended to Friday afternoon; however, reserved reference textbooks must still be returned by 5 PM today.",
                    "question": "When must reserved reference textbooks be returned?",
                    "options": [
                        "Today by 5 PM",
                        "Friday afternoon",
                        "Next Monday morning",
                        "Any time during finals week",
                    ],
                },
                "correct_answer": "Today by 5 PM",
                "explanation": "The word 'however' introduces the specific rule for reserved reference textbooks: today by 5 PM.",
                "hints": ["Pay attention to the contrast word 'however'."],
                "difficulty": 2,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-011",
        "skill_code": "dld_narrative_storytelling",
        "title": "Cause, Effect, and Logical Explanations",
        "description": "Structure technical and narrative explanations following a logical event timeline.",
        "track": "dld_track",
        "age_band": "teen",
        "difficulty": 2,
        "sequence_order": 11,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "narrative_sequencing",
                "instruction": "Place the problem-solving stages in logical chronological order.",
                "prompt": "Order the sequence of the robotics team's troubleshooting process.",
                "content": {
                    "events": [
                        {"id": "ev_1", "text": "First, the robotics drive motor overheated during the morning test run."},
                        {"id": "ev_2", "text": "Next, the programming team reduced the duty cycle and installed dual cooling fans."},
                        {"id": "ev_3", "text": "Finally, the robot completed all speed trials smoothly during the regional contest."},
                    ]
                },
                "correct_answer": ["ev_1", "ev_2", "ev_3"],
                "explanation": "Logical explanations sequence the initiating problem first, diagnostic intervention second, and validated outcome last.",
                "hints": ["Look for the problem, the response, and the final outcome."],
                "difficulty": 2,
                "sequence_order": 1,
            },
            {
                "exercise_type": "multiple_choice",
                "instruction": "Identify the cause of the motor overheating.",
                "prompt": "What primary factor necessitated the robotics team's intervention?",
                "content": {
                    "options": [
                        "The motor overheated during the test run",
                        "The robot ran out of battery power",
                        "The contest was canceled due to weather",
                        "The programming software crashed unexpectedly",
                    ],
                },
                "correct_answer": "The motor overheated during the test run",
                "explanation": "The overheating event was the causal catalyst for adjusting the duty cycle.",
                "hints": ["What challenge was described at the very beginning?"],
                "difficulty": 2,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-012",
        "skill_code": "dld_pragmatics",
        "title": "Conversational Context & Clarification",
        "description": "Practice pragmatic communication strategies, conversational repairs, and collaborative engagement.",
        "track": "dld_track",
        "age_band": "teen",
        "difficulty": 2,
        "sequence_order": 12,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "social_communication",
                "instruction": "Select the most effective collaborative response.",
                "prompt": "During a group project meeting, someone speaks quickly and assigns a deadline you did not fully catch.",
                "content": {
                    "scenario": "You are collaborating with three peers on a social studies project. One teammate quickly mentions due dates while flipping through slides.",
                    "question": "Which response politely asks for clarification without disrupting the meeting?",
                    "options": [
                        "Could you please repeat the date for that deliverable? I want to make sure I noted it correctly.",
                        "You talked way too fast, so I have no idea what you said.",
                        "Never mind, I guess I'll figure it out later on my own.",
                        "That schedule makes no sense at all.",
                    ],
                },
                "correct_answer": "Could you please repeat the date for that deliverable? I want to make sure I noted it correctly.",
                "explanation": "Taking collaborative ownership ('I want to make sure I noted it correctly') maintains a supportive group tone while obtaining the needed detail.",
                "hints": ["Which option asks for repetition politely while framing it as diligence?"],
                "difficulty": 2,
                "sequence_order": 1,
            },
            {
                "exercise_type": "social_communication",
                "instruction": "Identify supportive communicative engagement.",
                "prompt": "A classmate appears visibly anxious about their presentation notes right before class starts.",
                "content": {
                    "scenario": "Your classmate is pacing near the podium, rearranging cue cards with trembling hands.",
                    "question": "Which response offers supportive peer communication?",
                    "options": [
                        "Would you like to run through your main talking points with me once before we begin?",
                        "You look like you are going to forget everything.",
                        "Public speaking is super easy, just relax.",
                        "I am glad it is your turn to speak today and not mine.",
                    ],
                },
                "correct_answer": "Would you like to run through your main talking points with me once before we begin?",
                "explanation": "Offering a concrete, non-judgmental support action helps alleviate communicative stress.",
                "hints": ["Which response offers practical help rather than dismissal or criticism?"],
                "difficulty": 2,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-013",
        "skill_code": "dld_vocabulary",
        "title": "Professional & Workplace Vocabulary",
        "description": "Master high-utility functional and professional terminology used in workplace collaboration.",
        "track": "dld_track",
        "age_band": "adult",
        "difficulty": 3,
        "sequence_order": 13,
        "estimated_effort_minutes": 7,
        "exercises": [
            {
                "exercise_type": "multiple_choice",
                "instruction": "Define the target workplace term in professional context.",
                "prompt": "In organizational planning, what does it mean to 'allocate' department resources?",
                "content": {
                    "options": [
                        "To distribute or designate funds and personnel to specific initiatives",
                        "To permanently terminate future project funding",
                        "To borrow equipment from external competitors",
                        "To refund uncollected payments back to clients",
                    ],
                },
                "correct_answer": "To distribute or designate funds and personnel to specific initiatives",
                "explanation": "'Allocate' means setting apart or designating portions of resources for specific objectives.",
                "hints": ["Think of assigning portions of a budget to planned projects."],
                "difficulty": 3,
                "sequence_order": 1,
            },
            {
                "exercise_type": "sentence_completion",
                "instruction": "Select the appropriate workplace verb.",
                "prompt": "To mitigate future cross-department communication bottlenecks, management resolved to ____ weekly synchronization briefings.",
                "content": {
                    "options": ["institute", "abolish", "prohibit", "disregard"],
                },
                "correct_answer": "institute",
                "explanation": "'Institute' means introducing, initiating, or establishing a new organizational practice.",
                "hints": ["Which word means to introduce or put a beneficial process in place?"],
                "difficulty": 3,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-014",
        "skill_code": "dld_grammar",
        "title": "Clear Communication & Formal Registers",
        "description": "Practice writing and identifying professional registers suitable for workplace correspondence.",
        "track": "dld_track",
        "age_band": "adult",
        "difficulty": 3,
        "sequence_order": 14,
        "estimated_effort_minutes": 7,
        "exercises": [
            {
                "exercise_type": "multiple_choice",
                "instruction": "Identify the communication phrased in an appropriate professional register.",
                "prompt": "Which email opening demonstrates a professional, courteous business register?",
                "content": {
                    "options": [
                        "Thank you for contacting our team; I have reviewed your inquiry and attached the requested quarterly summary.",
                        "Hey, check out this attachment I sent over.",
                        "Summary attached, let me know if it works or whatever.",
                        "Got your email, here is the stuff you asked for.",
                    ],
                },
                "correct_answer": "Thank you for contacting our team; I have reviewed your inquiry and attached the requested quarterly summary.",
                "explanation": "Clear syntax, polite acknowledgments, and descriptive labeling characterize professional business registers.",
                "hints": ["Look for polite acknowledgment and clear specification of what is provided."],
                "difficulty": 3,
                "sequence_order": 1,
            },
            {
                "exercise_type": "sentence_completion",
                "instruction": "Select the correct conditional verb phrase.",
                "prompt": "Had the engineering department received the updated architectural specifications earlier, the project milestone ____ on schedule.",
                "content": {
                    "options": ["would have remained", "will remain", "is remaining", "remains"],
                },
                "correct_answer": "would have remained",
                "explanation": "Inverted third-conditional clauses ('Had the department received...') require 'would have + past participle' in the result clause.",
                "hints": ["Look for the past unreal conditional structure matching 'Had received...'."],
                "difficulty": 3,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-015",
        "skill_code": "dld_sentence_formation",
        "title": "Concise Professional Sentences",
        "description": "Formulate clear, concise statements without unnecessary ambiguity or run-on phrasing.",
        "track": "dld_track",
        "age_band": "adult",
        "difficulty": 3,
        "sequence_order": 15,
        "estimated_effort_minutes": 7,
        "exercises": [
            {
                "exercise_type": "word_order",
                "instruction": "Arrange the tokens into a coherent executive statement.",
                "prompt": "Build an informative sentence regarding operational improvements.",
                "content": {
                    "tokens": ["The", "operations", "team", "streamlined", "the", "workflow", "to", "reduce", "customer", "wait", "times."]
                },
                "correct_answer": ["The", "operations", "team", "streamlined", "the", "workflow", "to", "reduce", "customer", "wait", "times."],
                "explanation": "Leading with the active organizational subject and action verb creates concise business writing.",
                "hints": ["Start with 'The operations team streamlined the workflow...'."],
                "difficulty": 3,
                "sequence_order": 1,
            },
            {
                "exercise_type": "sentence_completion",
                "instruction": "Choose the formal prepositional connector.",
                "prompt": "The oversight board thoroughly reviewed the safety audit ____ recommending formal accreditation.",
                "content": {
                    "options": ["prior to", "contrary to", "regardless of", "in spite of"],
                },
                "correct_answer": "prior to",
                "explanation": "'Prior to' appropriately establishes temporal precedence in formal business reports.",
                "hints": ["Which phrase means 'before'?"],
                "difficulty": 3,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-016",
        "skill_code": "dld_listening_comprehension",
        "title": "Functional Listening: Workplace & Appointments",
        "description": "Listen to everyday spoken information, scheduling details, and multi-part operational instructions.",
        "track": "dld_track",
        "age_band": "adult",
        "difficulty": 3,
        "sequence_order": 16,
        "estimated_effort_minutes": 7,
        "exercises": [
            {
                "exercise_type": "listening_comprehension",
                "instruction": "Listen to the operational announcement and identify the deadline action.",
                "prompt": "Listen to the workplace facility coordinator's announcement.",
                "content": {
                    "transcript": "The quarterly review meeting has been relocated from Room 302 to the main conference hall on the 4th floor. Please ensure your department slide deck is uploaded to the shared repository at least one hour prior to our 2 PM start time.",
                    "question": "What primary action must department heads complete before the meeting?",
                    "options": [
                        "Upload the department slide deck to the shared repository by 1 PM",
                        "Print thirty physical handouts for attendees",
                        "Report to Room 302 at 2 PM",
                        "Call the facility coordinator for parking validation",
                    ],
                },
                "correct_answer": "Upload the department slide deck to the shared repository by 1 PM",
                "explanation": "'One hour prior to our 2 PM start time' means the upload must be completed by 1 PM.",
                "hints": ["Calculate the time 'one hour prior to 2 PM'."],
                "difficulty": 3,
                "sequence_order": 1,
            },
            {
                "exercise_type": "listening_comprehension",
                "instruction": "Listen and extract the arrival requirement.",
                "prompt": "Listen to the healthcare facility appointment confirmation.",
                "content": {
                    "transcript": "Your outpatient clinical appointment is confirmed for Thursday at 9:30 AM at the Northgate Medical Center. Please arrive 15 minutes early to finalize check-in, and bring your photo identification along with your current insurance card.",
                    "question": "What time should the patient plan to arrive at the facility?",
                    "options": [
                        "9:15 AM",
                        "9:30 AM",
                        "10:00 AM",
                        "9:45 AM",
                    ],
                },
                "correct_answer": "9:15 AM",
                "explanation": "Arriving 15 minutes before the 9:30 AM scheduled time means arriving at 9:15 AM.",
                "hints": ["Subtract 15 minutes from 9:30 AM."],
                "difficulty": 3,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-017",
        "skill_code": "dld_narrative_storytelling",
        "title": "Process Explanation & Incident Reporting",
        "description": "Structure professional incident descriptions and process explanations chronologically.",
        "track": "dld_track",
        "age_band": "adult",
        "difficulty": 3,
        "sequence_order": 17,
        "estimated_effort_minutes": 7,
        "exercises": [
            {
                "exercise_type": "narrative_sequencing",
                "instruction": "Sequence the steps of the workplace incident review process.",
                "prompt": "Arrange the investigation stages in proper chronological order.",
                "content": {
                    "events": [
                        {"id": "step_a", "text": "First, the warehouse supervisor logged an unexpected inventory variance during the morning count."},
                        {"id": "step_b", "text": "Next, the logistics team audited shipping manifests against physical shelf receipts."},
                        {"id": "step_c", "text": "Finally, the discrepancy was resolved and the updated reconciliation report was submitted to finance."},
                    ]
                },
                "correct_answer": ["step_a", "step_b", "step_c"],
                "explanation": "Professional reports document identification first, audit investigation second, and formal resolution last.",
                "hints": ["Look for the detection of the variance, the audit, and the final filing."],
                "difficulty": 3,
                "sequence_order": 1,
            },
            {
                "exercise_type": "multiple_choice",
                "instruction": "Identify best practices in objective incident reporting.",
                "prompt": "What information is essential to document first when preparing a factual workplace incident summary?",
                "content": {
                    "options": [
                        "The factual chronological sequence of events and verified actions taken",
                        "Personal unverified hunches about colleague motives",
                        "Speculative forecasts regarding next quarter's sales targets",
                        "Casual conversational opinions unrelated to the event",
                    ],
                },
                "correct_answer": "The factual chronological sequence of events and verified actions taken",
                "explanation": "Objective reporting relies on verified chronological facts and recorded actions taken.",
                "hints": ["Which option emphasizes facts, timestamps, and verifiable actions?"],
                "difficulty": 3,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dld-018",
        "skill_code": "dld_pragmatics",
        "title": "Workplace Collaboration & Tactful Clarifications",
        "description": "Navigate professional interpersonal communication, contradictory guidelines, and collaborative problem-solving.",
        "track": "dld_track",
        "age_band": "adult",
        "difficulty": 3,
        "sequence_order": 18,
        "estimated_effort_minutes": 7,
        "exercises": [
            {
                "exercise_type": "social_communication",
                "instruction": "Select the constructive collaborative response.",
                "prompt": "A colleague suggests a major project revision during a team sprint that could jeopardize the agreed deadline.",
                "content": {
                    "scenario": "During a project sync, a team member suggests redesigning the client portal interface, which would require an additional two weeks.",
                    "question": "Which response offers a constructive perspective while acknowledging project constraints?",
                    "options": [
                        "I appreciate the creative direction; let us evaluate the scope impact against our deliverable deadline and see if a phased rollout makes sense.",
                        "That idea will completely ruin our timeline and we cannot do it.",
                        "I refuse to discuss this proposal.",
                        "Whatever you think, but do not blame me when it fails.",
                    ],
                },
                "correct_answer": "I appreciate the creative direction; let us evaluate the scope impact against our deliverable deadline and see if a phased rollout makes sense.",
                "explanation": "Acknowledging the idea while proposing objective scope evaluation ('phased rollout') fosters collaborative professionalism.",
                "hints": ["Which option balances creative respect with practical timeline stewardship?"],
                "difficulty": 3,
                "sequence_order": 1,
            },
            {
                "exercise_type": "social_communication",
                "instruction": "Select the professional approach to resolving ambiguity.",
                "prompt": "You receive two conflicting directives from different project supervisors regarding task priority.",
                "content": {
                    "scenario": "Supervisor A emails asking for Report X by 2 PM, while Supervisor B messages asking you to prioritize Client Analysis Y by 2 PM.",
                    "question": "How should you seek clarification professionally?",
                    "options": [
                        "Thank you for the updates. Both tasks have a 2 PM target; could you both advise on the preferred priority order so I can align my time effectively?",
                        "You two gave me opposite orders, so you need to figure it out between yourselves.",
                        "I am simply going to ignore both requests until tomorrow.",
                        "I will pick the easier one and let you handle the angry client.",
                    ],
                },
                "correct_answer": "Thank you for the updates. Both tasks have a 2 PM target; could you both advise on the preferred priority order so I can align my time effectively?",
                "explanation": "Directly and respectfully surfacing competing deadlines allows leadership to coordinate priorities without assigning blame.",
                "hints": ["Which response politely highlights the competing deadlines and requests alignment?"],
                "difficulty": 3,
                "sequence_order": 2,
            },
        ],
    },

    # --- CONNECTED / MULTIMODAL LESSON ---
    {
        "id": "lesson-conn-001",
        "skill_code": "dld_vocabulary",
        "title": "Marine Ecosystems & Reading",
        "description": "Connect spoken language concepts with written comprehension in a shared ecological context.",
        "track": "both_track",
        "age_band": "all",
        "difficulty": 2,
        "sequence_order": 6,
        "estimated_effort_minutes": 8,
        "exercises": [
            {
                "exercise_type": "multiple_choice",
                "instruction": "Understand the central concept word.",
                "prompt": "What is an 'ecosystem' in nature?",
                "content": {
                    "options": [
                        "A community of living organisms interacting with their physical environment",
                        "A single species of deep-sea jellyfish",
                        "A man-made aquarium tank in a science museum",
                        "A sudden change in atmospheric pressure",
                    ]
                },
                "correct_answer": "A community of living organisms interacting with their physical environment",
                "explanation": "An ecosystem encompasses plants, animals, water, and soil functioning together.",
                "hints": ["Think about living organisms and their environment working as a team."],
                "difficulty": 2,
                "sequence_order": 1,
            },
            {
                "exercise_type": "reading_passage",
                "instruction": "Read the passage about coral reefs and answer the comprehension prompt.",
                "prompt": "Why are coral reefs often described as 'underwater rainforests'?",
                "content": {
                    "passage": "Coral reefs occupy less than one percent of the ocean floor, yet they provide vital shelter, breeding grounds, and nourishment for more than a quarter of all marine life. Because of this astonishing biological diversity and density, scientists frequently refer to coral reefs as underwater rainforests.",
                    "question": "What characteristic earns coral reefs the title of 'underwater rainforests'?",
                    "options": [
                        "Their immense biological diversity supporting a vast variety of species",
                        "They receive continuous heavy rainfall beneath the waves",
                        "They are made entirely of tropical timber and vines",
                        "They are located exclusively near freshwater rivers",
                    ]
                },
                "correct_answer": "Their immense biological diversity supporting a vast variety of species",
                "explanation": "The text explains they are called underwater rainforests because of their astonishing biological diversity.",
                "hints": ["Look for the phrase 'Because of this astonishing biological diversity...'"],
                "difficulty": 2,
                "sequence_order": 2,
            },
        ],
    },
    # --- DYSLEXIA / LITERACY TRACK LESSONS ---
    # Child Lessons (Ages 6-11)
    {
        "id": "lesson-dys-001",
        "skill_code": "dys_phonological_awareness",
        "title": "Rhyme & Syllable Discovery",
        "description": "Explore playful sound patterns, rhyming word endings, and syllable rhythms.",
        "track": "dyslexia_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 1,
        "estimated_effort_minutes": 5,
        "exercises": [
            {
                "exercise_type": "phonological_awareness",
                "instruction": "Listen to the word and choose the one that rhymes with it.",
                "prompt": "Which word rhymes with 'sun'?",
                "content": {
                    "options": ["run", "bat", "cup", "dog"]
                },
                "correct_answer": "run",
                "explanation": "'Sun' and 'run' end with the identical sound /un/.",
                "hints": ["Say the ending sound /un/ out loud."],
                "difficulty": 1,
                "sequence_order": 1,
            },
            {
                "exercise_type": "phonological_awareness",
                "instruction": "Clap or count the beats (syllables) in the word.",
                "prompt": "How many syllables are in the word 'but-ter-fly'?",
                "content": {
                    "options": ["1", "2", "3", "4"]
                },
                "correct_answer": "3",
                "explanation": "'But-ter-fly' has 3 distinct syllable beats.",
                "hints": ["Clap your hands as you say each chunk: but... ter... fly."],
                "difficulty": 1,
                "sequence_order": 2,
            },
            {
                "exercise_type": "phonological_awareness",
                "instruction": "Find the word with the same beginning sound.",
                "prompt": "Which word starts with the same sound as 'star' /st/?",
                "content": {
                    "options": ["stone", "moon", "cloud", "fish"]
                },
                "correct_answer": "stone",
                "explanation": "'Star' and 'stone' both begin with the /st/ sound blend.",
                "hints": ["Listen for the hiss and tap /st/ at the very start."],
                "difficulty": 1,
                "sequence_order": 3,
            },
        ],
    },
    {
        "id": "lesson-dys-002",
        "skill_code": "dys_phonics",
        "title": "Short Vowels & Consonant Blends",
        "description": "Learn clear sound-letter relationships for short vowels and friendly consonant blends.",
        "track": "dyslexia_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 2,
        "estimated_effort_minutes": 5,
        "exercises": [
            {
                "exercise_type": "phonics",
                "instruction": "Find the word with the short vowel /a/ sound like 'cat'.",
                "prompt": "Which word has the short /a/ vowel sound?",
                "content": {
                    "options": ["map", "cake", "boat", "car"]
                },
                "correct_answer": "map",
                "explanation": "'Map' has the classic short /a/ vowel sound, just like 'cat'.",
                "hints": ["Listen for the /a/ sound in apple and map."],
                "difficulty": 1,
                "sequence_order": 1,
            },
            {
                "exercise_type": "phonics",
                "instruction": "Identify the two letters that blend together at the start.",
                "prompt": "Which blend begins the word 'frog'?",
                "content": {
                    "options": ["fr", "tr", "gl", "pl"]
                },
                "correct_answer": "fr",
                "explanation": "The letters 'f' and 'r' blend together smoothly to make /fr/ in 'frog'.",
                "hints": ["Feel your teeth on your lower lip for /f/ then roll into /r/."],
                "difficulty": 1,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dys-003",
        "skill_code": "dys_decoding",
        "title": "Foundational Word Decoding",
        "description": "Practice blending individual letter sounds into full, readable words.",
        "track": "dyslexia_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 3,
        "estimated_effort_minutes": 5,
        "exercises": [
            {
                "exercise_type": "decoding",
                "instruction": "Slide the sounds together to read the word.",
                "prompt": "Which word is made from blending the sounds /s/ /i/ /t/?",
                "content": {
                    "options": ["sit", "sat", "set", "sun"]
                },
                "correct_answer": "sit",
                "explanation": "/s/ + /i/ + /t/ blends directly into 'sit'.",
                "hints": ["Listen carefully to the middle /i/ vowel sound."],
                "difficulty": 1,
                "sequence_order": 1,
            },
            {
                "exercise_type": "decoding",
                "instruction": "Recognize the word family pattern.",
                "prompt": "Which word belongs to the '-at' word family?",
                "content": {
                    "options": ["hat", "hot", "hit", "hut"]
                },
                "correct_answer": "hat",
                "explanation": "'Hat' ends with the '-at' phonogram pattern.",
                "hints": ["Look at the last two letters: -a-t."],
                "difficulty": 1,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dys-004",
        "skill_code": "dys_spelling",
        "title": "Building Simple Words",
        "description": "Construct words by placing sound and letter tiles in correct sequence.",
        "track": "dyslexia_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 4,
        "estimated_effort_minutes": 5,
        "exercises": [
            {
                "exercise_type": "word_building",
                "instruction": "Arrange the letter tiles to spell the word 'ship'.",
                "prompt": "Build the word: 'ship'",
                "content": {
                    "tiles": ["s", "h", "i", "p"],
                    "target_word": "ship"
                },
                "correct_answer": ["s", "h", "i", "p"],
                "explanation": "'Ship' starts with digraph 'sh', middle vowel 'i', and ends with 'p'.",
                "hints": ["Remember 'sh' makes the quiet sound at the front."],
                "difficulty": 1,
                "sequence_order": 1,
            },
            {
                "exercise_type": "spelling",
                "instruction": "Choose the missing vowel letter to complete the word.",
                "prompt": "Complete the word for a pet animal: c _ t",
                "content": {
                    "options": ["a", "e", "o", "u"]
                },
                "correct_answer": "a",
                "explanation": "'Cat' is spelled with letter 'a' in the middle.",
                "hints": ["Which vowel makes the short /a/ sound?"],
                "difficulty": 1,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dys-005",
        "skill_code": "dys_fluency",
        "title": "Paced Story Reading: The Forest Path",
        "description": "Read a cheerful connected passage with read-aloud support and comfortable line pacing.",
        "track": "dyslexia_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 5,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "reading_passage",
                "instruction": "Read the story or tap play to listen with line pacing.",
                "prompt": "Who walked down the forest path with Leo?",
                "content": {
                    "passage": "Leo and his friendly puppy Milo walked down the quiet forest path. The tall green pines rustled gently in the cool breeze. Suddenly, Milo stopped and wagged his tail. A bright blue butterfly fluttered over a patch of wild clover.",
                    "options": [
                        "His friendly puppy Milo",
                        "His brother Sam",
                        "A wild brown rabbit",
                        "His grandmother",
                    ]
                },
                "correct_answer": "His friendly puppy Milo",
                "explanation": "The story tells us that Leo walked with his friendly puppy Milo.",
                "hints": ["Check the very first sentence of the story."],
                "difficulty": 1,
                "sequence_order": 1,
            },
        ],
    },
    {
        "id": "lesson-dys-006",
        "skill_code": "dys_reading_comprehension",
        "title": "Story Clues & Comprehension",
        "description": "Find key details and understand what happened in the forest path story.",
        "track": "dyslexia_track",
        "age_band": "child",
        "difficulty": 1,
        "sequence_order": 6,
        "estimated_effort_minutes": 5,
        "exercises": [
            {
                "exercise_type": "reading_comprehension",
                "instruction": "Choose the best answer based on the story you read.",
                "prompt": "What caused Milo to stop and wag his tail?",
                "content": {
                    "passage": "Leo and his friendly puppy Milo walked down the quiet forest path. The tall green pines rustled gently in the cool breeze. Suddenly, Milo stopped and wagged his tail. A bright blue butterfly fluttered over a patch of wild clover.",
                    "options": [
                        "A bright blue butterfly fluttering nearby",
                        "A loud thunderstorm in the distance",
                        "A squirrel climbing an oak tree",
                        "A bell ringing for dinner",
                    ]
                },
                "correct_answer": "A bright blue butterfly fluttering nearby",
                "explanation": "Milo wagged his tail when he noticed the blue butterfly fluttering over clover.",
                "hints": ["Look at what appeared right after Milo wagged his tail."],
                "difficulty": 1,
                "sequence_order": 1,
            },
        ],
    },
    # Teen Lessons (Ages 12-17)
    {
        "id": "lesson-dys-007",
        "skill_code": "dys_decoding",
        "title": "Multisyllabic Word Attack",
        "description": "Break down long academic words into prefixes, roots, and suffixes.",
        "track": "dyslexia_track",
        "age_band": "teen",
        "difficulty": 2,
        "sequence_order": 7,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "decoding",
                "instruction": "Identify the natural syllable division of the word.",
                "prompt": "Which shows the correct syllable chunking for 'construction'?",
                "content": {
                    "options": [
                        "con-struc-tion",
                        "co-nst-ruct-ion",
                        "cons-tructi-on",
                        "con-st-ru-ction",
                    ]
                },
                "correct_answer": "con-struc-tion",
                "explanation": "'Construction' breaks naturally into prefix 'con-', root 'struc', and suffix '-tion'.",
                "hints": ["Look for the familiar prefix 'con-' and suffix '-tion'."],
                "difficulty": 2,
                "sequence_order": 1,
            },
            {
                "exercise_type": "decoding",
                "instruction": "Use structural analysis to determine word meaning.",
                "prompt": "In the word 'reconstruct', what does the prefix 're-' signify?",
                "content": {
                    "options": ["Again or back", "Before", "Without", "Under"]
                },
                "correct_answer": "Again or back",
                "explanation": "The prefix 're-' means again or back, so 'reconstruct' means to build again.",
                "hints": ["Think of words like 'replay' or 'redo'."],
                "difficulty": 2,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dys-008",
        "skill_code": "dys_phonics",
        "title": "Vowel Teams & Complex Phonics",
        "description": "Decode advanced vowel teams, silent letters, and irregular graphemes.",
        "track": "dyslexia_track",
        "age_band": "teen",
        "difficulty": 2,
        "sequence_order": 8,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "phonics",
                "instruction": "Match words sharing identical vowel team sounds.",
                "prompt": "Which word shares the same long /o/ vowel team sound as 'boat'?",
                "content": {
                    "options": ["float", "broad", "boot", "bought"]
                },
                "correct_answer": "float",
                "explanation": "'Float' and 'boat' both use the 'oa' vowel team for long /o/.",
                "hints": ["Look for the 'oa' spelling pattern making the long /o/ sound."],
                "difficulty": 2,
                "sequence_order": 1,
            },
            {
                "exercise_type": "phonics",
                "instruction": "Identify the word containing a silent consonant pattern.",
                "prompt": "Which word features an initial silent consonant?",
                "content": {
                    "options": ["knight", "king", "kite", "kitchen"]
                },
                "correct_answer": "knight",
                "explanation": "In 'knight', the 'k' before 'n' is silent, producing the /n/ sound.",
                "hints": ["Pronounce each word and find the letter you do not speak."],
                "difficulty": 2,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dys-009",
        "skill_code": "dys_spelling",
        "title": "Academic Spelling & Morphology",
        "description": "Master suffix spelling rules and morphological transformations in school vocabulary.",
        "track": "dyslexia_track",
        "age_band": "teen",
        "difficulty": 2,
        "sequence_order": 9,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "spelling",
                "instruction": "Apply the consonant doubling rule when adding a suffix.",
                "prompt": "Which is the correct spelling for adding '-ing' to 'begin'?",
                "content": {
                    "options": ["beginning", "begining", "begginning", "beginign"]
                },
                "correct_answer": "beginning",
                "explanation": "Because 'begin' is accented on the second syllable with a short vowel, double the 'n'.",
                "hints": ["Double the final consonant before adding '-ing'."],
                "difficulty": 2,
                "sequence_order": 1,
            },
            {
                "exercise_type": "spelling",
                "instruction": "Select the correct nominalized suffix spelling.",
                "prompt": "Complete the academic sentence: 'The biology lab required careful ____.'",
                "content": {
                    "options": ["observation", "observasion", "observacion", "observashen"]
                },
                "correct_answer": "observation",
                "explanation": "The Latin-origin root takes the '-tion' suffix for 'observation'.",
                "hints": ["Most scientific action-to-noun words end with '-tion'."],
                "difficulty": 2,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dys-010",
        "skill_code": "dys_fluency",
        "title": "Science Text Reading: Ecosystem Cycles",
        "description": "Read informational science text with sentence focus tracking and adjustable pacing.",
        "track": "dyslexia_track",
        "age_band": "teen",
        "difficulty": 2,
        "sequence_order": 10,
        "estimated_effort_minutes": 7,
        "exercises": [
            {
                "exercise_type": "reading_passage",
                "instruction": "Read the passage or use TTS read-aloud to review the key concept.",
                "prompt": "What primary source of energy fuels the process of photosynthesis?",
                "content": {
                    "passage": "Plants convert sunlight, carbon dioxide, and water into chemical energy through photosynthesis. This oxygen-producing cycle provides the vital energy foundation for organisms across both terrestrial and aquatic ecosystems.",
                    "options": [
                        "Sunlight",
                        "Soil minerals",
                        "Wind currents",
                        "Deep geothermal vents",
                    ]
                },
                "correct_answer": "Sunlight",
                "explanation": "The text states that plants convert sunlight, carbon dioxide, and water into energy.",
                "hints": ["Read the first three words of the passage."],
                "difficulty": 2,
                "sequence_order": 1,
            },
        ],
    },
    {
        "id": "lesson-dys-011",
        "skill_code": "dys_reading_comprehension",
        "title": "Informational Text Comprehension",
        "description": "Analyze relationships, cause and effect, and academic vocabulary in informational texts.",
        "track": "dyslexia_track",
        "age_band": "teen",
        "difficulty": 2,
        "sequence_order": 11,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "reading_comprehension",
                "instruction": "Identify the primary significance described in the passage.",
                "prompt": "Why is photosynthesis described as an energy foundation for ecosystems?",
                "content": {
                    "passage": "Plants convert sunlight, carbon dioxide, and water into chemical energy through photosynthesis. This oxygen-producing cycle provides the vital energy foundation for organisms across both terrestrial and aquatic ecosystems.",
                    "options": [
                        "It produces oxygen and chemical energy that support living organisms",
                        "It prevents seasonal temperature changes across the globe",
                        "It removes all mineral deposits from freshwater lakes",
                        "It replaces the need for water in terrestrial environments",
                    ]
                },
                "correct_answer": "It produces oxygen and chemical energy that support living organisms",
                "explanation": "Photosynthesis provides the energy foundation because it produces oxygen and usable chemical energy.",
                "hints": ["Look at the second sentence describing the oxygen-producing cycle."],
                "difficulty": 2,
                "sequence_order": 1,
            },
        ],
    },
    # Adult Lessons (Ages 18+)
    {
        "id": "lesson-dys-012",
        "skill_code": "dys_fluency",
        "title": "Workplace Document Reading: Safety Notice",
        "description": "Navigate functional workplace notices and memos with clear line guides and TTS.",
        "track": "dyslexia_track",
        "age_band": "adult",
        "difficulty": 3,
        "sequence_order": 12,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "reading_passage",
                "instruction": "Review the operational memo and verify the specified logistical instructions.",
                "prompt": "Where should commercial deliveries be directed during Thursday's maintenance?",
                "content": {
                    "passage": "Annual facility maintenance is scheduled for Building B this Thursday from 8:00 AM to 12:00 PM. Access to the main loading dock will be temporarily restricted during freight elevator inspection. All freight deliveries must be rerouted to Entrance C during this four-hour window.",
                    "options": [
                        "Entrance C",
                        "Main Loading Dock",
                        "Building A Reception",
                        "Underground Parking Ramp",
                    ]
                },
                "correct_answer": "Entrance C",
                "explanation": "The memo instructs that all freight deliveries must be rerouted to Entrance C.",
                "hints": ["Check the final sentence specifying the delivery location."],
                "difficulty": 3,
                "sequence_order": 1,
            },
        ],
    },
    {
        "id": "lesson-dys-013",
        "skill_code": "dys_spelling",
        "title": "Professional Spelling & Orthography",
        "description": "Reinforce accurate orthographic patterns in high-frequency professional communication.",
        "track": "dyslexia_track",
        "age_band": "adult",
        "difficulty": 3,
        "sequence_order": 13,
        "estimated_effort_minutes": 5,
        "exercises": [
            {
                "exercise_type": "spelling",
                "instruction": "Select the correct standard spelling used in corporate policies.",
                "prompt": "Which is the correct spelling for arranging suitable provisions or lodging?",
                "content": {
                    "options": [
                        "accommodate",
                        "acommodate",
                        "accomodate",
                        "acomodate",
                    ]
                },
                "correct_answer": "accommodate",
                "explanation": "'Accommodate' features double 'c' and double 'm'.",
                "hints": ["Remember: two 'c's and two 'm's."],
                "difficulty": 3,
                "sequence_order": 1,
            },
            {
                "exercise_type": "spelling",
                "instruction": "Select the correct spelling for professional calendar items.",
                "prompt": "Complete the sentence: 'Please confirm the updated project ____ before Friday.'",
                "content": {
                    "options": ["schedule", "schedual", "skedule", "scedule"]
                },
                "correct_answer": "schedule",
                "explanation": "'Schedule' is spelled with 'sch' and ends with 'dule'.",
                "hints": ["Notice the Greek-derived 'sch' spelling."],
                "difficulty": 3,
                "sequence_order": 2,
            },
        ],
    },
    {
        "id": "lesson-dys-014",
        "skill_code": "dys_reading_comprehension",
        "title": "Higher Education Reading: Urban Architecture",
        "description": "Analyze technical concepts and evidence in academic articles with assistive tools.",
        "track": "dyslexia_track",
        "age_band": "adult",
        "difficulty": 3,
        "sequence_order": 14,
        "estimated_effort_minutes": 7,
        "exercises": [
            {
                "exercise_type": "reading_comprehension",
                "instruction": "Evaluate the technical text and identify the stated ecological objective.",
                "prompt": "What primary environmental objective does permeable pavement serve in urban design?",
                "content": {
                    "passage": "Sustainable urban design incorporates green infrastructure, permeable pavements, and reflective roofing materials to mitigate urban heat islands and reduce stormwater runoff. Permeable pavements allow rainwater to infiltrate the subsoil naturally, preventing urban drainage overflow.",
                    "options": [
                        "Allowing rainwater to infiltrate the subsoil and reduce runoff overflow",
                        "Increasing vehicular speeds on multi-lane city boulevards",
                        "Reflecting commercial street lighting during evening hours",
                        "Replacing the need for municipal drinking water systems",
                    ]
                },
                "correct_answer": "Allowing rainwater to infiltrate the subsoil and reduce runoff overflow",
                "explanation": "The text directly states permeable pavements allow rainwater to infiltrate subsoil and prevent overflow.",
                "hints": ["Look at the second sentence explaining rainwater infiltration."],
                "difficulty": 3,
                "sequence_order": 1,
            },
        ],
    },
    {
        "id": "lesson-dys-015",
        "skill_code": "dys_decoding",
        "title": "Advanced Structural Word Analysis",
        "description": "Analyze Greek and Latin root morphemes commonly found in professional and technical texts.",
        "track": "dyslexia_track",
        "age_band": "adult",
        "difficulty": 3,
        "sequence_order": 15,
        "estimated_effort_minutes": 6,
        "exercises": [
            {
                "exercise_type": "decoding",
                "instruction": "Identify the morphemic root meaning.",
                "prompt": "What does the root morpheme 'chron' mean in 'chronological' and 'synchronize'?",
                "content": {
                    "options": ["Time", "Color", "Measure", "Sound"]
                },
                "correct_answer": "Time",
                "explanation": "The Greek root 'chron' means time (as in chronological order or synchronized clocks).",
                "hints": ["Chronology is the study of events arranged in order of time."],
                "difficulty": 3,
                "sequence_order": 1,
            },
            {
                "exercise_type": "decoding",
                "instruction": "Recognize the shared morphemic root.",
                "prompt": "Which word shares the Latin root 'dict' (to say or speak) with 'dictate'?",
                "content": {
                    "options": ["contradict", "conduct", "construct", "contract"]
                },
                "correct_answer": "contradict",
                "explanation": "'Contradict' combines 'contra' (against) and 'dict' (to speak).",
                "hints": ["Look for the word containing the exact root 'dict'."],
                "difficulty": 3,
                "sequence_order": 2,
            },
        ],
    },
]


def seed_learning_lessons_and_exercises(db: Session) -> None:
    """Populates curriculum-aligned practice lessons and exercises idempotently."""
    # Build skill code to ID lookup
    skills = db.query(Skill).all()
    skill_map = {s.code: s.id for s in skills}

    for l_data in LESSONS_SEED_DATA:
        skill_id = skill_map.get(l_data["skill_code"])
        if not skill_id:
            continue

        existing_lesson = db.query(Lesson).filter(Lesson.id == l_data["id"]).first()
        if not existing_lesson:
            lesson = Lesson(
                id=l_data["id"],
                skill_id=skill_id,
                title=l_data["title"],
                description=l_data["description"],
                track=l_data["track"],
                age_band=l_data["age_band"],
                difficulty=l_data["difficulty"],
                sequence_order=l_data["sequence_order"],
                estimated_effort_minutes=l_data["estimated_effort_minutes"],
                active=True,
            )
            db.add(lesson)
            db.flush()
        else:
            lesson = existing_lesson
            lesson.skill_id = skill_id
            lesson.title = l_data["title"]
            lesson.description = l_data["description"]
            lesson.track = l_data["track"]
            lesson.age_band = l_data["age_band"]
            lesson.difficulty = l_data["difficulty"]
            lesson.sequence_order = l_data["sequence_order"]
            lesson.estimated_effort_minutes = l_data["estimated_effort_minutes"]
            lesson.active = True

        # Add or update exercises for this lesson
        for ex_data in l_data.get("exercises", []):
            # Check if exercise already exists by sequence order in lesson
            existing_ex = (
                db.query(Exercise)
                .filter(
                    Exercise.lesson_id == lesson.id,
                    Exercise.sequence_order == ex_data["sequence_order"],
                )
                .first()
            )
            correct_ans_str = (
                json.dumps(ex_data["correct_answer"])
                if isinstance(ex_data["correct_answer"], (dict, list))
                else str(ex_data["correct_answer"])
            )
            if not existing_ex:
                exercise = Exercise(
                    lesson_id=lesson.id,
                    skill_id=skill_id,
                    exercise_type=ex_data["exercise_type"],
                    prompt=ex_data["prompt"],
                    instruction=ex_data["instruction"],
                    content_json=json.dumps(ex_data["content"]),
                    correct_answer_json=correct_ans_str,
                    explanation=ex_data.get("explanation"),
                    difficulty=ex_data.get("difficulty", lesson.difficulty),
                    age_band=lesson.age_band,
                    track=lesson.track,
                    sequence_order=ex_data["sequence_order"],
                    hints_json=json.dumps(ex_data.get("hints", [])),
                    feedback_config_json=json.dumps(ex_data.get("feedback_config", {})),
                    active=True,
                )
                db.add(exercise)
            else:
                existing_ex.skill_id = skill_id
                existing_ex.exercise_type = ex_data["exercise_type"]
                existing_ex.prompt = ex_data["prompt"]
                existing_ex.instruction = ex_data["instruction"]
                existing_ex.content_json = json.dumps(ex_data["content"])
                existing_ex.correct_answer_json = correct_ans_str
                existing_ex.explanation = ex_data.get("explanation")
                existing_ex.difficulty = ex_data.get("difficulty", lesson.difficulty)
                existing_ex.age_band = lesson.age_band
                existing_ex.track = lesson.track
                existing_ex.hints_json = json.dumps(ex_data.get("hints", []))
                existing_ex.feedback_config_json = json.dumps(ex_data.get("feedback_config", {}))
                existing_ex.active = True

    db.commit()
