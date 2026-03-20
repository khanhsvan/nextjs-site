@echo off
setlocal

cd /d "%~dp0"
title StreamVault Platform Launcher

echo.
echo ==========================================
echo   StreamVault One-Click Launcher
echo ==========================================
echo.

where docker >nul 2>&1
if errorlevel 1 (
  echo Docker is not installed or not available in PATH.
  echo Please install Docker Desktop first:
  echo https://www.docker.com/products/docker-desktop/
  echo.
  pause
  exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
  echo Docker Desktop is installed but not running.
  echo Please open Docker Desktop and wait until it is ready.
  echo.
  pause
  exit /b 1
)

if not exist ".env" (
  echo Creating .env from .env.example...
  copy /Y ".env.example" ".env" >nul
)

echo Using configuration from .env

echo.
echo Checking Docker Compose file...
if not exist "infra\docker\docker-compose.yml" (
  echo Could not find infra\docker\docker-compose.yml
  echo Please make sure you are running this file from the project folder.
  echo.
  pause
  exit /b 1
)

echo.
echo Starting platform services. This may take a few minutes on first run...
docker compose -f infra\docker\docker-compose.yml up --build -d
if errorlevel 1 (
  echo.
  echo The platform could not be started.
  echo Please read the error above.
  echo.
  pause
  exit /b 1
)

echo.
echo Platform started successfully.
echo.
echo Open these pages in your browser:
echo Web App:      http://localhost:3000
echo API Health:   http://localhost:4000/health
echo Mail Inbox:   http://localhost:8025
echo.
echo Important:
echo - Set STORAGE_BASE_URL in .env to your private storage server
echo - Make sure your storage server contains HLS files
echo.

start "" "http://localhost:3000"

echo Press any key to close this window.
pause >nul
exit /b 0
