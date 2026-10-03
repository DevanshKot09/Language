from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine, Base, SessionLocal
from app.core.seeds import seed_skills_and_activities
from app.models import User, Profile, AccessibilityPreferences, OnboardingState  # noqa: F401
from app.api.v1.router import api_v1_router
from app.core.middleware import (
    SecurityHeadersMiddleware,
    RequestSizeLimitMiddleware,
    RateLimitMiddleware,
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure database tables exist in non-test environments
    if settings.ENVIRONMENT != "test":
        Base.metadata.create_all(bind=engine)
        db = SessionLocal()
        try:
            from app.models.skill import Skill
            if db.query(Skill).first() is None:
                seed_skills_and_activities(db)
        finally:
            db.close()
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    description=settings.PROJECT_DESCRIPTION,
    version=settings.VERSION,
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

# 1. Security Headers (OWASP baseline)
app.add_middleware(SecurityHeadersMiddleware)

# 2. Request Payload Size Guard (5 MB max)
app.add_middleware(RequestSizeLimitMiddleware)

# 3. Sliding Window Rate Limiter
app.add_middleware(RateLimitMiddleware)

# 4. CORS Policy
cors_origins = (
    ["*"]
    if settings.ALLOWED_ORIGINS.strip() == "*"
    else [origin.strip() for origin in settings.ALLOWED_ORIGINS.split(",") if origin.strip()]
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health", tags=["Root Health"])
async def root_health_check():
    """Root health check for infrastructure monitors and load balancers."""
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "boundary": "Screening & Practice Support • Non-Diagnostic",
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
    }

# Register Versioned API Routes
app.include_router(api_v1_router, prefix=settings.API_V1_STR)
