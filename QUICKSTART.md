# 快速上手 — Kairo

> 目标：从零到第一条 AI 秘书回复，约 15 分钟。

---

## 前置要求

| 依赖        | 版本          | 说明               |
| ----------- | ------------- | ------------------ |
| Node.js     | ≥ 22          | `node -v` 确认     |
| pnpm        | ≥ 9           | `npm i -g pnpm`    |
| 操作系统    | Linux / macOS | Windows 需 WSL2    |
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

预期输出（末尾几行）：

```
✓ built in Xs
```

`dist/index.js` 存在即代表构建成功。

---

## 第二步：选择 AI 模型

Kairo 支持任何兼容 OpenAI API 格式的模型服务。选择一种：

<details>
<summary><b>选项 A：OpenAI API Key（最简单）</b></summary>

在 [platform.openai.com/api-keys](https://platform.openai.com/api-keys) 创建 API Key，设置环境变量：

```bash
export OPENAI_API_KEY="sk-proj-YOUR_API_KEY"
# 持久化：加入 ~/.bashrc 或 ~/.zshrc
```

后续 `openclaw.json` 中的 `agents.defaults.model.primary` 填 `"openai/gpt-4o-mini"`。

</details>

<details>
<summary><b>选项 B：ChatGPT Codex OAuth（Ken 在用的方案）</b></summary>

使用 ChatGPT 账号 OAuth 登录，无需付费 API Key。通过 CLI 交互式 onboard 完成授权：

```bash
node scripts/run-node.mjs onboard
# 选择 "openai-codex"，按提示在浏览器完成 OAuth
```

授权完成后 token 自动写入 `~/.openclaw/agents/main/agent/auth-profiles.json`，模型默认设为 `openai-codex/gpt-5.3-codex`。

</details>

<details>
<summary><b>选项 C：本地模型（Ollama，完全离线）</b></summary>

先安装 [Ollama](https://ollama.ai) 并拉取模型：

```bash
ollama pull llama3.3
# 确保 ollama 服务在运行：ollama serve
```

创建 `~/.openclaw/agents/main/agent/models.json`，注册本地 provider：

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "apiKey": "n/a",
      "api": "openai-completions",
      "models": [
        {
          "id": "llama3.3",
          "name": "llama3.3",
          "api": "openai-completions",
          "input": ["text"],
          "contextWindow": 128000,
          "maxTokens": 8192
        }
      ]
    }
  }
}
```

后续 `openclaw.json` 中的 `agents.defaults.model.primary` 填 `"ollama/llama3.3"`。

</details>

---

## 第三步：申请 Telegram Bot

1. 打开 Telegram，搜索 **@BotFather**
2. 发送 `/newbot`，按提示填写名称
3. 获得 Bot Token，格式如：`7123456789:AAHxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

## 第四步：创建配置文件

```bash
mkdir -p ~/.openclaw
```

创建 `~/.openclaw/openclaw.json`：

```jsonc
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "YOUR_BOT_TOKEN", // 上一步从 @BotFather 获取
      "dmPolicy": "open", // "open" 允许所有 DM；"pairing" 需首次配对（更安全）
    },
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o-mini", // 替换为步骤 2 选择的模型
      },
    },
  },
  "gateway": {
    "port": 18789,
  },
}
```

> 💡 **Telegram token 字段名是 `botToken`，不是 `token`。**

---

## 第五步：初始化工作区

Kairo 的所有数据存储在 `assistant_hub` 目录下：

```bash
mkdir -p ~/.openclaw/workspace/automation/assistant_hub/{00_inbox,02_work/tasks,03_life/daily_logs,04_knowledge/{people,beliefs,monthly_digest}}
touch ~/.openclaw/workspace/automation/assistant_hub/02_work/{tasks_master.md,waiting.md,calendar.md,gmail.md}
touch ~/.openclaw/workspace/automation/assistant_hub/04_knowledge/{roadmap.md,patterns.md}
touch ~/.openclaw/workspace/HEARTBEAT.md
```

> 注：`HEARTBEAT.md` 在 workspace 根目录，其他数据文件在 `automation/assistant_hub/` 下。

---

## 第六步：启动服务

```bash
node scripts/run-node.mjs gateway --port 18789
```

预期输出（几秒后出现，带时间戳）：

```
2026-xx-xxTxx:xx:xx.xxxZ [heartbeat] started
2026-xx-xxTxx:xx:xx.xxxZ [telegram] [main] starting provider
```

控制台地址：`http://localhost:18789`（需设置 `gateway.auth.token` 才能登录）

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

Kairo 的 Gmail 摘要功能（`scripts/capture/gmail-digest.ts`）读取 openclaw 网关中的 Gmail 会话记录，因此你需要先在 openclaw 中设置 Gmail 频道。

