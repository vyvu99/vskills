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

### `select`

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

- `renderHint`: `"plain"` (mặc định, list/radio thường) | `"swatch"` (option hiện 1 ô
  màu dùng `option.value` làm CSS color — `value` PHẢI là màu thật, vd `"#1E63B8"`,
  không phải tên khái niệm) | `"font-sample"` (label render bằng chính font trong
  `option.value` — `value` PHẢI là 1 CSS `font-family` hợp lệ, vd font thật kèm
  fallback).
- `description` (optional): render **ngay trên** danh sách option, không phải
  tooltip ẩn — dùng khi option cần đủ ngữ cảnh mới quyết định được (case dài).
- Value trả về = `option.value` của option được chọn (string).
- **Bắt buộc:** nếu dùng `swatch`/`font-sample`, mỗi option phải có 1 giá trị
  đại diện THẬT (màu hex/font family thật) — không gửi label suông rồi để
  `renderHint` không có gì để hiện.

### `text`

```json
{ "id": "catchall", "type": "text", "label": "Điều gì khác bạn muốn chỉnh?", "placeholder": "Optional" }
```

Input tự do (textarea), dùng cho "Other"/proposal/quyết định mở. Value trả về
= string đã nhập (rỗng nếu bỏ trống).

### `diff-review-list`

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

- Mỗi item render 1 khối riêng: `before`/`after` cạnh nhau, tự scroll riêng
  (item dài không đẩy các item khác ra khỏi màn hình).
- `default` (optional): action được chọn sẵn khi trang mở (mặc định `"apply"`
  nếu bỏ trống).
- `allowFreeText: true` → thêm ô nhập tuỳ chọn, dùng làm chỉ dẫn bổ sung thay
  vì chỉ apply/skip thô.
- Value trả về = mảng `{ id, action, freeText? }` theo **đúng thứ tự** `items`
  gốc — map ngược lại bằng `id`, không dựa vào thứ tự index.

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
curl -s -X POST localhost:4270/api/step -H 'content-type: application/json' -d @/path/to/step-template.json
```

  Lệnh này **tự treo** tới khi user submit trên trang web — harness tự động
  notify Claude khi lệnh nền hoàn tất (không tự polling/sleep-loop). Response
  stdout của lệnh chính là object kết quả `{ [field.id]: value }` — parse JSON
  đó để lấy quyết định của user.
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
