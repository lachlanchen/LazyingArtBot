import type { IncomingMessage, ServerResponse } from "node:http";
import fs from "node:fs";
import http from "node:http";
import https from "node:https";
import os from "node:os";
import path from "node:path";

const STATE_DIR =
  process.env.OPENCLAW_STATE_DIR ??
  process.env.KAIRO_HOME ??
  process.env.CLAWDBOT_STATE_DIR ??
  path.join(os.homedir(), ".openclaw");

const CONFIG_PATH = path.join(STATE_DIR, "openclaw.json");

function sendJson(res: ServerResponse, status: number, body: unknown, req?: IncomingMessage) {
  res.statusCode = status;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  // Allow github.io origins for wizard hosted on GitHub Pages
  const origin = req?.headers?.origin;
  if (origin && (origin.endsWith(".github.io") || origin === "null")) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Vary", "Origin");
  } else {
    res.setHeader("Access-Control-Allow-Origin", "*");
  }
  res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Setup-Pin");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.end(JSON.stringify(body));
}

function sendError(res: ServerResponse, status: number, message: string) {
  sendJson(res, status, { ok: false, error: message });
}

// Read request body as JSON
async function readJsonBody(req: IncomingMessage): Promise<unknown> {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk: Buffer) => {
      body += chunk.toString();
    });
    req.on("end", () => {
      try {
        resolve(JSON.parse(body));
      } catch {
        reject(new Error("Invalid JSON body"));
      }
    });
    req.on("error", reject);
  });
}

// Read existing config
function readConfig(): Record<string, unknown> {
  try {
    if (fs.existsSync(CONFIG_PATH)) {
      return JSON.parse(fs.readFileSync(CONFIG_PATH, "utf-8")) as Record<string, unknown>;
    }
  } catch {
    /* ignore */
  }
  return {};
}

// Verify setup PIN
function verifySetupPin(req: IncomingMessage): boolean {
  const pinFile = path.join(STATE_DIR, "setup.pin");
  const expiryFile = path.join(STATE_DIR, "setup.pin.expiry");

  try {
    if (!fs.existsSync(pinFile)) {
      return false;
    }

    // Check expiry
    if (fs.existsSync(expiryFile)) {
      const expiry = parseInt(fs.readFileSync(expiryFile, "utf-8").trim(), 10);
      if (Date.now() / 1000 > expiry) {
        return false;
      }
    }

    const storedPin = fs.readFileSync(pinFile, "utf-8").trim().toUpperCase();
    const providedPin = ((req.headers["x-setup-pin"] as string | undefined) ?? "")
      .trim()
      .toUpperCase();

    return storedPin.length > 0 && storedPin === providedPin;
  } catch {
    return false;
  }
}

// Invalidate PIN after successful setup
function invalidateSetupPin(): void {
  try {
    fs.unlinkSync(path.join(STATE_DIR, "setup.pin"));
    const expiryFile = path.join(STATE_DIR, "setup.pin.expiry");
    if (fs.existsSync(expiryFile)) {
      fs.unlinkSync(expiryFile);
    }
  } catch {
    /* ignore */
  }
}

// Atomic write config
function writeConfig(cfg: Record<string, unknown>): void {
  const tmp = CONFIG_PATH + ".tmp." + Date.now();
  fs.mkdirSync(path.dirname(CONFIG_PATH), { recursive: true });
  fs.writeFileSync(tmp, JSON.stringify(cfg, null, 2), "utf-8");
  // Backup old
  if (fs.existsSync(CONFIG_PATH)) {
    fs.copyFileSync(CONFIG_PATH, CONFIG_PATH + ".bak.setup");
  }
  fs.renameSync(tmp, CONFIG_PATH);
}

// Deep merge b into a
function deepMerge(
  a: Record<string, unknown>,
  b: Record<string, unknown>,
): Record<string, unknown> {
  const result: Record<string, unknown> = { ...a };
  for (const [k, v] of Object.entries(b)) {
    if (
      v !== null &&
      typeof v === "object" &&
      !Array.isArray(v) &&
      typeof result[k] === "object" &&
      result[k] !== null &&
      !Array.isArray(result[k])
    ) {
      result[k] = deepMerge(result[k] as Record<string, unknown>, v as Record<string, unknown>);
    } else {
      result[k] = v;
    }
  }
  return result;
}

