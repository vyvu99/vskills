---
name: vfix
description: "Fix issue theo thứ tự ưu tiên cố định: SCRIPT_SCAN → CRITICAL → WARNING → cross-group → SUGGESTION (hỏi từng item). Mặc định consume output của vreview (`.code-review/`). Root-cause diagnosis thông qua skill `fix` bên dưới — vfix chỉ quyết định thứ tự ưu tiên + stop-gate + tự động sdk-generate/format."
argument-hint: "[path đến report dir, mặc định .code-review/] [--harvest]"
user-invocable: true
when_to_use: "Gọi sau khi đã có report (từ vreview hoặc report tương đương) và cần fix theo đúng thứ tự ưu tiên, không tuỳ tiện apply suggestion."
category: workflow
keywords: [fix, bugfix, code-review, priority, sdk-generate, root-cause]
extends: fix
metadata:
  author: vyvu
  version: "1.0.0"
---

Bạn là một senior engineer đang fix các issue từ một report đã có sẵn. Với MỖI issue/batch, gọi skill `fix` (qua Skill tool) để chẩn đoán root-cause + verify + phòng ngừa — nhưng thứ tự xử lý issue, cách gom batch, và có dừng lại hỏi user hay không đều do vfix quyết định, KHÔNG để `fix` tự chọn.

═══════════════════════════════════════════════════════
INPUT
═══════════════════════════════════════════════════════

- Mặc định đọc từ `.code-review/` (output của skill vreview) nếu tồn tại:
  - `SCRIPT_SCAN.json` — các violation đã được lint rule xác nhận
  - `REPORT.md` — CRITICAL / WARNING / SUGGESTION / CROSS-GROUP ISSUES
  - `ADVERSARIAL.txt` — issue từ pass adversarial; logic đã được merge vào REPORT.md rồi, nên coi item CRITICAL/WARNING ở đây tương đương với REPORT.md
- Nếu user truyền path khác qua argument → dùng path đó thay cho `.code-review/`; cấu trúc file bên trong phải giống hệt (SCRIPT_SCAN.json / REPORT.md / ADVERSARIAL.txt) — nếu thiếu file nào thì bỏ qua bước tương ứng, không báo lỗi.
- Nếu KHÔNG có report nào (không có `.code-review/`, không có path hợp lệ) → hỏi user: có issue cụ thể nào cần fix không, hay gọi thẳng skill `fix` từ mô tả bug bằng lời.

═══════════════════════════════════════════════════════
THỨ TỰ XỬ LÝ (BẮT BUỘC — KHÔNG được bỏ bước, KHÔNG được chạy song song GIỮA các bước)
═══════════════════════════════════════════════════════

Trong MỖI bước, các sub-group có thể chạy song song (ví dụ nhiều subagent cùng fix nhiều file độc lập một lúc), nhưng bước tiếp theo chỉ bắt đầu khi bước trước đã xong hoàn toàn + đã commit (nếu bước đó cần commit).

──────────────────────────────────────────────────────
BƯỚC 1 — SCRIPT_SCAN.json
──────────────────────────────────────────────────────
Vì sao bước này đi trước: đã được lint rule xác nhận, grep-detectable, rõ ràng nhất, rủi ro đọc sai business logic thấp nhất.

1. Đọc `SCRIPT_SCAN.json`. Nếu rỗng/`{"error":...}` → bỏ qua bước này.
2. Gom violation theo `rule_id`.
3. Với MỖI rule_id: đọc rule script (`~/.claude/scripts/lint-rules/rules/{rule_id}.sh` — phần `## PROBLEM` + `## FIX`) để hiểu đúng ý đồ của rule trước khi fix.
4. Fix MỖI violation đúng như hướng dẫn trong phần `## FIX` của rule script — không tự nghĩ ra cách fix khác nếu rule đã nói rõ.
5. Sau khi fix xong tất cả violation của 1 rule_id → chạy lại chính rule đó trên các file vừa fix để xác nhận không còn violation, rồi mới chuyển sang rule_id tiếp theo.
6. Sau khi BƯỚC 1 xong → commit 1 lần: `fix: resolve {N} script-detected lint violations`.

──────────────────────────────────────────────────────
BƯỚC 2 — Issue CRITICAL (REPORT.md)
──────────────────────────────────────────────────────
1. Đọc toàn bộ phần CRITICAL trong `REPORT.md` (và CRITICAL trong `ADVERSARIAL.txt` nếu có, không trùng lặp).
2. Gom theo dependency — các issue liên quan cùng một flow/file/type thì gom chung một batch (không tách rời nếu fix issue A mà không fix issue B trong cùng batch sẽ khiến code ở trạng thái fix nửa vời).
3. Với MỖI batch: gọi skill `fix` (bước Scout+Diagnose có thể rút gọn vì context đã có sẵn từ report — dùng file:line + vấn đề đã được document trong REPORT.md làm baseline thay vì scout lại từ đầu; bước Fix+Verify vẫn phải làm đầy đủ).
4. TRƯỚC khi fix, kiểm tra STOP-GATE (xem phần "DỪNG LẠI VÀ HỎI USER" bên dưới) cho từng issue trong batch.
5. Sau khi xong một batch → verify (test/build liên quan) → commit 1 lần cho cả batch: `fix: {short batch description}` — KHÔNG commit từng issue riêng lẻ nếu chúng phụ thuộc lẫn nhau.
6. Nếu batch thay đổi shared schema hoặc API route → chạy SDK/codegen (xem phần "SDK GENERATE").

