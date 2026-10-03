# 03_UI_UX_AND_DESIGN_SYSTEM

## LINGUA AI — UI/UX architecture and Stitch-ready screen specification

## 1. UX principles

1. **Support, do not label.** Interface copy should emphasize skills and progress, not deficit labels.
2. **One platform, adaptive shell.** Child, teen and adult modes share components and logic but change presentation/configuration.
3. **Accessible by default.** Text, audio, spacing, contrast, input, motion and focus are first-class settings.
4. **Warm, not clinical.** Avoid hospital-like green/blue dashboards, excessive medical icons, or diagnostic-looking scorecards.
5. **Feedback is actionable.** Every error gives a next step, not a failure statement.
6. **Privacy is visible.** Recording, sharing and relationship permissions must be understandable.
7. **Progress is multi-dimensional.** Show skill trends, not a single "brain" or "language IQ" meter.

## 2. Visual identity

### Color palette

| Token | Suggested value | Use |
|---|---|---|
| `ink-900` | #18202A | primary text |
| `ink-700` | #45515E | secondary text |
| `paper-50` | #F8FAFC | app background |
| `paper-100` | #F1F5F9 | surfaces |
| `primary-600` | #5B5BD6 | primary action |
| `primary-100` | #E9E9FF | soft action background |
| `accent-500` | #F59E7A | warm attention/reward |
| `success-600` | #2F8F6B | success |
| `warning-600` | #B7791F | warning |
| `danger-600` | #B94A59 | error / destructive |

These are starting design tokens, not clinical standards. Contrast ratios must be checked for every text/background pair against WCAG 2.2 AA targets.

### Typography

Primary: **Atkinson Hyperlegible** or another accessibility-tested sans-serif with a complete script set for launch languages.

Secondary UI fallback: system sans-serif.

Recommended scale:

- Display: 36/44
- H1: 30/38
- H2: 24/32
- H3: 20/28
- Body large: 18/27
- Body: 16/24
- Body small: 14/21
- Caption: 12/18

Never bake text into images.

### Spacing

Use a 4 px base scale. Common spacing: 4, 8, 12, 16, 20, 24, 32, 40, 48.

### Radius

- Small control: 10 px
- Standard card/input: 14 px
- Hero panel: 20 px
- Pill/badge: 999 px

### Elevation

Use restrained elevation. Prefer surface contrast and borders over large shadows.

## 3. Component system

### Buttons

Primary, secondary, tertiary, destructive, icon-button.

Minimum touch target: 44×44 CSS/device-independent pixels, with larger targets in child mode.

### Cards

`SkillCard`, `LessonCard`, `ProgressCard`, `RecommendationCard`, `GoalCard`, `RecordCard`, `ConsentCard`.

### Inputs

`TextField`, `AgeSelector`, `RoleSelector`, `SearchField`, `MicInput`, `UploadDropzone`.

### Progress indicators

Use:

- skill progress bars;
- small trend sparklines;
- session completion steps;
- mastery bands with descriptive labels.

Avoid gauge-style clinical severity meters.

### Feedback components

`TryAgain`, `Hint`, `Explain`, `ListenAgain`, `SeeExample`, `NeedHelp`.

Error language examples:

- Instead of: "Wrong."
- Use: "Not yet. Listen once more, then try again."

## 4. Navigation

### Mobile learner

Bottom navigation (4–5 items):

**Home | Learn | Progress | Goals | Profile**

Contextual lesson navigation appears inside the Learn flow.

### Mobile parent/teacher/specialist

**Overview | Learners | Plans | Reports | Profile**

### Web

Use a left navigation rail/sidebar with role-aware navigation. Desktop should use multi-column dashboards, tables, filters and charts; it should not simply stretch the mobile card stack.

## 5. Complete screen inventory

