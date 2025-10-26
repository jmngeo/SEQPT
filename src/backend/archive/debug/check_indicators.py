from app import create_app
from models import db, CompetencyIndicator

app = create_app()

with app.app_context():
    indicators = CompetencyIndicator.query.all()
    print(f'Total indicators in database: {len(indicators)}')
    
    if len(indicators) > 0:
        print('\nSample indicators:')
        for ind in indicators[:10]:
            print(f'  ID: {ind.id}, Competency: {ind.competency_id}, Level: "{ind.level}", Indicator: {ind.indicator_en[:60] if ind.indicator_en else "None"}...')
        
        # Check unique levels
        levels = set(ind.level for ind in indicators if ind.level)
        print(f'\nUnique levels in database: {sorted(levels)}')
        
        # Check for specific competency
        comp_1_indicators = CompetencyIndicator.query.filter_by(competency_id=1).all()
        print(f'\nIndicators for competency 1: {len(comp_1_indicators)}')
        if comp_1_indicators:
            for ind in comp_1_indicators[:2]:
                print(f'  Level: "{ind.level}", Indicator: {ind.indicator_en[:80]}...')
    else:
        print('[ERROR] No indicators found in database!')
