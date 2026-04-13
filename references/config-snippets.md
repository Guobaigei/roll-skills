# OpenClaw 配置片段

只在以下情况读取本文件：

- `openclaw onboard` / `openclaw channels add` 不够用
- 用户明确要求手动改配置文件
- 需要给出最小可复制片段

## 关键路径

- 配置文件：`~/.openclaw/openclaw.json`
- 全局环境变量文件：`~/.openclaw/.env`
- Windows 路径写法：`%USERPROFILE%\.openclaw\openclaw.json` 和 `%USERPROFILE%\.openclaw\.env`

OpenClaw 支持在配置字符串中引用环境变量：

```json5
{
  gateway: { auth: { token: "${OPENCLAW_GATEWAY_TOKEN}" } },
  models: { providers: { custom: { apiKey: "${CUSTOM_API_KEY}" } } },
}
```

## DeepSeek

推荐命令：

```powershell
openclaw onboard --auth-choice deepseek-api-key
openclaw models set deepseek/deepseek-reasoner
```

如果需要把默认模型显式写进配置：

```json5
{
  agents: {
    defaults: {
      model: { primary: "deepseek/deepseek-reasoner" },
    },
  },
}
```

## Qwen

默认优先使用内置 `qwen` provider，不手写 `models.providers.qwen`。

`qwen/qwen3.6-plus` 推荐命令：

```powershell
openclaw onboard --auth-choice qwen-standard-api-key
openclaw models set qwen/qwen3.6-plus
openclaw models list --provider qwen
```

如果需要把默认模型显式写进配置：

```json5
{
  agents: {
    defaults: {
      model: { primary: "qwen/qwen3.6-plus" },
    },
  },
}
```

说明：

- 优先使用 `QWEN_API_KEY`
- 兼容别名还包括 `MODELSTUDIO_API_KEY` 和 `DASHSCOPE_API_KEY`
- `qwen/qwen3.6-plus` 最适合走 Standard DashScope endpoint 流程

## 飞书

推荐命令：

```powershell
openclaw channels add
```

按提示选择 Feishu，并填写 App ID / App Secret。

标准配置结构：

```json5
{
  channels: {
    feishu: {
      enabled: true,
      connectionMode: "websocket",
      dmPolicy: "pairing",
      defaultAccount: "main",
      accounts: {
        main: {
          appId: "${FEISHU_APP_ID}",
          appSecret: "${FEISHU_APP_SECRET}",
          name: "My AI assistant",
        },
      },
    },
  },
}
```

如果要走 webhook，还需要这些字段：

```json5
{
  channels: {
    feishu: {
      connectionMode: "webhook",
      verificationToken: "${FEISHU_VERIFICATION_TOKEN}",
      encryptKey: "${FEISHU_ENCRYPT_KEY}",
    },
  },
}
```

如果是国际版 Lark：

```json5
{
  channels: {
    feishu: {
      domain: "lark",
      accounts: {
        main: {
          appId: "${FEISHU_APP_ID}",
          appSecret: "${FEISHU_APP_SECRET}",
        },
      },
    },
  },
}
```

改完配置后执行：

```powershell
openclaw config validate
openclaw gateway status
openclaw dashboard --no-open
```
