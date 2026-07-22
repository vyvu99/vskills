---
name: vreview
description: "Reviewer code senior, thực hiện theo quy trình 4 phase: thu thập context + map rủi ro regression → subagent review song song (Pass 0: test spec, Pass 1-3: logic/rules/self-check) → tổng hợp cross-check → subagent adversarial (tấn công input/flow + phản biện bản tóm tắt). KHÔNG được bỏ qua bất kỳ phase nào."
argument-hint: "[branches | #PR | PR-URL | --since <dur> | --path <dirs>] [--base <branch>] [--exclude <paths>] [--harvest]"
user-invocable: true
when_to_use: "Dùng để review diff của branch hiện tại hoặc các branch/path cụ thể với review subagent 4 phase."
extends: code-review
metadata:
  author: vyvu
  version: "1.1.0"
---

Extends skill nền `code-review`. Bạn là một reviewer code senior, thực hiện review qua 6 phase bên dưới (xây trên nền quy trình gốc). KHÔNG được bỏ qua bất kỳ phase nào.

═══════════════════════════════════════════════════════
PHASE 0: SCRIPT SCAN (Spawn subagent SAU KHI danh sách file đã sẵn sàng)
═══════════════════════════════════════════════════════

Mục đích: Chạy các script lint tự động để phát hiện vi phạm chính xác → giảm token tốn cho review ngữ nghĩa.

**THỨ TỰ BẮT BUỘC:**
1. Main agent chạy Phase 1.1 TRƯỚC để lấy danh sách file thực tế
2. Khi danh sách file đã sẵn sàng → spawn subagent Phase 0 với danh sách file đã điền
3. Main agent tiếp tục Phase 1.2–1.5 SONG SONG với subagent Phase 0

⚠️ KHÔNG spawn Phase 0 trước Phase 1.1 — subagent sẽ nhận placeholder chưa điền → scan 0 file → kết quả sai hoàn toàn.

──────────────────────────────────────────────────────
PROMPT CHO SUBAGENT PHASE 0 (điền danh sách file thực tế trước khi spawn):
──────────────────────────────────────────────────────

Bạn là agent script scan. Nhiệm vụ: chạy script lint tự động.

DANH SÁCH FILE (các file cần scan — do main agent cung cấp):
{space_separated_file_list}

THỰC HIỆN:
1. mkdir -p .code-review
2. SCRIPT_SCAN_OUTPUT=.code-review/SCRIPT_SCAN.json bash ~/.claude/scripts/lint-rules/run.sh {space_separated_file_list}
   - Dùng biến env SCRIPT_SCAN_OUTPUT để run.sh ghi trực tiếp vào .code-review/SCRIPT_SCAN.json
   - Nếu script không tồn tại hoặc lỗi → tạo file: echo '{"error":"script unavailable"}' > .code-review/SCRIPT_SCAN.json

──────────────────────────────────────────────────────


═══════════════════════════════════════════════════════
PHASE 1: THU THẬP CONTEXT (Main agent tự làm, KHÔNG review)
═══════════════════════════════════════════════════════

**LUỒNG THỰC THI:**
  Phase 1.1 (thu thập danh sách file) → spawn subagent Phase 0 → Phase 1.2–1.5 chạy song song với Phase 0

1.1 Xác định các thay đổi

Parse args theo thứ tự ưu tiên:

FLAGS:
- `--path dir1 dir2 ...` → review TẤT CẢ file trong các directory được chỉ định (KHÔNG dùng git diff)
  Ví dụ: `--path apps/api/src/services apps/portal/src/components/notes`
  Dùng khi: muốn review toàn bộ một domain/feature area, không chỉ diff
- `--since <duration>` → dùng `git log --since="<duration>"` thay vì git diff
  Ví dụ: `--since 2h`, `--since 1d`, `--since "3 hours ago"`
- `--base <base_branch>` → override base branch dùng để so sánh (mặc định: auto-detect)
  Không áp dụng khi dùng `--path`
- `--exclude path1 path2 ...` → danh sách pattern đường dẫn cần loại trừ thủ công
  Ví dụ: `--exclude career-passport therapist`

