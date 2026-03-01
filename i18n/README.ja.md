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

> 🌍 **i18n status:** `i18n/` には現在、Arabic / German / Spanish / French / Japanese / Korean / Russian / Vietnamese / Simplified Chinese / Traditional Chinese の各言語版 README が含まれます。英語版が増分更新の基準文です。

**LazyingArtBot** は私の個人的 AI アシスタント基盤で、**lazying.art** 向けに運用されています。

**LazyingArtBot** は OpenClaw を基盤にし、日常ワークフローに合わせて調整されています。マルチチャンネルのチャット、ローカルファースト制御、メール → カレンダー/リマインダー/ノートの自動化を重視しています。

| 🔗 Link          | URL                                          | Focus                                    |
| ---------------- | -------------------------------------------- | ---------------------------------------- |
| 🌐 Website       | https://lazying.art                          | メインドメインとステータスダッシュボード |
| 🤖 Bot domain    | https://lazying.art                          | チャットとアシスタントのエントリポイント |
| 🧱 Upstream base | https://github.com/openclaw/openclaw         | OpenClaw の基盤                          |
| 📦 This repo     | https://github.com/lachlanchen/LazyingArtBot | LAB 固有の拡張                           |

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
- [Contact](#contact)
- [License](#license)

---

## Overview

LAB の中心は、実用的な個人生産性です。

- ✅ すでに使っているチャットチャネル上で、1 つのアシスタントを運用できます。
- 🔐 データと制御を自分の端末/サーバー側に保持できます。
- 📬 受信メールを構造化されたアクション（Calendar、Reminders、Notes）へ変換できます。
- 🛡️ 自動化が便利でありつつも安全に使えるようガードレールを設計できます。

要するに、雑務を減らして実行品質を高めることです。

---

## At a glance

| Area                      | Current baseline in this repo              |
| ------------------------- | ------------------------------------------ |
| Runtime                   | Node.js `>=22.12.0`                        |
| Package manager           | `pnpm@10.23.0`                             |
| Core CLI                  | `openclaw`                                 |
| Default local gateway     | `127.0.0.1:18789`                          |
| Default bridge port       | `127.0.0.1:18790`                          |
| Primary docs              | `docs/` (Mintlify)                         |
| Primary LAB orchestration | `orchestral/` + `orchestral/prompt_tools/` |
| README i18n location      | `i18n/README.*.md`                         |

---

## Features

- 🌐 ローカルゲートウェイで動くマルチチャネルアシスタントランタイム。
- 🖥️ ローカル運用向けブラウザダッシュボード/チャットインターフェース。
- 🧰 ツール連携型の自動化パイプライン（scripts + prompt-tools）。
- 📨 受信メールを Notes / Reminders / Calendar のアクションへ変換。
- 🧩 チャネル、プロバイダー、統合向けのプラグイン / 拡張エコシステム（`extensions/*`）。
- 📱 リポジトリ内のマルチプラットフォーム UI（`apps/macos`, `apps/ios`, `apps/android`, `ui`）。

---

## Core capabilities

| Capability                      | What it means in practice                                                                                   |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Multi-channel assistant runtime | 有効化したチャネルで Gateway とエージェントセッションが連動                                                 |
| Web dashboard / chat            | ローカル運用のためのブラウザベース制御画面                                                                  |
| Tool-enabled workflows          | shell + file + 自動化スクリプト実行チェーン                                                                 |
| Email automation pipeline       | メールを解析してアクションを分類し、Notes / Reminders / Calendar に振り分け、確認とデバッグ向けに履歴を記録 |

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

Notes:

- `orchestral/prompt_tools` は orchestral の prompt-tool 実装を指します。
- ルートの `i18n/` にはローカライズされた README が入っています。
- `.github/workflows.disabled/` がこのスナップショットに存在します。実運用前に CI の挙動を確認してください。

---

## Prerequisites

本リポジトリの前提となる実行環境:

- Node.js `>=22.12.0`
- pnpm `10.23.0`（`package.json` の `packageManager` を参照）
- モデル提供元キー（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、`GEMINI_API_KEY` など）
- 任意: Docker + Docker Compose（ゲートウェイ/CLI のコンテナ実行）
- 任意: モバイル / mac ビルド時は対象プラットフォームに応じて Apple / Android のツールチェーン

Optional global CLI install (matches quick-start flow):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Quick start

このリポジトリの実行基準は **Node >= 22.12.0**（`package.json` の engine）です。

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

次に、ローカルダッシュボードを開いてください。

- http://127.0.0.1:18789

リモートアクセスが必要な場合は、ローカルゲートウェイを安全なトンネル（ngrok/Tailscale など）で公開し、認証は有効のままにします。

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

`docker-compose.yml` には以下が含まれます:

- `openclaw-gateway`
- `openclaw-cli`

代表的な流れ:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

よく使う Compose 変数:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Usage

一般的なコマンド:

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

環境情報と設定の参照先は `.env` と `~/.openclaw/openclaw.json` に分かれます。

1. `.env.example` をもとに開始します。
2. ゲートウェイ認証を設定します（`OPENCLAW_GATEWAY_TOKEN` 推奨）。
3. 少なくとも 1 つのモデルキーを設定します（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY` など）。
4. 有効化したチャネルだけの認証情報を設定します。

英語版 `README` から引き継いだ `.env.example` の重要点:

- Env の優先順位: process env -> `./.env` -> `~/.openclaw/.env` -> 設定ファイルの `env` ブロック
- 既存の空でない process env 値は上書きされません。
- `gateway.auth.token` などの設定キーは、環境変数フォールバックより優先される場合があります。

インターネット公開前のセキュリティ基本方針:

- ゲートウェイ認証 / ペアリングを有効化する。
- 受信チャネルの allowlist を厳密にする。
- 受信メッセージ／メールはすべて不審要素を含む入力として扱う。
- 最小権限で運用し、ログを定期的に確認する。

ゲートウェイを公開する場合は、token/password 認証と trusted proxy 設定を必須化してください。

---

## Deployment modes

| Mode                 | Best for                                 | Typical command                                               |
| -------------------- | ---------------------------------------- | ------------------------------------------------------------- |
| Local foreground     | 開発とデバッグ                           | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Local daemon         | 日常利用                                 | `openclaw onboard --install-daemon`                           |
| Docker               | 分離された実行環境と再現性の高いデプロイ | `docker compose up -d`                                        |
| Remote host + tunnel | 自宅 LAN 外からアクセス                  | ゲートウェイ + secure tunnel を起動し、認証を有効化           |

前提として、運用レベルの reverse-proxy 強化、シークレットローテーション、バックアップ方針は環境ごとに定義します。

---

## LazyingArt workflow focus

このフォークは **lazying.art** 向けの個人ワークフローを優先しています。

- 🎨 カスタムブランド（LAB / panda テーマ）
- 📱 モバイル向けに使いやすいダッシュボード / チャット体験
- 📨 automail パイプラインの派生運用（ルール起動、Codex 補助保存モード）
- 🧹 送信者分類と個人向けクリーンアップのスクリプト
- 🗂️ Notes / Reminders / Calendar のルーティングを日常利用向けに調整

自動化ワークスペース（ローカル）:

- `~/.openclaw/workspace/automation/`
- リポジトリ内の参照: `references/lab-scripts-and-philosophy.md`
- 専用 Codex prompt tools: `orchestral/prompt_tools/`

---

## Orchestral philosophy

LAB の orchestration は次の設計原則に従います。
難しい目標は、確定的な実行処理と、焦点を絞ったプロンプトツールチェーンに分解します。

- Deterministic scripts が信頼性の高い基盤を担います。
  スケジューリング、ファイル振り分け、実行ディレクトリ、再試行、成果物受け渡しを処理します。
- Prompt tools が適応型の知性を担います。
  計画、トリアージ、文脈統合、条件不確実時の意思決定を実行します。
- 各ステージで再利用可能な成果物を出力し、下流のツールが一から始めなくても、より強い最終ノートやメールへ連結できるようにします。

主な orchestral chain:

- Company entrepreneurship chain:
  company context ingestion -> market/funding/academic/legal intelligence -> concrete growth actions.
- Auto mail chain:
  inbound mail triage -> conservative skip policy for low-value mail -> structured Notes/Reminders/Calendar actions.
- Web search chain:
  results-page capture -> targeted deep reads with screenshot/content extraction -> evidence-backed synthesis.

---

## Prompt tools in LAB

Prompt tools はモジュール式で、組み合わせやすく、orchestration-first の設計です。
単体でも利用でき、より大きなワークフローの連結段階としてつなぐこともできます。

- Read/save operations:
  AutoLife 運用向けの Notes、Reminders、Calendar の出力を作成・更新。
- Screenshot/read operations:
  検索結果ページとリンク先ページをキャプチャし、構造化テキストを抽出して下流解析へ渡します。
- Tool-connection operations:
  deterministic script を呼び、段階間で成果物を渡し、文脈の継続性を維持。

主な配置先:

- `orchestral/prompt_tools/`

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

- 実行基盤: Node `>=22.12.0`。
- パッケージマネージャ基準: `pnpm@10.23.0`（`packageManager` フィールド）。
- 主要な品質ゲート:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 開発時の CLI: `pnpm openclaw ...`
- TypeScript 実行ループ: `pnpm dev`
- UI パッケージの実行は root スクリプト経由（`pnpm ui:build`, `pnpm ui:dev`）。

本リポジトリで一般的な拡張テスト:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

追加の開発用ヘルパー:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

前提:

- モバイル / macOS 向けの build/run コマンドは `package.json`（`ios:*`, `android:*`, `mac:*`）に存在しますが、プラットフォーム固有の署名要件・プロビジョニングは環境依存であり、README では完全には記載されていません。

---

## Troubleshooting

### Gateway not reachable on `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

ポート競合やデーモン競合を確認してください。Docker 使用時は、ホストの公開ポートとサービスヘルスを検証します。

### Auth or channel config issues

- `.env` の値を `.env.example` と照合して再確認します。
- 少なくとも 1 つのモデルキーが設定されているか確認します。
- 有効化したチャネルのみトークンが設定されているか確認します。

### Build or install issues

- Node `>=22.12.0` で `pnpm install` を再実行します。
- `pnpm ui:build && pnpm build` で再構築します。
- optional native peer が不足している場合は、`@napi-rs/canvas` / `node-llama-cpp` の互換性をインストールログで確認します。

### General health checks

`openclaw doctor` を使って migration/security/config drift の問題を確認します。

### Useful diagnostics

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB ecosystem integrations

LAB は私の他の AI 製品・研究リポジトリを1つの運用レイヤーへ統合し、制作・成長・自動化を支えます。

Profile:

- https://github.com/lachlanchen?tab=repositories

Integrated repos:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (小説自動生成)
- `AutoAppDev` (アプリ開発の自動化)
- `OrganoidAgent` (基盤ビジョンモデル + LLM を使うオルガノイド研究基盤)
- `LazyEdit` (字幕/文字起こし/ハイライト/メタデータ/字幕を含む動画編集支援)
- `AutoPublish` (自動公開パイプライン)

実運用での LAB 統合目標:

- 自動で小説を執筆
- 自動でアプリを開発
- 自動で動画編集
- 自動で成果物を公開
- 自動でオルガノイドを分析
- 自動でメール運用を処理

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

この LAB フォークの進行中ロードマップ:

- sender/rule 分類を厳密化して automail の信頼性を向上
- orchestral stage の構成性と artifact の追跡可能性を改善
- モバイルファースト運用とリモートゲートウェイ管理 UX を強化
- LAB エコシステムリポジトリとの統合を深め、エンドツーエンドの自動制作を拡張
- 無人自動化運用でも安全に動くようセキュリティ既定値と観測性を継続強化

---

## Contributing

このリポジトリは OpenClaw の中核アーキテクチャを継承しつつ、個人 LAB の優先課題を反映しています。

- [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- 上流ドキュメントを確認: https://docs.openclaw.ai
- セキュリティ問題については [`SECURITY.md`](../SECURITY.md)

LAB 固有の挙動が不明な場合は、既存の動作を保ったまま、PR ノートに前提を明記してください。

---

## Acknowledgements

LazyingArtBot は **OpenClaw** をベースにしています。

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

OpenClaw の中核プラットフォームを支えるメンテナーとコミュニティに感謝します。

## ❤️ Support

| Donate                                                                                                                                                                                                                                                                                                                                                     | PayPal                                                                                                                                                                                                                                                                                                                                                          | Stripe                                                                                                                                                                                                                                                                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

## Contact

- Website: https://lazying.art
- Repository: https://github.com/lachlanchen/LazyingArtBot
- Issue tracker: https://github.com/lachlanchen/LazyingArtBot/issues
- Security or safety concerns: https://github.com/lachlanchen/LazyingArtBot/blob/main/SECURITY.md

---

## License

MIT（該当する場合は upstream と同一）。`../LICENSE` を参照。