// Check Feishu token status
function getFeishuTokenStatus(): "ok" | "expired" | "expiring" | "unconfigured" {
  try {
    const tokenPath = path.join(STATE_DIR, "feishu_user_token.json");
    if (!fs.existsSync(tokenPath)) {
      return "unconfigured";
    }
    const tok = JSON.parse(fs.readFileSync(tokenPath, "utf-8")) as {
      access_token?: string;
      expires_in?: number | string;
      obtained_at?: number | string;
    };
    if (!tok.access_token) {
      return "unconfigured";
    }
    const obtainedAt = tok.obtained_at
      ? typeof tok.obtained_at === "number"
        ? tok.obtained_at
        : new Date(String(tok.obtained_at)).getTime()
      : 0;
    const expiresIn = Number(tok.expires_in ?? 7200);
    const remainingMs = obtainedAt + expiresIn * 1000 - Date.now();
    if (remainingMs <= 0) {
      return "expired";
    }
    if (remainingMs < 30 * 60_000) {
      return "expiring";
    }
    return "ok";
  } catch {
    return "unconfigured";
  }
}

// Simple HTTP/HTTPS GET with timeout
function httpGet(
  url: string,
  headers: Record<string, string>,
  timeoutMs: number,
): Promise<{ status: number; body: string }> {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const isHttps = parsed.protocol === "https:";
    const opts = {
      hostname: parsed.hostname,
      port: parsed.port || (isHttps ? 443 : 80),
      path: parsed.pathname + parsed.search,
      method: "GET",
      headers,
    };
    const req = (isHttps ? https : http).request(opts, (res) => {
      let body = "";
      res.on("data", (c: Buffer) => {
        body += c.toString();
      });
      res.on("end", () => resolve({ status: res.statusCode ?? 0, body }));
    });
    req.on("error", reject);
    req.setTimeout(timeoutMs, () => {
      req.destroy(new Error("Timeout"));
    });
    req.end();
  });
}

// Simple HTTP/HTTPS POST with timeout
function httpPost(
  url: string,
  headers: Record<string, string>,
  body: string,
  timeoutMs: number,
): Promise<{ status: number; body: string }> {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const isHttps = parsed.protocol === "https:";
    const opts = {
      hostname: parsed.hostname,
      port: parsed.port || (isHttps ? 443 : 80),
      path: parsed.pathname + parsed.search,
      method: "POST",
      headers: { ...headers, "Content-Length": Buffer.byteLength(body) },
    };
    const req = (isHttps ? https : http).request(opts, (res) => {
      let respBody = "";
      res.on("data", (c: Buffer) => {
        respBody += c.toString();
      });
      res.on("end", () => resolve({ status: res.statusCode ?? 0, body: respBody }));
    });
    req.on("error", reject);
    req.setTimeout(timeoutMs, () => {
      req.destroy(new Error("Timeout"));
    });
    req.write(body);
    req.end();
  });
}

