---
name: vreview
description: "Review một diff, PR, branch, hoặc directory với vai trò reviewer code senior, ghi finding vào .code-review/REPORT.md, nhóm theo CRITICAL/WARNING/SUGGESTION. Dùng trước khi merge."
argument-hint: "[branches | #PR | PR-URL | --since <dur> | --path <dirs>] [--base <branch>] [--exclude <paths>] [--harvest]"
user-invocable: true
when_to_use: "Dùng để review diff của branch hiện tại hoặc các branch/path cụ thể với review subagent 4 phase (kèm phase pre-scan và lint-harvest tùy chọn)."
metadata:
  author: vyvu
  version: "1.2.0"
---

Bạn là một reviewer code senior, thực hiện review qua 4 phase cốt lõi (1-4) bên dưới, bao quanh bởi Phase 0 pre-scan tùy chọn và Phase 5 lint harvest tùy chọn, cộng thêm Phase 4.5 spot-check nhẹ. KHÔNG được bỏ qua bất kỳ phase nào.

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

Đọc `references/phase0-prescan-prompt.vi.md` và dùng nội dung đó **nguyên văn** làm prompt cho subagent ở phase này — không tóm tắt hay diễn giải lại khi truyền tiếp.

──────────────────────────────────────────────────────


═══════════════════════════════════════════════════════
PHASE 1: THU THẬP CONTEXT (Main agent tự làm, KHÔNG review)
═══════════════════════════════════════════════════════

**LUỒNG THỰC THI:**
  1.0 (check incremental) → Phase 1.1 (thu thập danh sách file) → spawn subagent Phase 0 → Phase 1.2–1.5 chạy song song với Phase 0

1.0 Check review trước đó (incremental mode — chỉ Mode 3, xem 1.1)

Trước khi build file list: nếu `.code-review/REPORT.md` đã tồn tại, đọc header tìm dòng `REVIEWED_COMMIT:`.
  - Không có `REVIEWED_COMMIT` (report cũ, hoặc file chưa tồn tại) → full review, bỏ qua phần còn lại của 1.0.
  - Có, `{prev_sha}` vẫn resolve được (`git cat-file -e {prev_sha} 2>/dev/null`), và `{prev_sha}` != HEAD hiện tại → incremental mode:
      Copy report cũ trước khi bị ghi đè: `cp .code-review/REPORT.md .code-review/REPORT.prev.md`
      `git diff --name-status {prev_sha}...HEAD` → file đã đổi KỂ TỪ lần review trước
      Khi build file list ở 1.1, gắn tag mỗi file:
        đổi kể từ `{prev_sha}` → `[NEW-SINCE-LAST-REVIEW]`
        không đổi kể từ `{prev_sha}` nhưng vẫn nằm trong diff base...HEAD hiện tại → `[CARRIED-FORWARD]`
      Phase 1.4 chỉ nhóm file `[NEW-SINCE-LAST-REVIEW]` (kèm dependency) cho Phase 2. File `[CARRIED-FORWARD]` bỏ qua Phase 2 — Phase 3.1b copy finding cũ từ `REPORT.prev.md` thay vì review lại.
  - Có và `{prev_sha}` == HEAD hiện tại (chạy lại mà không có gì mới) → bỏ qua Phase 0/2/4 hoàn toàn, copy `REPORT.md` nguyên vẹn kèm note đầu file `No changes since last review ({prev_sha[:8]})`, dừng lại.

Chỉ áp dụng cho MODE 3 (diff branch/commit). Mode `--path` và `--since` luôn review full — không có "commit trước đó" nào để diff.

1.1 Xác định các thay đổi

