"""create_skills_baseline_and_goals

Revision ID: f318da294c65
Revises: c941df20b411
Create Date: 2026-09-30 23:15:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f318da294c65'
down_revision: Union[str, None] = 'c941df20b411'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Create skills table
    op.create_table(
        'skills',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('code', sa.String(length=64), nullable=False),
        sa.Column('name', sa.String(length=128), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('track', sa.String(length=50), nullable=False),
        sa.Column('domain', sa.String(length=64), nullable=False),
        sa.Column('age_band_applicability', sa.String(length=64), nullable=False),
        sa.Column('priority', sa.String(length=32), nullable=False),
        sa.Column('active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_skills_code'), 'skills', ['code'], unique=True)
    op.create_index(op.f('ix_skills_track'), 'skills', ['track'], unique=False)
    op.create_index(op.f('ix_skills_domain'), 'skills', ['domain'], unique=False)

    # 2. Create baseline_sessions table
    op.create_table(
        'baseline_sessions',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('track', sa.String(length=50), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False),
        sa.Column('total_activities', sa.Integer(), nullable=False),
        sa.Column('completed_activities', sa.Integer(), nullable=False),
        sa.Column('started_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_baseline_sessions_user_id'), 'baseline_sessions', ['user_id'], unique=False)

    # 3. Create baseline_activities table
    op.create_table(
        'baseline_activities',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('skill_id', sa.String(length=36), nullable=False),
        sa.Column('track', sa.String(length=50), nullable=False),
        sa.Column('domain', sa.String(length=64), nullable=False),
        sa.Column('age_band', sa.String(length=50), nullable=False),
        sa.Column('activity_type', sa.String(length=64), nullable=False),
        sa.Column('instruction', sa.Text(), nullable=False),
        sa.Column('prompt', sa.Text(), nullable=False),
        sa.Column('options_json', sa.Text(), nullable=False),
        sa.Column('correct_answer', sa.String(length=255), nullable=False),
        sa.Column('hint', sa.Text(), nullable=True),
        sa.Column('difficulty', sa.Integer(), nullable=False),
        sa.Column('active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['skill_id'], ['skills.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_baseline_activities_skill_id'), 'baseline_activities', ['skill_id'], unique=False)
    op.create_index(op.f('ix_baseline_activities_track'), 'baseline_activities', ['track'], unique=False)
    op.create_index(op.f('ix_baseline_activities_domain'), 'baseline_activities', ['domain'], unique=False)

    # 4. Create baseline_responses table
    op.create_table(
        'baseline_responses',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('session_id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('activity_id', sa.String(length=36), nullable=False),
        sa.Column('skill_id', sa.String(length=36), nullable=False),
        sa.Column('selected_option', sa.String(length=255), nullable=False),
        sa.Column('is_correct', sa.Boolean(), nullable=False),
        sa.Column('time_taken_ms', sa.Integer(), nullable=False),
        sa.Column('attempt_count', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['session_id'], ['baseline_sessions.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['activity_id'], ['baseline_activities.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['skill_id'], ['skills.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_baseline_responses_session_id'), 'baseline_responses', ['session_id'], unique=False)
    op.create_index(op.f('ix_baseline_responses_user_id'), 'baseline_responses', ['user_id'], unique=False)
    op.create_index(op.f('ix_baseline_responses_activity_id'), 'baseline_responses', ['activity_id'], unique=False)
    op.create_index(op.f('ix_baseline_responses_skill_id'), 'baseline_responses', ['skill_id'], unique=False)

    # 5. Create skill_assessments table
    op.create_table(
        'skill_assessments',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('skill_id', sa.String(length=36), nullable=False),
        sa.Column('session_id', sa.String(length=36), nullable=True),
        sa.Column('assessment_type', sa.String(length=50), nullable=False),
        sa.Column('score', sa.Float(), nullable=False),
        sa.Column('accuracy', sa.Float(), nullable=False),
        sa.Column('attempt_count', sa.Integer(), nullable=False),
        sa.Column('duration_seconds', sa.Integer(), nullable=False),
        sa.Column('band', sa.String(length=50), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['skill_id'], ['skills.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['session_id'], ['baseline_sessions.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_skill_assessments_user_id'), 'skill_assessments', ['user_id'], unique=False)
    op.create_index(op.f('ix_skill_assessments_skill_id'), 'skill_assessments', ['skill_id'], unique=False)
    op.create_index(op.f('ix_skill_assessments_session_id'), 'skill_assessments', ['session_id'], unique=False)

    # 6. Create learner_goals table
    op.create_table(
        'learner_goals',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('skill_id', sa.String(length=36), nullable=True),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('target_frequency', sa.String(length=50), nullable=False),
        sa.Column('target_behavior', sa.String(length=255), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['skill_id'], ['skills.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_learner_goals_user_id'), 'learner_goals', ['user_id'], unique=False)
    op.create_index(op.f('ix_learner_goals_skill_id'), 'learner_goals', ['skill_id'], unique=False)

    # 7. Extend profiles table with Phase 4 fields
    with op.batch_alter_table('profiles', schema=None) as batch_op:
        batch_op.add_column(sa.Column('baseline_status', sa.String(length=50), server_default='not_started', nullable=False))
        batch_op.add_column(sa.Column('preferred_learning_mode', sa.String(length=50), server_default='multimodal', nullable=False))
        batch_op.add_column(sa.Column('primary_learning_goal', sa.String(length=255), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table('profiles', schema=None) as batch_op:
        batch_op.drop_column('primary_learning_goal')
        batch_op.drop_column('preferred_learning_mode')
        batch_op.drop_column('baseline_status')

    op.drop_table('learner_goals')
    op.drop_table('skill_assessments')
    op.drop_table('baseline_responses')
    op.drop_table('baseline_activities')
    op.drop_table('baseline_sessions')
    op.drop_table('skills')
