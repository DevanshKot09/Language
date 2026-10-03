# 04_TECHNICAL_ARCHITECTURE

## LINGUA AI — technical architecture

## 1. Architecture decisions

### Recommended stack

**Mobile:** Flutter + Dart (Android + iOS)

**Web:** Next.js + TypeScript for desktop-first role dashboards and accessible learner web experience; share design tokens and API contracts with mobile rather than duplicating business rules.

**Backend API:** Python + FastAPI

**Background jobs:** Python workers + Redis queue

**Database:** PostgreSQL

**Cache / queue:** Redis

**Object storage:** S3-compatible object storage for optional audio, report files and user uploads

**Authentication:** OIDC/OAuth 2.1 provider with MFA for adult/professional roles; use managed identity only after security/privacy/DPA review. Production can use a dedicated identity provider or self-hosted Keycloak depending on operational capacity.

**AI services:** provider-agnostic service adapters; keep model calls behind a backend interface so the product is not coupled to one vendor.

**Speech:** prefer on-device where feasible; otherwise encrypted backend processing with explicit retention rules.

**Observability:** OpenTelemetry + centralized logs/metrics/alerts.

**Reference cloud:** deploy on a major cloud with managed PostgreSQL, object storage, containerized API workers, private networking, secret manager, WAF and audit logging. Exact provider can be selected after data-residency and contract review.

## 2. Why Flutter for mobile

Flutter is well suited to Android + iOS because it permits a shared UI/component layer, predictable rendering and reusable accessibility semantics. Flutter documentation explicitly supports accessibility and screen-reader testing. [T1]

However, the web application should not be forced into a pure "Flutter everywhere" decision. Flutter web can expose accessible HTML/semantics, but a dashboard-heavy product benefits from the web ecosystem's mature table/form/navigation tooling. The recommended split is therefore:

**Flutter mobile + Next.js web + shared backend/data contracts.**

Shared assets:

- design tokens JSON;
- content schema;
- REST/OpenAPI contracts;
- localization files;
- analytics event names;
- skill taxonomy IDs.

## 3. High-level system

```text
                 ┌──────────────────────────┐
                 │ Flutter Android / iOS    │
                 └────────────┬─────────────┘
                              │ HTTPS
                 ┌────────────▼─────────────┐
                 │ Next.js Responsive Web   │
                 └────────────┬─────────────┘
                              │
                       API Gateway / WAF
                              │
                 ┌────────────▼─────────────┐
                 │ FastAPI Application       │
                 │ AuthZ / Skills / Progress │
                 │ Content / Reports / AI    │
                 └─────┬──────────┬─────────┘
                       │          │
             ┌─────────▼───┐   ┌─▼──────────────┐
             │ PostgreSQL  │   │ Redis / Workers │
             └─────────────┘   └─┬──────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │ AI / Speech Adapters      │
                    │ ASR / TTS / LLM / OCR     │
                    └─────────────┬─────────────┘
                                  │
                         ┌────────▼────────┐
                         │ Object Storage  │
                         │ audio / reports │
                         └─────────────────┘
```

## 4. Service boundaries

### Identity Service

Responsibilities:

- login/logout;
- email/phone verification;
- MFA for privileged roles;
- session/token management;
- role claims.

### User/Profile Service

Stores demographics and preferences needed for personalization; minimize collection.

### Relationship Service

Manages parent-child, teacher-student and specialist-learner relationships. Every relationship has status, scope, permissions, created_by, approved_by and timestamps.

### Learning Service

Stores skills, lessons, exercises, prerequisites, content versions and attempts.

### Progress Service

Calculates skill aggregates and time-series summaries. This service should be deterministic in MVP.

### Recommendation Service

Phase 1: rules. Phase 2: ML ranking on top of rules.

### Screening Support Service

Stores assessment sessions, tool version, raw responses, scoring metadata and clinician review status. Diagnostic interpretation stays outside the platform's autonomous logic.

### Speech Service

Pipeline:

`audio -> VAD -> ASR / alignment -> confidence -> target evaluation -> feedback object`

### AI Content Service

Constrained generation only. Inputs are skill objective + approved content constraints; no direct access to unrestricted user data unless specifically required and permitted.

### Report Service

Generates user-readable summaries from structured data. PDF generation is a backend job, not a request-time operation.

