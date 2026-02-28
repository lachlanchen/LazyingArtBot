[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)



<p align="center">
  <img src="https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png" alt="LazyingArtBot banner" />
</p>

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](../LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](../pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#-quick-start)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](../package.json)

**LazyingArtBot**은 **lazying.art**를 위한 저의 개인 AI 어시스턴트 스택입니다.  
OpenClaw를 기반으로 하며, 멀티채널 채팅, 로컬 우선 제어, 이메일 → 캘린더/리마인더/노트 자동화 같은 제 일상 워크플로우에 맞춰 커스터마이징했습니다.

| Link | URL |
| --- | --- |
| Website | https://lazying.art |
| Bot domain | https://lazying.art |
| Upstream base | https://github.com/openclaw/openclaw |
| This repo | https://github.com/lachlanchen/LazyingArtBot |

---

## Table of contents

- [🧭 개요](#-overview)
- [⚡ 한눈에 보기](#-at-a-glance)
- [⚙️ 핵심 기능](#️-core-capabilities)
- [🧱 프로젝트 구조](#-project-structure)
- [📋 사전 요구사항](#-prerequisites)
- [🚀 빠른 시작](#-quick-start)
- [🧱 설치](#-installation)
- [🛠️ 사용법](#️-usage)
- [🔐 설정](#-configuration)
- [🧩 LazyingArt 워크플로우 포커스](#-lazyingart-workflow-focus)
- [🎼 Orchestral 철학](#-orchestral-philosophy)
- [🧰 LAB의 프롬프트 도구](#-prompt-tools-in-lab)
- [💡 예시](#-examples)
- [🧪 개발 노트](#-development-notes)
- [🩺 문제 해결](#-troubleshooting)
- [🌐 LAB 생태계 통합](#-lab-ecosystem-integrations)
- [소스에서 설치](#install-from-source)
- [🗺️ 로드맵](#️-roadmap)
- [🤝 기여](#-contributing)
- [❤️ 지원 / 스폰서](#️-support--sponsor)
- [🙏 감사의 말](#-acknowledgements)
- [📄 라이선스](#-license)

---

## 🧭 Overview

LAB는 실용적인 개인 생산성에 집중합니다.

- 이미 사용 중인 채팅 채널 전반에서 하나의 어시스턴트를 실행합니다.
- 데이터와 제어 권한을 내 머신/서버에 유지합니다.
- 수신 이메일을 구조화된 액션(캘린더, 리마인더, 노트)으로 변환합니다.
- 자동화가 유용하면서도 안전하도록 가드레일을 추가합니다.

한마디로, 잡무는 줄이고 실행력은 높입니다.

---

## ⚡ At a glance

| Area | Current baseline in this repo |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Package manager | `pnpm@10.23.0` |
| Core CLI | `openclaw` |
| Default local gateway | `127.0.0.1:18789` |
| Primary docs | `docs/` (Mintlify) |
| Primary LAB orchestration | `orchestral/` + `scripts/prompt_tools/` |

---

## ⚙️ Core capabilities

- 멀티채널 어시스턴트 런타임(Gateway + agent sessions).
- 웹 대시보드 / 웹 채팅 제어 인터페이스.
- 도구 사용이 가능한 에이전트 워크플로우(셸, 파일, 자동화 스크립트).
- 개인 운영을 위한 이메일 자동화 파이프라인:
  - 수신 메일 파싱
  - 액션 유형 분류
  - Notes / Reminders / Calendar에 저장
  - 리뷰와 디버깅을 위한 모든 액션 로깅

---

## 🧱 Project structure

저장소의 상위 레벨 구조:

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

참고:

- `scripts/prompt_tools`는 orchestral 프롬프트 도구 구현을 가리킵니다.
- 이 스냅샷에서는 루트 `i18n/`이 존재하지만 최소 구성입니다. 현지화 문서는 주로 `docs/` 아래에 있습니다.

---

## 📋 Prerequisites

이 저장소의 런타임 및 툴링 기준:

- Node.js `>=22.12.0`
- pnpm `10.23.0` 기준 (`package.json`의 `packageManager` 참고)
- 설정된 모델 제공자 키 (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` 등)
- 선택 사항: 컨테이너형 gateway/CLI 실행을 위한 Docker + Docker Compose

선택적 전역 CLI 설치(빠른 시작 흐름과 동일):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## 🚀 Quick start

이 저장소의 런타임 기준: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

그다음 로컬 대시보드와 채팅을 엽니다.

- http://127.0.0.1:18789

원격 접근이 필요하면, 자체 보안 터널(예: ngrok/Tailscale)을 통해 로컬 gateway를 노출하고 인증을 반드시 유지하세요.

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

`docker-compose.yml`에는 다음이 포함되어 있습니다.

- `openclaw-gateway`
- `openclaw-cli`

일반적인 흐름:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

참고: 마운트 경로와 포트는 `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACE_DIR`, `OPENCLAW_GATEWAY_PORT`, `OPENCLAW_BRIDGE_PORT` 같은 compose 변수로 제어됩니다.

---

## 🛠️ Usage

자주 쓰는 명령:

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

개발 루프(watch 모드):

```bash
pnpm gateway:watch
```

UI 개발:

```bash
pnpm ui:dev
```

---

## 🔐 Configuration

환경 변수 및 설정 참조는 `.env`와 `~/.openclaw/openclaw.json`으로 나뉩니다.

1. `.env.example`에서 시작합니다.
2. gateway 인증을 설정합니다 (`OPENCLAW_GATEWAY_TOKEN` 권장).
3. 모델 제공자 키를 최소 1개 설정합니다 (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY` 등).
4. 활성화한 채널에 대해서만 채널 자격 증명을 설정합니다.

저장소의 중요한 `.env.example` 메모:

- Env 우선순위: process env → `./.env` → `~/.openclaw/.env` → config `env` block.
- 이미 값이 있는 process env는 덮어쓰지 않습니다.
- `gateway.auth.token` 같은 config 키는 env fallback보다 우선할 수 있습니다.

인터넷 노출 전 보안 핵심 기준:

- gateway auth/pairing을 활성화 상태로 유지합니다.
- 인바운드 채널 allowlist를 엄격하게 유지합니다.
- 모든 수신 메시지/이메일을 신뢰할 수 없는 입력으로 취급합니다.
- 최소 권한으로 실행하고 로그를 정기적으로 검토합니다.

gateway를 인터넷에 노출한다면 token/password 인증과 신뢰 프록시 설정을 필수로 적용하세요.

---

## 🧩 LazyingArt workflow focus

이 포크는 **lazying.art**에서의 제 개인 흐름에 우선순위를 둡니다.

- 커스텀 브랜딩(LAB / 판다 테마)
- 모바일 친화적 대시보드/채팅 경험
- automail 파이프라인 변형(rule-triggered, codex-assisted save modes)
- 개인 정리 및 발신자 분류 스크립트
- 실제 일상 사용에 맞춘 notes/reminders/calendar 라우팅

자동화 워크스페이스(로컬):

- `~/.openclaw/workspace/automation/`
- 저장소 내 스크립트 참조: `references/lab-scripts-and-philosophy.md`
- 전용 Codex 프롬프트 도구: `scripts/prompt_tools/`

---

## 🎼 Orchestral philosophy

LAB 오케스트레이션은 하나의 설계 규칙을 따릅니다.  
어려운 목표를 결정론적 실행 + 집중형 프롬프트 도구 체인으로 분해합니다.

- 결정론적 스크립트는 신뢰성 있는 배관을 담당합니다.
  스케줄링, 파일 라우팅, 실행 디렉터리, 재시도, 출력 핸드오프.
- 프롬프트 도구는 적응형 지능을 담당합니다.
  계획 수립, 트리아지, 컨텍스트 합성, 불확실성 하의 의사결정.
- 각 단계는 재사용 가능한 아티팩트를 생성하므로, 다운스트림 도구가 처음부터 다시 시작하지 않고 더 강한 최종 노트/이메일을 조합할 수 있습니다.

핵심 오케스트럴 체인:

- Company entrepreneurship chain:
  회사 컨텍스트 수집 → 시장/펀딩/학술/법률 인텔리전스 → 구체적 성장 액션.
- Auto mail chain:
  수신 메일 트리아지 → 저가치 메일에 대한 보수적 스킵 정책 → 구조화된 Notes/Reminders/Calendar 액션.
- Web search chain:
  결과 페이지 캡처 → 스크린샷/콘텐츠 추출 기반의 목표형 정밀 읽기 → 근거 기반 합성.

---

## 🧰 Prompt tools in LAB

프롬프트 도구는 모듈식이며, 조합 가능하고, 오케스트레이션 우선으로 설계됩니다.  
독립 실행도 가능하고, 더 큰 워크플로우의 연결된 단계로도 실행할 수 있습니다.

- Read/save operations:
  AutoLife 운영을 위해 Notes, Reminders, Calendar 결과물을 생성하고 업데이트합니다.
- Screenshot/read operations:
  검색 페이지와 링크 페이지를 캡처한 뒤, 다운스트림 분석을 위한 구조화 텍스트를 추출합니다.
- Tool-connection operations:
  결정론적 스크립트를 호출하고, 단계 간 아티팩트를 교환하며, 컨텍스트 연속성을 유지합니다.

주요 위치:

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

- 런타임 기준: Node `>=22.12.0`.
- 패키지 매니저 기준: `pnpm@10.23.0` (`packageManager` 필드).
- 일반적인 품질 게이트:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 개발 환경 CLI: `pnpm openclaw ...`
- TS 실행 루프: `pnpm dev`
- UI 패키지 명령은 루트 스크립트로 프록시됩니다 (`pnpm ui:build`, `pnpm ui:dev`).

---

## 🩺 Troubleshooting

### `127.0.0.1:18789`에서 gateway에 연결되지 않을 때

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

포트 충돌과 데몬 충돌을 확인하세요. Docker를 사용 중이라면 호스트 포트 매핑과 서비스 상태를 점검하세요.

### Auth 또는 channel 설정 문제

- `.env.example`을 기준으로 `.env` 값을 다시 확인하세요.
- 모델 키가 최소 1개 설정되어 있는지 확인하세요.
- 실제로 활성화한 채널에 대해서만 채널 토큰을 검증하세요.

### 일반 상태 점검

마이그레이션/보안/설정 드리프트 문제를 감지하려면 `openclaw doctor`를 사용하세요.

---

## 🌐 LAB ecosystem integrations

LAB는 제 AI 제품/리서치 저장소들을 하나의 운영 레이어로 통합해, 제작, 성장, 자동화를 연결합니다.

Profile:

- https://github.com/lachlanchen?tab=repositories

Integrated repos:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

Practical LAB integration goals:

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

Dev loop:

```bash
pnpm gateway:watch
```

---

## 🗺️ Roadmap

이 LAB 포크의 예정 방향(작업 로드맵):

- 더 엄격한 발신자/규칙 분류로 automail 신뢰성 확장.
- 오케스트럴 단계의 조합 가능성과 아티팩트 추적성 개선.
- 모바일 우선 운영 및 원격 gateway 관리 UX 강화.
- LAB 생태계 저장소와의 통합을 심화해 엔드투엔드 자동 생산 강화.
- 무인 자동화를 위한 보안 기본값과 관측 가능성(Observability) 지속 강화.

---

## 🤝 Contributing

이 저장소는 OpenClaw의 핵심 아키텍처를 계승하면서, 개인 LAB 우선순위를 반영합니다.

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) 읽기
- 업스트림 문서 확인: https://docs.openclaw.ai
- 보안 이슈는 [`SECURITY.md`](../SECURITY.md) 참고

LAB 전용 동작이 불확실하다면 기존 동작을 보존하고 PR 노트에 가정을 문서화하세요.

---

## ❤️ Support / Sponsor

LAB가 워크플로우에 도움이 된다면, 지속적인 개발을 후원해 주세요.

- GitHub Sponsors: https://github.com/sponsors/lachlanchen
- Donate page: https://chat.lazying.art/donate
- Website: https://lazying.art

---

## 🙏 Acknowledgements

LazyingArtBot은 **OpenClaw**를 기반으로 합니다.

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

핵심 플랫폼을 만들어 준 OpenClaw 유지관리자와 커뮤니티에 감사드립니다.

---

## 📄 License

MIT (해당되는 범위에서 업스트림과 동일). `LICENSE`를 참고하세요.
