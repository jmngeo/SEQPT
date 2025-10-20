from app import create_app, db
from sqlalchemy import text

app = create_app()
with app.app_context():
    indicators = db.session.execute(text('SELECT level, indicator_en FROM competency_indicators WHERE competency_id = 1 ORDER BY id')).fetchall()
    print('Competency indicators for ID=1:')
    for i in indicators:
        print(f'  Level: {repr(i[0])} | Indicator: {i[1][:60]}...')