// GET /api/setup/status
async function handleSetupStatus(res: ServerResponse): Promise<void> {
  const cfg = readConfig();
  const configExists = fs.existsSync(CONFIG_PATH);

  // Extract configured services (never expose keys)
  const channels = (cfg.channels ?? {}) as Record<string, unknown>;
  const tgChannel = channels.telegram as Record<string, unknown> | undefined;
  const feishuChannel = channels.feishu as Record<string, unknown> | undefined;

  const modelsProviders = ((cfg.models ?? {}) as Record<string, unknown>).providers as
    | Record<string, unknown>
    | undefined;
  const agentsDefaults = ((cfg.agents ?? {}) as Record<string, unknown>).defaults as
    | Record<string, unknown>
    | undefined;
  const primaryModel = (agentsDefaults?.model as Record<string, unknown>)?.primary as
    | string
    | undefined;

  let llmProvider: string | null = null;
  let llmModel: string | null = null;
  if (primaryModel) {
    const slash = primaryModel.indexOf("/");
    llmProvider = slash > 0 ? primaryModel.slice(0, slash) : primaryModel;
    llmModel = slash > 0 ? primaryModel.slice(slash + 1) : primaryModel;
  }

  // Telegram configured?
  let telegramUsername: string | null = null;
  if (tgChannel?.botToken) {
    // Don't expose token, just note it's configured
    telegramUsername = (tgChannel.botUsername as string) ?? "configured";
  }

  // LLM health: quick HEAD to provider URL
  let llmHealth: "ok" | "error" | "unconfigured" = "unconfigured";
  if (llmProvider && modelsProviders?.[llmProvider]) {
    const provCfg = modelsProviders[llmProvider] as Record<string, unknown>;
    const baseUrl = (provCfg.baseUrl as string) ?? "";
    if (baseUrl) {
      try {
        const apiKey = (provCfg.apiKey as string) ?? "";
        const r = await httpGet(baseUrl + "/models", { Authorization: `Bearer ${apiKey}` }, 5000);
        llmHealth = r.status < 500 ? "ok" : "error";
      } catch {
        llmHealth = "error";
      }
    } else {
      llmHealth = "ok"; // assume ok if provider configured but no baseUrl (local)
    }
  }

  // Feishu health
  const feishuStatus = getFeishuTokenStatus();
  const feishuHealth =
    feishuStatus === "ok"
      ? "ok"
      : feishuStatus === "expiring"
        ? "expiring"
        : feishuStatus === "expired"
          ? "expired"
          : "unconfigured";

  // Telegram health: just check if configured for now
  const telegramHealth: "ok" | "error" | "unconfigured" = telegramUsername ? "ok" : "unconfigured";

  // needsSetup: no telegram channel AND no LLM configured
  const needsSetup = !telegramUsername && !llmProvider && !configExists;

  sendJson(res, 200, {
    ok: true,
    needsSetup,
    configExists,
    configured: {
      llm: llmProvider ? { provider: llmProvider, model: llmModel } : null,
      telegram: telegramUsername ? { botUsername: telegramUsername } : null,
      feishu: feishuChannel?.appId ? { appId: feishuChannel.appId as string } : null,
      tts: (cfg.messages as Record<string, unknown>)?.tts
        ? {
            provider: ((cfg.messages as Record<string, unknown>).tts as Record<string, unknown>)
              .provider,
          }
        : null,
    },
    health: {
      llm: llmHealth,
      telegram: telegramHealth,
      feishu: feishuHealth,
    },
  });
}

