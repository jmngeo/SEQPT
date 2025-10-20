@echo off
REM SE-QPT Backend Startup Script
REM Starts the CORRECT backend (src/backend/) on port 5000

echo ========================================
echo SE-QPT Backend Startup
echo ========================================
echo.
echo Starting MAIN backend (src/backend/)...
echo Port: 5000
echo Database: competency_assessment
echo.

cd /d "%~dp0src\backend"

REM Set environment variables
set DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment

REM Activate virtual environment and run
call ..\..\venv\Scripts\activate.bat
python run.py --port 5000 --debug

pause
