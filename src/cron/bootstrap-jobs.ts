import type { CronService } from "./service.js";
import { resolveHubPaths } from "../capture-agent/hub.js";

const DAILY_BRIEFING_JOB_NAME = "每日晨報";
const MONTHLY_DIGEST_JOB_NAME = "月度記憶壓縮";
const QUEUE_ARCHIVE_JOB_NAME = "佇列歸檔";
const USAGE_DAILY_SUMMARY_JOB_NAME = "每日用量摘要";
const AUTH_HEALTH_CHECK_JOB_NAME = "Auth Token 健康檢查";

const FIRST_RUN_SENTINEL_JOB_NAME = "首次啟動歡迎（標記）";
const FIRST_RUN_WELCOME_JOB_NAME = "首次啟動歡迎訊息";
const FIRST_RUN_BRIEFING_JOB_NAME = "首次啟動晨報";

function buildFirstRunWelcomeMessage(): string {
  return [
    "🌟 Kairo 已啟動，你的 AI 秘書上線了",
    "",
    "我已完成初始化，以下功能立即可用：",
    "",
    "📝  說出任何事 → 我自動分類、建卡、設提醒",
    "     「提醒我明天下午 3 點開會」",
    "     「記一下：Jason 是百度前 PM」",
    "",
    "📋  每日晨報 — 07:10 自動發送（今日馬上發）",
    "📚  語言課程 — 08:00",
    "🏃  健康提醒 — 07:30",
    "💓  心跳巡邏 — 每 30 分鐘（07:00-23:30）",
    "",
    "完成後請使用 message 工具發送到 telegram，accountId=channel2，target=1898430254。",
  ].join("\n");
}

function buildDailyBriefingMessage(): string {
  const hubPaths = resolveHubPaths();
  const formatInstructions = [
    "請按以下格式輸出晨報（Telegram 友好格式）：",
    "",
    "📋 今日計劃 — {YYYY年M月D日 週X}",
    "━━━━━━━━━━━━━━━━━━━━━━━━━",
    "",
    "🔴 立即行動（逾期 + 今日到期）",
    "  • [優先級] 任務名 — 逾期 N 天 / 截止 HH:MM",
    "  （若無此類任務，輸出「✅ 無緊急項目」）",
    "",
    "🟡 今日可處理（今日到期但非緊急）",
    "  • [優先級] 任務名 — 截止 HH:MM",
    "  （若無，省略此段）",
    "",
    "🟢 本週待辦",
    "  • [優先級] 任務名 — 截止日期",
    "  （最多列 5 條）",
    "",
    "━━━━━━━━━━━━━━━━━━━━━━━━━",
    "💡 {一句行為洞察，如：上週有 3 個任務連續推遲，建議今日重新評估優先級}",
    "",
    "完成後請使用 message 工具發送到 telegram，accountId=channel2，target=1898430254。",
  ].join("\n");

  return [
    `【每日工作晨報】`,
    ``,
    `請執行以下步驟並向 Ken 發送今日摘要：`,
    ``,
    `1. read ${hubPaths.work}/tasks_master.md`,
    `   找出所有 [ ] 未完成條目，提取 title、id、due date、priority`,
    ``,
    `2. 按 due date 分類：`,
    `   - 逾期（due date < 今天）`,
    `   - 今日到期（due date = 今天）`,
    `   - 本週到期（due date 在今後 7 天內）`,
    `   - 無 due date / 長期`,
    ``,
    `3. ${formatInstructions}`,
    ``,
    `4. 如有逾期任務，判斷是否需要立即處理：`,
    `   可執行的 → 直接執行並更新狀態（status: done + tasks_master [x]）`,
    `   需 Ken 決策的 → 在晨報中列出並說明`,
    ``,
    `5. 如果今天是週一，在晨報最後加一行趨勢（不需要 Ken 回應）：`,
    `   a. 統計 tasks_master.md 上週（7天內）新增的 [x] 完成數 vs [ ] 未完成數`,
    `   b. 找出標題重複出現超過2次的任務（代表一直被推遲）`,
    `   c. 輸出一行：「📊 上週完成 X 項，Y 項連續推遲中」`,
    `   d. 同步更新 ${hubPaths.knowledge}/patterns.md（見下方格式）`,
    ``,
    `   patterns.md 格式（10行以內，舊內容覆蓋）：`,
    `   # 行為模式（自動維護，Ken 不需閱讀）`,
    `   更新：YYYY-MM-DD`,
    `   - 完成率：上週 X/Y`,
    `   - 常推遲類型：[列出 type 或關鍵字]`,
    `   - 待注意：[1-2條可操作的觀察]`,
  ].join("\n");
}

