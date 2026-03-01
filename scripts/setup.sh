#!/usr/bin/env bash
# =============================================================================
# Kairo — 交互式安裝向導 (Interactive Setup Wizard)
# =============================================================================
# Usage: bash setup.sh [--dry-run]
#
# 功能：引導技術用戶從 0 到完整運行 Kairo AI 秘書系統
# Target: 30 分鐘內完成基本配置
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# 顏色常量
# ---------------------------------------------------------------------------
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

# ---------------------------------------------------------------------------
# 全域變量
# ---------------------------------------------------------------------------
DRY_RUN=0
KAIRO_HOME=""
CHANNEL_CHOICE=""
MODEL_CHOICE=""

# Telegram
TG_MAIN_TOKEN=""
TG_CHANNEL2_TOKEN=""
TG_USER_ID=""
TG_MAIN_TOKEN_FILE=""
TG_CHANNEL2_TOKEN_FILE=""

# Feishu
FEISHU_APP_ID=""
FEISHU_APP_SECRET=""

# AI 模型
PROXY_URL=""
OPENAI_API_KEY=""
ANTHROPIC_API_KEY=""
MODEL_PROVIDER_ID=""
MODEL_ID=""
MODEL_BASE_URL=""

# systemd
SETUP_SYSTEMD=0

# ---------------------------------------------------------------------------
# 工具函數
# ---------------------------------------------------------------------------
info()    { echo -e "${GREEN}[INFO]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
success() { echo -e "${GREEN}${BOLD}[OK]${RESET} $*"; }
header()  { echo -e "\n${CYAN}${BOLD}=== $* ===${RESET}"; }

confirm_not_empty() {
  local val="$1"
  local label="$2"
  if [[ -z "$val" ]]; then
    error "$label 不能為空"
    return 1
  fi
  return 0
}

# dry-run 模式下打印命令而不執行
run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo -e "${YELLOW}[DRY-RUN]${RESET} $*"
  else
    "$@"
  fi
}

write_file() {
  local path="$1"
  local content="$2"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo -e "${YELLOW}[DRY-RUN]${RESET} Would write to: $path"
    echo "--- content preview (first 10 lines) ---"
    echo "$content" | head -10
    echo "---"
  else
    printf '%s\n' "$content" > "$path"
  fi
}

# ---------------------------------------------------------------------------
# 解析命令行參數
# ---------------------------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      echo "Usage: $0 [--dry-run]"
      echo "  --dry-run   打印操作但不實際執行"
      exit 0
      ;;
  esac
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo -e "${YELLOW}[DRY-RUN 模式] 不會實際修改任何文件${RESET}"
fi

# ---------------------------------------------------------------------------
# 歡迎畫面
# ---------------------------------------------------------------------------
clear
echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Kairo AI 秘書系統 — 安裝向導 v1.0                  ║"
echo "║  自托管 · 零訂閱費 · Telegram / Feishu 多渠道               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo "本向導將幫助您在 30 分鐘內完成 Kairo 的基本配置。"
echo "按 Ctrl+C 隨時退出（已輸入的信息不會被保存）。"
echo ""

# =============================================================================
# Phase 1: 環境檢查
# =============================================================================
header "Phase 1: 環境檢查"

PHASE1_OK=1

# --- Node.js ---
if command -v node >/dev/null 2>&1; then
  NODE_VERSION="$(node --version)"
  NODE_MAJOR="$(echo "$NODE_VERSION" | sed 's/v\([0-9]*\).*/\1/')"
  if [[ "$NODE_MAJOR" -ge 20 ]]; then
    success "Node.js $NODE_VERSION (>= v20 ✓)"
  else
    error "Node.js $NODE_VERSION 版本過低，需要 >= v20"
    echo "  安裝指引: https://nodejs.org/ 或使用 nvm"
    PHASE1_OK=0
  fi
