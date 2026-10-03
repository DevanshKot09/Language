import io
import json
from datetime import datetime, timezone
from typing import Dict, Any, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    HRFlowable,
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

from app.models.user import User
from app.models.profile import Profile
from app.models.collaboration import Report
from app.repositories.collaboration_repository import CollaborationRepository
from app.services.progress_service import ProgressService
from app.services.collaboration_service import CollaborationService
from app.core.security import log_security_event


STANDARD_NON_DIAGNOSTIC_DISCLAIMER = (
    "This report summarizes learning-support activity within LINGUA AI. "
    "It is an educational progress summary and is not a medical diagnosis, "
    "clinical evaluation, disorder severity rating, or substitute for professional assessment."
)

BANNED_CLINICAL_TERMS = [
    "dld severity",
    "dyslexia severity",
    "dld score",
    "dyslexia score",
    "clinical diagnosis",
    "medical prognosis",
    "disorder level",
    "treatment plan",
]


class ReportService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = CollaborationRepository(db)
        self.collab_service = CollaborationService(db)

    def generate_report(
        self,
        creator: User,
        learner_id: str,
        report_type: str,
        title: Optional[str] = None,
    ) -> Report:
        """
        Creates a structured, factual learning support report.
        Requires active relationship and report generation permission.
        """
        # Validate scope
        scope_needed = "generate_support_report" if creator.role == "specialist" else "generate_report"
        self.collab_service.verify_relationship_access(creator, learner_id, required_scope=scope_needed)

        learner = self.db.query(User).filter(User.id == learner_id).first()
        if not learner:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Learner not found.")

        profile = learner.profile
        learner_name = profile.display_name if profile else "Learner"

        # Deterministic progress snapshot from database
        progress_snapshot = ProgressService.get_progress_dashboard(self.db, learner, include_ai_insight=False)

        default_title = f"{learner_name} — Learning Support Summary"
        if report_type == "parent_summary":
            default_title = f"{learner_name} — Family Practice Summary"
        elif report_type == "teacher_summary":
            default_title = f"{learner_name} — Classroom Learning Summary"
        elif report_type == "specialist_summary":
            default_title = f"{learner_name} — Specialist Learning Support Review"

        summary_payload = {
            "learner_id": learner.id,
            "learner_name": learner_name,
            "age_band": profile.age_band if profile else "teen",
            "support_focus": profile.support_focus if profile else "dld_track",
            "baseline_status": profile.baseline_status if profile else "not_started",
            "metrics": {
                "total_lessons_completed": progress_snapshot.summary.total_lessons_completed,
                "total_exercises_attempted": progress_snapshot.summary.total_exercises_attempted,
                "total_practice_time_minutes": progress_snapshot.summary.total_practice_time_minutes,
                "independent_rate": progress_snapshot.summary.independent_rate,
                "active_goals_count": progress_snapshot.summary.active_goals_count,
                "completed_goals_count": progress_snapshot.summary.completed_goals_count,
                "achievements_count": progress_snapshot.summary.achievements_count,
            },
            "skills": [
                {
                    "name": s.name,
                    "track": s.track,
                    "band": s.current_band,
                    "attempts": s.attempt_count,
                    "rate": s.accuracy,
                }
                for s in progress_snapshot.skills
            ],
            "active_goals": [g.title for g in progress_snapshot.active_goals if g.status == "active"],
            "completed_goals": [g.title for g in progress_snapshot.active_goals if g.status in ["completed", "achieved"]],
            "achievements": [a.title for a in progress_snapshot.recent_achievements if a.is_unlocked],
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

        report = self.repo.create_report(
            creator_id=creator.id,
            learner_id=learner_id,
            report_type=report_type,
            title=title or default_title,
            summary_data=summary_payload,
            disclaimer=STANDARD_NON_DIAGNOSTIC_DISCLAIMER,
        )

        log_security_event(
            "report_generated",
            user_id=creator.id,
            details=f"report_id={report.id} learner={learner_id} type={report_type}",
        )
        return report

    def get_report(self, report_id: str, requesting_user: User) -> Report:
        report = self.repo.get_report(report_id)
        if not report:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found.")

        # Access check: if not the learner themself, caller must have an active relationship
        if report.learner_id != requesting_user.id:
            self.collab_service.verify_relationship_access(requesting_user, report.learner_id)

        self.repo.log_access_event(
            user_id=requesting_user.id,
            action="report_accessed",
            resource_type="report",
            resource_id=report.id,
            target_user_id=report.learner_id,
            details=f"type={report.report_type}",
        )
        return report

    def render_pdf(self, report: Report, requesting_user: User) -> bytes:
        """
        Renders accessible, non-diagnostic PDF document bytes using ReportLab.
        """
        # Enforce access
        self.get_report(report.id, requesting_user)

        data = json.loads(report.summary_data)
        metrics = data.get("metrics", {})
        skills = data.get("skills", [])
        active_goals = data.get("active_goals", [])
        achievements = data.get("achievements", [])

        # Safety verification: ensure text does not contain banned clinical terms
        raw_text = f"{report.title} {report.summary_data}".lower()
        for term in BANNED_CLINICAL_TERMS:
            if term in raw_text:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Report content safety check failed: prohibited term '{term}' detected.",
                )

        buf = io.BytesIO()
        doc = SimpleDocTemplate(
            buf,
            pagesize=letter,
            rightMargin=36,
            leftMargin=36,
            topMargin=36,
            bottomMargin=36,
        )

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            "DocTitle",
            parent=styles["Heading1"],
            fontSize=20,
            leading=24,
            textColor=colors.HexColor("#0D9488"),  # Lingua Teal Primary
        )
        subtitle_style = ParagraphStyle(
            "DocSubTitle",
            parent=styles["Normal"],
            fontSize=11,
            leading=15,
            textColor=colors.HexColor("#475569"),
        )
        h2_style = ParagraphStyle(
            "SectionH2",
            parent=styles["Heading2"],
            fontSize=14,
            leading=18,
            textColor=colors.HexColor("#0F172A"),
            spaceBefore=12,
            spaceAfter=6,
        )
        body_style = ParagraphStyle(
            "Body",
            parent=styles["Normal"],
            fontSize=10,
            leading=14,
            textColor=colors.HexColor("#1E293B"),
        )
        disclaimer_style = ParagraphStyle(
            "Disclaimer",
            parent=styles["Normal"],
            fontSize=9,
            leading=12,
            textColor=colors.HexColor("#64748B"),
        )

        story = []

        # Header
        story.append(Paragraph("LINGUA AI — Learning Support Summary", title_style))
        story.append(Paragraph(f"Report: {report.title}", subtitle_style))
        created_str = report.created_at.strftime("%B %d, %Y") if report.created_at else "Recent"
        story.append(Paragraph(f"Date: {created_str} | Perspective: {report.report_type.replace('_', ' ').title()}", subtitle_style))
        story.append(Spacer(1, 10))
        story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#CBD5E1"), spaceAfter=12))

        # Learner Profile Metadata Table
        story.append(Paragraph("Learner Profile Overview", h2_style))
        profile_data = [
            ["Learner Name:", data.get("learner_name", "Learner"), "Age Band:", data.get("age_band", "teen").title()],
            ["Support Track:", data.get("support_focus", "").replace("_", " ").title(), "Baseline Status:", data.get("baseline_status", "").replace("_", " ").title()],
        ]
        profile_table = Table(profile_data, colWidths=[110, 160, 110, 160])
        profile_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F8FAFC")),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.HexColor("#1E293B")),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTNAME', (2, 0), (2, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
            ('TOPPADDING', (0, 0), (-1, -1), 5),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ]))
        story.append(profile_table)
        story.append(Spacer(1, 12))

        # Learning Activity Summary Table
        story.append(Paragraph("Observable Learning Activity", h2_style))
        metrics_data = [
            ["Lessons Completed", "Exercises Attempted", "Practice Minutes", "Independent Rate"],
            [
                str(metrics.get("total_lessons_completed", 0)),
                str(metrics.get("total_exercises_attempted", 0)),
                f"{metrics.get('total_practice_time_minutes', 0)} min",
                f"{metrics.get('independent_rate', 0.0):.1f}%",
            ],
        ]
        metrics_table = Table(metrics_data, colWidths=[135, 135, 135, 135])
        metrics_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0D9488")),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E1")),
        ]))
        story.append(metrics_table)
        story.append(Spacer(1, 14))

        # Skill Readiness Bands
        if skills:
            story.append(Paragraph("Curriculum Skill Progress (Descriptive Readiness Bands)", h2_style))
            skill_rows = [["Skill Domain", "Track", "Readiness Band", "Practice Attempts", "Accuracy"]]
            for s in skills[:8]:
                skill_rows.append([
                    s.get("name", ""),
                    s.get("track", "").title(),
                    s.get("band", "").title(),
                    str(s.get("attempts", 0)),
                    f"{s.get('rate', 0.0):.0f}%",
                ])
            skill_table = Table(skill_rows, colWidths=[160, 95, 115, 100, 70])
            skill_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0284C7")),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, -1), 9),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
                ('TOPPADDING', (0, 0), (-1, -1), 4),
                ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
            ]))
            story.append(skill_table)
            story.append(Spacer(1, 14))

        # Goals & Milestones
        story.append(Paragraph("Active Goals & Learning Milestones", h2_style))
        goals_text = ", ".join(active_goals) if active_goals else "None currently set."
        story.append(Paragraph(f"<b>Current Active Goals:</b> {goals_text}", body_style))
        story.append(Spacer(1, 4))
        achievements_text = ", ".join(achievements) if achievements else "No milestones earned yet."
        story.append(Paragraph(f"<b>Milestones Earned:</b> {achievements_text}", body_style))
        story.append(Spacer(1, 16))

        # Mandatory Non-Diagnostic Disclaimer Box
        story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#E2E8F0"), spaceAfter=8))
        disclaimer_box = [
            [Paragraph(f"<b>Notice & Disclaimer:</b> {report.disclaimer}", disclaimer_style)]
        ]
        disc_table = Table(disclaimer_box, colWidths=[540])
        disc_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#FEF3C7")),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.HexColor("#92400E")),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
            ('LEFTPADDING', (0, 0), (-1, -1), 10),
            ('RIGHTPADDING', (0, 0), (-1, -1), 10),
            ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#F59E0B")),
        ]))
        story.append(disc_table)

        doc.build(story)
        pdf_bytes = buf.getvalue()
        buf.close()
        return pdf_bytes
