# 02_PRODUCT_REQUIREMENTS

## LINGUA AI — Product Requirements Specification

## 1. Product definition

**Working name:** LINGUA AI

**Positioning:** An evidence-informed, age-adaptive language and literacy support platform for people affected by Developmental Language Disorder (DLD) and/or dyslexia, with tools for families, educators and relevant professionals.

**Core promise:** help a learner understand what to practice, practice it accessibly, see progress, and connect that progress with the adults/professionals supporting them.

**Explicit boundary:** LINGUA AI is not a doctor, SLP, psychologist, educational specialist, diagnostic instrument, or replacement for formal assessment/treatment.

## 2. Problem statement

Existing digital support is fragmented across early speech practice, elementary literacy, reading accessibility, generic tutoring and clinician-led services. The research base shows that DLD and dyslexia overlap but require different skill targets. LINGUA AI should therefore combine access and learning support without collapsing the conditions into one label or score.

## 3. Target users

### Learner — child
School-age children who need language and/or literacy practice. The product should prioritize short sessions, visual support, simple instructions, low reading load and parent/teacher support. It should not be preschool-only.

### Learner — teen
Students who need more independence, motivation and academic relevance. Content should connect with school subjects, real-world reading and self-advocacy.

### Learner — adult
Adults in higher education, work or everyday life. Focus on practical reading/writing/speaking/listening, accessible documents, self-directed goals and privacy.

### Parent/caregiver
Needs understandable explanations, home-practice guidance, consent controls, child profiles, progress summaries and communication with professionals.

### Teacher
Needs class/student-level visibility, assigned practice, accommodation notes, plain-language summaries and low administrative burden.

### Specialist
SLP, educational specialist, psychologist/reading professional or other authorized role. Needs professional goal setting, session notes, progress trends, report export and role-based access.

## 4. Personas

| Persona | Goal | Pain point | Product response |
|---|---|---|---|
| School-age learner | practice without feeling "tested all the time" | hard tasks, confusing feedback | short adaptive activities, retry, encouraging feedback |
| Teen learner | improve reading/speaking for school and life | childlike tools feel irrelevant | modern UI, practical content, control over goals |
| Adult learner | function more easily at college/work | fragmented assistive tools | reading/writing support, TTS/STT, practical practice |
| Parent | know how to help at home | jargon and scattered advice | simple explanations + assigned home activities |
| Teacher | see what support helps | limited time and fragmented data | compact dashboard + class assignments |
| Specialist | track evidence of progress | manual data collection | structured goal/progress records and exportable reports |

## 5. User journeys

### Learner journey
Welcome → role → age → consent (as applicable) → profile → optional screening/support assessment → skill profile → personalized path → daily practice → feedback → progress → goals → repeat.

### Parent journey
Create account → verify consent/relationship → add child → view onboarding summary → receive home-practice tasks → review progress → communicate/share report with authorized professional.

### Teacher journey
Sign in → class roster → select student/group → assign a skill plan → review completion and trends → add observation → coordinate with specialist/parent as permitted.

### Specialist journey
Sign in → client list → review referral/profile → inspect baseline and prior results → set professional goals → assign/approve activities → review trend data → add note/report → export/share with explicit permission.

## 6. Functional requirements

### FR-01 Identity and roles
The system shall support learner, parent/caregiver, teacher, specialist and administrator roles. A person may have more than one role in the same organization only where policy allows.

### FR-02 Age-adaptive configuration
The system shall store age group as configuration metadata, not duplicate app code. Age mode shall change language complexity, content, visual density, reward style, accessibility defaults and task selection.

### FR-03 DLD and dyslexia separation
The system shall maintain separate skill taxonomies and evidence metadata for DLD-oriented and literacy/dyslexia-oriented activities. It shall allow a shared learner profile where indicated.

### FR-04 Screening support
The product may present optional screening/support activities using validated and licensed instruments where available. Every result screen shall clearly label these as **screening/support indicators**, not diagnosis.

### FR-05 Learning skill engine
Lessons shall be mapped to skills, objectives, difficulty, prerequisites, estimated duration and accessibility tags.

