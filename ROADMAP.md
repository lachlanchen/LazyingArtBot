# 長期路線圖

## 變革命題（Thesis）

> 所有現有的 AI 工具都是 **Pull** 模式：你問，它答；你不問，它沉默。
> Kairo 的賭注是：**真正有價值的 AI 應該是 Push** — 它知道你要什麼，在你開口之前就行動，在你遺忘之前就提醒，在你分心之前就閉環。

這個領域目前的天花板：

| 現有方案                               | 缺陷                                     |
| -------------------------------------- | ---------------------------------------- |
| ChatGPT / Claude                       | 無記憶、無自主、對話即消失               |
| Notion AI / 工具嵌入 AI                | 跨不出單一工具的圍牆                     |
| AutoGPT / 各種 agent framework         | 強大但需要不斷 babysit，一個任務跑完就死 |
| Leon / OwnPilot / open-source 個人助手 | skill-based chatbot，沒有持久身份和閉環  |

**Kairo 要佔領的空白**：一個活在你的服務器上、持續運行、主動推進你生活的 AI 協調層。不是工具，是基礎設施。

---

## 長期願景

**Kairo 成為個人的 AI OS** — 不是你打開的 app，而是在後台持續運行的第二個自己。它知道你的目標、習慣、人脈和截止日，在你分心的時候保持世界繼續轉動。

具體地說，當這個系統成熟時：

- 你說「做這件事」→ Kairo 分解、委派、追蹤、閉環，不需要你再管
- 你說「幫我研究這個方向」→ Kairo 調研、摘要、整理進你的知識庫
- 你什麼都不說 → Kairo 每天早上主動告訴你今天最重要的事是什麼

---

## 個人目標（Ken，當前）

| 目標              | 關鍵結果                      |
| ----------------- | ----------------------------- |
| 論文發表          | 初稿→修改→投稿至目標期刊/會議 |
| 大比賽            | 完成參賽作品、提交、取得結果  |
| 論文截稿          | 待填                          |
| 比賽名稱 & 截稿日 | 待填                          |

**當前季度里程碑**

- [ ] 確定研究問題 & 方法論
- [ ] 完成文獻回顧 & 實驗設計
- [ ] 完成初稿（Introduction + Methods）
- [ ] 研究比賽規則 & 評分標準

---

## Kairo 系統路線圖

### 現狀基線

```
[Telegram / Feishu] → [openclaw gateway] → [LLM agent]
                                               ↓
                       [capture → cron → heartbeat → hub-context]
                                               ↓
                           [Calendar / Gmail / Tophub / Tasks]
```

已實現：**被動捕獲 + 主動提醒**。Ken 說一件事，Kairo 記住並追蹤。

---

### Phase 1 — 研究夥伴

**要解決的問題**：現有 AI 工具幫不了研究者真正的工作流 — 文獻太多看不完，實驗結果分散難追蹤，寫作靈感與數據脫節。

**Kairo 做法**：成為 Ken 論文工作流的主動參與者，而不是被問到才回答的查詢工具。

