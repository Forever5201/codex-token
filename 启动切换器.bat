@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 正在启动 Codex 模型切换器…
echo.
where py >nul 2>nul
if %errorlevel%==0 (
    py -3 switcher.py
) else (
    python switcher.py
)
echo.
echo （窗口可关闭）
pause
