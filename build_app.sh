#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="KillAll"
APP_DIR="$APP_NAME.app"

echo "==> Building release binary (swift build -c release)…"
swift build -c release

echo "==> Assembling $APP_DIR …"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp ".build/release/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "Info.plist" "$APP_DIR/Contents/Info.plist"

echo "==> Ad-hoc code signing…"
codesign --force --deep --sign - "$APP_DIR" || true

echo ""
echo "Done ✅  ->  $(pwd)/$APP_DIR"
echo "运行：  open ./$APP_DIR"
echo "菜单栏会出现一个图标，点击即可查看/杀掉后台开发进程。"
