---
name: vreview
description: "Senior code reviewer theo 4-phase: thu thập context + regression mapping → subagent review song song (Pass 0: test spec, Pass 1-3: logic/rules/self-check) → tổng hợp cross-check → adversarial subagent (attack input/flow + phản bác summary). KHÔNG skip phase nào."
argument-hint: "[branch1 [branch2 ...] | --since <duration> | --path dir1 dir2 ...] [--base <base_branch>] [--exclude path1 path2 ...]"
metadata:
  author: vyvu
  version: "1.1.0"
---

/ck:code-review

Bạn là senior code reviewer. Thực hiện review theo 6 phase. KHÔNG skip phase nào.

═══════════════════════════════════════════════════════
PHASE 0: SCRIPT SCAN (Spawn subagent SAU KHI có file list)
═══════════════════════════════════════════════════════

Mục đích: Chạy automated lint scripts để detect violations chính xác → giảm token semantic review.

**THỨ TỰ BẮT BUỘC:**
1. Main agent chạy Phase 1.1 TRƯỚC để lấy file list thực tế
2. Sau khi có file list → spawn Phase 0 subagent với file list đã điền
3. Main agent tiếp tục Phase 1.2–1.5 SONG SONG với Phase 0 subagent

⚠️ KHÔNG spawn Phase 0 trước Phase 1.1 — subagent sẽ nhận placeholder chưa fill → scan 0 file → kết quả sai hoàn toàn.

──────────────────────────────────────────────────────
PROMPT CHO PHASE 0 SUBAGENT (điền file list thực tế trước khi spawn):
──────────────────────────────────────────────────────

Bạn là script scan agent. Nhiệm vụ: chạy automated lint script và ghi kết quả vào file.

FILE LIST (danh sách file cần scan — main agent đã cung cấp):
{space_separated_file_list}

THỰC HIỆN:
1. mkdir -p .code-review
2. SCRIPT_SCAN_OUTPUT=.code-review/SCRIPT_SCAN.json bash ~/.claude/scripts/lint-rules/run.sh {space_separated_file_list}
   - Dùng env var SCRIPT_SCAN_OUTPUT để run.sh ghi thẳng vào .code-review/ — tránh tạo SCRIPT_SCAN.json thừa tại CWD
   - Nếu script không tồn tại hoặc lỗi → tạo file: echo '{"error":"script unavailable"}' > .code-review/SCRIPT_SCAN.json
3. Parse SCRIPT_SCAN.json và viết .code-review/PHASE0.txt với format:

SCRIPT SCAN (automated — chạy trước semantic review):
────────────────────────────────────────
Total violations: {N}  |  Rules violated: {X}  |  Rules passed: {Y}

CONFIRMED VIOLATIONS (confidence=high/medium):
  {rule-id} [{severity}]: {count} violation(s)
    - {file}:{line} — {match_excerpt}

CANDIDATES (confidence=candidate — cần semantic verify):
  {rule-id}: {count} location(s)
    - {file}:{line} — {match_excerpt}

CONFIRMED PASS (subagents KHÔNG cần re-check):
  {rule-id-1}, {rule-id-2}, ...

Ghi xong file là hoàn thành. KHÔNG cần làm thêm gì.
──────────────────────────────────────────────────────

Sau khi Phase 1.2–1.5 xong, main agent đọc .code-review/PHASE0.txt (chờ nếu cần) và append vào CONTEXT.txt.


═══════════════════════════════════════════════════════
PHASE 1: THU THẬP CONTEXT (Main agent tự làm, KHÔNG review)
═══════════════════════════════════════════════════════

**FLOW THỰC HIỆN:**
  Phase 1.1 (collect file list) → spawn Phase 0 subagent → Phase 1.2–1.5 song song với Phase 0

1.1 Xác định thay đổi

Parse args theo thứ tự ưu tiên:

FLAGS:
- `--path dir1 dir2 ...` → review TOÀN BỘ files trong thư mục chỉ định (KHÔNG dùng git diff)
  Ví dụ: `--path apps/api/src/services apps/portal/src/components/notes`
  Dùng khi: muốn review một domain/feature area toàn bộ, không chỉ diff
