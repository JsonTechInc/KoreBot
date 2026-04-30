@echo off
chcp 65001 >nul
cls
title KoreBot + OpenClaw Auto Deploy Tool

::: ==============================================
::: Configuration (EDIT THIS)
::: ==============================================
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "NODE_DIR=%SCRIPT_DIR%nodejs"
set "NODE_EXE=%NODE_DIR%\node.exe"
set "ZIP_FILE=%SCRIPT_DIR%nodejs.zip"
set "GATEWAY_PORT=18789"

::: PUT YOUR ZHIPU API KEY HERE
set "ZHIPU_API_KEY=379fb6bd069b60bc4523759e43e990f7.EDRWe3mpilKMWvj1"

::: ==============================================
::: Check and install Node.js
::: ==============================================
echo.
echo =============================================
echo Checking Node.js...
echo =============================================

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
set "PATH=%NODE_DIR%;%NODE_DIR%\node_modules\.bin;%APPDATA%\npm;%PATH%"

echo [OK] Node.js ready:
"%NODE_EXE%" -v
echo.

::: ==============================================
::: Generate random token
::: ==============================================
echo [INFO] Generating random gateway token...
set "RANDOM_TOKEN=%random%%random%%random%%random%"
set "TOKEN=auto-%RANDOM_TOKEN%"

::: ==============================================
::: Check API Key
::: ==============================================
if "%ZHIPU_API_KEY%"=="your_api_key_here" (
    echo [ERROR] Please edit install.bat and set your ZHIPU_API_KEY first!
    echo You can get a key from: https://open.bigmodel.cn/
    pause
    exit /b 1
)
echo [INFO] API Key loaded (first 8 chars: %ZHIPU_API_KEY:~0,8%...)

::: ==============================================
::: Clean old installation (PRESERVE .openclaw)
::: ==============================================
echo.
echo =============================================
echo Cleaning old OpenClaw installation...
echo =============================================
call npm uninstall -g openclaw >nul 2>&1
if exist "%APPDATA%\npm\node_modules\openclaw" (
    rmdir /s /q "%APPDATA%\npm\node_modules\openclaw" >nul 2>&1
)
call npm cache clean --force >nul 2>&1

::: ==============================================
::: Install OpenClaw
::: ==============================================
echo.
echo =============================================
echo Installing OpenClaw@2026.3.31...
echo =============================================
call npm install -g openclaw@2026.3.31 --registry=https://registry.npmmirror.com
if errorlevel 1 (
    echo [ERROR] Installation failed
    pause
    exit /b 1
)

::: ==============================================
::: Create OpenClaw configuration
::: ==============================================
echo [INFO] Creating OpenClaw configuration...
mkdir "%USERPROFILE%\.openclaw" >nul 2>&1

::: Copy openclaw.json from script directory to user directory
copy "%SCRIPT_DIR%openclaw.json" "%USERPROFILE%\.openclaw\openclaw.json" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to copy openclaw.json
    pause
    exit /b 1
)

::: Replace token and userprofile placeholders (use semicolons to chain replacements)
powershell -NoProfile -Command "$up='%USERPROFILE%' -replace '\\', '\\'; $c=Get-Content '%USERPROFILE%\.openclaw\openclaw.json' -Raw; $c=$c -replace 'auto-demo-token','%TOKEN%'; $c=$c -replace 'USERPROFILE_PLACEHOLDER',($up+'\\.openclaw\\workspace'); Set-Content '%USERPROFILE%\.openclaw\openclaw.json' -Value $c -Encoding UTF8"
echo [INFO] Updated openclaw.json with gateway token and workspace path

::: Create agent config directory
mkdir "%USERPROFILE%\.openclaw\agents\main\agent" >nul 2>&1

