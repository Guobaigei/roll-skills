---
name: openclaw-install
description: 在 macOS 或 Windows 上安装和排障 OpenClaw。统一走 Node + npm 安装；如果没有 Node，先安装 Node，再执行 npm 全局安装。Windows 固定走原生管理员 PowerShell 安装，不走 WSL2 / Ubuntu。若 `.env` 已配置，直接用脚本写入飞书和模型配置，默认模型为 `qwen/qwen3.6-plus`，备选为 `deepseek/deepseek-reasoner`。用户提到 OpenClaw 安装、Node、npm、Gateway、dashboard、Feishu、Qwen、DeepSeek、pairing required 时使用。
---

# OpenClaw 安装

这个 skill 用于在 macOS / Windows 上安装、初始化和排障 OpenClaw。

## 默认原则

- 两个系统统一走 `npm install -g openclaw@latest`。
- 如果没有 Node，先安装 Node，再继续 npm 安装。
- Windows 固定走原生管理员 PowerShell，不走 WSL2 / Ubuntu。
- `.env` 已经准备好的情况下，不再让用户手动点选 wizard；直接运行配置脚本，把飞书和模型写好。
- 默认模型固定为 `qwen/qwen3.6-plus`。
- 备选模型固定为 `deepseek/deepseek-reasoner`。
- 回复时优先给“一条安装命令”或“一个脚本命令”，不要把流程拆成多种方案。

## 触发场景

用户提到以下内容时触发：

- 安装 OpenClaw
- `openclaw` 不存在、`dashboard` 打不开、Gateway 起不来
- Windows 上要装 OpenClaw
- mac 上要装 OpenClaw
- 配置 DeepSeek / Qwen / 飞书
- `pairing required`、`gateway closed`、飞书机器人不回消息
- Node / npm 环境没装好

## macOS 最佳实践

如果 `.env` 已经配好，直接运行：

```bash
bash <skill-dir>/scripts/install-openclaw-macos.sh <env-file>
```

执行逻辑：

- 如果缺 Node，先安装 Node
- 用 npm 全局安装 OpenClaw
- 把 `.env` 同步到 `~/.openclaw/.env`
- 直接写入 Feishu + 模型配置
- 安装并启动 Gateway
- 打开 dashboard 验证

## Windows 最佳实践

Windows 只走原生安装，不走 WSL2 / Ubuntu。

如果 `.env` 已经配好，在管理员 PowerShell 里直接运行：

```bash
powershell -ExecutionPolicy Bypass -File <skill-dir>\scripts\install-openclaw-windows.ps1 -EnvFile <env-file>
```

执行逻辑：

- 如果缺 Node，先用 `winget` 安装 Node
- 用 npm 全局安装 OpenClaw
- 把 `.env` 同步到 `%USERPROFILE%\.openclaw\.env`
- 直接写入 Feishu + 模型配置
- 安装并启动 Gateway
- 打开 dashboard 验证

## 模型与飞书

- 非交互配置脚本：`scripts/apply-openclaw-config.mjs`
- 它会直接设置：
  - 主模型：`qwen/qwen3.6-plus`
  - 备选模型：`deepseek/deepseek-reasoner`
  - 飞书：`websocket + defaultAccount=main + dmPolicy=pairing`
- 如果要看最终写入的配置结构，读 `references/config-snippets.md`
- 如果要发给中文用户的精简文案，读 `references/quickstart-zh.md`

## 排障顺序

无论是 macOS 还是 Windows，先按这个顺序排查：

```bash
openclaw gateway status
openclaw health --verbose
openclaw dashboard --no-open
```

- 如果安装阶段出错，先重新执行对应系统的安装脚本
- 如果是 macOS，运行 `scripts/check-openclaw.sh`
- 如果是 Windows，运行 `scripts/check-openclaw.ps1`
- 如果是配置脚本报错或飞书/模型仍不可用，读 `references/troubleshooting.md`

## 输出要求

使用这个 skill 时，回复应满足：

- 默认用中文
- 直接给下一步要执行的命令
- 明确当前是在 macOS 还是 Windows
- 明确问题属于安装、认证、Gateway、dashboard、pairing 还是飞书

## 不要这么做

- 不要默认让用户手动跑 `openclaw onboard` 向导
- 不要一上来就让用户手改 `~/.openclaw/openclaw.json`
- 不要要求用户把真实密钥粘贴到聊天里
- 不要把 `1008 pairing required` 误判成“Gateway 挂了”
