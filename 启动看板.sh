#!/bin/bash
# 客户追踪看板 · 一键启动脚本
# 青蓝图

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "========================================="
echo "  客户追踪看板 · 青蓝图"
echo "========================================="
echo ""

# Check Python
PYTHON=""
for cmd in python3 python3.11 python; do
    if command -v $cmd &>/dev/null; then
        PYTHON=$cmd
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo "❌ 未找到 Python，请先安装 Python 3.8+"
    echo "   macOS: brew install python3"
    echo "   Ubuntu: sudo apt install python3 python3-pip"
    exit 1
fi

echo "✅ Python: $($PYTHON --version)"

# Install deps
echo "📦 检查依赖..."
$PYTHON -m pip install flask flask-cors openpyxl -q 2>/dev/null

echo ""
echo "🚀 启动服务..."

# Kill any old process on 5000
lsof -ti:5000 2>/dev/null | xargs -r kill -9 2>/dev/null || true

$PYTHON api_server.py &
sleep 2

echo ""
echo "========================================="
echo "  ✅ 服务已启动！"
echo ""
echo "  📋 浏览器打开："
echo "     http://127.0.0.1:5000"
echo ""
echo "  📁 数据文件："
echo "     客户追踪看板.xlsx"
echo ""
echo "  ⏹  按 Ctrl+C 停止服务"
echo "========================================="

# Keep alive
wait