::: Create agent.json
if not exist "%USERPROFILE%\.openclaw\agents\main\agent\agent.json" (
    echo [INFO] Creating agent.json...
    powershell -NoProfile -Command "[System.IO.File]::WriteAllText('%USERPROFILE%\.openclaw\agents\main\agent\agent.json', '{\"version\":1,\"model\":{\"provider\":\"zai\",\"model\":\"glm-4.5-flash\"}}', [System.Text.Encoding]::UTF8)"
)

::: Create models.json
if not exist "%USERPROFILE%\.openclaw\agents\main\agent\models.json" (
    echo [INFO] Creating models.json...
    powershell -NoProfile -Command "[System.IO.File]::WriteAllText('%USERPROFILE%\.openclaw\agents\main\agent\models.json', '{\"providers\":{\"zai\":{\"baseUrl\":\"https://open.bigmodel.cn/api/paas/v4\",\"api\":\"openai-completions\",\"models\":[{\"id\":\"glm-4.5-flash\",\"name\":\"GLM-4.5 Flash\",\"reasoning\":true,\"input\":[\"text\"],\"cost\":{\"input\":0,\"output\":0,\"cacheRead\":0,\"cacheWrite\":0},\"contextWindow\":131072,\"maxTokens\":98304,\"api\":\"openai-completions\"},{\"id\":\"glm-5\",\"name\":\"GLM-5\",\"reasoning\":true,\"input\":[\"text\"],\"cost\":{\"input\":1,\"output\":3.2,\"cacheRead\":0.2,\"cacheWrite\":0},\"contextWindow\":202800,\"maxTokens\":131100,\"api\":\"openai-completions\"}]}}}', [System.Text.Encoding]::UTF8)"
)

::: Create auth-profiles.json (force overwrite to ensure correct content)
echo [INFO] Creating auth-profiles.json...
powershell -NoProfile -Command "[System.IO.File]::WriteAllText('%USERPROFILE%\.openclaw\agents\main\agent\auth-profiles.json', '{\"version\":1,\"profiles\":{\"zai:default\":{\"type\":\"api_key\",\"provider\":\"zai\",\"key\":\"%ZHIPU_API_KEY%\"}},\"lastGood\":{\"zai\":\"zai:default\"},\"usageStats\":{\"zai:default\":{\"errorCount\":0,\"lastUsed\":0}}}', [System.Text.Encoding]::UTF8)"
echo [OK] auth-profiles.json created

::: ==============================================
::: Add node and openclaw to user PATH
::: ==============================================
echo [INFO] Adding node and openclaw to user PATH...
powershell -NoProfile -Command "$nodeDir='%SCRIPT_DIR%nodejs'; $npmDir='%APPDATA%\npm'; $path=[Environment]::GetEnvironmentVariable('PATH','User'); if(-not $path.Contains($nodeDir)){[Environment]::SetEnvironmentVariable('PATH', $nodeDir + ';' + $npmDir + ';' + $path, 'User')}; Write-Host 'PATH updated'"
echo [OK] Environment variables updated. Please restart your terminal for changes to take effect.

::: ==============================================
::: Show info
::: ==============================================
echo.
echo =============================================
echo Deployment Complete!
echo =============================================
echo GATEWAY TOKEN: %TOKEN%
echo DASHBOARD URL: http://localhost:%GATEWAY_PORT%/dashboard?token=%TOKEN%
echo CHAT URL: http://localhost:%GATEWAY_PORT%/chat
echo =============================================
echo.

::: ==============================================
::: Start gateway
::: ==============================================
echo [INFO] Starting gateway...
call openclaw gateway install --force >nul 2>&1

::: Kill old node processes
taskkill /f /im node.exe >nul 2>&1
timeout /t 1 /nobreak >nul

::: Start gateway in background
start /B cmd /c "openclaw gateway --port=%GATEWAY_PORT% --allow-unconfigured >nul 2>&1"
timeout /t 3 /nobreak >nul

::: ==============================================
::: Start KoreBot
::: ==============================================
echo.
echo =============================================
echo Starting KoreBot...
echo =============================================
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
