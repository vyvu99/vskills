---
name: vplan
description: "Biến một file specs có sẵn (plans/specs/<feature-slug>.md, do vspecs tạo) thành implementation plan: so sánh từng case của specs với code hiện tại theo PASS, FAIL hoặc MISSING, rồi viết plan.md và các phase file nhóm theo case. Không viết specs và không sửa code."
argument-hint: "[specs-file-path]"
user-invocable: true
when_to_use: "Dùng khi đã có file specs của vspecs và user muốn có plan, phân tích khoảng cách giữa specs và code, hoặc các phase để đưa cho vcook."
metadata:
  author: vyvu
  version: "2.0.0"
---

Input là một file specs có sẵn. So sánh nó với code hiện tại trước khi lập plan, để plan bao đúng những gì cần thay đổi.

Đọc input:

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` rỗng, hỏi bằng `AskUserQuestion` đường dẫn specs (gợi ý `plans/specs/<feature-slug>.md`). Nếu đường dẫn không tồn tại thì báo và dừng; tạo specs là việc của `/vspecs`, không phải của skill này.

**Phạm vi:** skill này chỉ ghi `plans/<feature-slug>/plan.md` và các phase file của nó. Không sửa file specs hay bất kỳ source code nào.

## Bước 1 - Đọc specs và scout code

1. Đọc toàn bộ file specs: Decisions, Edge Cases, Experience Specs.
2. Scout code của feature trước khi kết luận bất cứ điều gì: routes, services, schemas, UI components, seed data, migration hiện có. Chỉ delegate scout cho subagent khi nó trải trên nhiều vùng; vài file thì tự đọc. Brief cho subagent nêu feature, các vùng cần phủ, việc subagent chỉ được đọc, và file báo cáo nó ghi dưới `plans/reports/` (`_vskills-shared/repo-profile.md` §6); đọc lại file đó.
3. Đọc các file khác trong `plans/specs/` để không xung đột với feature liên quan.
4. Suy ra `[feature-slug]` (kebab-case) từ tên file hoặc tên feature.

## Bước 2 - So sánh từng case với code

Tự verify mọi case (mỗi dòng Decisions và mỗi Edge Case) bằng cách đọc code; verdict từ trí nhớ không hợp lệ. Tạo `plans/<feature-slug>/plan.md` ngay đầu bước này và thêm dòng của từng case vào bảng Case Summary ngay khi có verdict, để trống Handling Phase và Effort đến Bước 4.

Với mỗi case, giữ nguyên ID và tên trong specs:
- **Status:** PASS (code đã hành xử đúng specs), FAIL (code hành xử khác) hoặc MISSING (chưa implement).
- **Specs requirement:** một dòng.
- **Current code:** file:line và hành vi thực tế. Với FAIL hoặc MISSING hãy tìm đến khi thấy; nếu tìm thật sự không có thì ghi "searched at {path/pattern}, not found" (§8).
- **Proposed fix:** chỉ cho FAIL và MISSING: file nào đổi và logic nào đổi.

Case PASS chỉ cần xác nhận một dòng kèm file:line.

## Bước 3 - Bổ sung case baseline còn thiếu

Nghĩ qua các khoảng trống thường gặp (input rỗng hoặc null, đồng thời, phân quyền, giới hạn, lỗi mạng hoặc API, trạng thái trung gian) mà không hỏi user, vì đây là lập plan chứ không phải brainstorm specs. Thêm tối đa 5 case như vậy, mỗi case có status (MISSING trừ khi code đã xử lý), một fix cụ thể và ghi chú `(added beyond specs)`. Giới hạn này giữ plan không phình vượt quá những gì user đã duyệt; nếu còn nhiều khoảng trống hơn thì ghi vào tin nhắn handoff kèm gợi ý chạy `/vspecs`.

## Bước 4 - Sinh plan

Viết `plan.md` và một `phase-XX-*.md` cho mỗi phase. Bảng Case Summary đã có từ Bước 2; điền bảng Phases, Key Dependencies, Risks / Rollback, từng phase file và các cột Handling Phase, Effort.

**Skeleton `plan.md`:**

```markdown
# <Feature Name> — Implementation Plan

