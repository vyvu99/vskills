---
name: vspecs
description: "Tạo và cập nhật file specs cho một feature qua vòng lặp lặp đi lặp lại: đọc codebase → brainstorm edge case → hỏi user → cập nhật file. Hỗ trợ so sánh với sản phẩm khác."
user-invocable: true
when_to_use: "Dùng khi muốn viết specs mới hoặc bổ sung specs hiện có cho một feature."
category: docs
keywords: [specs, feature, brainstorm, edge-cases, documentation]
argument-hint: "Feature: [tên feature]\nCompare: [tên sản phẩm] (tuỳ chọn)"
extends: brainstorm
metadata:
  author: vyvu
  version: "1.0.0"
---

# Specs Loop

> Kế thừa skill `brainstorm` gốc — thừa hưởng toàn bộ nguyên tắc của nó (YAGNI/KISS/DRY, thẳng thắn không né tránh, khám phá phương án thay thế, thách thức các giả định). Điểm khác biệt: output cuối cùng là file specs, không phải design doc.

Đọc input từ user:

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` rỗng — dùng `AskUserQuestion` để hỏi:
- Muốn viết specs cho feature nào?
- Có so sánh với sản phẩm nào không? (để trống = không so sánh)

---

## Bước 1 — Trinh sát (chạy song song)

1. Suy ra `[feature-slug]` từ tên feature (kebab-case, tiếng Anh)
2. Kiểm tra `plans/specs/[feature-slug].md` đã tồn tại chưa
3. Scout codebase tìm code liên quan đến feature này (routes, services, schemas, UI, seed data)
4. Đọc toàn bộ `plans/specs/` để nắm các quyết định hiện có, tránh mâu thuẫn
5. Nếu có Compare product: dùng `WebSearch` để research sản phẩm đó trên web (docs, help center, review, forum cộng đồng, video demo) — chỉ ghi lại những gì quan sát trực tiếp, KHÔNG BAO GIỜ suy diễn từ trí nhớ; nếu không có Compare product → bỏ qua bước này

## Bước 2 — Phân loại và đề xuất

Dựa trên kết quả trinh sát, xác định tình huống và đề xuất hành động:

| Tình huống | Đề xuất |
|---|---|
| Feature chưa tồn tại + specs chưa tồn tại | Tạo file specs mới từ template, để trống phần chưa biết, liệt kê open questions cuối file |
| Feature chưa tồn tại + specs đã tồn tại | Đọc specs hiện tại → báo cáo phần nào đã đủ / thiếu / mâu thuẫn → hỏi user bước tiếp theo |
| Feature đã tồn tại + specs chưa tồn tại | Reverse-engineer specs từ code, tạo file specs, đánh dấu rõ phần suy ra từ code vs phần còn chưa chắc chắn |
| Feature đã tồn tại + specs đã tồn tại | So sánh specs với code → liệt kê phần khớp / lệch / hành vi trong code chưa được specs cover → hỏi user muốn sync theo hướng nào |

**Dừng lại và chờ user xác nhận trước khi tiếp tục.**

---

## Bước 3 — Vòng lặp brainstorm edge case

Sau khi user xác nhận, bắt đầu vòng lặp. Mỗi vòng:

1. Đọc lại toàn bộ `plans/specs/[feature-slug].md`
2. Đọc lại code liên quan để nắm hành vi hiện tại
3. Tự mình verify mọi thứ chưa rõ bằng cách đối chiếu với code — **KHÔNG BAO GIỜ viết "cần verify" hoặc "chưa rõ" hoặc "có thể"** nếu code tồn tại và đọc được; nếu đã tìm thật sự mà không thấy → nói rõ "đã tìm, không thấy" + cách khác để verify

4. Trình bày tối đa **5 case**, sắp xếp theo mức độ quan trọng

**Format cho mỗi case:**

**[Type-Number]** _(ví dụ: UI-1, UX-2, FLOW-3, DATA-4)_
- **Priority:** P0 (chặn launch) / P1 (quan trọng) / P2 (nice-to-have)
- **Situation:** Mô tả bằng ngôn ngữ đơn giản — người không rành kỹ thuật đọc hiểu được
- **Impact:** Case này giúp gì khi xử lý đúng; hậu quả nếu bỏ qua
- **Current:** Hệ thống hiện đang làm gì — ngôn ngữ đơn giản, không có code
- **Gap:** Khác biệt cụ thể giữa hành vi hiện tại và kỳ vọng (hoặc so với Compare product)
- **[Tên sản phẩm] xử lý như sau:** _(chỉ có khi đang so sánh — chỉ ghi những gì quan sát trực tiếp trên web; nếu không tìm thấy → "không tìm thấy trên web" + cách khác để verify)_
- **Proposal:** 1-2 hướng xử lý cụ thể, bằng ngôn ngữ đơn giản

Sau mỗi vòng 5 case:
- Dừng lại và chờ user quyết định từng case
- Cập nhật trực tiếp vào file specs (Decisions, Edge Cases) — không recap, không giải thích thay đổi
- Hỏi: tiếp tục hay dừng?

---

## Bước 4 — Experience Specs

Chỉ làm bước này sau khi user xác nhận không còn edge case nào cần cover nữa. Thêm một section duy nhất vào cuối file specs:

```
### Experience Specs

- **What the user sees:** Mô tả UI cụ thể cho từng state
- **What the user does:** Các hành động theo từng bước
- **Feedback:** User thấy gì ngay sau mỗi hành động
- **States:** Mỗi trạng thái dữ liệu hiển thị trên màn hình như thế nào (ví dụ: pending, completed, error, v.v.)
- **Mobile vs Desktop:** Khác biệt, nếu có
```

---

## Template cho file specs mới

Khi cần tạo file mới:

```md
# [Tên feature] — Feature Spec Draft

---

## Decisions

| #  | Case | Decision |
| -- | ---- | ----------- |

---

## Edge Cases

(sẽ bổ sung sau)

---

## Experience Specs

(sẽ bổ sung sau)

---

## Open Questions

1. ...
```

---

## Hard rules

- **Ngôn ngữ:** tiếng Việt thuần, không thuật ngữ kỹ thuật, không code snippet trong specs; người không rành kỹ thuật đọc hiểu được
- Nếu buộc phải nhắc đến khái niệm kỹ thuật → giải thích ngay sau đó bằng ngôn ngữ đơn giản, trong ngoặc đơn
- **Không so sánh** → bỏ field Compare, tập trung vào gap giữa code hiện tại và kỳ vọng
- **Verify trước khi hỏi:** chỉ hỏi khi code không trả lời được — nếu code đã rõ ràng thì viết thẳng vào Decisions
- Không viết "cần verify" trừ khi đã thực sự tìm mà không thấy
- Luôn đi kèm proposal xử lý với mỗi vấn đề, không chỉ nêu vấn đề suông
- Không recap, không giải thích thay đổi sau khi cập nhật file
- Không ghi timestamp, không ghi version number trong nội dung specs

## Bước tiếp theo

Khi file specs đã xong (hết edge case cần bàn), báo user hướng đi phù hợp với tình huống:
- Specs cho feature còn cần build → đề xuất `/vplan <specs-file>` để biến thành implementation plan.
- User chỉ cần tài liệu, chưa cần build ngay → xác nhận file đã lưu, không cần làm gì thêm.
- Sau này phát sinh edge case mới → chạy lại `/vspecs` trên cùng file để tiếp tục bổ sung.
