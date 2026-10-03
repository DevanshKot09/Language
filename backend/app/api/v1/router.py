from fastapi import APIRouter
from app.api.v1.endpoints import (
    health,
    auth,
    profile,
    skills,
    baseline,
    learner,
    learning,
    ai,
    progress,
    goals,
    achievements,
    collaboration,
    parent,
    teacher,
    specialist,
    reports,
)

api_v1_router = APIRouter()
api_v1_router.include_router(health.router, tags=["Health"])
api_v1_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_v1_router.include_router(profile.router, prefix="/profile", tags=["Profile & Preferences"])
api_v1_router.include_router(skills.router, prefix="/skills", tags=["Skills Taxonomy"])
api_v1_router.include_router(baseline.router, prefix="/baseline", tags=["Skill Baseline"])
api_v1_router.include_router(learner.router, prefix="/learner", tags=["Learner Profile & Goals"])
api_v1_router.include_router(learning.router, prefix="", tags=["Learning Engine & Practice"])
api_v1_router.include_router(ai.router, prefix="/ai", tags=["AI Assistance & Personalization"])
api_v1_router.include_router(progress.router, prefix="/progress", tags=["Progress & Analytics"])
api_v1_router.include_router(goals.router, prefix="/goals", tags=["Learner Goals"])
api_v1_router.include_router(achievements.router, prefix="/achievements", tags=["Achievements & Milestones"])
api_v1_router.include_router(collaboration.router, prefix="/relationships", tags=["Relationships & Collaboration"])
api_v1_router.include_router(parent.router, prefix="/parent", tags=["Parent / Caregiver Workspace"])
api_v1_router.include_router(teacher.router, prefix="/teacher", tags=["Teacher / Educator Workspace"])
api_v1_router.include_router(specialist.router, prefix="/specialist", tags=["Specialist Caseload & Oversight"])
api_v1_router.include_router(reports.router, prefix="/reports", tags=["Learning Support Reports"])

