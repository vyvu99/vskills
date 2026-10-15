# Chế độ fix (`vreview --fix`)

CHỈ nạp khi user truyền `--fix` một cách tường minh. Một lần review thường không bao giờ đọc file này và không bao giờ sửa code.

Bạn giờ là một senior engineer đang fix các issue từ một report đã có sẵn. Với MỖI issue/batch, gọi skill `fix` (qua Skill tool) để chẩn đoán root-cause + verify + phòng ngừa — nhưng thứ tự xử lý issue, cách gom batch, và có dừng lại hỏi user hay không đều do file này quyết định, KHÔNG để `fix` tự chọn.

═══════════════════════════════════════════════════════
INPUT
═══════════════════════════════════════════════════════

- Đọc từ report directory đang dùng: mặc định `.code-review/` (lần review vừa xong trong run này), hoặc thư mục user truyền làm positional argument (thư mục đã tồn tại và chứa `REPORT.md`):
  - `SCRIPT_SCAN.json` — các violation đã được lint rule xác nhận
  - `REPORT.md` — CRITICAL / WARNING / SUGGESTION / CROSS-GROUP ISSUES
  - `ADVERSARIAL.txt` — issue từ pass adversarial; logic đã được merge vào REPORT.md rồi, nên coi item CRITICAL/WARNING ở đây tương đương với REPORT.md
- Thiếu file nào thì bỏ qua bước tương ứng, không báo lỗi. Mọi chỗ nhắc `.code-review/` bên dưới đều hiểu là thư mục đang dùng.
- KHÔNG có report nào (không có `.code-review/`, không có path hợp lệ) → hỏi user: có issue cụ thể nào cần fix không, hay gọi thẳng skill `fix` từ mô tả bug bằng lời.

═══════════════════════════════════════════════════════
THỨ TỰ XỬ LÝ (BẮT BUỘC — KHÔNG được bỏ bước, KHÔNG được chạy song song GIỮA các bước)
═══════════════════════════════════════════════════════

Trong MỖI bước, các sub-group có thể chạy song song (ví dụ nhiều subagent cùng fix nhiều file độc lập một lúc — mỗi fixer gộp lý do root-cause của mình vào nội dung commit message), nhưng bước tiếp theo chỉ bắt đầu khi bước trước đã xong hoàn toàn + đã commit (nếu bước đó cần commit).

──────────────────────────────────────────────────────
BƯỚC 1 — SCRIPT_SCAN.json
──────────────────────────────────────────────────────
Vì sao bước này đi trước: đã được lint rule xác nhận, grep-detectable, rõ ràng nhất, rủi ro đọc sai business logic thấp nhất.

1. Đọc `SCRIPT_SCAN.json`. Rỗng/`{"error":...}` → bỏ qua bước này.
2. Gom violation theo `rule_id`.
3. Với MỖI rule_id: đọc rule script (`~/.claude/scripts/lint-rules/rules/{rule_id}.sh` — phần `## PROBLEM` + `## FIX`) để hiểu đúng ý đồ của rule trước khi fix. Rule script không tồn tại → suy luận ý đồ từ field `message` của rule_id đó trong `~/.claude/scripts/lint-rules/config/rule-registry.json`; field đó cũng không có → bỏ qua rule_id đó và ghi chú vào report thay vì làm fail cả bước.
4. TRƯỚC khi fix một rule_id, kiểm tra STOP-GATE cho các file nó đụng tới.
5. Fix MỖI violation đúng như hướng dẫn trong phần `## FIX` của rule script — không tự nghĩ ra cách fix khác nếu rule đã nói rõ. Nếu áp dụng đúng `## FIX` mà gây fail test/typecheck, KHÔNG tự nghĩ ra cách fix khác — dừng lại, báo cáo "FIX guidance của rule `<rule_id>` có vẻ sai với case này," và đề xuất chạy `vreview --harvest` để siết lại rule đó, thay vì tự vá vòng qua nó.
6. Sau khi fix xong tất cả violation của 1 rule_id → chạy lại chính rule đó trên các file vừa fix để xác nhận không còn violation, rồi mới chuyển sang rule_id tiếp theo.
7. BƯỚC 1 xong → commit 1 lần: `fix: resolve {N} script-detected lint violations`.

