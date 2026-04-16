---
name: openclaw-feishu
description: 引导用户在 macOS 或 Windows 上安装 OpenClaw 并接入飞书。统一使用 Node + npm 安装；Windows 走原生管理员 PowerShell，不走 WSL2 / Ubuntu。重点告诉用户如何补齐 Git、Node、npm、.env、Qwen、DeepSeek、飞书配置，并处理 npm 安装时 GitHub git 依赖超时问题。用户提到 OpenClaw 安装、飞书接入、配置模型、dashboard、Gateway、Git、Node、npm、libsignal-node 或 GitHub 超时时使用。
---

# OpenClaw 飞书接入

这个 skill 用来引导用户安装 OpenClaw，不负责维护一键安装脚本。回答时要简洁，优先给用户可复制命令，并解释缺什么该怎么补。

## 默认原则

- OpenClaw 统一用 `npm install -g openclaw@latest` 安装。
- Windows 固定走原生管理员 PowerShell，不引导用户安装 WSL2 / Ubuntu。
- 安装前先检查 Node、npm、Git 和 `.env`；OpenClaw 当前安装链路会拉 GitHub git 依赖，所以 Git 不是可选项。
- `.env` 必须在安装前准备好；这是必填清单，不是可选后置步骤。
- 不要引导用户安装 yarn、pnpm 或 cnpm；全程只使用 Node 自带的 npm。
- 默认模型使用 `qwen/qwen3.6-plus`，备选模型使用 `deepseek/deepseek-reasoner`。
- 不要让用户把真实密钥发到聊天里，只指导他把密钥写进本机 `.env`。
- npm 国内镜像只能解决 npm 包下载，不能解决 `git ls-remote https://github.com/...` 这种 GitHub git 依赖。

## 触发场景

用户提到以下内容时触发：

- 安装 OpenClaw
- `openclaw` 不存在、`dashboard` 打不开、Gateway 起不来
- Windows 上要装 OpenClaw
- mac 上要装 OpenClaw
- 配置 DeepSeek / Qwen / 飞书
- `pairing required`、`gateway closed`、飞书机器人不回消息
- Git / Node / npm 环境没装好
- npm 安装时报 `libsignal-node`、`git ls-remote`、`github.com`、`SSL connection timeout`、`Connection was reset`
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
git --version
```

Windows PowerShell：

```powershell
node --version
npm --version
git --version
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

如果缺 Git，必须先补 Git：

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

## 3. 设置 npm 淘宝镜像和 GitHub 预检

安装完 Node 后，直接把 npm registry 切到淘宝镜像。这里的 npmmirror 是淘宝 NPM 镜像的新域名，不需要安装 yarn、pnpm 或 cnpm：

```bash
npm config set registry https://registry.npmmirror.com
npm config get registry
```

只有用户明确要求恢复官方源时，才给下面这条命令：

```bash
npm config set registry https://registry.npmjs.org
```

然后固定处理 OpenClaw 的 GitHub git 依赖。先把 GitHub SSH 地址统一重写成 HTTPS，避免卡在 `ssh://git@github.com/...`：

```bash
git config --global --replace-all "url.https://github.com/.insteadOf" "ssh://git@github.com/"
git config --global --add "url.https://github.com/.insteadOf" "git+ssh://git@github.com/"
git config --global --add "url.https://github.com/.insteadOf" "git@github.com:"
git config --global http.version HTTP/1.1
```

安装前必须做一次 `libsignal-node` 预检：

```bash
git ls-remote https://github.com/whiskeysockets/libsignal-node.git HEAD
```

如果这一步返回 commit hash，再继续安装 OpenClaw。如果这一步超时、连接重置或证书失败，不要继续执行 `npm install`，也不要让用户反复切 npm 源；直接告诉用户：当前网络无法访问 OpenClaw 安装链路里的 GitHub git 依赖，npm 镜像无法解决，必须换到能稳定访问 GitHub 的网络或使用维护方提供的无 GitHub 依赖安装包后再继续。

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

如果安装失败日志包含 `libsignal-node`、`git ls-remote`、`github.com`、`SSL connection timeout` 或 `Connection was reset`，回到第 3 步检查 `git ls-remote`。只有预检成功后才重试安装：

```bash
npm cache clean --force
npm install -g openclaw@latest
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
- 不要要求用户安装 yarn、pnpm 或 cnpm；安装 OpenClaw 只用 npm。
- 遇到缺 Git / Node / npm / `.env`，先指导补齐，不要跳到后面的模型或飞书配置。
- 遇到 `libsignal-node` 或 GitHub 超时，先执行第 3 步预检；预检失败就明确说明这是上游 GitHub git 依赖网络阻断，不要继续让用户无效重试。
- 不要要求用户把真实密钥粘贴到聊天里。
- 不要引导 Windows 用户安装 WSL2 / Ubuntu。