else
  error "未找到 Node.js"
  echo "  安裝指引: https://nodejs.org/ 或使用 nvm"
  PHASE1_OK=0
fi

# --- npm / pnpm ---
if command -v pnpm >/dev/null 2>&1; then
  success "pnpm $(pnpm --version) ✓"
  PKG_MANAGER="pnpm"
elif command -v npm >/dev/null 2>&1; then
  success "npm $(npm --version) ✓"
  PKG_MANAGER="npm"
else
  error "未找到 npm 或 pnpm"
  PHASE1_OK=0
fi

# --- sox（可選，TTS 音頻轉換）---
if command -v sox >/dev/null 2>&1; then
  success "sox $(sox --version 2>&1 | head -1 | awk '{print $3}') ✓ (TTS 音頻轉換)"
else
  warn "未找到 sox — TTS 語音功能將不可用"
  echo "  安裝方法:"
  echo "    Ubuntu/Debian: sudo apt install sox"
  echo "    CentOS/RHEL:   sudo yum install sox"
  echo "    macOS:         brew install sox"
fi

# --- git ---
if command -v git >/dev/null 2>&1; then
  success "git $(git --version | awk '{print $3}') ✓"
else
  warn "未找到 git（非必需，但推薦安裝）"
fi

if [[ "$PHASE1_OK" -eq 0 ]]; then
  error "環境檢查未通過，請安裝缺失的依賴後重試"
  exit 1
fi

echo ""
success "環境檢查通過！"

# =============================================================================
# Phase 2: KAIRO_HOME 設定
# =============================================================================
header "Phase 2: 資料目錄設定"

DEFAULT_KAIRO_HOME="${HOME}/.openclaw"
echo "Kairo 的配置、工作區及日誌將存放於此目錄。"
echo "預設位置: ${DEFAULT_KAIRO_HOME}"
echo ""
read -r -p "自定義路徑 (或按 Enter 使用預設): " CUSTOM_KAIRO_HOME

if [[ -z "$CUSTOM_KAIRO_HOME" ]]; then
  KAIRO_HOME="$DEFAULT_KAIRO_HOME"
else
  # 展開 ~ 符號
  KAIRO_HOME="${CUSTOM_KAIRO_HOME/#\~/$HOME}"
fi

info "資料目錄: $KAIRO_HOME"

# 創建必要的子目錄
DIRS_TO_CREATE=(
  "$KAIRO_HOME"
  "$KAIRO_HOME/agents/main/agent"
  "$KAIRO_HOME/agents/executor/agent"
  "$KAIRO_HOME/agents/reviewer/agent"
  "$KAIRO_HOME/workspace"
  "$KAIRO_HOME/workspace-executor"
  "$KAIRO_HOME/workspace-reviewer"
  "$KAIRO_HOME/cron"
  "$KAIRO_HOME/memory"
)

for dir in "${DIRS_TO_CREATE[@]}"; do
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo -e "${YELLOW}[DRY-RUN]${RESET} mkdir -p $dir"
  else
    mkdir -p "$dir"
  fi
done

success "目錄結構已創建"

# =============================================================================
# Phase 3: 通訊頻道選擇
# =============================================================================
header "Phase 3: 通訊頻道設定"

echo "選擇您要啟用的通訊頻道:"
echo "  1) Telegram"
echo "  2) Feishu / Lark"
echo "  3) 兩者都要"
echo ""

while true; do
  read -r -p "請選擇 [1-3]: " CHANNEL_CHOICE
  case "$CHANNEL_CHOICE" in
    1|2|3) break ;;
    *) warn "請輸入 1、2 或 3" ;;
  esac
done

