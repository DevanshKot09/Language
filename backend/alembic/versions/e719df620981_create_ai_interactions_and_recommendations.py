"""create_ai_interactions_and_recommendations

Revision ID: e719df620981
Revises: d523bf410892
Create Date: 2026-10-01 12:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e719df620981'
down_revision: Union[str, None] = 'd523bf410892'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Create ai_interactions table
    op.create_table(
        'ai_interactions',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('operation', sa.String(length=64), nullable=False),
        sa.Column('provider', sa.String(length=32), nullable=False),
        sa.Column('model', sa.String(length=64), nullable=False),
        sa.Column('prompt_version', sa.String(length=32), nullable=False),
        sa.Column('status', sa.String(length=32), nullable=False),
        sa.Column('latency_ms', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('safety_result', sa.String(length=32), nullable=False, server_default='passed'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_ai_interactions_user_id'), 'ai_interactions', ['user_id'], unique=False)
    op.create_index(op.f('ix_ai_interactions_operation'), 'ai_interactions', ['operation'], unique=False)
    op.create_index(op.f('ix_ai_interactions_status'), 'ai_interactions', ['status'], unique=False)
    op.create_index(op.f('ix_ai_interactions_created_at'), 'ai_interactions', ['created_at'], unique=False)

    # 2. Create recommendations table
    op.create_table(
        'recommendations',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('lesson_id', sa.String(length=36), nullable=False),
        sa.Column('operation', sa.String(length=64), nullable=False),
        sa.Column('reason_code', sa.String(length=64), nullable=False),
        sa.Column('short_explanation', sa.String(length=255), nullable=False),
        sa.Column('status', sa.String(length=32), nullable=False, server_default='active'),
        sa.Column('human_reviewed', sa.Boolean(), nullable=False, server_default=sa.text('false')),
        sa.Column('human_status', sa.String(length=32), nullable=False, server_default='none'),
        sa.Column('human_reviewer_id', sa.String(length=36), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['lesson_id'], ['lessons.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_recommendations_user_id'), 'recommendations', ['user_id'], unique=False)
    op.create_index(op.f('ix_recommendations_lesson_id'), 'recommendations', ['lesson_id'], unique=False)
    op.create_index(op.f('ix_recommendations_status'), 'recommendations', ['status'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_recommendations_status'), table_name='recommendations')
    op.drop_index(op.f('ix_recommendations_lesson_id'), table_name='recommendations')
    op.drop_index(op.f('ix_recommendations_user_id'), table_name='recommendations')
    op.drop_table('recommendations')

    op.drop_index(op.f('ix_ai_interactions_created_at'), table_name='ai_interactions')
    op.drop_index(op.f('ix_ai_interactions_status'), table_name='ai_interactions')
    op.drop_index(op.f('ix_ai_interactions_operation'), table_name='ai_interactions')
    op.drop_index(op.f('ix_ai_interactions_user_id'), table_name='ai_interactions')
    op.drop_table('ai_interactions')
