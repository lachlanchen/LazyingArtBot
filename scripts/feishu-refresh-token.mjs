#!/usr/bin/env node
/**
 * Standalone Feishu token refresh script.
 * Run daily (e.g. 06:55 via cron) to keep user_access_token alive.
 * No LLM dependency — safe to call even when gateway is down.
 *
 * Usage: node /opt/LazyingArtBot/scripts/feishu-refresh-token.mjs
 */
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const FEISHU_BASE = "https://open.feishu.cn/open-apis";
const STATE_DIR =
  process.env.OPENCLAW_STATE_DIR?.trim() ||
  process.env.KAIRO_HOME?.trim() ||
  path.join(os.homedir(), ".openclaw");
const TOKEN_FILE = path.join(STATE_DIR, "feishu_user_token.json");
const APP_ID = process.env.FEISHU_APP_ID ?? "cli_a92aeaf256389cd3";
const APP_SECRET = process.env.FEISHU_APP_SECRET ?? "hXdW0z6oMt4jShvylSwesggRSyEaUdnM";

async function main() {
  const raw = await fs.readFile(TOKEN_FILE, "utf8").catch(() => null);
  if (!raw) {
    console.error("[feishu-refresh] token file not found:", TOKEN_FILE);
    process.exit(1);
  }

  const stored = JSON.parse(raw);
  const ageSeconds = (Date.now() - new Date(stored.obtained_at).getTime()) / 1000;
  const isExpired = ageSeconds > stored.expires_in - 300;

  if (!isExpired) {
    console.log(
      `[feishu-refresh] token still valid (${Math.floor((stored.expires_in - ageSeconds) / 60)} min remaining), skipping`,
    );
    process.exit(0);
  }

  console.log("[feishu-refresh] token expired, refreshing...");

  // Get app_access_token
  const appRes = await fetch(`${FEISHU_BASE}/auth/v3/app_access_token/internal`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ app_id: APP_ID, app_secret: APP_SECRET }),
  });
  const appData = await appRes.json();
  if (appData.code !== 0) {
    console.error("[feishu-refresh] failed to get app_access_token:", appData.code, appData.msg);
    process.exit(1);
  }

  // OIDC refresh
  const refreshRes = await fetch(`${FEISHU_BASE}/authen/v1/oidc/refresh_access_token`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${appData.app_access_token}`,
    },
    body: JSON.stringify({ grant_type: "refresh_token", refresh_token: stored.refresh_token }),
  });
  const rd = await refreshRes.json();

  if (rd.code === 0) {
    stored.access_token = rd.data.access_token;
    if (rd.data.refresh_token) {
      stored.refresh_token = rd.data.refresh_token;
    }
    stored.obtained_at = new Date().toISOString();
    await fs.writeFile(TOKEN_FILE, JSON.stringify(stored, null, 2));
    console.log("[feishu-refresh] ✅ refreshed OK, new obtained_at:", stored.obtained_at);
    process.exit(0);
  }

  // OIDC failed — try legacy endpoint
  const legacyRes = await fetch(`${FEISHU_BASE}/authen/v1/refresh_access_token`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      app_id: APP_ID,
      app_secret: APP_SECRET,
      grant_type: "refresh_token",
      refresh_token: stored.refresh_token,
    }),
  });
  const ld = await legacyRes.json();
  if (ld.code === 0 && ld.data?.access_token) {
    stored.access_token = ld.data.access_token;
    if (ld.data.refresh_token) {
      stored.refresh_token = ld.data.refresh_token;
    }
    stored.obtained_at = new Date().toISOString();
    await fs.writeFile(TOKEN_FILE, JSON.stringify(stored, null, 2));
    console.log(
      "[feishu-refresh] ✅ refreshed via legacy endpoint, obtained_at:",
      stored.obtained_at,
    );
    process.exit(0);
  }

  console.error(
    "[feishu-refresh] ❌ both refresh endpoints failed. OIDC:",
    rd.code,
    rd.message,
    "| Legacy:",
    ld.code,
    ld.msg,
  );
  console.error(
    "[feishu-refresh] Manual re-auth needed: sudo node /opt/LazyingArtBot/scripts/feishu-oauth.mjs <CODE>",
  );
  process.exit(1);
}

main().catch((e) => {
  console.error("[feishu-refresh] fatal:", e);
  process.exit(1);
});
