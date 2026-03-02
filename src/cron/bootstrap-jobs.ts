import type { CronService } from "./service.js";
import { resolveHubPaths } from "../capture-agent/hub.js";

const DAILY_BRIEFING_JOB_NAME = "每日晨報";
const MONTHLY_DIGEST_JOB_NAME = "月度記憶壓縮";
const QUEUE_ARCHIVE_JOB_NAME = "佇列歸檔";

function buildDailyBriefingMessage(): string {
  const hubPaths = resolveHubPaths();
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
    `3. 向 Ken 發送簡潔晨報（繁體中文）：`,
    `   📋 今日工作摘要 (YYYY-MM-DD)`,
    `   ⚠️ 逾期 N 項 / 📅 今日到期 N 項 / 📆 本週到期 N 項`,
    `   每項一行：優先級 + 標題 + due date`,
    `   若全部完成 → 回覆「今日無待辦事項 ✅」`,
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
 * Ensures bootstrap cron jobs exist.
 * Idempotent — safe to call on every startup.
 */
export async function ensureBootstrapJobs(cron: CronService): Promise<void> {
  try {
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
  } catch {
    // best-effort: don't fail gateway startup if bootstrap fails
  }
}
