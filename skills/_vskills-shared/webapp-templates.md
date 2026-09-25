# Webapp interactive step — convention dùng chung

Dùng khi 1 skill (`vdesign`/`vfix`/`vspecs`...) cần hỏi user bằng UI trực quan
(màu/font/motion, hoặc duyệt hàng loạt diff) thay vì `AskUserQuestion` text-only.
Server + frontend nằm ở `web/` (xem `web/README.md` để chạy thủ công/debug).

## (a) 3 field type + JSON mẫu

Template gửi qua `POST /api/step`:

```json
{
  "title": "Aesthetic Customization — Round 1",
  "fields": [ /* mảng field, xem 3 loại bên dưới */ ]
}
```

Kết quả trả về khi `/api/step` resolve (Claude nhận) là 1 object
`{ [field.id]: value }` — 1 key cho mỗi field, gộp cả 3 loại cùng lúc.

**`/api/step` validate template ngay lập tức, trước khi hiện lên web** (title/fields
rỗng, field thiếu `id`/`label`/`type`, `type` lạ, `id` trùng, `select` thiếu
`options` hoặc option thiếu `label`/`value`, `renderHint` sai enum, `renderHint:
"swatch"` nhưng `value` không phải màu CSS thật, `diff-review-list` thiếu `items`
hoặc item thiếu field bắt buộc). Sai → trả `400` ngay (không mở web, không set
pending): `{ "error": "invalid template", "details": ["fields[0].label phải là
string không rỗng", ...] }`. Đọc `details`, tự sửa lại JSON, gọi lại `/api/step`
— đừng để user mở tab thấy trang hỏng/rỗng mới biết JSON sai.

### `select`

| Key | Type | Required | Ghi chú |
|---|---|---|---|
| `id` | string | ✅ | Key trong object kết quả |
| `type` | `"select"` | ✅ | |
| `label` | string | ✅ | Tiêu đề field |
| `description` | string | — | Render **ngay trên** danh sách option (không phải tooltip ẩn) — dùng khi option cần đủ ngữ cảnh mới quyết định được |
| `options` | array | ✅ | Xem bảng option bên dưới |

**Option** (mỗi phần tử của `options`):

| Key | Type | Required | Ghi chú |
|---|---|---|---|
| `label` | string | ✅ | Text hiển thị |
| `value` | string | ✅ | Giá trị trả về khi chọn — PHẢI là màu hex thật nếu `renderHint: "swatch"`, CSS `font-family` thật nếu `renderHint: "font-sample"`. Không gửi label suông rồi để `renderHint` không có gì để hiện |
| `renderHint` | `"plain"` \| `"swatch"` \| `"font-sample"` | — | Mặc định `"plain"` (radio/list thường). `"swatch"` = hiện 1 ô màu dùng `value` làm CSS color. `"font-sample"` = label render bằng chính font trong `value` |

Value trả về = `option.value` của option được chọn.

```json
{
  "id": "typography",
  "type": "select",
  "label": "Typography",
  "description": "Chọn 1 cặp font đại diện cho tiêu chí này.",
  "options": [
    { "label": "IBM Plex Sans / Source Sans 3", "value": "IBM Plex Sans, sans-serif", "renderHint": "font-sample" },
    { "label": "Playfair Display / Fraunces", "value": "Playfair Display, serif", "renderHint": "font-sample" }
  ]
}
```

### `text`

| Key | Type | Required | Ghi chú |
|---|---|---|---|
| `id` | string | ✅ | Key trong object kết quả |
| `type` | `"text"` | ✅ | |
| `label` | string | ✅ | |
| `description` | string | — | Cùng quy tắc hiển thị như `select` |
| `placeholder` | string | — | |

Input tự do (textarea), dùng cho "Other"/proposal/quyết định mở. Value trả về
= string đã nhập (rỗng nếu bỏ trống).

```json
{ "id": "catchall", "type": "text", "label": "Điều gì khác bạn muốn chỉnh?", "placeholder": "Optional" }
```

### `diff-review-list`

| Key | Type | Required | Ghi chú |
|---|---|---|---|
| `id` | string | ✅ | Key trong object kết quả |
| `type` | `"diff-review-list"` | ✅ | |
| `label` | string | ✅ | |
| `items` | array | ✅ | Xem bảng item bên dưới |

**Item** (mỗi phần tử của `items`):