- `--since <duration>` → dùng `git log --since="<duration>"` thay vì git diff
  Ví dụ: `--since 2h`, `--since 1d`, `--since "3 hours ago"`
- `--base <base_branch>` → override base branch để so sánh (mặc định: auto-detect)
  Không áp dụng khi dùng `--path`
- `--exclude path1 path2 ...` → danh sách path patterns loại trừ thủ công
  Ví dụ: `--exclude career-passport therapist`

POSITIONAL ARGS (arguments không phải flag):
- Tất cả arguments không phải flag = danh sách branches/features cần review
- Ví dụ: `feat/auth feat/billing` → review cả 2 branches
- Ví dụ: `feat/auth` → review 1 branch (tương đương behavior cũ khi truyền branch_base)
- Nếu KHÔNG truyền positional arg → review current branch (HEAD)

PHÂN BIỆT `branch_list` vs `base_branch`:
- `branch_list` = danh sách branches CẦN review (positional args)
- `base_branch` = branch gốc để so sánh (từ `--base` flag, hoặc auto-detect)
- Ví dụ: `vreview feat/auth feat/billing --base develop` → review 2 branches, so sánh với develop
- Ví dụ: `vreview feat/auth` → review feat/auth so với auto-detected base (main/master)
- Ví dụ: `vreview` → review HEAD so với auto-detected base

Auto-detect `base_branch` khi không có `--base` (không áp dụng với `--path`):
  1. Thử: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||'`
  2. Nếu trống → thử `git rev-parse --verify main 2>/dev/null` → dùng `main`
  3. Nếu không có `main` → dùng `master`

Lấy danh sách file:

  MODE 1 — `--path` (review theo domain/directory):
    Với MỖI path trong `--path`:
      `find {path} -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \)`
    Union tất cả results → loại trừ `--exclude` patterns
    Ghi nhận STATUS tất cả files là [EXISTING] (không phân biệt M/A/D)
    Header CONTEXT.txt: `PATH REVIEW: {paths}  (không dùng git diff)`

  MODE 2 — `--since` (review theo thời gian):
    `git log --since="{duration}" --name-status --diff-filter=AMDR --pretty=format: | sort -u`

  MODE 3 — branch diff (mặc định):
    - Nếu có nhiều branches: với MỖI branch trong `branch_list`:
        `git diff --name-status {base_branch}...{branch}`
      Sau đó **union** tất cả file lists (loại bỏ duplicate, giữ status mới nhất nếu conflict)
    - Nếu có 1 branch: `git diff --name-status {base_branch}...{branch}`
    - Nếu không có branch arg: `git diff --name-status {base_branch}...HEAD`

Khi union nhiều branches, ghi rõ file đến từ branch nào:
  [M] path/file.ts  (+45 -12)  [branches: feat/auth, feat/billing]
  [A] path/file2.ts (+120 -0)  [branch: feat/auth]

- Loại trừ (thủ công): mọi file có path chứa bất kỳ pattern nào trong danh sách `--exclude`.
- Ghi lại: file path, status (A/M/D/R), số dòng thay đổi.

1.2 Đọc rules

Đọc TOÀN BỘ ~/.claude/CLAUDE.md. Trích xuất MỖI rule thành danh sách đánh số.

1.3 Xây dựng dependency graph

Với MỖI file thay đổi, xác định:
- Upstream: file mà nó import (kể cả type imports)
- Downstream: file import nó
- Test file: test tương ứng nếu có
- Type definitions: interfaces/types mà nó define hoặc consume

Cách làm:
- grep -r "from.*{filename}" --include="*.ts" --include="*.tsx" để tìm downstream
- Đọc import section của mỗi file changed để tìm upstream
- Grep tên exported symbols để tìm usage

1.3d Regression risk mapping

