import type { CaptureAttachment, CaptureInput } from "../adapters/capture-input.js";

export type CaptureType =
  | "action"
  | "timeline"
  | "watch"
  | "idea"
  | "question"
  | "belief"
  | "memory"
  | "highlight"
  | "reference"
  | "person";

export type CapturePriority = "P0" | "P1" | "P2" | "P3" | null;

export type CaptureSource = "telegram" | "feishu" | "whatsapp" | "wechat" | "email" | "generic";

export type CaptureRemindSchedule = {
  mode: "auto" | "once" | "none";
  checkpoints: string[];
  autoArchiveAfter: string | null;
};

export type CaptureFeedback = {
  token: string;
  watchType: "completion" | "promotion" | "reference" | "watch" | "none";
  expectedHorizonDays: number | null;
};

export type CaptureFileOp = {
  op: "append" | "create" | "overwrite";
  path: string;
  content: string;
};

export type CaptureItem = {
  id: string;
  type: CaptureType;
  title: string;
  priority: CapturePriority;
  due: string | null;
  tags: string[];
  convertToTask: boolean;
  longTermMemory: boolean;
  calendarEntry: boolean;
  stage: "spark" | "sketch" | "proposal" | "active" | "archived" | null;
  qStatus: "open" | "partially_answered" | "resolved" | null;
  confidence: number;
  alts: string[];
  dedupeHint: "new" | "append_existing" | "possible_duplicate";
  nextBestAction: string | null;
  mainPath: string;
  attachments: string[];
  remindSchedule: CaptureRemindSchedule;
  feedback: CaptureFeedback;
  links: string[];
  files: CaptureFileOp[];
};

export type CaptureAck = {
  line1: string;
  line2: string;
  line3?: string;
};

export type CaptureJsonOutput = {
  timezone: "Asia/Shanghai";
  date: string;
  source: CaptureSource;
  ack: CaptureAck;
  items: CaptureItem[];
};

export type CaptureAgentCardOutput = {
  path: string;
  content: string;
};

export type CaptureAgentOutput = CaptureJsonOutput & {
  outputMode: "agent";
  agent: {
    cards: CaptureAgentCardOutput[];
    text: string;
  };
};

export type CaptureRunOutput = CaptureJsonOutput | CaptureAgentOutput;

export type CaptureAgentRunParams = {
  input: CaptureInput;
  applyWrites: boolean;
  outputMode?: string;
};

export type CaptureInference = {
  type: CaptureType;
  priority: CapturePriority;
  due: string | null;
  convertToTask: boolean;
  longTermMemory: boolean;
  confidence: number;
  dedupeHint: "new" | "append_existing" | "possible_duplicate";
  nextBestAction: string | null;
  title: string;
  tags: string[];
  attachments: string[];
  source: CaptureSource;
  rawInput: CaptureInput;
};

export type CaptureDateParts = {
  ymd: string;
  hm: string;
  isoWithOffset: string;
};

export type CaptureBasePaths = {
  root: string;
  inbox: string;
  work: string;
  life: string;
  knowledge: string;
  meta: string;
};

export type CaptureResolvedPaths = CaptureBasePaths & {
  tasks: string;
  projects: string;
  dailyLogs: string;
  ideas: string;
  highlights: string;
  people: string;
  questions: string;
  beliefs: string;
  references: string;
};

export type CapturePathSet = {
  mainPath: string;
  inboxPath: string;
  tasksMasterPath: string;
  waitingPath: string;
  calendarPath: string;
  ideasIndexPath: string;
  questionsIndexPath: string;
  beliefsIndexPath: string;
  reasoningQueuePath: string;
  feedbackSignalsPath: string;
};

export type CaptureCardFrontmatter = {
  id: string;
  type: CaptureType;
  title: string;
  created: string;
  source: CaptureSource;
  priority: CapturePriority;
  due: string | null;
  tags: string[];
  convertToTask: boolean;
  longTermMemory: boolean;
  calendarEntry: boolean;
  stage: "spark" | "sketch" | "proposal" | "active" | "archived" | null;
  qStatus: "open" | "partially_answered" | "resolved" | null;
  confidence: number;
  alts: string[];
  dedupeHint: "new" | "append_existing" | "possible_duplicate";
  nextBestAction: string | null;
  links: string[];
  attachments: string[];
  remindSchedule: CaptureRemindSchedule;
  feedback: CaptureFeedback;
};

export type CaptureContentParts = {
  originalText: string;
  summaryLine: string;
  rationaleLine: string;
  conservativeLine?: string;
  nextActionLine: string;
  keyFacts: string[];
  attachmentLines: string[];
};

export type CaptureBuildItemParams = {
  input: CaptureInput;
  inference: CaptureInference;
  now: CaptureDateParts;
  hubPaths: CaptureResolvedPaths;
};

export type CaptureApplyResult = {
  writes: number;
};

export type CaptureOpsBundle = {
  item: CaptureItem;
  ack: CaptureAck;
};

export function isCaptureAttachmentList(value: CaptureAttachment[]): CaptureAttachment[] {
  return Array.isArray(value) ? value : [];
}
