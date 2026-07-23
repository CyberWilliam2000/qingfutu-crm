@echo off
chcp 65001 >nul
setlocal

echo =========================================
echo   客户追踪看板 · 青蓝图
echo =========================================
echo.

:: Check Python
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 未找到 Python，请先安装 Python 3.8+
    echo    https://www.python.org/downloads/
    pause
    exit /b 1
)

python --version
echo.

echo 📦 检查依赖...
python -m pip install flask flask-cors openpyxl -q 2>nul

echo.
echo 🚀 启动服务...

:: Kill old process on 5000
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :5000 ^| findstr LISTENING 2^>nul') do (
    taskkill /F /PID %%a >nul 2>&1
)

start "" http://127.0.0.1:5000

python api_server.py

pause