| ID | Screen | Primary role | Purpose |
|---|---|---|---|
| UX-01 | WELCOME | all | explain product purpose and safety boundary |
| UX-02 | ONBOARDING | all | first-time setup |
| UX-03 | LOGIN | all | authentication |
| UX-04 | SIGNUP | all | account creation |
| UX-05 | ROLE SELECTION | all | learner/parent/teacher/specialist role |
| UX-06 | AGE SELECTION | learner | choose age band/configuration |
| UX-07 | PROFILE | all | personal preferences and profile |
| UX-08 | CONSENT & PRIVACY | parent/specialist/learner | consent, sharing and data choices |
| UX-09 | SCREENING INTRO | learner/support adult | explain screening support is not diagnosis |
| UX-10 | SCREENING SESSION | learner | optional skill assessment |
| UX-11 | SCREENING SUMMARY | adult/specialist | display non-diagnostic indicators |
| UX-12 | LEARNING DASHBOARD | learner | daily learning overview |
| UX-13 | PERSONALIZED PATH | learner | skill sequence |
| UX-14 | VOCABULARY | learner | word-learning practice |
| UX-15 | GRAMMAR | learner | grammar/morphosyntax |
| UX-16 | SENTENCE FORMATION | learner | construct/formulate sentences |
| UX-17 | PHONOLOGICAL AWARENESS | learner | sound manipulation |
| UX-18 | PHONICS | learner | grapheme–phoneme practice |
| UX-19 | WORD RECOGNITION | learner | decoding / sight-word practice |
| UX-20 | READING | learner | connected-text reading |
| UX-21 | READING COMPREHENSION | learner | comprehension practice |
| UX-22 | LISTENING | learner | listening comprehension |
| UX-23 | PRONUNCIATION | learner | target-word/sound practice |
| UX-24 | SPEAKING | learner | structured speaking |
| UX-25 | STORYTELLING | learner | narrative generation/retell |
| UX-26 | SOCIAL COMMUNICATION | learner | targeted pragmatic scenarios |
| UX-27 | AI ASSISTANT | learner/adult | constrained learning helper |
| UX-28 | PROGRESS | learner | skill trends and history |
| UX-29 | ACHIEVEMENTS | learner | non-shaming rewards |
| UX-30 | GOALS | learner | goals and milestones |
| UX-31 | SETTINGS | all | application settings |
| UX-32 | ACCESSIBILITY | all | text/audio/motion/input controls |
| UX-33 | PARENT DASHBOARD | parent | child progress and assignments |
| UX-34 | TEACHER DASHBOARD | teacher | class/student view |
| UX-35 | SPECIALIST DASHBOARD | specialist | professional progress and goals |
| UX-36 | LEARNER DETAIL | adult role | detailed skill profile |
| UX-37 | ASSIGNMENT BUILDER | teacher/specialist | assign skills/tasks |
| UX-38 | GOAL BUILDER | specialist/teacher/parent | define goal |
| UX-39 | REPORTS | adult roles | progress summaries |
| UX-40 | REPORT DETAIL | adult roles | share/export/report view |
| UX-41 | RELATIONSHIPS & PERMISSIONS | adult roles | parent-child/teacher-student/specialist relationships |
| UX-42 | VOICE DATA CENTER | all | recordings/transcripts and delete controls |
| UX-43 | NOTIFICATIONS | all | reminders and updates |
| UX-44 | HELP & SAFETY | all | help, boundaries, escalation |
| UX-45 | OFFLINE SYNC | learner | sync status and retry |
| UX-46 | ERROR RECOVERY | all | reusable error/empty states |

## 6. Major screen specifications

### UX-01 WELCOME
- **Purpose:** communicate what LINGUA AI does and does not do.
- **Target:** all.
- **Main components:** logo, one-sentence value proposition, DLD/dyslexia distinction, privacy link.
- **Primary CTA:** Get started.
- **Secondary CTA:** Learn about safety.
- **Data required:** none.
- **States:** first visit, returning user.
- **Animation:** subtle logo/illustration fade; no auto motion if reduced-motion.
- **Responsive:** centered mobile card; split hero on desktop.
- **Accessibility:** readable hierarchy, keyboard focus order, screen-reader landmarks.
- **Stitch prompt:** "Design a warm, trustworthy accessibility-first onboarding landing screen for LINGUA AI. Avoid hospital aesthetics. Use a calm editorial illustration showing reading, speaking and listening as connected skills. Primary CTA 'Get started'. Secondary link 'How LINGUA AI supports learning'. Include a visible non-diagnostic safety note."

### UX-02 ONBOARDING
- **Purpose:** gather role, age band, language, goals and accessibility preferences.
- **Target:** all.
- **Components:** stepper, simple questions, audio option, progress.
- **Primary CTA:** Continue.
- **Secondary CTA:** Save and finish later.
- **Data:** role, age band, locale, goals, accessibility settings.
- **States:** incomplete, complete, returning.
- **Animation:** horizontal/vertical step transition depending on platform.
- **Responsive:** one question per mobile page; two-column on desktop.
- **Accessibility:** offer "listen to this question" and "skip for now".
- **Stitch prompt:** "Create a 5-step inclusive onboarding flow for a language/literacy support platform, with one question per screen, large controls, audio instructions, clear progress, and a warm non-clinical visual style."