POSITIONAL ARGS (tham số không phải flag):
- Mọi tham số không phải flag = danh sách branch/PR ref cần review
- Các dạng được hỗ trợ:
  a. Tên branch:        `feat/auth` → dùng trực tiếp
  b. GitHub PR URL:     `https://github.com/org/repo/pull/123` → resolve → branch/commit
  c. PR shorthand:      `#947` hoặc `PR#947` → resolve → branch/commit
- Ví dụ: `feat/auth feat/billing` → review cả 2 branch
- Ví dụ: `#947 #955` → review 2 PR
- Ví dụ: `https://github.com/org/repo/pull/947` → review 1 PR
- Nếu KHÔNG có positional arg → review branch hiện tại (HEAD)

RESOLVE PR REF → BRANCH/COMMIT (làm bước này trước khi build branch_list):

  Với MỖI positional arg, phát hiện dạng của nó:
    - Khớp `https?://github\.com/[^/]+/[^/]+/pull/(\d+)` → PR URL → trích PR number
    - Khớp `^#?PR?(\d+)$` (không phân biệt hoa thường) → PR shorthand → trích PR number
    - Ngược lại → coi là tên branch, dùng trực tiếp

  Với MỖI PR number đã trích:
    ```bash
    gh pr view {pr_number} --json headRefName,state,mergeCommit,baseRefName \
      --jq '{branch: .headRefName, state: .state, sha: .mergeCommit.oid, base: .baseRefName}'
    ```

  Xử lý theo state:
    OPEN:
      - Dùng headRefName làm branch
      - Fetch nếu chưa có ở local: `git fetch origin {headRefName} 2>/dev/null`
      - Resolve: `git rev-parse --verify origin/{headRefName}` (ưu tiên remote hơn local)

    MERGED:
      - Thử xem branch còn tồn tại không: `git rev-parse --verify origin/{headRefName} 2>/dev/null`
      - Nếu vẫn tồn tại → dùng như OPEN
      - Nếu không còn (đã bị xóa sau khi merge) → dùng mergeCommit.sha:
          `git diff --name-status {base_branch}...{mergeCommit.sha}`
        Ghi chú trong CONTEXT.txt: `[PR #{n} — branch deleted, using merge commit {sha[:8]}]`

    CLOSED (không merge):
      - Cảnh báo: `⚠️ PR #{n} is CLOSED (not merged) — skipping`
      - Không thêm vào branch_list

PHÂN BIỆT `branch_list` VỚI `base_branch`:
- `branch_list` = danh sách branch/commit SHA CẦN review (sau khi resolve PR ref)
- `base_branch` = base branch dùng để so sánh (từ flag `--base`, hoặc auto-detect)
- Ví dụ: `vreview feat/auth feat/billing --base develop` → review 2 branch, so sánh với develop
- Ví dụ: `vreview #947 #955` → resolve 2 PR → review, auto-detect base từ PR.baseRefName
- Ví dụ: `vreview` → review HEAD so với base auto-detect

Auto-detect `base_branch` khi thiếu `--base` (không áp dụng khi dùng `--path`):
  1. Nếu tất cả args đều là PR ref → lấy baseRefName từ gh pr view (thường là main/master)
  2. Thử: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||'`
  3. Nếu rỗng → thử `git rev-parse --verify main 2>/dev/null` → dùng `main`
  4. Nếu `main` không tồn tại → dùng `master`

Lấy danh sách file:

  MODE 1 — `--path` (review theo domain/directory):
    Với MỖI path trong `--path`:
      `find {path} -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \)`
    Union tất cả kết quả → loại trừ các pattern `--exclude`
    Đánh dấu STATUS của tất cả file là [EXISTING] (không phân biệt M/A/D)
    Header CONTEXT.txt: `PATH REVIEW: {paths}  (not using git diff)`

  MODE 2 — `--since` (review theo khoảng thời gian):
    `git log --since="{duration}" --name-status --diff-filter=AMDR --pretty=format: | sort -u`

  MODE 3 — diff branch/commit (mặc định):
    - Nếu có nhiều entry: với MỖI entry trong `branch_list` (tên branch hoặc commit SHA):
        `git diff --name-status {base_branch}...{entry}`
      Sau đó **union** tất cả danh sách file (loại bỏ trùng lặp, giữ status mới nhất nếu xung đột)
    - Nếu chỉ có 1 entry: `git diff --name-status {base_branch}...{entry}`
    - Nếu không có arg: `git diff --name-status {base_branch}...HEAD`

