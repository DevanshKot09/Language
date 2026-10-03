from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict
from app.schemas.goal import GoalResponse
from app.schemas.achievement import AchievementResponse


class SkillProgressResponse(BaseModel):
    skill_id: str
    skill_code: str
    name: str
    domain: str
    track: str  # dld_track, dyslexia_track
    baseline_band: Optional[str] = None  # starting, developing, practicing, consistent
    current_band: str  # starting, developing, practicing, consistent
    attempt_count: int
    lesson_completed_count: int
    accuracy: float
    last_practiced_at: Optional[datetime] = None
    priority: str = "ESSENTIAL"

    model_config = ConfigDict(from_attributes=True)


class ActivityTimelineItem(BaseModel):
    id: str
    event_type: str  # baseline_completed, lesson_started, lesson_completed, goal_created, goal_completed, achievement_earned
    title: str
    description: str
    timestamp: datetime
    track: Optional[str] = None
    badge_icon: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class WeeklyActivityDay(BaseModel):
    day_name: str
    date: str
    activity_count: int
    practice_minutes: int


class ProgressTrend(BaseModel):
    days: List[WeeklyActivityDay]
    accessible_description: str


class TrackProgressSummary(BaseModel):
    track: str
    track_name: str
    completed_lessons: int
    total_lessons: int
    practiced_skills: int
    total_skills: int
    average_accuracy: float


class ProgressSummary(BaseModel):
    total_lessons_completed: int
    total_lessons_in_progress: int
    total_exercises_attempted: int
    total_practice_time_minutes: int
    independent_rate: float
    consistency_streak_days: int
    active_goals_count: int
    completed_goals_count: int
    achievements_count: int


class ProgressDashboardResponse(BaseModel):
    summary: ProgressSummary
    active_track: str
    dld_track_summary: Optional[TrackProgressSummary] = None
    dyslexia_track_summary: Optional[TrackProgressSummary] = None
    skills: List[SkillProgressResponse]
    dld_skills: List[SkillProgressResponse]
    dyslexia_skills: List[SkillProgressResponse]
    active_goals: List[GoalResponse]
    recent_achievements: List[AchievementResponse]
    timeline: List[ActivityTimelineItem]
    trend: ProgressTrend
    ai_insight_summary: Optional[str] = None
    ai_insight_details: Optional[List[str]] = None
    ai_fallback_used: bool = False

    model_config = ConfigDict(from_attributes=True)
