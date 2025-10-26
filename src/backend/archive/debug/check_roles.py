from app import create_app
from models import RoleCluster

app = create_app()

with app.app_context():
    roles = RoleCluster.query.filter_by(organization_id=16).order_by(RoleCluster.id).all()

    for role in roles:
        print(f"\n{role.id}. {role.role_cluster_name}")
        print(f"   Description: {role.role_cluster_description}")
