---
name: openclaw-feishu
description: 引导用户在 macOS 或 Windows 上安装 OpenClaw 并接入飞书。统一使用 Node + npm 安装；Windows 走原生管理员 PowerShell，不走 WSL2 / Ubuntu。重点告诉用户如何补齐 Git、Node、npm、.env、Qwen、DeepSeek 和飞书配置。用户提到 OpenClaw 安装、飞书接入、配置模型、dashboard、Gateway、Git、Node、npm 时使用。
---

# OpenClaw 飞书接入

这个 skill 用来引导用户安装 OpenClaw，不负责维护一键安装脚本。回答时要简洁，优先给用户可复制命令，并解释缺什么该怎么补。

## 默认原则

- OpenClaw 统一用 `npm install -g openclaw@latest` 安装。
- Windows 固定走原生管理员 PowerShell，不引导用户安装 WSL2 / Ubuntu。
- 安装前先检查 Node、npm 和 `.env`；如果用户需要拉取项目或命令报缺 Git，再指导安装 Git。
- `.env` 必须在安装前准备好；这是必填清单，不是可选后置步骤。
- 默认模型使用 `qwen/qwen3.6-plus`，备选模型使用 `deepseek/deepseek-reasoner`。
- 不要让用户把真实密钥发到聊天里，只指导他把密钥写进本机 `.env`。

## 触发场景

用户提到以下内容时触发：

- 安装 OpenClaw
- `openclaw` 不存在、`dashboard` 打不开、Gateway 起不来
- Windows 上要装 OpenClaw
- mac 上要装 OpenClaw
- 配置 DeepSeek / Qwen / 飞书
- `pairing required`、`gateway closed`、飞书机器人不回消息
- Git / Node / npm 环境没装好
- `.env` 缺少 Qwen、DeepSeek 或飞书配置

## 1. 先准备必填配置

先让用户根据 `.env.example` 准备环境变量。必须在安装前准备好：

```env
QWEN_API_KEY=你的QwenKey
DEEPSEEK_API_KEY=你的DeepSeekKey
FEISHU_APP_ID=你的飞书AppID
FEISHU_APP_SECRET=你的飞书AppSecret
FEISHU_BOT_NAME=OpenClaw
FEISHU_DOMAIN=feishu
```

用途：

- `QWEN_API_KEY`：默认模型 `qwen/qwen3.6-plus` 使用。
- `DEEPSEEK_API_KEY`：备选模型 `deepseek/deepseek-reasoner` 使用。
- `FEISHU_APP_ID`：飞书机器人应用 ID，用于飞书接入。
- `FEISHU_APP_SECRET`：飞书机器人应用密钥，用于飞书接入。
- `FEISHU_BOT_NAME`：OpenClaw 里显示的飞书账号名称。
- `FEISHU_DOMAIN`：大陆飞书填 `feishu`，国际版 Lark 填 `lark`。

不要让用户把真实值发到聊天里，只让他写进本机文件。

macOS：

```bash
mkdir -p ~/.openclaw
nano ~/.openclaw/.env
```