# ---- Telegram 配置 ----
if [[ "$CHANNEL_CHOICE" == "1" || "$CHANNEL_CHOICE" == "3" ]]; then
  echo ""
  echo -e "${BOLD}--- Telegram 配置 ---${RESET}"
  echo ""
  echo "您需要在 @BotFather 創建 Bot 並獲取 Token。"
  echo "詳情: https://core.telegram.org/bots#how-do-i-create-a-bot"
  echo ""

  # Main bot token
  while true; do
    read -rs -p "Main Bot Token (必填, 如 123456:ABC...): " TG_MAIN_TOKEN
    echo ""
    if confirm_not_empty "$TG_MAIN_TOKEN" "Main Bot Token"; then
      break
    fi
  done

  # Main bot token 文件路徑
  TG_MAIN_TOKEN_FILE_DEFAULT="${HOME}/.secrets/telegram.token"
  read -r -p "Main Token 保存路徑 (Enter 使用 ${TG_MAIN_TOKEN_FILE_DEFAULT}): " TG_MAIN_TOKEN_FILE
  if [[ -z "$TG_MAIN_TOKEN_FILE" ]]; then
    TG_MAIN_TOKEN_FILE="$TG_MAIN_TOKEN_FILE_DEFAULT"
  fi

  # Channel2 bot token（秘書頻道）
  echo ""
  echo "Channel2 Bot 用於秘書通知頻道 (可選，直接按 Enter 跳過):"
  read -rs -p "Channel2 Bot Token (可選): " TG_CHANNEL2_TOKEN
  echo ""

  if [[ -n "$TG_CHANNEL2_TOKEN" ]]; then
    TG_CHANNEL2_TOKEN_FILE_DEFAULT="${HOME}/.ssh/telegramChannel2.txt"
    read -r -p "Channel2 Token 保存路徑 (Enter 使用 ${TG_CHANNEL2_TOKEN_FILE_DEFAULT}): " TG_CHANNEL2_TOKEN_FILE
    if [[ -z "$TG_CHANNEL2_TOKEN_FILE" ]]; then
      TG_CHANNEL2_TOKEN_FILE="$TG_CHANNEL2_TOKEN_FILE_DEFAULT"
    fi
  fi

  # Telegram User ID
  echo ""
  echo "您的 Telegram User ID (用於 DM pairing):"
  echo "  可通過 @userinfobot 獲取"
  while true; do
    read -r -p "Telegram User ID (數字, 必填): " TG_USER_ID
    if [[ "$TG_USER_ID" =~ ^[0-9]+$ ]]; then
      break
    else
      warn "User ID 必須為純數字"
    fi
  done

  success "Telegram 配置收集完成"
fi

# ---- Feishu 配置 ----
if [[ "$CHANNEL_CHOICE" == "2" || "$CHANNEL_CHOICE" == "3" ]]; then
  echo ""
  echo -e "${BOLD}--- Feishu / Lark 配置 ---${RESET}"
  echo ""
  echo "您需要在飛書開放平台創建應用並獲取 App ID / App Secret。"
  echo "詳情: https://open.feishu.cn/app"
  echo ""

  while true; do
    read -r -p "App ID (如 cli_xxxxx): " FEISHU_APP_ID
    if confirm_not_empty "$FEISHU_APP_ID" "App ID"; then
      break
    fi
  done

  while true; do
    read -rs -p "App Secret: " FEISHU_APP_SECRET
    echo ""
    if confirm_not_empty "$FEISHU_APP_SECRET" "App Secret"; then
      break
    fi
  done

  success "Feishu 配置收集完成"
fi

# =============================================================================
# Phase 4: AI 模型提供商
# =============================================================================
header "Phase 4: AI 模型提供商設定"

echo "選擇 AI 模型提供商:"
echo "  1) copilot-proxy  (本地代理，需先運行 copilot-proxy)"
echo "  2) OpenAI         (需要 OpenAI API Key)"
echo "  3) Anthropic/Claude (需要 Anthropic API Key)"
echo ""

while true; do
  read -r -p "請選擇 [1-3]: " MODEL_CHOICE
  case "$MODEL_CHOICE" in
    1|2|3) break ;;
    *) warn "請輸入 1、2 或 3" ;;
  esac
