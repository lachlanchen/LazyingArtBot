export type CaptureAttachmentType = "image" | "audio" | "video" | "file" | "text";

export type CaptureAttachment = {
  type: CaptureAttachmentType;
  fileRef: string;
  transcript?: string;
  semanticDesc?: string;
};

export type CaptureInput = {
  content: string;
  attachments: CaptureAttachment[];
  metadata: {
    platform: string;
    messageId: string;
    groupId?: string;
    replyTo?: string;
    senderId?: string;
    timestamp: string;
  };
};

