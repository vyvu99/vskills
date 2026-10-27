# Phase 1 — Thu thập context

Main agent tự làm toàn bộ phần này và chưa review gì. Luồng: 1.0 kiểm tra incremental, 1.1 file list, rồi bắt đầu Phase 0 lint scan, sau đó 1.2-1.5 trong lúc nó chạy.

## Mục lục
1. [1.0 Kiểm tra incremental](#10-incremental-check)
2. [1.1 Xác định các thay đổi](#11-determine-the-changes) — repo profile, flags, resolve PR, file list
3. [1.2 Đọc rules](#12-read-the-rules)
4. [1.3 Dependency graph](#13-dependency-graph) — import pattern, coverage tag, regression mapping, boilerplate, thoát sớm
5. [1.4 Gom group file](#14-group-the-files)
6. [1.5 Format CONTEXT.txt](#15-contexttxt-format)

## 1.0 Incremental check

Chỉ áp dụng cho mode branch/commit diff. `--path` và `--since` luôn review đầy đủ, vì không có một commit trước duy nhất để diff.

Nếu `.code-review/REPORT.md` tồn tại, đọc header tìm `REVIEWED_COMMIT:`.
- Không thấy (report cũ, hoặc không có file): review đầy đủ, bỏ qua phần còn lại của 1.0.
- Thấy, `{prev_sha}` resolve được (`git cat-file -e {prev_sha} 2>/dev/null`) và khác HEAD: incremental mode.
  - Copy report trước khi lần chạy này ghi đè: `cp .code-review/REPORT.md .code-review/REPORT.prev.md`
  - `git diff --name-status {prev_sha}...HEAD` cho ra các file đổi kể từ lần review trước.
  - Tag từng file ở 1.1: đổi kể từ `{prev_sha}` là `[NEW-SINCE-LAST-REVIEW]`; không đổi từ đó nhưng vẫn nằm trong diff base...HEAD hiện tại là `[CARRIED-FORWARD]`.
  - Chỉ file `[NEW-SINCE-LAST-REVIEW]` (cùng dependencies của chúng) được gom group cho Phase 2. Phase 3 copy finding của file carried-forward từ `REPORT.prev.md` thay vì review lại.
- Thấy và `{prev_sha}` bằng HEAD: không có gì mới. Bỏ qua Phase 0, 2, 4; copy `REPORT.md` sang không đổi, thêm ghi chú `No changes since last review ({prev_sha[:8]})` ở đầu, rồi dừng.

## 1.1 Determine the changes

Repo profile: đọc `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (host và việc có `gh`) và §3 (tally ngôn ngữ/framework, dùng từ Phase 2). Nếu file không có, giả định GitHub + `gh` + TypeScript. Rule CLAUDE.md nêu tên một ngôn ngữ hoặc framework chỉ áp dụng cho file thuộc ngôn ngữ đó trong diff, nên file `.py` không bao giờ bị flag theo rule TypeScript. Check bảo mật (secrets, injection, authz) áp dụng cho mọi file. Khi không có rule nào khớp ngôn ngữ của file, review theo nguyên tắc chung (đặt tên, xử lý lỗi, bảo mật, dead code) thay vì bỏ qua.

### Flags
- `--path dir1 dir2 ...`: review mọi file trong các directory đó, không dùng git diff. Dành cho cả một domain hoặc feature area.
- `--since <duration>`: dùng `git log --since="<duration>"` thay cho diff (`2h`, `1d`, `"3 hours ago"`).
- `--base <branch>`: override base branch. Không áp dụng với `--path`.
- `--exclude p1 p2 ...`: các path pattern cần loại.

### Positional args
Mọi argument không phải flag là tên branch, PR URL (`https://github.com/org/repo/pull/123`) hoặc PR shorthand (`#947`, `PR#947`). Không có positional arg nghĩa là review HEAD. `branch_list` là thứ được review (sau khi resolve PR); `base_branch` là thứ nó được so sánh với.

### Resolve PR refs
- Khớp `https?://github\.com/[^/]+/[^/]+/pull/(\d+)` hoặc `^#?PR?(\d+)$` (không phân biệt hoa thường): lấy số PR. Còn lại là tên branch, dùng trực tiếp.
- Full gh mode (repo-profile §2):
  ```bash
  gh pr view {pr_number} --json headRefName,state,mergeCommit,baseRefName \
    --jq '{branch: .headRefName, state: .state, sha: .mergeCommit.oid, base: .baseRefName}'
  ```
- Degraded mode (không có `gh`): in thông báo vreview ở §2 (`⚠️ can't resolve PR refs without gh — pass a branch name instead; branch/diff modes work without gh`), bỏ argument, đi tiếp. Nếu `branch_list` rỗng thì review HEAD.
- Theo state (chỉ full gh mode):
  - OPEN: dùng `headRefName`; `git fetch origin {headRefName} 2>/dev/null` nếu chưa có local; resolve bằng `git rev-parse --verify origin/{headRefName}` (ưu tiên remote).
  - MERGED: nếu `origin/{headRefName}` còn tồn tại thì xử lý như OPEN. Nếu đã bị xóa, dùng `mergeCommit.sha` với `git diff --name-status {base_branch}...{sha}` và ghi `[PR #{n} — branch deleted, using merge commit {sha[:8]}]` vào CONTEXT.txt.
  - CLOSED (chưa merge): cảnh báo `⚠️ PR #{n} is CLOSED (not merged) — skipping` và không thêm vào.

### Base branch
Khi không có `--base` (và không phải `--path`): nếu mọi arg là PR ref và có gh thì lấy `baseRefName` từ `gh pr view`; ngược lại theo `_vskills-shared/repo-profile.md` §9.

### File list
- Mode 1, `--path`: extension lấy từ tally repo-profile §3 (TypeScript: `*.ts *.tsx`; Python: `*.py`; Go: `*.go`; Rust: `*.rs`; Java/Kotlin: `*.java *.kt`); resolve tally trước nếu cần. Với mỗi path chạy `find {path} -type f \( -name "*.{ext1}" -o -name "*.{ext2}" \)`, hợp các kết quả, áp `--exclude`, đánh dấu mọi file `[EXISTING]`. Header CONTEXT.txt: `PATH REVIEW: {paths}  (not using git diff)`.
- Mode 2, `--since`: `git log --since="{duration}" --name-status --diff-filter=AMDR --pretty=format: | sort -u`
- Mode 3, branch/commit diff (mặc định): với mỗi entry trong `branch_list`, `git diff --name-status {base_branch}...{entry}`; hợp các list (loại trùng, giữ status mới nhất). Không có arg: `git diff --name-status {base_branch}...HEAD`. Khi hợp nhiều branch, ghi nguồn: `[M] path/file.ts (+45 -12) [branches: feat/auth, feat/billing]`.
- Áp pattern `--exclude` theo substring của path. Ghi lại path, status (A/M/D/R) và số dòng đổi của từng file.

## 1.2 Read the rules

Dùng các CLAUDE.md đã có trong context (cấp user và cấp project). Chỉ đọc file khi chúng chưa có trong context. Trích mọi rule thành danh sách đánh số và append khối RULES vào `.code-review/CONTEXT.txt` ngay (tạo file với header block trước nếu lần chạy này chưa ghi).

## 1.3 Dependency graph

Import-search pattern theo ngôn ngữ (từ tally §3); thay `{module}` bằng basename không có extension của file đổi:
- TypeScript/JavaScript: `from ['"].*{module}['"]` hoặc `require\(.*{module}\)`
- Python: `from .*{module} import` hoặc `^import {module}`
- Go: `"{import_path}"` trong khối `import (...)`
- Rust: `use .*{module}`
- Java/Kotlin: `import .*\.{ClassName}`
- Khác: bỏ import grep, chỉ dùng grep exported-symbol

Với mỗi file đổi, xác định: upstream (file nó import, gồm type import), downstream (file import nó; grep bằng pattern trên và grep tên exported symbol), test file của nó, và type definition nó định nghĩa hoặc dùng. Đọc phần import của từng file đổi để tìm upstream.

Wiring dựa trên grep bỏ sót một số edge. Tag chúng cạnh dependency entry của file để reviewer Phase 2 mở rộng việc đọc thủ công (barrel index, DI module, route registration) thay vì tin edge list:
- directory có `index.ts`/`index.js`/`index.py` (barrel re-export): `[heuristic-incomplete: barrel-reexport]`
- marker DI/framework (`@Injectable`, `@Controller`, `@Component`, `@Service`, `@Autowired`, route dạng decorator): `[heuristic-incomplete: DI-wiring]`
- file-based routing của Next.js/Nuxt/SvelteKit/Remix: `[heuristic-incomplete: file-based-routing]`

### Regression risk mapping
Chỉ xác định test file của từng file đổi; Phase 2 Pass 0 sẽ đọc nó. Tìm theo convention của ngôn ngữ file (`{name}.test.ts`, `{name}.spec.ts`, `__tests__/{name}.ts`, `test_{name}.py`, `{name}_test.go`). Ghi mapping vào mục REGRESSION RISKS của CONTEXT.txt: `path/file.ts → path/file.test.ts` hoặc `→ (no test file found)`.

### Filter boilerplate
Tự động loại, và liệt kê dưới BOILERPLATE SKIPPED cho minh bạch:
- code generated: `**/*.generated.{ts,tsx,js}`, `**/__generated__/**`, `**/generated/**`
- `openapi.json`, `openapi.yaml`, `openapi.yml`
- lockfile: `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `bun.lock`, `bun.lockb`, `Cargo.lock`, `go.sum`, `poetry.lock`, `Gemfile.lock`, `composer.lock`
- output minified/bundled: `**/*.min.js`, `**/*.bundle.js`

`**/migrations/**` và `**/*.sql` cũng rời khỏi review nhưng vào danh sách MIGRATIONS SKIPPED riêng, report nêu chúng là chưa được review ngữ nghĩa thay vì lặng lẽ bỏ.

### Thoát sớm
- List rỗng sau khi lọc (toàn boilerplate, hoặc diff rỗng): bỏ qua Phase 2-4, bỏ output Phase 0 nếu có, ghi `.code-review/REPORT.md` chỉ với header block, `TOTAL ISSUES: 0` và ghi chú "No reviewable files (all changes were boilerplate/docs)". Không spawn gì.
- File chỉ đổi comment/whitespace: check từng file còn lại bằng
  `git diff -U0 {base_branch}...{entry} -- {file} | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)' | grep -vE '^[+-]\s*(//|#|\*|/\*|"""|--)'`
  Kết quả rỗng nghĩa là chỉ comment/whitespace. Tag `[COMMENT-ONLY]`, loại khỏi gom group, khỏi ngưỡng 5 file và khỏi cap dòng mỗi group, và liệt kê dưới FILES NOT REVIEWED. Best effort: bỏ check với ngôn ngữ không khớp pattern trên.

## 1.4 Group the files

- File liên quan về logic chung một group.
- Cap mỗi group khoảng 400 dòng đổi (tổng số từ 1.1), không tính theo số file, để năm file nhỏ và một file lớn được định cỡ công bằng. Ở incremental mode chỉ file `[NEW-SINCE-LAST-REVIEW]` được tính. 400 dòng xấp xỉ lượng một subagent đọc hết cùng dependencies mà vẫn review cẩn thận.
- File chỉ đổi config, type hoặc constant lập thành group riêng.

Ngay khi files và dependencies của một group đã chốt, append khối của nó (1.5) vào `CONTEXT.txt`; không dồn đến cuối.

## 1.5 Format CONTEXT.txt

Các khối được ghi dần: header khi 1.1 xong, RULES ở 1.2, mỗi GROUP khi 1.4 chốt.

```
CONTEXT
BRANCHES REVIEWED: {branch1}, {branch2}, ...  →  BASE: {base_branch}
  [or: PR #{n} (OPEN|MERGED via {sha[:8]}), PR #{m} ...  →  BASE: {base_branch}]
  [or: SINCE: {duration}  |  or: HEAD → {base_branch}]
TOTAL CHANGED FILES: {count} (user-excluded: {excluded_patterns_or_none})
PROFILE: lang={tally, e.g. TypeScript(12) Python(2)} · framework={framework} · host={host_mode} · pm={pm}
INCREMENTAL: {no  |  yes, since {prev_sha[:8]} — {N} new, {M} carried forward}

BOILERPLATE SKIPPED (auto):
  {files, or "none"}

MIGRATIONS SKIPPED (auto, not semantically reviewed):
  {files, or "none"}

RULES (from CLAUDE.md):
  1. {rule_1}
  2. {rule_2}
  ... (all rules)

REGRESSION RISKS:
  path/file.ts → path/file.test.ts

GROUP A: {descriptive logical group name}
CHANGED FILES:
  [M] path/file.ts  (+45 -12)
  [A] path/file2.ts (+120 -0)
DEPENDENCIES TO READ:
  upstream   → dep.ts        (imports: useHook, TypeY)
  downstream → consumer.ts   (imports: Component)
  types      → types.ts      (imports: Interface)
  test       → file.test.ts

GROUP B: ...
```