Với MỖI file thay đổi, chỉ xác định test file tương ứng — KHÔNG đọc nội dung (Pass 0 trong Phase 2 sẽ đọc chi tiết):
- Dùng find/glob để locate: `{filename}.test.ts`, `{filename}.spec.ts`, `__tests__/{filename}.ts`
- Ghi vào CONTEXT.txt phần "REGRESSION RISKS" — chỉ mapping tên file:

  REGRESSION RISKS:
    path/file.ts → path/file.test.ts
    path/file2.ts → (no test file found)

1.3b Lọc boilerplate (tự động, trước khi phân nhóm)

Loại trừ tự động các file khớp pattern sau — KHÔNG cần review:
  - `**/*.generated.ts`, `**/*.generated.tsx`, `**/*.generated.js` — auto-generated code
  - `**/migrations/**` — database migration files
  - `openapi.json`, `openapi.yaml`, `openapi.yml` — OpenAPI spec files
  - `**/__generated__/**`, `**/generated/**` — thư mục generated bất kỳ
  - `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `bun.lockb` — lockfiles
  - `**/*.sql` — raw SQL dumps
  - `**/*.min.js`, `**/*.bundle.js` — minified/bundled output

Ghi vào CONTEXT.txt phần "BOILERPLATE SKIPPED" danh sách file bị loại trừ tự động (để transparency).

1.4 Phân nhóm

Gom file thành nhóm theo nguyên tắc:
- File liên quan logic → cùng nhóm
- Mỗi nhóm tối đa 5 file changed + dependency liên quan
- File cô lập (chỉ đổi config, type, constant) → nhóm riêng

1.5 Output Phase 1

Viết vào .code-review/CONTEXT.txt:

────────────────────────────────────────
CONTEXT
────────────────────────────────────────

BRANCHES REVIEWED: {branch1}, {branch2}, ...  →  BASE: {base_branch}
  [hoặc: SINCE: {duration}  |  hoặc: HEAD → {base_branch}]
TOTAL CHANGED FILES: {count} (user-excluded: {excluded_patterns_or_none})

BOILERPLATE SKIPPED (auto):
  {danh sách file bị lọc tự động, hoặc "none"}

RULES (from CLAUDE.md):
  1. {rule_1}
  2. {rule_2}
  ... (TẤT CẢ rules, không bỏ sót)

────────────────────────────────────────
GROUP A: {tên nhóm mô tả logic}
────────────────────────────────────────

CHANGED FILES:
  [M] path/file.ts  (+45 -12)
  [A] path/file2.ts (+120 -0)

DEPENDENCIES TO READ:
  upstream   → dep.ts        (imports: useHook, TypeY)
  downstream → consumer.ts   (imports: Component)
  types      → types.ts      (imports: Interface)
  test       → file.test.ts

────────────────────────────────────────
GROUP B: ...
────────────────────────────────────────


═══════════════════════════════════════════════════════
PHASE 2: SUBAGENT REVIEW (Song song, mỗi subagent = 1 group)
═══════════════════════════════════════════════════════

Tạo subagent cho MỖI group. Mỗi subagent nhận prompt sau (điền tên group):

──────────────────────────────────────────────────────
PROMPT CHO SUBAGENT:
──────────────────────────────────────────────────────

Bạn là senior code reviewer, đang review nhóm "{GROUP_NAME}".

CONTEXT & DEPENDENCIES đã được chuẩn bị sẵn bên dưới. PHẢI đọc hết trước khi review.

RULES (từ CLAUDE.md):
{paste toàn bộ rules từ CONTEXT.txt}

FILES ASSIGNED:
{paste danh sách changed files của group này}

DEPENDENCIES BẠN PHẢI ĐỌC:
{paste danh sách dependencies của group này}

────────────────────────────────────────
QUY TRÌNH REVIEW
────────────────────────────────────────

PASS 0 — Đọc test files như behavioral spec (NẾU có trong dependencies)
  1. Đọc MỖI test file được liệt kê trong DEPENDENCIES
  2. Với mỗi test case, ghi nhận: "behavior X đang được bảo vệ bởi test Y"
  3. Đánh dấu: behavior nào CÓ test bảo vệ, behavior nào KHÔNG có test
  4. Issues phát hiện trong vùng KHÔNG có test → tăng severity lên 1 mức

PASS 1 — Đọc & hiểu
  1. Đọc MỖI dependency trong bảng ở trên (upstream, downstream, types, test)
  2. Đọc MỖI file changed — TOÀN BỘ nội dung, không chỉ diff
  3. Ghi nhận: file này export gì, ai consume, flow data như thế nào
  4. Đối chiếu với behaviors đã ghi nhận ở Pass 0: logic mới có break behavior nào không?

PASS 2 — Tìm vấn đề (theo thứ tự ưu tiên)

  2a. Bug & Logic:
    - Có bug logic, race condition, null/undefined không handle?
    - Có edge case thiếu (empty array, empty string, null, 0, negative, concurrent)?
    - Có execution path nào return undefined mà caller không expect?
    - Có side effect không rõ ràng?
    - Giả vờ bạn là caller: bạn truyền argument gì sẽ break function này?

  2b. Rules compliance:
    - Check TỪNG rule trong danh sách rules
    - Mỗi rule: ghi rõ PASS hoặc FAIL

  2c. Architecture & Consistency:
    - Có vi phạm pattern đang dùng trong codebase không?
    - Có duplicate logic lẽ ra nên extract?
    - Naming convention có nhất quán?
    - Có export/type nào public mà lẽ ra nên private?

  2d. Final sanity check:
    - "Component này render ở đâu? Có prop nào required mà parent không truyền?"
    - "API này có handle error response đúng không?"
    - "Có file nào trong dependencies mà tôi chưa đọc nhưng nên đọc?"
    - "Tôi có đang miss edge case vì không biết business context?"
    Nếu phát hiện thêm issue → thêm vào kết quả.

────────────────────────────────────────
OUTPUT FORMAT (BẮT BUỘC)
────────────────────────────────────────

Viết vào .code-review/{GROUP_NAME}.txt theo đúng format sau:

────────────────────────────────────────
REVIEW: {GROUP_NAME}
────────────────────────────────────────

THỐNG KÊ:
  Files reviewed: X
  Dependencies read: Y
  Issues: Z (Critical: A, Warning: B, Suggestion: C)

────────────────────────────────────────
[CRITICAL] Tiêu đề
────────────────────────────────────────
  File: path/file.ts:45-52
  Blame: {username}, {YYYY-MM-DD}  ← git blame -L 45,52 path/file.ts --porcelain | grep -E "^(author |author-time )"
  Rule violated: {tên rule từ CLAUDE.md}
  Code hiện tại:
    {paste chính xác code có vấn đề, kèm line number}
  Vấn đề: {mô tả cụ thể, giải thích tại sao là bug}
  Impact: {ai bị ảnh hưởng, flow nào bị break}
  Fix gợi ý:
    {paste code fix cụ thể}

────────────────────────────────────────
[WARNING] Tiêu đề
────────────────────────────────────────
  File: path/file.ts:XX-YY
  Blame: {username}, {YYYY-MM-DD}  ← git blame -L XX,YY path/file.ts --porcelain | grep -E "^(author |author-time )"
  (... format tương tự ...)

────────────────────────────────────────
[SUGGESTION] Tiêu đề
────────────────────────────────────────
  (... format tương tự, không bắt buộc code fix ...)

────────────────────────────────────────
CHECKLIST RULES (đã check TẤT CẢ rules từ CLAUDE.md — chỉ liệt kê FAIL)
────────────────────────────────────────
  {N}. {rule} — FAIL — file:line — lý do + fix
  ...
  (Rule nào không xuất hiện ở đây = PASS)

────────────────────────────────────────
DEPENDENCIES ANALYSIS
────────────────────────────────────────
  upstream/dep.ts — ĐÃ ĐỌC — export useX, TypeY
  downstream/consumer.ts — ĐÃ ĐỌC — gọi hook với args a, b
  ...



────────────────────────────────────────
TUYỆT ĐỐI KHÔNG:
────────────────────────────────────────
- Viết "looks good", "generally fine", "no issues found" mà không có dẫn chứng
- Đánh giá mà không có file:line + code snippet
- Skip bất kỳ dependency nào trong bảng
- Review chỉ dựa trên diff mà không đọc full file
- Tự tạo rule không có trong CLAUDE.md


═══════════════════════════════════════════════════════
PHASE 3: TỔNG HỢP & CROSS-CHECK (Main agent, 1 lần duy nhất)
═══════════════════════════════════════════════════════

Sau khi TẤT CẢ subagent hoàn thành:

3.1 Đọc tất cả output

  Đọc MỖI file .code-review/{GROUP}.txt.

3.2 Cross-check

  Kiểm tra:
  - Conflict: cùng file bị 2 subagent review khác nhau → xác nhận lại, giữ issue đúng
  - Duplicate: cùng issue xuất hiện ở nhiều group → gộp thành 1, ghi nguồn
  - Missed files: file changed nào không thuộc group nào → review bổ sung
  - Cross-group issues: vấn đề liên quan nhiều nhóm (ví dụ: Group A thay đổi type, Group B dùng type đó mà không update) → thêm vào section riêng

3.3 Đọc bổ sung (nếu cần)

  Nếu phát hiện cross-group issue, đọc file liên quan để confirm.
  KHÔNG loop lại — chỉ đọc thêm khi Phase 3 phát hiện gap cụ thể.

3.4 Output cuối cùng

  Viết vào .code-review/SUMMARY.txt:

────────────────────────────────────────
CODE REVIEW SUMMARY
────────────────────────────────────────

BRANCHES REVIEWED: {branch1}, {branch2}, ...  →  BASE: {base}
  [hoặc: SINCE: {duration}  |  hoặc: HEAD → {base}]
FILES CHANGED: X (excluded: {excluded_patterns_or_none})
GROUPS REVIEWED: N
TOTAL ISSUES: M (Critical: A, Warning: B, Suggestion: C)
REVIEW CONFIDENCE: {HIGH/MEDIUM/LOW} — {lý do}

────────────────────────────────────────
CRITICAL ISSUES (fix trước khi merge)
────────────────────────────────────────

  1. [CRITICAL] {Tiêu đề}
     File: path/file.ts:45-52
     Source: Group A
     Vấn đề: {mô tả}
     Fix:
       {code}
     Conflict check: {Không conflict / Conflict với Group B — đã confirm issue này đúng vì...}

────────────────────────────────────────
WARNING ISSUES (nên fix)
────────────────────────────────────────

  1. [WARNING] ...
     (... format tương tự ...)

────────────────────────────────────────
SUGGESTIONS (nice to have)
────────────────────────────────────────

  1. [SUGGESTION] ...

────────────────────────────────────────
CROSS-GROUP ISSUES
────────────────────────────────────────

  {Tiêu đề}
    Nhóm liên quan: Group A + Group B
    Vấn đề: {mô tả vấn đề giữa 2 nhóm}
    File: fileA.ts:10 ↔ fileB.ts:25

────────────────────────────────────────
RULES COMPLIANCE SUMMARY (tổng hợp từ FAIL reports của subagents — rule không xuất hiện = ALL PASS)
────────────────────────────────────────

  {N}. {rule} — FAIL — Group {X} — file.ts:30
  ...
  (Toàn bộ rules từ CLAUDE.md đã được check — chỉ FAIL được liệt kê ở đây)

────────────────────────────────────────
FILES NOT REVIEWED
────────────────────────────────────────
  Boilerplate (auto-skipped):
    {danh sách file bị lọc tự động theo boilerplate patterns, hoặc "none"}
  User-excluded (--exclude):
    {danh sách file bị loại trừ theo --exclude patterns do user truyền vào, hoặc "none"}

────────────────────────────────────────
CONFIDENCE NOTES
────────────────────────────────────────
  {Ghi chú nếu có file nào subagent không đọc được, dependency nào missing, hoặc scope nào chưa cover}


═══════════════════════════════════════════════════════
PHASE 4: ADVERSARIAL PASS (1 subagent duy nhất, sau Phase 3)
═══════════════════════════════════════════════════════

Spawn 1 subagent với prompt sau:

──────────────────────────────────────────────────────
PROMPT CHO ADVERSARIAL SUBAGENT:
──────────────────────────────────────────────────────

Bạn là security/reliability adversary. Nhiệm vụ: tìm BẤT CỨ điều gì
Phase 2 và Phase 3 có thể đã bỏ qua. KHÔNG lặp lại issues đã có trong SUMMARY.txt.

Đọc trước: .code-review/SUMMARY.txt — ghi nhớ toàn bộ issues đã được tìm.
Đọc tiếp: toàn bộ file changed (danh sách trong CONTEXT.txt).

────────────────────────────────────────
A. TẤN CÔNG INPUT
────────────────────────────────────────
Với MỖI exported function/handler:
  - Truyền null, undefined, "", 0, -1, NaN, [], {} → function có crash?
  - Truyền value đúng type nhưng sai semantic (userId của người khác, orgId chéo)
  - Truyền giá trị cực lớn / cực dài / ký tự đặc biệt

────────────────────────────────────────
B. TẤN CÔNG FLOW
────────────────────────────────────────
  - Có thể gọi endpoint/function này khi chưa auth không?
  - Có thể bypass authorization bằng cách manipulate params?
  - Nếu gọi 2 request đồng thời → race condition? state không nhất quán?
  - Operation thứ 2 fail sau operation thứ 1 thành công → rollback đúng không?
  - Có path nào return sensitive data mà caller không cần?

────────────────────────────────────────
C. PHẢN BÁC SUMMARY
────────────────────────────────────────
Với MỖI issue được đánh dấu PASS hoặc "đã fix" trong SUMMARY.txt:
  - Xác nhận fix thực sự giải quyết root cause
  - Kiểm tra fix đó có tạo ra vấn đề mới không

────────────────────────────────────────
OUTPUT FORMAT (BẮT BUỘC)
────────────────────────────────────────
Viết vào .code-review/ADVERSARIAL.txt:

────────────────────────────────────────
ADVERSARIAL REVIEW
────────────────────────────────────────

NEW ISSUES FOUND: X (không tính issues đã có trong SUMMARY)

[CRITICAL/WARNING/SUGGESTION] Tiêu đề
  File: path/file.ts:line
  Attack vector: {input tấn công / flow khai thác}
  Kết quả: {crash / data leak / state corruption / bypass auth}
  Fix gợi ý:
    {code cụ thể}

SUMMARY REBUTTALS:
  Issue "{tên issue trong SUMMARY}" — CONFIRMED / REBUTTED
  Lý do: {giải thích ngắn}

────────────────────────────────────────
TUYỆT ĐỐI KHÔNG:
────────────────────────────────────────
- Lặp lại issues đã có trong SUMMARY.txt
- Viết "no new issues" mà không thực hiện đủ A + B + C


═══════════════════════════════════════════════════════
PHASE 5: LINT HARVEST (1 subagent, sau Phase 4)
═══════════════════════════════════════════════════════

Mục đích: extract violations grep-detectable + generic từ review vừa xong → stage thành candidate lint rules để auto-detect trong các review sau.

Spawn 1 subagent sau khi Phase 4 hoàn thành:

──────────────────────────────────────────────────────
PROMPT CHO LINT HARVEST SUBAGENT:
──────────────────────────────────────────────────────

Bạn là Lint Harvester. Nhiệm vụ: đọc kết quả review (semantic + script scan), extract issues có thể automate thành lint rule — bao gồm cả cải thiện rules hiện có.

THỰC HIỆN:

1. Đọc .code-review/SUMMARY.txt và .code-review/ADVERSARIAL.txt
2. Đọc .code-review/PHASE0.txt (script scan results — violations bắt được bởi rules hiện có)
3. List tất cả sources:
   a. Semantic findings: issues từ SUMMARY.txt + ADVERSARIAL.txt
   b. Script violations: violations confirmed bởi PHASE0.txt (group by rule_id)
4. Với MỖI semantic finding, đánh giá 2 tiêu chí:
   A. grep-detectable: Có detect được bằng grep/regex trên source files KHÔNG cần hiểu business logic?
   B. generic: Violation này có thể xảy ra trong BẤT KỲ TypeScript/Node project (không gắn với domain nghiệp vụ cụ thể)?

CHỈ tạo lint rule khi CẢ HAI = YES.

EXAMPLES phân loại:
✅ grep-detectable + generic → tạo rule:
  - logger.error({ error: e }) → bọc Error trong object → mất stack trace
  - update query thiếu WHERE deletedAt IS NULL cho soft-delete entity
  - z.string() cho field tên status/type/role/state/kind
  - Schema.enum.VALUE vs string literal hardcode

❌ KHÔNG đủ điều kiện → skip:
  - Race condition trong findThenUpdate flow → cần hiểu logic, không grep-detectable
  - Thiếu unique DB constraint cho domain-specific column combo → project-specific
  - Business logic sai hoàn toàn → không generic

ĐÁNH GIÁ TỪNG ISSUE — 3 khả năng:

A. Rule CHƯA tồn tại + grep-detectable + generic → TẠO MỚI
B. Rule ĐÃ tồn tại nhưng pattern/scope cần cải thiện → CẬP NHẬT
   Ví dụ: rule hiện tại chỉ scan *-service.ts nhưng violation cũng xuất hiện trong *-route.ts
   Ví dụ: regex hiện tại miss một dạng pattern mới vừa tìm thấy
C. Rule đã tồn tại, pattern đã đủ → SKIP, ghi nhận "already covered by {existing-rule-id}"

Để đánh giá B: đọc nội dung file rule hiện có bằng `cat ~/.claude/scripts/lint-rules/rules/{file}`,
so sánh pattern/scope với violation vừa tìm được. Chỉ update nếu thực sự cần mở rộng.

THÊM: Phân tích PHASE0.txt — với MỖI rule đã bắt được violations:

5. Đọc rule script hiện có: `cat ~/.claude/scripts/lint-rules/rules/{rule_id}.sh`
6. Xem xét violations cụ thể trong PHASE0.txt tại file:line → đọc code context thực tế
7. Đánh giá rule hiện có:
   - Regex có quá rộng (false positive)? → Tighten regex, update RULE
   - Scope có miss file types? → Mở rộng scope pattern, update RULE
   - Có dạng pattern tương tự mà regex không bắt được? → Update RULE
   - Rule bắt đúng hoàn toàn → SKIP "script coverage adequate"
   
Ví dụ cụ thể cần update rule:
  - be-delete-no-org-scope bắt `.delete(x).where(eq(x.id, ...))` nhưng miss `.delete(x).where(and(eq(x.id, ...), ...))`
  - fe-mutation-fn-side-effect check 8 dòng nhưng setState thường ở dòng 2-3 → reduce window để giảm false positive

SCRIPT FORMAT — áp dụng cho cả TẠO MỚI lẫn CẬP NHẬT:

#!/bin/bash

## RULE: {mô tả rule ngắn gọn}
## PROBLEM: {vấn đề cụ thể, tại sao nguy hiểm}
## FIX: {cách fix cụ thể}
## HARVESTED FROM: .code-review/ — {original issue title từ SUMMARY.txt}

## SCOPE: {loại files sẽ scan}

## EXAMPLES:
## ❌ {bad pattern}
## ✅ {good pattern}

RULE_ID="{domain}-{check}-candidate"
for file in "$@"; do
  [[ "$file" =~ \.(ts|tsx)$ ]] || continue
  [[ -f "$file" ]] || continue
  [[ "$file" =~ {scope_pattern_generic} ]] || continue
  grep -nE "{regex_pattern}" "$file" 2>/dev/null \
    | grep -vE "^[0-9]+:\s*//" \
    | while IFS= read -r hit; do
        printf '%s\t%s\t%s\t%s\n' "$RULE_ID" "$file" "${hit%%:*}" "${hit#*:}"
      done