## 5. Database design

### User

- `id`
- `email`
- `status`
- `created_at`
- `updated_at`

### Profile

- `user_id`
- `display_name`
- `date_of_birth` or age-band representation depending on privacy design
- `preferred_language`
- `timezone`
- `accessibility_profile_id`

Avoid storing precise date of birth when age band is sufficient for the product purpose.

### AgeGroup

- `id`
- `name`
- `min_age`
- `max_age`
- `ui_profile`
- `content_profile`

### LearningProfile

- `id`
- `user_id`
- `track_type` (`DLD_SUPPORT`, `LITERACY_SUPPORT`, `MIXED`)
- `created_from`
- `confidence`
- `review_status`
- `updated_at`

`track_type` is a support configuration, not a clinical diagnosis field.

### Skill

- `id`
- `domain`
- `name`
- `description`
- `prerequisite_skill_id`
- `evidence_tag`
- `age_band`
- `language`

### SkillAssessment

- `id`
- `user_id`
- `skill_id`
- `assessment_type`
- `score`
- `raw_response_ref`
- `version`
- `review_status`

### ScreeningSession

- `id`
- `user_id`
- `tool_id`
- `tool_version`
- `status`
- `started_at`
- `completed_at`
- `disclaimer_version`

### Question

- `id`
- `skill_id`
- `lesson_id`
- `prompt`
- `response_type`
- `difficulty`
- `content_version`

### Lesson

- `id`
- `skill_id`
- `title`
- `age_band`
- `duration_seconds`
- `content_version`

### Exercise

- `id`
- `lesson_id`
- `exercise_type`
- `objective`
- `accessibility_tags`

### ExerciseAttempt

- `id`
- `exercise_id`
- `user_id`
- `attempt_number`
- `correct`
- `latency_ms`
- `hints_used`
- `response_metadata`
- `created_at`

### Progress

- `id`
- `user_id`
- `skill_id`
- `mastery_estimate`
- `accuracy_7d`
- `accuracy_30d`
- `independent_rate`
- `updated_at`

### Achievement / Streak / Goal

Use independent tables; do not entangle reward state with educational mastery.

### ParentChildRelationship / TeacherStudentRelationship / SpecialistRelationship

All relationship tables should support:

- actor user ID;
- target user ID;
- organization/scope;
- consent state;
- data visibility scope;
- status;
- timestamps.

### Recommendation

- `id`
- `user_id`
- `skill_id`
- `reason_code`
- `source_type` (`RULE`, `MODEL`)
- `explanation`
- `accepted`
- `created_at`

### AIInteraction

- `id`
- `user_id`
- `feature`
- `model_provider`
- `model_version`
- `input_classification`
- `output_classification`
- `safety_flags`
- `retained`
- `created_at`

Avoid storing raw prompts containing child data unless explicitly necessary.

### VoiceRecording

- `id`
- `user_id`
- `purpose`
- `storage_uri`
- `duration_ms`
- `transcript_ref`
- `retention_until`
- `consent_scope`
- `deleted_at`

### Report

- `id`
- `user_id`
- `created_by`
- `report_type`
- `visibility_scope`
- `object_uri`
- `version`
- `created_at`

## 6. Entity relationship sketch

```text
User 1──1 Profile
User 1──1 LearningProfile
User 1──∞ ExerciseAttempt ──∞ Exercise ──∞ Lesson ──1 Skill
User 1──∞ Progress ──1 Skill
User 1──∞ Goal
User 1──∞ Recommendation ──1 Skill
User 1──∞ AIInteraction
User 1──∞ VoiceRecording
User 1──∞ ScreeningSession
ScreeningSession 1──∞ SkillAssessment ──1 Skill
User 1──∞ Report
User 1──∞ ParentChildRelationship ──∞ User
User 1──∞ TeacherStudentRelationship ──∞ User
User 1──∞ SpecialistRelationship ──∞ User
```

## 7. API design

Use REST for the main API with OpenAPI generation from FastAPI. Keep AI/speech calls asynchronous where latency is unpredictable.

Example endpoints:

```text
POST   /v1/auth/session
GET    /v1/me
PATCH  /v1/me/profile
GET    /v1/me/learning-path
GET    /v1/skills
GET    /v1/lessons/{lessonId}
POST   /v1/attempts
GET    /v1/progress
POST   /v1/goals
GET    /v1/recommendations
POST   /v1/screening/sessions
POST   /v1/speech/transcribe
POST   /v1/speech/analyze
POST   /v1/ai/explain
POST   /v1/reports
POST   /v1/relationships
GET    /v1/audit/events
```

Every endpoint must enforce:

1. authentication;
2. role/relationship authorization;
3. record-level ownership/scope;
4. input validation;
5. audit logging for sensitive operations.

## 8. Authentication and authorization

Use OIDC/OAuth 2.1 style flows.

Mobile:

- authorization code + PKCE;
- secure OS token storage;
- refresh token rotation where supported;
- device logout/revocation.

Web:

- secure, httpOnly session cookies where appropriate;
- CSRF protection for cookie-authenticated state-changing requests;
- no tokens in localStorage if avoidable.

RBAC roles:

`LEARNER`, `PARENT`, `TEACHER`, `SPECIALIST`, `ORG_ADMIN`, `SYSTEM_ADMIN`.

ABAC additions:

- relationship active?
- organization scope?
- consent present?
- data category allowed?

## 9. AI architecture

### Layer 1 — content and skill rules

No AI needed. Curriculum decides what skill is being trained.

### Layer 2 — recommendation engine

Rule-based thresholds.

### Layer 3 — optional ML ranker

Ranks next-task candidates from allowed candidates.

### Layer 4 — generative AI

Only for constrained tasks:

- explanation;
- examples;
- controlled story variations;
- progress summaries.

### AI gateway contract

```text
AIRequest
- feature
- user_context_minimal
- skill_context
- language
- age_band
- safety_policy
- prompt_template_version

AIResponse
- content
- safety_flags
- confidence/quality metadata
- model_version
- provenance
```

## 10. Speech architecture

### MVP approach

Use platform or managed speech APIs only for basic transcription if necessary, but store **no audio by default**.

### Privacy-forward path

For supported devices/languages, evaluate on-device inference via sherpa-onnx/Vosk or platform speech services. This reduces server-side voice retention risk.

### Reading flow

```text
Passage
  │
  ├── expected token sequence
  │
  └── user audio
        │
        ▼
      VAD
        │
        ▼
   ASR / alignment
        │
        ▼
 token-level comparison
        │
        ├── confidence
        ├── omissions
        ├── substitutions
        └── timing
        │
        ▼
 practice feedback
```

Do not infer DLD/dyslexia from this output.

## 11. OCR architecture

Use OCR to help a learner access a teacher worksheet, textbook page or personal document where rights and privacy permit.

`image -> local OCR if possible -> user confirms text -> TTS / read-aloud`

Tesseract is Apache-2.0, but its dependencies and the content being scanned still require review. [O1]

## 12. Caching and offline

Local storage:

- SQLite/Drift or Isar for structured local data;
- secure storage for secrets/tokens;
- encrypted local cache for sensitive content where feasible.

Offline queue:

`local_event -> sync_queue -> encrypted upload -> server idempotency key -> ack -> remove local queue item`

Never silently overwrite server progress.

## 13. Folder structure — Flutter

```text
mobile/
  lib/
    app/
      router/
      theme/
      accessibility/
    core/
      networking/
      storage/
      analytics/
      errors/
      widgets/
    features/
      onboarding/
      authentication/
      learner_home/
      learning_path/
      vocabulary/
      grammar/
      phonological_awareness/
      phonics/
      reading/
      comprehension/
      listening/
      speaking/
      pronunciation/
      storytelling/
      progress/
      goals/
      achievements/
      profile/
      accessibility/
      parent/
      teacher/
      specialist/
    shared/
      models/
      design_tokens/
      l10n/
```

## 14. Folder structure — backend

```text
backend/
  app/
    api/
    auth/
    users/
    relationships/
    skills/
    lessons/
    attempts/
    progress/
    recommendations/
    screening/
    speech/
    ai/
    reports/
    audit/
    privacy/
    common/
  tests/
```

## 15. Security architecture

- TLS 1.2+; prefer current TLS configurations.
- encryption at rest using managed keys.
- separate production/staging environments.
- secrets in secret manager, never source control.
- short-lived service credentials.
- database private networking.
- least-privilege service accounts.
- WAF/rate limiting on public endpoints.
- malware scanning for file uploads.
- audit trail for data export/share/delete.
- immutable logs for security events where possible.
- dependency scanning + SBOM.
- incident-response runbook.

