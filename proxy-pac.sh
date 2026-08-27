#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle PAC Mode
# @raycast.mode compact
#
# Optional parameters:
# @raycast.icon 📜
# @raycast.packageName OpenClash Proxy
# @raycast.description 系统代理切到 OpenClash PAC 规则模式 / 关闭

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/proxy-lib.sh"

svc=$(active_service)

if [ "$(proxy_state "$svc")" = "pac" ]; then
  proxy_off "$svc"
  echo "PAC 已关闭（$svc）"
  exit 0
fi

if ! proxy_reachable; then
  echo "⚠️ $PROXY_HOST 不可达，iStoreOS 虚拟机开了吗？"
  exit 1
fi

proxy_on_pac "$svc"
echo "PAC 已开启（$svc）→ 按规则分流"
