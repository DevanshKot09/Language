from typing import List, Optional
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from app.models.goal import LearnerGoal


class GoalRepository:
    @staticmethod
    def get_goals_by_user(
        db: Session,
        user_id: str,
        status: Optional[str] = None,
    ) -> List[LearnerGoal]:
        query = db.query(LearnerGoal).filter(LearnerGoal.user_id == user_id)
        if status:
            if status in ("completed", "achieved"):
                query = query.filter(LearnerGoal.status.in_(["completed", "achieved"]))
            else:
                query = query.filter(LearnerGoal.status == status)
        return query.order_by(LearnerGoal.created_at.desc()).all()

    @staticmethod
    def get_goal_by_id(db: Session, goal_id: str, user_id: str) -> Optional[LearnerGoal]:
        return (
            db.query(LearnerGoal)
            .filter(LearnerGoal.id == goal_id, LearnerGoal.user_id == user_id)
            .first()
        )

    @staticmethod
    def create_goal(
        db: Session,
        user_id: str,
        title: str,
        skill_id: Optional[str] = None,
        description: Optional[str] = None,
        goal_type: str = "complete_lessons",
        target_count: int = 3,
        target_frequency: str = "weekly",
        target_behavior: Optional[str] = None,
    ) -> LearnerGoal:
        goal = LearnerGoal(
            user_id=user_id,
            skill_id=skill_id,
            title=title,
            description=description,
            goal_type=goal_type,
            target_count=target_count,
            current_count=0,
            target_frequency=target_frequency,
            target_behavior=target_behavior,
            status="active",
        )
        db.add(goal)
        db.commit()
        db.refresh(goal)
        return goal

    @staticmethod
    def update_goal(
        db: Session,
        goal_id: str,
        user_id: str,
        title: Optional[str] = None,
        description: Optional[str] = None,
        target_count: Optional[int] = None,
        target_frequency: Optional[str] = None,
        target_behavior: Optional[str] = None,
        status: Optional[str] = None,
    ) -> Optional[LearnerGoal]:
        goal = GoalRepository.get_goal_by_id(db, goal_id, user_id)
        if not goal:
            return None

        if title is not None:
            goal.title = title
        if description is not None:
            goal.description = description
        if target_count is not None:
            goal.target_count = target_count
        if target_frequency is not None:
            goal.target_frequency = target_frequency
        if target_behavior is not None:
            goal.target_behavior = target_behavior
        if status is not None:
            goal.status = status
            if status in ("completed", "achieved") and not goal.completed_at:
                goal.completed_at = datetime.now(timezone.utc)
            elif status == "active":
                goal.completed_at = None

        db.commit()
        db.refresh(goal)
        return goal

    @staticmethod
    def delete_goal(db: Session, goal_id: str, user_id: str) -> bool:
        goal = GoalRepository.get_goal_by_id(db, goal_id, user_id)
        if not goal:
            return False
        db.delete(goal)
        db.commit()
        return True

    @staticmethod
    def increment_goals_for_event(
        db: Session,
        user_id: str,
        event_type: str,  # 'lesson_completed', 'exercise_attempted'
        skill_id: Optional[str] = None,
    ) -> List[LearnerGoal]:
        """
        Deterministically updates active goals matching this application event.
        Automatically marks completed when target_count is reached.
        """
        active_goals = (
            db.query(LearnerGoal)
            .filter(LearnerGoal.user_id == user_id, LearnerGoal.status == "active")
            .all()
        )

        completed_goals = []
        for goal in active_goals:
            should_increment = False

            if event_type == "lesson_completed":
                if goal.goal_type == "complete_lessons":
                    if goal.skill_id is None or goal.skill_id == skill_id:
                        should_increment = True
                elif goal.goal_type == "practice_sessions":
                    should_increment = True
                elif goal.goal_type == "practice_skill" and goal.skill_id == skill_id:
                    should_increment = True

            elif event_type == "exercise_attempted":
                if goal.goal_type == "practice_skill" and goal.skill_id == skill_id:
                    should_increment = True

            if should_increment:
                goal.current_count += 1
                if goal.current_count >= goal.target_count:
                    goal.status = "completed"
                    goal.completed_at = datetime.now(timezone.utc)
                    completed_goals.append(goal)

        if active_goals:
            db.commit()

        return completed_goals
