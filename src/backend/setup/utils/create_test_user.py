"""
Quick script to create a test user with known credentials
"""
import sys
sys.path.insert(0, '.')

from app import create_app, db
from models import User
from werkzeug.security import generate_password_hash

app = create_app()

with app.app_context():
    # Check if test_user exists
    existing_user = User.query.filter_by(username='test_user').first()
    if existing_user:
        print(f"Deleting existing test_user (id={existing_user.id})")
        db.session.delete(existing_user)
        db.session.commit()

    # Create test user with known password
    password = "testpass123"
    password_hash = generate_password_hash(password)

    test_user = User(
        username='test_user',
        password_hash=password_hash,
        role='admin',
        organization_id=1
    )

    db.session.add(test_user)
    db.session.commit()

    print(f"[SUCCESS] Created test user:")
    print(f"  Username: test_user")
    print(f"  Password: testpass123")
    print(f"  ID: {test_user.id}")
    print(f"  Role: admin")
