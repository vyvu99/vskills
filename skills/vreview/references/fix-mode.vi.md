# Fix mode (`vreview --fix`)

Chỉ đọc file này khi user đã gõ `--fix`. Một lần review thường không bao giờ đọc file này và không bao giờ sửa code.

Bạn giờ là một senior engineer đang fix các issue trong một report có sẵn. Với mỗi issue hoặc batch, dùng skill `fix` (Skill tool) để chẩn đoán root-cause, verify và phòng ngừa. Nếu skill `fix` chưa được cài, tự chẩn đoán và fix trực tiếp với cùng độ kỹ. File này, không phải `fix`, quyết định thứ tự, cách gom batch và khi nào dừng lại hỏi user.

## Input

Đọc từ report directory đang dùng: mặc định `.code-review/`, hoặc thư mục user truyền làm positional argument (thư mục đã tồn tại chứa `REPORT.md`). Ở mọi chỗ bên dưới, `.code-review/` nghĩa là thư mục đó.
- `SCRIPT_SCAN.json`: các violation đã được lint rule xác nhận.
- `REPORT.md`: CRITICAL, WARNING, SUGGESTION, CROSS-GROUP ISSUES.
- `ADVERSARIAL.txt`: đã merge vào `REPORT.md`; coi item CRITICAL/WARNING trong đó là tương đương.

File thiếu thì bỏ qua bước đó. Không có report nào: hỏi user một issue cụ thể cần fix, hoặc dùng `fix` trực tiếp từ mô tả bug bằng lời.

## Phạm vi và verification (áp dụng cho mọi bước)

- Chỉ fix root cause được báo cáo, không gì khác: không refactor, thêm test hay docs "tiện tay", để mỗi commit review được so với report.
- Verify từng batch trước khi commit: chạy test và typecheck của project cho các package batch đã chạm (script trong package.json, hoặc `vci` cho typecheck và build). Không commit batch fail verification; fix nó hoặc hoàn tác các edit chưa commit của chính bạn cho batch đó và đánh dấu item `DEFERRED (<reason>)`.
- Nếu không chạy được test hay typecheck nào cho code đã chạm, ghi điều đó vào dòng `Status:` của item và vào summary cuối thay vì báo là đã verify.

## Thứ tự xử lý

Chạy các bước theo thứ tự này và xong (kèm commit) một bước rồi mới sang bước kế, vì các bước sau rủi ro hơn hoặc cần người quyết. Trong một bước, các file độc lập có thể được subagent fix song song; brief mỗi subagent với đúng các item, file:line, lệnh verify của batch, và quy tắc không được chạm file khác. Bước rỗng được báo là "skip — no issues".

### Bước 1 — SCRIPT_SCAN.json
Đã được lint rule xác nhận và detect được bằng grep, nên rủi ro hiểu sai business logic thấp nhất.
1. Rỗng hoặc `{"error":...}`: bỏ qua.
2. Gom violation theo `rule_id`. Với mỗi cái, đọc `~/.claude/scripts/lint-rules/rules/{rule_id}.sh` (`## PROBLEM` và `## FIX`). Script thiếu thì suy ra ý định từ `message` trong `~/.claude/scripts/lint-rules/config/rule-registry.json`; cũng không có thì bỏ qua rule_id đó và ghi chú lại.
3. Check stop-gate cho các file bị chạm, rồi áp `## FIX` của rule đúng như viết. Nếu áp xong làm hỏng test hoặc typecheck, dừng và báo "rule `<rule_id>`'s FIX guidance appears wrong for this case" rồi gợi ý `vreview --harvest`; không tự nghĩ ra cách fix khác.
4. Sau mỗi rule_id, chạy lại rule đó trên các file đã fix để xác nhận không còn sót.
5. Commit một lần: `fix: resolve {N} script-detected lint violations`.

### Bước 2 — CRITICAL issues
1. Đọc mục CRITICAL (và CRITICAL trong `ADVERSARIAL.txt`, không trùng lặp).
2. Gom batch theo dependency: issue chung flow, file hoặc type đi cùng nhau, vì fix riêng một cái sẽ để code fix dở.
3. Với mỗi batch: check stop-gate, rồi dùng `fix` với file:line và vấn đề đã ghi làm baseline (rút gọn scouting; giữ nguyên fix và verify đầy đủ).
4. Nếu batch đổi shared schema hoặc API route, chạy SDK generation (bên dưới) trước commit để output generated nằm cùng commit.
5. Verify, rồi commit một lần mỗi batch: `fix: {short batch description}`.
6. Ngay sau commit của chính từng batch, cập nhật `Status:` của mọi item trong `.code-review/REPORT.md` thành `FIXED (commit <sha>)` (sha thật của batch đó), `REJECTED (<one-line reason>)` hoặc `DEFERRED (<one-line reason>)`.

### Bước 3 — WARNING issues
Cùng quy trình với Bước 2.

