from fastapi import APIRouter
from app.api.v1.endpoints import (
    health,
    auth,
    profile,
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
api_v1_router.include_router(collaboration.router, prefix="/relationships", tags=["Relationships & Collaboration"])
api_v1_router.include_router(parent.router, prefix="/parent", tags=["Parent / Caregiver Workspace"])
api_v1_router.include_router(teacher.router, prefix="/teacher", tags=["Teacher / Educator Workspace"])
api_v1_router.include_router(specialist.router, prefix="/specialist", tags=["Specialist Caseload & Oversight"])
api_v1_router.include_router(reports.router, prefix="/reports", tags=["Learning Support Reports"])

