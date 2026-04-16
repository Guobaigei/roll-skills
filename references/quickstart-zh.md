# OpenClaw 精简实战版

这份文案用于直接发给中文用户，目标是“拿到就能装”。

## macOS

前提：`.env` 已经配好。

直接执行：

```bash
bash <skill-dir>/scripts/install-openclaw-macos.sh <env-file>
```

装完后的判断标准：

- `openclaw gateway status` 显示服务正常
- `openclaw dashboard` 能打开本地 dashboard

## Windows

前提：`.env` 已经配好，并且要在管理员 PowerShell 中执行。

说明：Windows 这里固定走原生安装，不走 WSL2 / Ubuntu。

直接执行：

```bash
powershell -ExecutionPolicy Bypass -File <skill-dir>\scripts\install-openclaw-windows.ps1 -EnvFile <env-file>
```

装完后的判断标准：

- `openclaw gateway status` 正常
- `openclaw dashboard` 能打开本地 dashboard

## 后续接 Qwen / DeepSeek / 飞书

安装脚本已经会直接写好：

- 默认模型：`qwen/qwen3.6-plus`
- 备选模型：`deepseek/deepseek-reasoner`
- 飞书：`websocket`

如果还要看配置细节，再看 `references/config-snippets.md`。