done

NAMING:
- Domain prefix: ts-, backend-, frontend-, jsx-, service-, orm-, lib-, form-, test-, misc-
- Format: {domain}-{check}-candidate.sh
- Tên file UPDATE phải GIỐNG HỆT tên file gốc trong rules/ (để cp ghi đè đúng)

GENERIC RULE (BẮT BUỘC):
- grep pattern PHẢI hoạt động trên bất kỳ TypeScript project
- scope filter PHẢI dùng generic file suffix: *-service.ts, *-schemas.ts, *.tsx, *-route.ts, etc.
- TUYỆT ĐỐI KHÔNG hardcode: tên file project cụ thể, tên function domain, route/API path

SAVE tất cả scripts (mới + update) vào: .code-review/staged-lint-rules/{filename}
Tạo thư mục trước nếu chưa có: mkdir -p .code-review/staged-lint-rules
Chmod: chmod +x .code-review/staged-lint-rules/{filename}

⚠️ KHÔNG ghi thẳng vào ~/.claude/scripts/lint-rules/rules/ — user phải duyệt trước.

OUTPUT cuối cùng — in ra terminal:
LINT HARVEST SUMMARY:
  Semantic issues processed: {N}
  Script-confirmed rules reviewed: {M}
  Rules new: {A}
  Rules updated (semantic finding): {B}
  Rules updated (script coverage gap): {C}
  Skipped (not grep-detectable): {X}
  Skipped (project-specific): {Y}
  Skipped (already covered, no update needed): {Z}

  Staged — NEW (.code-review/staged-lint-rules/):
    - {filename}.sh — {one-line description}

  Staged — UPDATED (.code-review/staged-lint-rules/):
    - {filename}.sh — {what changed vs original: e.g. "added *.tsx scope, extended regex"}
      Source: semantic finding | script coverage gap

  Not harvested (với lý do):
    - "{issue title}" → {reason}