| Key | Type | Required | Ghi chú |
|---|---|---|---|
| `id` | string | ✅ | ID ổn định trong lần chạy này (vd `SUGGESTION-1`) — dùng để map ngược quyết định, không dựa vào thứ tự index |
| `before` | string | ✅ | Render riêng 1 khối, tự scroll (item dài không đẩy item khác ra khỏi màn hình) |
| `after` | string | ✅ | Cùng quy tắc render như `before` |
| `actions` | string[] | ✅ | Thường `["apply", "skip"]` |
| `allowFreeText` | boolean | — | Mặc định `false`. `true` → thêm ô nhập tuỳ chọn, dùng làm chỉ dẫn bổ sung thay vì chỉ apply/skip thô |
| `default` | string | — | Action chọn sẵn khi trang mở — mặc định `"apply"` nếu bỏ trống |

Value trả về = mảng `{ id, action, freeText? }` theo **đúng thứ tự** `items` gốc.

```json
{
  "id": "suggestions",
  "type": "diff-review-list",
  "label": "Review suggestions",
  "items": [
    {
      "id": "SUGGESTION-1",
      "before": "mô tả vấn đề + code hiện tại",
      "after": "fix đề xuất",
      "actions": ["apply", "skip"],
      "allowFreeText": true,
      "default": "apply"
    }
  ]
}
```

## (b) 1 port cố định + health-check + start nền + mở browser

`web/` là 1 script Node thuần (`node:http`, 0 dependency, 0 `npm install`) —
1 process, 1 port, phục vụ cả frontend lẫn API.

- Webapp: `http://localhost:4270` (override bằng env `VSKILLS_WEBAPP_PORT`)

**Trước khi dùng, Claude luôn health-check trước khi start:**

```bash
curl -s localhost:4270/api/health
# mong đợi: {"service":"vskills-webapp","ok":true}
```

- Nhận đúng field `service: "vskills-webapp"` → server đã chạy, dùng luôn,
  KHÔNG start lại.
- Không có response, lỗi kết nối, hoặc `service` khác/thiếu (port bị service
  khác chiếm) → start nền (từ repo root):

```bash
node web/server.mjs &     # Bash run_in_background: true
```

- Đợi health-check pass rồi mở tab: `open http://localhost:4270` (macOS).
- **Ghi JSON template ra 1 file tạm trước** (dùng tool Write, không phải `echo`/heredoc)
  — template thường chứa code diff/text tự do với backtick, dấu nháy, `$`, nhét
  thẳng vào `-d '<json>'` sẽ vỡ shell-escaping hoặc sai nội dung. Rồi gọi bước
  tương tác bằng 1 lệnh Bash `run_in_background: true` duy nhất, đọc body từ file:

```bash
curl -s -w '\n%{http_code}' -X POST localhost:4270/api/step -H 'content-type: application/json' -d @/path/to/step-template.json
```

  Lệnh này **tự treo** tới khi user submit trên trang web — harness tự động
  notify Claude khi lệnh nền hoàn tất (không tự polling/sleep-loop). Dòng cuối
  của stdout là HTTP status code (nhờ `-w`), phần còn lại là JSON body — luôn
  kiểm tra status trước khi dùng body:
  - `400` → template sai (xem mục (a)), trả về NGAY LẬP TỨC, không phải sau khi
    user submit — đọc `details`, sửa JSON, gọi lại, KHÔNG hỏi/mở tab cho user
  - `504` → hết timeout, không có answer — coi như user không chọn webapp,
    fallback theo hướng dẫn bên dưới
  - `200` → body chính là object kết quả `{ [field.id]: value }` — parse JSON
    đó để lấy quyết định của user
- User đóng tab không submit → lệnh trên tự trả lỗi timeout sau 30 phút mặc
  định (`VSKILLS_WEBAPP_STEP_TIMEOUT_MS` để đổi) — skill nên nói rõ cho user
  biết sẽ chờ tối đa bao lâu trước khi gọi.
- Timeout/lỗi khi đang chờ → coi như user không chọn mode webapp cho bước đó:
  báo ngắn gọn rồi hỏi lại bằng `AskUserQuestion` (cách cũ) thay vì thử lại
  webapp hoặc dừng hẳn skill.

## (c) Đoạn `AskUserQuestion` mẫu hỏi mode

Hỏi đúng 1 lần trước khi vào bước cần webapp (không hỏi lại mỗi round nếu
bước đó có nhiều vòng lặp trong cùng 1 lần chạy skill):

```
question: "Bước này có nhiều lựa chọn cần NHÌN THẤY (màu/font) / duyệt hàng loạt. Dùng webapp tương tác hay giữ cách hỏi qua chat như cũ?"
header: "Chế độ tương tác"
options:
  - label: "Dùng webapp tương tác (Recommended)"
    description: "Mở 1 trang xem trực quan swatch màu/font thật, hoặc duyệt hàng loạt diff — trả lời 1 lần, nhanh hơn nhiều vòng hỏi qua chat"
  - label: "Giữ cách hỏi qua chat (AskUserQuestion)"
    description: "Không mở webapp, tiếp tục hỏi tuần tự qua chat như hiện tại"
```
