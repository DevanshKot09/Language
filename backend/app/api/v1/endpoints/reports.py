import json
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.collaboration import Report
from app.schemas.collaboration import ReportCreateRequest, ReportResponse
from app.services.report_service import ReportService

router = APIRouter()


@router.post("", response_model=ReportResponse, status_code=status.HTTP_201_CREATED)
async def create_report(
    request: ReportCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Generate an educational learning support report for an authorized learner.
    Enforces role and relationship permission.
    """
    service = ReportService(db)
    report = service.generate_report(
        creator=current_user,
        learner_id=request.learner_id,
        report_type=request.report_type,
        title=request.title,
    )
    creator_prof = current_user.profile
    learner = db.query(User).filter(User.id == report.learner_id).first()
    learner_prof = learner.profile if learner else None

    return ReportResponse(
        id=report.id,
        creator_id=report.creator_id,
        creator_name=creator_prof.display_name if creator_prof else "Creator",
        learner_id=report.learner_id,
        learner_name=learner_prof.display_name if learner_prof else "Learner",
        report_type=report.report_type,
        title=report.title,
        summary_data=json.loads(report.summary_data),
        disclaimer=report.disclaimer,
        status=report.status,
        created_at=report.created_at,
        expires_at=report.expires_at,
        pdf_download_url=f"/api/v1/reports/{report.id}/pdf",
    )


@router.get("", response_model=List[ReportResponse])
async def list_reports(
    learner_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Lists reports accessible to the user (created by user or for user's authorized learner).
    """
    service = ReportService(db)
    if current_user.role == "learner":
        reports = service.repo.list_reports_for_learner(current_user.id)
    elif learner_id:
        # Verify relationship access
        service.collab_service.verify_relationship_access(current_user, learner_id)
        reports = service.repo.list_reports_for_learner(learner_id)
    else:
        reports = service.repo.list_reports_for_creator(current_user.id)

    res = []
    for r in reports:
        creator = db.query(User).filter(User.id == r.creator_id).first()
        creator_prof = creator.profile if creator else None
        learner = db.query(User).filter(User.id == r.learner_id).first()
        learner_prof = learner.profile if learner else None
        res.append(
            ReportResponse(
                id=r.id,
                creator_id=r.creator_id,
                creator_name=creator_prof.display_name if creator_prof else "Creator",
                learner_id=r.learner_id,
                learner_name=learner_prof.display_name if learner_prof else "Learner",
                report_type=r.report_type,
                title=r.title,
                summary_data=json.loads(r.summary_data),
                disclaimer=r.disclaimer,
                status=r.status,
                created_at=r.created_at,
                expires_at=r.expires_at,
                pdf_download_url=f"/api/v1/reports/{r.id}/pdf",
            )
        )
    return res


@router.get("/{report_id}", response_model=ReportResponse)
async def get_report(
    report_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get structured report details. Access restricted to creator, learner, or authorized collaborator.
    """
    service = ReportService(db)
    report = service.get_report(report_id, current_user)
    creator = db.query(User).filter(User.id == report.creator_id).first()
    creator_prof = creator.profile if creator else None
    learner = db.query(User).filter(User.id == report.learner_id).first()
    learner_prof = learner.profile if learner else None

    return ReportResponse(
        id=report.id,
        creator_id=report.creator_id,
        creator_name=creator_prof.display_name if creator_prof else "Creator",
        learner_id=report.learner_id,
        learner_name=learner_prof.display_name if learner_prof else "Learner",
        report_type=report.report_type,
        title=report.title,
        summary_data=json.loads(report.summary_data),
        disclaimer=report.disclaimer,
        status=report.status,
        created_at=report.created_at,
        expires_at=report.expires_at,
        pdf_download_url=f"/api/v1/reports/{report.id}/pdf",
    )


@router.get("/{report_id}/pdf")
async def download_report_pdf(
    report_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Download accessible, non-diagnostic PDF report bytes.
    Enforces authentication and relationship authorization.
    """
    service = ReportService(db)
    report = service.get_report(report_id, current_user)
    pdf_bytes = service.render_pdf(report, current_user)

    filename = f"lingua_ai_report_{report.id[:8]}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Cache-Control": "no-store, must-revalidate",
        },
    )