// POST /api/setup/validate
async function handleSetupValidate(req: IncomingMessage, res: ServerResponse): Promise<void> {
  let body: Record<string, unknown>;
  try {
    body = (await readJsonBody(req)) as Record<string, unknown>;
  } catch {
    sendError(res, 400, "Invalid JSON body");
    return;
  }

  const type = body.type as string;

  // PIN validation — doesn't require existing PIN auth
  if (type === "setup-pin") {
    const value = String(body.value ?? "")
      .trim()
      .toUpperCase();
    if (!value || value.length !== 6) {
      sendJson(res, 200, { ok: false, error: "PIN 應為 6 位字母數字" }, req);
      return;
    }
    const pinFile = path.join(STATE_DIR, "setup.pin");
    const expiryFile = path.join(STATE_DIR, "setup.pin.expiry");
    try {
      if (!fs.existsSync(pinFile)) {
        sendJson(
          res,
          200,
          {
            ok: false,
            error:
              "PIN 不存在。請在服務器執行：\nnewpin=$(LC_ALL=C tr -dc A-Z0-9 </dev/urandom | head -c6); echo $newpin > ~/.openclaw/setup.pin; echo $(($(date +%s)+3600)) > ~/.openclaw/setup.pin.expiry; echo PIN: $newpin",
            pinMissing: true,
          },
          req,
        );
        return;
      }
      if (fs.existsSync(expiryFile)) {
        const expiry = parseInt(fs.readFileSync(expiryFile, "utf-8").trim(), 10);
        if (Date.now() / 1000 > expiry) {
          sendJson(res, 200, { ok: false, error: "PIN 已過期（24小時）" }, req);
          return;
        }
      }
      const stored = fs.readFileSync(pinFile, "utf-8").trim().toUpperCase();
      if (stored === value) {
        sendJson(res, 200, { ok: true, details: { message: "PIN 驗證成功" } }, req);
      } else {
        sendJson(res, 200, { ok: false, error: "PIN 錯誤" }, req);
      }
    } catch (err) {
      sendJson(res, 200, { ok: false, error: String(err) }, req);
    }
    return;
  }

  if (type === "telegram-user-id") {
    const value = String(body.value ?? "").trim();
    if (/^\d{5,15}$/.test(value)) {
      sendJson(res, 200, { ok: true, details: { userId: value } });
    } else {
      sendJson(res, 200, { ok: false, error: "User ID should be a numeric string (5-15 digits)" });
    }
    return;
  }

  if (type === "telegram-token") {
    const value = String(body.value ?? "").trim();
    if (!value || !/^\d+:[A-Za-z0-9_-]{30,}$/.test(value)) {
      sendJson(res, 200, { ok: false, error: "Invalid token format. Expected: 123456:ABCdef..." });
      return;
    }
    try {
      const r = await httpGet(`https://api.telegram.org/bot${value}/getMe`, {}, 10000);
      if (r.status === 200) {
        const data = JSON.parse(r.body) as {
          ok: boolean;
          result?: { username?: string; first_name?: string };
        };
        if (data.ok && data.result) {
          sendJson(res, 200, {
            ok: true,
            details: { botUsername: data.result.username ?? data.result.first_name ?? "Bot" },
          });
        } else {
          sendJson(res, 200, { ok: false, error: "Telegram rejected this token" });
        }
      } else if (r.status === 401) {
        sendJson(res, 200, { ok: false, error: "Invalid token: 401 Unauthorized" });
      } else {
        sendJson(res, 200, { ok: false, error: `Telegram returned HTTP ${r.status}` });
      }
    } catch (err) {
      sendJson(res, 200, { ok: false, error: `Connection failed: ${String(err)}` });
    }
    return;
  }

  if (type === "llm-api-key") {
    const provider = body.provider as string;
    const value = String(body.value ?? "").trim();
    if (!value) {
      sendJson(res, 200, { ok: false, error: "API key cannot be empty" });
      return;
    }

    const PROVIDER_URLS: Record<string, string> = {
      openai: "https://api.openai.com/v1/models",
      dashscope: "https://dashscope.aliyuncs.com/compatible-mode/v1/models",
      anthropic: "https://api.anthropic.com/v1/models",
    };
    const PROVIDER_HEADERS: Record<string, (k: string) => Record<string, string>> = {
      openai: (k) => ({ Authorization: `Bearer ${k}` }),
      dashscope: (k) => ({ Authorization: `Bearer ${k}` }),
      anthropic: (k) => ({ "x-api-key": k, "anthropic-version": "2023-06-01" }),
    };

    const url = PROVIDER_URLS[provider];
    const headersFn = PROVIDER_HEADERS[provider];
    if (!url || !headersFn) {
      sendJson(res, 200, { ok: false, error: `Unknown provider: ${provider}` });
      return;
    }

    try {
      const r = await httpGet(url, headersFn(value), 10000);
      if (r.status === 200 || r.status === 201) {
        const models = JSON.parse(r.body) as { data?: Array<{ id: string }> };
        const modelList = models.data?.slice(0, 3).map((m) => m.id) ?? [];
        sendJson(res, 200, { ok: true, details: { models: modelList } });
      } else if (r.status === 401 || r.status === 403) {
        sendJson(res, 200, { ok: false, error: `Invalid API key: HTTP ${r.status}` });
      } else {
        sendJson(res, 200, { ok: false, error: `Provider returned HTTP ${r.status}` });
      }
    } catch (err) {
      sendJson(res, 200, { ok: false, error: `Connection failed: ${String(err)}` });
    }
    return;
  }

  if (type === "feishu-credentials") {
    const appId = String(body.appId ?? "").trim();
    const appSecret = String(body.appSecret ?? "").trim();
    if (!appId || !appSecret) {
      sendJson(res, 200, { ok: false, error: "App ID 和 App Secret 不能為空" }, req);
      return;
    }
    if (!appId.startsWith("cli_")) {
      sendJson(res, 200, { ok: false, error: "App ID 格式錯誤（應以 cli_ 開頭）" }, req);
      return;
    }
    try {
      const r = await httpPost(
        "https://open.feishu.cn/open-apis/auth/v3/app_access_token/internal",
        { "Content-Type": "application/json; charset=utf-8" },
        JSON.stringify({ app_id: appId, app_secret: appSecret }),
        10000,
      );
      if (r.status === 200) {
        const data = JSON.parse(r.body) as { code: number; msg?: string; app_name?: string };
        if (data.code === 0) {
          sendJson(
            res,
            200,
            { ok: true, details: { appName: data.app_name ?? "Feishu App" } },
            req,
          );
        } else {
          sendJson(
            res,
            200,
            { ok: false, error: data.msg ?? `Feishu error code: ${data.code}` },
            req,
          );
        }
      } else {
        sendJson(res, 200, { ok: false, error: `HTTP ${r.status}` }, req);
      }
    } catch (err) {
      sendJson(res, 200, { ok: false, error: `連接失敗: ${String(err)}` }, req);
    }
    return;
  }

  sendJson(res, 200, { ok: false, error: `Unknown validation type: ${type}` });
}

