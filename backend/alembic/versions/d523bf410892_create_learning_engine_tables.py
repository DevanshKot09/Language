"""create_learning_engine_tables

Revision ID: d523bf410892
Revises: f318da294c65
Create Date: 2026-10-01 10:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd523bf410892'
down_revision: Union[str, None] = 'f318da294c65'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Create lessons table
    op.create_table(
        'lessons',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('skill_id', sa.String(length=36), nullable=False),
        sa.Column('title', sa.String(length=128), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('track', sa.String(length=50), nullable=False),
        sa.Column('age_band', sa.String(length=32), nullable=False),
        sa.Column('difficulty', sa.Integer(), nullable=False),
        sa.Column('sequence_order', sa.Integer(), nullable=False),
        sa.Column('estimated_effort_minutes', sa.Integer(), nullable=False),
        sa.Column('active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['skill_id'], ['skills.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_lessons_skill_id'), 'lessons', ['skill_id'], unique=False)
    op.create_index(op.f('ix_lessons_track'), 'lessons', ['track'], unique=False)
    op.create_index(op.f('ix_lessons_age_band'), 'lessons', ['age_band'], unique=False)
    op.create_index(op.f('ix_lessons_difficulty'), 'lessons', ['difficulty'], unique=False)

    # 2. Create exercises table
    op.create_table(
        'exercises',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('lesson_id', sa.String(length=36), nullable=False),
        sa.Column('skill_id', sa.String(length=36), nullable=False),
        sa.Column('exercise_type', sa.String(length=64), nullable=False),
        sa.Column('prompt', sa.Text(), nullable=False),
        sa.Column('instruction', sa.Text(), nullable=False),
        sa.Column('content_json', sa.Text(), nullable=False),
        sa.Column('correct_answer_json', sa.Text(), nullable=False),
        sa.Column('explanation', sa.Text(), nullable=True),
        sa.Column('difficulty', sa.Integer(), nullable=False),
        sa.Column('age_band', sa.String(length=32), nullable=False),
        sa.Column('track', sa.String(length=50), nullable=False),
        sa.Column('sequence_order', sa.Integer(), nullable=False),
        sa.Column('hints_json', sa.Text(), nullable=True),
        sa.Column('feedback_config_json', sa.Text(), nullable=True),
        sa.Column('active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['lesson_id'], ['lessons.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['skill_id'], ['skills.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_exercises_lesson_id'), 'exercises', ['lesson_id'], unique=False)
    op.create_index(op.f('ix_exercises_skill_id'), 'exercises', ['skill_id'], unique=False)
    op.create_index(op.f('ix_exercises_exercise_type'), 'exercises', ['exercise_type'], unique=False)

    # 3. Create exercise_attempts table
    op.create_table(
        'exercise_attempts',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('exercise_id', sa.String(length=36), nullable=False),
        sa.Column('lesson_id', sa.String(length=36), nullable=False),
        sa.Column('response_json', sa.Text(), nullable=False),
        sa.Column('is_correct', sa.Boolean(), nullable=False),
        sa.Column('partial_score', sa.Float(), nullable=False),
        sa.Column('attempt_number', sa.Integer(), nullable=False),
        sa.Column('time_spent_ms', sa.Integer(), nullable=False),
        sa.Column('hint_used', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['exercise_id'], ['exercises.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['lesson_id'], ['lessons.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_exercise_attempts_user_id'), 'exercise_attempts', ['user_id'], unique=False)
    op.create_index(op.f('ix_exercise_attempts_exercise_id'), 'exercise_attempts', ['exercise_id'], unique=False)
    op.create_index(op.f('ix_exercise_attempts_lesson_id'), 'exercise_attempts', ['lesson_id'], unique=False)

    # 4. Create user_lesson_progress table
    op.create_table(
        'user_lesson_progress',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('lesson_id', sa.String(length=36), nullable=False),
        sa.Column('current_exercise_index', sa.Integer(), nullable=False),
        sa.Column('status', sa.String(length=32), nullable=False),
        sa.Column('score', sa.Float(), nullable=True),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('last_attempted_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['lesson_id'], ['lessons.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_user_lesson_progress_user_id'), 'user_lesson_progress', ['user_id'], unique=False)
    op.create_index(op.f('ix_user_lesson_progress_lesson_id'), 'user_lesson_progress', ['lesson_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_user_lesson_progress_lesson_id'), table_name='user_lesson_progress')
    op.drop_index(op.f('ix_user_lesson_progress_user_id'), table_name='user_lesson_progress')
    op.drop_table('user_lesson_progress')

    op.drop_index(op.f('ix_exercise_attempts_lesson_id'), table_name='exercise_attempts')
    op.drop_index(op.f('ix_exercise_attempts_exercise_id'), table_name='exercise_attempts')
    op.drop_index(op.f('ix_exercise_attempts_user_id'), table_name='exercise_attempts')
    op.drop_table('exercise_attempts')

    op.drop_index(op.f('ix_exercises_exercise_type'), table_name='exercises')
    op.drop_index(op.f('ix_exercises_skill_id'), table_name='exercises')
    op.drop_index(op.f('ix_exercises_lesson_id'), table_name='exercises')
    op.drop_table('exercises')

    op.drop_index(op.f('ix_lessons_difficulty'), table_name='lessons')
    op.drop_index(op.f('ix_lessons_age_band'), table_name='lessons')
    op.drop_index(op.f('ix_lessons_track'), table_name='lessons')
    op.drop_index(op.f('ix_lessons_skill_id'), table_name='lessons')
    op.drop_table('lessons')
