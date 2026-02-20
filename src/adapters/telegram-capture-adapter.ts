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
  const understanding = new Map<number, string>();
  for (const item of ctx.MediaUnderstanding ?? []) {
    const index = Number(item.attachmentIndex);
    const text = typeof item.text === "string" ? item.text.trim() : "";
    if (!Number.isFinite(index) || !text) {
      continue;
    }
    if (!understanding.has(index)) {
      understanding.set(index, text);
    }
  }

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
    const semanticDesc = understanding.get(i);
    attachments.push({
      type: normalizeMediaType(mediaType),
      fileRef,
      semanticDesc,
    });
  }

  if (typeof ctx.Transcript === "string" && ctx.Transcript.trim()) {
    const transcript = ctx.Transcript.trim();
    const audioAttachment = attachments.find((item) => item.type === "audio");
    if (audioAttachment) {
      audioAttachment.transcript = transcript;
      if (!audioAttachment.semanticDesc) {
        audioAttachment.semanticDesc = `語音逐字稿：${transcript}`;
      }
    } else {
      attachments.push({
        type: "audio",
        fileRef: ctx.MediaPath ?? ctx.MediaUrl ?? "inline-transcript",
        transcript,
        semanticDesc: `語音逐字稿：${transcript}`,
      });
    }
  }

  return attachments;
}

function resolveIsoTimestamp(ctx: FinalizedMsgContext): string {
  if (typeof ctx.Timestamp === "number" && Number.isFinite(ctx.Timestamp)) {
    return new Date(ctx.Timestamp).toISOString();
  }
  return new Date().toISOString();
}

export function toTelegramCaptureInput(ctx: FinalizedMsgContext): CaptureInput {
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
      platform: "telegram",
      messageId,
      groupId: ctx.ChatType === "group" ? (ctx.From ?? ctx.OriginatingTo) : undefined,
      replyTo: ctx.ReplyToId,
      senderId: ctx.SenderId,
      timestamp: resolveIsoTimestamp(ctx),
    },
  };
}
