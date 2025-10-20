@echo off
REM SE-QPT Frontend Startup Script
REM Starts the Vue/Vite frontend on port 3000

echo ========================================
echo SE-QPT Frontend Startup
echo ========================================
echo.
echo Starting frontend (src/frontend/)...
echo Port: 3000 (or 3001 if 3000 is busy)
echo Proxy: Forwards /api and /mvp to http://localhost:5000
echo.

cd /d "%~dp0src\frontend"
npm run dev

pause
