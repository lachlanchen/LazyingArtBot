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

> 🌍 **i18n 상태:** `i18n/` 디렉터리가 존재하며 현재 아랍어, 독일어, 스페인어, 프랑스어, 일본어, 한국어, 러시아어, 베트남어, 중국어 간체, 중국어 번체 README를 포함합니다. 점진적 업데이트의 기준 문서는 이 영어 초안입니다.

**LazyingArtBot**은 **lazying.art**를 위한 제 개인 AI 어시스턴트 스택입니다.  
OpenClaw를 기반으로 하며, 멀티채널 채팅, 로컬 우선 제어, 이메일 -> 캘린더/리마인더/노트 자동화 같은 일상 워크플로우에 맞게 조정되어 있습니다.

| 🔗 링크 | URL | 포커스 |
| --- | --- | --- |
| 🌐 Website | https://lazying.art | 주요 도메인 및 상태 대시보드 |
| 🤖 Bot domain | https://lazying.art | 채팅/어시스턴트 진입점 |
| 🧱 Upstream base | https://github.com/openclaw/openclaw | OpenClaw 플랫폼 기반 |
| 📦 This repo | https://github.com/lachlanchen/LazyingArtBot | LAB 전용 커스터마이징 |

---

## 목차

- [개요](#overview)
- [한눈에 보기](#at-a-glance)
- [기능](#features)
- [핵심 역량](#core-capabilities)
- [프로젝트 구조](#project-structure)
- [사전 요구사항](#prerequisites)
- [빠른 시작](#quick-start)
- [설치](#installation)
- [사용법](#usage)
- [설정](#configuration)
- [배포 모드](#deployment-modes)
- [LazyingArt 워크플로우 포커스](#lazyingart-workflow-focus)
- [Orchestral 철학](#orchestral-philosophy)
- [LAB의 프롬프트 도구](#prompt-tools-in-lab)
- [예시](#examples)
- [개발 노트](#development-notes)
- [문제 해결](#troubleshooting)
- [LAB 생태계 통합](#lab-ecosystem-integrations)
- [소스에서 설치 (빠른 참조)](#install-from-source-quick-reference)
- [로드맵](#roadmap)
- [기여](#contributing)
- [❤️ Support](#-support)
- [감사의 말](#acknowledgements)
- [라이선스](#license)

---

## Overview

LAB는 실용적인 개인 생산성에 집중합니다.

- ✅ 이미 사용하는 채팅 채널 전반에서 하나의 어시스턴트를 실행합니다.
- 🔐 데이터와 제어 권한을 본인 머신/서버에 유지합니다.
- 📬 수신 이메일을 구조화된 액션(캘린더, 리마인더, 노트)으로 변환합니다.
- 🛡️ 자동화가 유용하면서도 안전하도록 가드레일을 둡니다.

요약하면, 단순 반복 업무를 줄이고 실행력을 높이는 데 목적이 있습니다.

---

## At a glance

| 영역 | 이 저장소의 현재 기준 |
| --- | --- |
| 런타임 | Node.js `>=22.12.0` |
| 패키지 매니저 | `pnpm@10.23.0` |
| 핵심 CLI | `openclaw` |
| 기본 로컬 게이트웨이 | `127.0.0.1:18789` |
| 기본 브리지 포트 | `127.0.0.1:18790` |
| 기본 문서 위치 | `docs/` (Mintlify) |
| 주요 LAB 오케스트레이션 | `orchestral/` + `scripts/prompt_tools/` |
| README i18n 위치 | `i18n/README.*.md` |

---

## Features

- 🌐 로컬 게이트웨이를 중심으로 동작하는 멀티채널 어시스턴트 런타임
- 🖥️ 로컬 작업을 제어할 수 있는 브라우저 대시보드/채팅 인터페이스
- 🧰 도구 기반 자동화 파이프라인(스크립트 + 프롬프트 도구)
- 📨 이메일 분류 및 Notes/Reminders/Calendar 액션 전환
- 🧩 채널/프로바이더/통합을 위한 플러그인 생태계(`extensions/*`)
- 📱 저장소 내 멀티플랫폼 인터페이스(`apps/macos`, `apps/ios`, `apps/android`, `ui`)

---

## Core capabilities

| 역량 | 실제 동작 의미 |
| --- | --- |
| 멀티채널 어시스턴트 런타임 | 활성화한 채널 전반에서 gateway + agent session을 운영 |
| 웹 대시보드 / 채팅 | 로컬 작업을 브라우저에서 제어 |
| 도구 기반 워크플로우 | 셸 + 파일 + 자동화 스크립트 실행 체인 |
| 이메일 자동화 파이프라인 | 메일 파싱, 액션 분류, Notes/Reminders/Calendar 라우팅, 리뷰/디버깅용 로그 기록 |

현재 워크플로우의 파이프라인 단계:

- 수신 메일 파싱
- 액션 유형 분류
- Notes/Reminders/Calendar에 저장
- 검토 및 디버깅을 위해 모든 액션 로그를 기록

---

## Project structure

저장소 상위 구조:

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

참고:

- `scripts/prompt_tools`는 orchestral 프롬프트 도구 구현을 가리킵니다.
- 루트 `i18n/` 디렉터리에는 현지화된 README 변형이 있습니다.
- 현재 스냅샷에는 `.github/workflows.disabled/`가 존재하므로, CI 동작 가정 전에 실제 활성 워크플로우를 확인해야 합니다.

---

## Prerequisites

이 저장소의 런타임 및 도구 기준:

- Node.js `>=22.12.0`
- pnpm `10.23.0` 기준 (`packageManager` in `package.json`)
- 구성된 모델 프로바이더 키 (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` 등)
- 선택 사항: 컨테이너형 gateway/CLI를 위한 Docker + Docker Compose
- 선택 사항(모바일/mac 빌드): 대상 플랫폼에 맞는 Apple/Android 툴체인

선택적 전역 CLI 설치(빠른 시작과 동일):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Quick start

이 저장소의 런타임 기준: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

그다음 로컬 대시보드와 채팅을 엽니다:

- http://127.0.0.1:18789

원격 접근이 필요하면, 자체 보안 터널(예: ngrok/Tailscale)로 로컬 gateway를 노출하고 인증을 반드시 유지하세요.

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

`docker-compose.yml`에는 아래 서비스가 포함되어 있습니다:

- `openclaw-gateway`
- `openclaw-cli`

일반적인 흐름:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

자주 필요한 Compose 변수:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Usage

자주 쓰는 명령:

```bash
# 사용자 데몬 온보딩/설치
openclaw onboard --install-daemon

# 게이트웨이를 포그라운드로 실행
openclaw gateway run --bind loopback --port 18789 --verbose

# 설정한 채널로 직접 메시지 전송
openclaw message send --to +1234567890 --message "Hello from LAB"

# 에이전트에게 직접 질의
openclaw agent --message "Create today checklist" --thinking high
```

개발 루프(watch mode):

```bash
pnpm gateway:watch
```

UI 개발:

```bash
pnpm ui:dev
```

추가로 유용한 운영 명령:

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

환경 및 구성 참조는 `.env`와 `~/.openclaw/openclaw.json`로 나뉩니다.

1. `.env.example`에서 시작합니다.
2. gateway 인증을 설정합니다 (`OPENCLAW_GATEWAY_TOKEN` 권장).
3. 모델 프로바이더 키를 최소 하나 설정합니다 (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY` 등).
4. 실제 활성화한 채널의 자격 증명만 설정합니다.

저장소 `.env.example`의 중요 메모:

- Env 우선순위: process env -> `./.env` -> `~/.openclaw/.env` -> config `env` block.
- 이미 값이 있는 process env는 덮어쓰지 않습니다.
- `gateway.auth.token` 같은 config 키는 env fallback보다 우선될 수 있습니다.

인터넷 노출 전 보안 핵심 기준:

- gateway auth/pairing을 활성화 상태로 유지
- 인바운드 채널 allowlist를 엄격하게 유지
- 모든 인바운드 메시지/이메일을 비신뢰 입력으로 처리
- 최소 권한으로 실행하고 로그를 주기적으로 검토

gateway를 인터넷에 노출하는 경우 token/password 인증과 trusted proxy 설정을 필수로 적용하세요.

---

## Deployment modes

| 모드 | 적합한 용도 | 대표 명령 |
| --- | --- | --- |
| Local foreground | 개발 및 디버깅 | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Local daemon | 일상 개인 사용 | `openclaw onboard --install-daemon` |
| Docker | 격리된 런타임과 반복 가능한 배포 | `docker compose up -d` |
| Remote host + tunnel | 홈 LAN 외부 접근 | gateway 실행 + 보안 터널, 인증 유지 |

가정: 프로덕션급 reverse-proxy 하드닝, 시크릿 로테이션, 백업 정책은 배포 환경별로 별도 정의해야 합니다.

---

## LazyingArt workflow focus

이 포크는 **lazying.art**의 개인 운영 흐름에 우선순위를 둡니다:

- 🎨 커스텀 브랜딩 (LAB / panda theme)
- 📱 모바일 친화 대시보드/채팅 경험
- 📨 automail 파이프라인 변형 (rule-triggered, codex-assisted save modes)
- 🧹 개인 정리 및 발신자 분류 스크립트
- 🗂️ 실제 일상 사용에 맞춘 notes/reminders/calendar 라우팅

로컬 자동화 워크스페이스:

- `~/.openclaw/workspace/automation/`
- 저장소 스크립트 참조: `references/lab-scripts-and-philosophy.md`
- 전용 Codex 프롬프트 도구: `scripts/prompt_tools/`

---

## Orchestral philosophy

LAB 오케스트레이션은 하나의 설계 원칙을 따릅니다:  
복잡한 목표를 결정론적 실행 + 집중형 프롬프트 도구 체인으로 분해합니다.

- 결정론적 스크립트는 안정적인 배관을 담당합니다:
  일정, 파일 라우팅, 실행 디렉터리, 재시도, 출력 전달.
- 프롬프트 도구는 적응형 지능을 담당합니다:
  계획 수립, 트리아지, 컨텍스트 합성, 불확실성 하 의사결정.
- 각 단계는 재사용 가능한 아티팩트를 출력하므로, 하위 도구가 처음부터 다시 시작하지 않고 더 강한 최종 노트/이메일을 구성할 수 있습니다.

핵심 orchestral 체인:

- Company entrepreneurship chain:
  company context ingestion -> market/funding/academic/legal intelligence -> concrete growth actions.
- Auto mail chain:
  inbound mail triage -> conservative skip policy for low-value mail -> structured Notes/Reminders/Calendar actions.
- Web search chain:
  results-page capture -> targeted deep reads with screenshot/content extraction -> evidence-backed synthesis.

---

## Prompt tools in LAB

프롬프트 도구는 모듈식이며 조합 가능하고 orchestration-first로 설계되었습니다.  
독립 실행도 가능하고, 더 큰 워크플로우 안에서 연결된 단계로도 실행할 수 있습니다.

- 읽기/저장 작업:
  AutoLife 운영을 위해 Notes, Reminders, Calendar 결과를 생성하고 업데이트합니다.
- 스크린샷/조회 작업:
  검색 결과 페이지와 링크 페이지를 캡처한 뒤, 하위 분석용 구조화 텍스트를 추출합니다.
- 도구 연계 작업:
  결정론적 스크립트를 호출하고, 단계 간 아티팩트를 교환하며 컨텍스트 연속성을 유지합니다.

주요 위치:

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

- 런타임 기준: Node `>=22.12.0`
- 패키지 매니저 기준: `pnpm@10.23.0` (`packageManager` field)
- 일반적인 품질 게이트:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- 개발용 CLI: `pnpm openclaw ...`
- TS 실행 루프: `pnpm dev`
- UI 패키지 명령은 루트 스크립트로 프록시됩니다 (`pnpm ui:build`, `pnpm ui:dev`).

이 저장소의 확장 테스트 명령:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

추가 개발 도우미:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

가정 메모:

- `package.json`에 모바일/macOS 앱 빌드/실행 명령(`ios:*`, `android:*`, `mac:*`)이 존재하지만, 플랫폼 서명/프로비저닝 요구사항은 환경별로 달라 이 README에서 완전히 문서화되어 있지는 않습니다.

---

## Troubleshooting

### Gateway가 `127.0.0.1:18789`에서 접근되지 않을 때

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

포트 충돌과 데몬 충돌을 확인하세요. Docker 사용 시 호스트 포트 매핑과 서비스 상태도 확인하세요.

### Auth 또는 channel 설정 문제

- `.env.example`과 비교해 `.env` 값을 다시 확인하세요.
- 모델 키가 최소 하나 설정되어 있는지 확인하세요.
- 실제 활성화한 채널에 대해서만 채널 토큰을 검증하세요.

### Build 또는 install 문제

- Node `>=22.12.0`에서 `pnpm install`을 다시 실행하세요.
- `pnpm ui:build && pnpm build`로 재빌드하세요.
- 선택적 네이티브 피어가 누락되었다면 `@napi-rs/canvas` / `node-llama-cpp` 호환성 관련 설치 로그를 검토하세요.

### 일반 상태 점검

마이그레이션/보안/설정 드리프트 탐지에는 `openclaw doctor`를 사용하세요.

### 유용한 진단 명령

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB ecosystem integrations

LAB는 제 AI 제품/리서치 저장소를 하나의 운영 레이어로 통합해 제작, 성장, 자동화를 연결합니다.

프로필:

- https://github.com/lachlanchen?tab=repositories

연동 저장소:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (자동 소설 작성)
- `AutoAppDev` (자동 앱 개발)
- `OrganoidAgent` (오가노이드 연구 플랫폼으로, 기초 비전 모델 + LLM 조합)
- `LazyEdit` (AI 보조 영상 편집: 캡션/자막 추출/하이라이트/메타데이터)
- `AutoPublish` (자동 출판 파이프라인)

실무형 LAB 통합 목표:

- 소설 자동 작성
- 앱 자동 개발
- 영상 자동 편집
- 결과물 자동 발행
- 오가노이드 자동 분석
- 이메일 자동 처리

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

이 LAB 포크의 계획 방향(작업 로드맵):

- 더 엄격한 발신자/규칙 분류로 automail 신뢰성 확장
- orchestral 단계 조합성과 아티팩트 추적성 개선
- 모바일 우선 운영과 원격 gateway 관리 UX 강화
- LAB 생태계 저장소와의 통합 심화로 엔드투엔드 자동 생산 강화
- 무인 자동화를 위한 보안 기본값과 observability 지속 강화

---

## Contributing

이 저장소는 OpenClaw 핵심 아키텍처를 계승하면서 개인 LAB 우선순위를 반영합니다.

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) 읽기
- 업스트림 문서 확인: https://docs.openclaw.ai
- 보안 이슈는 [`SECURITY.md`](../SECURITY.md) 참고

LAB 전용 동작이 불확실하면 기존 동작을 유지하고 PR 노트에 가정을 문서화하세요.

---

## Acknowledgements

LazyingArtBot은 **OpenClaw**를 기반으로 합니다:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

핵심 플랫폼을 만들어 준 OpenClaw 유지관리자와 커뮤니티에 감사드립니다.

---

## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

## License

MIT (해당되는 범위에서 업스트림과 동일). `LICENSE`를 참고하세요.
