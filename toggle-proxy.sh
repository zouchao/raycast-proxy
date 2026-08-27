#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Proxy
# @raycast.mode compact
#
# Optional parameters:
# @raycast.icon 🌐
# @raycast.packageName OpenClash Proxy
# @raycast.description 一键开关系统代理（全局模式 → iStoreOS 虚拟机）

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/proxy-lib.sh"

svc=$(active_service)
state=$(proxy_state "$svc")

if [ "$state" != "off" ]; then
  proxy_off "$svc"
  write_env_file off
  echo "代理已关闭（$svc）"
  exit 0
fi

if ! proxy_reachable; then
  echo "⚠️ $PROXY_HOST:$HTTP_PORT 不可达，iStoreOS 虚拟机开了吗？"
  exit 1
fi

proxy_on_global "$svc"
write_env_file on
if vpn_primary; then
  echo "代理已开启（$svc）→ $PROXY_HOST:$HTTP_PORT ｜VPN 抢占主服务，Chrome 请用 Chrome with Proxy"
else
  echo "代理已开启（$svc）→ $PROXY_HOST:$HTTP_PORT"
fi
