@echo off
setlocal

cd /d "%~dp0"
title StreamVault Platform Stopper

echo Stopping StreamVault platform...
docker compose -f infra\docker\docker-compose.yml down

echo.
echo Platform stopped.
pause
exit /b 0
