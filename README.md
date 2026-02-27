<p align="center">
  <img src="https://github.com/sou350121/Kairo-KenVersion/raw/main/assets/kairo-banner.png" alt="Kairo banner" width="800"/>
</p>

<p align="center">
  <a href="https://github.com/sou350121/Kairo-KenVersion"><img src="https://img.shields.io/github/stars/sou350121/Kairo-KenVersion?style=flat-square&logo=github" alt="Stars"/></a>
  <a href="https://github.com/sou350121/Kairo-KenVersion/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License"/></a>
  <img src="https://img.shields.io/badge/node-%3E%3D22-green?style=flat-square&logo=node.js" alt="Node"/>
  <img src="https://img.shields.io/badge/channels-Telegram%20%7C%20Feishu-blueviolet?style=flat-square" alt="Channels"/>
  <img src="https://img.shields.io/badge/status-personal--live-orange?style=flat-square" alt="Status"/>
</p>

<h1 align="center">Kairo · 個人全能 AI 秘書</h1>

<p align="center">
  <b>You think. Kairo remembers, organizes, follows up — and reminds you at exactly the right moment.</b>
</p>

---

## 這是什麼

你有沒有這種經歷：

```
☕ 咖啡館           💼 開完會               🌙 睡前
────────            ──────────              ──────────
看到一篇論文         需要跟進某件事           腦子裡塞滿 10 件事
  ↓                   ↓                       ↓
想記下來             忘了記                   睡不著
  ↓                   ↓                       ↓
懶得開 Notion         下次再說                 靠意志力撐
  ↓                   ↓                       ↓
過兩天忘了            事情沒推進               精力耗盡
```

**Kairo 解決這個問題。**

只要你在 Telegram 或 Feishu 隨手一說，Kairo 就幫你：

- 📝 **捕捉** — 識別你說的是任務、想法、提醒還是筆記
- 🗂 **整理** — 自動建立結構化卡片，歸入對應目錄
- ⏰ **提醒** — 在你設定的時間主動找你
- 📊 **晨報** — 每天早上彙報今日行程、逾期任務、郵件摘要
- 🔄 **閉環** — 任務完成後自動標記，跟進中的事項持續追蹤

---

## 核心能力

### 1. 🎯 智能捕捉 — 說話就夠了

> 「提醒我下週一早上9點跟 Jason 確認合同」  
> 「記一下：Naval 說的 Leverage 理論值得深入研究」  
> 「周五前要把報告發給王總」

Kairo 自動判斷意圖類型，精確度 ≥ 85% 時靜默建卡，低於時顯示選單讓你確認。

支援 10 種意圖類型：

| 類型        | 說明             | 例子                       |
| ----------- | ---------------- | -------------------------- |
| `action`    | 需要執行的任務   | 「整理Q1報告」             |
| `timeline`  | 有 deadline 的事 | 「3/15前提交申請」         |
| `watch`     | 需要持續跟進     | 「等王總回覆」             |
| `idea`      | 靈感/想法        | 「考慮用 Rust 重寫這塊」   |
| `memory`    | 要記住的人/事    | 「Jason 喜歡從數據出發聊」 |
| `belief`    | 認知/原則        | 「永遠先問 WHY」           |
| `reference` | 資料/連結        | 「這篇論文值得精讀」       |
| `question`  | 待解答的問題     | 「為什麼 LLM 會幻覺？」    |
| `highlight` | 值得摘錄的金句   | 「時間比金錢更稀缺」       |
| `person`    | 聯絡人資訊       | 「陳教授，清華，AI 方向」  |

### 2. 🗄 本地文件系統 — 你的數據，完全掌控

所有信息以 Markdown 文件形式存於本地，沒有雲端黑箱：

```
~/.openclaw/workspace/
│
├── 00_inbox/              ← 所有原始輸入，永不刪除
├── 02_work/
│   ├── tasks/             ← ⚡ 任務卡片
│   ├── tasks_master.md    ← 任務總索引
│   ├── waiting.md         ← 👀 跟進中清單
│   ├── calendar.md        ← 📅 每日行程（自動同步）
│   └── gmail.md           ← 📧 郵件摘要（自動寫入）
├── 03_life/
│   └── daily_logs/        ← 📝 每日記憶
└── 04_knowledge/
    ├── people/            ← 🧑 聯絡人卡片
    ├── beliefs/           ← 💡 決策智慧（Naval / Munger 等）
    └── roadmap.md         ← 長期路線圖
```

### 3. ⏰ 主動提醒 — 不需要你去翻待辦

- **每日晨報** 08:00 自動發送：今日行程 + 逾期任務 + 郵件摘要
- **截止日提醒**：捕捉到 deadline 後自動排程，到時主動找你
- **Heartbeat**：定期掃描工作區，主動推送需要關注的事項
- **逾期掃描**：每晚 20:30 掃描所有未完成項目

