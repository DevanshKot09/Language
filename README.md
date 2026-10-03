# LINGUA AI 🗣️📚

**LINGUA AI** is an evidence-informed speech, language, and literacy support platform designed to assist individuals with Developmental Language Disorder (DLD) and Dyslexia through personalized screening support, adaptive learning pathways, real-time speech evaluation, and multi-stakeholder collaboration (Learners, Parents, Educators, and Specialists).

> **Non-Diagnostic Notice:** LINGUA AI is an evidence-informed educational and screening support tool. It provides practice, monitoring, and educational interventions and does not replace medical or clinical diagnoses.

---

## 🌟 Key Features

- **Personalized Learning Tracks:**
  - **DLD Track:** Vocabulary breadth, syntax, sentence formulation, morphology, and narrative sequencing.
  - **Dyslexia Track:** Phonological awareness, decoding, orthographic mapping, and structured reading passages.
- **Multimodal AI & Speech Engine:** Interactive pronunciation assessment, speech feedback, and contextual hints powered by Gemini AI and audio streaming.
- **Collaborative Ecosystem:** Role-based dashboards for Learners, Parents, Teachers, and Speech-Language Specialists.
- **Evidence-Based Baseline Screening:** Age-adaptive questionnaires and skill snapshots without clinical labeling.
- **Gamified Progress & Goals:** Real-time analytics, skill mastery tracking, milestones, and achievements.

---

## 🏗️ Project Architecture

```
Lingual AI/
├── backend/                  # FastAPI Python backend
│   ├── app/
│   │   ├── ai/               # Gemini AI engine and speech processing
│   │   ├── api/              # RESTful API endpoints (v1)
│   │   ├── core/             # Configuration, security, database settings
│   │   ├── models/           # SQLAlchemy database models
│   │   ├── repositories/     # Data access layer
│   │   ├── schemas/          # Pydantic data schemas
│   │   └── services/         # Business logic services
│   ├── alembic/              # Database migrations
│   └── tests/                # Unit and integration test suites
│
├── mobile/                   # Flutter cross-platform mobile application
│   ├── lib/
│   │   ├── app/              # Router, state management, providers
│   │   ├── core/             # Design system, widgets, network clients
│   │   ├── features/         # Authentication, learning, collaboration, speech
│   │   └── shared/           # Models, tokens, themes
│   └── test/                 # Flutter unit and widget tests
│
├── shared/                   # Common taxonomy, design tokens, schemas
│   ├── architecture/         # Skill taxonomy and safety boundaries
│   ├── design_tokens/        # Design system design tokens
│   └── schemas/              # JSON schemas
│
└── brain/                    # Research documentation & technical specifications
```

---

## 🚀 Getting Started

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create and activate a Python virtual environment:
   ```bash
   python -m venv .venv
   # Windows:
   .venv\Scripts\activate
   # macOS/Linux:
   source .venv/bin/activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure environment variables:
   ```bash
   cp .env.example .env
   # Add your GEMINI_API_KEY and other configuration keys
   ```

5. Run database migrations:
   ```bash
   alembic upgrade head
   ```

6. Start the development server:
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```

---

### Mobile App Setup

1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation (if needed):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Start the application:
   ```bash
   flutter run
   ```

---

## 🔒 Security & Privacy

- All environment variables and sensitive keys (`.env`, service account credentials, private configs) are strictly ignored in `.gitignore`.
- Role-based access control (RBAC) and OAuth 2.0 / JWT token authentication.
- Privacy-first voice and audio data handling.

---

## 📄 License

This project is licensed under the MIT License.
