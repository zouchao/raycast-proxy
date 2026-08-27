#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Chrome with Proxy
# @raycast.mode compact
#
# Optional parameters:
# @raycast.icon 🧭
# @raycast.packageName OpenClash Proxy
# @raycast.description 带显式代理参数启动 Chrome（VPN 抢占主服务时用）

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/proxy-lib.sh"

if pgrep -x "Google Chrome" >/dev/null 2>&1; then
  echo "⚠️ Chrome 在运行，请先 ⌘Q 完全退出再执行"
  exit 1
fi

if ! proxy_reachable; then
  echo "⚠️ $PROXY_HOST:$HTTP_PORT 不可达，iStoreOS 虚拟机开了吗？"
  exit 1
fi

bypass=$(IFS=\;; echo "${BYPASS_DOMAINS[*]}")
open -na "Google Chrome" --args \
  --proxy-server="http=$PROXY_HOST:$HTTP_PORT;https=$PROXY_HOST:$HTTP_PORT;socks=$PROXY_HOST:$SOCKS_PORT" \
  --proxy-bypass-list="$bypass"
echo "Chrome 已启动（代理 → $PROXY_HOST:$HTTP_PORT）"
