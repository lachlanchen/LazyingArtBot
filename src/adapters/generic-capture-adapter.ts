import type { FinalizedMsgContext } from "../auto-reply/templating.js";
import type { CaptureAttachment, CaptureAttachmentType, CaptureInput } from "./capture-input.js";

function normalizeMediaType(value: string): CaptureAttachmentType {
  const raw = value.toLowerCase();
  if (raw.includes("image")) {
    return "image";
  }
  if (raw.includes("audio")) {
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

function resolvePlatform(ctx: FinalizedMsgContext): string {
  const surface = String(ctx.Surface ?? "").trim().toLowerCase();
  if (surface) {
    return surface;
  }
  const provider = String(ctx.Provider ?? "").trim().toLowerCase();
  if (provider) {
    return provider;
  }
  return "generic";
}

function resolveGroupId(ctx: FinalizedMsgContext): string | undefined {
  if (ctx.ChatType !== "group" && ctx.ChatType !== "channel") {
    return undefined;
  }
  const candidates = [ctx.GroupSubject, ctx.OriginatingTo, ctx.From];
  for (const value of candidates) {
    const trimmed = value?.trim();
    if (trimmed) {
      return trimmed;
    }
  }
  return undefined;
}

export function toGenericCaptureInput(ctx: FinalizedMsgContext): CaptureInput {
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
      platform: resolvePlatform(ctx),
      messageId,
      groupId: resolveGroupId(ctx),
      replyTo: ctx.ReplyToId ?? ctx.ReplyToIdFull,
      senderId: ctx.SenderId ?? ctx.SenderE164,
      timestamp: resolveIsoTimestamp(ctx),
    },
  };
}