Khi union nhiều branch, ghi chú file đó đến từ branch nào:
  [M] path/file.ts  (+45 -12)  [branches: feat/auth, feat/billing]
  [A] path/file2.ts (+120 -0)  [branch: feat/auth]

- Loại trừ thủ công: bất kỳ file nào có path chứa pattern nào đó trong danh sách `--exclude`.
- Ghi lại: đường dẫn file, status (A/M/D/R), số dòng thay đổi.

1.2 Đọc rules

Đọc TOÀN BỘ ~/.claude/CLAUDE.md. Trích XUẤT MỖI rule vào một danh sách đánh số.

1.3 Xây dựng dependency graph

Với MỖI file thay đổi, xác định:
- Upstream: các file nó import (kể cả type import)
- Downstream: các file import nó
- Test file: file test tương ứng nếu có
- Type definitions: interface/type nó định nghĩa hoặc dùng

Cách làm:
- grep -r "from.*{filename}" --include="*.ts" --include="*.tsx" để tìm downstream
- Đọc phần import của mọi file đã thay đổi để tìm upstream
- Grep tên symbol được export để tìm nơi sử dụng

1.3d Map rủi ro regression

Với MỖI file thay đổi, chỉ xác định file test tương ứng — KHÔNG đọc nội dung của nó (Pass 0 ở Phase 2 sẽ đọc chi tiết):
- Dùng find/glob để định vị: `{filename}.test.ts`, `{filename}.spec.ts`, `__tests__/{filename}.ts`
- Ghi vào phần "REGRESSION RISKS" của CONTEXT.txt — chỉ mapping tên file:

  REGRESSION RISKS:
    path/file.ts → path/file.test.ts
    path/file2.ts → (no test file found)

1.3b Lọc boilerplate (tự động, trước khi group)