──────────────────────────────────────────────────────
BƯỚC 2 — Issue CRITICAL (REPORT.md)
──────────────────────────────────────────────────────
1. Đọc toàn bộ phần CRITICAL trong `REPORT.md` (và CRITICAL trong `ADVERSARIAL.txt` nếu có, không trùng lặp).
2. Gom theo dependency — các issue liên quan cùng một flow/file/type thì gom chung một batch (không tách rời nếu fix issue A mà không fix issue B trong cùng batch sẽ khiến code ở trạng thái fix nửa vời).
3. Với MỖI batch: gọi skill `fix` (bước Scout+Diagnose có thể rút gọn vì context đã có sẵn từ report — dùng file:line + vấn đề đã được document trong REPORT.md làm baseline thay vì scout lại từ đầu; bước Fix+Verify vẫn phải làm đầy đủ).
4. TRƯỚC khi fix, kiểm tra STOP-GATE (xem bên dưới) cho từng issue trong batch.
5. Sau khi xong một batch → verify (test/build liên quan) → commit 1 lần cho cả batch: `fix: {short batch description}` — KHÔNG commit từng issue riêng lẻ nếu chúng phụ thuộc lẫn nhau.
6. Batch thay đổi shared schema hoặc API route → chạy SDK/codegen (xem "SDK GENERATE") TRƯỚC khi commit để output sinh ra nằm trong commit của chính batch đó.
7. Khi quyết định outcome của từng item, ghi chú lại (fix / reject / defer) nhưng CHƯA ghi `Status:` vội. Ngay sau khi **commit của riêng từng batch** hoàn tất (không phải một lần cho cả bước), đi một lượt qua từng item vừa xử lý và cập nhật dòng `Status:` của nó trong `.code-review/REPORT.md` thành `FIXED (commit <sha>)` (dùng sha commit thật của batch đó) / `REJECTED (<lý do ngắn gọn>)` / `DEFERRED (<lý do ngắn gọn>)`.

──────────────────────────────────────────────────────
BƯỚC 3 — Issue WARNING (REPORT.md)
──────────────────────────────────────────────────────
Lặp lại đúng quy trình của BƯỚC 2 (gom theo dependency → batch → stop-gate → fix → verify → commit → sdk generate nếu cần → ghi `Status:` ngay sau khi **commit của riêng từng batch** hoàn tất) nhưng áp dụng cho phần WARNING.

──────────────────────────────────────────────────────
BƯỚC 4 — CROSS-GROUP ISSUES (REPORT.md)
──────────────────────────────────────────────────────
0. Trước khi fix, kiểm tra STOP-GATE.
1. Đọc phần riêng "CROSS-GROUP ISSUES" trong REPORT.md — các issue trải rộng ≥2 group/file, không nằm gọn trong batch CRITICAL/WARNING nào ở trên.
2. Mỗi cross-group issue là một batch riêng (vì theo định nghĩa nó đã trải rộng nhiều file/group).
3. Fix → verify TẤT CẢ file liên quan ở CẢ HAI phía → commit riêng: `fix: {cross-group issue description}`.
4. Một trong hai phía thay đổi shared schema hoặc API route → chạy SDK/codegen (xem "SDK GENERATE") trước khi commit.
5. Áp dụng đúng rule ghi `Status:` write-back như Bước 2 điểm 7 — ghi chú outcome, rồi cập nhật `.code-review/REPORT.md` ngay sau khi commit của riêng batch đó hoàn tất.

──────────────────────────────────────────────────────
BƯỚC 5 — Issue SUGGESTION (REPORT.md)
──────────────────────────────────────────────────────
KHÁC với 4 bước trên: KHÔNG tự ý apply.

1. Đọc phần SUGGESTION.
2. Hỏi đúng 1 `AskUserQuestion` để chọn chế độ duyệt (nội dung theo `~/.claude/skills/_vskills-shared/webapp-templates.md` mục (c)): **webapp** hay **từng item một** (cách cũ).
   - **Từng item một (cách cũ)** — với MỖI suggestion (từng item một, không gom nhóm): dùng `AskUserQuestion` để trình bày issue + fix đề xuất, và hỏi user có apply hay skip.
   - **Webapp** — build 1 field `diff-review-list` chứa hết toàn bộ item SUGGESTION theo `~/.claude/skills/_vskills-shared/webapp-templates.md` mục (a): `id` = `SUGGESTION-{n}` (`n` = số thứ tự item trong phần SUGGESTIONS), `before` = text `Issue:` cộng với code hiện tại đọc lại từ `File:line` (REPORT.md không có sẵn khối "code hiện tại" như `Fix:` — phải đọc file), `after` = text/code trong `Fix:`, `actions: ["apply","skip"]`, `allowFreeText: true`. Health-check + start webapp theo mục (b) nếu chưa chạy, `POST /api/step` (Bash `run_in_background: true`), rồi lặp qua mảng quyết định trả về theo đúng thứ tự.