Resolve repo profile trước: đọc `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (host + khả năng dùng gh) và §3 (tally ngôn ngữ/framework, dùng từ Phase 2 trở đi). Fallback nếu file không tồn tại: GitHub + gh + TypeScript, tức là assumption hiện tại. Một rule CLAUDE.md nêu tên ngôn ngữ/framework cụ thể (rule TypeScript, rule React/Next.js, rule Tailwind) chỉ áp dụng cho file thuộc ngôn ngữ/framework đó trong diff — file `.py` hoặc `.go` không được flag theo rule TypeScript. Check thuộc nhóm security (secret, injection, authz) là ngôn ngữ-agnostic và áp dụng cho MỌI file bất kể tally. Nơi không có rule nào áp dụng cho ngôn ngữ của file → review theo nguyên tắc chung (naming, error handling, security, dead code) thay vì bỏ qua.

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
    Full gh mode (theo §2) →
    ```bash
    gh pr view {pr_number} --json headRefName,state,mergeCommit,baseRefName \
      --jq '{branch: .headRefName, state: .state, sha: .mergeCommit.oid, base: .baseRefName}'
    ```
    Degraded mode → in thông báo §2 của vreview (`⚠️ can't resolve PR refs without gh — pass a branch name instead; branch/diff modes work without gh`), bỏ positional arg này khỏi `branch_list`, và tiếp tục với các arg còn lại. Nếu `branch_list` rỗng sau khi bỏ hết PR ref, fallback về review HEAD (hành vi mặc định khi không có arg đã mô tả ở trên) thay vì abort.

  Xử lý theo state (chỉ áp dụng full gh mode):
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
  1. Nếu tất cả args đều là PR ref VÀ full gh mode (theo §2) → lấy baseRefName từ gh pr view (thường là main/master). Degraded mode → chuyển sang bước 2.
  2. Thử: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||'`
  3. Nếu rỗng → thử `git rev-parse --verify main 2>/dev/null` → dùng `main`
  4. Nếu `main` không tồn tại → dùng `master`

Lấy danh sách file:

  MODE 1 — `--path` (review theo domain/directory):
    Extension cần scan = extension nguồn của mọi ngôn ngữ có mặt trong tally §3 repo-profile (vd: TypeScript(12) → *.ts *.tsx; Python(3) → *.py; Go → *.go; Rust → *.rs; Java/Kotlin → *.java *.kt). Chưa resolve tally → resolve trước (repo-profile §3), rồi mới dùng kết quả ở đây.
    Với MỖI path trong `--path`:
      `find {path} -type f \( -name "*.{ext1}" -o -name "*.{ext2}" ... \)`  (1 clause `-o -name` cho mỗi extension đã resolve ở trên)
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

Pattern tìm import theo ngôn ngữ (dựa vào tally §3 repo-profile đã resolve ở bước 1.1) — thay {module} bằng tên module/basename của file đã đổi (bỏ extension):
  TypeScript/JavaScript → `from ['"].*{module}['"]` hoặc `require\(.*{module}\)`
  Python                → `from .*{module} import` hoặc `^import {module}`
  Go                    → `"{import_path}"` trong block `import (...)`
  Rust                  → `use .*{module}`
  Java/Kotlin           → `import .*\.{ClassName}`
  Khác / không match    → bỏ qua grep theo cú pháp import, chỉ dùng grep exported-symbol bên dưới

Với MỖI file thay đổi, xác định:
- Upstream: các file nó import (kể cả type import)
- Downstream: các file import nó
- Test file: file test tương ứng nếu có
- Type definitions: interface/type nó định nghĩa hoặc dùng

Cách làm:
- grep -r dùng pattern ở trên (khớp với ngôn ngữ của file) để tìm downstream
- Đọc phần import của mọi file đã thay đổi để tìm upstream
- Grep tên symbol được export để tìm nơi sử dụng

Tag coverage-confidence (wiring dạng grep-based sẽ miss các case này — chỉ gắn tag, không cố resolve):
  - File nằm trong directory có `index.ts`/`index.js`/`index.py` (barrel re-export) → tag `[heuristic-incomplete: barrel-reexport]`
  - File/symbol mang marker DI/framework (`@Injectable`, `@Controller`, `@Component`, `@Service`, Spring `@Autowired`, đăng ký route bằng decorator) → tag `[heuristic-incomplete: DI-wiring]`
  - Framework = Next.js/Nuxt/SvelteKit/Remix (file-based routing — không có import nào nối route với caller) → tag `[heuristic-incomplete: file-based-routing]`
  Ghi tag cạnh dependency entry của file đó trong CONTEXT.txt (output 1.5). Subagent Phase 2 thấy file bị tag PHẢI đọc rộng hơn (kiểm tra barrel index / module DI / route registration) thay vì tin tuyệt đối vào edge list từ grep.

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
  - `Cargo.lock`, `go.sum`, `poetry.lock`, `Gemfile.lock`, `composer.lock` — lockfile của ecosystem khác
  - `**/*.sql` — SQL dump thô
  - `**/*.min.js`, `**/*.bundle.js` — output minified/bundled

