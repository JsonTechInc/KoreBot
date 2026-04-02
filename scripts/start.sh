#!/bin/bash

# echo ""
# echo "=================================================="
# echo " 启动 KoreBot 后端 (端口 32451)"
# echo "=================================================="
# node server/index.js >/dev/null 2>&1 &
# sleep 2

# echo "=================================================="
# echo " 启动 KoreBot 前端 (端口 43126)"
# echo "=================================================="
# cd client
# if [ ! -d "node_modules" ]; then
#   echo "📦 安装前端依赖..."
#   npm install --registry=https://registry.npmmirror.com
# fi
# npm run dev