**Generated against commit:** <short-sha>  <!-- from `git rev-parse --short HEAD` at generation time -->

## Case Summary

| Case ID | Status | Handling Phase | Effort |
|---|---|---|---|
| <id> | PASS / FAIL / MISSING | phase-N or "—" | S/M/L or "—" |

## Phases

| Phase | Title | Status | Dependencies |
|---|---|---|---|
| Phase 1 | <title> | pending | — |
| Phase 2 | <title> | pending | Phase 1 |

## Key Dependencies

- <cross-phase or external dependency>

## Risks / Rollback

### Phase 1
- **If it fails partway:** <state left behind — code/DB>
- **Rollback:** <how to undo>
```

**Skeleton `phase-XX-*.md`:**

```markdown
---
phase: 1
title: "<phase title>"
priority: high | medium | low
effort: S | M | L
dependencies: []
---

## Overview
<1-2 sentences: what this phase does and why>

## Requirements
- <functional/non-functional requirement>

## Architecture
<component interactions, data flow relevant to this phase>

## Related Code Files
- <file to modify/create/delete>

## Implementation Steps
1. **File:** <path>
   **Logic:** <exact condition/branch/field changed>
   **Validate:** <specific test name (red→green), or manual verify command + expected result>

## Success Criteria
- <definition of done>

## Risk Assessment
- <potential issue + mitigation>
```

Stamp commit cho người đọc, hoặc `vcook` chạy plan sau này, biết các tham chiếu file:line có thể cũ đến đâu; `vcook` re-verify các case PASS khi stamp lệch HEAD.

**Rule ngoài skeleton:**

1. Chia phase theo nhóm case liên quan, không theo file hay layer. "Validate số lượng item trong giỏ" là một phase dù chạm nhiều route, service và UI.
2. Mỗi Implementation Step có đủ ba phần, vì step mơ hồ buộc người implement phải đoán:
   - **File:** đường dẫn chính xác.
   - **Logic:** điều kiện, nhánh hoặc field cụ thể thay đổi, không bao giờ viết "update logic".
   - **Validate:** có test framework thì nêu test cụ thể (có sẵn hoặc mới), fail trước khi đổi và pass sau; không có thì nêu lệnh hoặc bước cụ thể cùng quan sát chính xác xác nhận thành công, không viết "check the UI".
3. Migration nằm ở phase đầu, để mọi phase sau xây trên schema đã hoàn chỉnh. Chỉ tách migration thành phase riêng khi nó độc lập (không chung table hay key) với migration của Phase 1, và nói rõ lý do. Phase sau cần thêm thay đổi schema thì quay lại sửa Phase 1.
4. Case Summary bao mọi case từ Bước 2 và 3: Case ID, Status, Handling Phase (số phase, hoặc "—" cho PASS không cần đổi) và Effort (giá trị `effort` của phase đó, "—" cho PASS). Effort là bucket S/M/L thô, không bao giờ là số giờ hay ngày hứa hẹn.
5. Status của phase chỉ nằm trong bảng Phases của `plan.md`, nên không thể lệch với bản sao trong phase file. Điền Risks / Rollback cho mọi phase: trạng thái để lại nếu fail giữa chừng và cách hoàn tác.

## Bước 5 - Cross-check plan

Trước khi handoff, kiểm tra và sửa mọi chỗ fail:
1. Mọi Case ID từ Bước 2 và 3 xuất hiện đúng một lần trong Case Summary.
2. Mọi case FAIL hoặc MISSING có Handling Phase.
3. Mọi phase truy ngược được về ít nhất một case; phase không truy về case nào có thể là scope creep.

Nếu specs thiếu một case cần user quyết (không suy ra được từ code) thì dừng và gợi ý `/vspecs` để bổ sung.

Sau đó đề xuất bằng `AskUserQuestion`: (a) implement ngay bằng `vcook <plan-path>`, (b) tạo GitHub tracking issue trước bằng `vtickets <plan-dir>`, hoặc (c) kết thúc session.

## Next steps

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
