[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)


[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](../LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](../pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#quick-start)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](../package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](.)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](../docs)


**LazyingArtBot** は、**lazying.art** のために構築している個人用 AI アシスタントスタックです。  
OpenClaw をベースに、日々の運用向けに最適化しています。主な焦点は、マルチチャネル会話、ローカルファースト制御、そして email -> calendar/reminder/notes 自動化です。

| 🔗 Link | URL |
| --- | --- |
| 🌐 Website | https://lazying.art |
| 🤖 Bot domain | https://lazying.art |
| 🧱 Upstream base | https://github.com/openclaw/openclaw |
| 📦 This repo | https://github.com/lachlanchen/LazyingArtBot |

---

## Table of contents

- [Overview](#overview)
- [At a glance](#at-a-glance)
- [Features](#features)
- [Core capabilities](#core-capabilities)
- [Project structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Deployment modes](#deployment-modes)
- [LazyingArt workflow focus](#lazyingart-workflow-focus)
- [Orchestral philosophy](#orchestral-philosophy)
- [Prompt tools in LAB](#prompt-tools-in-lab)
- [Examples](#examples)
- [Development notes](#development-notes)
- [Troubleshooting](#troubleshooting)
- [LAB ecosystem integrations](#lab-ecosystem-integrations)
- [Install from source (quick reference)](#install-from-source-quick-reference)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [❤️ Support](#-support)
- [Acknowledgements](#acknowledgements)
- [License](#license)

---

## Overview

LAB は、実用的な個人生産性にフォーカスしています。

- ✅ 普段使っているチャットチャネルを横断して、1つのアシスタントを動かせます。
- 🔐 データと制御を自分のマシン/サーバー側に維持できます。
- 📬 受信メールを構造化アクション（Calendar / Reminders / Notes）へ変換できます。
- 🛡️ 自動化が安全に機能するよう、ガードレールを追加できます。

要するに、雑務を減らし、実行力を上げるための構成です。

---

## At a glance

| Area | Current baseline in this repo |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Package manager | `pnpm@10.23.0` |
| Core CLI | `openclaw` |
| Default local gateway | `127.0.0.1:18789` |
| Default bridge port | `127.0.0.1:18790` |
| Primary docs | `docs/` (Mintlify) |
| Primary LAB orchestration | `orchestral/` + `scripts/prompt_tools/` |
| README i18n location | `i18n/README.*.md` |

---

## Features

- 🌐 ローカルゲートウェイによるマルチチャネル・アシスタント実行基盤。
- 🖥️ ローカル運用向けのブラウザダッシュボード/チャット画面。
- 🧰 ツール連携型オートメーションパイプライン（scripts + prompt-tools）。
- 📨 メールのトリアージと Notes / Reminders / Calendar への変換。
- 🧩 チャネル/プロバイダ/統合向けプラグイン拡張エコシステム（`extensions/*`）。
- 📱 リポジトリ内のマルチプラットフォームUI（`apps/macos`, `apps/ios`, `apps/android`, `ui`）。

---

## Core capabilities

| Capability | What it means in practice |
| --- | --- |
| Multi-channel assistant runtime | 有効化したチャネル全体で動く gateway + agent session |
| Web dashboard / chat | ローカル運用を行うブラウザベースの制御画面 |
| Tool-enabled workflows | shell + file + automation script を連鎖させる実行フロー |
| Email automation pipeline | メール解析、アクション種別判定、Notes/Reminders/Calendar へのルーティング、監査/デバッグログ記録 |

現在のワークフローで維持されているパイプライン手順:

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

## Project structure

リポジトリの高レベル構成:

```text
.
├─ src/                 # core runtime, gateway, channels, CLI, infra
├─ extensions/          # optional channel/provider/auth plugins
├─ orchestral/          # LAB orchestration pipelines + prompt tools
├─ scripts/             # build/dev/test/release helpers
├─ ui/                  # web dashboard UI package
├─ apps/                # macOS / iOS / Android apps
├─ docs/                # Mintlify documentation
├─ references/          # LAB references and operating notes
├─ test/                # test suites
├─ i18n/                # localized README files
├─ .env.example         # environment template
├─ docker-compose.yml   # gateway + CLI containers
├─ README_OPENCLAW.md   # larger upstream-style reference README
└─ README.md            # this LAB-focused README
```

補足:

- `scripts/prompt_tools` は orchestral の prompt-tool 実装を指します。
- ルートの `i18n/` に各言語の README を格納しています。
- このスナップショットには `.github/workflows.disabled/` があり、実運用の CI 挙動は前提化せず確認してください。

---

## Prerequisites

このリポジトリでのランタイム/ツール基準:

- Node.js `>=22.12.0`
- pnpm `10.23.0` 基準（`package.json` の `packageManager` を参照）
- 設定済みのモデルプロバイダーキー（`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` など）
- 任意: コンテナ運用向けの Docker + Docker Compose
- 任意（モバイル/mac ビルド）: ターゲットプラットフォームに応じた Apple/Android ツールチェーン

任意のグローバル CLI インストール（quick-start と同じ流れ）:

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Quick start

このリポジトリのランタイム基準: **Node >= 22.12.0**（`package.json` engine）。

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

その後、ローカルのダッシュボード/チャットを開きます:

- http://127.0.0.1:18789

リモートアクセスする場合は、自分で管理する安全なトンネル（例: ngrok/Tailscale）経由でローカル gateway を公開し、認証を有効のまま運用してください。

---

## Installation

### Install from source

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Optional Docker workflow

同梱の `docker-compose.yml` には以下が含まれます:

- `openclaw-gateway`
- `openclaw-cli`

一般的な手順:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Compose でよく必要になる変数:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Usage

よく使うコマンド:

```bash
# Onboard and install user daemon
openclaw onboard --install-daemon

# Run gateway in foreground
openclaw gateway run --bind loopback --port 18789 --verbose

# Send a direct message via configured channels
openclaw message send --to +1234567890 --message "Hello from LAB"

# Ask the agent directly
openclaw agent --message "Create today checklist" --thinking high
```

開発ループ（watch mode）:

```bash
pnpm gateway:watch
```

UI 開発:

```bash
pnpm ui:dev
```

運用時に有用な追加コマンド:

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --all
openclaw status --deep
openclaw health
openclaw doctor
```

---

## Configuration

環境変数と設定の参照先は `.env` と `~/.openclaw/openclaw.json` に分かれています。

1. `.env.example` を起点にする。
2. gateway 認証を設定する（`OPENCLAW_GATEWAY_TOKEN` 推奨）。
3. 最低1つのモデルプロバイダーキーを設定する（`OPENAI_API_KEY`, `ANTHROPIC_API_KEY` など）。
4. 有効化するチャネルの認証情報だけを設定する。

リポジトリで維持されている `.env.example` の重要ポイント:

- Env 優先順位: process env -> `./.env` -> `~/.openclaw/.env` -> config `env` block。
- 既存の process env に入っている非空値は上書きされません。
- `gateway.auth.token` のような config キーが env fallback より優先される場合があります。

インターネット公開前のセキュリティ基準:

- gateway の auth/pairing を有効化したままにする。
- 受信チャネルの allowlist を厳格に保つ。
- すべての受信メッセージ/メールを未信頼入力として扱う。
- 最小権限で実行し、ログを定期確認する。

gateway を公開する場合は、token/password 認証と trusted proxy 設定を必須にしてください。

---

## Deployment modes

| Mode | Best for | Typical command |
| --- | --- | --- |
| Local foreground | 開発とデバッグ | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Local daemon | 日常の個人利用 | `openclaw onboard --install-daemon` |
| Docker | 分離された実行環境と再現可能なデプロイ | `docker compose up -d` |
| Remote host + tunnel | 自宅LAN外からのアクセス | gateway + 安全なトンネルを実行し、auth を有効化 |

前提: 本番レベルの reverse-proxy hardening、secret rotation、backup policy は環境ごとに定義してください。

---

## LazyingArt workflow focus

この fork は **lazying.art** における私の実運用フローを優先しています。

- 🎨 カスタムブランディング（LAB / panda theme）
- 📱 モバイルフレンドリーな dashboard/chat 体験
- 📨 automail パイプラインの派生（rule-triggered, codex-assisted save modes）
- 🧹 個人用 cleanup / sender-classification スクリプト
- 🗂️ 実運用向けに調整した notes/reminders/calendar ルーティング

自動化ワークスペース（ローカル）:

- `~/.openclaw/workspace/automation/`
- リポジトリ内のスクリプト参照: `references/lab-scripts-and-philosophy.md`
- 専用 Codex prompt tools: `scripts/prompt_tools/`

---

## Orchestral philosophy

LAB orchestration は、次の1ルールで設計しています。  
難しい目標を deterministic execution と、焦点化した prompt-tool chain に分解することです。

- Deterministic scripts は確実な基盤処理を担当:
  scheduling、file routing、run directory、retry、output handoff。
- Prompt tools は適応的な知性を担当:
  planning、triage、context synthesis、不確実性下での意思決定。
- すべての段階が再利用可能な成果物を出力し、下流ツールがゼロから始めずに高品質な最終ノート/メールを組み立てられるようにします。

主要 orchestral chain:

- Company entrepreneurship chain:
  company context ingestion -> market/funding/academic/legal intelligence -> concrete growth actions.
- Auto mail chain:
  inbound mail triage -> conservative skip policy for low-value mail -> structured Notes/Reminders/Calendar actions.
- Web search chain:
  results-page capture -> targeted deep reads with screenshot/content extraction -> evidence-backed synthesis.

---

## Prompt tools in LAB

Prompt tools は modular・composable・orchestration-first です。  
単体実行も、より大きなワークフロー内の連結段階としての実行もできます。

- Read/save operations:
  AutoLife 運用向けに Notes / Reminders / Calendar の出力を作成・更新。
- Screenshot/read operations:
  検索結果ページとリンク先ページを取得し、下流解析向けの構造化テキストを抽出。
- Tool-connection operations:
  deterministic script を呼び出し、段階間で成果物を受け渡し、文脈の連続性を維持。

主な配置先:

- `scripts/prompt_tools/`

---

## Examples

### Example: local-only gateway

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Example: ask agent to process daily planning

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Example: source build + watch loop

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

### Example: run in Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## Development notes

- ランタイム基準: Node `>=22.12.0`。
- パッケージマネージャ基準: `pnpm@10.23.0`（`packageManager` フィールド）。
- よく使う品質ゲート:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 開発時の CLI: `pnpm openclaw ...`
- TS 実行ループ: `pnpm dev`
- UI パッケージコマンドはルートスクリプト経由（`pnpm ui:build`, `pnpm ui:dev`）。

このリポジトリでよく使う拡張テストコマンド:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

追加の開発ヘルパー:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

前提メモ:

- モバイル/macOS アプリの build/run コマンドは `package.json`（`ios:*`, `android:*`, `mac:*`）にありますが、署名/プロビジョニング要件は環境依存で、この README では網羅していません。

---

## Troubleshooting

### Gateway not reachable on `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

ポート競合と daemon 競合を確認してください。Docker 利用時はホスト側ポートマッピングとサービスヘルスを確認します。

### Auth or channel config issues

- `.env.example` と突き合わせて `.env` を再確認する。
- 最低1つのモデルキーが設定されていることを確認する。
- 実際に有効化したチャネルのトークンだけが設定されていることを確認する。

### Build or install issues

- Node `>=22.12.0` で `pnpm install` を再実行する。
- `pnpm ui:build && pnpm build` で再ビルドする。
- optional native peer が不足する場合は、`@napi-rs/canvas` / `node-llama-cpp` の互換性に関する install log を確認する。

### General health checks

`openclaw doctor` を実行すると migration/security/config drift を検出できます。

### Useful diagnostics

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB ecosystem integrations

LAB は、私の AI プロダクト/研究リポジトリ群を、制作・成長・自動化のための単一運用レイヤーへ統合します。

Profile:

- https://github.com/lachlanchen?tab=repositories

連携リポジトリ:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

LAB の実運用統合ゴール:

- Auto write novels
- Auto develop apps
- Auto edit videos
- Auto publish outputs
- Auto analyze organoids
- Auto handle email operations

---

## Install from source (quick reference)

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

Dev loop:

```bash
pnpm gateway:watch
```

---

## Roadmap

この LAB fork の計画中の方向性（working roadmap）:

- sender/rule classification を強化し、automail の信頼性を拡張する。
- orchestral stage の composability と artifact traceability を改善する。
- mobile-first 運用と remote gateway 管理 UX を強化する。
- LAB ecosystem リポジトリとの統合を深め、エンドツーエンド自動生産を進める。
- unattended automation 向けに security default と observability の強化を継続する。

---

## Contributing

このリポジトリは OpenClaw のコアアーキテクチャを継承しつつ、個人の LAB 優先事項を反映しています。

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) を読む
- 上流ドキュメントを確認: https://docs.openclaw.ai
- セキュリティ関連は [`SECURITY.md`](../SECURITY.md) を参照

LAB 固有の挙動に迷う場合は、既存挙動を維持し、PR ノートで前提を明記してください。

---

## ❤️ Support

| Donate | PayPal | Stripe |
|---|---|---|
| [![Donate](https://img.shields.io/badge/Donate-LazyingArt-0EA5E9?style=for-the-badge&logo=ko-fi&logoColor=white)](https://chat.lazying.art/donate) | [![PayPal](https://img.shields.io/badge/PayPal-RongzhouChen-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/RongzhouChen) | [![Stripe](https://img.shields.io/badge/Stripe-Donate-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

---

## Acknowledgements

LazyingArtBot は **OpenClaw** をベースにしています:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

コアプラットフォームを支える OpenClaw のメンテナーとコミュニティに感謝します。

---

## License

MIT（該当箇所は upstream と同一）。詳細は `../LICENSE` を参照してください。