function buildMonthlyDigestMessage(): string {
  const hubPaths = resolveHubPaths();
  return [
    `【月度記憶壓縮】`,
    ``,
    `請執行以下步驟（靜默完成，不需要通知 Ken）：`,
    ``,
    `1. 計算上個月的年月（YYYY-MM），例如今天是 3 月 1 日 → 上個月是 2 月 → "2026-02"`,
    ``,
    `2. 列出 ${hubPaths.dailyLogs}/ 下所有符合 {YYYY-MM}-*.md 的文件並逐一閱讀`,
    ``,
    `3. 將內容壓縮成 300 字以內的月摘要，格式：`,
    `   # {YYYY-MM} 月摘要`,
    `   更新：{today}`,
    ``,
    `   ## 主要事件`,
    `   （3-5 條最重要的事，每條一行）`,
    ``,
    `   ## 重要決策`,
    `   （做了哪些決定，各一行）`,
    ``,
    `   ## 人脈互動`,
    `   （提到了哪些重要的人、發生了什麼）`,
    ``,
    `4. 寫入 ${hubPaths.knowledge}/monthly_digest/{YYYY-MM}.md`,
    `   若文件已存在則覆蓋`,
    ``,
    `5. 完成後回覆一行確認：「月摘要已生成：{YYYY-MM}，共 N 天記錄」`,
  ].join("\n");
}

/**
 * Detects a fresh install (no sentinel job exists) and schedules a one-time
 * welcome message + immediate morning briefing.
 * Idempotent — the sentinel job prevents re-running on subsequent startups.
 */
async function ensureFirstRunOnboarding(cron: CronService): Promise<void> {
  const jobs = await cron.list({ includeDisabled: true });

  // Already ran once — skip entirely
  if (jobs.some((j) => j.name === FIRST_RUN_SENTINEL_JOB_NAME)) {
    return;
  }

  const now = Date.now();
  const in3s = new Date(now + 3_000).toISOString();
  const in8s = new Date(now + 8_000).toISOString();

  // 立即發歡迎消息（3 秒後）
  if (!jobs.some((j) => j.name === FIRST_RUN_WELCOME_JOB_NAME)) {
    await cron.add({
      name: FIRST_RUN_WELCOME_JOB_NAME,
      description: "首次啟動：發送歡迎消息",
      schedule: { kind: "at", at: in3s, tz: "Asia/Shanghai" },
      agentId: "executor",
      sessionTarget: "isolated",
      wakeMode: "now",
      enabled: true,
      deleteAfterRun: true,
      payload: {
        kind: "agentTurn",
        message: buildFirstRunWelcomeMessage(),
        deliver: true,
        channel: "telegram",
        bestEffortDeliver: true,
      },
    });
  }

  // 立即跑晨報（8 秒後）
  if (!jobs.some((j) => j.name === FIRST_RUN_BRIEFING_JOB_NAME)) {
    await cron.add({
      name: FIRST_RUN_BRIEFING_JOB_NAME,
      description: "首次啟動：立即晨報",
      schedule: { kind: "at", at: in8s, tz: "Asia/Shanghai" },
      agentId: "executor",
      sessionTarget: "isolated",
      wakeMode: "now",
      enabled: true,
      deleteAfterRun: true,
      payload: {
        kind: "agentTurn",
        message: buildDailyBriefingMessage(),
        deliver: true,
        channel: "telegram",
        bestEffortDeliver: true,
      },
    });
  }

  // 建立持久哨兵（disabled，永不執行，只用作標記）
  await cron.add({
    name: FIRST_RUN_SENTINEL_JOB_NAME,
    description: "首次啟動完成標記（請勿刪除）",
    schedule: { kind: "at", at: "2099-12-31T00:00:00.000Z", tz: "Asia/Shanghai" },
    agentId: "executor",
    sessionTarget: "isolated",
    wakeMode: "now",
    enabled: false,
    deleteAfterRun: false,
    payload: {
      kind: "agentTurn",
      message: "sentinel",
      deliver: false,
      channel: "last",
      bestEffortDeliver: false,
    },
  });
}

/**
 * Ensures bootstrap cron jobs exist.
 * Idempotent — safe to call on every startup.
 */