### FR-06 Attempt tracking
Every activity attempt shall record the minimum fields required for personalization and progress reporting: skill, item, outcome, hints, time, optional response, and device/context metadata when justified.

### FR-07 Personalization
A deterministic rule engine shall select recommended practice from skill performance. AI/ML may refine recommendations only after sufficient evaluation and should remain explainable/overrideable.

### FR-08 TTS
Text-to-speech shall be available as an accessibility control. Users can adjust speed, voice (where available), highlighting and auto-play behavior.

### FR-09 STT
Speech-to-text shall be optional, with visible recording status, stop/delete controls, confidence-aware transcription and a manual retry path.

### FR-10 Reading support
Reading mode shall support adjustable text size, line/word spacing, readable font selection, contrast themes, read-aloud, word definitions, highlighting, pause/replay and focus controls.

### FR-11 Progress
The system shall provide skill-level trends, practice history, goal completion and learner reflections. It shall not display a clinical severity score without validated clinical governance.

### FR-12 Collaboration
Parents, teachers and specialists shall only see data explicitly authorized for their relationship and role.

### FR-13 Reports
Reports shall be exportable as structured PDF/document output later, but the MVP can start with an on-screen shareable summary.

### FR-14 Offline-friendly operation
Core text activities and selected audio/TTS content should work offline where technically feasible. Uploading/syncing should occur after connectivity is restored.

### FR-15 Auditability
Sensitive actions such as consent changes, relationship creation, report sharing and deletion requests shall be logged.

## 7. Non-functional requirements

| Area | Requirement |
|---|---|
| Accessibility | WCAG 2.2 AA web target; screen-reader semantics; keyboard navigation; scalable text; reduced motion; captions/transcripts |
| Performance | learner practice screen should feel instant for local interactions; target p95 API latency <500 ms for standard non-AI reads under normal load |
| Reliability | graceful retry; local queue for progress events; avoid data loss during intermittent connectivity |
| Security | TLS in transit, encryption at rest, strict RBAC, secure token handling, secret management, audit logs |
| Privacy | data minimization, consent-aware collection, configurable retention/deletion, privacy by default |
| Maintainability | feature-based folders, typed API contracts, reusable design tokens, automated testing |
| Scalability | stateless API nodes; background jobs for AI/report generation; object storage for media |
| Observability | structured logs, metrics, traces, security events, model monitoring |
| Internationalization | locale-aware text/audio, orthography-aware reading tasks, UTF-8 throughout |
| Safety | no autonomous diagnosis; safe-content controls; age-appropriate AI; clear escalation to humans |

## 8. Age-adaptive requirements

### Child mode

Visual language: friendly and warm, not clinical.

Interaction: one task per screen where possible; large touch targets; short instructions; icon + text; optional audio instruction.

Rewards: XP, badges, character/path progression, but no public leaderboards, shame, negative streak language or loss framing.

Accessibility: reduced motion, high contrast, dyslexia-friendly reading settings, adjustable pace, audio repetition, alternative input where possible.

### Teen mode

Visual language: modern, compact, achievement-oriented.

Interaction: quick start, progress stats, optional challenges, practical academic vocabulary.

Rewards: streaks/achievements used as optional motivation; no forced daily pressure.

### Adult mode

Visual language: professional, clean, low clutter.

Interaction: task batching, goals, search, practical scenarios, flexible session length.

Rewards: progress milestones and competence signals rather than cartoon characters.

## 9. Core feature requirements by classification

### ESSENTIAL — MVP core

- Vocabulary
- Grammar and sentence formation
- Phonological awareness
- Phonics
- Word recognition/decoding
- Reading fluency
- Reading comprehension
- Listening comprehension
- Speaking practice
- TTS + audio-assisted reading
- Personalized learning path
- Progress tracking
- Accessibility settings

### IMPORTANT — MVP+ / early post-MVP

- language screening support
- dyslexia skill/risk screening support
- spelling
- writing
- storytelling/narrative skills
- pronunciation practice
- sequencing
- parent dashboard
- teacher dashboard
- STT/dictation

### OPTIONAL — post-MVP

- social communication modules
- memory/language exercises
- AI conversation practice
- specialist dashboard as a full workflow

### NOT RECOMMENDED

