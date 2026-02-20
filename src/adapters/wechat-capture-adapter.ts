import type { FinalizedMsgContext } from "../auto-reply/templating.js";
import type { CaptureAttachment, CaptureAttachmentType, CaptureInput } from "./capture-input.js";

export type WechatbotWebhookPayload = {
  content?: string;
  type?: string;
  url?: string;
  roomid?: string;
  wxid?: string;
  sender?: string;
  isMentioned?: boolean | number | string;
  timestamp?: string | number;
  reply_to_message_id?: string;
};

function normalizeMediaType(value: string): CaptureAttachmentType {
  const raw = value.toLowerCase();
  if (raw.includes("image") || raw.includes("pic")) {
    return "image";
  }
  if (raw.includes("audio") || raw.includes("voice")) {
    return "audio";
  }
  if (raw.includes("video")) {
    return "video";
  }
  if (raw.includes("text")) {
    return "text";
  }
  return "file";
}

function buildAttachments(ctx: FinalizedMsgContext): CaptureAttachment[] {
  const refs = (ctx.MediaPaths ?? ctx.MediaUrls ?? []).filter(Boolean);
  if (refs.length === 0 && !ctx.MediaPath && !ctx.MediaUrl && !ctx.Transcript) {
    return [];
  }

  const firstType = typeof ctx.MediaType === "string" ? ctx.MediaType : "";
  const types = (ctx.MediaTypes ?? []).map((value) => value.trim()).filter(Boolean);
  const mergedTypes = [firstType.trim(), ...types].filter(Boolean);
  const attachments: CaptureAttachment[] = [];

  if (refs.length === 0 && (ctx.MediaPath || ctx.MediaUrl)) {
    refs.push(ctx.MediaPath ?? ctx.MediaUrl ?? "");
  }

  for (let i = 0; i < refs.length; i += 1) {
    const mediaType = mergedTypes[i] ?? mergedTypes[0] ?? "file";
    const fileRef = refs[i]?.trim();
    if (!fileRef) {
      continue;
    }
    attachments.push({
      type: normalizeMediaType(mediaType),
      fileRef,
    });
  }

  if (typeof ctx.Transcript === "string" && ctx.Transcript.trim()) {
    attachments.push({
      type: "audio",
      fileRef: ctx.MediaPath ?? ctx.MediaUrl ?? "inline-transcript",
      transcript: ctx.Transcript.trim(),
    });
  }

  return attachments;
}

function resolveIsoTimestamp(ctx: FinalizedMsgContext): string {
  if (typeof ctx.Timestamp === "number" && Number.isFinite(ctx.Timestamp)) {
    return new Date(ctx.Timestamp).toISOString();
  }
  return new Date().toISOString();
}

function parseWechatGroupId(ctx: FinalizedMsgContext): string | undefined {
  if (ctx.ChatType !== "group" && ctx.ChatType !== "channel") {
    return undefined;
  }
  const candidates = [ctx.GroupSubject, ctx.OriginatingTo, ctx.From];
  for (const value of candidates) {
    const trimmed = value?.trim();
    if (!trimmed) {
      continue;
    }
    if (trimmed.startsWith("wechat:group:")) {
      return trimmed.slice("wechat:group:".length);
    }
    return trimmed;
  }
  return undefined;
}

function resolveWebhookTimestamp(raw?: string | number): string {
  if (typeof raw === "number" && Number.isFinite(raw)) {
    return new Date(raw).toISOString();
  }
  if (typeof raw === "string" && raw.trim()) {
    const parsed = Date.parse(raw);
    if (Number.isFinite(parsed)) {
      return new Date(parsed).toISOString();
    }
  }
  return new Date().toISOString();
}

export function toWechatCaptureInput(ctx: FinalizedMsgContext): CaptureInput {
  const content =
    (ctx.BodyForCommands ?? ctx.RawBody ?? ctx.CommandBody ?? ctx.BodyForAgent ?? ctx.Body ?? "").trim() ||
    "(empty)";

  const messageId =
    (ctx.MessageSidFull ?? ctx.MessageSid ?? ctx.MessageSidFirst ?? ctx.MessageSidLast ?? "").trim() ||
    String(Date.now());

  return {
    content,
    attachments: buildAttachments(ctx),
    metadata: {
      platform: "wechat",
      messageId,
      groupId: parseWechatGroupId(ctx),
      replyTo: ctx.ReplyToId ?? ctx.ReplyToIdFull,
      senderId: ctx.SenderId ?? ctx.SenderE164,
      timestamp: resolveIsoTimestamp(ctx),
    },
  };
}

export function toWechatCaptureInputFromWebhook(payload: WechatbotWebhookPayload): CaptureInput {
  const content = String(payload.content ?? "").trim() || "(empty)";
  const type = String(payload.type ?? "").trim().toLowerCase();
  const fileRef = String(payload.url ?? "").trim();
  const attachments: CaptureAttachment[] = fileRef
    ? [
        {
          type: normalizeMediaType(type || "file"),
          fileRef,
        },
      ]
    : [];

  return {
    content,
    attachments,
    metadata: {
      platform: "wechat",
      messageId: String(payload.wxid ?? "").trim() || String(Date.now()),
      groupId: String(payload.roomid ?? "").trim() || undefined,
      replyTo: String(payload.reply_to_message_id ?? "").trim() || undefined,
      senderId: String(payload.sender ?? "").trim() || undefined,
      timestamp: resolveWebhookTimestamp(payload.timestamp),
    },
  };
}