// POST /api/setup/apply
async function handleSetupApply(req: IncomingMessage, res: ServerResponse): Promise<void> {
  // Verify setup PIN
  if (!verifySetupPin(req)) {
    sendJson(res, 403, { ok: false, error: "Invalid or expired setup PIN" }, req);
    return;
  }
  let body: Record<string, unknown>;
  try {
    body = (await readJsonBody(req)) as Record<string, unknown>;
  } catch {
    sendError(res, 400, "Invalid JSON body");
    return;
  }

  const existing = readConfig();
  const patch: Record<string, unknown> = {};

  // LLM setup
  const llm = body.llm as Record<string, unknown> | undefined;
  if (llm?.provider && llm.apiKey) {
    const provider = String(llm.provider);
    const apiKey = String(llm.apiKey);
    const model = String(llm.model ?? "");

    const PROVIDER_DEFAULTS: Record<string, { baseUrl: string; defaultModel: string }> = {
      openai: { baseUrl: "https://api.openai.com/v1", defaultModel: "gpt-4o" },
      dashscope: {
        baseUrl: "https://dashscope.aliyuncs.com/compatible-mode/v1",
        defaultModel: "qwen-plus",
      },
      anthropic: { baseUrl: "https://api.anthropic.com", defaultModel: "claude-sonnet-4-6" },
    };
    const defaults = PROVIDER_DEFAULTS[provider] ?? {
      baseUrl: String(llm.baseUrl ?? ""),
      defaultModel: model,
    };
    const chosenModel = model || defaults.defaultModel;

    patch.models = deepMerge((existing.models ?? {}) as Record<string, unknown>, {
      providers: {
        [provider]: {
          baseUrl: (llm.baseUrl as string) || defaults.baseUrl,
          apiKey,
          models: [chosenModel],
        },
      },
    });
    patch.agents = deepMerge((existing.agents ?? {}) as Record<string, unknown>, {
      defaults: {
        model: {
          primary: `${provider}/${chosenModel}`,
        },
      },
    });
  }

  // Telegram setup
  const telegram = body.telegram as Record<string, unknown> | undefined;
  if (telegram?.botToken) {
    const botToken = String(telegram.botToken);
    const userId = String(telegram.userId ?? "");
    const channelPatch: Record<string, unknown> = {
      botToken,
      dmPolicy: "open",
    };
    if (userId) {
      channelPatch.allowFrom = [userId];
    }
    patch.channels = deepMerge((existing.channels ?? {}) as Record<string, unknown>, {
      telegram: channelPatch,
    });

    // Add binding if not present
    const existingBindings = (existing.bindings ?? []) as unknown[];
    const hasTgBinding = existingBindings.some(
      (b) =>
        typeof b === "object" &&
        b !== null &&
        (b as Record<string, unknown>).channel === "telegram",
    );
    if (!hasTgBinding) {
      patch.bindings = [...existingBindings, { match: { channel: "telegram" }, agentId: "main" }];
    }
  }

  // Gateway auth
  const gateway = body.gateway as Record<string, unknown> | undefined;
  if (gateway?.authToken) {
    patch.gateway = deepMerge((existing.gateway ?? {}) as Record<string, unknown>, {
      auth: { mode: "token", token: String(gateway.authToken) },
    });
  }

  // Feishu setup
  const feishu = body.feishu as Record<string, unknown> | undefined;
  if (feishu?.appId && feishu?.appSecret) {
    patch.channels = deepMerge(
      (patch.channels ?? existing.channels ?? {}) as Record<string, unknown>,
      { feishu: { appId: String(feishu.appId), appSecret: String(feishu.appSecret) } },
    );
    // Add feishu to plugins.entries if not present
    const existingPlugins = (existing.plugins ?? {}) as Record<string, unknown>;
    const existingEntries = (existingPlugins.entries ?? {}) as Record<string, unknown>;
    if (!existingEntries.feishu) {
      patch.plugins = deepMerge(existingPlugins, {
        entries: { feishu: { enabled: true } },
      });
    }
  }

  // Write merged config
  const merged = deepMerge(existing, patch);
  try {
    writeConfig(merged);
    invalidateSetupPin();
    sendJson(res, 200, { ok: true, restartRequired: true }, req);
  } catch (err) {
    sendError(res, 500, `Failed to write config: ${String(err)}`);
  }
}