**1. 通过 CLI Onboard 设置 Gmail：**

```bash
node scripts/run-node.mjs onboard
# 按提示选择 Gmail，完成 OAuth 授权
# 授权完成后会话记录写入 ~/.openclaw/agents/main/sessions/
```

**2. 在 `openclaw.json` 启用 Gmail 频道（onboard 会自动写入）：**

Gmail 频道配置由 onboard 工具自动生成，无需手动编辑。

**3. 验证摘要脚本可运行：**

```bash
node --import tsx scripts/capture/gmail-digest.ts
```

成功后，Kairo 每日 07:10 自动运行脚本，将摘要写入：
`~/.openclaw/workspace/automation/assistant_hub/02_work/gmail.md`，晨报时一并推送。

</details>

---

## 可选：接入飞书日历

<details>
<summary>展开配置步骤</summary>

飞书日历使用 Feishu OAuth user_access_token，需要以下步骤：

**1. 在 [飞书开放平台](https://open.feishu.cn/) 创建企业自建应用**

- 开通「日历」权限范围（`calendar:calendar:read`）
- 记下 App ID 和 App Secret

**2. 设置环境变量（加入 systemd 服务文件或 ~/.bashrc）：**

```bash
export FEISHU_APP_ID="cli_xxxxxxxxxxxxxxxx"
export FEISHU_APP_SECRET="YOUR_APP_SECRET"
```

**3. 手动完成 OAuth 授权，获取 user_access_token：**

通过飞书 OAuth 授权页面（需要你的应用有 `authen` scope）获取 token，写入：

```json
// ~/.openclaw/feishu_user_token.json
{
  "access_token": "u-xxx",
  "refresh_token": "u-xxx",
  "expires_in": 7200,
  "refresh_expires_in": 2592000,
  "token_type": "Bearer",
  "calendar_id": "your.calendar.id",
  "obtained_at": "2026-01-01T00:00:00.000Z"
}
```

**4. 验证脚本可运行：**

```bash
node --import tsx scripts/capture/feishu-calendar.ts
```

成功后，Kairo 每日 07:00 自动写入：
`~/.openclaw/workspace/automation/assistant_hub/02_work/calendar.md`

> 💡 token 会自动刷新，`obtained_at` 字段记录获取时间，无需手动续期。

</details>

---

## 可选：以 systemd 服务运行（后台常驻）

<details>
<summary>展开配置步骤</summary>

**对于 root 用户**（推荐服务器部署方式）：

创建 `/root/.config/systemd/user/kairo.service`：

```ini
[Unit]
Description=Kairo AI Secretary
After=network.target

[Service]
Type=simple
WorkingDirectory=/path/to/Kairo-KenVersion
ExecStart=node scripts/run-node.mjs gateway --port 18789
Environment=NODE_ENV=production
Environment=OPENAI_API_KEY=sk-proj-YOUR_KEY
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

启用并启动：

```bash
XDG_RUNTIME_DIR=/run/user/0 systemctl --user daemon-reload
XDG_RUNTIME_DIR=/run/user/0 systemctl --user enable --now kairo.service
XDG_RUNTIME_DIR=/run/user/0 systemctl --user status kairo.service
```

查看日志：

```bash
journalctl --user -u kairo.service -f
```

</details>

---

## 常见问题

**Q：Bot 没有回复？**

1. 检查 `botToken` 是否正确（字段名是 `botToken`，不是 `token`）
2. 如果 `dmPolicy` 是 `"pairing"`，需要先通过配对码验证身份
3. 查看日志确认 telegram provider 已启动：`journalctl --user -u kairo.service | grep telegram`

**Q：模型报错 `No API key found`？**

- 使用 OpenAI：确认环境变量 `OPENAI_API_KEY` 已设置，且对运行 Kairo 的进程可见（systemd 服务需在 `Environment=` 行设置）
- 使用 Anthropic：确认 `ANTHROPIC_API_KEY` 已设置
- 使用 Ollama：确认 Ollama 服务正在运行（`ollama serve`），且 `models.json` 中的 `provider id` 与 `openclaw.json` 的 `primary` 前缀一致

**Q：如何查看日志？**

```bash
# 直接运行时
node scripts/run-node.mjs gateway --port 18789 2>&1 | tee kairo.log

# systemd 服务
journalctl --user -u kairo.service -f
```

**Q：如何手动触发晨报？**

编辑 `~/.openclaw/cron/jobs.json`，将目标 job 的 `nextRunAtMs` 改为当前时间戳 + 5000（毫秒），等待约 30 秒即可触发。

---

## 下一步

- 查看 [README](./README.md) 了解完整功能说明
- 查看 [content/](./content/) 了解情报中心输出格式
- 在 Telegram 对话中发送任何想法，开始建立你的个人知识库
