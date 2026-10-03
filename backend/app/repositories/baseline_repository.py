from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.baseline import BaselineSession, BaselineActivity, BaselineResponse
from app.models.skill_assessment import SkillAssessment


class BaselineRepository:
    @staticmethod
    def get_session_by_id(db: Session, session_id: str) -> Optional[BaselineSession]:
        return db.query(BaselineSession).filter(BaselineSession.id == session_id).first()

    @staticmethod
    def get_active_session_for_user(db: Session, user_id: str) -> Optional[BaselineSession]:
        return (
            db.query(BaselineSession)
            .filter(
                BaselineSession.user_id == user_id,
                BaselineSession.status == "in_progress",
            )
            .order_by(BaselineSession.started_at.desc())
            .first()
        )

    @staticmethod
    def create_session(
        db: Session,
        user_id: str,
        track: str,
        total_activities: int = 6,
    ) -> BaselineSession:
        session = BaselineSession(
            user_id=user_id,
            track=track,
            status="in_progress",
            total_activities=total_activities,
            completed_activities=0,
            started_at=datetime.now(timezone.utc),
        )
        db.add(session)
        db.commit()
        db.refresh(session)
        return session

    @staticmethod
    def get_activities_for_session(
        db: Session,
        track: str,
        age_band: str,
        limit: int = 6,
    ) -> List[BaselineActivity]:
        query = db.query(BaselineActivity).filter(BaselineActivity.active == True)
        if track != "both_track":
            query = query.filter((BaselineActivity.track == track) | (BaselineActivity.track == "both_track"))

        # Age band filtering: matches specific age or 'all'
        age_matched = (
            query.filter((BaselineActivity.age_band == age_band) | (BaselineActivity.age_band == "all"))
            .order_by(BaselineActivity.difficulty, BaselineActivity.id)
            .all()
        )

        if len(age_matched) >= limit:
            return age_matched[:limit]

        # If matching count is under limit, supplement with other activities from track
        seen_ids = {a.id for a in age_matched}
        all_track_acts = query.order_by(BaselineActivity.difficulty, BaselineActivity.id).all()
        for a in all_track_acts:
            if a.id not in seen_ids:
                age_matched.append(a)
                seen_ids.add(a.id)
            if len(age_matched) >= limit:
                break

        return age_matched[:limit]

    @staticmethod
    def get_activity_by_id(db: Session, activity_id: str) -> Optional[BaselineActivity]:
        return db.query(BaselineActivity).filter(BaselineActivity.id == activity_id).first()

    @staticmethod
    def create_response(
        db: Session,
        session_id: str,
        user_id: str,
        activity_id: str,
        skill_id: str,
        selected_option: str,
        is_correct: bool,
        time_taken_ms: int = 0,
    ) -> BaselineResponse:
        response = BaselineResponse(
            session_id=session_id,
            user_id=user_id,
            activity_id=activity_id,
            skill_id=skill_id,
            selected_option=selected_option,
            is_correct=is_correct,
            time_taken_ms=time_taken_ms,
        )
        db.add(response)
        db.commit()
        db.refresh(response)
        return response

    @staticmethod
    def get_responses_for_session(db: Session, session_id: str) -> List[BaselineResponse]:
        return (
            db.query(BaselineResponse)
            .filter(BaselineResponse.session_id == session_id)
            .order_by(BaselineResponse.created_at.asc())
            .all()
        )

    @staticmethod
    def create_or_update_assessment(
        db: Session,
        user_id: str,
        skill_id: str,
        session_id: Optional[str],
        assessment_type: str,
        score: float,
        accuracy: float,
        attempt_count: int,
        duration_seconds: int,
        band: str,
        notes: Optional[str] = None,
    ) -> SkillAssessment:
        assessment = SkillAssessment(
            user_id=user_id,
            skill_id=skill_id,
            session_id=session_id,
            assessment_type=assessment_type,
            score=score,
            accuracy=accuracy,
            attempt_count=attempt_count,
            duration_seconds=duration_seconds,
            band=band,
            notes=notes,
        )
        db.add(assessment)
        db.commit()
        db.refresh(assessment)
        return assessment

    @staticmethod
    def get_assessments_for_user(db: Session, user_id: str) -> List[SkillAssessment]:
        return (
            db.query(SkillAssessment)
            .filter(SkillAssessment.user_id == user_id)
            .order_by(SkillAssessment.created_at.desc())
            .all()
        )
