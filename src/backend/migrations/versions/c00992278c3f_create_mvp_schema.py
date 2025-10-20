"""Create MVP schema with 6 core tables

Revision ID: c00992278c3f
Revises: 86e9a1987709
Create Date: 2025-09-28 12:45:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'c00992278c3f'
down_revision = '86e9a1987709'
branch_labels = None
depends_on = None


def upgrade():
    """Create MVP schema tables"""

    # 1. Create organizations table
    op.create_table(
        'organizations',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('name', sa.String(200), nullable=False),
        sa.Column('organization_code', sa.String(8), nullable=False, unique=True),
        sa.Column('size', sa.String(20)),
        sa.Column('maturity_score', sa.Float()),
        sa.Column('selected_archetype', sa.String(100)),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now())
    )

    # Create index on organization_code for fast lookups
    op.create_index('idx_organization_code', 'organizations', ['organization_code'])

    # 2. Create new simplified users table
    op.create_table(
        'mvp_users',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('email', sa.String(120), nullable=False, unique=True),
        sa.Column('password_hash', sa.String(255), nullable=False),
        sa.Column('first_name', sa.String(50), nullable=False),
        sa.Column('last_name', sa.String(50), nullable=False),
        sa.Column('role', sa.String(20), nullable=False),  # 'admin' or 'employee'
        sa.Column('organization_id', sa.String(36), nullable=False),
        sa.Column('joined_via_code', sa.String(8)),
        sa.Column('is_active', sa.Boolean(), default=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('last_login', sa.DateTime()),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'])
    )

    # Create indexes for users
    op.create_index('idx_user_email', 'mvp_users', ['email'])
    op.create_index('idx_user_organization', 'mvp_users', ['organization_id'])
    op.create_index('idx_user_role', 'mvp_users', ['role'])

    # 3. Create maturity_assessments table
    op.create_table(
        'maturity_assessments',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('organization_id', sa.String(36), nullable=False),
        sa.Column('scope_score', sa.Float(), nullable=False),
        sa.Column('process_score', sa.Float(), nullable=False),
        sa.Column('overall_maturity', sa.String(20), nullable=False),
        sa.Column('overall_score', sa.Float(), nullable=False),
        sa.Column('responses', sa.Text()),  # JSON string
        sa.Column('completed_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'])
    )

    # 4. Create competency_assessments table
    op.create_table(
        'competency_assessments',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('user_id', sa.String(36), nullable=False),
        sa.Column('competency_scores', sa.Text(), nullable=False),  # JSON string
        sa.Column('role_cluster', sa.String(100)),
        sa.Column('completed_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(['user_id'], ['mvp_users.id'])
    )

    # 5. Create learning_plans table
    op.create_table(
        'learning_plans',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('user_id', sa.String(36), nullable=False),
        sa.Column('objectives', sa.Text(), nullable=False),  # JSON array
        sa.Column('recommended_modules', sa.Text()),  # JSON array
        sa.Column('estimated_duration_weeks', sa.Integer()),
        sa.Column('archetype_used', sa.String(100)),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(['user_id'], ['mvp_users.id'])
    )

    # 6. Create role_mappings table
    op.create_table(
        'role_mappings',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('user_id', sa.String(36), nullable=False),
        sa.Column('assigned_role_cluster', sa.String(100), nullable=False),
        sa.Column('confidence', sa.Float()),
        sa.Column('mapping_data', sa.Text()),  # JSON string
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(['user_id'], ['mvp_users.id'])
    )

    # Create additional useful indexes
    op.create_index('idx_competency_user', 'competency_assessments', ['user_id'])
    op.create_index('idx_learning_plan_user', 'learning_plans', ['user_id'])
    op.create_index('idx_role_mapping_user', 'role_mappings', ['user_id'])


def downgrade():
    """Drop MVP schema tables"""

    # Drop indexes first
    op.drop_index('idx_role_mapping_user', 'role_mappings')
    op.drop_index('idx_learning_plan_user', 'learning_plans')
    op.drop_index('idx_competency_user', 'competency_assessments')
    op.drop_index('idx_user_role', 'mvp_users')
    op.drop_index('idx_user_organization', 'mvp_users')
    op.drop_index('idx_user_email', 'mvp_users')
    op.drop_index('idx_organization_code', 'organizations')

    # Drop tables in reverse order (due to foreign key constraints)
    op.drop_table('role_mappings')
    op.drop_table('learning_plans')
    op.drop_table('competency_assessments')
    op.drop_table('maturity_assessments')
    op.drop_table('mvp_users')
    op.drop_table('organizations')