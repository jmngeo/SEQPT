@echo off
echo Starting SE-QPT Application...
echo.
echo Starting Backend (Flask)...
start "SE-QPT Backend" cmd /k "%~dp0start_backend.bat"
timeout /t 3 /nobreak >nul
echo.
echo Starting Frontend (Vue)...
start "SE-QPT Frontend" cmd /k "%~dp0start_frontend.bat"
echo.
echo Both servers are starting in separate windows.
echo Backend: http://localhost:5000
echo Frontend: http://localhost:3000
echo.
pause