3. User đồng ý (từng item một: trả lời apply; webapp: `action: "apply"` không kèm `freeText`) → kiểm tra STOP-GATE cho item đó → fix ngay → verify → ghi `Status: FIXED (pending commit)` → chuyển sang item tiếp theo.
4. User từ chối (từng item một: trả lời skip; webapp: `action: "skip"`) → ghi `Status: REJECTED (<lý do ngắn gọn>)` ngay (không phụ thuộc commit) → chuyển sang item tiếp theo — KHÔNG hỏi lại.
5. Chỉ ở mode webapp, item có `freeText` (bất kể `action` là gì) → coi free text là chỉ dẫn bổ sung, gọi skill `fix` cho item đó kèm chỉ dẫn này thay vì áp fix mặc định trong `Fix:` → kiểm tra STOP-GATE → verify → ghi `Status: FIXED (pending commit)` theo kết quả thật.
6. `400` (template sai — xem webapp-templates.md mục (b)) → sửa JSON theo `details` rồi gọi lại `/api/step`, vẫn ở mode webapp. Treo/lỗi kết nối khi đang chờ webapp → báo ngắn gọn cho user rồi chuyển sang hỏi từng item một cho các item còn lại thay vì thử lại hay dừng hẳn.
7. Sau khi đi hết các item SUGGESTION → có ít nhất 1 item được apply → chạy SDK/codegen nếu cần, rồi commit chung: `fix: apply {N} accepted suggestions` → đi một lượt cuối qua từng item `FIXED (pending commit)` và thay bằng `FIXED (commit <sha>)` dùng sha commit thật.

═══════════════════════════════════════════════════════
STOP-GATE — DỪNG LẠI VÀ HỎI USER (áp dụng cho MỌI fix ở bước 1-5, KHÔNG tự quyết định)
═══════════════════════════════════════════════════════

Trước khi fix bất kỳ issue nào (lint violation, CRITICAL, WARNING, cross-group, hoặc SUGGESTION đã được chấp nhận), kiểm tra 4 điều kiện sau — KHỚP bất kỳ điều kiện nào → dừng lại, dùng `AskUserQuestion`, KHÔNG tự fix. User trả lời "apply" cho một SUGGESTION không miễn gate — đó là đồng ý với thay đổi, không phải đồng ý với migration, sửa shared package hay ghi data.

a. Report ghi chú "verify with product" / "needs business-logic confirmation" / cách diễn đạt tương đương cho thấy fix phụ thuộc vào một quyết định business chưa rõ ràng.
b. Fix cần database migration (thêm/sửa/xoá column, constraint, hoặc enum value ở tầng DB).
c. Fix ảnh hưởng đến shared package (package được ≥2 app trong monorepo dùng — kiểm tra xem `packages/` có được ≥2 `apps/` import không).
d. Fix cần `UPDATE`/`DELETE` trên data đã tồn tại (không chỉ đổi schema) — coi trọng ngang với migration, vì rủi ro tương đương.

Không khớp điều kiện nào → fix trực tiếp theo đúng quy trình của bước tương ứng.

═══════════════════════════════════════════════════════
SDK GENERATE (sau MỖI batch làm thay đổi shared schema / API route, trước commit của batch đó)
═══════════════════════════════════════════════════════

Tự động detect script trong `package.json` (root và/hoặc package bị ảnh hưởng), thứ tự ưu tiên: `sdk:generate` → `api:generate` → `codegen`. Tìm thấy → chạy (ưu tiên qua package manager của project, tự động phát hiện qua lockfile). Không tìm thấy → bỏ qua, không tự tạo script mới.

═══════════════════════════════════════════════════════
WRAP-UP — FORMAT + DỌN DẸP
═══════════════════════════════════════════════════════