- [ ] **arXiv 每日監控** — 自動抓取相關方向新論文 → 精選摘要 → 推送 + 寫入 knowledge base
- [ ] **文獻調研 tool** — 整合 [gpt-researcher](https://github.com/assafelovic/gpt-researcher)，一句話觸發深度調研
- [ ] **實驗追蹤** — `experiments/` 目錄 + LLM tool，自動對比多輪結果，標注異常
- [ ] **寫作協作** — 借鑒 [AgentLaboratory](https://github.com/SamuelSchmidgall/AgentLaboratory) 流程：文獻→實驗→初稿三段式，Kairo 作為入口統一調度

**這個 phase 的核心變革**：研究者第一次不需要親自「管理信息」，Kairo 把相關信息主動推到 Ken 面前。

---

### Phase 2 — MCP 樞紐

**要解決的問題**：現在每個 AI 工具都是孤島，Claude 不知道你的任務列表，ChatGPT 不知道你的日曆，agent framework 不知道你的習慣。

**Kairo 做法**：把自己變成標準接口，讓任何 agent 都能讀取 Ken 的個人數據。

```
[Claude Desktop / ChatGPT / 任意 agent]
            ↓  MCP protocol
    [Kairo MCP Server]
      ├── calendar（飛書日曆）
      ├── tasks（tasks_master.md）
      ├── waiting（waiting.md）
      ├── research（research_notes/）
      └── people（people/ 人脈卡片）
```

- [ ] **Kairo MCP Server**（`src/mcp/`）— 把 Ken 的個人數據暴露為標準 MCP resource/tool
- [ ] **MCP client** — Kairo 自己也作為 client，調用外部 MCP server（filesystem、github、web-search）

**這個 phase 的核心變革**：Ken 的個人上下文從封閉系統變成開放基礎設施，任何工具都能「認識」Ken。

---

### Phase 3 — Swarm 調度

**要解決的問題**：複雜任務無法靠一個 LLM 對話完成，現有 swarm 框架強大但沒有「了解你的那個人」作為協調中心。

**Kairo 做法**：成為 swarm 的 orchestrator，把任務分派給最合適的 worker agent，自己只負責理解 Ken 的意圖和最終確認。

```
[Ken 的意圖]
      ↓
[Kairo Orchestrator — 了解 Ken 的目標/習慣/限制]
      ├── Research Agent（文獻 / 寫作）
      ├── Code Agent（實驗 / 腳本）
      ├── Calendar Agent（排程 / 提醒）
      ├── Web Agent（信息收集 / 表單）
      └── Email Agent（起草 / 篩選）
```

- [ ] **整合 [agency-swarm](https://github.com/VRSEN/agency-swarm) 或 OpenAI Agents SDK** 作為執行層
- [ ] **Bounded autonomy** — 每個 worker agent 有明確 scope；高風險操作（對外發信、刪文件）必須 Ken 確認
- [ ] **Audit trail** — 所有 agent 行動寫入 `~/.openclaw/audit.jsonl`，可回溯

**這個 phase 的核心變革**：Ken 第一次可以委派整件事，而不只是委派一個步驟。

---

### Phase 4 — 開源：讓任何人都能擁有自己的 Kairo

**要解決的問題**：個人 AI OS 不應該只有技術人員才能用。現有開源方案（Leon、OwnPilot）要麼太重，要麼沒有真正的自主閉環。

**Kairo 的差異化定位**：

| 對比 | Leon / OwnPilot | Kairo                        |
| ---- | --------------- | ---------------------------- |
| 模式 | 你呼叫，它執行  | 它主動推進，你確認           |
| 記憶 | skill 級別      | 持久身份 + 知識庫            |
| 閉環 | 無              | capture → cron → 執行 → 更新 |
| 擴展 | plugin          | MCP + swarm agent            |

- [ ] 移除 hardcoded 路徑，改 `$KAIRO_HOME`
- [ ] `install.sh` + AI 引導式 setup（非技術用戶可一鍵部署）
- [ ] `openclaw.example.json` 完整模板
- [ ] GitHub release v1.0

---

### Phase 5 — 個人 AI OS（成熟形態）

**到達這裡時，Kairo 是什麼**：

- **Self-improving** — 每週分析自己的錯誤，更新 SOUL.md / IDENTITY.md，下次更準
- **Long-term memory** — 月度壓縮 → 年度精華，Ken 的知識資產不隨記憶消退
- **Computer use** — 不只是文字建議，Kairo 直接在電腦上操作完成任務
- **關係圖譜** — `people/` 卡片升級為圖，自動識別潛在協作機會
- **跨設備** — phone / laptop / server 同一個 Kairo 上下文

**到達這裡時，Kairo 改變的不只是 Ken 的效率，而是人與 AI 協作的默認模式。**

---

## 可整合的 GitHub 項目

| 項目                                                                                    | 用途                 | 優先級 |
| --------------------------------------------------------------------------------------- | -------------------- | ------ |
| [assafelovic/gpt-researcher](https://github.com/assafelovic/gpt-researcher)             | 自動文獻調研         | 🔴 高  |
| [SamuelSchmidgall/AgentLaboratory](https://github.com/SamuelSchmidgall/AgentLaboratory) | 研究→實驗→寫作自動化 | 🔴 高  |
| [VRSEN/agency-swarm](https://github.com/VRSEN/agency-swarm)                             | multi-agent 執行層   | 🟡 中  |
| [SakanaAI/AI-Scientist-v2](https://github.com/SakanaAI/AI-Scientist-v2)                 | 自主論文生成架構參考 | 🟡 中  |
| [myshell-ai/AIlice](https://github.com/myshell-ai/AIlice)                               | IACT agent tree 架構 | 🟢 低  |

---

## 秘書備注

- 有新信息（截稿日、比賽名稱）→ 直接更新上方「個人目標」表格
- Kairo 系統路線圖進展 → Ken 告知或秘書每月回顧一次自動更新
- 每週一晨報對比當前季度里程碑進度，逾期 → 詢問是否調整
