@echo off
chcp 65001 >nul
cls
echo ==================================================
echo KoreBot 一键安装 (Windows) - Node + OpenClaw 2026.3.31
echo ==================================================
echo.

:: ==============================
:: 1. 检查并安装 NVM for Windows
:: ==============================
nvm version >nul 2>&1
if %errorlevel% neq 0 (
    echo 👉 安装 NVM for Windows...
    curl -L -o nvm-setup.exe https://github.com/coreybutler/nvm-windows/releases/download/1.4.12/nvm-setup.exe
    start /wait nvm-setup.exe /S
    del nvm-setup.exe
    echo ✅ NVM 安装完成
    echo.
)

:: ==============================
:: 2. 安装 Node.js 24
:: ==============================
echo 👉 安装 Node.js 24...
nvm install 24
nvm use 24
nvm alias default 24
echo.

echo ✅ Node.js 版本:
node -v
echo ✅ npm 版本:
npm -v
echo.

:: ==============================
:: 3. 清理旧版 OpenClaw（修复 ENOTEMPTY）
:: ==============================
echo 👉 清理旧版 OpenClaw 残留...
npm uninstall -g openclaw >nul 2>&1
if exist "%APPDATA%\npm\node_modules\openclaw" (
    rmdir /s /q "%APPDATA%\npm\node_modules\openclaw"
)
if exist "%USERPROFILE%\.openclaw" (
    rmdir /s /q "%USERPROFILE%\.openclaw"
)
echo.

:: ==============================
:: 4. 安装 OpenClaw 固定版本
:: ==============================
echo 👉 安装 OpenClaw@2026.3.31...
npm install -g openclaw@2026.3.31 --registry=https://registry.npmmirror.com
echo.

:: ==============================
:: 5. 安装配置文件（从外部复制）
:: ==============================
echo ==================================================
echo 👉 安装 OpenClaw 配置文件
echo ==================================================
mkdir "%USERPROFILE%\.openclaw" >nul 2>&1
copy /y "openclaw.config.json" "%USERPROFILE%\.openclaw\openclaw.json"
echo ✅ 配置已安装
echo.

:: ==============================
:: 6. 安装网关服务
:: ==============================
echo 👉 安装网关服务...
openclaw gateway install --force
echo.

:: ==============================
:: 7. 重启网关
:: ==============================
echo ==================================================
echo  正在重启 OpenClaw 网关 (端口 18789)
echo ==================================================
taskkill /f /im node.exe >nul 2>&1
timeout /t 1 /nobreak >nul
start /b openclaw gateway --port 18789 --allow-unconfigured
timeout /t 3 /nobreak >nul
echo ✅ OpenClaw 网关已重启完成
echo.

:: ==============================
:: 8. 启动 KoreBot
:: ==============================
echo ==================================================
echo ✅ 全部安装完成！正在启动 KoreBot...
echo ==================================================
echo.
if exist start.bat (
    call start.bat
) else (
    echo 未找到 start.bat，按任意键退出
    pause >nul
)