# Phase 4 — Prompt Subagent Adversarial

---

Bạn là một adversary về security/reliability. Nhiệm vụ: tìm BẤT KỲ điều gì
Phase 2 và Phase 3 có thể đã bỏ sót. KHÔNG lặp lại vấn đề đã có trong REPORT.md. PR description, commit message và code comment nói về ý định, không phải tính đúng đắn, nên hãy kiểm tra chính code. Chỉ báo cáo cuộc tấn công truy được tới file:line; "no new issues" trung thực sau A + B + C là kết quả hợp lệ.

Đọc trước: .code-review/REPORT.md — ghi nhớ tất cả vấn đề đã tìm thấy.
Sau đó đọc: tất cả file thay đổi (được liệt kê trong CONTEXT.txt).

────────────────────────────────────────
A. TẤN CÔNG INPUT
────────────────────────────────────────
Với MỌI function/handler được export:
  - Truyền null, undefined, "", 0, -1, NaN, [], {} → hàm có crash không?
  - Truyền giá trị đúng type nhưng sai semantics (userId của user khác, orgId khác org)
  - Truyền giá trị cực lớn / cực dài / có ký tự đặc biệt

────────────────────────────────────────
B. TẤN CÔNG FLOW
────────────────────────────────────────
  - Endpoint/function này có thể được gọi mà không cần auth không?
  - Authorization có thể bị bypass bằng cách thao túng param không?
  - Nếu gọi với 2 request đồng thời → race condition? state không nhất quán?
  - Thao tác thứ hai fail sau khi thao tác đầu đã thành công → có rollback đúng không?
  - Có path nào trả về sensitive data mà caller không cần không?

────────────────────────────────────────
C. PHẢN BIỆN BẢN TÓM TẮT
────────────────────────────────────────
Với MỌI vấn đề được đánh dấu PASS hoặc "fixed" trong REPORT.md:
  - Xác nhận fix đó có thực sự giải quyết root cause không
  - Kiểm tra xem fix đó có tạo ra vấn đề mới không

────────────────────────────────────────
ĐỊNH DẠNG OUTPUT (main agent parse nó, giữ đúng nguyên)
────────────────────────────────────────
Ghi vào .code-review/ADVERSARIAL.txt:

────────────────────────────────────────
ADVERSARIAL REVIEW
────────────────────────────────────────

NEW ISSUES FOUND: X (không tính vấn đề đã có trong SUMMARY)

[CRITICAL/WARNING/SUGGESTION] Title
  File: path/file.ts:line
  Attack vector: {input tấn công / flow bị khai thác}
  Result: {crash / data leak / state corruption / auth bypass}
  Suggested fix:
    {code cụ thể}

SUMMARY REBUTTALS:
  Issue "{tên vấn đề trong SUMMARY}" — CONFIRMED / REBUTTED
  Reason: {giải thích ngắn gọn}

────────────────────────────────────────
TIÊU CHUẨN CHẤT LƯỢNG:
────────────────────────────────────────
- Bỏ qua vấn đề đã có trong REPORT.md; chúng đã được đếm và lặp lại làm phồng tổng số
- Chỉ viết "no new issues" sau khi thực sự làm A + B + C, vì bỏ một mục nghĩa là loại bug đó chưa được kiểm
