#!/usr/bin/env bash
# 本地打包脚本（macOS / Linux）：把 CrossDeskMobile.app 打包为未签名 IPA。
# 用法：bash scripts/package-ipa.sh [app_path] [out_dir]
# 仅打包不签名；签名请使用 GitHub Actions 的 signed 模式。
set -euo pipefail

APP_PATH="${1:-CrossDeskMobile.app}"
OUT_DIR="${2:-dist}"
APP_NAME="CrossDeskMobile"

[ -d "$APP_PATH" ] || { echo "找不到应用包: $APP_PATH" >&2; exit 1; }

# 读取版本号（PlistBuddy 为 macOS 自带；Linux 退化为 plutil 或默认值）
VERSION="0.0.0"
if [ -x /usr/libexec/PlistBuddy ]; then
  VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Info.plist" 2>/dev/null || echo "$VERSION")"
elif command -v plutil >/dev/null 2>&1; then
  VERSION="$(plutil -extract CFBundleShortVersionString raw "$APP_PATH/Info.plist" 2>/dev/null || echo "$VERSION")"
fi

# 读取架构（macOS 用 lipo；失败则默认 arm64）
ARCH="arm64"
if command -v lipo >/dev/null 2>&1; then
  ARCH="$(lipo -archs "$APP_PATH/$APP_NAME" 2>/dev/null | awk '{print $1}')"
  [ -n "$ARCH" ] || ARCH="arm64"
fi

mkdir -p "$OUT_DIR"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
mkdir -p "$STAGING/Payload"
cp -R "$APP_PATH" "$STAGING/Payload/"

OUT_DIR_ABS="$(cd "$OUT_DIR" && pwd)"
IPA="$OUT_DIR_ABS/${APP_NAME}-${VERSION}-${ARCH}-unsigned.ipa"
(cd "$STAGING" && zip -qry "$IPA" Payload)

# 校验
unzip -t "$IPA" >/dev/null
echo ""
echo "✅ 已生成: $IPA"
unzip -l "$IPA" | sed -n '1,6p'