Windows PowerShell：

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.openclaw"
notepad "$env:USERPROFILE\.openclaw\.env"
```

## 2. 检查依赖

先让用户执行：

macOS：

```bash
node --version
npm --version
```

Windows PowerShell：

```powershell
node --version
npm --version
winget --version
```

如果缺 Node / npm：

macOS：

```bash
brew install node@24
brew link --overwrite --force node@24
```

Windows：

```powershell
winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
```

如果 Node 官网下载不通，给用户国内镜像兜底：

- npmmirror Node 镜像：https://registry.npmmirror.com/binary.html?path=node/

引导用户下载最新 LTS 或 Node 24 的 Windows `.msi` 安装包，安装完成后重新打开 PowerShell，再执行：

```powershell
node --version
npm --version
```

如果命令报缺 Git，再补 Git：

macOS：

```bash
brew install git
```

如果 macOS 没有 Homebrew，就让用户先执行：

```bash
xcode-select --install
```

Windows：

```powershell
winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
```

如果 `winget`、Git 官网或 GitHub 下载不通，给用户国内镜像兜底：

- USTC GitHub Release 镜像：https://mirrors.ustc.edu.cn/github-release/git-for-windows/git/
- npmmirror 二进制镜像：https://registry.npmmirror.com/binary.html?path=git-for-windows%2F

引导用户在镜像页面下载最新的 `Git-*-64-bit.exe`，双击安装，安装选项保持默认即可。安装完成后必须重新打开 PowerShell，再执行：

```powershell
git --version
```

如果 Windows 没有 `winget`，让用户手动下载并安装：

- Node.js: https://nodejs.org/en/download
- Node.js 国内镜像: https://registry.npmmirror.com/binary.html?path=node/
- Git: https://git-scm.com/download/win
- Git 国内镜像: https://mirrors.ustc.edu.cn/github-release/git-for-windows/git/

安装 Git 或 Node 后，提醒用户重新打开终端 / 管理员 PowerShell，再继续下一步。

## 3. 设置 npm 国内镜像

安装完 Node 后，国内网络环境先切 npm registry 到 npmmirror：

```bash
npm config set registry https://registry.npmmirror.com
npm config get registry
```

如果用户明确在海外网络或公司内网已有 npm 代理，可以跳过这一步。需要恢复官方源时使用：

```bash
npm config set registry https://registry.npmjs.org
```

## 4. 安装 OpenClaw

macOS / Windows 都使用 npm：

```bash
npm install -g openclaw@latest
openclaw --version
```

Windows 如果遇到 `openclaw.ps1` 被 PowerShell 拦截，改用：

```powershell
& "$env:APPDATA\npm\openclaw.cmd" --version
```

## 5. 配置模型

默认 Qwen 3.6，备选 DeepSeek：

```bash
openclaw models set qwen/qwen3.6-plus
openclaw models fallbacks clear
openclaw models fallbacks add deepseek/deepseek-reasoner
openclaw models status --plain
```

## 6. 配置飞书

优先使用 OpenClaw 自带配置命令：

```bash
openclaw config set channels.feishu.enabled true
openclaw config set channels.feishu.connectionMode '"websocket"'
openclaw config set channels.feishu.dmPolicy '"pairing"'
openclaw config set channels.feishu.defaultAccount '"main"'
openclaw config set channels.feishu.accounts.main.appId '"${FEISHU_APP_ID}"'
openclaw config set channels.feishu.accounts.main.appSecret '"${FEISHU_APP_SECRET}"'
openclaw config set channels.feishu.accounts.main.name '"${FEISHU_BOT_NAME}"'
openclaw config validate
```

如果用户是国际版 Lark，再加：

```bash
openclaw config set channels.feishu.domain '"lark"'
```

## 7. 启动 Gateway 和 Dashboard

macOS：

```bash
openclaw gateway install
openclaw gateway start
openclaw gateway status
openclaw dashboard
```

Windows 管理员 PowerShell：

```powershell
openclaw gateway install
openclaw gateway start
openclaw gateway status
openclaw dashboard
```

如果 Windows 提示 `schtasks` 拒绝访问，说明当前不是管理员 PowerShell，要求用户重新用管理员 PowerShell 执行。

## 8. 最小排障

```bash
openclaw gateway status
openclaw health --verbose
openclaw dashboard --no-open
```

如果 dashboard 出现 `disconnected (1008): pairing required`，这是设备配对问题，不是 Gateway 挂了。让用户执行：

```bash
openclaw devices list
openclaw devices approve <requestId>
```

## 回答要求

- 默认用中文回答。
- 先判断用户是 macOS 还是 Windows。
- 每次只给当前最需要执行的一组命令。
- 遇到缺 Git / Node / npm / `.env`，先指导补齐，不要跳到后面的模型或飞书配置。
- 不要要求用户把真实密钥粘贴到聊天里。
- 不要引导 Windows 用户安装 WSL2 / Ubuntu。