export async function ensureBootstrapJobs(cron: CronService): Promise<void> {
  try {
    await ensureFirstRunOnboarding(cron);

    const jobs = await cron.list({ includeDisabled: true });

    if (!jobs.some((j) => j.name === DAILY_BRIEFING_JOB_NAME)) {
      await cron.add({
        name: DAILY_BRIEFING_JOB_NAME,
        description: "auto-created: proactive daily morning briefing",
        schedule: { kind: "cron", expr: "10 7 * * *", tz: "Asia/Shanghai" },
        sessionTarget: "isolated",
        payload: {
          kind: "agentTurn",
          message: buildDailyBriefingMessage(),
          deliver: true,
          channel: "last",
          bestEffortDeliver: true,
        },
      });
    }

    if (!jobs.some((j) => j.name === MONTHLY_DIGEST_JOB_NAME)) {
      await cron.add({
        name: MONTHLY_DIGEST_JOB_NAME,
        description: "auto-created: monthly memory compression on 1st of each month",
        schedule: { kind: "cron", expr: "0 8 1 * *", tz: "Asia/Shanghai" },
        sessionTarget: "isolated",
        payload: {
          kind: "agentTurn",
          message: buildMonthlyDigestMessage(),
          deliver: true,
          channel: "last",
          bestEffortDeliver: true,
        },
      });
    }
    if (!jobs.some((j) => j.name === QUEUE_ARCHIVE_JOB_NAME)) {
      await cron.add({
        name: QUEUE_ARCHIVE_JOB_NAME,
        description:
          "auto-created: monthly archive of consumed reasoning_queue and feedback_signals",
        schedule: { kind: "cron", expr: "0 4 2 * *", tz: "Asia/Shanghai" },
        agentId: "reviewer",
        sessionTarget: "isolated",
        wakeMode: "now",
        enabled: true,
        payload: {
          kind: "agentTurn",
          message: [
            "【佇列歸檔】",
            "",
            "請執行佇列歸檔腳本：",
            "  node scripts/capture/queue-archive.ts",
            "",
            "歸檔 reasoning_queue.jsonl 和 feedback_signals.jsonl 中 90 天前已消費的條目到 archive/ 子目錄。",
            "完成後回覆一行確認：「佇列歸檔完成：reasoning_queue 歸檔 N 條，feedback_signals 歸檔 M 條」",
          ].join("\n"),
          deliver: true,
          channel: "last",
          bestEffortDeliver: true,
        },
      });
    }
    if (!jobs.some((j) => j.name === USAGE_DAILY_SUMMARY_JOB_NAME)) {
      await cron.add({
        name: USAGE_DAILY_SUMMARY_JOB_NAME,
        description: "auto-created: daily token usage summary at 22:00",
        schedule: { kind: "cron", expr: "0 22 * * *", tz: "Asia/Shanghai" },
        agentId: "reviewer",
        sessionTarget: "isolated",
        wakeMode: "now",
        enabled: true,
        payload: {
          kind: "agentTurn",
          message: [
            "【每日用量摘要】",
            "",
            "請執行每日 Token 用量統計腳本：",
            "  cd /opt/LazyingArtBot && (pnpm moltbot:capture:usage-daily-summary || node --import tsx scripts/capture/usage-daily-summary.ts)",
            "",
            "取得輸出後，使用 message 工具將結果原文發送到 telegram，accountId=channel2，target=1898430254。",
            "如果腳本不存在或報錯，發送「今日用量統計暫不可用」。",
          ].join("\n"),
          deliver: true,
          channel: "last",
          bestEffortDeliver: true,
        },
      });
    }
    if (!jobs.some((j) => j.name === AUTH_HEALTH_CHECK_JOB_NAME)) {
      await cron.add({
        name: AUTH_HEALTH_CHECK_JOB_NAME,
        description: "auto-created: daily OAuth token expiry check at 09:00",
        schedule: { kind: "cron", expr: "0 9 * * *", tz: "Asia/Shanghai" },
        agentId: "executor",
        sessionTarget: "isolated",
        wakeMode: "now",
        enabled: true,
        payload: {
          kind: "agentTurn",
          message: [
            "【Auth Token 健康檢查】",
            "",
            "請靜默執行以下操作：",
            "1. 讀取 /root/.openclaw/agents/main/agent/auth-profiles.json",
            "2. 找出所有有 expires 字段的 profile",
            "3. 計算每個 profile 的剩餘時間（expires - 當前時間戳毫秒）",
            "4. 如果任何 profile 剩餘時間 < 3 天（259200000 毫秒），",
            "   使用 message 工具發送警告到 telegram，accountId=channel2，target=1898430254：",
            "   ⚠️ Auth Token 即將過期：[profile_id] 剩餘 [X] 天，請重新授權。",
            "5. 如果所有 token 狀態正常，不需要發送任何消息（靜默完成）",
          ].join("\n"),
          deliver: true,
          channel: "last",
          bestEffortDeliver: true,
        },
      });
    }
  } catch {
    // best-effort: don't fail gateway startup if bootstrap fails
  }
}