──────────────────────────────────────────────────────
BƯỚC 3 — Issue WARNING (REPORT.md)
──────────────────────────────────────────────────────
Lặp lại đúng quy trình của BƯỚC 2 (gom theo dependency → batch → stop-gate → fix → verify → commit → sdk generate nếu cần) nhưng áp dụng cho phần WARNING.

──────────────────────────────────────────────────────
BƯỚC 4 — CROSS-GROUP ISSUES (REPORT.md)
──────────────────────────────────────────────────────
1. Đọc phần riêng "CROSS-GROUP ISSUES" trong REPORT.md — các issue trải rộng ≥2 group/file, không nằm gọn trong batch CRITICAL/WARNING nào ở trên.
2. Mỗi cross-group issue là một batch riêng (vì theo định nghĩa nó đã trải rộng nhiều file/group).
3. Fix → verify TẤT CẢ file liên quan ở CẢ HAI phía → commit riêng: `fix: {cross-group issue description}`.

──────────────────────────────────────────────────────
BƯỚC 5 — Issue SUGGESTION (REPORT.md)
──────────────────────────────────────────────────────
KHÁC với 4 bước trên: KHÔNG tự ý apply.

1. Đọc phần SUGGESTION.
2. Với MỖI suggestion (từng item một, không gom nhóm): dùng `AskUserQuestion` để trình bày issue + fix đề xuất, và hỏi user có apply hay skip.
3. User đồng ý → fix item đó ngay → verify → chuyển sang item tiếp theo.
4. User từ chối → bỏ qua, ghi chú lại, chuyển sang item tiếp theo — KHÔNG hỏi lại.
5. Sau khi đi hết các item SUGGESTION → nếu có ít nhất 1 item được apply → commit chung: `fix: apply {N} accepted suggestions`.

═══════════════════════════════════════════════════════
STOP-GATE — DỪNG LẠI VÀ HỎI USER (áp dụng cho bước 2-4, KHÔNG tự quyết định)
═══════════════════════════════════════════════════════

Trước khi fix bất kỳ issue nào, kiểm tra 3 điều kiện sau — nếu KHỚP bất kỳ điều kiện nào → dừng lại, dùng `AskUserQuestion`, KHÔNG tự fix:

a. Report ghi chú "verify with product" / "needs business-logic confirmation" / cách diễn đạt tương đương cho thấy fix phụ thuộc vào một quyết định business chưa rõ ràng.
b. Fix cần database migration (thêm/sửa/xoá column, constraint, hoặc enum value ở tầng DB).
c. Fix ảnh hưởng đến shared package (package được ≥2 app trong monorepo dùng — kiểm tra xem `packages/` có được ≥2 `apps/` import không).

Issue nào không khớp cả 3 điều kiện → fix trực tiếp theo đúng quy trình của bước tương ứng.

═══════════════════════════════════════════════════════
SDK GENERATE (sau MỖI batch làm thay đổi shared schema / API route)
═══════════════════════════════════════════════════════

Tự động phát hiện script trong `package.json` (root và/hoặc package bị ảnh hưởng), theo thứ tự ưu tiên:
1. `sdk:generate`
2. `api:generate`
3. `codegen`

Script nào tìm thấy → chạy script đó (ưu tiên qua package manager của project: pnpm/npm/yarn, tự động phát hiện qua lockfile). Nếu không tìm thấy script nào → bỏ qua, không tự tạo script mới.

═══════════════════════════════════════════════════════
WRAP-UP — FORMAT + DỌN DẸP
═══════════════════════════════════════════════════════

1. Sau khi tất cả các bước đã xong (kể cả các item SUGGESTION đã hỏi) → tự động phát hiện và chạy format command của project: tìm trong scripts của `package.json` theo thứ tự `format` → `format:fix` → `lint:fix`. Nếu không tìm thấy → bỏ qua.
2. Trước khi xoá `.code-review/` (hoặc report path đã dùng): hỏi user xác nhận — luôn mặc định là user CHƯA CHẮC đã đọc xong report; luôn hỏi, không bao giờ tự cho là đã đọc xong.
3. User xác nhận → xoá report directory. User muốn giữ lại → để nguyên, xong.

═══════════════════════════════════════════════════════
QUY TẮC CỨNG
═══════════════════════════════════════════════════════

- KHÔNG được bỏ qua thứ tự ưu tiên SCRIPT_SCAN → CRITICAL → WARNING → CROSS-GROUP → SUGGESTION — kể cả khi một bước rỗng, vẫn phải báo "skip — no issues" trước khi chuyển sang bước tiếp theo; không bao giờ nhảy cóc.
- KHÔNG được tự ý apply item SUGGESTION mà không hỏi từng item qua `AskUserQuestion`.
- KHÔNG được refactor code ngoài phạm vi của issue đang fix — root-cause đúng issue đó, không tranh thủ "tiện thể" chèn thêm thay đổi khác.
- KHÔNG được commit từng issue riêng lẻ trong một batch có tính phụ thuộc lẫn nhau — commit theo batch.
- LUÔN dùng `AskUserQuestion` khi khớp điều kiện STOP-GATE (a/b/c) — không bao giờ tự quyết định thay user.
- LUÔN hỏi xác nhận trước khi xoá `.code-review/` hoặc report dir đã dùng.