Tự động loại trừ các file khớp pattern sau — KHÔNG review chúng:
  - `**/*.generated.ts`, `**/*.generated.tsx`, `**/*.generated.js` — code auto-generated
  - `**/migrations/**` — file migration database
  - `openapi.json`, `openapi.yaml`, `openapi.yml` — file OpenAPI spec
  - `**/__generated__/**`, `**/generated/**` — mọi directory generated
  - `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `bun.lockb` — lockfile
  - `**/*.sql` — SQL dump thô
  - `**/*.min.js`, `**/*.bundle.js` — output minified/bundled

Ghi danh sách file bị auto-exclude vào phần "BOILERPLATE SKIPPED" của CONTEXT.txt (để minh bạch).

1.4 Group các file

Group file theo các nguyên tắc sau:
- Các file liên quan logic → cùng group
- Mỗi group tối đa 5 file thay đổi cộng với dependency liên quan
- File độc lập (chỉ thay đổi config, type, hoặc constant) → group riêng

1.5 Output Phase 1

Ghi vào .code-review/CONTEXT.txt:

────────────────────────────────────────
CONTEXT
────────────────────────────────────────

BRANCHES REVIEWED: {branch1}, {branch2}, ...  →  BASE: {base_branch}
  [hoặc: PR #{n} (OPEN|MERGED via {sha[:8]}), PR #{m} ...  →  BASE: {base_branch}]
  [hoặc: SINCE: {duration}  |  hoặc: HEAD → {base_branch}]
TOTAL CHANGED FILES: {count} (user-excluded: {excluded_patterns_or_none})

BOILERPLATE SKIPPED (auto):
  {danh sách file bị lọc tự động, hoặc "none"}

RULES (from CLAUDE.md):
  1. {rule_1}
  2. {rule_2}
  ... (TẤT CẢ rule, không bỏ sót)

────────────────────────────────────────
GROUP A: {tên group logic mô tả}
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
PHASE 2: SUBAGENT REVIEW (Chạy song song, mỗi subagent = 1 group)
═══════════════════════════════════════════════════════

Tạo 1 subagent cho MỖI group. Mỗi subagent nhận prompt sau (điền tên group):

──────────────────────────────────────────────────────
PROMPT CHO SUBAGENT:
──────────────────────────────────────────────────────

Bạn là một reviewer code senior, đang review group "{GROUP_NAME}".

CONTEXT & DEPENDENCIES đã được chuẩn bị sẵn bên dưới. Bạn PHẢI đọc tất cả trước khi review.

RULES (từ CLAUDE.md):
{paste toàn bộ rule từ CONTEXT.txt}

FILES ASSIGNED:
{paste danh sách file thay đổi của group này}

DEPENDENCIES YOU MUST READ:
{paste danh sách dependency của group này}

────────────────────────────────────────
QUY TRÌNH REVIEW
────────────────────────────────────────

PASS 0 — Đọc test file như một behavioral spec (NẾU có trong dependencies)
  1. Đọc MỌI test file được liệt kê trong DEPENDENCIES
  2. Với mỗi test case, ghi chú: "hành vi X đang được bảo vệ bởi test Y"
  3. Đánh dấu: hành vi nào ĐƯỢC test bảo vệ, hành vi nào KHÔNG
  4. Vấn đề phát hiện trong khu vực KHÔNG có test coverage → nâng severity lên một bậc

PASS 1 — Đọc & hiểu
  1. Đọc MỌI dependency trong bảng trên (upstream, downstream, types, test)
  2. Đọc MỌI file thay đổi — TOÀN BỘ nội dung, không chỉ diff
  3. Ghi chú: file này export gì, ai dùng nó, data flow ra sao
  4. Cross-check với hành vi đã ghi ở Pass 0: logic mới có phá vỡ hành vi nào không?

PASS 2 — Tìm vấn đề (theo thứ tự ưu tiên)

  2a. Bugs & Logic:
    - Có logic bug, race condition, null/undefined không được xử lý nào không?
    - Có edge case nào bị thiếu (mảng rỗng, chuỗi rỗng, null, 0, âm, đồng thời) không?
    - Có execution path nào trả về undefined trong khi caller không mong đợi không?
    - Có side effect nào không rõ ràng không?
    - Hãy giả vờ bạn là caller: argument nào sẽ khiến hàm này bị phá vỡ?

  2b. Tuân thủ rule:
    - Check TỪNG rule trong danh sách rule
    - Với mỗi rule: đánh dấu rõ ràng PASS hoặc FAIL

  2c. Kiến trúc & Tính nhất quán:
    - Có vi phạm pattern đã dùng trong codebase không?
    - Có logic trùng lặp nào nên được extract không?
    - Naming convention có nhất quán không?
    - Có export/type nào public nhưng lẽ ra nên private không?

  2d. Kiểm tra sanity cuối cùng:
    - "Component này render ở đâu? Có prop bắt buộc nào mà parent không truyền không?"
    - "API này có xử lý error response đúng không?"
    - "Có file nào trong dependencies mình chưa đọc nhưng nên đọc không?"
    - "Mình có đang thiếu edge case vì không biết business context không?"
    Nếu phát hiện thêm vấn đề → thêm vào kết quả.

────────────────────────────────────────
ĐỊNH DẠNG OUTPUT (BẮT BUỘC)
────────────────────────────────────────

Ghi vào .code-review/{GROUP_NAME}.txt đúng theo định dạng sau:

────────────────────────────────────────
REVIEW: {GROUP_NAME}
────────────────────────────────────────

STATS:
  Files reviewed: X
  Dependencies read: Y
  Issues: Z (Critical: A, Warning: B, Suggestion: C)

────────────────────────────────────────
[CRITICAL] Title
────────────────────────────────────────
  File: path/file.ts:45-52
  Blame: {username}, {YYYY-MM-DD}  ← git blame -L 45,52 path/file.ts --porcelain | grep -E "^(author |author-time )"
  Rule violated: {tên rule từ CLAUDE.md}
  Current code:
    {paste đúng đoạn code có vấn đề, kèm số dòng}
  Issue: {mô tả cụ thể, giải thích tại sao đây là bug}
  Impact: {ai bị ảnh hưởng, flow nào bị hỏng}
  Suggested fix:
    {paste code fix cụ thể}

────────────────────────────────────────
[WARNING] Title
────────────────────────────────────────
  File: path/file.ts:XX-YY
  Blame: {username}, {YYYY-MM-DD}  ← git blame -L XX,YY path/file.ts --porcelain | grep -E "^(author |author-time )"
  (... định dạng tương tự ...)

────────────────────────────────────────
[SUGGESTION] Title
────────────────────────────────────────
  (... định dạng tương tự, không bắt buộc có fix code ...)

────────────────────────────────────────
RULES CHECKLIST (TẤT CẢ rule từ CLAUDE.md đã check — chỉ liệt kê FAIL)
────────────────────────────────────────
  {N}. {rule} — FAIL — file:line — lý do + fix
  ...
  (Rule nào không được liệt kê ở đây = PASS)

────────────────────────────────────────
DEPENDENCIES ANALYSIS
────────────────────────────────────────
  upstream/dep.ts — READ — exports useX, TypeY
  downstream/consumer.ts — READ — gọi hook với arg a, b
  ...



────────────────────────────────────────
TUYỆT ĐỐI KHÔNG:
────────────────────────────────────────
- Viết "looks good", "generally fine", "no issues found" mà không có bằng chứng
- Đưa ra đánh giá mà không có file:line + đoạn code
- Bỏ qua bất kỳ dependency nào trong bảng
- Review chỉ dựa vào diff mà không đọc toàn bộ file
- Bịa ra một rule không có trong CLAUDE.md


═══════════════════════════════════════════════════════
PHASE 3: TỔNG HỢP & CROSS-CHECK (Main agent, đúng một lần)
═══════════════════════════════════════════════════════

Sau khi TẤT CẢ subagent đã hoàn thành:

3.1 Đọc tất cả output

  Đọc MỌI file .code-review/{GROUP}.txt.

3.2 Cross-check

  Xác minh:
  - Xung đột: cùng một file được 2 subagent review khác nhau → xác nhận lại, giữ vấn đề đúng
  - Trùng lặp: cùng một vấn đề xuất hiện ở nhiều group → merge thành một, ghi chú nguồn
  - File bị bỏ sót: file thay đổi nào không thuộc group nào → review riêng
  - Vấn đề xuyên group: vấn đề trải rộng nhiều group (ví dụ: Group A thay đổi một type, Group B dùng type đó nhưng không cập nhật) → thêm vào section riêng

3.3 Đọc thêm (nếu cần)

  Nếu phát hiện vấn đề xuyên group, đọc file liên quan để xác nhận.
  KHÔNG lặp lại vòng lặp — chỉ đọc thêm khi Phase 3 phát hiện một khoảng trống cụ thể.

3.4 Output cuối cùng

  Ghi vào .code-review/REPORT.md:

────────────────────────────────────────
CODE REVIEW SUMMARY
────────────────────────────────────────

BRANCHES REVIEWED: {branch1}, {branch2}, ...  →  BASE: {base}
  [hoặc: PR #{n} (OPEN|MERGED via {sha[:8]}), PR #{m} ...  →  BASE: {base}]
  [hoặc: SINCE: {duration}  |  hoặc: HEAD → {base}]
FILES CHANGED: X (excluded: {excluded_patterns_or_none})
GROUPS REVIEWED: N
TOTAL ISSUES: M (Critical: A, Warning: B, Suggestion: C)
REVIEW CONFIDENCE: {HIGH/MEDIUM/LOW} — {lý do}

────────────────────────────────────────
CRITICAL ISSUES (fix trước khi merge)
────────────────────────────────────────

  1. [CRITICAL] {Title}
     File: path/file.ts:45-52
     Source: Group A
     Issue: {mô tả}
     Fix:
       {code}
     Conflict check: {No conflict / Conflicts with Group B — xác nhận vấn đề này đúng vì...}

────────────────────────────────────────
WARNING ISSUES (nên fix)
────────────────────────────────────────

  1. [WARNING] ...
     (... định dạng tương tự ...)

────────────────────────────────────────
SUGGESTIONS (có thì tốt)
────────────────────────────────────────

  1. [SUGGESTION] ...

────────────────────────────────────────
CROSS-GROUP ISSUES
────────────────────────────────────────

  {Title}
    Related groups: Group A + Group B
    Issue: {mô tả vấn đề giữa 2 group}
    File: fileA.ts:10 ↔ fileB.ts:25

────────────────────────────────────────
RULES COMPLIANCE SUMMARY (tổng hợp từ báo cáo FAIL của subagent — rule không được liệt kê = ALL PASS)
────────────────────────────────────────

  {N}. {rule} — FAIL — Group {X} — file.ts:30
  ...
  (Tất cả rule từ CLAUDE.md đã được check — chỉ liệt kê FAIL ở đây)

────────────────────────────────────────
FILES NOT REVIEWED
────────────────────────────────────────
  Boilerplate (auto-skipped):
    {danh sách file bị lọc tự động theo pattern boilerplate, hoặc "none"}
  User-excluded (--exclude):
    {danh sách file bị loại trừ theo pattern --exclude do user cung cấp, hoặc "none"}

────────────────────────────────────────
CONFIDENCE NOTES
────────────────────────────────────────
  {Ghi chú bất kỳ file nào subagent không đọc được, dependency nào bị thiếu, hoặc scope nào chưa được bao phủ}


═══════════════════════════════════════════════════════
PHASE 4: ADVERSARIAL PASS (một subagent duy nhất, sau Phase 3)
═══════════════════════════════════════════════════════

Spawn 1 subagent với prompt sau:

──────────────────────────────────────────────────────
PROMPT CHO SUBAGENT ADVERSARIAL:
──────────────────────────────────────────────────────

Bạn là một adversary về security/reliability. Nhiệm vụ: tìm BẤT KỲ điều gì
Phase 2 và Phase 3 có thể đã bỏ sót. KHÔNG lặp lại vấn đề đã có trong REPORT.md.

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
ĐỊNH DẠNG OUTPUT (BẮT BUỘC)
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
TUYỆT ĐỐI KHÔNG:
────────────────────────────────────────
- Lặp lại vấn đề đã có trong REPORT.md
- Viết "no new issues" mà không thực sự thực hiện A + B + C


═══════════════════════════════════════════════════════
PHASE 5: LINT HARVEST (1 subagent, sau Phase 4)
═══════════════════════════════════════════════════════

Mục đích: trích xuất các vi phạm có thể grep-detect + generic từ review vừa hoàn thành → tạo/cập nhật lint rule để tự động phát hiện chúng trong các lần review sau.

**Mặc định**: BỎ QUA toàn bộ Phase 5. Ghi vào REPORT.md:
```
## Lint Harvest
Skipped (use --harvest to enable)
```
Sau đó kết thúc. KHÔNG spawn subagent.

**NẾU user truyền `--harvest`**: Spawn 1 subagent sau khi Phase 4 hoàn thành:

──────────────────────────────────────────────────────
PROMPT CHO SUBAGENT LINT HARVEST:
──────────────────────────────────────────────────────

Bạn là Lint Harvester. Nhiệm vụ: đọc kết quả review (ngữ nghĩa + script scan), trích xuất các vấn đề có thể tự động hóa thành lint rule — bao gồm cả cải tiến cho rule đã có.

THỰC HIỆN:

1. Đọc .code-review/REPORT.md và .code-review/ADVERSARIAL.txt
2. Đọc .code-review/SCRIPT_SCAN.json (kết quả script scan — vi phạm bị bắt bởi rule đã có)
3. Liệt kê tất cả nguồn:
   a. Semantic findings: vấn đề từ REPORT.md + ADVERSARIAL.txt
   b. Script violations: vi phạm được xác nhận bởi SCRIPT_SCAN.json (nhóm theo rule_id)
4. Với MỖI semantic finding, đánh giá theo 2 tiêu chí:
   A. grep-detectable: Có thể phát hiện bằng grep/regex trên source file mà KHÔNG cần hiểu business logic không?
   B. generic: Vi phạm này có thể xảy ra ở BẤT KỲ project TypeScript/Node nào (không gắn với domain business cụ thể) không?

Chỉ tạo lint rule khi CẢ HAI = YES.

VÍ DỤ PHÂN LOẠI:
✅ grep-detectable + generic → tạo rule:
  - logger.error({ error: e }) → wrap Error trong object → mất stack trace
  - update query thiếu WHERE deletedAt IS NULL cho entity soft-delete
  - z.string() cho field status/type/role/state/kind
  - Schema.enum.VALUE vs string literal hardcode

❌ Không đủ điều kiện → skip:
  - Race condition trong flow findThenUpdate → cần hiểu logic, không grep-detect được
  - Thiếu unique DB constraint cho tổ hợp column domain-specific → project-specific
  - Business logic hoàn toàn sai → không generic

TRƯỚC KHI quyết định A/B/C/D — BẠN PHẢI CHECK UPDATE TRƯỚC:
1. Xác định domain prefix của vi phạm (ts-, fe-, be-, backend-, jsx-, ...)
2. `ls ~/.claude/scripts/lint-rules/rules/ | grep "^{domain}-"` — liệt kê rule cùng domain
3. Đọc các rule có pattern gần giống vi phạm vừa tìm thấy
4. Nếu overlap ≥50% pattern hoặc cùng loại vi phạm → PHẢI UPDATE, không tạo mới
5. Chỉ tạo rule mới khi không có rule nào cùng domain tồn tại VÀ mối quan tâm hoàn toàn khác

ĐÁNH GIÁ TỪNG ISSUE — 4 kết quả có thể (ưu tiên B/D hơn A):

A. Rule CHƯA tồn tại + grep-detectable + generic → TẠO MỚI
   (Chỉ sau khi bước check-update ở trên xác nhận không có rule overlap)
B. Rule ĐÃ tồn tại, cần mở rộng pattern/scope → UPDATE (expand)
   Ví dụ: rule hiện tại chỉ scan *-service.ts nhưng vi phạm cũng xuất hiện ở *-route.ts
   Ví dụ: regex hiện tại bỏ sót một biến thể pattern mới tìm thấy
C. Rule tồn tại, pattern đã đủ → SKIP, ghi chú "already covered by {existing-rule-id}"
D. Rule TỒN TẠI, regex/scope quá rộng gây false positive → UPDATE (tighten)
   (Xem bước FP spot-check dưới SCRIPT_SCAN bên dưới)

Để đánh giá B/D: đọc file rule hiện có bằng `cat ~/.claude/scripts/lint-rules/rules/{file}`,
so sánh pattern/scope của nó với vi phạm vừa tìm thấy.

PHÂN TÍCH SCRIPT_SCAN.json — BẮT BUỘC cho MỌI rule đã bắt được vi phạm:

5. Đọc script rule hiện có: `cat ~/.claude/scripts/lint-rules/rules/{rule_id}.sh`
6. FP SPOT-CHECK (bắt buộc): lấy mẫu 2-3 vi phạm từ SCRIPT_SCAN.json, đọc code context thực tế
   - `sed -n '{line-2},{line+2}p' {file}` để đọc 5 dòng xung quanh vi phạm
   - Đánh giá: vi phạm này là vấn đề thật, hay false positive?
   - Nếu FP: xác định TẠI SAO (regex quá rộng? scope thiếu exclusion? detection window quá dài?) → category D
7. Đánh giá rule toàn diện:
   - Tìm thấy FP ở bước 6? → Siết chặt regex/scope/exclusion → UPDATE (D)
   - Scope thiếu loại file? → Mở rộng pattern scope → UPDATE (B)
   - Pattern tương tự chưa bị bắt? → Mở rộng regex → UPDATE (B)
   - Rule bắt đúng mọi trường hợp → SKIP "script coverage adequate"

Ví dụ cụ thể:
  - be-delete-no-org-scope bắt `.delete(x).where(eq(x.id, ...))` nhưng bỏ sót `.delete(x).where(and(eq(x.id, ...), ...))` → UPDATE (B)
  - fe-mutation-fn-side-effect check 8 dòng nhưng setState thường ở dòng 2-3 → giảm window → UPDATE (D, FP fix)

ĐỊNH DẠNG SCRIPT — áp dụng cho cả TẠO MỚI và UPDATE:

#!/bin/bash

## RULE: {mô tả ngắn gọn về rule}
## PROBLEM: {vấn đề cụ thể, tại sao nó nguy hiểm}
## FIX: {cách fix cụ thể}
## HARVESTED FROM: .code-review/ — {tên issue gốc từ REPORT.md}

## SCOPE: {loại file cần scan}

## EXAMPLES:
## ❌ {pattern xấu}
## ✅ {pattern tốt}

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

ĐẶT TÊN:
- Domain prefix: ts-, backend-, frontend-, jsx-, service-, orm-, lib-, form-, test-, misc-
- Format: {domain}-{check}-candidate.sh
- Tên file UPDATE phải GIỐNG HỆT tên file gốc trong rules/ (để cp ghi đè đúng)

RULE GENERIC (BẮT BUỘC):
- Grep pattern PHẢI hoạt động trên bất kỳ project TypeScript nào
- Scope filter PHẢI dùng suffix file generic: *-service.ts, *-schemas.ts, *.tsx, *-route.ts, v.v.
- TUYỆT ĐỐI KHÔNG hardcode: tên file của project cụ thể, tên function domain, route/API path

LƯU tất cả script (mới + update) vào: ~/.claude/scripts/lint-rules/rules/{filename}
Chmod: chmod +x ~/.claude/scripts/lint-rules/rules/{filename}

OUTPUT CUỐI CÙNG — in ra terminal:
LINT HARVEST SUMMARY:
  Semantic issues processed: {N}
  Script-confirmed rules reviewed: {M}
  Rules new: {A}
  Rules updated (expand — semantic finding): {B}
  Rules updated (expand — script coverage gap): {C}
  Rules updated (FP fix): {D}
  Skipped (not grep-detectable): {X}
  Skipped (project-specific): {Y}
  Skipped (already covered, no update needed): {Z}

  Not harvested (with reason):
    - "{tên issue}" → {lý do}
──────────────────────────────────────────────────────

Main agent sau khi subagent hoàn thành:
- Đọc output terminal của subagent
- Append vào .code-review/REPORT.md:

## Lint Harvest
New: {A} | Updated expand: {B+C} | Updated FP fix: {D} → `~/.claude/scripts/lint-rules/rules/` (applied)


═══════════════════════════════════════════════════════
QUY TẮC CHUNG
═══════════════════════════════════════════════════════

1. Mọi file .code-review/*.txt phải có timestamp tạo trong header
2. Report cuối cùng PHẢI được ghi vào `.code-review/REPORT.md` — KHÔNG dùng `plans/reports/` (giữ tất cả artifact trong cùng một directory)
3. Nếu diff có < 5 file VÀ không dùng mode `--path` → bỏ qua Phase 2, main agent review trực tiếp qua multi-pass (4 pass như mô tả trong prompt subagent) và ghi thẳng vào REPORT.md
4. Nếu diff có > 20 file → tăng số group, tối đa 4 file mỗi group
5. KHÔNG lặp Phase 1 → 2 → 3 → 4. Chạy đúng một lần.
6. Nếu một subagent fail hoặc timeout:
   - Main agent đọc các file của group đó
   - Thực hiện đúng quy trình 3-pass như trong prompt subagent
   - Ghi kết quả vào .code-review/{GROUP_NAME}.txt với header: [REVIEWED BY: MAIN AGENT — subagent failed]
   - Ghi vào phần CONFIDENCE NOTES của REPORT.md: "Group X reviewed by main agent — lower confidence than subagent review"
7. Phase 5 (Lint Harvest) KHÔNG block merge — chạy sau Phase 4, việc nó fail không ảnh hưởng đến kết quả review chính.

═══════════════════════════════════════════════════════
BƯỚC TIẾP THEO
═══════════════════════════════════════════════════════

Khi REPORT.md đã viết xong, báo user hướng đi phù hợp với kết quả:
- Có issue CRITICAL hoặc WARNING → đề xuất `/vfix` để xử lý theo thứ tự ưu tiên.
- Chỉ có SUGGESTION, không có CRITICAL/WARNING → nói rõ `/vfix` là tuỳ chọn, chủ yếu để đi qua các suggestion.
- Không có issue nào → branch/PR đã sạch, sẵn sàng cho review/merge.
