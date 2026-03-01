// Feishu OAuth Code Exchange + Calendar ID Discovery
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const APP_ID = "cli_a92aeaf256389cd3";
const APP_SECRET = "hXdW0z6oMt4jShvylSwesggRSyEaUdnM";
const STATE_DIR =
  process.env.OPENCLAW_STATE_DIR?.trim() ||
  process.env.KAIRO_HOME?.trim() ||
  path.join(os.homedir(), ".openclaw");
const TOKEN_FILE = path.join(STATE_DIR, "feishu_user_token.json");
// Known calendar_id as fallback (from previous token)
const KNOWN_CALENDAR_ID = "feishu.cn_NiNT3twWMhJNei05w0pRWf@group.calendar.feishu.cn";

const code = process.argv[2];
if (!code) {
  console.error("Usage: node /tmp/exchange_token.mjs <CODE>");
  process.exit(1);
}

// Step 1: Get app_access_token
const appRes = await fetch("https://open.feishu.cn/open-apis/auth/v3/app_access_token/internal", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ app_id: APP_ID, app_secret: APP_SECRET }),
});
const appData = await appRes.json();
if (appData.code !== 0) {
  console.error("app_access_token failed:", appData);
  process.exit(1);
}
const appToken = appData.app_access_token;
console.log("✓ app_access_token");

// Step 2: Exchange code for user token
const tokenRes = await fetch("https://open.feishu.cn/open-apis/authen/v1/access_token", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ app_access_token: appToken, code, grant_type: "authorization_code" }),
});
const tokenData = await tokenRes.json();
if (tokenData.code !== 0) {
  console.error("Token exchange failed:", JSON.stringify(tokenData, null, 2));
  process.exit(1);
}
const d = tokenData.data;
const userToken = d.access_token;
const refreshToken = d.refresh_token;
const openId = d.open_id;
console.log("✓ user_access_token, open_id:", openId);

// Step 3: Find primary calendar_id (try correct endpoint)
let calendarId = KNOWN_CALENDAR_ID;
try {
  const calRes = await fetch(
    "https://open.feishu.cn/open-apis/calendar/v4/calendars?page_size=50",
    {
      headers: { Authorization: `Bearer ${userToken}` },
    },
  );
  const calText = await calRes.text();
  const calData = JSON.parse(calText);
  if (calData.code === 0) {
    const primary = (calData.data?.calendar_list ?? []).find((c) => c.type === "primary");
    calendarId =
      primary?.calendar_id ?? calData.data?.calendar_list?.[0]?.calendar_id ?? KNOWN_CALENDAR_ID;
    console.log("✓ calendar_id from API:", calendarId);
  } else {
    console.log("Calendar list returned code", calData.code, "— using known calendar_id");
  }
} catch (e) {
  console.log("Calendar list failed, using known calendar_id:", e.message);
}

// Step 4: Save token file
const tokenFile = {
  access_token: userToken,
  refresh_token: refreshToken,
  expires_in: d.expires_in ?? 6900,
  refresh_expires_in: d.refresh_expires_in ?? 2591700,
  token_type: "Bearer",
  open_id: openId,
  calendar_id: calendarId,
  obtained_at: new Date().toISOString(),
};
await fs.writeFile(TOKEN_FILE, JSON.stringify(tokenFile, null, 2));
console.log("");
console.log("✅ Saved to", TOKEN_FILE);
console.log("   calendar_id:", calendarId);
console.log(
  "   expires_in:",
  tokenFile.expires_in,
  "seconds (~",
  Math.round(tokenFile.expires_in / 60),
  "min)",
);