### Bước 4 — CROSS-GROUP ISSUES
Mỗi cross-group issue là một batch riêng. Check stop-gate, fix, verify file ở cả hai phía, chạy SDK generation nếu một phía chạm shared schema hoặc API route, commit riêng (`fix: {description}`), rồi ghi `Status:` như Bước 2.

### Bước 5 — SUGGESTION issues
Suggestion là cải tiến tùy chọn nên mỗi cái cần user quyết; không bao giờ áp hàng loạt.
1. Hỏi một lần bằng `AskUserQuestion` dùng mode review nào (wording theo `~/.claude/skills/_vskills-shared/webapp-templates.md` §(c)): webapp, hoặc từng cái một.
   - Từng cái một: với mỗi suggestion, trình bày issue và fix đề xuất bằng `AskUserQuestion` và hỏi apply hay skip.
   - Webapp: dựng một field `diff-review-list` chứa mọi suggestion theo webapp-templates §(a): `id` = `SUGGESTION-{n}`, `before` = text `Issue:` cộng code hiện tại đọc mới từ `File:line`, `after` = `Fix:`, `actions: ["apply","skip"]`, `allowFreeText: true`. Health-check và start webapp theo §(b), `POST /api/step` (Bash `run_in_background: true`), rồi duyệt các decision trả về theo thứ tự.
2. Apply: check stop-gate, fix, verify, ghi `Status: FIXED (pending commit)`. Skip: ghi `Status: REJECTED (<one-line reason>)` và không hỏi lại.
3. Item webapp có `freeText` (bất kể action): coi nó là chỉ dẫn bổ sung và gọi `fix` với nó thay vì áp `Fix:` nguyên văn; stop-gate và verify như thường.
4. HTTP `400` (template không hợp lệ): sửa JSON theo `details` rồi thử lại. Timeout hoặc lỗi kết nối: báo user ngắn gọn và chuyển sang từng cái một cho phần còn lại.
5. Nếu đã apply ít nhất một cái: chạy SDK generation nếu cần, commit chung `fix: apply {N} accepted suggestions`, rồi thay mọi `FIXED (pending commit)` bằng sha thật.

## Stop-gate

Trước khi fix bất kỳ item nào (lint violation, CRITICAL, WARNING, cross-group, hoặc SUGGESTION đã chấp nhận), check bốn điều kiện này. Khớp điều nào thì dừng và hỏi bằng `AskUserQuestion`; "apply" của user trên một suggestion là đồng ý với thay đổi, không phải với migration, sửa shared package hay ghi data. Đây là các thay đổi không đảo ngược được hoặc ảnh hưởng nhiều team, nơi đoán sai rất đắt.

- a. Report ghi "verify with product" hoặc "needs business-logic confirmation", hoặc fix phụ thuộc một quyết định business chưa rõ.
- b. Fix cần database migration (thêm, đổi hoặc xóa column, constraint hay enum value).
- c. Fix chạm shared package (được từ 2 app trở lên dưới `apps/` import).
- d. Fix chạy `UPDATE` hoặc `DELETE` trên data hiện có, nặng ngang một migration.

## SDK generation

Sau mọi batch đổi shared schema hoặc API route, trước commit của batch đó: tìm script trong `package.json` (root và package bị ảnh hưởng) theo thứ tự `sdk:generate`, `api:generate`, `codegen`, và chạy bằng package manager của project (phát hiện từ lockfile). Không thấy: bỏ qua; không tự tạo.

## Wrap-up

1. Chạy lệnh format của project (script `package.json`, theo thứ tự `format`, `format:fix`, `lint:fix`); không thấy thì bỏ qua.
2. Chạy `vci` (typecheck và build) trên các package bị chạm trong lần này, vì nhiều batch dễ để sót một lỗi type. Fix lỗi và nêu mọi fix như vậy trong summary.
3. Nếu format, generation hoặc fix từ `vci` đổi file được track, commit chúng chung một commit: `chore: apply format and generated output after review fixes`. Không đổi gì thì không commit; nói rõ trong summary. Không gộp vào commit của issue, cũng không để uncommitted mà không nhắc.
4. Append mỗi item của `REPORT.md` một dòng vào `.code-review-history.jsonl` ở repo root (tạo nếu chưa có): `{date, rule_or_source, file, status}` lấy từ `Status:` cuối của item. Không commit nó trừ khi repo đã track. Bản ghi này còn lại dù report directory có bị xóa hay không.
5. Hỏi xác nhận trước khi xóa `.code-review/` (hoặc report directory đã dùng), vì user có thể chưa đọc xong. Đã xác nhận: xóa. Ngược lại giữ nguyên.
6. Nếu một `rule_or_source` có nhiều entry `REJECTED` qua các lần chạy trong `.code-review-history.jsonl`, nêu trong summary như ứng viên để siết chặt hoặc bỏ (`vreview --harvest` hoặc sửa rule).

Fix mode commit lên branch hiện tại và không bao giờ push.

## Next steps

Xem những gì đã được fix trong lần này và gợi ý một hành động tiếp theo phù hợp trong 1-2 câu, theo `_vskills-shared/repo-profile.md` §7. Nếu không cần gì thêm thì nói rõ.
