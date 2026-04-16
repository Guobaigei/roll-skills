# OpenClaw 排障

本文件用于处理以下两类问题：

- macOS npm 安装后仍无法正常工作
- Windows npm 安装后仍无法正常工作

## 先做这三步

先统一检查：

```bash
openclaw gateway status
openclaw health --verbose
openclaw dashboard --no-open
```

如果是 macOS，优先再跑：

```bash
bash <skill-dir>/scripts/check-openclaw.sh
```

如果是 Windows，优先再跑：

```powershell
powershell -ExecutionPolicy Bypass -File <skill-dir>\scripts\check-openclaw.ps1
```

## 配置脚本报缺变量

默认要求 `.env` 至少包含：

- `QWEN_API_KEY`，或 `MODELSTUDIO_API_KEY` / `DASHSCOPE_API_KEY`
- `DEEPSEEK_API_KEY`
- `FEISHU_APP_ID`
- `FEISHU_APP_SECRET`

缺任何一个，安装脚本都不应该继续往下跑。

## `openclaw.ps1` 无法加载

原因：PowerShell 优先命中 npm 生成的 `.ps1` shim，但当前执行策略把它拦住了。

改用 `.cmd` shim：

```powershell
& "$env:APPDATA\npm\openclaw.cmd" --version
& "$env:APPDATA\npm\openclaw.cmd" doctor
```

如果想长期可用，可以在 PowerShell profile 里加：

```powershell
function Global:openclaw { & (Join-Path $env:APPDATA 'npm\openclaw.cmd') @args }
```

不要默认让用户全局放宽执行策略。

## `openclaw` 找不到

先检查：

```bash
node --version
npm --version
openclaw --version
```

如果 `node` 不存在，先装 Node：

macOS：

```bash
brew install node@24
brew link --overwrite --force node@24
```

Windows：

```powershell
winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
```

然后重新执行安装脚本。

## dashboard 打不开

按这个顺序检查：

```bash
openclaw gateway status
openclaw dashboard --no-open
openclaw health --verbose
nc -z 127.0.0.1 18789
curl -I http://127.0.0.1:18789/
```

判断方式：

- `gateway status` 失败：Gateway 还没跑起来
- `18789` 端口不通：本地监听没起来
- `curl` 失败但 Gateway 是 running：多半是本地代理、浏览器插件或 bind 问题
- `dashboard --no-open` 能打印 URL 但浏览器打不开：先用无插件或干净 profile 试

如果是 Windows，再检查：

```powershell
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride
```

确保 `localhost` / `127.0.0.1` 直连。

## Windows：`gateway install` / `schtasks` 拒绝访问

说明当前 PowerShell 不是管理员，或公司策略禁止计划任务。

先在管理员 PowerShell 里重新执行安装脚本；如果只想补装 Gateway，可重试：

```powershell
openclaw gateway install
openclaw gateway start
```

如果公司策略还是禁止计划任务，只能前台运行：

```powershell
openclaw gateway
```

## dashboard 出现 `disconnected (1008): pairing required`

这表示设备配对，不是单纯的网络故障。

检查待审批设备：

```powershell
openclaw devices list
openclaw devices approve <requestId>
```

说明：

- `127.0.0.1` / `localhost` 浏览器连接会自动通过
- LAN / Tailnet / 远程浏览器连接仍然需要显式审批
- 清空浏览器存储后，可能会再次触发配对

## 飞书机器人不收消息

先检查：

```bash
openclaw gateway status
openclaw logs --follow
openclaw channels status --probe
openclaw channels logs --channel feishu
```

再确认飞书应用配置：

- 已开启 bot 能力
- 事件订阅走的是 long connection / WebSocket
- 已添加事件 `im.message.receive_v1`
- 应用已经发布

如果机器人回了 pairing code，就执行审批：

```powershell
openclaw pairing list feishu
openclaw pairing approve feishu <CODE>
```

## Qwen 3.6 Plus 不可用或找不到

先看当前可用模型：

```bash
openclaw models list --provider qwen
openclaw models status --plain
openclaw models fallbacks list --plain
```

如果主模型或备选模型没有写进去，重新执行安装脚本；如果只想补配置，也可以直接跑：

```bash
node <skill-dir>/scripts/apply-openclaw-config.mjs --env-file <env-file>
```

不要再回退到交互式 provider 向导。

## Shell 里能用 API Key，但 Gateway 里不生效

后台 Gateway 进程不会自动继承你当前 shell 的临时 `export`。

把密钥放到：

```text
~/.openclaw/.env
```

然后重新检查：

```bash
openclaw config validate
openclaw gateway status
openclaw health --verbose
```
