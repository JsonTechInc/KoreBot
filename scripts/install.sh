#!/bin/bash
clear
echo "=================================================="
echo " KoreBot 一键安装 —— 自动安装 Node + OpenClaw 2026.3.31"
echo "=================================================="

# 安装 nvm + Node.js 24
if ! command -v node &> /dev/null; then
  echo "👉 安装 nvm & Node.js 24..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  \. "$HOME/.nvm/nvm.sh"
  nvm install 24
  nvm use 24
  nvm alias default 24
fi

echo "✅ Node.js 版本: $(node -v)"
echo "✅ npm 版本: $(npm -v)"

# ==============================
# 🔥 修复 ENOTEMPTY 报错
# ==============================
echo ""
echo "👉 清理旧版 OpenClaw 残留..."
npm uninstall -g openclaw >/dev/null 2>&1
rm -rf "$(npm root -g)/openclaw" >/dev/null 2>&1
rm -rf "$HOME/.openclaw" >/dev/null 2>&1

# 安装 OpenClaw@2026.3.31
echo "👉 安装 OpenClaw@2026.3.31..."
npm install -g openclaw@2026.3.31 --registry=https://registry.npmmirror.com

# 复制配置（从外部文件复制）
echo ""
echo "=================================================="
echo "👉 安装 OpenClaw 配置文件"
echo "=================================================="

mkdir -p ~/.openclaw
cd "$(dirname "$0")"
cp -f openclaw.config.json ~/.openclaw/openclaw.json

echo "✅ 配置已安装"

# 安装网关服务
echo "👉 安装网关服务..."
openclaw gateway install --force

# 重启网关
echo "=================================================="
echo " 正在重启 OpenClaw 网关"
echo "=================================================="

pkill -f "openclaw" 2>/dev/null
sleep 1
openclaw gateway --port 18789 --allow-unconfigured &
sleep 3

echo "✅ OpenClaw 网关已重启完成"

echo ""
echo "=================================================="
echo " ✅ 全部安装完成！正在启动 KoreBot..."
echo "=================================================="
echo ""

chmod +x start.sh
./start.sh