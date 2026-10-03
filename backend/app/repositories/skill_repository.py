from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.skill import Skill


class SkillRepository:
    @staticmethod
    def get_all(
        db: Session,
        track: Optional[str] = None,
        age_band: Optional[str] = None,
    ) -> List[Skill]:
        query = db.query(Skill).filter(Skill.active == True)
        if track:
            if track == "both_track":
                # Both track includes DLD, Dyslexia, and shared skills
                pass
            else:
                query = query.filter((Skill.track == track) | (Skill.track == "both_track"))
        if age_band:
            query = query.filter(
                (Skill.age_band_applicability == "all") | (Skill.age_band_applicability.contains(age_band))
            )
        return query.order_by(Skill.track, Skill.priority, Skill.name).all()

    @staticmethod
    def get_by_id(db: Session, skill_id: str) -> Optional[Skill]:
        return db.query(Skill).filter(Skill.id == skill_id, Skill.active == True).first()

    @staticmethod
    def get_by_code(db: Session, code: str) -> Optional[Skill]:
        return db.query(Skill).filter(Skill.code == code, Skill.active == True).first()
