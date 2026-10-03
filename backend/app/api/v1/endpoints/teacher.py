from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import require_role
from app.models.user import User
from app.models.collaboration import Assignment
from app.schemas.collaboration import AssignmentCreateRequest, AssignmentResponse
from app.schemas.progress import ProgressDashboardResponse
from app.services.collaboration_service import CollaborationService
from app.services.progress_service import ProgressService

router = APIRouter()


@router.get("/students", response_model=List[Dict[str, Any]])
async def get_teacher_students(
    current_user: User = Depends(require_role(["teacher", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Returns student roster connected to the authenticated teacher.
    Only includes students with an active relationship.
    """
    service = CollaborationService(db)
    return service.get_teacher_students(current_user)


@router.get("/students/{student_id}/progress", response_model=ProgressDashboardResponse)
async def get_student_progress(
    student_id: str,
    current_user: User = Depends(require_role(["teacher", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Returns deterministic learning progress for an authorized student.
    Enforces relationship and 'view_progress' scope.
    """
    collab_service = CollaborationService(db)
    collab_service.verify_relationship_access(
        actor=current_user,
        target_learner_id=student_id,
        required_scope="view_progress",
    )

    student = db.query(User).filter(User.id == student_id).first()
    if not student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found.")

    return ProgressService.get_progress_dashboard(db, student)


@router.post("/assignments", response_model=AssignmentResponse, status_code=status.HTTP_201_CREATED)
async def create_assignment(
    request: AssignmentCreateRequest,
    current_user: User = Depends(require_role(["teacher", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Assign an approved curriculum lesson to an authorized student.
    Enforces 'create_assignment' permission.
    """
    service = CollaborationService(db)
    assignment = service.create_assignment(
        teacher=current_user,
        student_id=request.student_id,
        lesson_id=request.lesson_id,
        title=request.title,
        instructions=request.instructions,
        due_at=request.due_at,
    )
    teacher_prof = current_user.profile
    student = db.query(User).filter(User.id == assignment.student_id).first()
    student_prof = student.profile if student else None

    return AssignmentResponse(
        id=assignment.id,
        teacher_id=assignment.teacher_id,
        teacher_name=teacher_prof.display_name if teacher_prof else "Teacher",
        student_id=assignment.student_id,
        student_name=student_prof.display_name if student_prof else "Student",
        lesson_id=assignment.lesson_id,
        lesson_title=assignment.lesson.title if assignment.lesson else "Lesson",
        title=assignment.title,
        instructions=assignment.instructions,
        status=assignment.status,
        due_at=assignment.due_at,
        completed_at=assignment.completed_at,
        created_at=assignment.created_at,
    )


@router.get("/assignments", response_model=List[AssignmentResponse])
async def list_teacher_assignments(
    current_user: User = Depends(require_role(["teacher", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Lists assignments created by the current teacher.
    """
    service = CollaborationService(db)
    assignments = service.repo.list_teacher_assignments(current_user.id)
    teacher_prof = current_user.profile

    res = []
    for a in assignments:
        student = db.query(User).filter(User.id == a.student_id).first()
        student_prof = student.profile if student else None
        res.append(
            AssignmentResponse(
                id=a.id,
                teacher_id=a.teacher_id,
                teacher_name=teacher_prof.display_name if teacher_prof else "Teacher",
                student_id=a.student_id,
                student_name=student_prof.display_name if student_prof else "Student",
                lesson_id=a.lesson_id,
                lesson_title=a.lesson.title if a.lesson else "Lesson",
                title=a.title,
                instructions=a.instructions,
                status=a.status,
                due_at=a.due_at,
                completed_at=a.completed_at,
                created_at=a.created_at,
            )
        )
    return res


@router.get("/classroom-trends")
async def get_classroom_trends(
    current_user: User = Depends(require_role(["teacher", "admin"])),
    db: Session = Depends(get_db),
):
    """
    Returns aggregated cohort trends across authorized students.
    Strictly educational: NO individual rankings or disorder severity comparisons!
    """
    service = CollaborationService(db)
    students = service.get_teacher_students(current_user)
    total_students = len(students)
    if total_students == 0:
        return {
            "total_students": 0,
            "total_assignments_created": 0,
            "assignment_completion_rate": 0.0,
            "practice_overview": "Connect with students to see aggregated classroom learning trends.",
        }

    assignments = service.repo.list_teacher_assignments(current_user.id)
    total_assignments = len(assignments)
    completed_assignments = sum(1 for a in assignments if a.status == "completed")
    completion_rate = (completed_assignments / total_assignments * 100) if total_assignments > 0 else 0.0

    return {
        "total_students": total_students,
        "total_assignments_created": total_assignments,
        "assignments_completed": completed_assignments,
        "assignment_completion_rate": round(completion_rate, 1),
        "practice_overview": f"Classroom cohort of {total_students} students with {completed_assignments}/{total_assignments} assignments completed.",
    }
