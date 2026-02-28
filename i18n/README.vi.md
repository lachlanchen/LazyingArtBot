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

>
> Lưu ý: `i18n/` đã tồn tại và hiện có tiếng Ả Rập. Các biến thể README bản địa hóa bổ sung sẽ được xử lý từng ngôn ngữ một để giữ nội dung nhất quán với các bản cập nhật nguồn.

**LazyingArtBot** là stack trợ lý AI cá nhân của tôi cho **lazying.art**.  
Nó được xây dựng trên OpenClaw và tùy biến cho quy trình làm việc hằng ngày của tôi: chat đa kênh, điều khiển local-first, và tự động hóa email → lịch/nhắc việc/ghi chú.

| Liên kết | URL |
| --- | --- |
| Website | https://lazying.art |
| Bot domain | https://lazying.art |
| Upstream base | https://github.com/openclaw/openclaw |
| Repo này | https://github.com/lachlanchen/LazyingArtBot |

---

## Table of contents

- [🧭 Tổng quan](#-tổng-quan)
- [⚡ Nhanh gọn](#-nhanh-gọn)
- [⚙️ Năng lực cốt lõi](#️-năng-lực-cốt-lõi)
- [🧱 Cấu trúc dự án](#-cấu-trúc-dự-án)
- [📋 Điều kiện tiên quyết](#-điều-kiện-tiên-quyết)
- [🚀 Bắt đầu nhanh](#-bắt-đầu-nhanh)
- [🧱 Cài đặt](#-cài-đặt)
- [🛠️ Sử dụng](#️-sử-dụng)
- [🔐 Cấu hình](#-cấu-hình)
- [🧩 Trọng tâm quy trình LazyingArt](#-trọng-tâm-quy-trình-lazyingart)
- [🎼 Triết lý Orchestral](#-triết-lý-orchestral)
- [🧰 Prompt tools trong LAB](#-prompt-tools-trong-lab)
- [💡 Ví dụ](#-ví-dụ)
- [🧪 Ghi chú phát triển](#-ghi-chú-phát-triển)
- [🩺 Khắc phục sự cố](#-khắc-phục-sự-cố)
- [🌐 Tích hợp hệ sinh thái LAB](#-tích-hợp-hệ-sinh-thái-lab)
- [Cài đặt từ source](#cài-đặt-từ-source)
- [🗺️ Lộ trình](#️-lộ-trình)
- [🤝 Đóng góp](#-đóng-góp)
- [❤️ Hỗ trợ / Tài trợ](#️-hỗ-trợ--tài-trợ)
- [🙏 Lời cảm ơn](#-lời-cảm-ơn)
- [📄 Giấy phép](#-giấy-phép)

---

## 🧭 Tổng quan

LAB tập trung vào năng suất cá nhân thực dụng:

- Chạy một trợ lý trên các kênh chat bạn đã dùng sẵn.
- Giữ dữ liệu và quyền kiểm soát trên máy chủ/máy tính của riêng bạn.
- Chuyển email đến thành hành động có cấu trúc (Calendar, Reminders, Notes).
- Thêm guardrail để tự động hóa hữu ích nhưng vẫn an toàn.

Tóm lại: bớt việc vặt, thực thi tốt hơn.

---

## ⚡ Nhanh gọn

| Khu vực | Mốc cơ sở hiện tại trong repo này |
| --- | --- |
| Runtime | Node.js `>=22.12.0` |
| Trình quản lý gói | `pnpm@10.23.0` |
| CLI cốt lõi | `openclaw` |
| Gateway local mặc định | `127.0.0.1:18789` |
| Tài liệu chính | `docs/` (Mintlify) |
| Điều phối LAB chính | `orchestral/` + `scripts/prompt_tools/` |

---

## ⚙️ Năng lực cốt lõi

- Runtime trợ lý đa kênh (Gateway + phiên agent).
- Dashboard web / giao diện điều khiển web chat.
- Quy trình agent có bật công cụ (shell, file, script tự động hóa).
- Pipeline tự động hóa email cho vận hành cá nhân:
  - phân tích email đến
  - phân loại loại hành động
  - lưu vào Notes / Reminders / Calendar
  - ghi log mọi hành động để rà soát và debug

---

## 🧱 Cấu trúc dự án

Bố cục cấp cao của repository:

```text
.
├─ src/                 # runtime lõi, gateway, channels, CLI, infra
├─ extensions/          # plugin kênh/provider/auth tùy chọn
├─ orchestral/          # pipeline điều phối LAB + prompt tools
├─ scripts/             # trợ giúp build/dev/test/release
├─ ui/                  # gói UI dashboard web
├─ apps/                # ứng dụng macOS / iOS / Android
├─ docs/                # tài liệu Mintlify
├─ references/          # tài liệu tham chiếu và ghi chú vận hành LAB
├─ test/                # bộ test
├─ .env.example         # mẫu môi trường
├─ docker-compose.yml   # container gateway + CLI
├─ README_OPENCLAW.md   # README tham chiếu kiểu upstream đầy đủ hơn
└─ README.md            # README tập trung LAB này
```

Ghi chú:

- `scripts/prompt_tools` trỏ đến phần triển khai prompt-tool của orchestral.
- Thư mục `i18n/` gốc đã tồn tại và hiện còn tối giản trong snapshot này; tài liệu bản địa hóa chủ yếu nằm dưới `docs/`.

---

## 📋 Điều kiện tiên quyết

Mốc runtime và công cụ từ repository này:

- Node.js `>=22.12.0`
- Mốc pnpm `10.23.0` (xem `packageManager` trong `package.json`)
- Khóa model provider đã cấu hình (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, v.v.)
- Tùy chọn: Docker + Docker Compose cho gateway/CLI dạng container

Cài CLI global tùy chọn (khớp với luồng quick-start):

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest
```

---

## 🚀 Bắt đầu nhanh

Mốc runtime trong repo này: **Node >= 22.12.0** (`package.json` engine).

```bash
npm install -g openclaw@latest
# or
pnpm add -g openclaw@latest

openclaw onboard --install-daemon
openclaw gateway run --bind loopback --port 18789 --verbose
```

Sau đó mở dashboard local và chat:

- http://127.0.0.1:18789

Để truy cập từ xa, hãy public gateway local qua đường hầm bảo mật của riêng bạn (ví dụ ngrok/Tailscale) và luôn bật xác thực.

---

## 🧱 Cài đặt

### Cài đặt từ source

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

### Luồng Docker tùy chọn

Có `docker-compose.yml` đi kèm với:

- `openclaw-gateway`
- `openclaw-cli`

Luồng điển hình:

```bash
cp .env.example .env
# set at minimum: OPENCLAW_GATEWAY_TOKEN and your model provider key(s)
docker compose up -d
```

Lưu ý: mount path và port được điều khiển bởi các biến compose như `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACE_DIR`, `OPENCLAW_GATEWAY_PORT`, và `OPENCLAW_BRIDGE_PORT`.

---

## 🛠️ Sử dụng

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

Vòng lặp dev (watch mode):

```bash
pnpm gateway:watch
```

Phát triển UI:

```bash
pnpm ui:dev
```

---

## 🔐 Cấu hình

Tham chiếu môi trường và cấu hình được tách giữa `.env` và `~/.openclaw/openclaw.json`.

1. Bắt đầu từ `.env.example`.
2. Thiết lập auth gateway (`OPENCLAW_GATEWAY_TOKEN` được khuyến nghị).
3. Thiết lập ít nhất một khóa model provider (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, v.v.).
4. Chỉ đặt thông tin xác thực kênh cho các kênh bạn bật.

Các lưu ý quan trọng từ `.env.example` được giữ nguyên từ repo:

- Thứ tự ưu tiên env: process env → `./.env` → `~/.openclaw/.env` → khối `env` trong config.
- Giá trị process env hiện có và không rỗng sẽ không bị ghi đè.
- Các khóa config như `gateway.auth.token` có thể được ưu tiên hơn env fallback.

Mốc cơ sở bảo mật quan trọng trước khi public internet:

- Giữ auth/pairing của gateway ở trạng thái bật.
- Giữ allowlist chặt chẽ cho các kênh inbound.
- Xem mọi tin nhắn/email inbound là dữ liệu không tin cậy.
- Chạy với đặc quyền tối thiểu và rà soát log thường xuyên.

Nếu bạn public gateway lên internet, bắt buộc dùng token/password auth và cấu hình trusted proxy.

---

## 🧩 Trọng tâm quy trình LazyingArt

Fork này ưu tiên luồng cá nhân của tôi tại **lazying.art**:

- branding tùy chỉnh (LAB / chủ đề gấu trúc)
- trải nghiệm dashboard/chat thân thiện di động
- các biến thể pipeline automail (trigger theo rule, chế độ lưu có codex hỗ trợ)
- script dọn dẹp cá nhân và phân loại người gửi
- định tuyến notes/reminders/calendar được tinh chỉnh cho sử dụng hằng ngày thực tế

Workspace tự động hóa (local):

- `~/.openclaw/workspace/automation/`
- Tham chiếu script trong repo: `references/lab-scripts-and-philosophy.md`
- Prompt tools Codex chuyên dụng: `scripts/prompt_tools/`

---

## 🎼 Triết lý Orchestral

Điều phối LAB theo một quy tắc thiết kế:  
chia mục tiêu khó thành thực thi tất định + chuỗi prompt-tool tập trung.

- Script tất định xử lý phần plumbing đáng tin cậy:
  scheduling, định tuyến file, thư mục run, retry và bàn giao đầu ra.
- Prompt tools xử lý trí tuệ thích ứng:
  lập kế hoạch, phân loại ưu tiên, tổng hợp ngữ cảnh và ra quyết định trong điều kiện bất định.
- Mỗi giai đoạn đều tạo artifact có thể tái sử dụng để công cụ downstream tổng hợp ghi chú/email cuối tốt hơn mà không phải bắt đầu từ con số 0.

Các chuỗi orchestral cốt lõi:

- Chuỗi khởi nghiệp doanh nghiệp:
  nạp ngữ cảnh công ty → intelligence về thị trường/funding/học thuật/pháp lý → hành động tăng trưởng cụ thể.
- Chuỗi auto mail:
  phân loại email đến → chính sách skip bảo thủ cho email giá trị thấp → hành động Notes/Reminders/Calendar có cấu trúc.
- Chuỗi web search:
  chụp trang kết quả → đọc sâu có mục tiêu với trích xuất ảnh chụp/nội dung → tổng hợp dựa trên bằng chứng.

---

## 🧰 Prompt tools trong LAB

Prompt tools có tính mô-đun, kết hợp được, và ưu tiên điều phối.  
Chúng có thể chạy độc lập hoặc nối theo giai đoạn trong một workflow lớn hơn.

- Thao tác đọc/lưu:
  tạo và cập nhật đầu ra Notes, Reminders, và Calendar cho các tác vụ AutoLife.
- Thao tác screenshot/read:
  chụp trang tìm kiếm và các trang được liên kết, sau đó trích xuất văn bản có cấu trúc cho phân tích downstream.
- Thao tác kết nối công cụ:
  gọi script tất định, trao đổi artifact giữa các giai đoạn, và duy trì tính liên tục ngữ cảnh.

Vị trí chính:

- `scripts/prompt_tools/`

---

## 💡 Ví dụ

### Ví dụ: gateway chỉ local

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

### Ví dụ: yêu cầu agent xử lý kế hoạch hằng ngày

```bash
openclaw agent --message "Review today inbox and build a prioritized task plan" --thinking high
```

### Ví dụ: build từ source + vòng lặp watch

```bash
pnpm install
pnpm ui:build
pnpm build
pnpm gateway:watch
```

---

## 🧪 Ghi chú phát triển

- Mốc runtime: Node `>=22.12.0`.
- Mốc package manager: `pnpm@10.23.0` (trường `packageManager`).
- Các cổng chất lượng thường dùng:

```bash
pnpm check          # format + ts checks + lint
pnpm build          # build dist output
pnpm test           # test suite
pnpm test:coverage  # coverage run
```

- CLI trong dev: `pnpm openclaw ...`
- Vòng lặp chạy TS: `pnpm dev`
- Các lệnh gói UI được proxy qua script gốc (`pnpm ui:build`, `pnpm ui:dev`).

---

## 🩺 Khắc phục sự cố

### Không thể truy cập Gateway tại `127.0.0.1:18789`

```bash
openclaw gateway run --bind loopback --port 18789 --verbose
```

Kiểm tra xung đột cổng và xung đột daemon. Nếu dùng Docker, xác minh cổng host map và tình trạng service.

### Lỗi auth hoặc cấu hình kênh

- Kiểm tra lại giá trị `.env` so với `.env.example`.
- Đảm bảo đã cấu hình ít nhất một model key.
- Chỉ xác minh channel token cho các kênh bạn thực sự bật.

### Kiểm tra sức khỏe tổng quát

Dùng `openclaw doctor` để phát hiện các vấn đề migration/security/config drift.

---

## 🌐 Tích hợp hệ sinh thái LAB

LAB tích hợp các repo sản phẩm và nghiên cứu AI rộng hơn của tôi vào một lớp vận hành duy nhất cho sáng tạo, tăng trưởng và tự động hóa.

Hồ sơ:

- https://github.com/lachlanchen?tab=repositories

Các repo tích hợp:

- `VoidAbyss` (隙遊之淵)
- `AutoNovelWriter` (automatic novel writing)
- `AutoAppDev` (automatic app development)
- `OrganoidAgent` (organoid research platform with foundation vision models + LLMs)
- `LazyEdit` (AI-assisted video editing: captions/transcription/highlights/metadata/subtitles)
- `AutoPublish` (automatic publication pipeline)

Mục tiêu tích hợp LAB thực tế:

- Tự động viết tiểu thuyết
- Tự động phát triển ứng dụng
- Tự động chỉnh sửa video
- Tự động xuất bản đầu ra
- Tự động phân tích organoid
- Tự động xử lý tác vụ email

---

## Cài đặt từ source

```bash
git clone https://github.com/lachlanchen/LazyingArtBot.git
cd LazyingArtBot
pnpm install
pnpm ui:build
pnpm build
pnpm openclaw onboard --install-daemon
```

Vòng lặp dev:

```bash
pnpm gateway:watch
```

---

## 🗺️ Lộ trình

Các hướng dự kiến cho fork LAB này (working roadmap):

- Mở rộng độ tin cậy của automail với phân loại người gửi/rule chặt chẽ hơn.
- Cải thiện khả năng kết hợp giữa các stage orchestral và khả năng truy vết artifact.
- Tăng cường trải nghiệm vận hành mobile-first và UX quản lý gateway từ xa.
- Làm sâu hơn tích hợp với các repo hệ sinh thái LAB để tự động hóa sản xuất end-to-end.
- Tiếp tục tăng cường mặc định bảo mật và khả năng quan sát cho tự động hóa không giám sát.

---

## 🤝 Đóng góp

Repository này bám theo ưu tiên LAB cá nhân, đồng thời kế thừa kiến trúc cốt lõi từ OpenClaw.

- Đọc [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Xem tài liệu upstream: https://docs.openclaw.ai
- Với vấn đề bảo mật, xem [`SECURITY.md`](SECURITY.md)

Nếu chưa chắc về hành vi đặc thù của LAB, hãy giữ nguyên hành vi hiện có và ghi rõ giả định trong ghi chú PR.

---

## ❤️ Hỗ trợ / Tài trợ

Nếu LAB giúp ích cho workflow của bạn, hãy ủng hộ quá trình phát triển liên tục:

- GitHub Sponsors: https://github.com/sponsors/lachlanchen
- Trang donate: https://chat.lazying.art/donate
- Website: https://lazying.art

---

## 🙏 Lời cảm ơn

LazyingArtBot được xây dựng dựa trên **OpenClaw**:

- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai

Cảm ơn các maintainer và cộng đồng OpenClaw cho nền tảng cốt lõi.

---

## 📄 Giấy phép

MIT (giống upstream khi áp dụng). Xem `LICENSE`.
