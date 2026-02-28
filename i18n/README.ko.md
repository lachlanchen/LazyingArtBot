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
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)

> 🌍 **i18n 상태:** `i18n/` 디렉터리가 존재하며 현재 아랍어, 독일어, 스페인어, 프랑스어, 일본어, 한국어, 러시아어, 베트남어, 중국어 간체, 중국어 번체 README가 포함되어 있습니다. 점진적 업데이트의 기준 문서는 이 영어 초안입니다.

**LazyingArtBot**은 **lazying.art**를 위한 제 개인 AI 어시스턴트 스택입니다.

**LazyingArtBot**은 OpenClaw 기반으로, 멀티 채널 채팅, 로컬 우선 제어, 이메일 → 캘린더/리마인더/노트 자동화에 맞게 내 일상 워크플로우로 조정되어 있습니다.

| 🔗 Link | URL | Focus |
| --- | --- | --- |
| 🌐 Website | https://lazying.art | Primary domain and status dashboard |
| 🤖 Bot domain | https://lazying.art | Chat and assistant entrypoint |
| 🧱 Upstream base | https://github.com/openclaw/openclaw | OpenClaw platform foundation |
| 📦 This repo | https://github.com/lachlanchen/LazyingArtBot | LAB-specific adaptations |

---

## Table of contents

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
- [오케스트레이션 철학](#orchestral-philosophy)
- [LAB의 프롬프트 도구](#prompt-tools-in-lab)
- [예시](#examples)
- [개발 노트](#development-notes)
- [문제 해결](#troubleshooting)
- [LAB 생태계 통합](#lab-ecosystem-integrations)
- [소스에서 설치 (빠른 참조)](#install-from-source-quick-reference)
- [로드맵](#roadmap)
- [기여](#contributing)
- [감사의 말](#acknowledgements)
- [❤️ Support](#-support)
- [문의](#contact)
- [라이선스](#license)

---

## Overview

LAB는 실질적인 개인 생산성에 초점을 맞춥니다.

- ✅ 이미 사용하는 채팅 채널 전반에서 단일 어시스턴트를 실행합니다.
- 🔐 데이터와 제어권을 내 머신/서버에 유지합니다.
- 📬 수신 이메일을 구조화된 작업(캘린더, 리마인더, 노트)으로 변환합니다.
- 🛡️ 자동화가 실용적이면서도 안전하게 동작하도록 가드레일을 설정합니다.

한마디로, 반복적 잡무를 줄이고 실행 품질을 높입니다.

---

## At a glance

| 영역 | 이 저장소의 현재 기준 |
| --- | --- |
| 런타임 | Node.js `>=22.12.0` |
| 패키지 매니저 | `pnpm@10.23.0` |
| 핵심 CLI | `openclaw` |
| 기본 로컬 게이트웨이 | `127.0.0.1:18789` |
| 기본 브리지 포트 | `127.0.0.1:18790` |
| 주요 문서 | `docs/` (Mintlify) |
| 주요 LAB 오케스트레이션 | `orchestral/` + `scripts/prompt_tools/` |
| README i18n 위치 | `i18n/README.*.md` |

---

## Features

- 🌐 로컬 게이트웨이를 중심으로 한 멀티 채널 어시스턴트 런타임
- 🖥️ 로컬 운영을 위한 브라우저 대시보드/채팅 화면
- 🧰 도구 기반 자동화 파이프라인(스크립트 + 프롬프트 도구)
- 📨 이메일을 정리하고 Notes, Reminders, Calendar 작업으로 변환
- 🧩 채널/공급자/통합을 위한 플러그인/확장 생태계 (`extensions/*`)
- 📱 저장소 내 멀티 플랫폼 인터페이스(`apps/macos`, `apps/ios`, `apps/android`, `ui`)

---

## Core capabilities

| 역량 | 실제 의미 |
| --- | --- |
| 멀티 채널 어시스턴트 런타임 | 활성화한 채널 전체에서 gateway + agent 세션 운영 |
| 웹 대시보드 / 채팅 | 브라우저 기반 로컬 운영 제어 화면 |
| 도구 기반 워크플로우 | 쉘 + 파일 + 자동화 스크립트 실행 체인 |
| 이메일 자동화 파이프라인 | 메일 파싱, 액션 타입 분류, Notes/Reminders/Calendar 라우팅, 검토/디버깅을 위한 작업 로그 기록 |

현재 워크플로우에서 유지되는 파이프라인 단계:

- 수신 메일 파싱
- 액션 타입 분류
- Notes / Reminders / Calendar에 저장
- 모든 액션 로그를 검토와 디버깅 용도로 저장

---

## Project structure

상위 저장소 구조:

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
- 루트 `i18n/`에는 로컬라이즈된 README 변형이 있습니다.
- `.github/workflows.disabled/`가 스냅샷에 포함되어 있으므로 활성 CI 동작은 사용 전 확인하세요.

---

## Prerequisites

이 저장소 기준 런타임/도구:

- Node.js `>=22.12.0`
- pnpm `10.23.0` 기준 (`package.json`의 `packageManager`)
- 모델 공급자 키 설정 (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` 등)
- 선택: Docker + Docker Compose(컨테이너형 gateway/CLI 사용 시)
- 선택: 모바일/mac 빌드 시 플랫폼별 툴체인(Apple/Android)

빠른 시작 흐름과 같은 선택적 전역 CLI 설치:

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Quick start

이 저장소의 런타임 기준은 **Node >= 22.12.0**입니다 (`package.json`의 engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

그다음 로컬 대시보드와 채팅을 엽니다.

- http://127.0.0.1:18789

원격 접근이 필요하면 보안 터널(예: ngrok/Tailscale)을 통해 로컬 게이트웨이를 노출하고, 인증은 항상 활성화 상태로 유지하세요.

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

`docker-compose.yml`에는 다음이 포함됩니다:

- `openclaw-gateway`
- `openclaw-cli`

일반적인 사용 흐름:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

일반적으로 필요한 Compose 변수:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

## Usage

자주 쓰는 명령:

```bash
# 온보딩 및 사용자 데몬 설치
openclaw onboard --install-daemon

# 게이트웨이를 포그라운드로 실행
openclaw gateway run --bind loopback --port 18789 --verbose

# 설정한 채널로 직접 메시지 전송
openclaw message send --to +1234567890 --message "Hello from LAB"

# 에이전트에게 직접 요청
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

환경 변수와 설정은 `.env`와 `~/.openclaw/openclaw.json`에서 나뉘어 관리됩니다.

1. `.env.example`을 시작점으로 사용합니다.
2. 게이트웨이 인증을 설정합니다 (`OPENCLAW_GATEWAY_TOKEN` 권장).
3. 최소 하나 이상의 모델 키를 설정합니다 (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY` 등).
4. 실제 활성화할 채널의 자격 증명만 입력합니다.

`.env.example`의 핵심 참고사항:

- 환경 변수 우선순위: process env -> `./.env` -> `~/.openclaw/.env` -> config `env` block.
- 기존에 값이 있는 process env는 덮어쓰지 않습니다.
- `gateway.auth.token` 같은 config 키는 env fallback보다 우선할 수 있습니다.

인터넷에 노출하기 전 보안 기본선:

- gateway auth/pairing을 항상 활성화
- 인바운드 채널 allowlist를 엄격하게 유지
- 모든 인바운드 메시지/이메일을 신뢰되지 않은 입력으로 처리
- 최소 권한으로 실행하고 로그를 정기적으로 검토

게이트웨이를 외부에 노출할 경우 token/password 인증 및 신뢰 가능한 proxy 설정을 적용하세요.

---

## Deployment modes

| 모드 | 적합한 사용 | 대표 명령 |
| --- | --- | --- |
| Local foreground | 개발 및 디버깅 | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Local daemon | 일상 개인 사용 | `openclaw onboard --install-daemon` |
| Docker | 격리형 런타임과 반복 가능한 배포 | `docker compose up -d` |
| Remote host + tunnel | 홈 LAN 외부에서 접근 | 게이트웨이 실행 + 보안 터널 사용, 인증 유지 |

가정: 운영 환경별 reverse-proxy 하드닝, 비밀값 회전, 백업 정책은 별도로 정의해야 합니다.

---

## LazyingArt workflow focus

이 포크는 **lazying.art**에서 사용하는 개인 흐름에 맞춰 우선순위를 둡니다.

- 🎨 LAB / panda 테마의 커스텀 브랜딩
- 📱 모바일 친화형 대시보드/채팅 사용성
- 📨 automail 파이프라인 변형(규칙 기반 트리거, codex 보조 저장 모드)
- 🧹 개인 정리 및 발신자 분류 스크립트
- 🗂️ 실무 사용에 맞춘 notes/reminders/calendar 라우팅

로컬 자동화 워크스페이스:

- `~/.openclaw/workspace/automation/`
- 저장소 내 참조: `references/lab-scripts-and-philosophy.md`
- 전용 Codex 프롬프트 도구: `scripts/prompt_tools/`

---

## Orchestral philosophy

LAB 오케스트레이션은 한 가지 설계 원칙을 따릅니다:
복잡한 목표를 결정론적 실행과 집중형 프롬프트 도구 체인으로 분해합니다.

- 결정론적 스크립트가 신뢰성 있는 처리를 담당합니다.
  일정 관리, 파일 라우팅, 실행 디렉터리, 재시도, 출력 전달.
- 프롬프트 도구는 적응형 지능을 담당합니다.
  계획 수립, 트리아지, 맥락 합성, 불확실성 하에서의 의사결정.
- 각 단계에서 재사용 가능한 산출물을 내보내므로 하위 도구가 초기부터 시작하지 않아도 최종 노트/이메일을 더 강하게 조합할 수 있습니다.

핵심 orchestral 체인:

- Company entrepreneurship chain:
  company context ingestion -> market/funding/academic/legal intelligence -> concrete growth actions.
- Auto mail chain:
  inbound mail triage -> conservative skip policy for low-value mail -> structured Notes/Reminders/Calendar actions.
- Web search chain:
  results-page capture -> targeted deep reads with screenshot/content extraction -> evidence-backed synthesis.

---

## Prompt tools in LAB

LAB의 프롬프트 도구는 모듈형이고 조합 가능하며 오케스트레이션 우선으로 설계됩니다.
단독 실행은 물론, 더 큰 워크플로우의 연결 단계로서도 동작합니다.

- 읽기/저장 작업:
  AutoLife 운영을 위한 Notes, Reminders, Calendar 산출물을 생성하고 갱신합니다.
- 스크린샷/조회 작업:
  검색 결과 페이지와 링크 페이지를 캡처한 뒤, 하위 분석을 위한 구조화 텍스트를 추출합니다.
- 도구 연결 작업:
  결정론적 스크립트를 호출하고 단계 간 산출물을 교환하며 맥락 연속성을 유지합니다.

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

- 런타임 기준: Node `>=22.12.0`.
- 패키지 매니저 기준: `pnpm@10.23.0` (`packageManager` 값).
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

이 저장소의 확장 테스트 예시:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

추가 개발 보조 명령:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

가정 메모:

- `package.json`에는 `ios:*`, `android:*`, `mac:*` 같은 모바일/macOS 앱 빌드 명령이 있으나,
  플랫폼 서명/프로비저닝 요건은 환경별이므로 이 README에서 완전히 문서화되지는 않습니다.

---

## Troubleshooting

### Gateway가 `127.0.0.1:18789`에서 보이지 않을 때

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

포트 충돌과 데몬 충돌 여부를 확인하세요. Docker를 쓰는 경우 매핑된 호스트 포트와 서비스 상태를 확인합니다.

### 인증/채널 설정 문제

- `.env` 값을 `.env.example`과 비교해 다시 확인합니다.
- 최소 하나 이상의 모델 키가 설정되어 있는지 확인합니다.
- 실제로 활성화한 채널만 채널 토큰을 설정했는지 점검합니다.

### 빌드 또는 설치 문제

- Node `>=22.12.0` 환경에서 `pnpm install`을 재실행합니다.
- `pnpm ui:build && pnpm build`로 재빌드합니다.
- 선택적 네이티브 peer가 누락된 경우 `@napi-rs/canvas` / `node-llama-cpp` 호환성 로그를 확인하세요.

### 일반 상태 점검

`openclaw doctor`를 사용해 마이그레이션/보안/설정 드리프트를 점검하세요.

### 유용한 진단 명령

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## LAB ecosystem integrations

LAB은 제 AI 제품 및 연구 저장소를 하나의 운영 계층으로 묶어 제작, 성장, 자동화를 연결합니다.

프로필:

- https://github.com/lachlanchen?tab=repositories

통합 저장소:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (자동 소설 작성)
- `AutoAppDev` (자동 앱 개발)
- `OrganoidAgent` (오가노이드 연구 플랫폼, foundation 비전 모델 + LLM 조합)
- `LazyEdit` (AI 기반 동영상 편집: 캡션/전사/하이라이트/메타데이터/자막)
- `AutoPublish` (자동 출판 파이프라인)

실무형 LAB 통합 목표:

- 소설 자동 작성
- 앱 자동 개발
- 동영상 자동 편집
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

이 LAB 포크의 예정 방향(작업 중인 로드맵):

- 발신자/규칙 분류 강화로 automail 안정성 개선
- orchestral 단계 조합성과 산출물 추적성 강화
- 모바일 우선 운영성과 원격 게이트웨이 관리 UX 개선
- LAB 생태계 저장소와 통합을 더 강화해 엔드투엔드 자동화 생산성 확대
- 무인 자동화를 위한 보안 기본값 및 관찰성(observability) 강화 지속

---

## Contributing

이 저장소는 OpenClaw 핵심 아키텍처를 계승하며 개인 LAB 우선순위를 반영합니다.

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) 읽기
- 업스트림 문서 확인: https://docs.openclaw.ai
- 보안 이슈는 [`SECURITY.md`](../SECURITY.md) 참고

LAB 특화 동작이 불명확한 경우 기존 동작을 유지하고, PR 노트에 가정 사항을 문서화하세요.

---

## Acknowledgements

LazyingArtBot은 **OpenClaw**를 기반으로 합니다:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

핵심 플랫폼을 제공한 OpenClaw 유지관리자와 커뮤니티에 감사드립니다.

## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

## Contact

- Website: https://lazying.art
- Repository: https://github.com/lachlanchen/LazyingArtBot
- Issue tracker: https://github.com/lachlanchen/LazyingArtBot/issues
- Security or safety concerns: https://github.com/lachlanchen/LazyingArtBot/blob/main/SECURITY.md

---

## License

MIT (해당되는 범위에서 업스트림과 동일). `LICENSE`를 참고하세요.