// POST /api/setup/generate-pin — local-only, regenerates PIN
async function handleGeneratePin(res: ServerResponse, req: IncomingMessage): Promise<void> {
  try {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let pin = "";
    // Use crypto for randomness
    const crypto = await import("node:crypto");
    const bytes = crypto.randomBytes(6);
    for (const b of bytes) {
      pin += chars[b % chars.length];
    }
    const pinFile = path.join(STATE_DIR, "setup.pin");
    const expiryFile = path.join(STATE_DIR, "setup.pin.expiry");
    fs.mkdirSync(path.dirname(pinFile), { recursive: true });
    fs.writeFileSync(pinFile, pin + "\n", { mode: 0o600 });
    fs.writeFileSync(expiryFile, String(Math.floor(Date.now() / 1000) + 3600) + "\n");
    sendJson(res, 200, { ok: true, pin, expiresInSeconds: 3600 }, req);
  } catch (err) {
    sendJson(res, 500, { ok: false, error: String(err) }, req);
  }
}

// Main router for setup API
export async function handleSetupRequest(
  req: IncomingMessage,
  res: ServerResponse,
  subPath: string,
): Promise<boolean> {
  // Handle CORS preflight for GitHub Pages requests
  if (req.method === "OPTIONS") {
    res.statusCode = 204;
    const origin = req.headers.origin;
    if (origin && (origin.endsWith(".github.io") || origin === "null")) {
      res.setHeader("Access-Control-Allow-Origin", origin);
      res.setHeader("Vary", "Origin");
    } else {
      res.setHeader("Access-Control-Allow-Origin", "*");
    }
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Setup-Pin");
    res.end();
    return true;
  }

  if (subPath === "status" && req.method === "GET") {
    await handleSetupStatus(res);
    return true;
  }
  if (subPath === "validate" && req.method === "POST") {
    await handleSetupValidate(req, res);
    return true;
  }
  if (subPath === "apply" && req.method === "POST") {
    await handleSetupApply(req, res);
    return true;
  }
  if (subPath === "generate-pin" && req.method === "POST") {
    await handleGeneratePin(res, req);
    return true;
  }
  sendJson(res, 404, { ok: false, error: `Unknown setup endpoint: ${subPath}` });
  return true;
}
