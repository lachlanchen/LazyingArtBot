# 快速上手 — Kairo

> 目标：从零到第一条 AI 秘书回复，约 15 分钟。

---

## 前置要求

| 依赖        | 版本          | 说明               |
| ----------- | ------------- | ------------------ |
| Node.js     | ≥ 22          | 推荐 LTS 版本      |
| pnpm        | ≥ 9           | `npm i -g pnpm`    |
| 操作系统    | Linux / macOS | Windows 暂不支持   |
| AI 模型 API | 任意一种      | 见下方「模型选择」 |

---

## 第一步：安装

```bash
git clone https://github.com/sou350121/Kairo-KenVersion.git
cd Kairo-KenVersion
pnpm install
pnpm ui:build
pnpm build
```

预期输出：

```
 DONE  Build complete.
dist/
├── entry.js
└── index.js
```

---

## 第二步：选择 AI 模型

Kairo 支持任何兼容 OpenAI API 格式的模型服务。选择一种：

<details>
<summary><b>选项 A：OpenAI（最简单）</b></summary>

准备好 OpenAI API Key，后续配置填入即可。

模型推荐：`gpt-4o` 或 `gpt-4o-mini`

</details>

<details>
<summary><b>选项 B：ChatGPT Codex OAuth（免费，Ken 在用）</b></summary>

使用 ChatGPT 账号的 OAuth token，无需付费 API Key。

配置方式见 `~/.openclaw/agents/main/agent/auth-profiles.json`，token 来源为 ChatGPT 网页端抓取。

</details>

<details>
<summary><b>选项 C：本地模型（Ollama）</b></summary>

```bash
# 先启动 Ollama
ollama run qwen2.5:14b
```

后续配置中 `baseUrl` 填 `http://localhost:11434/v1`，`api` 填 `openai-responses`。

</details>

---

## 第三步：申请 Telegram Bot

1. 打开 Telegram，搜索 **@BotFather**
2. 发送 `/newbot`，按提示填写名称
3. 获得 Bot Token，格式如：`7123456789:AAHxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
4. 记下你的 Telegram 账号 ID（可向 **@userinfobot** 发送任意消息获取）

---

## 第四步：创建配置文件

```bash
mkdir -p ~/.openclaw/agents/main/agent
```

创建 `~/.openclaw/openclaw.json`：

```jsonc
{
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "YOUR_BOT_TOKEN",
      "allowedUserIds": ["YOUR_TELEGRAM_USER_ID"],
    },
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o",
      },
    },
  },
  "gateway": {
    "port": 18789,
    "auth": {
      "token": "your-secret-token",
    },
  },
}
```

创建 `~/.openclaw/agents/main/agent/models.json`：

```json
{
  "providers": {
    "openai": {
      "baseUrl": "https://api.openai.com/v1",
      "api": "openai-responses",
      "models": [
        {
          "id": "gpt-4o",
          "name": "gpt-4o",
          "api": "openai-responses",
          "reasoning": false,
          "input": ["text", "image"],
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
          "contextWindow": 128000,
          "maxTokens": 16384
        }
      ]
    }
  }
}
```

创建 `~/.openclaw/agents/main/agent/auth-profiles.json`：

```json
{
  "openai": {
    "apiKey": "sk-YOUR_OPENAI_API_KEY"
  }
}
```

---

## 第五步：初始化工作区

```bash
mkdir -p ~/.openclaw/workspace/{00_inbox,02_work/tasks,03_life/daily_logs,04_knowledge/{people,beliefs,monthly_digest}}
touch ~/.openclaw/workspace/02_work/{tasks_master.md,waiting.md,calendar.md,gmail.md}
touch ~/.openclaw/workspace/04_knowledge/{roadmap.md,patterns.md}
touch ~/.openclaw/workspace/HEARTBEAT.md
```

---

## 第六步：启动服务

```bash
node scripts/run-node.mjs gateway --port 18789
```

预期输出：

```
[gateway] Starting on port 18789
[telegram] Bot connected: @YourBotName
[cron] Bootstrap jobs registered
[heartbeat] Runner started
✓ Kairo is ready
```

控制台地址：`http://localhost:18789`

