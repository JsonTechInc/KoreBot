@echo off
cls
echo ==================================================
echo  启动 OpenClaw 网关 (端口 18789)
echo ==================================================
start /b openclaw gateway --port 18789
timeout /t 3 /nobreak >nul

echo ==================================================
echo  启动 KoreBot 后端 (端口 32451)
echo ==================================================
start /b node server/index.js
timeout /t 2 /nobreak >nul

echo ==================================================
echo  启动 KoreBot 前端 (Vue3, 端口 43126)
echo ==================================================
cd client
if not exist node_modules (
  echo 安装前端依赖...
  npm install --registry=https://registry.npmmirror.com
)
npm run dev