──────────────────────────────────────────────────────

Main agent sau khi subagent hoàn thành:
- Đọc terminal output của subagent
- Append vào .code-review/REPORT.md (hoặc SUMMARY.txt nếu không có REPORT.md):

## Lint Harvest
New: {A} | Updated semantic: {B} | Updated script-gap: {C} → `.code-review/staged-lint-rules/` (chờ duyệt)
To apply sau khi duyệt:
  cp .code-review/staged-lint-rules/*.sh ~/.claude/scripts/lint-rules/rules/
{list staged filenames or "No rules harvested"}


═══════════════════════════════════════════════════════
QUY TẮC CHUNG
═══════════════════════════════════════════════════════

1. Mỗi file .code-review/*.txt phải có timestamp tạo ở header
2. Final report PHẢI viết vào `.code-review/REPORT.md` — KHÔNG dùng `plans/reports/` (giữ toàn bộ artifacts trong cùng thư mục)
3. Nếu diff < 5 file VÀ không dùng `--path` mode → skip Phase 2, main agent tự review bằng multi-pass (4 pass như mô tả trong subagent prompt) rồi viết thẳng SUMMARY.txt
4. Nếu diff > 20 file → tăng số group, mỗi group tối đa 4 file
5. KHÔNG loop Phase 1 → 2 → 3 → 4. Chạy đúng 1 lần.
6. Nếu subagent fail hoặc timeout:
   - Main agent đọc files của group đó
   - Thực hiện đúng 3-pass như trong subagent prompt
   - Ghi kết quả vào .code-review/{GROUP_NAME}.txt với header: [REVIEWED BY: MAIN AGENT — subagent failed]
   - Ghi vào SUMMARY.txt phần CONFIDENCE NOTES: "Group X reviewed by main agent — confidence thấp hơn subagent review"
7. Phase 5 (Lint Harvest) KHÔNG block merge — chạy sau Phase 4, failure không ảnh hưởng kết quả review chính.