done

case "$MODEL_CHOICE" in
  1)
    echo ""
    PROXY_URL_DEFAULT="http://localhost:3000/v1"
    read -r -p "Proxy URL (Enter 使用 ${PROXY_URL_DEFAULT}): " PROXY_URL
    if [[ -z "$PROXY_URL" ]]; then
      PROXY_URL="$PROXY_URL_DEFAULT"
    fi
    MODEL_PROVIDER_ID="copilot-proxy"
    MODEL_ID="gpt-5.3-codex"
    MODEL_BASE_URL="$PROXY_URL"
    success "copilot-proxy 配置完成 (URL: ${PROXY_URL})"
    ;;
  2)
    echo ""
    while true; do
      read -rs -p "OpenAI API Key (sk-...): " OPENAI_API_KEY
      echo ""
      if confirm_not_empty "$OPENAI_API_KEY" "OpenAI API Key"; then
        break
      fi
    done
    MODEL_PROVIDER_ID="openai"
    MODEL_ID="gpt-4o"
    MODEL_BASE_URL="https://api.openai.com/v1"
    success "OpenAI 配置完成"
    ;;
  3)
    echo ""
    while true; do
      read -rs -p "Anthropic API Key (sk-ant-...): " ANTHROPIC_API_KEY
      echo ""
      if confirm_not_empty "$ANTHROPIC_API_KEY" "Anthropic API Key"; then
        break
      fi
    done
    MODEL_PROVIDER_ID="anthropic"
    MODEL_ID="claude-opus-4-5"
    MODEL_BASE_URL="https://api.anthropic.com/v1"
    success "Anthropic 配置完成"
    ;;
esac

# =============================================================================
# Phase 5: 生成 openclaw.json
# =============================================================================
header "Phase 5: 生成 openclaw.json"

GATEWAY_TOKEN="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 2>/dev/null || openssl rand -hex 16)"

# 構建 channels 配置
build_channels_json() {
  local channels_json=""

  # --- Telegram ---
  if [[ "$CHANNEL_CHOICE" == "1" || "$CHANNEL_CHOICE" == "3" ]]; then
    local accounts_json=""
    accounts_json="$(cat <<ACCOUNTS_EOF
      "main": {
        "enabled": true,
        "dmPolicy": "pairing",
        "tokenFile": "${TG_MAIN_TOKEN_FILE}",
        "groupPolicy": "allowlist",
        "streamMode": "partial"
      }
ACCOUNTS_EOF
)"
    if [[ -n "$TG_CHANNEL2_TOKEN" ]]; then
      accounts_json="${accounts_json},
      \"channel2\": {
        \"name\": \"Kairo Assistant\",
        \"enabled\": true,
        \"tokenFile\": \"${TG_CHANNEL2_TOKEN_FILE}\"
      }"
    fi

    channels_json="$(cat <<TG_EOF
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "streamMode": "partial",
      "accounts": {
${accounts_json}
      }
    }
TG_EOF
)"
  fi

  # --- Feishu ---
  if [[ "$CHANNEL_CHOICE" == "2" || "$CHANNEL_CHOICE" == "3" ]]; then
    local feishu_block
    feishu_block="$(cat <<FS_EOF
    "feishu": {
      "enabled": true,
      "appId": "${FEISHU_APP_ID}",
      "appSecret": "${FEISHU_APP_SECRET}",
      "domain": "feishu",
      "connectionMode": "websocket",
      "dmPolicy": "open",
      "allowFrom": ["*"],
      "groupPolicy": "open",
      "groupAllowFrom": ["*"],
      "requireMention": true
    }
FS_EOF
)"
    if [[ -n "$channels_json" ]]; then
      channels_json="${channels_json},
${feishu_block}"
    else
      channels_json="$feishu_block"
    fi
  fi

  echo "$channels_json"
}

