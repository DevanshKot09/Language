"""create_achievements_and_expand_goals

Revision ID: f920da821034
Revises: e719df620981
Create Date: 2026-10-01 15:50:00.000000

"""
from typing import Sequence, Union
from datetime import datetime, timezone
import uuid
from alembic import op
import sqlalchemy as sa


revision: str = 'f920da821034'
down_revision: Union[str, None] = 'e719df620981'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Expand learner_goals table with tracking metrics
    with op.batch_alter_table('learner_goals') as batch_op:
        batch_op.add_column(sa.Column('description', sa.String(length=500), nullable=True))
        batch_op.add_column(sa.Column('goal_type', sa.String(length=50), nullable=False, server_default='complete_lessons'))
        batch_op.add_column(sa.Column('target_count', sa.Integer(), nullable=False, server_default='3'))
        batch_op.add_column(sa.Column('current_count', sa.Integer(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True))

    # 2. Create achievements table
    op.create_table(
        'achievements',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('code', sa.String(length=64), nullable=False),
        sa.Column('title', sa.String(length=128), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('icon_name', sa.String(length=64), nullable=False, server_default='emoji_events'),
        sa.Column('threshold', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('badge_tier', sa.String(length=32), nullable=False, server_default='bronze'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_achievements_code'), 'achievements', ['code'], unique=True)
    op.create_index(op.f('ix_achievements_category'), 'achievements', ['category'], unique=False)

    # 3. Create user_achievements table
    op.create_table(
        'user_achievements',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('achievement_id', sa.String(length=36), nullable=False),
        sa.Column('progress_value', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('unlocked_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['achievement_id'], ['achievements.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'achievement_id', name='uq_user_achievement'),
    )
    op.create_index(op.f('ix_user_achievements_user_id'), 'user_achievements', ['user_id'], unique=False)
    op.create_index(op.f('ix_user_achievements_achievement_id'), 'user_achievements', ['achievement_id'], unique=False)

    # 4. Seed standard non-punitive achievement definitions
    achievements_table = sa.table(
        'achievements',
        sa.column('id', sa.String),
        sa.column('code', sa.String),
        sa.column('title', sa.String),
        sa.column('description', sa.String),
        sa.column('category', sa.String),
        sa.column('icon_name', sa.String),
        sa.column('threshold', sa.Integer),
        sa.column('badge_tier', sa.String),
        sa.column('created_at', sa.DateTime),
    )

    now = datetime.now(timezone.utc)
    op.bulk_insert(
        achievements_table,
        [
            {
                'id': str(uuid.uuid4()),
                'code': 'first_lesson',
                'title': 'First Practice Step',
                'description': 'Completed your first practice lesson.',
                'category': 'learning',
                'icon_name': 'school',
                'threshold': 1,
                'badge_tier': 'bronze',
                'created_at': now,
            },
            {
                'id': str(uuid.uuid4()),
                'code': 'five_lessons',
                'title': 'Practice Momentum',
                'description': 'Completed 5 learning lessons.',
                'category': 'learning',
                'icon_name': 'military_tech',
                'threshold': 5,
                'badge_tier': 'silver',
                'created_at': now,
            },
            {
                'id': str(uuid.uuid4()),
                'code': 'ten_lessons',
                'title': 'Ten Lesson Journey',
                'description': 'Completed 10 learning lessons.',
                'category': 'learning',
                'icon_name': 'workspace_premium',
                'threshold': 10,
                'badge_tier': 'gold',
                'created_at': now,
            },
            {
                'id': str(uuid.uuid4()),
                'code': 'twenty_five_lessons',
                'title': 'Mastery Pathfinder',
                'description': 'Completed 25 learning lessons across your curriculum.',
                'category': 'learning',
                'icon_name': 'stars',
                'threshold': 25,
                'badge_tier': 'gold',
                'created_at': now,
            },
            {
                'id': str(uuid.uuid4()),
                'code': 'three_skills_practiced',
                'title': 'Skill Explorer',
                'description': 'Practiced activities across 3 distinct skill areas.',
                'category': 'skills',
                'icon_name': 'explore',
                'threshold': 3,
                'badge_tier': 'bronze',
                'created_at': now,
            },
            {
                'id': str(uuid.uuid4()),
                'code': 'first_goal_completed',
                'title': 'Goal Setter',
                'description': 'Set and completed your first learning goal.',
                'category': 'goals',
                'icon_name': 'flag',
                'threshold': 1,
                'badge_tier': 'silver',
                'created_at': now,
            },
            {
                'id': str(uuid.uuid4()),
                'code': 'three_goals_completed',
                'title': 'Goal Champion',
                'description': 'Successfully completed 3 learning goals.',
                'category': 'goals',
                'icon_name': 'emoji_events',
                'threshold': 3,
                'badge_tier': 'gold',
                'created_at': now,
            },
            {
                'id': str(uuid.uuid4()),
                'code': 'consistent_practice_3d',
                'title': 'Consistent Effort',
                'description': 'Engaged in learning practice on 3 distinct days this week.',
                'category': 'practice',
                'icon_name': 'today',
                'threshold': 3,
                'badge_tier': 'silver',
                'created_at': now,
            },
        ]
    )


def downgrade() -> None:
    op.drop_table('user_achievements')
    op.drop_table('achievements')
    with op.batch_alter_table('learner_goals') as batch_op:
        batch_op.drop_column('completed_at')
        batch_op.drop_column('current_count')
        batch_op.drop_column('target_count')
        batch_op.drop_column('goal_type')
        batch_op.drop_column('description')
