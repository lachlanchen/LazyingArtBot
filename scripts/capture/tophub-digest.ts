/**
 * scripts/capture/tophub-digest.ts
 *
 * 今日热榜精选 — 使用 tophubdata.com 官方 API
 * 每日 07:08 自动抓取，写入 02_work/tophub-digest.md，可推送到 Telegram。
 *
 * 环境变量：
 *   TOPHUB_API_KEY                         API Key（必须）
 *   CAPTURE_TOPHUB_NODES                   逗号分隔的 hashid 列表（可选，默认精选6个）
 *   CAPTURE_TOPHUB_TOP_N                   每个源取前几条（默认 5）
 *   CAPTURE_TOPHUB_PUSH_ENABLED            是否推送（默认 false）
 *   CAPTURE_TOPHUB_PUSH_DRY_RUN            dry-run（默认 true）
 *   CAPTURE_TOPHUB_PUSH_CHANNEL            推送频道（默认 telegram）
 *   CAPTURE_TOPHUB_PUSH_TO                 推送目标 chat_id
 *   CAPTURE_TOPHUB_PUSH_ACCOUNT_ID         账号 ID
 */

import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { initHub, writeText, tokyoYmd, envBool } from "./_utils.js";

const API_BASE = "https://api.tophubdata.com";

// Ken 精选：科技创业 + 财经 + AI + 生产力 + GitHub
const DEFAULT_NODES: Array<{ hashid: string; name: string }> = [
  { hashid: "Q1Vd5Ko85R", name: "36氪" },
  { hashid: "5VaobgvAj1", name: "虎嗅网" },
  { hashid: "DOvnNz1vEB", name: "机器之心" },
  { hashid: "G2me3ndwjq", name: "华尔街见闻" },
  { hashid: "Y2KeDGQdNP", name: "少数派" },
  { hashid: "rYqoXQ8vOD", name: "GitHub Trending" },
];

type NodeItem = { title: string; url: string; extra?: string };
type NodeData = { name: string; items: NodeItem[] };

async function fetchNode(apiKey: string, hashid: string): Promise<NodeData | null> {
  try {
    const resp = await fetch(`${API_BASE}/nodes/${hashid}`, {
      headers: { Authorization: apiKey },
      signal: AbortSignal.timeout(15_000),
    });
    if (!resp.ok) {
      return null;
    }
    const d = (await resp.json()) as {
      error?: boolean;
      data?: { name?: string; items?: NodeItem[] };
    };
    if (d.error || !d.data) {
      return null;
    }
    return { name: d.data.name ?? hashid, items: d.data.items ?? [] };
  } catch {
    return null;
  }
}

function runOpenclawMessageSend(params: {
  pushChannel: string;
  pushTo: string;
  text: string;
  pushAccountId?: string;
  pushDryRun: boolean;
}) {
  const cliBin = (process.env.CAPTURE_TOPHUB_PUSH_CLI_BIN ?? "openclaw").trim() || "openclaw";
  const sendArgs = [
    "message",
    "send",
    "--channel",
    params.pushChannel,
    "--target",
    params.pushTo,
    "--message",
    params.text,
  ];
  if (params.pushAccountId) {
    sendArgs.push("--account", params.pushAccountId);
  }
  if (params.pushDryRun) {
    sendArgs.push("--dry-run");
  }

  let result = spawnSync(cliBin, sendArgs, { encoding: "utf8", env: process.env });
  if (result.status !== 0) {
    for (const ep of [
      path.join(os.homedir(), ".openclaw", "dist", "entry.js"),
      path.join(process.cwd(), "dist", "entry.js"),
    ]) {
      result = spawnSync(process.execPath, [ep, ...sendArgs], {
        encoding: "utf8",
        env: process.env,
      });
      if (result.status === 0) {
        break;
      }
    }
  }
  return result;
}

