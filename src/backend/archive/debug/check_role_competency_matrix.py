import os
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'
from app import create_app
from models import db
from sqlalchemy import text

app = create_app()
app.app_context().push()

count = db.session.execute(text('SELECT COUNT(*) FROM role_competency_matrix;')).scalar()
print(f'role_competency_matrix entries: {count}')

if count == 0:
    print('\nTABLE IS EMPTY - Need to populate!')
    print('This table maps SE roles to their required competency levels.')
    print('We can populate it by calling the stored procedure:')
    print('  CALL update_role_competency_matrix(1);  -- For organization_id=1')
else:
    print(f'\nTable has {count} rows')
    sample = db.session.execute(text('SELECT role_cluster_id, competency_id, role_competency_value FROM role_competency_matrix LIMIT 5;')).fetchall()
    print('\nSample data:')
    for r in sample:
        print(f'  Role {r[0]}, Competency {r[1]}: value={r[2]}')
