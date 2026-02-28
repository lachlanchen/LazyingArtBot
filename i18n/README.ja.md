[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)


<p align="center">
  <img src="https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png" alt="LazyingArtBot banner" />
</p>

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#-quick-start)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)

> 注: `i18n/` は存在しており、このスナップショット時点ではアラビア語を含みます。追加のローカライズREADMEは、ソース更新との整合性を保つために1言語ずつ管理されます。

**LazyingArtBot** は、**lazying.art** のための個人向け AI アシスタント基盤です。  
OpenClaw をベースに、日常ワークフロー向けに最適化しています: マルチチャネルチャット、ローカルファースト制御、メール → カレンダー/リマインダー/ノート自動化。

| リンク | URL |
| --- | --- |
| Website | https://lazying.art |
| Bot domain | https://lazying.art |
| Upstream base | https://github.com/openclaw/openclaw |
| This repo | https://github.com/lachlanchen/LazyingArtBot |

---

## Table of contents

- [🧭 Overview](#-overview)
- [⚡ At a glance](#-at-a-glance)
- [⚙️ Core capabilities](#️-core-capabilities)
- [🧱 Project structure](#-project-structure)
- [📋 Prerequisites](#-prerequisites)
- [🚀 Quick start](#-quick-start)
- [🧱 Installation](#-installation)
- [🛠️ Usage](#️-usage)
- [🔐 Configuration](#-configuration)
- [🧩 LazyingArt workflow focus](#-lazyingart-workflow-focus)
- [🎼 Orchestral philosophy](#-orchestral-philosophy)
- [🧰 Prompt tools in LAB](#-prompt-tools-in-lab)
- [💡 Examples](#-examples)
- [🧪 Development notes](#-development-notes)
- [🩺 Troubleshooting](#-troubleshooting)
- [🌐 LAB ecosystem integrations](#-lab-ecosystem-integrations)
- [Install from source](#install-from-source)
- [🗺️ Roadmap](#️-roadmap)
- [🤝 Contributing](#-contributing)
- [❤️ Support / Sponsor](#️-support--sponsor)
- [🙏 Acknowledgements](#-acknowledgements)
- [📄 License](#-license)

---

## 🧭 Overview

LAB は、実用的な個人生産性に焦点を当てています:

- ふだん使っているチャットチャネルを 1 つのアシスタントで運用する。
- データと制御を自分のマシン/サーバーに保持する。
- 受信メールを構造化アクション（Calendar、Reminders、Notes）へ変換する。
- 自動化を便利さと安全性の両立ができるようガードレールを追加する。

要するに: 雑務を減らし、実行力を高めることです。

---

## ⚡ At a glance

| 項目 | このリポジトリでの現在のベースライン |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Package manager | `pnpm@10.23.0` |
| Core CLI | `openclaw` |
| Default local gateway | `127.0.0.1:18789` |
| Primary docs | `docs/` (Mintlify) |
| Primary LAB orchestration | `orchestral/` + `scripts/prompt_tools/` |

---

## ⚙️ Core capabilities

- マルチチャネル対応アシスタント実行基盤（Gateway + agent sessions）。
- Web ダッシュボード / Web チャット制御画面。
- ツール利用対応のエージェントワークフロー（shell、files、automation scripts）。
- 個人運用向けメール自動化パイプライン:
  - 受信メールを解析
  - アクション種別を分類
  - Notes / Reminders / Calendar に保存
  - すべてのアクションをレビュー/デバッグ用に記録

---

## 🧱 Project structure

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
├─ .env.example         # environment template
├─ docker-compose.yml   # gateway + CLI containers
├─ README_OPENCLAW.md   # larger upstream-style reference README
└─ README.md            # this LAB-focused README
```

補足:

- `scripts/prompt_tools` は orchestral の prompt-tool 実装を指します。
- ルートの `i18n/` は存在し、このスナップショットでは最小構成です。ローカライズ文書の主な配置先は `docs/` です。

---

## 📋 Prerequisites

このリポジトリでのランタイム/ツール基準:

- Node.js `>=22.12.0`
- pnpm `10.23.0` ベースライン（`packageManager` in `package.json`）
- 設定済みモデルプロバイダキー（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY`、`GEMINI_API_KEY` など）
- 任意: Docker + Docker Compose（gateway/CLI のコンテナ運用向け）

任意のグローバル CLI インストール（quick-start と同じ流れ）:

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## 🚀 Quick start

このリポジトリのランタイム基準: **Node >= 22.12.0**（`package.json` engine）。

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

その後、ローカルのダッシュボードとチャットを開きます:

- http://127.0.0.1:18789

リモートアクセス時は、ローカル gateway を自分で管理する安全なトンネル（例: ngrok/Tailscale）経由で公開し、認証を有効に保ってください。

---

## 🧱 Installation

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

一般的な手順:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

注: マウントパスとポートは `OPENCLAW_CONFIG_DIR`、`OPENCLAW_WORKSPACE_DIR`、`OPENCLAW_GATEWAY_PORT`、`OPENCLAW_BRIDGE_PORT` などの compose 変数で制御されます。

---

## 🛠️ Usage

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

開発ループ（watch モード）:

```bash
pnpm gateway:watch
```

UI 開発:

```bash
pnpm ui:dev
```

---

## 🔐 Configuration

環境変数と設定の参照先は `.env` と `~/.openclaw/openclaw.json` に分かれています。

1. `.env.example` から始める。
2. gateway 認証を設定する（`OPENCLAW_GATEWAY_TOKEN` 推奨）。
3. 少なくとも 1 つのモデルプロバイダキーを設定する（`OPENAI_API_KEY`、`ANTHROPIC_API_KEY` など）。
4. 有効化するチャネルの認証情報のみ設定する。

リポジトリの `.env.example` から引き継ぐ重要メモ:

- Env の優先順位: process env → `./.env` → `~/.openclaw/.env` → config `env` block。
- 既存の空でない process env 値は上書きされません。
- `gateway.auth.token` などの config key は env フォールバックより優先される場合があります。

インターネット公開前のセキュリティ重要ベースライン:

- gateway の auth/pairing を有効に保つ。
- 受信チャネルの allowlist を厳格に保つ。
- すべての受信メッセージ/メールを未信頼入力として扱う。
- 最小権限で実行し、ログを定期的に確認する。

gateway をインターネットへ公開する場合は、token/password 認証と trusted proxy 設定を必須にしてください。

---

## 🧩 LazyingArt workflow focus

このフォークは **lazying.art** における個人運用フローを優先しています:

- カスタムブランディング（LAB / panda theme）
- モバイルフレンドリーなダッシュボード/チャット体験
- automail パイプラインのバリエーション（rule-triggered、codex-assisted save modes）
- 個人向けクリーンアップ/送信者分類スクリプト
- 日々の実運用に合わせて調整した notes/reminders/calendar ルーティング

自動化ワークスペース（ローカル）:

- `~/.openclaw/workspace/automation/`
- リポジトリ内スクリプト参照: `references/lab-scripts-and-philosophy.md`
- 専用 Codex prompt tools: `scripts/prompt_tools/`

---

## 🎼 Orchestral philosophy

LAB オーケストレーションは 1 つの設計原則に従います:  
難しい目標を、決定論的実行 + 焦点化した prompt-tool チェーンに分解すること。

- 決定論的スクリプトは、信頼性の高い基盤処理を担当:
  scheduling、file routing、run directories、retries、output handoff。
- Prompt tools は、適応的な知能処理を担当:
  planning、triage、context synthesis、不確実性下での意思決定。
- 各ステージは再利用可能な成果物を出力し、下流ツールがゼロから始めずに、より強い最終ノート/メールを組み立てられるようにします。

主要な orchestral チェーン:

- Company entrepreneurship chain:
  company context ingestion → market/funding/academic/legal intelligence → concrete growth actions。
- Auto mail chain:
  inbound mail triage → low-value mail 向け conservative skip policy → structured Notes/Reminders/Calendar actions。
- Web search chain:
  results-page capture → screenshot/content extraction を使った targeted deep reads → evidence-backed synthesis。

---

## 🧰 Prompt tools in LAB

Prompt tools はモジュール式で、合成しやすく、オーケストレーション優先です。  
単体でも、より大きなワークフローの連結ステージとしても実行できます。

- Read/save operations:
  AutoLife 運用向けに Notes、Reminders、Calendar 出力を作成/更新。
- Screenshot/read operations:
  検索結果ページとリンク先ページを取得し、下流分析向けの構造化テキストを抽出。
- Tool-connection operations:
  決定論的スクリプトの呼び出し、ステージ間成果物の受け渡し、コンテキスト連続性の維持。

主な配置先:

- `scripts/prompt_tools/`

---

## 💡 Examples

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

---

## 🧪 Development notes

- ランタイム基準: Node `>=22.12.0`。
- パッケージマネージャ基準: `pnpm@10.23.0`（`packageManager` field）。
- 主な品質ゲート:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 開発時 CLI: `pnpm openclaw ...`
- TS 実行ループ: `pnpm dev`
- UI パッケージコマンドはルートスクリプト経由で実行（`pnpm ui:build`, `pnpm ui:dev`）。

---

## 🩺 Troubleshooting

### Gateway not reachable on `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

ポート競合や daemon 競合を確認してください。Docker を使っている場合は、ホスト側マッピングポートとサービスヘルスを確認します。

### Auth or channel config issues

- `.env` の値を `.env.example` と照合して再確認する。
- 少なくとも 1 つのモデルキーが設定済みであることを確認する。
- 実際に有効化したチャネル分だけトークンを設定しているか確認する。

### General health checks

移行/セキュリティ/設定ドリフトの問題を検出するため、`openclaw doctor` を使います。

---

## 🌐 LAB ecosystem integrations

LAB は、作成・成長・自動化のために、より広い AI 製品/研究リポジトリ群を 1 つの運用レイヤーへ統合します。

Profile:

- https://github.com/lachlanchen?tab=repositories

Integrated repos:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

実運用での LAB 統合ゴール:

- Auto write novels
- Auto develop apps
- Auto edit videos
- Auto publish outputs
- Auto analyze organoids
- Auto handle email operations

---

## Install from source

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

開発ループ:

```bash
pnpm gateway:watch
```

---

## 🗺️ Roadmap

この LAB フォークの計画中の方向性（作業ロードマップ）:

- sender/rule classification をより厳密化し、automail の信頼性を拡張する。
- orchestral ステージの合成可能性と成果物トレーサビリティを改善する。
- モバイルファースト運用とリモート gateway 管理 UX を強化する。
- LAB エコシステムリポジトリとの統合を深め、end-to-end automated production を実現する。
- unattended automation 向けに、security defaults と observability を継続的に強化する。

---

## 🤝 Contributing

このリポジトリは OpenClaw のコアアーキテクチャを継承しつつ、個人向け LAB の優先事項を反映しています。

- [`CONTRIBUTING.md`](CONTRIBUTING.md) を読む
- upstream docs: https://docs.openclaw.ai を確認する
- セキュリティ問題は [`SECURITY.md`](SECURITY.md) を参照する

LAB 固有の挙動に確信が持てない場合は、既存挙動を維持し、PR ノートに前提を明記してください。

---

## ❤️ Support / Sponsor

LAB があなたのワークフローに役立っている場合、継続開発の支援をお願いします:

- GitHub Sponsors: https://github.com/sponsors/lachlanchen
- Donate page: https://chat.lazying.art/donate
- Website: https://lazying.art

---

## 🙏 Acknowledgements

LazyingArtBot は **OpenClaw** をベースにしています:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

コアプラットフォームを支える OpenClaw メンテナとコミュニティに感謝します。

---

## 📄 License

MIT（該当箇所は upstream と同一）。`LICENSE` を参照。
