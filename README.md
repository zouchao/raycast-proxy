# raycast-proxy

一键切换代理的 Raycast 脚本工具集。代理端点是 iStoreOS 虚拟机里的 OpenClash（在禁止安装 ClashX 类软件的 Mac 上的替代方案），纯 bash、零依赖。

```
Mac（本机）
 ├─ 系统代理 / 终端 env ──▶ 192.168.64.2:7890 (HTTP) / :7891 (SOCKS)
 └─ PAC 规则模式 ─────────▶ http://192.168.64.2/luci-static/resources/openclash/pac/...
```

## 虚拟机侧安装（iStoreOS + OpenClash）

以 UTM（免费、Apple Silicon / Intel 通用）为例；Parallels / VMware Fusion 同理，关键是网络选**共享/NAT 模式**。

### 1. 安装 UTM

```bash
brew install --cask utm   # 或官网 utmapp.com 下载安装
```

### 2. 下载 iStoreOS 镜像

官网 istoreos.com → 下载中心：

- Apple Silicon Mac：`aarch64` EFI 版镜像
- Intel Mac：`x86_64` EFI 版镜像

### 3. 创建虚拟机

1. UTM → Create a New Virtual Machine → **Virtualize**（ARM Mac + aarch64 镜像）→ Linux
2. 镜像作为启动盘；内存 1–2 GB、核心 1–2 个足够（只跑代理）
3. 网络保持默认 **Shared Network**（宿主机分配 192.168.64.x，第一台虚拟机通常就是 192.168.64.2）
4. 启动后用 `root` / 默认密码 `password` 登录

### 4. 配置网络

把 iStoreOS 的 LAN 口改成 **DHCP 客户端**（或固定 192.168.64.2），并关掉它自带的 DHCP 服务器，避免和 Mac 的共享网络打架：

Network → Interfaces → LAN → 协议改 DHCP / 静态 192.168.64.2，禁用 DHCP server。

Mac 终端确认：`ping 192.168.64.2` 通即可。LuCI 管理地址：http://192.168.64.2（首次登录后记得改 root 密码）。

### 5. 安装 OpenClash

二选一：

- **iStore 应用商店（推荐）**：LuCI 侧边栏 `iStore` → 找到 OpenClash → 安装
- **手动**：[OpenClash Releases](https://github.com/vernesong/OpenClash/releases) 下载 ipk → LuCI → 系统 → 软件包 → 上传安装

### 6. OpenClash 关键设置

Services → OpenClash：

1. **配置文件管理**：添加你的 Clash 订阅地址（或上传配置文件）
2. **全局设置 → 端口**：HTTP 7890 / SOCKS 7891（需与 `proxy-lib.sh` 一致；用别的端口就同步改脚本）
3. **允许局域网连接**：开启（否则 Mac 用不了）
4. **代理认证**：留空/关闭（开了 Mac 侧会 407，踩过坑）
5. 启用 OpenClash，等核心启动

### 7. 验证

```bash
nc -z -G 2 192.168.64.2 7890 && echo ok
curl -x http://192.168.64.2:7890 https://www.google.com -o /dev/null -w '%{http_code}\n'
```

两条都通，虚拟机侧就绪；回到上面的「安装」节接 Raycast。

## 命令一览

| Raycast 命令      | 脚本              | 说明                                                                                                 |
| ----------------- | ----------------- | ---------------------------------------------------------------------------------------------------- |
| Toggle Proxy      | `toggle-proxy.sh` | 一键开关系统代理（全局模式），同步终端 env。热键 `⌃⌥P`                                               |
| Toggle PAC Mode   | `proxy-pac.sh`    | 系统代理切到 OpenClash PAC 规则模式，再按关闭                                                        |
| Proxy Status      | `proxy-status.sh` | 当前模式 / 网络服务 / VM 可达性 / env 状态；VPN 抢占主服务时主动提示                                 |
| Chrome with Proxy | `chrome-proxy.sh` | 带显式 `--proxy-server` 启动 Chrome（VPN 抢占主服务时用）。需先 `⌘Q` 退出 Chrome；终端别名 `chromep` |

## 安装（本机已完成，供迁移参考）

1. Raycast 设置 → Extensions → Script Commands → Add Script Directory → 本目录
2. 给 Toggle Proxy 绑定热键（当前为 `⌃⌥P`）
3. `~/.zshrc` 已加两行：
   - `source ~/.config/proxy-env.sh` —— 新终端自动继承代理开关状态
   - `alias chromep=...` —— Chrome 代理启动

## 使用速查

| 场景   | 终端             | Chrome               | 其他尊重系统代理的 GUI 应用          |
| ------ | ---------------- | -------------------- | ------------------------------------ |
| VPN 关 | 新终端自动走 env | `⌃⌥P` 系统代理覆盖   | `⌃⌥P` 覆盖                           |
| VPN 开 | ✅ env 不受影响  | 先 `⌘Q` 再 `chromep` | ❌ 系统代理被 VPN 抢占（见已知限制） |

## 配置

全部在 `proxy-lib.sh` 顶部一处修改：

- `PROXY_HOST` / `HTTP_PORT` / `SOCKS_PORT` —— VM 地址与端口
- `PAC_URL` —— PAC 模式地址
- `BYPASS_DOMAINS` —— 直连名单（内网/本地不进代理）：`localhost, 127.0.0.1, *.local, 10.*, 192.168.*, 172.16.*, 169.254/16`

## 行为细节

- 自动识别活跃网络服务（默认路由接口 → 服务名）
- VM 端口不可达时**拒绝开启**并告警，避免设个死代理
- global 与 PAC 互斥，开一个关另一个
- 开关时写 `~/.config/proxy-env.sh`：开 = export 代理变量，关 = unset
- 只用官方 `networksetup` API 配置系统代理，不写系统文件、不存任何密码

## 已知限制

1. **GlobalProtect VPN 连接时**：GP 的隐藏服务 `gpd.pan` 抢占主服务位置，GUI 应用读不到我们设的系统代理（官方 API 改不到该隐藏服务，底层动态 store 归 configd 管）。终端 env 不受影响；Chrome 用 `chromep`。
2. **VPN 断开时**：公司 LAN 防火墙可能拦代理节点协议 → 外网打不开（国内直连正常）；VPN 连上时节点反而通（流量封装在隧道里）。最佳姿势 = VPN 常连 + 代理常开。
3. env 只影响新终端；已有终端手动 `source ~/.config/proxy-env.sh`。

## 排错

1. 先跑 **Proxy Status** 看模式与 VM 可达性
2. 报 407 → OpenClash 侧代理认证被重新启用了，去虚拟机设置关掉
3. VM 不可达 → 检查 iStoreOS 虚拟机是否在跑、IP 是否变化（变了改 `proxy-lib.sh` 的 `PROXY_HOST`）
4. 外网超时但百度通 → 代理节点问题，去 LuCI 测节点延迟/换节点
