import { runCaptureAgent } from "../capture-agent/run.js";
import type { CaptureRunOutput } from "../capture-agent/types.js";
import type { CaptureInput } from "./capture-input.js";
import {
  toWechatCaptureInputFromWebhook,
  type WechatbotWebhookPayload,
} from "./wechat-capture-adapter.js";

export type WechatCaptureWebhookProcessOptions = {
  selfWxid?: string;
  requireMentionInGroup?: boolean;
  applyWrites?: boolean;
  outputMode?: string;
};

export type SendWechatbotAckParams = {
  baseUrl: string;
  to: string;
  content: string;
  path?: string;
  token?: string;
  timeoutMs?: number;
};

export type SendWechatbotAckResult = {
  ok: boolean;
  status: number | null;
  url: string;
  error?: string;
};

export type WechatCaptureWebhookProcessResult =
  | {
      handled: false;
      reason: "missing_message_id" | "group_not_mentioned" | "dm_not_self_sender";
    }
  | {
      handled: true;
      captureInput: CaptureInput;
      output: CaptureRunOutput;
      ackText: string;
      ackTarget: string | null;
    };

function normalizeId(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function isTruthyMention(value: unknown): boolean {
  if (value === true || value === 1) {
    return true;
  }
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    return normalized === "1" || normalized === "true" || normalized === "yes" || normalized === "on";
  }
  return false;
}

function resolveAckTarget(payload: WechatbotWebhookPayload): string | null {
  const roomId = normalizeId(payload.roomid);
  if (roomId) {
    return roomId;
  }
  const wxid = normalizeId(payload.wxid);
  return wxid || null;
}

function shouldHandleWechatPayload(
  payload: WechatbotWebhookPayload,
  options: WechatCaptureWebhookProcessOptions,
): WechatCaptureWebhookProcessResult | null {
  const messageId = normalizeId(payload.wxid);
  if (!messageId) {
    return { handled: false, reason: "missing_message_id" };
  }

  const roomId = normalizeId(payload.roomid);
  const sender = normalizeId(payload.sender);
  const selfWxid = normalizeId(options.selfWxid);
  const isGroup = Boolean(roomId);
  const requireMentionInGroup = options.requireMentionInGroup ?? true;
  const mentioned = isTruthyMention(payload.isMentioned);

  if (isGroup) {
    if (selfWxid && sender && sender !== selfWxid && requireMentionInGroup && !mentioned) {
      return { handled: false, reason: "group_not_mentioned" };
    }
    if (!selfWxid && requireMentionInGroup && !mentioned) {
      return { handled: false, reason: "group_not_mentioned" };
    }
  } else if (selfWxid && sender && sender !== selfWxid) {
    return { handled: false, reason: "dm_not_self_sender" };
  }

  return null;
}

export function normalizeWechatWebhookPayload(raw: unknown): WechatbotWebhookPayload | null {
  if (!raw || typeof raw !== "object") {
    return null;
  }
  const root = raw as Record<string, unknown>;
  const nested = root["data"];
  const source =
    nested && typeof nested === "object" ? (nested as Record<string, unknown>) : (root as Record<string, unknown>);

  return {
    content: typeof source["content"] === "string" ? source["content"] : undefined,
    type: typeof source["type"] === "string" ? source["type"] : undefined,
    url: typeof source["url"] === "string" ? source["url"] : undefined,
    roomid: typeof source["roomid"] === "string" ? source["roomid"] : undefined,
    wxid: typeof source["wxid"] === "string" ? source["wxid"] : undefined,
    sender: typeof source["sender"] === "string" ? source["sender"] : undefined,
    isMentioned: source["isMentioned"] as boolean | number | string | undefined,
    timestamp: source["timestamp"] as string | number | undefined,
    reply_to_message_id:
      typeof source["reply_to_message_id"] === "string" ? source["reply_to_message_id"] : undefined,
  };
}

export async function sendWechatbotAck(params: SendWechatbotAckParams): Promise<SendWechatbotAckResult> {
  const baseUrl = params.baseUrl.trim();
  const to = params.to.trim();
  const content = params.content.trim();
  const routePath = (params.path?.trim() || "/webhook/msg/v2").replace(/^\/*/, "/");

  if (!baseUrl || !to || !content) {
    return {
      ok: false,
      status: null,
      url: "",
      error: "missing_base_url_or_target_or_content",
    };
  }

  const url = new URL(routePath, baseUrl).toString();
  const headers: Record<string, string> = {
    "content-type": "application/json",
  };
  if (params.token?.trim()) {
    headers["x-wechatbot-token"] = params.token.trim();
  }

  try {
    const response = await fetch(url, {
      method: "POST",
      headers,
      body: JSON.stringify({
        to,
        type: "text",
        content,
      }),
      signal: AbortSignal.timeout(params.timeoutMs ?? 8000),
    });
    if (!response.ok) {
      const text = (await response.text()).slice(0, 500);
      return {
        ok: false,
        status: response.status,
        url,
        error: text || `http_${response.status}`,
      };
    }

    return {
      ok: true,
      status: response.status,
      url,
    };
  } catch (err) {
    return {
      ok: false,
      status: null,
      url,
      error: String(err),
    };
  }
}

export async function processWechatCaptureWebhook(params: {
  payload: WechatbotWebhookPayload;
  options?: WechatCaptureWebhookProcessOptions;
}): Promise<WechatCaptureWebhookProcessResult> {
  const options = params.options ?? {};
  const preflight = shouldHandleWechatPayload(params.payload, options);
  if (preflight) {
    return preflight;
  }

  const captureInput = toWechatCaptureInputFromWebhook(params.payload);
  const output = await runCaptureAgent({
    input: captureInput,
    applyWrites: options.applyWrites ?? true,
    outputMode: options.outputMode ?? process.env.OUTPUT_MODE ?? "json",
  });

  return {
    handled: true,
    captureInput,
    output,
    ackTarget: resolveAckTarget(params.payload),
    ackText: [output.ack.line1, output.ack.line2, output.ack.line3].filter(Boolean).join("\n"),
  };
}
