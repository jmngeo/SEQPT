from app import create_app
import json

app = create_app()

with app.test_client() as client:
    response = client.get('/get_user_competency_results?username=se_survey_user_15&organization_id=1&survey_type=known_roles')
    print(f'Status: {response.status_code}')
    print(f'Response: {response.data.decode()}')