### UX-06 AGE SELECTION
- **Purpose:** set age-adaptive presentation.
- **Target:** learner / parent creating learner.
- **Components:** Child / Teen / Adult cards, explanation of personalization.
- **Primary CTA:** Continue.
- **Secondary CTA:** Why this matters.
- **Accessibility:** text labels not icon-only.
- **Stitch prompt:** "Three age-mode selection cards for Child, Teen, Adult; mature but friendly typography; no cartoon preschool-only treatment; explain that learning content and UI adapt while the same account/system remains." 

### UX-09 SCREENING INTRO
- **Purpose:** explain optional support assessment.
- **Primary CTA:** Start support check.
- **Secondary CTA:** Skip.
- **Critical copy:** "This is a screening/support activity, not a diagnosis. A qualified professional is needed for diagnosis."
- **Stitch prompt:** "Create a trust-forward pre-assessment explanation screen. Use an information card, a simple illustration, clear consent, and strong but calm copy distinguishing screening support from diagnosis."

### UX-12 LEARNING DASHBOARD
- **Purpose:** show what to do today.
- **Components:** next activity, personalized path, progress snapshot, goals, accessibility quick toggle.
- **Primary CTA:** Continue learning.
- **Secondary CTA:** View path.
- **Child:** larger cards + progress character.
- **Teen:** compact stats + challenge card.
- **Adult:** schedule/goal cards + practical task.
- **Stitch prompt:** "Responsive learning dashboard with one clear next action, two supporting skill cards, progress trend, goals and privacy-safe reminders. Adapt visual density by age mode."

### UX-13 PERSONALIZED PATH
- **Purpose:** explain skill sequence.
- **Components:** skill graph/path, current node, locked prerequisite states, why this task.
- **Primary CTA:** Start next.
- **Secondary CTA:** Change goal.
- **Accessibility:** path must also have a list/table alternative.
- **Stitch prompt:** "Create a visually clear learning path with a primary sequence and a list alternative. Show skills such as Vocabulary, Listening, Phonological Awareness, Phonics, Reading Fluency and Comprehension without implying medical severity."

### UX-20 READING
- **Purpose:** accessible connected-text practice.
- **Components:** text surface, mic, play/pause TTS, speed, theme/font, word help, progress.
- **Primary CTA:** Start reading.
- **Secondary CTA:** Listen instead.
- **States:** before start, recording, pause, complete, ASR uncertainty, offline.
- **Animation:** word/line highlight only if enabled.
- **Accessibility:** keyboard support, TTS, spacing, contrast, reduced motion, captions/transcript.
- **Stitch prompt:** "Design an accessible reading-practice screen with large adjustable text, optional per-word highlighting, read-aloud controls, microphone control, word help and a calm progress indicator. Include a visible 'audio is off/on' state and do not show diagnostic labels."

### UX-28 PROGRESS
- **Purpose:** show trends by skill.
- **Components:** skill cards, timeline, independent-vs-prompted trend, goals, notes.
- **Primary CTA:** Continue practice.
- **Secondary CTA:** Share summary.
- **Accessibility:** chart summary as text table/list.
- **Stitch prompt:** "Create a learner progress dashboard using descriptive skill cards, small trend lines and text summaries. Avoid medical gauges or red/green pass-fail severity."

### UX-33 PARENT DASHBOARD
- **Purpose:** practical support for home.
- **Components:** child switcher, weekly summary, assigned home tasks, strengths, privacy/relationship status.
- **Primary CTA:** Open today's activity.
- **Secondary CTA:** View tips.
- **Stitch prompt:** "Parent dashboard for a language/literacy support app. Use simple language, large summaries, child strengths, one recommended home activity, and an obvious privacy/share settings area."

### UX-34 TEACHER DASHBOARD
- **Purpose:** classroom-level overview.
- **Components:** class list, filters by skill, assignment queue, quick observations, alerts for missing work (not deficit labels).
- **Primary CTA:** Assign practice.
- **Secondary CTA:** View learner.
- **Stitch prompt:** "Desktop-first teacher dashboard with roster, skill filters, assignment cards, compact progress trends and clear privacy boundaries. Use educational rather than clinical styling."

