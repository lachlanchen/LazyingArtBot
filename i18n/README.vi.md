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

> 🌍 **Trạng thái i18n:** `i18n/` đã tồn tại và hiện có các bản địa hóa tiếng Ả Rập, tiếng Đức, tiếng Tây Ban Nha, tiếng Pháp, tiếng Nhật, tiếng Hàn, tiếng Nga, tiếng Việt, tiếng Trung giản thể và tiếng Trung phồn thể. Bản tiếng Anh này vẫn là nguồn nội dung chuẩn cho các cập nhật tăng dần.

**LazyingArtBot** là bộ công cụ trợ lý AI cá nhân của tôi cho **lazying.art**:

**LazyingArtBot** được xây dựng trên OpenClaw và chỉnh sửa cho phù hợp với luồng làm việc hằng ngày của tôi: chat đa kênh, điều khiển theo hướng local-first, và tự động hóa email → lịch nhắc, ghi chú.

| 🔗 Liên kết     | URL                                          | Mục tiêu                                   |
| --------------- | -------------------------------------------- | ------------------------------------------ |
| 🌐 Website      | https://lazying.art                          | Domain chính và bảng điều khiển trạng thái |
| 🤖 Miền bot     | https://lazying.art                          | Điểm vào chat và trợ lý                    |
| 🧱 Nền tảng gốc | https://github.com/openclaw/openclaw         | Nền tảng lõi OpenClaw                      |
| 📦 Repo này     | https://github.com/lachlanchen/LazyingArtBot | Tùy biến của LAB                           |

---

## Mục lục

