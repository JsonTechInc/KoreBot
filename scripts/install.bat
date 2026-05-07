@echo off
chcp 65001 >nul
cls
title KoreBot + OpenClaw Auto Deploy Tool

:::: ==============================================
:::: Configuration (EDIT THIS)
:::: ==============================================
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "NODE_DIR=%SCRIPT_DIR%nodejs"
set "NODE_EXE=%NODE_DIR%\node.exe"
set "ZIP_FILE=%SCRIPT_DIR%nodejs.zip"
set "GATEWAY_PORT=18789"
set "TMPL_DIR=%SCRIPT_DIR%templates"

:::: PUT YOUR ZHIPU API KEY HERE
set "ZHIPU_API_KEY=379fb6bd069b60bc4523759e43e990f7.EDRWe3mpilKMWvj1"

:::: ==============================================
:::: Check and install Node.js
:::: ==============================================
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

:::: ==============================================
:::: Generate random token
:::: ==============================================
echo [INFO] Generating gateway token...
set "RANDOM_TOKEN=%random%%random%%random%%random%"
set "TOKEN=auto-%RANDOM_TOKEN%"
echo [INFO] Gateway token: %TOKEN%

:::: ==============================================
:::: Check API Key
:::: ==============================================
if "%ZHIPU_API_KEY%"=="your_api_key_here" (
    echo [ERROR] Please edit install.bat and set your ZHIPU_API_KEY first!
    echo You can get a key from: https://open.bigmodel.cn/
    pause
    exit /b 1
)
echo [INFO] API Key loaded (first 8 chars: %ZHIPU_API_KEY:~0,8%...)

:::: ==============================================
:::: Clean old installation (PRESERVE .openclaw)
:::: ==============================================
echo.
echo =============================================
echo Cleaning old OpenClaw installation...
echo =============================================

call npm uninstall -g openclaw >nul 2>&1
if exist "%NODE_DIR%\node_modules\openclaw" (
    rmdir /s /q "%NODE_DIR%\node_modules\openclaw" >nul 2>&1
)
if exist "%APPDATA%\npm\node_modules\openclaw" (
    rmdir /s /q "%APPDATA%\npm\node_modules\openclaw" >nul 2>&1
)
call npm cache clean --force >nul 2>&1

:::: ==============================================
:::: Install OpenClaw
:::: ==============================================
echo.
echo =============================================
echo Installing OpenClaw@2026.3.31...
echo =============================================
call npm install -g openclaw@2026.3.31 --registry=https://registry.npmmirror.com --legacy-peer-deps
if errorlevel 1 (
    echo [ERROR] Installation failed
    pause
    exit /b 1
)

:::: Install missing peer dependencies for bundled extensions (Slack, AWS Bedrock)
:::: Without these, HTTP 500 on all endpoints due to dynamic import failures
echo [INFO] Installing missing peer dependencies for bundled extensions...
if exist "%NODE_DIR%\node_modules\openclaw" (
    pushd "%NODE_DIR%\node_modules\openclaw"
    call npm install @slack/web-api @slack/bolt @aws-sdk/client-bedrock --registry=https://registry.npmmirror.com --legacy-peer-deps
    popd
    echo [OK] Peer dependencies installed
) else if exist "%APPDATA%\npm\node_modules\openclaw" (
    pushd "%APPDATA%\npm\node_modules\openclaw"
    call npm install @slack/web-api @slack/bolt @aws-sdk/client-bedrock --registry=https://registry.npmmirror.com --legacy-peer-deps
    popd
    echo [OK] Peer dependencies installed
) else (
    echo [WARNING] OpenClaw package directory not found, skipping peer deps
)

:::: Verify installation
set "OPENCLAW_MJS="
if exist "%NODE_DIR%\node_modules\openclaw\openclaw.mjs" (
    set "OPENCLAW_MJS=%NODE_DIR%\node_modules\openclaw\openclaw.mjs"
) else if exist "%APPDATA%\npm\node_modules\openclaw\openclaw.mjs" (
    set "OPENCLAW_MJS=%APPDATA%\npm\node_modules\openclaw\openclaw.mjs"
)
if "%OPENCLAW_MJS%"=="" (
    echo [ERROR] OpenClaw module not found after installation
    echo [HINT] Try running: npm install -g openclaw@2026.3.31 --registry=https://registry.npmmirror.com
    pause
    exit /b 1
)
echo [OK] OpenClaw installed at: %OPENCLAW_MJS%

:::: ==============================================
:::: Create OpenClaw configuration
:::: ==============================================
echo.
echo =============================================
echo Creating OpenClaw configuration...
echo =============================================

