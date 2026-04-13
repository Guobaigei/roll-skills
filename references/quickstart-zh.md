# OpenClaw 精简实战版

这份文案用于直接发给中文用户，目标是“拿到就能装”。

## macOS

复制执行：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon
openclaw gateway status
openclaw dashboard
```

装完后的判断标准：

- `openclaw gateway status` 显示服务正常
- `openclaw dashboard` 能打开本地 dashboard

## Windows

Windows 从零安装时，统一走 WSL2。

先在管理员 PowerShell 执行：

```powershell
wsl --install -d Ubuntu
```

如果系统提示重启，就先重启。然后打开 Ubuntu，执行：

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

重新打开 Ubuntu，继续执行：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon
openclaw gateway status
openclaw dashboard
```

装完后的判断标准：

- `openclaw gateway status` 正常
- `openclaw dashboard` 能打开本地 dashboard

## 后续接 Qwen / DeepSeek / 飞书

装好以后，如果还要接模型或飞书，再看 `references/config-snippets.md`。