### UX-35 SPECIALIST DASHBOARD
- **Purpose:** authorized professional collaboration.
- **Components:** caseload, goals, baseline/current comparison, notes, assigned plan, report generator, audit/consent indicator.
- **Primary CTA:** Review learner.
- **Secondary CTA:** Update plan.
- **Stitch prompt:** "Professional collaboration dashboard for an SLP/learning specialist. Evidence-oriented but not a hospital EHR. Use a clean information hierarchy, skill goal cards, trends, note panels, and consent/share indicators."

### UX-42 VOICE DATA CENTER
- **Purpose:** make audio/transcript retention visible and controllable.
- **Components:** recording list, duration, purpose, retention status, delete button, transcript view, download only if permitted.
- **Primary CTA:** Delete selected data.
- **Secondary CTA:** Learn why voice is collected.
- **Accessibility:** confirm destructive action clearly.
- **Stitch prompt:** "Privacy-first voice data management screen. Use plain language to show why each recording exists, whether it is stored, when it will be deleted, and give one-tap deletion."

## 7. Lesson interaction pattern

1. Preview objective.
2. Teach/model.
3. Guided practice.
4. Independent practice.
5. Feedback/retry.
6. Reflection / confidence (optional).
7. Next-step recommendation.

Keep the interaction loop under 3–7 minutes for child/teen micro-sessions and configurable for adults.

## 8. Gamification system

### Child

- XP for effort/completion.
- badges for milestones.
- collectible visual path elements.
- streaks are optional and forgiving.
- no negative language for missed days.

### Teen

- achievement cards.
- skill milestones.
- challenge modes.
- optional streaks.

### Adult

- progress milestones.
- goal completion.
- competence markers.
- optional challenges.

### No-shame rules

Never subtract XP because of an incorrect answer. Never display another learner's score. Never create a "failure" animation. Retry should always be available.

## 9. Animation system

Animation durations:

- Micro feedback: 120–180 ms
- Page transition: 180–240 ms
- Card expansion: 180–260 ms
- Reward animation: 400–700 ms
- Long decorative motion: avoid by default

Reduced-motion mode should:

- remove confetti/particle effects;
- remove parallax;
- avoid moving text;
- replace bouncing indicators with static state changes;
- keep loading feedback understandable without animation.

## 10. Responsive web behavior

### Desktop ≥1200 px

Three-column opportunities: nav / content / contextual panel. Data tables can appear.

### Tablet 768–1199 px

Two-column layout; contextual panels become drawers.

### Mobile <768 px

One-column, bottom navigation, sticky primary CTA where appropriate.

Never hide critical privacy/accessibility settings only on desktop.

## 11. Accessibility checklist

- WCAG 2.2 AA target on web.
- Full keyboard navigation.
- Visible focus ring.
- Screen-reader labels for icon buttons.
- Alternative to charts.
- Adjustable text size.
- Reflow at high zoom.
- High-contrast theme.
- Reduced motion.
- Audio instructions and visual equivalent.
- Captions/transcripts.
- No color-only status.
- Error messages with recovery instructions.
- Child-sized touch targets.
- Optional switch from speech to touch/text input.
- Clear recording indicators.

Flutter's accessibility guidance recommends first-class accessibility planning and testing with platform screen readers such as TalkBack and VoiceOver. [A2]

## 12. Stitch prompt template

Use this template for each new design screen:

> "Design the [SCREEN NAME] for LINGUA AI, an evidence-informed language and literacy support platform. Target user: [ROLE]. Age mode: [CHILD/TEEN/ADULT]. Primary task: [TASK]. Include [COMPONENTS]. Primary CTA: [CTA]. Secondary CTA: [CTA]. Style: warm, trustworthy, modern, accessible, non-clinical. Do not use hospital dashboard aesthetics. Support WCAG 2.2 AA principles, visible focus, large controls, readable type, alternative text/audio where relevant, and reduced-motion behavior. Show [STATES]. Responsive behavior: [MOBILE/TABLET/DESKTOP]."

## 13. Content tone examples

**Child:** "Let's try this word together."

**Teen:** "Practice the words that slowed you down."

**Adult:** "Choose a reading task for today."

**Parent:** "Here are two simple ways to practice this skill at home."

**Teacher:** "Three learners need a short review of phoneme blending."

**Specialist:** "Current performance is compared with the learner's previous sessions; no diagnostic interpretation is shown here."