- [Tổng quan](#tổng-quan)
- [Nhìn tổng quát](#nhìn-tổng-quát)
- [Tính năng](#tính-năng)
- [Khả năng cốt lõi](#khả-năng-cốt-lõi)
- [Cấu trúc dự án](#cấu-trúc-dự-án)
- [Yêu cầu trước khi bắt đầu](#yêu-cầu-trước-khi-bắt-đầu)
- [Bắt đầu nhanh](#bắt-đầu-nhanh)
- [Cài đặt](#cài-đặt)
- [Sử dụng](#sử-dụng)
- [Cấu hình](#cấu-hình)
- [Chế độ triển khai](#chế-độ-triển-khai)
- [Trọng tâm quy trình LazyingArt](#trọng-tâm-quy-trình-lazyingart)
- [Triết lý Orchestral](#triết-lý-orchestral)
- [Prompt tools trong LAB](#prompt-tools-trong-lab)
- [Ví dụ](#ví-dụ)
- [Ghi chú phát triển](#ghi-chú-phát-triển)
- [Khắc phục sự cố](#khắc-phục-sự-cố)
- [Tích hợp hệ sinh thái LAB](#tích-hợp-hệ-sinh-thái-lab)
- [Cài đặt từ mã nguồn (tham chiếu nhanh)](#cài-đặt-từ-mã-nguồn-tham-chiếu-nhanh)
- [Lộ trình](#lộ-trình)
- [Đóng góp](#đóng-góp)
- [❤️ Support](#-support)
- [Liên hệ](#liên-hệ)
- [Giấy phép](#giấy-phép)

---

## Tổng quan

LAB tập trung vào năng suất cá nhân theo hướng thực tiễn:

- ✅ Chạy một trợ lý duy nhất cho các kênh chat bạn đã dùng.
- 🔐 Giữ dữ liệu và quyền kiểm soát trên máy/chủ của chính bạn.
- 📬 Chuyển đổi email đến thành các hành động có cấu trúc (Calendar, Reminders, Notes).
- 🛡️ Bổ sung guardrails để tự động hóa hữu ích nhưng vẫn an toàn.

Nói ngắn gọn: ít việc lặt vặt hơn, thực thi tốt hơn.

---

## Nhìn tổng quát

| Khu vực                | Trạng thái hiện tại trong repo             |
| ---------------------- | ------------------------------------------ |
| Runtime                | Node.js `>=22.12.0`                        |
| Quản lý gói            | `pnpm@10.23.0`                             |
| Core CLI               | `openclaw`                                 |
| Gateway local mặc định | `127.0.0.1:18789`                          |
| Cổng bridge mặc định   | `127.0.0.1:18790`                          |
| Tài liệu chính         | `docs/` (Mintlify)                         |
| Điều phối LAB chính    | `orchestral/` + `orchestral/prompt_tools/` |
| Vị trí README i18n     | `i18n/README.*.md`                         |

---

## Tính năng

- 🌐 Runtime trợ lý đa kênh với local gateway.
- 🖥️ Bề mặt dashboard/chat chạy trên trình duyệt cho vận hành local.
- 🧰 Chuỗi tự động hóa có công cụ hỗ trợ (scripts + prompt-tools).
- 📨 Phân loại email và chuyển thành hành động cho Notes, Reminders, Calendar.
- 🧩 Hệ sinh thái plugin/extension (`extensions/*`) cho kênh/provider/tích hợp.
- 📱 Nhiều giao diện nền tảng trong repo (`apps/macos`, `apps/ios`, `apps/android`, `ui`).

---

## Khả năng cốt lõi

| Khả năng                   | Ý nghĩa trong thực tế                                                                                                          |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Runtime trợ lý đa kênh     | Gateway + phiên làm việc agent trên các kênh bạn bật                                                                           |
| Dashboard/chat web         | Bề mặt điều khiển trong trình duyệt cho vận hành local                                                                         |
| Workflow có công cụ        | Dây chuyền thực thi shell + file + script tự động hóa                                                                          |
| Pipeline tự động hóa email | Phân tích email, phân loại loại hành động, chuyển sang Notes/Reminders/Calendar và ghi log toàn bộ hành động để rà soát/gỡ lỗi |

Các bước pipeline giữ theo workflow hiện tại:

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

- `orchestral/prompt_tools` trỏ tới phần triển khai prompt-tool orchestral.
- Root `i18n/` chứa các biến thể README bản địa hóa.
- `.github/workflows.disabled/` có trong snapshot này; hành vi CI nên được xác minh trước khi dựa vào giả định về workflow.

---

## Yêu cầu trước khi bắt đầu

Baseline runtime/tooling của repo:

- Node.js `>=22.12.0`
- pnpm `10.23.0` baseline (xem `packageManager` trong `package.json`)
- Ít nhất một khóa model provider đã cấu hình (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, ...)
- Tùy chọn: Docker + Docker Compose cho gateway/CLI theo container
- Tùy chọn cho build mobile/mac: bộ công cụ Apple/Android tùy theo nền tảng đích

Cài đặt global CLI tùy chọn (phù hợp luồng nhanh):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## Bắt đầu nhanh

Baseline runtime trong repo: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Sau đó mở dashboard local và chat:

- http://127.0.0.1:18789

Với truy cập từ xa, mở local gateway của bạn qua tunnel an toàn (ví dụ ngrok/Tailscale) và vẫn bật xác thực.

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

File `docker-compose.yml` đã đi kèm gồm:

- `openclaw-gateway`
- `openclaw-cli`

Luồng điển hình:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Biến compose thường cần thiết:

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

## Cấu hình

Tham chiếu môi trường và cấu hình nằm giữa `.env` và `~/.openclaw/openclaw.json`.

1. Bắt đầu từ `.env.example`.
2. Cấu hình auth của gateway (`OPENCLAW_GATEWAY_TOKEN` được khuyến nghị).
3. Thiết lập ít nhất một khóa model provider (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, v.v.).
4. Chỉ cấu hình credentials cho kênh bạn đã bật.

Lưu ý quan trọng trong `.env.example`:

- Thứ tự ưu tiên env: process env -> `./.env` -> `~/.openclaw/.env` -> block `env` trong config.
- Các giá trị process env không rỗng hiện có sẽ không bị ghi đè.
- Các khóa config như `gateway.auth.token` có thể ưu tiên hơn env fallback.

Định hướng an toàn bắt buộc trước khi đưa lên internet:

- Giữ gateway auth/pairing luôn bật.
- Giữ allowlists nghiêm ngặt cho inbound channels.
- Đối xử mọi tin nhắn/email đến như đầu vào không đáng tin.
- Chạy theo nguyên tắc least privilege và kiểm tra logs thường xuyên.

Nếu expose gateway ra internet, bắt buộc bật token/password auth và trusted proxy config.

---

## Chế độ triển khai

| Chế độ               | Phù hợp cho                           | Lệnh điển hình                                                |
| -------------------- | ------------------------------------- | ------------------------------------------------------------- |
| Foreground local     | Development và debug                  | `openclaw gateway run --bind loopback --port 18789 --verbose` |
| Daemon local         | Dùng hằng ngày cho bản thân           | `openclaw onboard --install-daemon`                           |
| Docker               | Runtime cách ly và triển khai lặp lại | `docker compose up -d`                                        |
| Remote host + tunnel | Truy cập từ ngoài mạng nội bộ         | Chạy gateway + tunnel an toàn, giữ auth bật                   |

Giả định: hardening reverse-proxy cấp production, luân chuyển secret, và chính sách backup phụ thuộc môi trường triển khai.

---

## Trọng tâm quy trình LazyingArt

Fork này ưu tiên luồng làm việc cá nhân của tôi tại **lazying.art**:

- 🎨 Branding tùy chỉnh (chủ đề LAB / panda)
- 📱 Dashboard/chat có trải nghiệm thân thiện mobile
- 📨 Các biến thể automail (rule-driven và các chế độ save có hỗ trợ codex)
- 🧹 Tự động dọn dẹp và phân loại sender theo nhu cầu cá nhân
- 🗂️ Routing notes/reminders/calendar tối ưu cho sử dụng hằng ngày

Không gian automation local:

- `~/.openclaw/workspace/automation/`
- Tài liệu tham chiếu trong repo: `references/lab-scripts-and-philosophy.md`
- Prompt tool dành cho Codex: `orchestral/prompt_tools/`

---

## Triết lý Orchestral

Orchestration của LAB theo một quy tắc thiết kế:
chia mục tiêu phức tạp thành thực thi deterministic + chuỗi prompt-tool có trọng tâm.

- Scripts deterministic chịu trách nhiệm những phần plumbing đáng tin cậy:
  lập lịch, định tuyến file, cấu hình run directory, retry, và bàn giao output.
- Prompt tools xử lý trí tuệ thích ứng:
  lập kế hoạch, triage, tổng hợp ngữ cảnh, và ra quyết định khi có bất định.
- Mỗi giai đoạn tạo artifact tái sử dụng được để công cụ kế tiếp có thể compose ra notes/email tốt hơn mà không cần bắt đầu lại từ đầu.

Các chuỗi orchestration chính:

- Chuỗi khởi nghiệp:
  thu thập ngữ cảnh công ty -> thông tin thị trường/nhu cầu vốn/học thuật/pháp lý -> hành động tăng trưởng cụ thể.
- Chuỗi auto mail:
  triage email đầu vào -> chính sách bỏ qua bảo thủ với email giá trị thấp -> actions Notes/Reminders/Calendar có cấu trúc.
- Chuỗi web search:
  capture trang kết quả -> đọc sâu chọn lọc kèm screenshot/extract nội dung -> tổng hợp có bằng chứng.

---

## Prompt tools trong LAB

Prompt tools được thiết kế theo kiểu module, ghép nối được, và ưu tiên orchestration.
Chúng có thể chạy độc lập hoặc như các giai đoạn liên kết trong workflow lớn hơn.

- Đọc/lưu: tạo và cập nhật Notes, Reminders, Calendar cho AutoLife operations.
- Screenshot/đọc: chụp các trang search và trang liên kết, rồi trích xuất text có cấu trúc cho phân tích tiếp theo.
- Kết nối công cụ:
  gọi script deterministic, trao đổi artifacts giữa các giai đoạn, và giữ liên tục ngữ cảnh.

Vị trí chính:

- `orchestral/prompt_tools/`

---

## Ví dụ

### Ví dụ: local-only gateway

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Ví dụ: nhờ agent xử lý lập kế hoạch hằng ngày

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
- Các cổng kiểm tra chất lượng phổ biến:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI trong dev: `pnpm openclaw ...`
- TS run loop: `pnpm dev`
- Lệnh UI package được chạy qua script gốc (`pnpm ui:build`, `pnpm ui:dev`).

Lệnh test mở rộng trong repo:

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

- Build/run app mobile/macOS có trong `package.json` (`ios:*`, `android:*`, `mac:*`) nhưng yêu cầu ký tên/chứng chỉ nền tảng phụ thuộc môi trường và không hoàn toàn được mô tả trong README này.

---

## Khắc phục sự cố

### Gateway không thể truy cập tại `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Kiểm tra xung đột cổng và xung đột daemon. Nếu dùng Docker, xác minh port host đã map và health của service.

### Vấn đề auth hoặc cấu hình kênh

- Kiểm tra lại các giá trị `.env` so với `.env.example`.
- Bảo đảm có ít nhất một model key đã cấu hình.
- Chỉ bật tokens cho các kênh thực sự sử dụng.

### Vấn đề build hoặc cài đặt

- Chạy lại `pnpm install` với Node `>=22.12.0`.
- Build lại với `pnpm ui:build && pnpm build`.
- Nếu thiếu native peer optional, kiểm tra logs cài đặt cho khả năng tương thích của `@napi-rs/canvas` / `node-llama-cpp`.

### Kiểm tra sức khỏe tổng quát

Dùng `openclaw doctor` để phát hiện drift migration/security/config.

### Chẩn đoán hữu ích

```bash
openclaw channels status --probe
openclaw gateway status
openclaw status --deep
```

---

## Tích hợp hệ sinh thái LAB

LAB kết nối các repo AI sản phẩm và nghiên cứu của tôi thành một lớp vận hành cho tạo nội dung, tăng trưởng và tự động hóa.

Hồ sơ:

- https://github.com/lachlanchen?tab=repositories

Repo tích hợp:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (nền tảng nghiên cứu orgaoid dùng foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

Mục tiêu tích hợp thực tế của LAB:

- Tự động viết tiểu thuyết
- Tự động phát triển app
- Tự động chỉnh sửa video
- Tự động xuất bản đầu ra
- Tự động phân tích organoid
- Tự động xử lý vận hành email

---

## Cài đặt từ mã nguồn (tham chiếu nhanh)

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

Kế hoạch cho fork LAB này (roadmap đang cập nhật):

- Mở rộng độ tin cậy automail với phân loại sender/rule nghiêm ngặt hơn.
- Cải thiện khả năng ghép stage orchestral và truy vết artifact.
- Tăng cường vận hành mobile-first và UX quản lý gateway từ xa.
- Tăng độ sâu tích hợp với các repo trong hệ sinh thái LAB cho sản xuất tự động đầu-cuối.
- Tiếp tục siết chặt mặc định bảo mật và quan sát cho automation chạy không giám sát.

---

## Đóng góp

Repo này theo dõi các ưu tiên cá nhân của LAB trong khi kế thừa kiến trúc lõi từ OpenClaw.

- Đọc [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- Tham khảo docs upstream: https://docs.openclaw.ai
- Với các vấn đề bảo mật, xem [`SECURITY.md`](../SECURITY.md)

Nếu không chắc về hành vi riêng của LAB, giữ nguyên hành vi hiện có và ghi rõ giả định trong ghi chú PR.

---

## Lời cảm ơn

LazyingArtBot dựa trên **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Cảm ơn các maintainer và cộng đồng OpenClaw đã xây dựng nền tảng lõi.

## Liên hệ

- Website: https://lazying.art
- Repository: https://github.com/lachlanchen/LazyingArtBot
- Issue tracker: https://github.com/lachlanchen/LazyingArtBot/issues
- Security or safety concerns: https://github.com/lachlanchen/LazyingArtBot/blob/main/SECURITY.md

---

## Giấy phép

MIT (giống upstream khi có thể áp dụng). Xem `LICENSE`.

## ❤️ Support

| Donate                                                                                                                                                                                                                                                                                                                                                     | PayPal                                                                                                                                                                                                                                                                                                                                                          | Stripe                                                                                                                                                                                                                                                                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Donate](https://camo.githubusercontent.com/24a4914f0b42c6f435f9e101621f1e52535b02c225764b2f6cc99416926004b7/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d4c617a79696e674172742d3045413545393f7374796c653d666f722d7468652d6261646765266c6f676f3d6b6f2d6669266c6f676f436f6c6f723d7768697465)](https://chat.lazying.art/donate) | [![PayPal](https://camo.githubusercontent.com/d0f57e8b016517a4b06961b24d0ca87d62fdba16e18bbdb6aba28e978dc0ea21/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f50617950616c2d526f6e677a686f754368656e2d3030343537433f7374796c653d666f722d7468652d6261646765266c6f676f3d70617970616c266c6f676f436f6c6f723d7768697465)](https://paypal.me/RongzhouChen) | [![Stripe](https://camo.githubusercontent.com/1152dfe04b6943afe3a8d2953676749603fb9f95e24088c92c97a01a897b4942/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5374726970652d446f6e6174652d3633354246463f7374796c653d666f722d7468652d6261646765266c6f676f3d737472697065266c6f676f436f6c6f723d7768697465)](https://buy.stripe.com/aFadR8gIaflgfQV6T4fw400) |