# 構建 model providers 配置
build_model_provider_json() {
  case "$MODEL_CHOICE" in
    1)
      cat <<EOF
      "copilot-proxy": {
        "baseUrl": "${PROXY_URL}",
        "apiKey": "copilot-proxy",
        "api": "openai-completions",
        "authHeader": false,
        "models": [
          {
            "id": "gpt-5.3-codex",
            "name": "gpt-5.3-codex",
            "api": "openai-completions",
            "reasoning": true,
            "input": ["text", "image"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 200000,
            "maxTokens": 32768
          }
        ]
      }
EOF
      ;;
    2)
      cat <<EOF
      "openai": {
        "baseUrl": "https://api.openai.com/v1",
        "apiKey": "${OPENAI_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "gpt-4o",
            "name": "gpt-4o",
            "api": "openai-completions",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": { "input": 2.5, "output": 10, "cacheRead": 1.25, "cacheWrite": 0 },
            "contextWindow": 128000,
            "maxTokens": 16384
          },
          {
            "id": "gpt-4o-mini",
            "name": "gpt-4o-mini",
            "api": "openai-completions",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": { "input": 0.15, "output": 0.6, "cacheRead": 0.075, "cacheWrite": 0 },
            "contextWindow": 128000,
            "maxTokens": 16384
          }
        ]
      }
EOF
      ;;
    3)
      cat <<EOF
      "anthropic": {
        "baseUrl": "https://api.anthropic.com/v1",
        "apiKey": "${ANTHROPIC_API_KEY}",
        "api": "anthropic-messages",
        "models": [
          {
            "id": "claude-opus-4-5",
            "name": "claude-opus-4-5",
            "api": "anthropic-messages",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": { "input": 15, "output": 75, "cacheRead": 1.5, "cacheWrite": 3.75 },
            "contextWindow": 200000,
            "maxTokens": 32000
          },
          {
            "id": "claude-sonnet-4-6",
            "name": "claude-sonnet-4-6",
            "api": "anthropic-messages",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": { "input": 3, "output": 15, "cacheRead": 0.3, "cacheWrite": 0.75 },
            "contextWindow": 200000,
            "maxTokens": 32000
          }
        ]
      }
EOF
      ;;
  esac
}

# 構建 bindings 配置
build_bindings_json() {
  local bindings="[]"
  local binding_list=""

  if [[ "$CHANNEL_CHOICE" == "1" || "$CHANNEL_CHOICE" == "3" ]]; then
    binding_list="${binding_list:+$binding_list,}
    {
      \"agentId\": \"main\",
      \"match\": { \"channel\": \"telegram\", \"accountId\": \"main\" }
    }"
    if [[ -n "$TG_CHANNEL2_TOKEN" ]]; then
      binding_list="${binding_list},
    {
      \"agentId\": \"executor\",
      \"match\": { \"channel\": \"telegram\", \"accountId\": \"channel2\" }
    }"
    fi
  fi

  if [[ "$CHANNEL_CHOICE" == "2" || "$CHANNEL_CHOICE" == "3" ]]; then
    binding_list="${binding_list:+$binding_list,}
    {
      \"agentId\": \"main\",
      \"match\": { \"channel\": \"feishu\" }
    }"
  fi

  if [[ -n "$binding_list" ]]; then
    echo "[${binding_list}
  ]"
  else
    echo "[]"
  fi
}

CHANNELS_JSON="$(build_channels_json)"
MODEL_PROVIDER_JSON="$(build_model_provider_json)"
BINDINGS_JSON="$(build_bindings_json)"

# 確定主模型配置
case "$MODEL_CHOICE" in
  1) PRIMARY_MODEL="copilot-proxy/gpt-5.3-codex" ;;
  2) PRIMARY_MODEL="openai/gpt-4o" ;;
  3) PRIMARY_MODEL="anthropic/claude-opus-4-5" ;;
esac

