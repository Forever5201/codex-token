#!/bin/bash
# 双击运行：启动 Codex 模型切换器本地网页
cd "$(dirname "$0")"
echo "正在启动 Codex 模型切换器…"
python3 switcher.py
echo
echo "（窗口可关闭）"
read -n 1 -s
