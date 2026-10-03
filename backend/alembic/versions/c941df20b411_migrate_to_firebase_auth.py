"""migrate_to_firebase_auth

Revision ID: c941df20b411
Revises: 8842fc05ca55
Create Date: 2026-09-30 22:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c941df20b411'
down_revision: Union[str, None] = '8842fc05ca55'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Drop refresh_tokens table (Firebase manages authentication refresh tokens)
    op.drop_table('refresh_tokens')

    # 2. Modify users table: add firebase_uid, remove password_hash
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('firebase_uid', sa.String(length=128), nullable=False))
        batch_op.create_index(batch_op.f('ix_users_firebase_uid'), ['firebase_uid'], unique=True)
        batch_op.drop_column('password_hash')


def downgrade() -> None:
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('password_hash', sa.String(length=255), nullable=False))
        batch_op.drop_index(batch_op.f('ix_users_firebase_uid'))
        batch_op.drop_column('firebase_uid')

    op.create_table(
        'refresh_tokens',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('token_hash', sa.String(length=64), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('revoked', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_refresh_tokens_token_hash', 'refresh_tokens', ['token_hash'], unique=False)
    op.create_index('ix_refresh_tokens_user_id', 'refresh_tokens', ['user_id'], unique=False)
