@echo off
cd /d "%~dp0src\competency_assessor"
set DATABASE_URL=postgresql://postgres:root@localhost:5432/competency_assessment
set FLASK_APP=run.py
set FLASK_DEBUG=1
set OPENAI_API_KEY=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
echo Starting Flask backend...
echo Database: %DATABASE_URL%
flask run
pause
