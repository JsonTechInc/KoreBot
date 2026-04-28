@echo off
chcp 65001 >nul
cls
title KoreBot + OpenClaw Auto Deploy Tool

:: ==============================================
:: Configuration
:: ==============================================
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "NODE_DIR=%SCRIPT_DIR%nodejs"
set "NODE_EXE=%NODE_DIR%\node.exe"
set "ZIP_FILE=%SCRIPT_DIR%nodejs.zip"
set "GATEWAY_PORT=18789"
set "PROJECT_CONFIG=%PROJECT_DIR%\openclaw.json"

:: ==============================================
:: Check and install Node.js
:: ==============================================
echo ==============================================
echo Checking Node.js...
echo ==============================================

if exist "%NODE_EXE%" (
    echo [OK] Node.js detected, checking version...
    "%NODE_EXE%" -v | findstr /r /c:"v22\.1[4-9]\." /c:"v22\.[2-9][0-9]\." /c:"v2[3-9]\." >nul
    if %errorlevel% equ 0 (
        echo [OK] Node.js version OK
        goto SET_PATH
    ) else (
        echo [WARNING] Upgrading Node.js...
        rmdir /s /q "%NODE_DIR%" >nul 2>&1
    )
)

echo [INFO] Downloading Node.js v22.14.0...
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v22.14.0/node-v22.14.0-win-x64.zip' -OutFile '%ZIP_FILE%'"
if not exist "%ZIP_FILE%" (
    echo [ERROR] Node.js download failed
    pause
    exit /b 1
)

echo [INFO] Extracting Node.js...
powershell -NoProfile -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%SCRIPT_DIR%' -Force"
if not exist "%NODE_DIR%\node.exe" (
    :: Try alternative extraction path
    if exist "%SCRIPT_DIR%node-v22.14.0-win-x64" (
        ren "%SCRIPT_DIR%node-v22.14.0-win-x64" "nodejs"
    ) else (
        echo [ERROR] Node.js extraction failed
        pause
        exit /b 1
    )
)

del "%ZIP_FILE%" >nul 2>&1

:SET_PATH
:: Use bundled Node.js
set "PATH=%NODE_DIR%;%NODE_DIR%\node_modules\.bin;%APPDATA%\npm;%PATH%"

echo [OK] Node.js ready:
"%NODE_EXE%" -v
echo.

:: ==============================================
:: Generate random token
:: ==============================================
echo [INFO] Generating random gateway token...
set "RANDOM_TOKEN=%random%%random%%random%%random%"
set "TOKEN=auto-%RANDOM_TOKEN%"

:: ==============================================
:: Clean old installation (PRESERVE .openclaw)
:: ==============================================
echo.
echo ==============================================
echo Cleaning old OpenClaw installation...
echo ==============================================
call npm uninstall -g openclaw >nul 2>&1
if exist "%APPDATA%\npm\node_modules\openclaw" (
    rmdir /s /q "%APPDATA%\npm\node_modules\openclaw" >nul 2>&1
)
call npm cache clean --force >nul 2>&1

:: ==============================================
:: Install OpenClaw
:: ==============================================
echo.
echo ==============================================
echo Installing OpenClaw@2026.3.31...
echo ==============================================
call npm install -g openclaw@2026.3.31 --registry=https://registry.npmmirror.com
if errorlevel 1 (
    echo [ERROR] Installation failed
    pause
    exit /b 1
)

:: ==============================================
:: Create OpenClaw configuration
:: ==============================================
echo [INFO] Creating OpenClaw configuration...
mkdir "%USERPROFILE%\.openclaw" >nul 2>&1

:: Copy openclaw.json from script directory to user directory
copy "%SCRIPT_DIR%openclaw.json" "%USERPROFILE%\.openclaw\openclaw.json" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to copy openclaw.json
    pause
    exit /b 1
)

:: Replace token placeholder with generated token
powershell -NoProfile -Command "(Get-Content '%USERPROFILE%\.openclaw\openclaw.json') -replace 'auto-demo-token', '%TOKEN%' | Set-Content '%USERPROFILE%\.openclaw\openclaw.json'"
echo [INFO] Updated openclaw.json with gateway token

:: Create agent auth config directory
mkdir "%USERPROFILE%\.openclaw\agents\main" >nul 2>&1

:: ==============================================
:: Show info
:: ==============================================
echo.
echo ==============================================
echo Deployment Complete!
echo ==============================================
echo GATEWAY TOKEN: %TOKEN%
echo DASHBOARD URL: http://localhost:%GATEWAY_PORT%/dashboard?token=%TOKEN%
echo CHAT URL: http://localhost:%GATEWAY_PORT%/chat
echo ==============================================
echo.

:: ==============================================
:: Start gateway
:: ==============================================
echo [INFO] Starting gateway...
call openclaw gateway install --force >nul 2>&1

:: Kill old node processes (without killing this script)
taskkill /f /im node.exe /fi "windowtitle ne %~nx0" >nul 2>&1
timeout /t 1 /nobreak >nul

:: Start gateway in background
start /B cmd /c "openclaw gateway --port=%GATEWAY_PORT% --allow-unconfigured >nul 2>&1"
timeout /t 3 /nobreak >nul

:: ==============================================
:: Start KoreBot
:: ==============================================
echo.
echo ==============================================
echo Starting KoreBot...
echo ==============================================
cd /d "%PROJECT_DIR%"
if not exist "package.json" (
    echo [ERROR] package.json not found in project directory
    pause
    exit /b 1
)

call npm run start

echo.
echo [INFO] KoreBot has stopped
pause