CONFIG_JSON="$(cat <<CONFIG_HEREDOC
{
  "meta": {
    "lastTouchedVersion": "2026.2.9",
    "lastTouchedAt": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
  },
  "models": {
    "providers": {
${MODEL_PROVIDER_JSON}
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "${PRIMARY_MODEL}"
      },
      "workspace": "${KAIRO_HOME}/workspace",
      "compaction": {
        "mode": "safeguard"
      },
      "maxConcurrent": 4,
      "subagents": {
        "maxConcurrent": 8
      }
    },
    "list": [
      {
        "id": "main",
        "default": true,
        "name": "Planner",
        "identity": {
          "name": "Kairo",
          "emoji": "pencil2"
        },
        "subagents": {
          "allowAgents": ["executor", "reviewer"]
        },
        "tools": {
          "profile": "full"
        }
      },
      {
        "id": "executor",
        "name": "Executor",
        "workspace": "${KAIRO_HOME}/workspace-executor",
        "identity": {
          "name": "Kairo Exec",
          "emoji": "zap"
        },
        "subagents": {
          "allowAgents": []
        },
        "tools": {
          "profile": "full"
        }
      },
      {
        "id": "reviewer",
        "name": "Reviewer",
        "workspace": "${KAIRO_HOME}/workspace-reviewer",
        "identity": {
          "name": "Kairo Watch",
          "emoji": "mag"
        },
        "subagents": {
          "allowAgents": ["executor"]
        },
        "tools": {
          "profile": "full"
        },
        "heartbeat": {
          "every": "30m",
          "activeHours": {
            "start": "07:00",
            "end": "23:30",
            "timezone": "Asia/Shanghai"
          },
          "mirrorTo": []
        }
      }
    ]
  },
  "messages": {
    "ackReactionScope": "group-mentions"
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  },
  "channels": {
${CHANNELS_JSON}
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "${GATEWAY_TOKEN}"
    }
  },
  "bindings": ${BINDINGS_JSON}
}
CONFIG_HEREDOC
)"

CONFIG_FILE="${KAIRO_HOME}/openclaw.json"
info "正在寫入配置文件: ${CONFIG_FILE}"
write_file "$CONFIG_FILE" "$CONFIG_JSON"

if [[ "$DRY_RUN" -eq 0 ]]; then
  chmod 600 "$CONFIG_FILE"
fi

success "openclaw.json 已生成"

# =============================================================================
# Phase 6: 保存 Telegram Token 文件 & 複製 models.json
# =============================================================================
header "Phase 6: Token 文件 & Agent models.json"

# ---- 保存 Telegram token 文件 ----
if [[ "$CHANNEL_CHOICE" == "1" || "$CHANNEL_CHOICE" == "3" ]]; then
  TG_MAIN_TOKEN_DIR="$(dirname "$TG_MAIN_TOKEN_FILE")"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo -e "${YELLOW}[DRY-RUN]${RESET} mkdir -p ${TG_MAIN_TOKEN_DIR}"
    echo -e "${YELLOW}[DRY-RUN]${RESET} Write TG main token → ${TG_MAIN_TOKEN_FILE}"
    echo -e "${YELLOW}[DRY-RUN]${RESET} chmod 600 ${TG_MAIN_TOKEN_FILE}"
  else
    mkdir -p "$TG_MAIN_TOKEN_DIR"
    printf '%s\n' "$TG_MAIN_TOKEN" > "$TG_MAIN_TOKEN_FILE"
    chmod 600 "$TG_MAIN_TOKEN_FILE"
    success "Main Bot Token → ${TG_MAIN_TOKEN_FILE}"
  fi

  if [[ -n "$TG_CHANNEL2_TOKEN" ]]; then
    TG_CHANNEL2_TOKEN_DIR="$(dirname "$TG_CHANNEL2_TOKEN_FILE")"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo -e "${YELLOW}[DRY-RUN]${RESET} mkdir -p ${TG_CHANNEL2_TOKEN_DIR}"
      echo -e "${YELLOW}[DRY-RUN]${RESET} Write TG channel2 token → ${TG_CHANNEL2_TOKEN_FILE}"
    else
      mkdir -p "$TG_CHANNEL2_TOKEN_DIR"
      printf '%s\n' "$TG_CHANNEL2_TOKEN" > "$TG_CHANNEL2_TOKEN_FILE"
      chmod 600 "$TG_CHANNEL2_TOKEN_FILE"
      success "Channel2 Bot Token → ${TG_CHANNEL2_TOKEN_FILE}"
    fi
  fi