### 4. 📧 郵件 + 日曆自動摘要

| 數據源            | 更新頻率   | 輸出                  |
| ----------------- | ---------- | --------------------- |
| Gmail             | 每日 07:10 | `02_work/gmail.md`    |
| Feishu Calendar   | 每日 07:00 | `02_work/calendar.md` |
| Outlook / QQ Mail | 可配置     | `02_work/*-mail.md`   |

### 5. 🧠 決策智慧注入

每次對話自動注入 Naval Ravikant、Charlie Munger、Ray Dalio 等人的核心思維框架，讓秘書的建議有更深的認知底色。

---

## 系統架構

```
[你的輸入]
  Telegram / Feishu / Discord / Slack
          │
          ▼
  ┌──────────────────┐
  │   OpenClaw 閘道   │  ← 多頻道接收，統一路由
  └────────┬─────────┘
           │
     ┌─────▼──────┐         ┌──────────────┐
     │  Capture   │         │    Cron      │
     │   Agent    │         │  Scheduler   │  ← 晨報 / 提醒 / 郵件摘要
     └─────┬──────┘         └──────┬───────┘
           │                       │
           ▼                       ▼
  ┌─────────────────────────────────────┐
  │         assistant_hub (本地文件系統)  │
  │   Markdown 卡片 · 任務索引 · 日誌     │
  └──────────────────┬──────────────────┘
                     │
                     ▼
              ┌─────────────┐
              │  Heartbeat  │  ← 主動掃描 → 主動推送
              └─────────────┘
```

---

## 快速開始（Ken 的個人版）

> ⚠️ **這是個人生產環境版本，不是開箱即用的公開產品。**  
> 公開易用版 (Kairo) 正在規劃中。

### 環境要求

- Node.js >= 22
- pnpm >= 9
- Linux / macOS（推薦 Ubuntu 22.04+）

### 安裝

```bash
git clone https://github.com/sou350121/Kairo-KenVersion.git
cd Kairo-KenVersion
pnpm install
pnpm ui:build
pnpm build
```

### 配置（核心三項）

**1. 頻道（Telegram 或 Feishu）**

```json
// ~/.openclaw/openclaw.json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "YOUR_BOT_TOKEN"
    }
  }
}
```

**2. LLM 提供者**

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai-codex/gpt-5.3-codex"
      }
    }
  }
}
```

**3. 啟動**

```bash
# 一鍵啟動（systemd 管理）
node scripts/run-node.mjs gateway --port 18789

# 或用 Docker
docker-compose up -d
```

打開控制台：http://localhost:18789

---

## 支援的頻道

| 頻道          | 狀態        | 備註                   |
| ------------- | ----------- | ---------------------- |
| Telegram      | ✅ 完整支援 | 推薦首選               |
| Feishu / Lark | ✅ 完整支援 | WebSocket，無需公網 IP |
| Discord       | ✅ 支援     |                        |
| Slack         | ✅ 支援     |                        |
| WhatsApp      | 🚧 測試中   |                        |
| WeChat        | 🚧 規劃中   | 需備用帳號             |

---

## 項目結構

```
Kairo-KenVersion/
├── src/                    ← 核心源碼（OpenClaw 基礎 + Kairo 擴展）
│   ├── auto-reply/         ← 捕捉 Agent、Hub Context 注入
│   ├── cron/               ← 定時任務引擎
│   ├── gateway/            ← 多頻道閘道
│   └── infra/              ← Heartbeat、系統事件
├── scripts/
│   └── capture/            ← 郵件摘要、日曆同步、任務掃描腳本
├── extensions/
│   └── feishu/             ← Feishu channel plugin
├── ui/                     ← 控制台 Web UI（Lit + Vite）
└── ~/.openclaw/            ← 用戶數據（不在 repo 中）
    ├── openclaw.json        ← 主配置
    ├── workspace/           ← assistant_hub 工作區
    └── cron/jobs.json       ← 定時任務持久化
```

---

## 路線圖

- [x] 多頻道捕捉（Telegram / Feishu）
- [x] 智能意圖識別（10 種類型）
- [x] 本地 Markdown 文件系統
- [x] 每日晨報 + 自動提醒
- [x] 郵件摘要（Gmail / Feishu Calendar）
- [x] Heartbeat 主動推送
- [x] 聯絡人記憶卡片
- [x] 決策智慧注入（Naval / Munger / Dalio 等）
- [ ] 公開易用版（一鍵 Docker 部署）
- [ ] Setup Wizard（5分鐘完成配置）
- [ ] 多語言支援
- [ ] 移動端 App

---

## 致謝

Kairo 基於 **[OpenClaw](https://github.com/openclaw/openclaw)** 構建。感謝 OpenClaw 團隊提供堅實的多頻道 AI 閘道基礎。

---

## License

MIT License — 詳見 [LICENSE](./LICENSE)