## 16. Privacy-by-design architecture

Data classes:

**Class A:** account data.

**Class B:** learning/progress data.

**Class C:** relationship/consent data.

**Class D:** screening/assessment data.

**Class E:** voice/audio/biometric-adjacent data.

Class E should have the strictest retention and access controls.

Use separate database permissions/columns or services where practical. Do not make voice accessible to general analytics queries.

## 17. Testing strategy

### Unit tests

- recommendation rules;
- scoring rules;
- consent logic;
- access policy;
- age adaptation;
- content validation.

### Widget/component tests

- learner lesson flow;
- accessibility state changes;
- recording UI;
- progress components;
- retry/error states.

### Integration tests

- auth + relationship access;
- lesson -> attempt -> progress;
- speech pipeline;
- report generation;
- offline sync.

### Security tests

- authorization matrix;
- IDOR tests;
- rate-limit tests;
- token expiry/revocation;
- file upload sandboxing;
- audit logging.

### AI evaluation

- age/language subgroup accuracy;
- hallucination rate;
- unsafe-output rate;
- response stability;
- recommendation acceptance vs benefit;
- false-confidence analysis.

## 18. Deployment architecture

```text
Internet
  │
CDN/WAF
  │
Load Balancer
  │
┌───────────────┐
│ API containers │────── Redis
└──────┬────────┘
       │
   PostgreSQL
       │
 Object storage
       │
AI/Speech services (private egress where possible)
```

Use separate environments:

`local -> dev -> staging -> production`

No production child/sensitive data in developer environments.

## 19. Open-source integration strategy

### Approved for evaluation

- Whisper (MIT): transcription baseline.
- sherpa-onnx (Apache-2.0): on-device speech candidate.
- Vosk (Apache-2.0): offline ASR candidate.
- SpeechBrain (Apache-2.0): research/model toolkit.
- Tesseract (Apache-2.0): OCR.
- Montreal Forced Aligner (MIT): alignment pipeline candidate.
- Piper (MIT repo): local TTS candidate.

### Use with legal boundary

- Phonemizer (GPL): not a default embedded dependency in a proprietary client.
- Meta Seamless: research-only because its license is noncommercial.

### Inspiration/reference

- archived fairseq: research reference only; do not introduce as a new production dependency without a compelling reason.

## 20. Architecture principles

1. Keep the core learning loop functional without AI.
2. Keep AI behind interfaces.
3. Keep sensitive voice separate from analytics.
4. Keep relationships and permissions explicit.
5. Store age adaptation as configuration.
6. Treat content licensing as a first-class data field.
7. Make every AI recommendation explainable and overrideable.
8. Design for offline-friendly reading practice.

## 21. Verified technical sources

- Flutter accessibility: https://docs.flutter.dev/ui/accessibility/ [T1]
- Flutter web accessibility: https://docs.flutter.dev/ui/accessibility/web-accessibility [T2]
- W3C WCAG 2.2: https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/ [T3]
- OpenAI Whisper repo/license: https://github.com/openai/whisper [O1]
- sherpa-onnx: https://github.com/k2-fsa/sherpa-onnx [O2]
- Vosk: https://github.com/alphacephei/vosk-api [O3]
- SpeechBrain: https://github.com/speechbrain/speechbrain [O4]
- Tesseract: https://github.com/tesseract-ocr/tesseract [O5]
- Montreal Forced Aligner: https://github.com/MontrealCorpusTools/Montreal-Forced-Aligner [O6]
- Piper: https://github.com/rhasspy/piper [O7]
- Phonemizer: https://github.com/bootphon/phonemizer [O8]
- fairseq: https://github.com/facebookresearch/fairseq [O9]
- Seamless license: https://github.com/facebookresearch/seamless_communication/blob/main/SEAMLESS_LICENSE [O10]

## 22. Technical decisions that should wait for validation

Do not lock the following before a pilot:

- exact ASR model;
- exact LLM vendor;
- cloud region;
- clinical assessment instruments;
- voice-retention duration;
- local vs server inference for every device tier;
- multilingual model coverage.

Those decisions depend on measured accuracy, privacy/legal review, device performance and licensing.