1. Sau khi tất cả các bước đã xong (kể cả các item SUGGESTION đã hỏi) → tự động phát hiện và chạy format command của project: tìm trong scripts của `package.json` theo thứ tự `format` → `format:fix` → `lint:fix`. Không tìm thấy → bỏ qua.
2. Chạy `vci` (typecheck + build) trên (các) package đã bị đụng tới trong lần chạy này — fix nhiều violation qua nhiều batch rất dễ để sót một type error lẻ. vci báo lỗi → fix trước khi qua bước tiếp theo (fix cho lỗi vci là một thay đổi riêng: nêu cho user trong summary).
3. Bước 1-2 làm thay đổi file đang được track (formatter ghi lại file, output sinh lại, fix lỗi vci) → commit gộp thành MỘT commit riêng: `chore: apply format and generated output after review fixes`. Không có gì thay đổi → không commit; nói rõ trong summary cuối. Không bao giờ nhét vào commit issue trước đó, và không bao giờ để uncommitted mà không nói.
4. Append mỗi item trong `.code-review/REPORT.md` thành 1 dòng vào `.code-review-history.jsonl` ở repo root (tạo file nếu chưa có) — mỗi dòng JSON: `{date, rule_or_source, file, status}`, đọc giá trị `Status:` cuối cùng của từng item. Làm bước này bất kể sau đó user xác nhận hay từ chối xoá — đây là bản ghi bền vững tồn tại độc lập với cả hai lựa chọn. (Không commit file này trừ khi repo vốn đã track nó.)
5. Trước khi xoá `.code-review/` (hoặc report path đã dùng): hỏi user xác nhận — không bao giờ mặc định là user đã đọc xong report.
6. User xác nhận → xoá report directory. User muốn giữ lại → để nguyên, xong.
7. Gợi ý tinh chỉnh rule: trong `.code-review-history.jsonl`, `rule_or_source` nào có nhiều entry `REJECTED` qua các lần chạy → ghi chú vào summary cuối như một ứng viên cần siết lại hoặc retire rule đó (qua `vreview --harvest` hoặc sửa trực tiếp rule). KHÔNG đọc `~/.claude/scripts/lint-rules/violation-history.jsonl` cho việc này — file đó chỉ lưu số violation theo từng lần scan (tổng, top rule), không lưu kết quả reject/skip.

═══════════════════════════════════════════════════════
QUY TẮC CỨNG
═══════════════════════════════════════════════════════

- KHÔNG được bỏ qua thứ tự ưu tiên SCRIPT_SCAN → CRITICAL → WARNING → CROSS-GROUP → SUGGESTION — kể cả khi một bước rỗng, vẫn phải báo "skip — no issues" trước khi chuyển sang bước tiếp theo; không bao giờ nhảy cóc.
- KHÔNG được tự ý apply item SUGGESTION mà không có quyết định tường minh từng item từ user — qua `AskUserQuestion` (mode từng item một) hoặc `diff-review-list` của webapp (mode webapp); không bao giờ bulk-apply mà thiếu cả 2.
- KHÔNG được refactor code ngoài phạm vi của issue đang fix — root-cause đúng issue đó, không tranh thủ "tiện thể" chèn thêm thay đổi khác.
- KHÔNG được commit từng issue riêng lẻ trong một batch có tính phụ thuộc lẫn nhau — commit theo batch.
- LUÔN dùng `AskUserQuestion` khi khớp điều kiện STOP-GATE (a/b/c/d) — không bao giờ tự quyết định thay user.
- LUÔN hỏi xác nhận trước khi xoá `.code-review/` hoặc report dir đã dùng.

═══════════════════════════════════════════════════════
BƯỚC TIẾP THEO
═══════════════════════════════════════════════════════

Nhìn vào những gì thực sự đã fix trong lần chạy này và tự đề xuất MỘT hành động tiếp theo hợp lý, 1-2 câu — không chọn theo danh sách cố định. Cân nhắc các skill khác trong bộ này (vspecs, vplan, vcook, vreview, vci, vtickets, vdesign, vrollback) nếu thực sự phù hợp; nếu không cần gì thêm thì nói rõ luôn. (Xem convention chung tại `_vskills-shared/repo-profile.md` §7.)
