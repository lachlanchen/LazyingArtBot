#!/usr/bin/env -S node --import tsx
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import {
  normalizeWechatWebhookPayload,
  processWechatCaptureWebhook,
  sendWechatbotAck,
} from "../src/adapters/wechat-capture-webhook.js";

type JsonRecord = Record<string, unknown>;

function envBool(name: string, fallback: boolean): boolean {
  const raw = process.env[name]?.trim().toLowerCase();
  if (!raw) {
    return fallback;
  }
  return raw === "1" || raw === "true" || raw === "yes" || raw === "on";
}

function envInt(name: string, fallback: number): number {
  const raw = process.env[name]?.trim();
  if (!raw) {
    return fallback;
  }
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizePath(raw: string | undefined, fallback: string): string {
  const value = raw?.trim() || fallback;
  const withLeadingSlash = value.startsWith("/") ? value : `/${value}`;
  return withLeadingSlash.replace(/\/+/g, "/");
}

function toHeaderValue(value: string | string[] | undefined): string {
  if (Array.isArray(value)) {
    return value[0]?.trim() || "";
  }
  return typeof value === "string" ? value.trim() : "";
}

function nowIso(): string {
  return new Date().toISOString();
}

function logInfo(message: string) {
  console.log(`[${nowIso()}] [wechat-capture-webhook] ${message}`);
}

function logError(message: string) {
  console.error(`[${nowIso()}] [wechat-capture-webhook] ${message}`);
}

function writeJson(res: ServerResponse, statusCode: number, payload: JsonRecord) {
  res.statusCode = statusCode;
  res.setHeader("content-type", "application/json; charset=utf-8");
  res.end(JSON.stringify(payload));
}

function readBody(req: IncomingMessage): Promise<string> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    req.on("data", (chunk: Buffer) => chunks.push(chunk));
    req.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    req.on("error", reject);
  });
}

const host = process.env.WECHAT_CAPTURE_HOST?.trim() || "0.0.0.0";
const port = envInt("WECHAT_CAPTURE_PORT", 8789);
const webhookPath = normalizePath(process.env.WECHAT_CAPTURE_PATH, "/wechat/webhook");
const healthPath = normalizePath(process.env.WECHAT_CAPTURE_HEALTH_PATH, "/healthz");
const selfWxid = process.env.WECHAT_CAPTURE_SELF_WXID?.trim() || undefined;
const requireMentionInGroup = envBool("WECHAT_CAPTURE_REQUIRE_MENTION_IN_GROUP", true);
const applyWrites = envBool("WECHAT_CAPTURE_APPLY_WRITES", true);
const sendAck = envBool("WECHAT_CAPTURE_SEND_ACK", true);
const outputMode = process.env.OUTPUT_MODE?.trim() || "json";
const webhookToken = process.env.WECHAT_CAPTURE_WEBHOOK_TOKEN?.trim() || "";
const wechatbotBaseUrl =
  process.env.WECHATBOT_HOST?.trim() || process.env.WECHATBOT_BASE_URL?.trim() || "";
const wechatbotReplyPath = normalizePath(process.env.WECHATBOT_REPLY_PATH, "/webhook/msg/v2");
const wechatbotToken = process.env.WECHATBOT_TOKEN?.trim() || "";

async function handleIncomingWebhook(req: IncomingMessage, res: ServerResponse) {
  if (webhookToken) {
    const headerToken = toHeaderValue(req.headers["x-wechat-capture-token"]);
    if (headerToken !== webhookToken) {
      writeJson(res, 401, { ok: false, error: "unauthorized" });
      return;
    }
  }

  const body = await readBody(req);
  let parsedBody: unknown;
  try {
    parsedBody = JSON.parse(body);
  } catch {
    writeJson(res, 400, { ok: false, error: "invalid_json" });
    return;
  }

  const payload = normalizeWechatWebhookPayload(parsedBody);
  if (!payload) {
    writeJson(res, 400, { ok: false, error: "invalid_payload" });
    return;
  }

  const result = await processWechatCaptureWebhook({
    payload,
    options: {
      selfWxid,
      requireMentionInGroup,
      applyWrites,
      outputMode,
    },
  });

  if (!result.handled) {
    logInfo(`skipped reason=${result.reason} messageId=${payload.wxid ?? ""}`);
    writeJson(res, 200, {
      ok: true,
      handled: false,
      reason: result.reason,
    });
    return;
  }

  const ackMeta: JsonRecord = {
    attempted: false,
    sent: false,
    target: result.ackTarget,
  };
  if (sendAck && result.ackTarget && wechatbotBaseUrl) {
    ackMeta.attempted = true;
    const ackResult = await sendWechatbotAck({
      baseUrl: wechatbotBaseUrl,
      path: wechatbotReplyPath,
      to: result.ackTarget,
      content: result.ackText,
      token: wechatbotToken,
    });
    ackMeta.sent = ackResult.ok;
    ackMeta.status = ackResult.status;
    ackMeta.url = ackResult.url;
    if (!ackResult.ok) {
      ackMeta.error = ackResult.error;
      logError(`ack failed target=${result.ackTarget} error=${ackResult.error ?? "unknown"}`);
    }
  }

  logInfo(
    `handled messageId=${payload.wxid ?? ""} type=${payload.type ?? "text"} items=${result.output.items.length}`,
  );

  writeJson(res, 200, {
    ok: true,
    handled: true,
    messageId: payload.wxid ?? null,
    itemCount: result.output.items.length,
    ack: ackMeta,
  });
}

const server = createServer(async (req, res) => {
  const method = (req.method ?? "GET").toUpperCase();
  const reqPath = (req.url ?? "/").split("?")[0] ?? "/";

  if (method === "GET" && reqPath === healthPath) {
    res.statusCode = 200;
    res.setHeader("content-type", "text/plain; charset=utf-8");
    res.end("ok");
    return;
  }

  if (method !== "POST" || reqPath !== webhookPath) {
    writeJson(res, 404, { ok: false, error: "not_found" });
    return;
  }

  try {
    await handleIncomingWebhook(req, res);
  } catch (err) {
    logError(`webhook exception: ${String(err)}`);
    if (!res.headersSent) {
      writeJson(res, 500, { ok: false, error: "internal_error" });
    }
  }
});

server.listen(port, host, () => {
  logInfo(`listening on http://${host}:${port}${webhookPath}`);
  logInfo(`health endpoint: http://${host}:${port}${healthPath}`);
  logInfo(
    `config selfWxid=${selfWxid ?? "(unset)"} requireMention=${String(requireMentionInGroup)} applyWrites=${String(applyWrites)} sendAck=${String(sendAck)}`,
  );
});

const shutdown = () => {
  logInfo("shutting down");
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 3000).unref();
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