- generic articulation therapy as a universal DLD/dyslexia feature
- autonomous diagnostic score
- "AI diagnosis" branding
- generic brain-training promises
- public learner leaderboards

## 10. Personalization specification

### Rule-based personalization — Phase 1

Inputs: accuracy, recent attempts, hints, latency, skill prerequisites, goals, age mode, accessibility settings.

Example:

`IF phoneme-blending accuracy < threshold AND prerequisites complete → present smaller item set + audio model + additional retry.`

`IF reading accuracy improves but fluency latency remains high → keep decoding target stable and add repeated/connected-text practice.`

`IF vocabulary item is repeatedly missed → add semantic cue + picture + example sentence + spaced re-practice.`

### AI/ML personalization — Phase 2+

AI can learn which task sequences are associated with progress for a given learner profile. The model must not invent the skill taxonomy. It operates on top of a clinician/content-designed curriculum map.

Outputs must include an explanation such as:

> "Suggested because you were accurate on X but needed hints on Y in the last three sessions."

Every recommendation must have a fallback rule and an override.

## 11. Progress model

Progress should be multidimensional:

- skill mastery estimate;
- current level/difficulty;
- recent accuracy;
- independent vs prompted performance;
- fluency/time trend;
- practice consistency;
- goal completion;
- learner-reported confidence (optional);
- accommodation usage.

Avoid aggregating all of these into one clinical-looking score.

## 12. Content requirements

All content items need metadata:

`skill_id, age_band, language, dialect/orthography, difficulty, objective, modality, prerequisite, accessibility_tags, copyright_source, author, review_status, version`.

AI-generated items must be marked with provenance and pass automated + human review rules before production use.

## 13. Safety requirements

- Always distinguish support/screening from diagnosis.
- Do not infer a clinical disorder from ASR confidence or reading performance alone.
- Do not present treatment plans as clinician-equivalent advice.
- Do not store microphone audio by default.
- Provide delete controls and clear retention information.
- Require parent/guardian consent where applicable for child accounts/data processing.
- Prevent advertising/behavioral profiling on child accounts in deployments where prohibited.
- Make escalation to a human professional easy.
- Show model limitations on AI-assisted output.

## 14. Analytics requirements

Collect product analytics separately from educational records wherever possible. Use pseudonymous event IDs for standard usage analytics. Do not use sensitive learner outcomes to build advertising audiences.

Recommended events:

`session_started`, `lesson_started`, `exercise_completed`, `hint_used`, `reading_started`, `reading_completed`, `tts_used`, `stt_used`, `recommendation_shown`, `recommendation_accepted`, `goal_completed`, `report_shared`, `consent_changed`.

## 15. MVP definition

The MVP should prove five things:

1. A learner can create a safe profile and receive an age-adaptive skill path.
2. The DLD-oriented language track and dyslexia-oriented literacy track remain separate but can coexist.
3. The learner can complete short practice sessions with accessibility controls.
4. Progress can be understood by the learner and one supporting adult.
5. No AI feature is required for the core educational loop to work.

### MVP scope

**Learner:** onboarding, profile, skill map, vocabulary, grammar/sentence, phonological awareness, phonics, reading, comprehension, TTS, progress, goals, accessibility.

**Parent/teacher:** basic relationship, assigned activity, progress snapshot.

**Specialist:** read-only progress and exportable summary first; full clinical workflow later.

**AI:** constrained personalization and content variation only; no open-ended clinical assistant.

## 16. Post-MVP

- specialist workspace;
- validated screening integrations;
- richer speech analysis;
- on-device ASR;
- OCR of user-provided worksheets;
- writing support;
- multilingual/orthography-aware curriculum;
- conversation scenarios;
- research study mode and consented outcome collection.

## 17. Success metrics

Do not use diagnosis rates as product KPIs.

Product outcomes:

- practice completion rate;
- successful independent attempts;
- reduction in hint dependence;
- mastery progression by skill;
- repeat-use retention without coercive streak mechanics;
- accessibility feature utilization;
- parent/teacher/specialist task completion;
- report usefulness ratings.

Research outcomes:

- validated pre/post measures where licensed;
- generalization tasks;
- user-reported function;
- subgroup performance across age/language/dialect.
