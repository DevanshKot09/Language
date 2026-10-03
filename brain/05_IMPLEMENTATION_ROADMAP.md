# 05_IMPLEMENTATION_ROADMAP

## LINGUA AI — phased development plan

## 1. Development order

The project should be built in this order:

**Evidence → product rules → design system → content model → core learning loop → progress → roles/relationships → accessibility hardening → speech → constrained AI → professional workflow → research/validation → deployment.**

Do not start with AI speech diagnosis, a full specialist dashboard, or an open-ended chatbot.

## 2. Phase roadmap

### Phase 1 — Research + Product Definition

**Goal:** convert evidence into the validated product boundary.

Deliverables:

- DLD evidence map;
- dyslexia evidence map;
- overlap model;
- feature classification;
- clinical/safety terminology guide;
- target population and inclusion/exclusion criteria;
- content/licensing inventory.

Milestone: product requirements approved by a multidisciplinary review group.

Dependency: none.

Testing checkpoint: review every clinical-facing claim and every screening statement.

### Phase 2 — Design System + UI/UX

Deliverables:

- design tokens;
- child/teen/adult configurations;
- reusable components;
- screen inventory;
- Stitch-ready prompts;
- accessibility specification;
- content tone guide.

Milestone: clickable learner + parent flows.

Testing checkpoint: keyboard, screen-reader, contrast and text-scaling review on representative screens.

### Phase 3 — Flutter Foundation

Deliverables:

- Flutter project;
- routing;
- state management;
- local storage;
- design tokens;
- analytics abstraction;
- error handling;
- environment configuration.

Recommended state management: Riverpod or Bloc; choose one and standardize.

Milestone: app shell running on Android/iOS.

### Phase 4 — Authentication + Profiles

Deliverables:

- sign-up/login;
- role assignment;
- age mode;
- learner profile;
- consent/privacy screens;
- accessibility profile.

Milestone: secure onboarding end-to-end.

Security checkpoint: token storage, logout, account recovery, relationship authorization.

### Phase 5 — Learning Engine

Deliverables:

- skill taxonomy;
- lesson schema;
- exercise schema;
- attempts;
- rule-based recommendations;
- local progress store.

Milestone: learner can complete one full learning loop without AI.

Testing checkpoint: unit tests for scoring and recommendation rules.

### Phase 6 — DLD Modules

Build:

- vocabulary;
- grammar;
- sentence formation;
- listening comprehension;
- speaking;
- storytelling/narrative;
- selected social communication activities.

Milestone: DLD-support learning path.

Validation checkpoint: every activity mapped to evidence and reviewed for age/language appropriateness.

### Phase 7 — Dyslexia / Literacy Modules

Build:

- phonological awareness;
- phonics;
- word recognition/decoding;
- spelling;
- reading fluency;
- reading comprehension;
- writing support.

Milestone: literacy-support path independent of DLD path.

Validation checkpoint: explicit/systematic sequencing and appropriate difficulty progression.

### Phase 8 — Audio + Speech

Start with:

- TTS;
- playback controls;
- reading-aloud recording UI;
- ASR transcription;
- privacy/data controls.

Only then add:

- pronunciation scoring;
- phoneme-level alignment;
- more advanced speech analysis.

Milestone: reading practice with safe speech pipeline.

Validation checkpoint: evaluate by age, language/dialect, device and speech profile; publish no accuracy claim until tested.

### Phase 9 — AI Personalization

First release:

- constrained explanation;
- controlled exercise variation;
- rule-based recommendation explanations.

Later:

- ML task ranking;
- adaptive difficulty model.

Milestone: AI improves convenience without becoming a dependency.

AI safety checkpoint: prompt injection, hallucination, unsafe content, privacy leakage, subgroup evaluation.

### Phase 10 — Progress + Analytics

Build:

- skill trends;
- goal tracking;
- session history;
- teacher/parent summaries;
- text equivalents for charts;
- data export.

Milestone: progress can be interpreted without clinical overclaiming.

### Phase 11 — Parent / Teacher / Specialist

