[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)


[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#quick-start)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](docs)

> 🌍 **Trạng thái i18n:** `i18n/` hiện có và đang bao gồm các file README đã bản địa hóa bằng tiếng Ả Rập, tiếng Đức, tiếng Tây Ban Nha, tiếng Pháp, tiếng Nhật, tiếng Hàn, tiếng Việt, tiếng Trung giản thể và tiếng Trung phồn thể. Bản thảo tiếng Anh này vẫn là nguồn chính thống cho các cập nhật dần dần.

**LazyingArtBot** là bộ công cụ trợ lý AI cá nhân của tôi cho **lazying.art**.
Nó được xây dựng trên OpenClaw và được điều chỉnh cho quy trình làm việc hằng ngày của riêng tôi: chat đa kênh, kiểm soát local-first và tự động hóa email -> calendar/reminder/notes.

| 🔗 Liên kết | URL |
| --- | --- |
| 🌐 Website | https://lazying.art |
| 🤖 Miền bot | https://lazying.art |
| 🧱 Nguồn gốc nền tảng | https://github.com/openclaw/openclaw |
| 📦 Repo này | https://github.com/lachlanchen/LazyingArtBot |

---

## Mục lục

- [Tổng quan](#overview)
- [Tóm tắt nhanh](#at-a-glance)
- [Tính năng](#features)
- [Khả năng cốt lõi](#core-capabilities)
- [Cấu trúc dự án](#project-structure)
- [Điều kiện tiên quyết](#prerequisites)
- [Bắt đầu nhanh](#quick-start)
- [Cài đặt](#installation)
- [Sử dụng](#usage)
- [Cấu hình](#configuration)
- [Chế độ triển khai](#deployment-modes)
- [Tập trung quy trình LazyingArt](#lazyingart-workflow-focus)
- [Triết lý orchestral](#orchestral-philosophy)
- [Prompt tools trong LAB](#prompt-tools-in-lab)
- [Ví dụ](#examples)
- [Ghi chú phát triển](#development-notes)
- [Khắc phục sự cố](#troubleshooting)
- [Tích hợp hệ sinh thái LAB](#lab-ecosystem-integrations)
- [Cài đặt từ source (tham chiếu nhanh)](#install-from-source-quick-reference)
- [Lộ trình](#roadmap)
- [Đóng góp](#contributing)
- [❤️ Support](#-support)
- [Lời cảm ơn](#acknowledgements)
- [Giấy phép](#license)

---

<a id="overview"></a>
## Tổng quan

LAB tập trung vào hiệu suất công việc cá nhân theo hướng thực dụng:

- ✅ Chạy một trợ lý trên các kênh chat bạn đã sử dụng.
- 🔐 Giữ dữ liệu và quyền kiểm soát trên máy/chủ riêng của bạn.
- 📬 Chuyển email đến thành các hành động có cấu trúc (Calendar, Reminders, Notes).
- 🛡️ Thêm các rào cản an toàn để tự động hóa vẫn hữu ích nhưng vẫn an toàn.

Nói ngắn gọn: ít việc vặt hơn, thực thi tốt hơn.

---

<a id="at-a-glance"></a>
## Tóm tắt nhanh

| Khu vực | Trạng thái cơ sở hiện tại trong repo này |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Package manager | `pnpm@10.23.0` |
| Core CLI | `openclaw` |
| Gateway local mặc định | `127.0.0.1:18789` |
| Cổng bridge mặc định | `127.0.0.1:18790` |
| Tài liệu chính | `docs/` (Mintlify) |
| Điều phối LAB chính | `orchestral/` + `scripts/prompt_tools/` |
| Vị trí README i18n | `i18n/README.*.md` |

---

<a id="features"></a>
## Tính năng

- 🌐 Runtime trợ lý đa kênh với local gateway.
- 🖥️ Bề mặt dashboard/chat trên trình duyệt cho vận hành local.
- 🧰 Quy trình tự động hóa có công cụ hỗ trợ (scripts + prompt-tools).
- 📨 Phân loại email và chuyển thành hành động Notes, Reminders, Calendar.
- 🧩 Hệ sinh thái plugin/extension (`extensions/*`) cho các kênh/provider/integration.
- 📱 Nhiều bề mặt đa nền tảng trong repo (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

<a id="core-capabilities"></a>
## Khả năng cốt lõi

| Khả năng | Ý nghĩa thực tế |
| --- | --- |
| Runtime trợ lý đa kênh | Gateway + phiên làm việc agent trên các kênh bạn bật |
| Dashboard/chat web | Bề mặt điều khiển dựa trên trình duyệt cho các thao tác local |
| Quy trình dựa trên công cụ | Chuỗi thực thi shell + file + script tự động hóa |
| Pipeline tự động hóa email | Phân tích mail, phân loại loại hành động, chuyển sang Notes/Reminders/Calendar, ghi log mọi hành động để xem xét/gỡ lỗi |

Các bước pipeline giữ nguyên từ workflow hiện tại:

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

<a id="project-structure"></a>
## Cấu trúc dự án

Bố cục cấp cao của repository:

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

Ghi chú:

- `scripts/prompt_tools` trỏ đến phần triển khai prompt-tool của orchestral.
- Thư mục gốc `i18n/` chứa các biến thể README đã bản địa hóa.
- `.github/workflows.disabled/` có trong snapshot này; hành vi CI đang hoạt động cần được xác minh trước khi phụ thuộc vào giả định về workflow.

---

<a id="prerequisites"></a>
## Điều kiện tiên quyết

Các nền tảng runtime và công cụ từ repo này:

- Node.js `>=22.12.0`
- pnpm `10.23.0` baseline (xem `packageManager` trong `package.json`)
- Một khóa provider mô hình đã được cấu hình (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, ...)
- Tùy chọn: Docker + Docker Compose cho gateway/CLI chạy container
- Tùy chọn cho build mobile/mac: Apple/Android toolchains tùy theo nền tảng mục tiêu

Cài đặt global CLI tùy chọn (phù hợp với luồng quick-start):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

<a id="quick-start"></a>
## Bắt đầu nhanh

Nền tảng runtime trong repo này: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Sau đó mở dashboard local và chat:

- http://127.0.0.1:18789

Đối với truy cập từ xa, hãy expose local gateway qua secure tunnel riêng (ví dụ ngrok/Tailscale) và giữ xác thực bật.

---

<a id="installation"></a>
## Cài đặt

### Cài đặt từ source

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Workflow Docker tùy chọn

Repository có sẵn `docker-compose.yml` với:

- `openclaw-gateway`
- `openclaw-cli`

Luồng điển hình:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Các biến compose thường cần:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

<a id="usage"></a>
## Sử dụng

Các lệnh thường dùng:

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

Dev loop (watch mode):

```bash
pnpm gateway:watch
```

Phát triển UI:

```bash
pnpm ui:dev
```

Các lệnh vận hành hữu ích khác:

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --all
openclaw status --deep
openclaw health
openclaw doctor
```

---

<a id="configuration"></a>
## Cấu hình

Tham chiếu environment và config được chia giữa `.env` và `~/.openclaw/openclaw.json`.

1. Bắt đầu từ `.env.example`.
2. Đặt auth gateway (`OPENCLAW_GATEWAY_TOKEN` recommended).
3. Đặt ít nhất một khóa model provider (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, ...).
4. Chỉ đặt thông tin xác thực kênh cho các kênh bạn bật.

Lưu ý từ `.env.example` của repo cần giữ nguyên:

- Thứ tự ưu tiên env: process env -> `./.env` -> `~/.openclaw/.env` -> block config `env`.
- Các giá trị process env hiện có mà không rỗng không bị ghi đè.
- Các khóa cấu hình như `gateway.auth.token` có thể ưu tiên hơn fallback env.

Các yêu cầu an toàn trước khi mở rộng ra internet:

- Giữ gateway auth/pairing bật.
- Giữ allowlists chặt chẽ cho các kênh inbound.
- Xử lý mọi tin nhắn/email inbound như dữ liệu đầu vào chưa tin cậy.
- Chạy với nguyên tắc least privilege và kiểm tra log thường xuyên.

Nếu expose gateway ra internet, bắt buộc token/password auth và cấu hình trusted proxy.

---

<a id="deployment-modes"></a>
## Chế độ triển khai

| Chế độ | Phù hợp cho | Lệnh điển hình |
| --- | --- | --- |
| Chạy foreground local | Development và debugging | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Daemon local | Sử dụng cá nhân hằng ngày | `openclaw onboard --install-daemon` |
| Docker | Runtime cô lập và triển khai lặp lại | `docker compose up -d` |
| Remote host + tunnel | Truy cập từ bên ngoài LAN | Chạy gateway + secure tunnel, giữ auth bật |

Giả định: việc hardening reverse-proxy cấp production, quay vòng secret và chính sách backup phụ thuộc theo môi trường.

---

<a id="lazyingart-workflow-focus"></a>
## Tập trung quy trình LazyingArt

Fork này ưu tiên quy trình cá nhân của tôi trên **lazying.art**:

- 🎨 branding tùy chỉnh (chủ đề LAB / panda)
- 📱 trải nghiệm dashboard/chat thân thiện trên mobile
- 📨 các biến thể automail (các chế độ lưu theo rule-driven, chế độ hỗ trợ bởi codex)
- 🧹 script dọn dẹp cá nhân và phân loại sender
- 🗂️ định tuyến notes/reminders/calendar đã tinh chỉnh cho dùng hằng ngày thực tế

Không gian làm việc tự động hóa (local):

- `~/.openclaw/workspace/automation/`
- Tham chiếu script trong repo: `references/lab-scripts-and-philosophy.md`
- Prompt tool dành riêng cho Codex: `scripts/prompt_tools/`

---

<a id="orchestral-philosophy"></a>
## Triết lý orchestral

Phương pháp thiết kế điều phối LAB tuân theo một nguyên tắc:
chia các mục tiêu phức tạp thành thực thi deterministic + chuỗi prompt-tool tập trung.

- Các script deterministic xử lý phần plumbing đáng tin cậy:
  lập lịch, định tuyến file, run directories, retries, và bàn giao output.
- Prompt tools xử lý trí tuệ thích ứng:
  lập kế hoạch, triage, tổng hợp bối cảnh, và ra quyết định khi không chắc chắn.
- Mỗi giai đoạn tạo ra artifacts tái sử dụng để các công cụ hạ nguồn có thể phối hợp thành note/email đầu ra mạnh hơn mà không cần bắt đầu từ con số 0.

Chuỗi orchestral chính:

- Công ty khởi nghiệp chain:
  nạp ngữ cảnh công ty -> intelligence thị trường/đầu tư/học thuật/pháp lý -> hành động tăng trưởng cụ thể.
- Auto mail chain:
  triage email tới -> chính sách skip thận trọng cho mail giá trị thấp -> hành động có cấu trúc Notes/Reminders/Calendar.
- Web search chain:
  capture trang kết quả -> đọc sâu có mục tiêu với screenshot/content extraction -> tổng hợp có bằng chứng.

---

<a id="prompt-tools-in-lab"></a>
## Prompt tools trong LAB

Prompt tools là dạng mô-đun, có tính kết hợp, ưu tiên orchestration.
Chúng có thể chạy độc lập hoặc là các giai đoạn liên kết trong workflow lớn hơn.

- Thao tác đọc/lưu:
  tạo và cập nhật Notes, Reminders và Calendar cho các thao tác AutoLife.
- Thao tác screenshot/read:
  capture trang search và các trang liên kết, rồi trích xuất văn bản có cấu trúc cho phân tích downstream.
- Thao tác tool-connection:
  gọi scripts deterministic, trao đổi artifacts giữa các giai đoạn, và duy trì tính liên tục context.

Vị trí chính:

- `scripts/prompt_tools/`

---

<a id="examples"></a>
## Ví dụ

### Ví dụ: local-only gateway

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Ví dụ: yêu cầu agent xử lý kế hoạch hàng ngày

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Ví dụ: build source + watch loop

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

### Ví dụ: chạy bằng Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

<a id="development-notes"></a>
## Ghi chú phát triển

- Runtime baseline: Node `>=22.12.0`.
- Package manager baseline: `pnpm@10.23.0` (`packageManager` field).
- Các cổng chất lượng phổ biến:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI trong dev: `pnpm openclaw ...`
- TS run loop: `pnpm dev`
- Lệnh package UI được proxy qua root scripts (`pnpm ui:build`, `pnpm ui:dev`).

Các lệnh test mở rộng trong repo:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Các helper phát triển bổ sung:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Ghi chú giả định:

- Các lệnh build/run mobile/macOS nằm trong `package.json` (`ios:*`, `android:*`, `mac:*`) nhưng yêu cầu ký tên/nền tảng ký code phụ thuộc môi trường và chưa được mô tả đầy đủ trong README này.

---

<a id="troubleshooting"></a>
## Khắc phục sự cố

### Gateway không truy cập được trên `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Kiểm tra xung đột cổng và xung đột daemon. Nếu dùng Docker, xác minh cổng host đã map và trạng thái health của service.

### Vấn đề xác thực hoặc cấu hình kênh

- Kiểm tra lại giá trị `.env` với `.env.example`.
- Đảm bảo có ít nhất một model key đã cấu hình.
- Kiểm tra token kênh chỉ cho các kênh bạn đã bật thật sự.

### Vấn đề build hoặc cài đặt

- Chạy lại `pnpm install` với Node `>=22.12.0`.
- Build lại với `pnpm ui:build && pnpm build`.
- Nếu thiếu native peer optional, kiểm tra logs cài đặt để xem tương thích `@napi-rs/canvas` / `node-llama-cpp`.

### Kiểm tra health tổng quát

Dùng `openclaw doctor` để phát hiện vấn đề migration/security/config drift.

### Các chẩn đoán hữu ích

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

<a id="lab-ecosystem-integrations"></a>
## Tích hợp hệ sinh thái LAB

LAB tích hợp các repo AI sản phẩm và nghiên cứu rộng hơn của tôi vào một lớp vận hành chung cho tạo nội dung, tăng trưởng và automation.

Hồ sơ:

- https://github.com/lachlanchen?tab=repositories

Các repo tích hợp:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (nền tảng nghiên cứu organoid với foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

Mục tiêu tích hợp LAB thực tế:

- Tự động viết tiểu thuyết
- Tự động phát triển ứng dụng
- Tự động chỉnh sửa video
- Tự động xuất bản kết quả
- Tự động phân tích organoids
- Tự động xử lý email

---

<a id="install-from-source-quick-reference"></a>
## Cài đặt từ source (tham chiếu nhanh)

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

<a id="roadmap"></a>
## Lộ trình

Hướng phát triển kế hoạch cho nhánh LAB này (roadmap đang làm việc):

- Mở rộng độ tin cậy của automail với phân loại sender/rule nghiêm ngặt hơn.
- Cải thiện khả năng compose lại orchestral stages và tính truy xuất artifact.
- Tăng cường vận hành mobile-first và UX quản lý gateway từ xa.
- Thấm nhuần hơn các tích hợp với repo trong hệ sinh thái LAB cho sản xuất tự động đầu-cuối.
- Tiếp tục siết chặt mặc định bảo mật và observability cho automation không giám sát.

---

<a id="contributing"></a>
## Đóng góp

Repo này theo dõi các ưu tiên LAB cá nhân trong khi kế thừa kiến trúc lõi từ OpenClaw.

- Đọc [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Xem tài liệu upstream: https://docs.openclaw.ai
- Với vấn đề bảo mật, xem [`SECURITY.md`](SECURITY.md)

Nếu chưa chắc về hành vi đặc thù LAB, hãy giữ nguyên hành vi hiện có và ghi lại giả định trong ghi chú PR.

<a id="-support"></a>
## ❤️ Support

| Donate | PayPal | Stripe |
|---|---|---|
| [![Donate](https://img.shields.io/badge/Donate-LazyingArt-0EA5E9?style=for-the-badge&logo=ko-fi&logoColor=white)](https://chat.lazying.art/donate) | [![PayPal](https://img.shields.io/badge/PayPal-RongzhouChen-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/RongzhouChen) | [![Stripe](https://img.shields.io/badge/Stripe-Donate-635BFF?style=for-the-badge&logo=stripe&logoColor=white)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |

---

<a id="acknowledgements"></a>
## Lời cảm ơn

LazyingArtBot dựa trên **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Cảm ơn các maintainer OpenClaw và cộng đồng vì nền tảng lõi.

<a id="license"></a>
## Giấy phép

MIT (giống upstream khi áp dụng). Xem `LICENSE`.
