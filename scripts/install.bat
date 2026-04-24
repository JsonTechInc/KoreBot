@echo off
chcp 65001 >nul
cls

:: ==============================================
:: KoreBot + OpenClaw Auto Deploy Tool
:: ==============================================

:: Set base paths
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "NODE_DIR=%SCRIPT_DIR%nodejs"
set "GATEWAY_PORT=18789"

:: Use bundled Node.js and npm
set "PATH=%NODE_DIR%;%APPDATA%\npm;%PATH%"

:: Clean broken OpenClaw installation (FIXED SYNTAX, NO HANG)
echo [INFO] Cleaning old/corrupted OpenClaw...
call npm uninstall -g openclaw >nul 2>&1
if exist "%APPDATA%\npm\node_modules\openclaw" (
    rmdir /s /q "%APPDATA%\npm\node_modules\openclaw" >nul 2>&1
)
if exist "%USERPROFILE%\.openclaw" (
    rmdir /s /q "%USERPROFILE%\.openclaw" >nul 2>&1
)
call npm cache clean --force >nul 2>&1

:: Install fixed OpenClaw version
echo [INFO] Installing OpenClaw@2026.3.31...
call npm install -g openclaw@2026.3.31 --registry=https://registry.npmmirror.com
if errorlevel 1 (
    echo [ERROR] Installation failed
    pause
    exit /b 1
)

:: Create config folder
mkdir "%USERPROFILE%\.openclaw" >nul 2>&1

:: Generate token directly (NO HANGING COMMANDS)
echo [INFO] Creating gateway token...
(
echo {
echo   "gateway": {
echo     "auth": {
echo       "token": "auto-generated-by-script-1234567890"
echo     }
echo   }
echo }
) > "%USERPROFILE%\.openclaw\openclaw.json"
set "TOKEN=auto-generated-by-script-1234567890"

:: Show token and URL
echo.
echo ==============================================
echo GATEWAY TOKEN: %TOKEN%
echo DASHBOARD URL: http://localhost:%GATEWAY_PORT%/dashboard?token=%TOKEN%
echo ==============================================
echo.

:: Install gateway
echo [INFO] Installing gateway...
call openclaw gateway install --force >nul 2>&1

:: Start gateway IN BACKGROUND (NO NEW WINDOW)
taskkill /f /im node.exe >nul 2>&1
timeout /t 1 /nobreak >nul
start /B "" cmd /c "openclaw gateway --port=%GATEWAY_PORT% --allow-unconfigured >nul 2>&1"
timeout /t 3 /nobreak >nul

:: Start KoreBot
echo [INFO] Starting KoreBot...
cd /d "%PROJECT_DIR%"
if exist "package.json" (
    call npm run start
) else (
    echo [ERROR] package.json not found
    pause
    exit /b 1
)
