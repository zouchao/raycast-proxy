#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Proxy Status
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 📡
# @raycast.packageName OpenClash Proxy
# @raycast.description 查看当前代理模式与虚拟机连通性

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/proxy-lib.sh"

svc=$(active_service)
state=$(proxy_state "$svc")

case "$state" in
  off)    mode="❌ 关闭（系统代理未启用）" ;;
  global) mode="🌐 全局（HTTP/SOCKS → $PROXY_HOST:$HTTP_PORT/$SOCKS_PORT）" ;;
  pac)    mode="📜 PAC 规则模式" ;;
esac

echo "网络服务: $svc"
echo "代理模式: $mode"

if proxy_reachable; then
  rtt=$(ping -c 1 -t 2 "$PROXY_HOST" 2>/dev/null | awk -F'time=' '/time=/{print $2}' | awk '{print $1}')
  echo "虚拟机:   ✅ $PROXY_HOST 可达（${rtt:-?} ms）"
else
  echo "虚拟机:   ⚠️  $PROXY_HOST 不可达（虚拟机没开或 IP 变了）"
fi

if grep -q 'state: on' "$ENV_FILE" 2>/dev/null; then
  echo "终端 env: 已开启（新终端自动走代理）"
else
  echo "终端 env: 关闭"
fi

if vpn_primary; then
  echo "注意:     主服务被 VPN 抢占，系统代理对 GUI 应用无效；Chrome 用 Chrome with Proxy"
fi