Ghi danh sách file bị auto-exclude vào phần "BOILERPLATE SKIPPED" của CONTEXT.txt (để minh bạch).

1.3c Early exit cho diff trivial / rỗng sau khi filter

Rỗng sau khi filter: nếu file list rỗng sau 1.3b (mọi file thay đổi đều là boilerplate, hoặc diff vốn rỗng) → bỏ qua Phase 0, 2, 3, 4 hoàn toàn. Ghi `.code-review/REPORT.md` chỉ với header block, `TOTAL ISSUES: 0`, và note 1 dòng "No reviewable files (all changes were boilerplate/docs)". Dừng lại — không spawn subagent nào.

File chỉ đổi comment/whitespace: với mỗi file còn lại, check xem mọi hunk thay đổi có phải chỉ comment/whitespace không:
  `git diff -U0 {base_branch}...{entry} -- {file} | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)' | grep -vE '^[+-]\s*(//|#|\*|/\*|"""|--)'`
  Kết quả rỗng → diff của file đó chỉ đổi comment/whitespace. Tag `[COMMENT-ONLY]` trong CONTEXT.txt, loại khỏi grouping ở 1.4 (vẫn xuất hiện trong "FILES NOT REVIEWED" của báo cáo cuối, không âm thầm bỏ), và không tính vào ngưỡng >20-file / <5-file ở GENERAL RULES.
  Chỉ best-effort — bỏ qua check này với ngôn ngữ không match cú pháp comment nào ở trên, không bao giờ block review vì nó.

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
PROFILE: lang={tally, vd TypeScript(12) Python(2)} · framework={framework} · host={host_mode} · pm={pm}
INCREMENTAL: {no  |  yes, kể từ {prev_sha[:8]} — {N} mới, {M} carried forward}

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

Tạo 1 subagent cho MỖI group. Mỗi subagent nhận prompt bên dưới (điền tên group).

──────────────────────────────────────────────────────
PROMPT CHO SUBAGENT:
──────────────────────────────────────────────────────

Đọc `references/subagent-prompt.vi.md` và dùng nội dung đó **nguyên văn** làm prompt cho subagent ở phase này — không tóm tắt hay diễn giải lại khi truyền tiếp. Điền {GROUP_NAME}, RULES, FILES ASSIGNED, DEPENDENCIES trước khi spawn.

──────────────────────────────────────────────────────


═══════════════════════════════════════════════════════
PHASE 3: TỔNG HỢP & CROSS-CHECK (Main agent, đúng một lần)
═══════════════════════════════════════════════════════

Sau khi TẤT CẢ subagent đã hoàn thành:

3.1 Đọc tất cả output

  Đọc MỌI file .code-review/{GROUP}.txt.

3.1b Carry forward (chỉ incremental mode, theo 1.0)

  Với mỗi file tag `[CARRIED-FORWARD]` trong CONTEXT.txt: đọc entry của nó từ `.code-review/REPORT.prev.md`, copy các item CRITICAL/WARNING/SUGGESTION vào working set của lần chạy này, append `(carried forward from previous review)` vào mỗi item. KHÔNG review lại các file này ở Phase 2 — đã bị skip từ 1.0.

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
REVIEWED_COMMIT: {sha HEAD hiện tại}  [previous: {prev_sha[:8] hoặc "none"}]

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
     Status: PENDING

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
    Status: PENDING

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

Spawn 1 subagent với prompt bên dưới:

──────────────────────────────────────────────────────
PROMPT CHO SUBAGENT ADVERSARIAL:
──────────────────────────────────────────────────────

