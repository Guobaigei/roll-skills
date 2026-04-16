# OpenClaw 配置片段

只在以下情况读取本文件：

- 安装脚本已跑完，但你还想确认它到底写了什么
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

安装脚本会把 DeepSeek 作为备选模型写入：

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "qwen/qwen3.6-plus",
        fallbacks: ["deepseek/deepseek-reasoner"],
      },
    },
  },
}
```

## Qwen

安装脚本会直接把 Qwen 设为主模型：

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "qwen/qwen3.6-plus",
        fallbacks: ["deepseek/deepseek-reasoner"],
      },
    },
  },
}
```

说明：

- 优先使用 `QWEN_API_KEY`
- 兼容别名还包括 `MODELSTUDIO_API_KEY` 和 `DASHSCOPE_API_KEY`
- 安装脚本不会再走交互式 provider 向导，而是直接设置默认模型

## 飞书

安装脚本会直接写入下面这组配置：

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

```bash
openclaw config validate
openclaw gateway status
openclaw dashboard --no-open
```
