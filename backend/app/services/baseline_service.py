from datetime import datetime, timezone
from typing import Dict, List
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import log_security_event
from app.models.user import User
from app.models.skill import Skill
from app.models.baseline import BaselineSession
from app.repositories.baseline_repository import BaselineRepository
from app.repositories.skill_repository import SkillRepository
from app.schemas.baseline import (
    BaselineSessionResponse,
    BaselineActivityResponse,
    BaselineResponseRequest,
    BaselineResponseResult,
    SkillSnapshotResponse,
    SkillSnapshotItem,
)


class BaselineService:
    @staticmethod
    def get_or_create_session(db: Session, user: User) -> BaselineSessionResponse:
        """
        Retrieves an active baseline session or creates a new deterministic baseline session
        tailored to the learner's age band and active support track.
        """
        session = BaselineRepository.get_active_session_for_user(db, user.id)

        track = user.profile.support_focus if user.profile else "dld_track"
        age_band = user.profile.age_band if user.profile else "teen"

        if not session:
            # Query deterministic baseline activities for track & age
            activities = BaselineRepository.get_activities_for_session(
                db=db,
                track=track,
                age_band=age_band,
                limit=6,
            )
            total = len(activities) if activities else 6
            session = BaselineRepository.create_session(
                db=db,
                user_id=user.id,
                track=track,
                total_activities=total,
            )
            if user.profile and user.profile.baseline_status == "not_started":
                user.profile.baseline_status = "in_progress"
                db.add(user.profile)
                db.commit()

            log_security_event("baseline_session_started", user_id=user.id, details=f"session_id={session.id} track={track}")
        else:
            limit = session.total_activities if session.total_activities > 0 else 6
            activities = BaselineRepository.get_activities_for_session(
                db=db,
                track=session.track,
                age_band=age_band,
                limit=limit,
            )
            if session.total_activities != len(activities) and activities:
                session.total_activities = len(activities)
                db.commit()

        act_responses = [
            BaselineActivityResponse(
                id=a.id,
                skill_id=a.skill_id,
                track=a.track,
                domain=a.domain,
                age_band=a.age_band,
                activity_type=a.activity_type,
                instruction=a.instruction,
                prompt=a.prompt,
                options=a.options_json,
                hint=a.hint,
                difficulty=a.difficulty,
            )
            for a in activities
        ]

        return BaselineSessionResponse(
            id=session.id,
            user_id=session.user_id,
            track=session.track,
            status=session.status,
            total_activities=session.total_activities,
            completed_activities=session.completed_activities,
            started_at=session.started_at,
            completed_at=session.completed_at,
            activities=act_responses,
        )

    @staticmethod
    def get_session(db: Session, session_id: str, user: User) -> BaselineSessionResponse:
        session = BaselineRepository.get_session_by_id(db, session_id)
        if not session:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Baseline session not found.")

        # Data ownership verification
        if session.user_id != user.id:
            log_security_event("unauthorized_session_access", user_id=user.id, details=f"target_session={session_id}")
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied to this session.")

        age_band = user.profile.age_band if user.profile else "teen"
        limit = session.total_activities if session.total_activities > 0 else 6
        activities = BaselineRepository.get_activities_for_session(
            db=db,
            track=session.track,
            age_band=age_band,
            limit=limit,
        )

        act_responses = [
            BaselineActivityResponse(
                id=a.id,
                skill_id=a.skill_id,
                track=a.track,
                domain=a.domain,
                age_band=a.age_band,
                activity_type=a.activity_type,
                instruction=a.instruction,
                prompt=a.prompt,
                options=a.options_json,
                hint=a.hint,
                difficulty=a.difficulty,
            )
            for a in activities
        ]

        return BaselineSessionResponse(
            id=session.id,
            user_id=session.user_id,
            track=session.track,
            status=session.status,
            total_activities=session.total_activities,
            completed_activities=session.completed_activities,
            started_at=session.started_at,
            completed_at=session.completed_at,
            activities=act_responses,
        )

    @staticmethod
    def record_response(
        db: Session,
        session_id: str,
        user: User,
        request: BaselineResponseRequest,
    ) -> BaselineResponseResult:
        session = BaselineRepository.get_session_by_id(db, session_id)
        if not session:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Baseline session not found.")
        if session.user_id != user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")
        if session.status == "completed":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="This baseline session is already completed.")

        activity = BaselineRepository.get_activity_by_id(db, request.activity_id)
        if not activity:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Activity not found.")

        is_correct = request.selected_option.strip().lower() == activity.correct_answer.strip().lower()

        BaselineRepository.create_response(
            db=db,
            session_id=session.id,
            user_id=user.id,
            activity_id=activity.id,
            skill_id=activity.skill_id,
            selected_option=request.selected_option.strip(),
            is_correct=is_correct,
            time_taken_ms=request.time_taken_ms,
        )

        # Update completed activities count
        responses = BaselineRepository.get_responses_for_session(db, session.id)
        session.completed_activities = len(responses)
        db.add(session)
        db.commit()

        is_complete = session.completed_activities >= session.total_activities

        return BaselineResponseResult(
            activity_id=activity.id,
            is_correct=is_correct,
            correct_answer=activity.correct_answer,
            completed_activities=session.completed_activities,
            total_activities=session.total_activities,
            is_session_complete=is_complete,
        )

    @staticmethod
    def complete_session(db: Session, session_id: str, user: User) -> SkillSnapshotResponse:
        session = BaselineRepository.get_session_by_id(db, session_id)
        if not session:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Baseline session not found.")
        if session.user_id != user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

        responses = BaselineRepository.get_responses_for_session(db, session.id)

        # Group responses by skill to compute non-diagnostic readiness bands
        skill_groups: Dict[str, List[bool]] = {}
        duration_total = 0
        for r in responses:
            skill_groups.setdefault(r.skill_id, []).append(r.is_correct)
            duration_total += int(r.time_taken_ms / 1000)

        snapshot_items = []
        strength_areas = []
        priority_practice_areas = []

        for skill_id, outcomes in skill_groups.items():
            skill = SkillRepository.get_by_id(db, skill_id)
            if not skill:
                continue

            accuracy = sum(1 for o in outcomes if o) / len(outcomes) if outcomes else 0.0

            # Deterministic, non-diagnostic readiness band mapping
            if accuracy >= 0.85:
                band = "Consistent"
                band_desc = "Strong independent skill; ready for diverse applied contexts."
                strength_areas.append(skill.name)
            elif accuracy >= 0.60:
                band = "Practicing"
                band_desc = "Developing solid understanding; benefits from regular varied practice."
                strength_areas.append(skill.name)
            elif accuracy >= 0.40:
                band = "Developing"
                band_desc = "Emerging ability; benefits from structured visual and scaffolded support."
                priority_practice_areas.append(skill.name)
            else:
                band = "Starting"
                band_desc = "Initial practice target; benefits from audio models and explicit cues."
                priority_practice_areas.append(skill.name)

            # Persist historical assessment record
            BaselineRepository.create_or_update_assessment(
                db=db,
                user_id=user.id,
                skill_id=skill.id,
                session_id=session.id,
                assessment_type="baseline",
                score=accuracy,
                accuracy=accuracy,
                attempt_count=len(outcomes),
                duration_seconds=duration_total,
                band=band.lower(),
                notes=band_desc,
            )

            snapshot_items.append(
                SkillSnapshotItem(
                    skill_id=skill.id,
                    skill_code=skill.code,
                    skill_name=skill.name,
                    track=skill.track,
                    domain=skill.domain,
                    band=band,
                    score=accuracy,
                    accuracy=accuracy,
                    description=band_desc,
                )
            )

        # Mark session completed and update profile baseline status
        session.status = "completed"
        session.completed_at = datetime.now(timezone.utc)
        db.add(session)

        if user.profile:
            user.profile.baseline_status = "completed"
            db.add(user.profile)

        db.commit()
        log_security_event("baseline_session_completed", user_id=user.id, details=f"session_id={session.id}")

        return SkillSnapshotResponse(
            user_id=user.id,
            baseline_status="completed",
            completed_at=session.completed_at,
            skills=snapshot_items,
            strength_areas=strength_areas,
            priority_practice_areas=priority_practice_areas,
        )

    @staticmethod
    def get_skill_snapshot(db: Session, user: User) -> SkillSnapshotResponse:
        """
        Retrieves the learner's current Skill Snapshot derived from baseline assessments.
        Adheres to non-diagnostic learning readiness bands.
        """
        assessments = BaselineRepository.get_assessments_for_user(db, user.id)

        # Deduplicate to most recent assessment per skill
        seen_skills = set()
        snapshot_items = []
        strength_areas = []
        priority_practice_areas = []

        completed_at = None

        for a in assessments:
            if a.skill_id in seen_skills:
                continue
            seen_skills.add(a.skill_id)

            skill = SkillRepository.get_by_id(db, a.skill_id)
            if not skill:
                continue

            if completed_at is None and a.created_at:
                completed_at = a.created_at

            band_capitalized = a.band.capitalize()
            if a.band in ("consistent", "practicing"):
                strength_areas.append(skill.name)
            else:
                priority_practice_areas.append(skill.name)

            snapshot_items.append(
                SkillSnapshotItem(
                    skill_id=skill.id,
                    skill_code=skill.code,
                    skill_name=skill.name,
                    track=skill.track,
                    domain=skill.domain,
                    band=band_capitalized,
                    score=a.score,
                    accuracy=a.accuracy,
                    description=a.notes or f"Learning readiness: {band_capitalized}",
                )
            )

        status_str = user.profile.baseline_status if user.profile else "not_started"

        return SkillSnapshotResponse(
            user_id=user.id,
            baseline_status=status_str,
            completed_at=completed_at,
            skills=snapshot_items,
            strength_areas=strength_areas,
            priority_practice_areas=priority_practice_areas,
        )
