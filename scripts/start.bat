@echo off
chcp 65001 >nul
cls
title KoreBot + OpenClaw Gateway

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "NODE_DIR=%SCRIPT_DIR%nodejs"
set "NODE_EXE=%NODE_DIR%\node.exe"
set "GATEWAY_PORT=18789"

:::: Add node to PATH
if exist "%NODE_EXE%" (
    set "PATH=%NODE_DIR%;%NODE_DIR%\node_modules\.bin;%APPDATA%\npm;%PATH%"
)

:::: Check if openclaw is installed (check NODE_DIR first, then APPDATA)
set "OPENCLAW_MJS="
if exist "%NODE_DIR%\node_modules\openclaw\openclaw.mjs" (
    set "OPENCLAW_MJS=%NODE_DIR%\node_modules\openclaw\openclaw.mjs"
) else if exist "%APPDATA%\npm\node_modules\openclaw\openclaw.mjs" (
    set "OPENCLAW_MJS=%APPDATA%\npm\node_modules\openclaw\openclaw.mjs"
)
if "%OPENCLAW_MJS%"=="" (
    echo [ERROR] OpenClaw not found. Please run install.bat first.
    pause
    exit /b 1
)

:::: Check if openclaw.json exists
if not exist "%USERPROFILE%\.openclaw\openclaw.json" (
    echo [ERROR] OpenClaw config not found. Please run install.bat first.
    pause
    exit /b 1
)

:::: Kill old gateway process on this port only
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%GATEWAY_PORT% " ^| findstr "LISTENING"') do (
    echo [INFO] Stopping old gateway process PID %%p
    taskkill /f /pid %%p >nul 2>&1
)
timeout /t 2 /nobreak >nul

:::: Start OpenClaw Gateway
echo ==================================================
echo  Starting OpenClaw Gateway (port %GATEWAY_PORT%)
echo ==================================================
start "OpenClaw Gateway" /B "%NODE_EXE%" "%OPENCLAW_MJS%" gateway --port=%GATEWAY_PORT% --allow-unconfigured
timeout /t 5 /nobreak >nul

:::: Verify
netstat -ano | findstr ":%GATEWAY_PORT% " | findstr "LISTENING" >nul
if errorlevel 1 (
    echo [ERROR] Gateway failed to start on port %GATEWAY_PORT%
    pause
    exit /b 1
) else (
    echo [OK] Gateway is running on port %GATEWAY_PORT%
)

::::: Read token from config
for /f "delims=" %%v in ('powershell -NoProfile -Command "(Get-Content '%USERPROFILE%\.openclaw\openclaw.json' -Raw|ConvertFrom-Json).gateway.auth.token" 2^>nul') do set "TOKEN=%%v"

echo.
echo ==================================================
echo  Gateway Ready!
echo ==================================================
echo  Dashboard: http://localhost:%GATEWAY_PORT%/dashboard?token=%TOKEN%
echo  Chat:      http://localhost:%GATEWAY_PORT%/chat?token=%TOKEN%
echo ==================================================
echo.
echo  Press Ctrl+C to stop the gateway
echo.

:::: Keep the window alive - the gateway runs as a child process
:::: Wait for it to exit or user to press Ctrl+C
:LOOP
timeout /t 60 /nobreak >nul
:::: Check if gateway is still running
netstat -ano | findstr ":%GATEWAY_PORT% " | findstr "LISTENING" >nul
if errorlevel 1 (
    echo [WARNING] Gateway process has stopped.
    pause
    exit /b 1
)
goto LOOP