Đọc `references/adversarial-prompt.vi.md` và dùng nội dung đó **nguyên văn** làm prompt cho subagent ở phase này — không tóm tắt hay diễn giải lại khi truyền tiếp.

──────────────────────────────────────────────────────


═══════════════════════════════════════════════════════
PHASE 4.5: MAIN AGENT SPOT-CHECK (không cần subagent — chạy khi Phase 4 tìm được vấn đề MỚI)
═══════════════════════════════════════════════════════

Mục đích: ADVERSARIAL.txt là 1 pass duy nhất của 1 subagent — không có gì xác minh lại trước khi nó vào REPORT.md. Bịt lỗ hổng này mà không cần spawn thêm subagent.

Với MỖI "NEW ISSUE" trong ADVERSARIAL.txt:
  1. Main agent (không phải subagent) đọc trực tiếp file:line được trích dẫn.
  2. Xác nhận code tại vị trí đó thực sự khớp với vấn đề được nêu — attack vector là thật và dòng code làm đúng như bị cáo buộc.
  3. Khớp → merge vào REPORT.md như bình thường.
  4. Không khớp (dòng không tồn tại, code không khớp claim, attack vector không áp dụng được) → bỏ finding đó, ghi chú vào CONFIDENCE NOTES của REPORT.md: "Adversarial finding '{title}' dropped — {lý do}".

Đây là spot-check read-only (không phân tích lại, không grep mới) — chi phí chỉ vài lệnh Read, không phải spawn agent mới.


═══════════════════════════════════════════════════════
PHASE 5: LINT HARVEST (1 subagent, sau Phase 4.5)
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

Đọc `references/lint-harvest-prompt.vi.md` và dùng nội dung đó **nguyên văn** làm prompt cho subagent ở phase này — không tóm tắt hay diễn giải lại khi truyền tiếp.

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
3. Nếu diff có < 5 file VÀ không dùng mode `--path` → bỏ qua Phase 2, main agent review trực tiếp qua multi-pass (4 pass như mô tả trong prompt subagent) và ghi thẳng vào REPORT.md. Ở incremental mode (1.0), số lượng này tính theo file `[NEW-SINCE-LAST-REVIEW]`, không phải tổng diff/carried-forward — file carried-forward không bao giờ quay lại Phase 2 bất kể ngưỡng này.
4. Nếu diff có > 20 file → tăng số group, tối đa 4 file mỗi group. Ở incremental mode (1.0), số lượng này tính theo file `[NEW-SINCE-LAST-REVIEW]`, không phải tổng diff/carried-forward.
5. KHÔNG lặp Phase 1 → 2 → 3 → 4. Chạy đúng một lần.
6. Nếu một subagent fail hoặc timeout:
   - Main agent đọc các file của group đó
   - Thực hiện đúng quy trình 3-pass như trong prompt subagent
   - Ghi kết quả vào .code-review/{GROUP_NAME}.txt với header: [REVIEWED BY: MAIN AGENT — subagent failed]
   - Ghi vào phần CONFIDENCE NOTES của REPORT.md: "Group X reviewed by main agent — lower confidence than subagent review"
7. Phase 5 (Lint Harvest) KHÔNG block merge — chạy sau Phase 4.5, việc nó fail không ảnh hưởng đến kết quả review chính.
8. Diff rỗng-sau-khi-filter hoặc toàn comment-only (1.3c) → early exit, không spawn subagent nào.
9. Incremental mode (1.0) chỉ áp dụng cho Mode 3 diff review; `--path`/`--since` luôn chạy full.
10. Phase 4.5 spot-check chạy inline trong main agent — không bao giờ spawn subagent cho nó.

═══════════════════════════════════════════════════════
BƯỚC TIẾP THEO
═══════════════════════════════════════════════════════

Nhìn vào những gì REPORT.md thực sự tìm thấy và tự đề xuất MỘT hành động tiếp theo hợp lý, 1-2 câu — không chọn theo danh sách cố định. Cân nhắc các skill khác trong bộ này (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) nếu thực sự phù hợp; nếu không cần gì thêm thì nói rõ luôn.
