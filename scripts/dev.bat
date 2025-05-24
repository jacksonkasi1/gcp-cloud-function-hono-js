@echo off
REM =============================================================================
REM Local Development Server Script for Windows
REM =============================================================================
REM This script starts the Hono.js application in development mode
REM =============================================================================

setlocal enabledelayedexpansion

echo.
echo 🚀 Starting Hono.js Development Server
echo =====================================
echo.

REM Configuration
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
if "%PORT%"=="" set "PORT=8080"

echo Project Root: %PROJECT_ROOT%
echo Port: %PORT%
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Node.js is not installed or not in PATH
    pause
    exit /b 1
)

REM Get Node.js version
for /f "tokens=*" %%i in ('node --version') do set "NODE_VERSION=%%i"
set "NODE_VERSION=%NODE_VERSION:v=%"

echo ✅ Node.js version: %NODE_VERSION%

REM Change to project root
cd /d "%PROJECT_ROOT%"

REM Check if dependencies are installed
if not exist "node_modules" (
    echo 📦 Installing dependencies...
    npm install
)

echo.
echo 🌐 Server will be available at:
echo    http://localhost:%PORT%
echo    http://localhost:%PORT%/health ^(Health Check^)
echo    http://localhost:%PORT%/api/users ^(Users API^)
echo.
echo Press Ctrl+C to stop the server
echo.

REM Set environment variables for development
set "NODE_ENV=development"

REM Start the development server
npm run dev

pause