"""create_collaboration_tables

Revision ID: a174c829e012
Revises: f920da821034
Create Date: 2026-10-01 16:20:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a174c829e012'
down_revision: Union[str, None] = 'f920da821034'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. relationships table
    op.create_table(
        'relationships',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('source_user_id', sa.String(length=36), nullable=False),
        sa.Column('target_user_id', sa.String(length=36), nullable=False),
        sa.Column('relationship_type', sa.String(length=32), nullable=False),
        sa.Column('status', sa.String(length=32), nullable=False, server_default='active'),
        sa.Column('permission_scope', sa.Text(), nullable=False),
        sa.Column('consent_status', sa.String(length=32), nullable=False, server_default='verified'),
        sa.Column('organization', sa.String(length=128), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('revoked_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['source_user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['target_user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('source_user_id', 'target_user_id', 'relationship_type', name='uq_relationship')
    )
    op.create_index('ix_relationships_source_user_id', 'relationships', ['source_user_id'], unique=False)
    op.create_index('ix_relationships_target_user_id', 'relationships', ['target_user_id'], unique=False)
    op.create_index('ix_relationships_type', 'relationships', ['relationship_type'], unique=False)
    op.create_index('ix_relationships_status', 'relationships', ['status'], unique=False)

    # 2. relationship_invitations table
    op.create_table(
        'relationship_invitations',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('invitation_token', sa.String(length=64), nullable=False),
        sa.Column('inviter_id', sa.String(length=36), nullable=False),
        sa.Column('invitee_email', sa.String(length=255), nullable=False),
        sa.Column('target_learner_id', sa.String(length=36), nullable=True),
        sa.Column('relationship_type', sa.String(length=32), nullable=False),
        sa.Column('permission_scope', sa.Text(), nullable=False),
        sa.Column('status', sa.String(length=32), nullable=False, server_default='pending'),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('accepted_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['inviter_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['target_learner_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('invitation_token', name='uq_invitation_token')
    )
    op.create_index('ix_relationship_invitations_token', 'relationship_invitations', ['invitation_token'], unique=False)
    op.create_index('ix_relationship_invitations_inviter_id', 'relationship_invitations', ['inviter_id'], unique=False)
    op.create_index('ix_relationship_invitations_email', 'relationship_invitations', ['invitee_email'], unique=False)
    op.create_index('ix_relationship_invitations_status', 'relationship_invitations', ['status'], unique=False)

    # 3. assignments table
    op.create_table(
        'assignments',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('teacher_id', sa.String(length=36), nullable=False),
        sa.Column('student_id', sa.String(length=36), nullable=False),
        sa.Column('lesson_id', sa.String(length=36), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('instructions', sa.Text(), nullable=True),
        sa.Column('status', sa.String(length=32), nullable=False, server_default='assigned'),
        sa.Column('due_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['teacher_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['student_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['lesson_id'], ['lessons.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_assignments_teacher_id', 'assignments', ['teacher_id'], unique=False)
    op.create_index('ix_assignments_student_id', 'assignments', ['student_id'], unique=False)
    op.create_index('ix_assignments_lesson_id', 'assignments', ['lesson_id'], unique=False)
    op.create_index('ix_assignments_status', 'assignments', ['status'], unique=False)

    # 4. reports table
    op.create_table(
        'reports',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('creator_id', sa.String(length=36), nullable=False),
        sa.Column('learner_id', sa.String(length=36), nullable=False),
        sa.Column('report_type', sa.String(length=32), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('summary_data', sa.Text(), nullable=False),
        sa.Column('disclaimer', sa.Text(), nullable=False),
        sa.Column('status', sa.String(length=32), nullable=False, server_default='active'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['creator_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['learner_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_reports_creator_id', 'reports', ['creator_id'], unique=False)
    op.create_index('ix_reports_learner_id', 'reports', ['learner_id'], unique=False)
    op.create_index('ix_reports_type', 'reports', ['report_type'], unique=False)
    op.create_index('ix_reports_status', 'reports', ['status'], unique=False)

    # 5. report_access_events table
    op.create_table(
        'report_access_events',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('action', sa.String(length=64), nullable=False),
        sa.Column('target_user_id', sa.String(length=36), nullable=True),
        sa.Column('resource_type', sa.String(length=64), nullable=False),
        sa.Column('resource_id', sa.String(length=36), nullable=True),
        sa.Column('details', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_report_access_events_user_id', 'report_access_events', ['user_id'], unique=False)
    op.create_index('ix_report_access_events_action', 'report_access_events', ['action'], unique=False)
    op.create_index('ix_report_access_events_target_id', 'report_access_events', ['target_user_id'], unique=False)


def downgrade() -> None:
    op.drop_table('report_access_events')
    op.drop_table('reports')
    op.drop_table('assignments')
    op.drop_table('relationship_invitations')
    op.drop_table('relationships')
