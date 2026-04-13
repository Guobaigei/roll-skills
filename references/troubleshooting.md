# OpenClaw 排障

本文件用于处理以下两类问题：

- macOS / WSL2 安装完成后仍无法正常工作
- 已经存在的原生 Windows 安装卡住了

## 先做这三步

先统一检查：

```bash
openclaw gateway status
openclaw health --verbose
openclaw dashboard --no-open
```

如果是 macOS 或 WSL2，优先再跑：

```bash
bash <skill-dir>/scripts/check-openclaw.sh
```

## `openclaw.ps1` 无法加载

原因：PowerShell 优先命中 npm 生成的 `.ps1` shim，但当前执行策略把它拦住了。

改用 `.cmd` shim：

```powershell
& "$env:APPDATA\npm\openclaw.cmd" --version
& "$env:APPDATA\npm\openclaw.cmd" doctor
```

如果想长期可用，可以在 PowerShell profile 里加：

```powershell
function Global:openclaw {
  & (Join-Path $env:APPDATA 'npm\openclaw.cmd') @args
}
```

不要默认让用户全局放宽执行策略。

## `openclaw` 找不到

先检查：

```powershell
node --version
npm prefix -g
where.exe openclaw
```

如果这是遗留原生 Windows 安装，且用户不执着于 npm 方式，最快修复通常是官方安装脚本：

```powershell
& ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -NoOnboard
```

## macOS / WSL2：dashboard 打不开

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

如果这是 macOS 本机环境，再检查系统代理或浏览器代理插件；如果这是 WSL2，优先确认你访问的是 WSL 内实际打印出来的 dashboard 地址。

如果是遗留原生 Windows 环境，再检查：

```powershell
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride
```

确保 `localhost` / `127.0.0.1` 直连。

## WSL2：`gateway install` 装不上

最常见原因是 `systemd` 没开。

先检查：

```bash
systemctl --user status
```

如果提示 systemd 不可用，就执行：

```powershell
wsl --shutdown
```

然后重新进入 Ubuntu，确认 `/etc/wsl.conf` 里已有：

```ini
[boot]
systemd=true
```

再执行：

```bash
openclaw onboard --install-daemon
```

## 原生 Windows：`gateway install` / `schtasks` 拒绝访问

这是遗留原生 Windows 路径的问题，不是新的推荐安装方式。

先在管理员 PowerShell 里重试：

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

```powershell
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

```powershell
openclaw models list --provider qwen
openclaw models status --plain
```

`qwen/qwen3.6-plus` 推荐重新走 Standard API key 流程：

```powershell
openclaw onboard --auth-choice qwen-standard-api-key
openclaw models set qwen/qwen3.6-plus
```

不要继续沿用旧的 Qwen OAuth / 控制台说明。

## Shell 里能用 API Key，但 Gateway 里不生效

后台 Gateway 进程不会自动继承你当前 shell 的临时 `export`。

把密钥放到：

```text
%USERPROFILE%\.openclaw\.env
```

然后重新检查：

```powershell
openclaw config validate
openclaw gateway status
openclaw health --verbose
```