:::: 1. Copy openclaw.json template and replace placeholders
mkdir "%USERPROFILE%\.openclaw" >nul 2>&1
if not exist "%USERPROFILE%\.openclaw\openclaw.json" (
    copy /Y "%TMPL_DIR%\..\openclaw.json" "%USERPROFILE%\.openclaw\openclaw.json" >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Failed to copy openclaw.json
        pause
        exit /b 1
    )
) else (
    echo [OK] openclaw.json already exists, preserving
)
echo [INFO] Replacing placeholders in openclaw.json...
powershell -NoProfile -Command "$f='%USERPROFILE%\.openclaw\openclaw.json';$c=[IO.File]::ReadAllText($f);if($c.Contains('auto-demo-token')){$c=$c.Replace('auto-demo-token','%TOKEN%')};$ws=('%USERPROFILE%\.openclaw\workspace').Replace('\','\\\\');$c=$c.Replace('USERPROFILE_PLACEHOLDER',$ws);$c=$c.Replace('ZHIPU_API_KEY_PLACEHOLDER','%ZHIPU_API_KEY%');[IO.File]::WriteAllText($f,$c,[Text.UTF8Encoding]::new($false))"
echo [OK] openclaw.json updated

:::: 2. Create workspace directory
mkdir "%USERPROFILE%\.openclaw\workspace" >nul 2>&1
echo [OK] Workspace directory ready

:::: 3. Create agent config directory
mkdir "%USERPROFILE%\.openclaw\agents\main\agent" >nul 2>&1

:::: 4. Copy agent.json template (no placeholders, just copy)
if not exist "%USERPROFILE%\.openclaw\agents\main\agent\agent.json" (
    copy /Y "%TMPL_DIR%\agent.json" "%USERPROFILE%\.openclaw\agents\main\agent\agent.json" >nul 2>&1
    echo [OK] agent.json created
) else (
    echo [OK] agent.json already exists, skipped
)

:::: 5. Copy models.json template (no placeholders, just copy)
if not exist "%USERPROFILE%\.openclaw\agents\main\agent\models.json" (
    copy /Y "%TMPL_DIR%\models.json" "%USERPROFILE%\.openclaw\agents\main\agent\models.json" >nul 2>&1
    echo [OK] models.json created
) else (
    echo [OK] models.json already exists, skipped
)

:::: 6. Copy auth-profiles.json template and replace API key placeholder
echo [INFO] Creating auth-profiles.json...
copy /Y "%TMPL_DIR%\auth-profiles.json" "%USERPROFILE%\.openclaw\agents\main\agent\auth-profiles.json" >nul 2>&1
powershell -NoProfile -Command "$f='%USERPROFILE%\.openclaw\agents\main\agent\auth-profiles.json';$c=[IO.File]::ReadAllText($f);$c=$c.Replace('ZHIPU_API_KEY_PLACEHOLDER','%ZHIPU_API_KEY%');[IO.File]::WriteAllText($f,$c,[Text.UTF8Encoding]::new($false))"
echo [OK] auth-profiles.json created

:::: ==============================================
:::: Add node and openclaw to user PATH
:::: ==============================================
echo [INFO] Adding node and openclaw to user PATH...
powershell -NoProfile -Command "$nodeDir='%SCRIPT_DIR%nodejs'; $npmDir='%APPDATA%\npm'; $path=[Environment]::GetEnvironmentVariable('PATH','User'); if(-not $path.Contains($nodeDir)){[Environment]::SetEnvironmentVariable('PATH', $nodeDir + ';' + $npmDir + ';' + $path, 'User')}; Write-Host 'PATH updated'"
echo [OK] Environment variables updated. Please restart your terminal for changes to take effect.

:::: ==============================================
:::: Show info
:::: ==============================================
echo.
echo =============================================
echo Deployment Complete!
echo =============================================
echo GATEWAY TOKEN: %TOKEN%
echo DASHBOARD URL: http://localhost:%GATEWAY_PORT%/dashboard?token=%TOKEN%
echo CHAT URL: http://localhost:%GATEWAY_PORT%/chat?token=%TOKEN%
echo =============================================
echo.

:::: ==============================================
:::: Start gateway
:::: ==============================================
echo [INFO] Starting gateway...

:::: Kill old gateway process on this port only
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%GATEWAY_PORT% " ^| findstr "LISTENING"') do (
    echo [INFO] Killing old gateway process PID %%p
    taskkill /f /pid %%p >nul 2>&1
)
timeout /t 2 /nobreak >nul

:::: Start gateway using node.exe directly
start "OpenClaw Gateway" /B "%NODE_EXE%" "%OPENCLAW_MJS%" gateway --port=%GATEWAY_PORT% --allow-unconfigured
timeout /t 5 /nobreak >nul

:::: Verify gateway is running
netstat -ano | findstr ":%GATEWAY_PORT% " | findstr "LISTENING" >nul
if errorlevel 1 (
    echo [WARNING] Gateway may not have started. Try running: start.bat
) else (
    echo [OK] Gateway is running on port %GATEWAY_PORT%
)

echo.
echo [INFO] Installation complete. Use start.bat to launch the gateway next time.
pause