---

## 第七步：第一次对话

打开 Telegram，找到你的 Bot，发送：

```
提醒我明天上午 10 点跟 Jason 确认合同
```

预期回复：

```
✅ 已建立任务卡片
📋 类型：timeline
📅 截止：明天 10:00
⏰ 已排程提醒

明天上午 10:00 我会主动提醒你。
```

再试一个：

```
记一下：Naval 说「用杠杆，而不是用时间」
```

预期回复：

```
✅ 已记录
📋 类型：belief
💡 Naval Ravikant — Leverage 原则

已存入知识库。
```

---

## 可选：接入 Gmail 邮件摘要

<details>
<summary>展开配置步骤</summary>

1. 前往 [Google Cloud Console](https://console.cloud.google.com/) 创建项目
2. 启用 Gmail API，创建 OAuth 2.0 客户端（桌面应用类型）
3. 下载凭据文件，运行授权脚本：

```bash
node scripts/capture/gmail-digest.ts --auth
```

4. 在 `openclaw.json` 中添加：

```jsonc
{
  "capture": {
    "gmail": {
      "enabled": true,
      "clientId": "YOUR_CLIENT_ID",
      "clientSecret": "YOUR_CLIENT_SECRET",
    },
  },
}
```

配置完成后，每日 07:10 自动读取 Gmail 并写入 `~/.openclaw/workspace/02_work/gmail.md`，
晨报时一并推送。

</details>

---

## 可选：接入飞书日历

<details>
<summary>展开配置步骤</summary>

1. 前往 [飞书开放平台](https://open.feishu.cn/) 创建企业自建应用
2. 开通「日历」权限范围
3. 运行授权脚本获取 user_access_token：

```bash
node scripts/capture/feishu-calendar.ts --auth
```

4. 在 `openclaw.json` 中添加：

```jsonc
{
  "capture": {
    "feishu": {
      "enabled": true,
      "appId": "cli_xxxxxxxxxxxxxxxx",
      "appSecret": "YOUR_APP_SECRET",
    },
  },
}
```

配置完成后，每日 07:00 自动读取个人日历并写入 `~/.openclaw/workspace/02_work/calendar.md`。

</details>

---

## 可选：以 systemd 服务运行（后台常驻）

<details>
<summary>展开配置步骤</summary>

创建 `~/.config/systemd/user/kairo.service`：

```ini
[Unit]
Description=Kairo AI Secretary
After=network.target

[Service]
Type=simple
WorkingDirectory=/path/to/Kairo-KenVersion
ExecStart=node scripts/run-node.mjs gateway --port 18789
Environment=NODE_ENV=production
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

启用并启动：

```bash
systemctl --user daemon-reload
systemctl --user enable --now kairo.service
systemctl --user status kairo.service
```

</details>

---

## 常见问题

**Q：Bot 没有回复？**

检查 Bot Token 是否正确，以及 `allowedUserIds` 是否填了你的 Telegram ID。

**Q：模型报错 `No API key found`？**

检查 `~/.openclaw/agents/main/agent/auth-profiles.json` 中的 API Key 是否正确，以及 `models.json` 中的 provider 名称是否与 `auth-profiles.json` 一致。

**Q：如何查看日志？**

```bash
# 直接运行时
node scripts/run-node.mjs gateway --port 18789 2>&1 | tee kairo.log

# systemd 服务
journalctl --user -u kairo.service -f
```

**Q：如何手动触发晨报？**

编辑 `~/.openclaw/cron/jobs.json`，将目标 job 的 `nextRunAtMs` 改为当前时间戳 + 5000，等待约 30 秒即可触发。

---

## 下一步

- 查看 [README](./README.md) 了解完整功能说明
- 查看 [content/](./content/) 了解情报中心输出格式
- 在 Telegram 对话中发送任何想法，开始建立你的个人知识库
