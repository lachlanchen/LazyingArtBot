[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)



[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](../LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](../pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#quick-start)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](../package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](../i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](../docs)
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)

> 🌍 **i18n status:** `i18n/` exists and currently includes localized README files for Arabic, German, Spanish, French, Japanese, Korean, Russian, Vietnamese, Simplified Chinese, and Traditional Chinese. This English draft remains the canonical source for incremental updates.

**LazyingArtBot** は **lazying.art** 用の私的 AI アシスタント基盤です。

**LazyingArtBot** は OpenClaw 上に構築され、日常のワークフロー向けに調整されています。マルチチャネルのチャット、ローカルファーストの制御、email → calendar/reminder/notes の自動化に重点を置いています。

| 🔗 Link | URL | Focus |
| --- | --- | --- |
| 🌐 Website | https://lazying.art | プライマリドメインとステータスダッシュボード |
| 🤖 Bot domain | https://lazying.art | チャットとアシスタントのエントリーポイント |
| 🧱 Upstream base | https://github.com/openclaw/openclaw | OpenClaw プラットフォーム基盤 |
| 📦 This repo | https://github.com/lachlanchen/LazyingArtBot | LAB 固有の拡張 |

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
- [Acknowledgements](#acknowledgements)
- [❤️ Support](#-support)
- [License](#license)

---

## Overview

LAB の焦点は実用的な個人生産性です。

- ✅ 既に使っているチャネル上で、1 つのアシスタントを運用できます。
- 🔐 データと制御を自分のマシン/サーバー上に保持できます。
- 📬 受信メールを構造化されたアクション（Calendar、Reminders、Notes）へ変換できます。
- 🛡️ 自動化が有益だが安全なまま動くようガードレールを付与できます。

要するに、雑務を減らし、実行を改善する設計です。

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

- 🌐 ローカルゲートウェイを用いたマルチチャネルアシスタントランタイム。
- 🖥️ ローカル運用向けのブラウザベースのダッシュボード/チャット画面。
- 🧰 ツールを使った自動化パイプライン（scripts + prompt-tools）。
- 📨 メールトリアージを Notes、Reminders、Calendar のアクションに変換。
- 🧩 チャネル/プロバイダー/統合向けのプラグイン/拡張エコシステム（`extensions/*`）。
- 📱 リポジトリ内の複数プラットフォーム向け UI（`apps/macos`, `apps/ios`, `apps/android`, `ui`）。

---

## Core capabilities

| Capability | What it means in practice |
| --- | --- |
| Multi-channel assistant runtime | 有効化したチャネル全体で動作するゲートウェイ + エージェントセッション |
| Web dashboard / chat | ローカル運用を行うためのブラウザベース制御画面 |
| Tool-enabled workflows | シェル + ファイル + 自動化スクリプト実行チェーン |
| Email automation pipeline | メール解析、アクション分類、Notes/Reminders/Calendar への振り分け、監査・デバッグ用の記録 |

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
- ルートの `i18n/` に言語別 README が格納されています。
- `.github/workflows.disabled/` はこのスナップショットに存在します。実際の CI の挙動は、利用前に確認してください。

---

## Prerequisites

このリポジトリの実行環境とツールの基準:

- Node.js `>=22.12.0`
- pnpm `10.23.0` ベースライン（`package.json` の `packageManager` を参照）
- モデル提供元のキー設定（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、`GEMINI_API_KEY` など）
- 任意: Docker + Docker Compose（コンテナ化された gateway/CLI 用）
- 任意: モバイル/mac ビルド向けに Apple/Android のツールチェーン

任意のグローバル CLI インストール（quick-start の流れと一致）:

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Quick start

このリポジトリの実行環境は **Node >= 22.12.0**（`package.json` の engine）です。

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

その後、ローカルダッシュボードを開きます。

- http://127.0.0.1:18789

リモートアクセスする場合は、ローカルゲートウェイを secure tunnel（例: ngrok/Tailscale）を通して公開し、認証を有効のまま運用してください。

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

`docker-compose.yml` には次が含まれます:

- `openclaw-gateway`
- `openclaw-cli`

一般的な手順:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

よく使われる Compose 変数:

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

運用で便利なコマンド:

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

環境変数と設定は `.env` と `~/.openclaw/openclaw.json` に分かれます。

1. `.env.example` を起点にします。
2. ゲートウェイ認証を設定します（`OPENCLAW_GATEWAY_TOKEN` 推奨）。
3. 少なくとも 1 つのモデルプロバイダーキーを設定します（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY` など）。
4. 有効にするチャネルの認証情報だけを設定します。

`.env.example` の重要な注意点:

- Env の優先順位: process env -> `./.env` -> `~/.openclaw/.env` -> config の `env` ブロック
- 既存で非空の process env 値は上書きされません。
- `gateway.auth.token` のような config キーは、環境変数のフォールバックより優先される場合があります。

インターネット公開前のセキュリティ基本方針:

- ゲートウェイ認証/ペアリングを有効にします。
- 受信チャネルの allowlist を厳格にします。
- すべての受信メッセージ/メールを信頼されていない入力として扱います。
- 最小権限で実行し、ログを定期的に確認します。

ゲートウェイを公開する場合、token/password 認証と trusted proxy 設定は必須にします。

---

## Deployment modes

| Mode | Best for | Typical command |
| --- | --- | --- |
| Local foreground | 開発とデバッグ | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Local daemon | 日常利用 | `openclaw onboard --install-daemon` |
| Docker | 分離された実行環境と再現性の高いデプロイ | `docker compose up -d` |
| Remote host + tunnel | 自宅 LAN 外からのアクセス | ゲートウェイ起動後に secure tunnel を構築し、認証を有効化 |

前提条件: 本番レベルの reverse-proxy hardening、secret rotation、バックアップ方針は環境ごとに定義してください。

---

## LazyingArt workflow focus

このフォークでは **lazying.art** の個人運用を最優先しています。

- 🎨 カスタムブランディング（LAB / panda テーマ）
- 📱 モバイルフレンドリーなダッシュボード／チャット体験
- 📨 automail パイプラインの派生運用（rule-triggered、codex-assisted save のモード）
- 🧹 個人用のクリーンアップと送信者分類スクリプト
- 🗂️ Notes / Reminders / Calendar のルーティングを日々の実運用向けに調整

自動化ワークスペース（ローカル）:

- `~/.openclaw/workspace/automation/`
- リポジトリ内の参照: `references/lab-scripts-and-philosophy.md`
- 専用 Codex prompt tools: `scripts/prompt_tools/`

---

## Orchestral philosophy

LAB のオーケストレーションは、1 つの設計原則で動きます。
難しい目標を「確定的実行」と「焦点化した prompt-tool チェーン」に分解することです。

- Deterministic scripts は確実な処理を担います。
  スケジュール、ファイルルーティング、実行ディレクトリ管理、リトライ、成果物受け渡しなど。
- Prompt tools は適応的な知性を担います。
  計画、トリアージ、文脈統合、不確実性下での意思決定。
- 各段階で再利用可能な成果物を出力し、後段のツールがゼロから再構築せずに、より良い最終ノート/メールを合成できます。

主要な orchestral チェーン:

- Company entrepreneurship chain:
  company context ingestion -> market/funding/academic/legal intelligence -> concrete growth actions.
- Auto mail chain:
  inbound mail triage -> conservative skip policy for low-value mail -> structured Notes/Reminders/Calendar actions.
- Web search chain:
  results-page capture -> targeted deep reads with screenshot/content extraction -> evidence-backed synthesis.

---

## Prompt tools in LAB

Prompt tools はモジュール化され、合成可能で、orchestration-first です。
単体でも使えますし、より大きなワークフローの連結段階としても使えます。

- Read/save operations:
  AutoLife 向けの Notes、Reminders、Calendar の出力を作成・更新します。
- Screenshot/read operations:
  検索結果ページとリンク先ページをキャプチャし、構造化テキストを抽出して下流分析に渡します。
- Tool-connection operations:
  deterministic script を呼び出し、段階間で成果物を共有し、文脈の連続性を維持します。

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
- パッケージマネージャ基準: `pnpm@10.23.0`（`packageManager` 設定）。
- よく使う品質ゲート:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 開発中の CLI: `pnpm openclaw ...`
- TypeScript 実行ループ: `pnpm dev`
- UI のパッケージコマンドはルートのスクリプト経由です（`pnpm ui:build`、`pnpm ui:dev`）。

このリポジトリでの拡張テストコマンド:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

追加の開発支援コマンド:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

前提:

- モバイル/macOS アプリの build/run コマンドは `package.json`（`ios:*`、`android:*`、`mac:*`）に存在しますが、プラットフォーム別の署名・プロビジョニング要件は環境依存であり、この README では完全にはドキュメント化されていません。

---

## Troubleshooting

### Gateway not reachable on `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

ポート競合やデーモン競合を確認します。Docker を使う場合は、ホスト側のポート割り当てとサービス状態を確認してください。

### Auth or channel config issues

- `.env` と `.env.example` を照合して再確認します。
- 少なくとも 1 つのモデルキーが設定されていることを確認します。
- 有効化したチャネルのトークンだけが設定されていることを確認します。

### Build or install issues

- Node `>=22.12.0` で `pnpm install` を再実行します。
- `pnpm ui:build && pnpm build` で再ビルドします。
- optional native peer が不足している場合は、`@napi-rs/canvas` / `node-llama-cpp` の互換性でインストールログを確認します。

### General health checks

`openclaw doctor` を使って migration/security/config drift 問題を検出します。

### Useful diagnostics

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB ecosystem integrations

LAB は、私の AI 製品・研究リポジトリを 1 つの運用レイヤーに統合し、制作・成長・自動化を支えます。

Profile:

- https://github.com/lachlanchen?tab=repositories

連携リポジトリ:

- `VoidAbyss` （隙遊之淵）
- `AutoNovelWriter`（automatic novel writing）
- `AutoAppDev`（automatic app development）
- `OrganoidAgent`（organoid research platform with foundation vision models + LLMs）
- `LazyEdit`（AI-assisted video editing: captions/transcription/highlights/metadata/subtitles）
- `AutoPublish`（automatic publication pipeline）

実用的な LAB 統合ゴール:

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

この LAB フォークの計画中の方向性（working roadmap）:

- 送信者/ルール分類を強化し、automail の信頼性を高める。
- orchestral stage の composability と artifact traceability を改善する。
- モバイルファースト運用と remote gateway 管理 UX を強化する。
- LAB エコシステムリポジトリとの統合を深め、エンドツーエンドの自動化生産を拡張する。
- 常時運用自動化向けにセキュリティ既定値と observability を継続的に強化する。

---

## Contributing

このリポジトリは OpenClaw のコアアーキテクチャを継承しつつ、個人 LAB の優先事項を追従しています。

- [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- 上流ドキュメントを確認: https://docs.openclaw.ai
- セキュリティ問題については [`SECURITY.md`](../SECURITY.md)

LAB 固有の挙動について不明な点がある場合、既存動作を維持し、PR ノートに前提を明記してください。

---

## Acknowledgements

LazyingArtBot は **OpenClaw** をベースにしています。

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

コアプラットフォームを支える OpenClaw のメンテナーとコミュニティに感謝します。

## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

## License

MIT（該当する場合は upstream と同一）。`../LICENSE` を参照してください。