async function main() {
  const apiKey = (process.env.TOPHUB_API_KEY ?? "").trim();
  if (!apiKey) {
    console.error("[tophub-digest] TOPHUB_API_KEY not set — skipping");
    process.exit(0);
  }

  const topN = Math.max(1, Math.min(20, Number(process.env.CAPTURE_TOPHUB_TOP_N ?? "5") || 5));
  const pushEnabled = envBool("CAPTURE_TOPHUB_PUSH_ENABLED", false);
  const pushDryRun = envBool("CAPTURE_TOPHUB_PUSH_DRY_RUN", true);
  const pushChannel = (process.env.CAPTURE_TOPHUB_PUSH_CHANNEL ?? "telegram").trim() || "telegram";
  const pushTo = (process.env.CAPTURE_TOPHUB_PUSH_TO ?? "").trim();
  const pushAccountId = (process.env.CAPTURE_TOPHUB_PUSH_ACCOUNT_ID ?? "").trim() || undefined;

  // Allow override via env
  const nodeList: Array<{ hashid: string; name: string }> = process.env.CAPTURE_TOPHUB_NODES
    ? process.env.CAPTURE_TOPHUB_NODES.split(",")
        .map((s) => s.trim())
        .filter(Boolean)
        .map((hashid) => ({ hashid, name: hashid }))
    : DEFAULT_NODES;

  const paths = await initHub();
  const today = tokyoYmd();

  console.log(`[tophub-digest] fetching ${nodeList.length} nodes for ${today}...`);

  const results: Array<{ name: string; items: NodeItem[] }> = [];

  await Promise.all(
    nodeList.map(async ({ hashid, name: fallbackName }) => {
      const data = await fetchNode(apiKey, hashid);
      if (data && data.items.length > 0) {
        results.push({ name: data.name || fallbackName, items: data.items.slice(0, topN) });
        console.log(`[tophub-digest] ${data.name}: ${data.items.length} items`);
      } else {
        console.warn(`[tophub-digest] ${fallbackName} (${hashid}): no data`);
      }
    }),
  );

  if (results.length === 0) {
    console.warn("[tophub-digest] No data fetched");
    process.exit(0);
  }

  // Sort: preserve DEFAULT_NODES order
  const orderMap = new Map(nodeList.map((n, i) => [n.hashid, i]));
  results.sort((a, b) => {
    const ia = nodeList.find((n) => n.name === a.name || results.indexOf(a) >= 0)
      ? (orderMap.get(nodeList.find((n) => n.name === a.name)?.hashid ?? "") ?? 99)
      : 99;
    return ia - 99;
  });

  // Build markdown
  const mdLines: string[] = [`# 今日热榜精选  ${today}`, ""];
  const pushLines: string[] = [`📰 今日热榜精选 ${today}\n`];

  for (const { name, items } of results) {
    mdLines.push(`## ${name}`);
    pushLines.push(`【${name}】`);
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const heat = item.extra ? ` _(${item.extra})_` : "";
      mdLines.push(`${i + 1}. [${item.title}](${item.url})${heat}`);
      pushLines.push(`${i + 1}. ${item.title}`);
    }
    mdLines.push("");
    pushLines.push("");
  }

  mdLines.push(`\nupdated: ${today}`);

  const mdContent = mdLines.join("\n");
  const outPath = path.join(paths.work, "tophub-digest.md");
  await writeText(outPath, mdContent);
  console.log(`[tophub-digest] written → ${outPath}`);

  if (pushEnabled) {
    if (!pushTo) {
      console.warn("[tophub-digest] CAPTURE_TOPHUB_PUSH_TO not set, skipping push");
    } else {
      const pushText = pushLines.join("\n").slice(0, 4000);
      const run = runOpenclawMessageSend({
        pushChannel,
        pushTo,
        text: pushText,
        pushAccountId,
        pushDryRun,
      });
      if (run.status === 0) {
        console.log("[tophub-digest] push OK");
      } else {
        console.warn("[tophub-digest] push failed:", run.stderr || run.stdout);
      }
    }
  }
}

main().catch((err) => {
  console.error("[tophub-digest] fatal:", err);
  process.exit(1);
});
