[English](../README.md) · [العربية](README.ar.md) · [Español](README.es.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Tiếng Việt](README.vi.md) · [中文 (简体)](README.zh-Hans.md) · [中文（繁體）](README.zh-Hant.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)



[![LazyingArt banner](https://github.com/lachlanchen/lachlanchen/raw/main/figs/banner.png)](https://github.com/lachlanchen/lachlanchen/blob/main/figs/banner.png)

# 🐼 LazyingArtBot (LAB)

[![License: MIT](https://img.shields.io/badge/License-MIT-1f6feb.svg)](../LICENSE)
[![Node >= 22.12.0](https://img.shields.io/badge/Node-%3E%3D22.12.0-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![pnpm workspace](https://img.shields.io/badge/pnpm-workspace-F69220?logo=pnpm&logoColor=white)](../pnpm-workspace.yaml)
[![Upstream: openclaw/openclaw](https://img.shields.io/badge/upstream-openclaw%2Fopenclaw-111827?logo=github)](https://github.com/openclaw/openclaw)
[![Gateway Default Port](https://img.shields.io/badge/Gateway-18789-0ea5e9)](#bắt-đầu-nhanh)
[![Version](https://img.shields.io/badge/version-2026.2.10-16a34a)](../package.json)
[![i18n README](https://img.shields.io/badge/i18n-10_languages-8b5cf6)](../i18n)
[![Docs](https://img.shields.io/badge/docs-Mintlify-06b6d4)](../docs)
[![GitHub stars](https://img.shields.io/badge/GitHub-stars-0ea5e9?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/stargazers)
[![GitHub issues](https://img.shields.io/badge/GitHub-issues-ef4444?logo=github&logoColor=white)](https://github.com/lachlanchen/LazyingArtBot/issues)

> 🌍 **Trạng thái i18n:** `i18n/` hiện có và đang bao gồm các file README đã bản địa hóa cho tiếng Ả Rập, tiếng Đức, tiếng Tây Ban Nha, tiếng Pháp, tiếng Nhật, tiếng Hàn, tiếng Nga, tiếng Việt, tiếng Trung giản thể và tiếng Trung phồn thể. Bản thảo tiếng Anh này vẫn là nguồn chính thống cho các cập nhật dần dần.

**LazyingArtBot** là bộ công cụ trợ lý AI cá nhân của tôi cho **lazying.art**:

**LazyingArtBot** được xây dựng trên nền tảng OpenClaw và được tùy chỉnh cho quy trình làm việc hằng ngày của tôi: chat đa kênh, điều khiển local-first và tự động hóa email -> lịch nhắc/chú ý/ghi chú.

| 🔗 Liên kết | URL | Mục tiêu |
| --- | --- | --- |
| 🌐 Website | https://lazying.art | Miền chính và bảng điều khiển trạng thái |
| 🤖 Miền bot | https://lazying.art | Điểm vào chat và trợ lý |
| 🧱 Nền tảng gốc | https://github.com/openclaw/openclaw | Nền tảng lõi của OpenClaw |
| 📦 Repo này | https://github.com/lachlanchen/LazyingArtBot | Biến thể tùy chỉnh dành cho LAB |

---

## Mục lục

- [Tổng quan](#tổng-quan)
- [Nhìn tổng quát](#nhìn-tổng-quát)
- [Tính năng](#tính-năng)
- [Khả năng cốt lõi](#khả-năng-cốt-lõi)
- [Cấu trúc dự án](#cấu-trúc-dự-án)
- [Điều kiện tiên quyết](#điều-kiện-tiên-quyết)
- [Bắt đầu nhanh](#bắt-đầu-nhanh)
- [Cài đặt](#cài-đặt)
- [Sử dụng](#sử-dụng)
- [Cấu hình](#cấu-hình)
- [Chế độ triển khai](#chế-độ-triển-khai)
- [Là trọng tâm quy trình của LazyingArt](#là-trọng-tâm-quy-trình-của-lazyingart)
- [Triết lý orchestral](#triết-lý-orchestral)
- [Prompt tools trong LAB](#prompt-tools-trong-lab)
- [Ví dụ](#ví-dụ)
- [Ghi chú phát triển](#ghi-chú-phát-triển)
- [Khắc phục sự cố](#khắc-phục-sự-cố)
- [Tích hợp hệ sinh thái LAB](#tích-hợp-hệ-sinh-thái-lab)
- [Cài đặt từ source (tham chiếu nhanh)](#cài-đặt-từ-source-tham-chiếu-nhanh)
- [Lộ trình](#lộ-trình)
- [Đóng góp](#đóng-góp)
- [❤️ Support](#-support)
- [Lời cảm ơn](#lời-cảm-ơn)
- [Giấy phép](#giấy-phép)

---

## Tổng quan

LAB tập trung vào năng suất cá nhân theo hướng thực tế:

- ✅ Chạy một trợ lý trên các kênh chat mà bạn đã dùng.
- 🔐 Giữ dữ liệu và quyền kiểm soát trên máy/chủ của riêng bạn.
- 📬 Chuyển email đến thành các hành động có cấu trúc (Calendar, Reminders, Notes).
- 🛡️ Bố trí guardrails để tự động hóa vẫn hữu ích nhưng vẫn an toàn.

Nói ngắn gọn: giảm việc vặt, tăng hiệu quả thực thi.

---

## Nhìn tổng quát

| Khu vực | Mức cơ sở hiện tại trong repo này |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Quản lý gói | `pnpm@10.23.0` |
| Core CLI | `openclaw` |
| Gateway local mặc định | `127.0.0.1:18789` |
| Cổng bridge mặc định | `127.0.0.1:18790` |
| Tài liệu chính | `docs/` (Mintlify) |
| Orchestration chính của LAB | `orchestral/` + `scripts/prompt_tools/` |
| Vị trí README đa ngôn ngữ | `i18n/README.*.md` |

---

## Tính năng

- 🌐 Runtime trợ lý đa kênh với local gateway.
- 🖥️ Giao diện dashboard/chat trên trình duyệt cho vận hành local.
- 🧰 Chuỗi tự động hóa có hỗ trợ công cụ (scripts + prompt-tools).
- 📨 Phân loại email và chuyển thành các action Notes, Reminders, Calendar.
- 🧩 Hệ sinh thái plugin/extension (`extensions/*`) cho kênh/provider/tích hợp.
- 📱 Nhiều giao diện nền tảng trong repository (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Khả năng cốt lõi

| Khả năng | Ý nghĩa trong thực tế |
| --- | --- |
| Runtime trợ lý đa kênh | Gateway + phiên làm việc agent trên các kênh bạn kích hoạt |
| Dashboard/chat web | Bề mặt điều khiển trên trình duyệt cho vận hành local |
| Quy trình dựa trên công cụ | Chuỗi thực thi shell + file + script tự động hóa |
| Pipeline tự động hóa email | Phân tích email, phân loại loại action, chuyển vào Notes/Reminders/Calendar, ghi lại mọi action để rà soát/gỡ lỗi |

Các bước pipeline được giữ theo workflow hiện tại:

- parse inbound mail
- classify action type
- save to Notes / Reminders / Calendar
- log every action for review and debugging

---

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
├─ README_OPENCLAW.md   # upstream-style reference README
└─ README.md            # this LAB-focused README
```

Ghi chú:

- `scripts/prompt_tools` trỏ đến phần triển khai prompt-tool của orchestral.
- Root `i18n/` chứa các biến thể README bản địa hóa.
- `.github/workflows.disabled/` có trong snapshot này; hành vi CI đang hoạt động nên cần xác minh trước khi dựa vào giả định về workflow.

---

## Điều kiện tiên quyết

Runtime và tooling baseline của repository:

- Node.js `>=22.12.0`
- pnpm `10.23.0` baseline (xem `packageManager` trong `package.json`)
- Một khóa provider mô hình đã được cấu hình (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, ...)
- Tùy chọn: Docker + Docker Compose cho gateway/CLI container hóa
- Tùy chọn cho build mobile/mac: Apple/Android toolchains tùy nền tảng mục tiêu

Cài đặt global CLI tùy chọn (phù hợp luồng quick-start):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Bắt đầu nhanh

Runtime baseline trong repository này: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Sau đó mở dashboard local và chat:

- http://127.0.0.1:18789

Đối với truy cập từ xa, expose local gateway của bạn qua secure tunnel riêng (ví dụ ngrok/Tailscale) và giữ xác thực đã bật.

---

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

Repository có `docker-compose.yml` kèm theo:

- `openclaw-gateway`
- `openclaw-cli`

Luồng điển hình:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Các biến compose thường cần thiết:

- `OPENCLAW_CONFIG_DIR`
- `OPENCLAW_WORKSPACE_DIR`
- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

---

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

UI development:

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

## Cấu hình

Tham chiếu môi trường và cấu hình được chia giữa `.env` và `~/.openclaw/openclaw.json`.

1. Bắt đầu từ `.env.example`.
2. Cấu hình auth gateway (`OPENCLAW_GATEWAY_TOKEN` được khuyến nghị).
3. Cấu hình ít nhất một khóa model provider (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, ...).
4. Chỉ cấu hình credentials cho các kênh bạn đang bật.

Lưu ý quan trọng của `.env.example` trong repo:

- Thứ tự ưu tiên env: process env -> `./.env` -> `~/.openclaw/.env` -> block config `env`.
- Các giá trị process env không rỗng hiện có không bị ghi đè.
- Các khóa config như `gateway.auth.token` có thể có ưu tiên cao hơn env fallback.

Nền tảng an toàn bắt buộc trước khi phơi lên internet:

- Giữ gateway auth/pairing bật.
- Giữ allowlists nghiêm ngặt cho inbound channels.
- Đối xử mọi tin nhắn/email đến như dữ liệu chưa tin cậy.
- Chạy với nguyên tắc quyền hạn tối thiểu và kiểm tra logs định kỳ.

Nếu expose gateway ra internet, bắt buộc xác thực token/password và cấu hình trusted proxy.

---

## Chế độ triển khai

| Chế độ | Phù hợp với | Lệnh điển hình |
| --- | --- | --- |
| Foreground local | Development và debug | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Daemon local | Sử dụng cá nhân hằng ngày | `openclaw onboard --install-daemon` |
| Docker | Runtime cách ly và triển khai lặp lại | `docker compose up -d` |
| Remote host + tunnel | Truy cập từ ngoài LAN nhà | Chạy gateway + tunnel bảo mật, giữ auth bật |

Giả định: hardening reverse-proxy đạt chuẩn production, xoay vòng secret, và chính sách backup là vấn đề riêng theo môi trường.

---

## Là trọng tâm quy trình của LazyingArt

Fork này ưu tiên luồng cá nhân của tôi tại **lazying.art**:

- 🎨 Branding tùy chỉnh (chủ đề LAB / panda)
- 📱 Trải nghiệm dashboard/chat thân thiện mobile
- 📨 Biến thể automail (chế độ lưu theo rule-driven, chế độ có trợ giúp từ codex)
- 🧹 Script dọn dẹp và phân loại sender cá nhân
- 🗂️ Routing notes/reminders/calendar đã tối ưu cho sử dụng hằng ngày thực tế

Không gian làm việc tự động hóa (local):

- `~/.openclaw/workspace/automation/`
- Tham chiếu script trong repo: `references/lab-scripts-and-philosophy.md`
- Prompt tools dành riêng cho Codex: `scripts/prompt_tools/`

---

## Triết lý orchestral

Orchestration của LAB theo một nguyên tắc thiết kế:
chia mục tiêu phức tạp thành thực thi deterministic + chuỗi prompt-tool có trọng tâm.

- Scripts deterministic đảm nhận các phần plumbing đáng tin cậy:
  lập lịch, định tuyến file, run directories, retries, và bàn giao output.
- Prompt tools xử lý trí tuệ thích ứng:
  lập kế hoạch, triage, tổng hợp ngữ cảnh, và ra quyết định khi có bất định.
- Mỗi giai đoạn tạo artifact có thể tái sử dụng để công cụ hạ nguồn có thể gắn kết các note/email cuối cùng mạnh hơn mà không cần bắt đầu lại từ đầu.

Core orchestration chains:

- Chuỗi khởi nghiệp doanh nghiệp:
  ingest ngữ cảnh công ty -> intelligence thị trường/tài trợ/học thuật/pháp lý -> action tăng trưởng cụ thể.
- Chuỗi auto mail:
  triage email vào -> chính sách skip thận trọng cho email thấp giá trị -> action Notes/Reminders/Calendar có cấu trúc.
- Chuỗi web search:
  capture trang kết quả -> đọc sâu có mục tiêu kèm screenshot/content extraction -> tổng hợp có cơ sở bằng chứng.

---

## Prompt tools trong LAB

Prompt tools là mô-đun, có thể ghép nối, và orchestration-first.
Chúng có thể chạy độc lập hoặc là các giai đoạn liên kết trong workflow lớn hơn.

- Read/save operations:
  tạo và cập nhật Notes, Reminders, và Calendar cho thao tác AutoLife.
- Screenshot/read operations:
  capture trang tìm kiếm và trang liên kết, sau đó trích xuất text có cấu trúc cho phân tích tiếp theo.
- Tool-connection operations:
  gọi deterministic scripts, trao đổi artifact giữa các giai đoạn, và duy trì context continuity.

Vị trí chính:

- `scripts/prompt_tools/`

---

## Ví dụ

### Ví dụ: local-only gateway

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Ví dụ: yêu cầu agent xử lý lập kế hoạch hàng ngày

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

### Ví dụ: chạy trong Docker

```bash
cp .env.example .env
docker compose up -d
docker compose logs -f openclaw-gateway
```

---

## Ghi chú phát triển

- Baseline runtime: Node `>=22.12.0`.
- Baseline package manager: `pnpm@10.23.0` (`packageManager` field).
- Bộ cổng chất lượng thường dùng:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI trong dev: `pnpm openclaw ...`
- TS run loop: `pnpm dev`
- Lệnh UI package được proxy qua root scripts (`pnpm ui:build`, `pnpm ui:dev`).

Lệnh kiểm thử mở rộng trong repo:

```bash
pnpm test:e2e
pnpm test:live
pnpm test:docker:all
pnpm test:ui
```

Các helper phát triển thêm:

```bash
pnpm docs:dev
pnpm format:check
pnpm lint
pnpm tsgo:test
```

Ghi chú giả định:

- Build/run app mobile/macOS có trong `package.json` (`ios:*`, `android:*`, `mac:*`) nhưng yêu cầu ký số/cấp phép nền tảng phụ thuộc môi trường và chưa được ghi đầy đủ trong README này.

---

## Khắc phục sự cố

### Gateway không thể truy cập tại `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Kiểm tra va chạm cổng và xung đột daemon. Nếu dùng Docker, xác minh cổng host đã map và service health.

### Vấn đề xác thực hoặc cấu hình channel

- Kiểm tra lại các giá trị `.env` so với `.env.example`.
- Đảm bảo ít nhất một model key đã được cấu hình.
- Xác thực token channel chỉ cho các channel bạn thực sự bật.

### Vấn đề build hoặc cài đặt

- Chạy lại `pnpm install` với Node `>=22.12.0`.
- Build lại với `pnpm ui:build && pnpm build`.
- Nếu thiếu native peer tuỳ chọn, xem log cài đặt về tương thích của `@napi-rs/canvas` / `node-llama-cpp`.

### Kiểm tra health tổng quát

Dùng `openclaw doctor` để phát hiện drift migration/security/config.

### Chẩn đoán hữu ích

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## Tích hợp hệ sinh thái LAB

LAB tích hợp các repo AI sản phẩm và nghiên cứu rộng hơn của tôi thành một lớp vận hành cho tạo nội dung, tăng trưởng và tự động hóa.

Hồ sơ:

- https://github.com/lachlanchen?tab=repositories

Repo tích hợp:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (nền tảng nghiên cứu organoid dùng foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

Mục tiêu tích hợp thực tế của LAB:

- Viết tiểu thuyết tự động
- Phát triển app tự động
- Chỉnh sửa video tự động
- Tự động xuất bản đầu ra
- Tự động phân tích organoids
- Tự động xử lý vận hành email

---

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

## Lộ trình

Kế hoạch phát triển cho fork LAB này (roadmap đang làm việc):

- Mở rộng độ tin cậy automail với phân loại sender/rule nghiêm ngặt hơn.
- Cải thiện khả năng ghép orchestral stages và khả năng truy xuất artifact.
- Tăng cường vận hành mobile-first và UX quản lý gateway từ xa.
- Sâu sắc hơn các tích hợp với repo hệ sinh thái LAB cho sản xuất tự động đầu-cuối.
- Tiếp tục siết chặt mặc định bảo mật và observability cho tự động hóa chạy không giám sát.

---

## Đóng góp

Repository này theo dõi các ưu tiên cá nhân của LAB trong khi kế thừa kiến trúc lõi từ OpenClaw.

- Đọc [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- Xem tài liệu upstream: https://docs.openclaw.ai
- Vấn đề bảo mật xem [`SECURITY.md`](../SECURITY.md)

Nếu không chắc về hành vi đặc thù của LAB, giữ nguyên hành vi hiện có và ghi lại giả định trong ghi chú PR.

---

## Lời cảm ơn

LazyingArtBot dựa trên **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Cảm ơn các maintainer và cộng đồng OpenClaw vì nền tảng lõi.

---

## Giấy phép

MIT (như upstream khi phù hợp). Xem `LICENSE`.


## ❤️ Support

| Donate | PayPal | Stripe |
| --- | --- | --- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |
