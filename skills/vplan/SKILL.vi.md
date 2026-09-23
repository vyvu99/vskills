---
name: vplan
description: "Tạo implementation plan từ một file specs có sẵn: đọc specs + scout codebase → so sánh từng case (PASS/FAIL/MISSING) → bổ sung các case baseline còn thiếu → sinh plan.md + phase files, phase nhóm theo case, migration gộp vào phase đầu tiên."
argument-hint: "[specs-file-path]"
user-invocable: true
when_to_use: "Dùng khi đã có sẵn file specs (được tạo bởi vspecs, dạng plans/specs/<feature-slug>.md) và muốn xây implementation plan từ đó."
metadata:
  author: vyvu
  version: "1.0.0"
---

> Input bắt buộc phải là một file specs có sẵn, và trước khi sinh plan phải chạy bước so sánh (gap analysis) giữa specs và code hiện tại để biết chính xác cần thay đổi những gì.

Đọc input từ user:

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` rỗng — dùng `AskUserQuestion` để hỏi đường dẫn file specs (gợi ý mặc định: `plans/specs/<feature-slug>.md`).

Nếu đường dẫn không tồn tại → báo lỗi và dừng. **Không tự tạo specs** — đó là việc của `/vspecs`.

---

## Bước 1 — Đọc specs + Scout codebase (trước khi làm bất cứ gì khác)

1. Đọc TOÀN BỘ file specs được chỉ định — bảng Decisions, Edge Cases, Experience Specs.
2. Scout codebase liên quan đến feature này TRƯỚC khi phân tích: routes, services, schemas, UI components, seed data, các file migration hiện có. Scout được delegate cho subagent → findings của nó ghi ra `plans/reports/` theo `_vskills-shared/repo-profile.md` §6.
3. Đọc các file khác trong `plans/specs/` (nếu có) để tránh xung đột với specs của feature liên quan.
4. Xác định `[feature-slug]` (từ tên file specs hoặc tên feature, dạng kebab-case).

---

## Bước 2 — So sánh từng case: specs vs code

Với MỌI case trong specs (mỗi dòng của bảng Decisions, mỗi Edge Case) — **tự mình verify bằng cách đọc code**, không được đoán:

Ngay khi verdict PASS/FAIL/MISSING của một case được xác định, ghi luôn dòng đó vào bảng Case Summary của `plan.md` đang được dựng dở (tạo file này ngay từ đầu Bước 2 nếu chưa có) thay vì giữ toàn bộ so sánh trong bộ nhớ hội thoại tới tận Bước 4. Handling Phase / Effort cứ để trống — Bước 4 sẽ điền sau khi phase được gán.

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

Sinh `plan.md` tổng quan + mỗi phase một file `phase-XX-*.md` chi tiết, theo đúng khung mẫu literal bên dưới. Bảng Case Summary đã được khởi tạo từ Bước 2 — bước này chỉ còn điền bảng Phases, Key Dependencies, Risks/Rollback, và từng phase file, cộng thêm cột Handling Phase / Effort còn để trống từ Bước 2.

**Khung mẫu `plan.md`:**

```markdown
# <Feature Name> — Implementation Plan

**Generated against commit:** <short-sha>  <!-- lấy từ `git rev-parse --short HEAD` lúc sinh plan -->

## Case Summary

| Case ID | Status | Handling Phase | Effort |
|---|---|---|---|
| <id> | PASS / FAIL / MISSING | phase-N hoặc "—" | S/M/L hoặc "—" |

## Phases

| Phase | Title | Status | Dependencies |
|---|---|---|---|
| Phase 1 | <title> | pending | — |
| Phase 2 | <title> | pending | Phase 1 |

## Key Dependencies

- <dependency giữa các phase hoặc bên ngoài>

## Risks / Rollback

### Phase 1
- **Nếu fail giữa chừng:** <state còn lại — code/DB>
- **Rollback:** <cách undo>
```

**Khung mẫu `phase-XX-*.md`:**

```markdown
---
phase: 1
title: "<phase title>"
status: pending
priority: high | medium | low
effort: S | M | L
dependencies: []
---

## Overview
<1-2 câu: phase này làm gì, tại sao>

## Requirements
- <functional/non-functional requirement>

## Architecture
<tương tác giữa các component, data flow liên quan đến phase này>

## Related Code Files
- <file cần sửa/tạo/xóa>

## Implementation Steps
1. **File:** <path>
   **Logic:** <điều kiện/nhánh/field cụ thể bị thay đổi>
   **Validate:** <tên test cụ thể (red→green), hoặc lệnh verify thủ công + kết quả kỳ vọng>

## Success Criteria
- <definition of done>

## Risk Assessment
- <rủi ro tiềm ẩn + cách mitigate>
```

Stamp `**Generated against commit:**` tồn tại để người đọc (hoặc `vcook` khi implement plan sau này) biết được các file:line trong plan đã cũ đến mức nào. `vcook` nên coi việc stamp này lệch với HEAD hiện tại là tín hiệu phải re-verify lại các case PASS trước khi tin, không được mặc định chúng vẫn còn đúng.

**Quy tắc ngoài khung mẫu:**

1. **Phase được chia theo NHÓM CASE LIÊN QUAN** (không chia theo file/layer). Ví dụ: "Phase 2: Validate cart item quantity" gộp mọi case liên quan đến giới hạn số lượng, dù các case đó chạm route + service + UI khác nhau.
2. Mỗi mục trong Implementation Steps của một phase BẮT BUỘC phải nêu rõ 3 phần, không được mập mờ:
   - **File:** đường dẫn cụ thể
   - **Logic:** thay đổi chính xác cái gì (không bao giờ viết chung chung "update logic" — nêu rõ điều kiện/nhánh/field cụ thể bị thay đổi)
   - **Validate:** repo có test framework → nêu tên test cụ thể (có sẵn hoặc mới viết), nói rõ phải fail trước khi sửa (red) và pass sau khi sửa (green); không có test framework → một bước/lệnh verify thủ công cụ thể kèm kết quả kỳ vọng nêu rõ ràng (không viết "check UI" chung chung — phải là kết quả chính xác xác nhận thành công)
3. **Quy tắc gộp migration:** migration mặc định gộp vào duy nhất một **Phase đầu tiên**. Tách một migration sang phase của case riêng chỉ khi nó thực sự độc lập (không chung table/key) với các migration khác ở Phase 1 — phải nêu rõ tính độc lập đó. Một phase sau phát sinh cần thêm thay đổi schema không độc lập trong lúc viết plan → quay lại cập nhật Phase 1, không tách thành phase migration mới.
4. Ở đầu `plan.md`, bảng **"Case Summary"** tóm tắt mọi case từ Bước 2 + Bước 3: Case ID | Status (PASS/FAIL/MISSING) | Handling Phase (số phase, hoặc "—" nếu PASS và không cần thay đổi gì) | Effort (giá trị frontmatter `effort` của phase xử lý; "—" cho dòng PASS). Effort là ước tính sizing tương đối thô, không calibrated — một bucket thô (S/M/L), tuyệt đối không phải con số giờ tưởng-chính-xác hay một lời hứa timeline.
5. Điền `## Risks / Rollback` cho MỌI phase, không chỉ Phase 1 — nêu rõ nếu phase đó fail giữa chừng thì state (code/DB) còn lại là gì, và cách rollback ra sao.

---

## Bước 5 — Cross-check plan

Sau khi sinh xong plan.md + phase files, trước khi handoff, verify:

1. Mọi Case ID từ Bước 2 + Bước 3 xuất hiện đúng một lần trong bảng Case Summary.
2. Mọi case FAIL/MISSING đều có Handling Phase.
3. Mọi phase đều trace về ít nhất một case trong Case Summary — phase tracing về không case nào bị đánh dấu là scope creep tiềm ẩn.

Sửa plan.md/phase files cho check nào fail, trước khi tiếp tục.

Sau đó handoff — dùng `AskUserQuestion` để đề xuất: (a) implement ngay với `vcook <plan-path>`, (b) tạo GitHub tracking issues trước với `vtickets <plan-dir>`, hoặc (c) kết thúc session.

## Bước tiếp theo

Theo đúng convention Next Steps ở `_vskills-shared/repo-profile.md` §7.

---

## Hard rules

- Xem `_vskills-shared/repo-profile.md` §8 (Verification honesty rule).
- Đã tìm kỹ mà không thấy code liên quan → nêu rõ "đã tìm tại {path/pattern}, không thấy" thay vì để trống.
- Migration mặc định gộp vào duy nhất Phase 1 — chỉ tách sang phase riêng khi migration đó thực sự độc lập (không chung table/key) với các migration khác ở Phase 1, và phải nêu rõ điều đó.
- Mỗi mục trong Implementation Steps phải có File + Logic + Validate đầy đủ, cụ thể — KHÔNG BAO GIỜ chung chung kiểu "fix cho đúng" hay "test lại".
- KHÔNG BAO GIỜ tự tạo hoặc sửa file specs — specs thiếu một case quan trọng cần user quyết định (không suy ra được từ code) → dừng lại, đề xuất chạy `/vspecs` để bổ sung trước khi tiếp tục.
- KHÔNG BAO GIỜ bỏ qua Bước 1 (scout codebase) dù case trông có vẻ đơn giản — status PASS/FAIL/MISSING chỉ hợp lệ khi đã thực sự đọc code thật.