Order:

1. parent basic dashboard;
2. teacher basic dashboard;
3. specialist read-only view;
4. specialist goal/plan workflow;
5. report generation.

Milestone: shared learning plan with explicit permissions.

Privacy checkpoint: test every role pair and organization scope for data leakage.

### Phase 12 — Backend Integration + Scale

Deliverables:

- production Postgres;
- Redis workers;
- object storage;
- API versioning;
- background reports;
- observability;
- backup/restore.

Milestone: cloud staging environment.

### Phase 13 — Testing + Accessibility

Test matrix:

- Android/iOS device tiers;
- desktop browsers;
- tablet;
- keyboard-only;
- TalkBack;
- VoiceOver;
- zoom/text scaling;
- reduced motion;
- high contrast;
- poor network/offline.

Milestone: accessibility release candidate.

### Phase 14 — Security + Privacy

Deliverables:

- threat model;
- data inventory;
- DPIA/impact assessments as appropriate;
- retention schedule;
- deletion workflow;
- breach response plan;
- access-review process;
- dependency/SBOM review;
- open-source license ledger.

Milestone: production security gate.

### Phase 15 — Deployment + Pilot

Launch a controlled pilot first.

Pilot groups should cover:

- child users;
- teen users;
- adult users;
- parents;
- teachers;
- professionals.

Measure:

- usability;
- accessibility;
- completion;
- accuracy of non-clinical skill metrics;
- speech recognition error patterns;
- privacy comprehension;
- stakeholder usefulness.

Only after pilot evidence should wider release and clinical/research partnerships be considered.

## 3. MVP definition

### In scope

**Learner:**
- onboarding;
- profile;
- age-adaptive UI;
- vocabulary;
- grammar/sentence formation;
- phonological awareness;
- phonics;
- word recognition;
- reading;
- comprehension;
- listening;
- speaking;
- TTS;
- accessibility;
- progress;
- goals.

**Adult supporter:**
- parent dashboard;
- teacher dashboard (basic);
- specialist read-only summary.

**Backend:**
- auth;
- profiles;
- skills/lessons/exercises;
- attempts;
- progress;
- relationships;
- audit events.

**AI:**
- constrained personalization explanations only.

### Explicitly out of MVP

- autonomous diagnosis;
- diagnostic probability score;
- general-purpose medical chatbot;
- unrestricted AI therapy planner;
- autonomous pronunciation diagnosis;
- public social network;
- behavior-advertising monetization for child accounts;
- generic articulation therapy module.

## 4. Milestones

| Milestone | Exit condition |
|---|---|
| M1 Evidence lock | evidence map and safety boundary approved |
| M2 Design lock | component library and age modes approved |
| M3 Learning loop | end-to-end learner session works locally |
| M4 First content | DLD + literacy pilot curriculum complete |
| M5 Data foundation | secure backend + progress persistence works |
| M6 Accessibility RC | core screens pass accessibility checklist |
| M7 Speech RC | speech pipeline measured and bounded |
| M8 Collaboration RC | parent/teacher roles work with permissions |
| M9 Pilot RC | security, privacy, usability and analytics ready |

## 5. Dependencies

```text
Research
  ↓
Safety + evidence rules
  ↓
Skill taxonomy + content schema
  ↓
Design system
  ↓
Learning engine
  ↓
DLD + Literacy content
  ↓
Progress
  ↓
Roles / collaboration
  ↓
Speech
  ↓
AI personalization
  ↓
Pilot / validation
```

AI should depend on stable skill/content definitions, not define them.

## 6. Testing checkpoints

### Every sprint

- unit tests;
- accessibility spot-check;
- security regression for changed permissions.

### Every feature completion

- mobile + web behavior;
- empty/loading/error/success states;
- reduced-motion behavior;
- localization readiness.

### Before pilot

- full authorization matrix;
- child/consent flow;
- data export/delete;
- voice retention;
- model subgroup evaluation;
- backup/restore.

## 7. Open-source integration strategy

### Stage A — audit

For each repository record:

- repository URL;
- commit/tag pinned;
- license;
- dependencies;
- model/weight license;
- dataset license;
- mobile support;
- security issues;
- maintenance activity.

### Stage B — isolate

Wrap third-party components behind internal interfaces such as:

`SpeechRecognizer`, `SpeechSynthesizer`, `OCRProvider`, `PhonemeAligner`.

This allows replacement without rewriting the application.

### Stage C — prove

Benchmark on LINGUA AI's actual target population and devices.

### Stage D — production review

Legal/security approval before shipping any model/voice/dataset with ambiguous licensing.

## 8. Risk register

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Overclaiming diagnosis | medium | high | product copy gate; clinical/legal review; separate screening language |
| ASR misrecognizes child/atypical speech | high | high | on-device/validated ASR, confidence, retry, manual correction, no diagnosis |
| DLD/dyslexia concepts get conflated | medium | high | separate skill taxonomies and evidence IDs |
| Child privacy failure | low/medium | very high | minimization, parental consent, strict RBAC, no unnecessary voice storage |
| Weak digital evidence | medium | high | pilot research; outcome tracking; conservative claims |
| AI hallucination | medium | medium/high | constrained generation, validators, human review |
| Accessibility regressions | medium | high | automated + manual accessibility checks every release |
| Content licensing violation | medium | high | provenance ledger; legal review |
| Too much scope | high | high | MVP gate and phase dependencies |
| Adult UX feels childish | medium | medium | distinct adult tokens/content/layout configuration |
| Clinical workflow mismatch | medium | high | specialist co-design before full dashboard |
| Vendor lock-in | medium | medium | provider adapters + open data contracts |
| Offline sync conflicts | medium | medium | event IDs, idempotent APIs, conflict policy |

## 9. Future research roadmap

### Research track A — DLD

- validate digital vocabulary/grammar/narrative tasks;
- measure generalization to classroom/home outcomes;
- expand adolescent/adult modules;
- study multilingual support.

### Research track B — Dyslexia

- validate skill progression against established literacy measures;
- study transfer to connected-text reading and comprehension;
- evaluate assistive technology + instruction combinations.

### Research track C — Speech

- build representative child speech evaluation sets;
- stratify by age, language, dialect and speech profile;
- compare local vs cloud ASR;
- measure false correction rates.

### Research track D — AI

- compare rule-based vs ML personalization;
- audit subgroup fairness;
- study explanations and user trust;
- measure whether AI improves efficiency without reducing human oversight.

## 10. Product maturity path

### Version 0.1 — Learning support prototype

No clinical claims. Core DLD + literacy activities.

### Version 0.5 — Pilot

Progress, parent/teacher, accessibility, limited speech.

### Version 1.0 — Evidence-informed public release

Privacy/security hardening, stable curriculum, validated non-diagnostic metrics, professional collaboration.

### Version 2.x — Research/partnership platform

Consented research mode, richer specialist workflow, multilingual, better speech analysis, formal validation studies.

## 11. Definition of done for a feature

A feature is complete only when:

- evidence basis or explicit product rationale is recorded;
- content has provenance/license metadata;
- age adaptation is defined;
- accessibility states exist;
- privacy implications are documented;
- error/empty/loading states are defined;
- tests exist;
- analytics events are named;
- human override exists where recommendations are involved.

## 12. Final product vision

```text
User
  ↓
Age + Profile
  ↓
Optional Screening Support
  ↓
Language / Literacy Skill Profile
  ↓
Personalized Learning Path
  ↓
Interactive Practice
  ↓
AI-Assisted Adaptation (where it adds value)
  ↓
Progress
  ↓
Parent / Teacher / Specialist Collaboration
  ↓
Long-Term Improvement Tracking
```

The system should feel like one coherent product across the lifespan, while adapting its content, UI and learning strategy to children, teenagers and adults. The platform should make professional support easier to extend—not easier to replace.

## 13. Immediate next development phase

The next engineering phase after approval of these documents should be **Phase 2: Design System + UI/UX**, followed by a content/skill schema workshop before writing production Flutter code.
