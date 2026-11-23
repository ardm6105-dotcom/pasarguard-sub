#!/usr/bin/env bash
# نصب / حذف قالب صفحه اشتراک PasarGuard
# نصب:  curl -fsSL https://raw.githubusercontent.com/ardm6105-dotcom/pasarguard-sub/main/install.sh | sudo bash
# حذف:  ... | sudo bash -s -- --uninstall
set -euo pipefail

REPO="${REPO:-ardm6105-dotcom/pasarguard-sub}"   # <- نام کاربری گیت‌هاب / نام ریپو
BRANCH="${BRANCH:-main}"
ENV_FILE="${ENV_FILE:-/opt/pasarguard/.env}"
TPL_DIR="${TPL_DIR:-/var/lib/pasarguard/templates}"
TARGET="$TPL_DIR/subscription/index.html"
URL="https://raw.githubusercontent.com/$REPO/$BRANCH/index.html"

[ "$(id -u)" -eq 0 ] || { echo "با sudo اجرا کنید."; exit 1; }
[ -f "$ENV_FILE" ] || { echo "فایل $ENV_FILE پیدا نشد. مسیر را با ENV_FILE=... بدهید."; exit 1; }

set_env() {  # set_env KEY VALUE
  local k="$1" v="$2"
  if grep -qE "^[[:space:]]*$k=" "$ENV_FILE"; then
    sed -i -E "s|^[[:space:]]*$k=.*|$k=\"$v\"|" "$ENV_FILE"
  elif grep -qE "^[[:space:]]*#[[:space:]]*$k=" "$ENV_FILE"; then
    sed -i -E "0,/^[[:space:]]*#[[:space:]]*$k=.*/s||$k=\"$v\"|" "$ENV_FILE"
  else
    printf '\n%s="%s"\n' "$k" "$v" >> "$ENV_FILE"
  fi
}

restart() {
  if command -v pasarguard >/dev/null 2>&1; then pasarguard restart || true
  else echo "دستور pasarguard پیدا نشد؛ پنل را دستی ریستارت کنید."; fi
}

if [ "${1:-}" = "--uninstall" ]; then
  rm -f "$TARGET"
  sed -i -E 's|^([[:space:]]*)(SUBSCRIPTION_PAGE_TEMPLATE=.*)|# \2|' "$ENV_FILE"
  echo "قالب حذف شد."; restart; exit 0
fi

mkdir -p "$TPL_DIR/subscription"
[ -f "$TARGET" ] && cp "$TARGET" "$TARGET.bak"
curl -fsSL "$URL" -o "$TARGET"
set_env CUSTOM_TEMPLATES_DIRECTORY "$TPL_DIR/"
set_env SUBSCRIPTION_PAGE_TEMPLATE "subscription/index.html"
echo "قالب نصب شد: $TARGET"
restart