fi

# ---- 複製 models.json 到各 agent 目錄 ----
# 查找 source models.json
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MODELS_JSON_SOURCES=(
  "${REPO_ROOT}/src/agents/tools/models.json"
  "${REPO_ROOT}/dist/agents/models.json"
  "$(npm root -g 2>/dev/null)/openclaw/models.json"
  "/opt/LazyingArtBot/src/agents/tools/models.json"
)

FOUND_MODELS_JSON=""
for src in "${MODELS_JSON_SOURCES[@]}"; do
  if [[ -f "$src" ]]; then
    FOUND_MODELS_JSON="$src"
    break
  fi
done

AGENT_IDS=("main" "executor" "reviewer")

if [[ -n "$FOUND_MODELS_JSON" ]]; then
  info "找到 models.json: ${FOUND_MODELS_JSON}"
  for agent_id in "${AGENT_IDS[@]}"; do
    DEST="${KAIRO_HOME}/agents/${agent_id}/agent/models.json"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo -e "${YELLOW}[DRY-RUN]${RESET} cp ${FOUND_MODELS_JSON} → ${DEST}"
    else
      cp "$FOUND_MODELS_JSON" "$DEST"
      success "models.json → agents/${agent_id}/agent/"
    fi
  done
else
  warn "未找到 models.json 源文件，將跳過複製"
  warn "請手動將 models.json 複製到以下位置:"
  for agent_id in "${AGENT_IDS[@]}"; do
    echo "  ${KAIRO_HOME}/agents/${agent_id}/agent/models.json"
  done
fi

# =============================================================================
# Phase 7: systemd 用戶服務（可選）
# =============================================================================
header "Phase 7: systemd 用戶服務（可選）"

if command -v systemctl >/dev/null 2>&1; then
  read -r -p "是否設置 systemd 用戶服務以開機自啟? [y/N]: " SETUP_SYSTEMD_ANSWER
  case "${SETUP_SYSTEMD_ANSWER:-N}" in
    y|Y|yes|YES) SETUP_SYSTEMD=1 ;;
    *) SETUP_SYSTEMD=0 ;;
  esac
else
  warn "系統不支持 systemctl，跳過 systemd 配置"
  SETUP_SYSTEMD=0
fi

if [[ "$SETUP_SYSTEMD" -eq 1 ]]; then
  SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
  SERVICE_FILE="${SYSTEMD_USER_DIR}/openclaw-gateway.service"

  # 查找 openclaw 可執行文件
  OPENCLAW_BIN="$(command -v openclaw 2>/dev/null || echo '')"
  if [[ -z "$OPENCLAW_BIN" ]]; then
    # 嘗試 npx/pnpx
    OPENCLAW_BIN="$(command -v openclaw-gateway 2>/dev/null || echo '')"
  fi
  if [[ -z "$OPENCLAW_BIN" ]]; then
    OPENCLAW_BIN="/usr/local/bin/openclaw"
    warn "未找到 openclaw 可執行文件，使用默認路徑: ${OPENCLAW_BIN}"
  fi

  SERVICE_CONTENT="$(cat <<SERVICE_EOF
