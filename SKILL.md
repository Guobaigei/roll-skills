---
name: openclaw-install
description: 在 macOS 或 Windows 上安装和排障 OpenClaw。默认最佳实践：macOS 走官方 install.sh + openclaw onboard --install-daemon；Windows 一律走 WSL2（推荐 Ubuntu）+ install.sh + onboard。用户提到 OpenClaw 安装、Gateway、dashboard、Feishu、Qwen、DeepSeek、pairing required、WSL2 时使用。
---

# OpenClaw 安装

这个 skill 用于在 macOS / Windows 上安装、初始化和排障 OpenClaw。

## 默认原则

- 默认走 CLI 新手引导，不先手改 `openclaw.json`。
- macOS 的主路径固定为：官方 `install.sh` + `openclaw onboard --install-daemon`。
- Windows 的主路径固定为：`WSL2 + Ubuntu + install.sh + openclaw onboard --install-daemon`。
- 从零开始安装时，不把原生 Windows 作为默认推荐路径；原生 Windows 仅用于处理“已经这样装了但现在卡住”的情况。
- 回复时直接给可复制执行的命令，不给“方案 A / 方案 B”。

## 触发场景

用户提到以下内容时触发：

- 安装 OpenClaw
- `openclaw` 不存在、`dashboard` 打不开、Gateway 起不来
- Windows 上要装 OpenClaw
- mac 上要装 OpenClaw
- 配置 DeepSeek / Qwen / 飞书
- `pairing required`、`gateway closed`、飞书机器人不回消息

## macOS 最佳实践

直接给下面这组命令：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon
openclaw gateway status
openclaw dashboard
```

执行逻辑：

- 第 1 步安装 CLI
- 第 2 步完成新手引导并安装后台服务
- 第 3 步确认 Gateway 已启动
- 第 4 步打开 dashboard 验证

## Windows 最佳实践

Windows 从零安装时，一律按 WSL2 处理。

先在管理员 PowerShell 执行：

```powershell
wsl --install -d Ubuntu
```

如果系统提示重启，就先重启，然后打开 Ubuntu，再执行：

```bash
sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true
EOF
```

回到 PowerShell 执行：

```powershell
wsl --shutdown
```

重新打开 Ubuntu，执行：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon
openclaw gateway status
openclaw dashboard
```

执行逻辑：

- 第 1 步把 Windows 运行环境固定成 WSL2 + Ubuntu
- 第 2 步启用 systemd，保证 Gateway 服务能装上
- 第 3 步在 WSL 里安装 OpenClaw
- 第 4 步完成新手引导并安装 systemd 用户服务
- 第 5 步确认 Gateway 正常
- 第 6 步打开 dashboard 验证

## 模型与飞书

- DeepSeek、Qwen、飞书的推荐配置与最小片段，读 `references/config-snippets.md`
- 如果用户要“中文可直接复制”的短文案，优先读 `references/quickstart-zh.md`

## 排障顺序

无论是 macOS 还是 WSL2，先按这个顺序排查：

```bash
openclaw gateway status
openclaw health --verbose
openclaw dashboard --no-open
```

- 如果是 macOS 或 WSL2，优先运行 `scripts/check-openclaw.sh`
- 如果是已经存在的原生 Windows 安装，读 `references/troubleshooting.md`
- 如果是 PowerShell shim、`schtasks`、原生 Windows dashboard 等问题，也读 `references/troubleshooting.md`

## 输出要求

使用这个 skill 时，回复应满足：

- 默认用中文
- 直接给下一步要执行的命令
- 明确当前是在 macOS、WSL2 还是“遗留原生 Windows”
- 明确问题属于安装、认证、Gateway、dashboard、pairing 还是飞书

## 不要这么做

- 不要把原生 Windows 当成从零安装的默认方案
- 不要一上来就让用户手改 `~/.openclaw/openclaw.json`
- 不要要求用户把真实密钥粘贴到聊天里
- 不要把 `1008 pairing required` 误判成“Gateway 挂了”
