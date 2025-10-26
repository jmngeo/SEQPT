from app import create_app
from models import db, User

app = create_app()
with app.app_context():
    try:
        count = User.query.count()
        print(f'[OK] User table accessible, count: {count}')
    except Exception as e:
        print(f'[ERROR] {e}')