[Unit]
Description=Kairo AI Secretary Gateway (openclaw)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Restart=on-failure
RestartSec=10
WorkingDirectory=${KAIRO_HOME}
Environment=HOME=${HOME}
Environment=OPENCLAW_STATE_DIR=${KAIRO_HOME}
Environment=OPENCLAW_GATEWAY_PORT=18789
Environment=MOLTBOT_CAPTURE_ALSO_REPLY=1
ExecStart=${OPENCLAW_BIN} gateway serve
StandardOutput=journal
StandardError=journal
SyslogIdentifier=openclaw-gateway

[Install]
WantedBy=default.target
SERVICE_EOF
)"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo -e "${YELLOW}[DRY-RUN]${RESET} mkdir -p ${SYSTEMD_USER_DIR}"
    echo -e "${YELLOW}[DRY-RUN]${RESET} Would write service file → ${SERVICE_FILE}"
    echo "--- service file preview ---"
    echo "$SERVICE_CONTENT" | head -20
    echo "---"
  else
    mkdir -p "$SYSTEMD_USER_DIR"
    printf '%s\n' "$SERVICE_CONTENT" > "$SERVICE_FILE"
    chmod 644 "$SERVICE_FILE"
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable openclaw-gateway.service 2>/dev/null || true
    success "systemd 服務已安裝: ${SERVICE_FILE}"
    info "啟用開機自啟: systemctl --user enable openclaw-gateway"
  fi
fi

# =============================================================================
# Phase 8: 完成訊息
# =============================================================================
header "Phase 8: 設置完成"

echo ""
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Kairo 設置完成！                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${BOLD}配置摘要:${RESET}"
echo "  資料目錄:    ${KAIRO_HOME}"
echo "  配置文件:    ${KAIRO_HOME}/openclaw.json"
echo "  AI 模型:     ${PRIMARY_MODEL}"

case "$CHANNEL_CHOICE" in
  1) echo "  通訊頻道:    Telegram" ;;
  2) echo "  通訊頻道:    Feishu / Lark" ;;
  3) echo "  通訊頻道:    Telegram + Feishu / Lark" ;;
esac

if [[ "$SETUP_SYSTEMD" -eq 1 ]]; then
  echo "  systemd 服務: 已安裝"
fi

echo ""
echo -e "${BOLD}下一步:${RESET}"
echo ""
echo "  1. 啟動服務:"
if [[ "$SETUP_SYSTEMD" -eq 1 ]]; then
  echo "       systemctl --user start openclaw-gateway"
else
  echo "       openclaw-restart"
  echo "       # 或: XDG_RUNTIME_DIR=/run/user/\$(id -u) systemctl --user start openclaw-gateway"
fi
echo ""

if [[ "$CHANNEL_CHOICE" == "1" || "$CHANNEL_CHOICE" == "3" ]]; then
  echo "  2. Telegram 配對:"
  echo "       在 Telegram 找到您的 Bot，發送 /start 開始配對"
  echo "       或者在 Kairo 界面掃描 QR Code"
  echo ""
fi

if [[ "$CHANNEL_CHOICE" == "2" || "$CHANNEL_CHOICE" == "3" ]]; then
  echo "  3. Feishu 授權:"
  echo "       確保 Bot 已加入您的工作區並訂閱了必要事件"
  echo "       OAuth URL 請參考文檔: docs/feishu-setup.md"
  echo ""
fi

echo "  4. 測試連接:"
echo "       向 Bot 發送「你好」確認連接正常"
echo ""
echo "  5. 查看日誌:"
echo "       journalctl --user -u openclaw-gateway -f"
echo "       # 或: sudo XDG_RUNTIME_DIR=/run/user/0 journalctl --user -u openclaw-gateway -f"
echo ""
echo "  6. 查看完整文檔:"
echo "       ${REPO_ROOT}/CLAUDE.md"
echo ""

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo -e "${YELLOW}[注意] 本次為 DRY-RUN 模式，以上操作均未實際執行${RESET}"
fi

echo -e "${GREEN}${BOLD}祝您使用愉快！${RESET}"
echo ""
