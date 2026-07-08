#!/bin/bash
# 发布用：编译通用二进制(arm64+x86_64) -> 组装 .app -> ad-hoc 签名 -> 打 zip -> 出 sha256
# 用法: ./release.sh [版本号]   例: ./release.sh 1.0.0
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="KillAll"
VERSION="${1:-1.0.0}"
APP_DIR="$APP_NAME.app"
DIST="dist"
ZIP="$DIST/$APP_NAME-$VERSION.zip"

echo "==> 通用二进制编译 (arm64 + x86_64)…"
swift build -c release --arch arm64 --arch x86_64

echo "==> 组装 $APP_DIR …"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp ".build/apple/Products/Release/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp Info.plist "$APP_DIR/Contents/Info.plist"
[ -f AppIcon.icns ] && cp AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns" || true

echo "==> ad-hoc 签名 (不签名分发)…"
codesign --force --deep --sign - "$APP_DIR"

echo "==> 校验架构:"
lipo -info "$APP_DIR/Contents/MacOS/$APP_NAME"

echo "==> 打包 -> $ZIP"
mkdir -p "$DIST"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP_DIR" "$ZIP"

echo ""
echo "产物: $(pwd)/$ZIP"
echo "sha256 (填进 cask 的 sha256):"
shasum -a 256 "$ZIP" | awk '{print "    "$1}'
