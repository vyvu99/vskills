---
name: vplan
description: "Tạo implementation plan từ một file specs có sẵn: đọc specs + scout codebase → so sánh từng case (PASS/FAIL/MISSING) → bổ sung các case baseline còn thiếu → sinh plan.md + phase files, phase nhóm theo case, migration gộp vào phase đầu tiên."
argument-hint: "[specs-file-path]"
user-invocable: true
when_to_use: "Dùng khi đã có sẵn file specs (được tạo bởi vspecs, dạng plans/specs/<feature-slug>.md) và muốn xây implementation plan từ đó."
category: workflow
keywords: [plan, specs, implementation, phases, migration, gap-analysis]
extends: plan
metadata:
  author: vyvu
  version: "1.0.0"
---

> Kế thừa skill `plan` gốc — nhận toàn bộ base workflow (mode detection, cấu trúc plan.md + phase-XX-*.md, red-team, validate, task hydration, post-plan handoff). Điểm khác biệt: input bắt buộc phải là một file specs có sẵn, và trước khi sinh plan phải chạy bước so sánh (gap analysis) giữa specs và code hiện tại để biết chính xác cần thay đổi những gì.

Đọc input từ user:

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` rỗng — dùng `AskUserQuestion` để hỏi đường dẫn file specs (gợi ý mặc định: `plans/specs/<feature-slug>.md`).

Nếu đường dẫn không tồn tại → báo lỗi và dừng. **Không tự tạo specs** — đó là việc của `/vspecs`.

---

## Bước 1 — Đọc specs + Scout codebase (trước khi làm bất cứ gì khác)

1. Đọc TOÀN BỘ file specs được chỉ định — bảng Decisions, Edge Cases, Experience Specs.
2. Scout codebase liên quan đến feature này TRƯỚC khi phân tích: routes, services, schemas, UI components, seed data, các file migration hiện có.
3. Đọc các file khác trong `plans/specs/` (nếu có) để tránh xung đột với specs của các feature liên quan.
4. Xác định `[feature-slug]` (từ tên file specs hoặc tên feature, dạng kebab-case).

---

## Bước 2 — So sánh từng case: specs vs code

Với MỌI case trong specs (mỗi dòng của bảng Decisions, mỗi Edge Case) — **tự mình verify bằng cách đọc code**, không được đoán:

**Format cho mỗi case:**

**[Case ID]** _(giữ nguyên ID/tên đúng như trong specs)_
- **Status:** PASS / FAIL / MISSING
  - PASS — code hiện tại đã hoạt động đúng như specs yêu cầu
  - FAIL — code hiện tại hoạt động khác/sai so với specs
  - MISSING — code hiện tại chưa implement case này
- **Specs requirement:** tóm tắt 1 dòng
- **Current code:** file:line + mô tả hành vi thực tế (chỉ điền sau khi đã đọc code; nếu FAIL/MISSING mà chưa tìm ra — tiếp tục tìm, không được để trống mập mờ)
- **Proposed fix:** (chỉ áp dụng cho FAIL/MISSING) — file nào cần đổi, logic thay đổi cụ thể ra sao

Case PASS chỉ cần xác nhận 1 dòng (file:line), không cần proposed fix.

---

## Bước 3 — Bổ sung các case baseline còn thiếu

Dùng tư duy edge-case tương tự vspecs (input rỗng/null, concurrency, phân quyền, giới hạn số lượng, lỗi network/API, trạng thái trung gian...) nhưng **không hỏi lại user từng case** — đây là giai đoạn planning, không phải brainstorm specs. Tự đề xuất case + status trực tiếp (mặc định MISSING, trừ khi code đã xử lý sẵn) + fix cụ thể, rồi thêm vào danh sách case từ Bước 2 kèm ghi chú `(added beyond specs)`.

---

## Bước 4 — Sinh plan

Tuân theo đúng cấu trúc `plan.md` tổng quan + `phase-XX-*.md` chi tiết theo template chuẩn của skill `plan` gốc (frontmatter phase/title/status/priority/effort/dependencies; các section Overview/Requirements/Architecture/Related Code Files/Implementation Steps/Success Criteria/Risk Assessment).

**Khác biệt so với `plan` mặc định:**

1. **Phase được chia theo NHÓM CASE LIÊN QUAN** (không chia theo file/layer). Ví dụ: "Phase 2: Validate cart item quantity" gộp mọi case liên quan đến giới hạn số lượng, dù các case đó chạm vào route + service + UI khác nhau.
2. Mỗi mục trong Implementation Steps của một phase BẮT BUỘC phải nêu rõ 3 phần, không được mập mờ:
   - **File:** đường dẫn cụ thể
   - **Logic:** thay đổi chính xác cái gì (không viết chung chung "update logic" — phải nêu rõ điều kiện/nhánh/field cụ thể bị thay đổi)
   - **Validate:** test case nào cover nó (nếu repo có test framework) hoặc bước kiểm tra thủ công cụ thể (gọi API nào, check UI nào, xem field DB nào)
3. **Ràng buộc migration (BẮT BUỘC):** nếu bất kỳ case nào (kể cả case thêm ở Bước 3) yêu cầu thay đổi database schema → TẤT CẢ migration liên quan phải được gộp vào duy nhất một **Phase đầu tiên**. Không tạo migration riêng ở phase 2, 3, v.v. Nếu một phase sau phát sinh cần thêm thay đổi schema trong lúc viết plan → quay lại cập nhật Phase 1, không tách thành phase migration mới.
4. Ở đầu `plan.md`, thêm section **"Case Summary"** — một bảng tóm tắt mọi case từ Bước 2 + Bước 3, mỗi dòng: Case ID | Status (PASS/FAIL/MISSING) | Handling Phase (số phase, hoặc "—" nếu PASS và không cần thay đổi gì).

Sau khi hoàn tất plan.md + phase files: tiếp tục đúng Post-Plan Handoff của skill `plan` gốc — dùng `AskUserQuestion` để đề xuất chạy validate/red-team gate của `plan`, implement ngay với `vcook <plan-path>`, hoặc kết thúc session.

## Bước tiếp theo

Khi plan đã viết xong, báo user hướng đi phù hợp với tình huống:
- Plan ổn, không còn câu hỏi mở → đề xuất `/vcook <plan-path>` để implement.
- Plan đụng vùng rủi ro/quan trọng, đáng có thêm 1 lượt kiểm tra → đề xuất chạy validate/red-team gate của skill `plan` trước khi implement.
- Specs còn khoảng trống không suy ra được từ code → đề xuất `/vspecs` để bổ sung trước khi plan tiếp.

---

## Hard rules

- KHÔNG BAO GIỜ viết "cần verify", "chưa rõ", "có thể" cho bất kỳ case nào nếu code có thể đọc được và trả lời được câu hỏi đó — phải tự đọc code trước khi kết luận status.
- Nếu đã tìm kỹ mà không thấy code liên quan → nêu rõ "đã tìm tại {path/pattern}, không thấy" thay vì để trống.
- Migration phải gộp vào duy nhất Phase 1 — không ngoại lệ, không tạo file migration riêng ở phase khác.
- Mỗi mục trong Implementation Steps phải có File + Logic + Validate đầy đủ, cụ thể — KHÔNG BAO GIỜ viết chung chung kiểu "fix cho đúng" hay "test lại".
- KHÔNG BAO GIỜ tự tạo hoặc sửa file specs — nếu phát hiện specs thiếu một case quan trọng cần user quyết định (thứ không thể suy ra từ code) → dừng lại và đề xuất chạy `/vspecs` để bổ sung trước khi tiếp tục.
- KHÔNG BAO GIỜ bỏ qua Bước 1 (scout codebase) dù case trông có vẻ đơn giản — status PASS/FAIL/MISSING chỉ hợp lệ khi đã thực sự đọc code thật.
