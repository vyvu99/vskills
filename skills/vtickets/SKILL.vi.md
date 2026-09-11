---
name: vissues
description: "Tạo/đồng bộ 1 GitHub epic issue + sub-issues từ 1 plan directory, dùng gh CLI + REST sub_issues API (GraphQL addSubIssue làm fallback). Nội dung issue phi kỹ thuật, migration được gộp vào sub-issue chứa nội dung phase 1. Idempotent — chạy lại không tạo trùng."
argument-hint: "<plan-path>"
user-invocable: true
disable-model-invocation: true
when_to_use: "Dùng khi cần tạo hoặc đồng bộ GitHub epic + sub-issues từ 1 plan có sẵn (plan.md + phase-XX-*.md)."
metadata:
  author: vyvu
  version: "1.1.0"
---

# vissues

Tạo hoặc đồng bộ 1 GitHub epic issue + sub-issues từ 1 plan directory, dùng `gh` CLI. Idempotent — chạy lần thứ hai sẽ update thay vì tạo trùng.

Đọc input từ user:

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` rỗng — hỏi user đường dẫn đến plan directory (ví dụ `plans/<slug>/`).

---

## Bước 0 — Xác định VCS profile

Đọc `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (nếu có; nếu không có, giả định GitHub + gh — mặc định hiện tại). Full gh mode → tiếp tục như bình thường bên dưới. Degraded/local-only → in thông báo §2 dành cho vissues (link sub-issue — cả REST `sub_issues` lẫn GraphQL `addSubIssue` fallback — đều là API riêng của GitHub, không có tương đương ở host khác), rồi vẫn làm Bước 1 (đọc plan) và Bước 4 (soạn nội dung issue), in ra nội dung epic + sub-issue sẵn sàng để paste — đánh dấu sub-issue nào chứa migration theo Bước 5. KHÔNG BAO GIỜ abort chỉ vì thiếu `gh`.

## Bước 1 — Đọc plan

- Đọc `<plan-path>/plan.md` + TẤT CẢ các file `<plan-path>/phase-XX-*.md` liên quan
- Hiểu toàn bộ scope: tên feature, các phase, và phase nào đụng đến database/migration

## Bước 2 — Tìm/tạo Epic issue

Các lệnh này giả định đang ở full gh mode từ Bước 0; ở chế độ degraded, làm theo hướng dẫn thủ công ở Bước 0 thay thế.

1. Search issue hiện có khớp với plan này:
   ```
   gh issue list --search "<keyword from plan name>" --state all --json number,title,url,labels
   ```
2. Nếu tìm thấy issue title tương đồng cao → dùng nó làm epic, **KHÔNG tạo mới**
3. Nếu không tìm thấy → kiểm tra xem label `epic` đã tồn tại trong repo chưa:
   ```
   gh label list
   ```
   - Label `epic` đã tồn tại → tạo issue với `--label epic`
   - Chưa tồn tại → **STOP, hỏi user** có muốn tạo label mới không (không bao giờ tự tạo label mà không xác nhận)
4. Tạo epic mới:
   ```
   gh issue create --title "<feature name, in English>" --body "<epic description, see Step 4>" --label epic
   ```
5. Lấy node ID của epic — chỉ cần cho GraphQL fallback ở Bước 3, không cần cho REST path (`<owner>`/`<repo>` xác định theo §2):
   ```
   gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' -f owner=<owner> -f repo=<repo> -F number=<epic_number>
   ```

## Bước 3 — Tạo/cập nhật sub-issues

1. Gom các phase của plan thành sub-issues theo mảng công việc — **KHÔNG** tạo mỗi phase nhỏ 1 sub-issue riêng; các phase liên quan (cùng layer, cùng feature slice) phải gộp vào 1 sub-issue. Tránh tạo quá nhiều issue. Đặt title của mỗi sub-issue theo cách **deterministic**, suy ra trực tiếp từ số phase/mảng công việc mà nó bao phủ (ví dụ 1 template cố định như `<Tên mảng> (Phase N-M)`) — không phrase tự do có thể đổi khác giữa các lần chạy, để check dedupe ở bước 3 luôn khớp đúng title khi chạy lại.
2. Trước khi tạo/cập nhật hoặc link bất kỳ sub-issue nào, fetch danh sách sub-issues hiện tại của epic **một lần duy nhất cho mỗi lần chạy skill** (REST, `<owner>`/`<repo>` theo §2) — cache danh sách này (`id`, `number`, `title`) và tái dùng cho check dedupe khi tạo ở bước 3, check "đã link chưa" ở bước 5, LẪN check giới hạn số lượng, không fetch lại nhiều lần:
   ```
   gh api repos/<owner>/<repo>/issues/<epic_number>/sub_issues --paginate --jq '.[] | {id,number,title}'
   ```
   - Nếu call này fail hẳn → KHÔNG được giả định epic có 0 sub-issue. Cảnh báo user rõ ràng rằng không xác minh được số lượng/link hiện tại, và hỏi user có muốn tiếp tục link hay không.
   - Nếu thành công → check giới hạn: nếu danh sách đã có từ 100 entry trở lên (giới hạn per-parent chính thức của GitHub — xác minh lại live nếu skill này được sửa lại sau này, không tin số cũ), **STOP** và báo user epic đã đạt giới hạn sub-issue của GitHub; user phải đóng/tái tổ chức sub-issue hiện có trước khi thêm mới. Chỉ check một lần cho cả lần chạy, không check theo từng sub-issue.
3. Với MỖI sub-issue định tạo — dedupe với danh sách cache từ bước 2 trước, theo exact title match: nếu 1 entry trong cache có title khớp đúng với title đang định tạo, nghĩa là nó đã tồn tại rồi, dùng luôn `number` của entry đó. Chỉ khi epic không có sub-issue nào khớp trong danh sách cache đó, mới fallback sang search title trên toàn repo (dựa trên title, có thể miss do GitHub normalize title hoặc do ký tự đặc biệt):
   ```
   gh issue list --search "<planned title>" --state all --json number,title,url
   ```
4. Nếu đã tồn tại (từ 1 trong 2 cách tìm ở bước 3) → update nội dung theo phase tương ứng:
   ```
   gh issue edit <number> --body "<new content>"
   ```
   Nếu chưa tồn tại → tạo mới:
   ```
   gh issue create --title "<title, in English>" --body "<content, see Step 4>"
   ```
5. Với mỗi sub-issue cần link (đã tìm thấy hoặc vừa tạo ở bước 4):
   a. Fetch `id` dạng số của nó — **KHÔNG PHẢI** `number`, **KHÔNG PHẢI** node ID:
      ```
      gh api repos/<owner>/<repo>/issues/<sub_issue_number> --jq .id
      ```
   b. Nếu id dạng số này đã có trong danh sách cache từ bước 2 → đã link với epic này từ lần chạy trước, **bỏ qua âm thầm** — đây là kết quả bình thường, thường gặp ở mỗi lần chạy lại, không phải lỗi.
   c. Nếu chưa → thử link qua REST (cách này cũng xử lý luôn trường hợp sub-issue đang thuộc parent khác, nhờ `replace_parent`):
      ```
      gh api repos/<owner>/<repo>/issues/<epic_number>/sub_issues -F sub_issue_id=<numeric_id> -F replace_parent=true
      ```
      - **201** → đã link xong, hoàn tất cho sub-issue này.
      - **401/403** (lỗi permission/auth) → **STOP** và báo lỗi chính xác cho user trực tiếp — KHÔNG fallback sang GraphQL; vấn đề token/permission này rất có thể cũng làm hỏng GraphQL mutation, nên fallback âm thầm sẽ che giấu lỗi cấu hình scope token thay vì báo ra.
      - **Bất kỳ lỗi nào khác** (404, 410, 422, lỗi mạng, v.v.) → fallback sang GraphQL: lấy cả 2 node ID, rồi gọi `addSubIssue` với `replaceParent: true`:
        ```
        gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' -f owner=<owner> -f repo=<repo> -F number=<sub_issue_number>
        ```
        ```
        gh api graphql -f query='mutation($issueId:ID!,$subIssueId:ID!,$replaceParent:Boolean){addSubIssue(input:{issueId:$issueId,subIssueId:$subIssueId,replaceParent:$replaceParent}){issue{title}subIssue{title}}}' -f issueId=<epic_node_id> -f subIssueId=<sub_issue_node_id> -F replaceParent=true
        ```
6. Tùy chọn — milestone/labels: hỏi user một lần (qua `AskUserQuestion`) xem có muốn gán milestone theo phase và/hoặc label theo mảng công việc cho các sub-issue đụng tới trong lần chạy này không. Nếu có:
   ```
   gh issue edit <number> --milestone "<milestone>" --add-label "<label>"
   ```
   Nếu user từ chối, bỏ qua âm thầm — không hỏi lại theo từng sub-issue.

## Bước 4 — Nội dung issue (cả epic lẫn sub-issue đều theo format này)

Ngôn ngữ đơn giản, phi kỹ thuật — không tên file, không tên hàm, không tên table DB, không tên biến. Tập trung vào vấn đề mà end user gặp phải + kết quả mong muốn.

```md
## Current problem
<description of the problem/gap the user is experiencing>

## Desired outcome
<after this is done, what can the user do / what experience do they get>

## Scope
<brief — what's in, what's out>
```

## Bước 5 — Ràng buộc về migration

Nếu plan có thay đổi database → đưa TOÀN BỘ nội dung liên quan đến migration vào **sub-issue chứa nội dung phase 1** (không nhất thiết là sub-issue tạo đầu tiên — Bước 3.1 gom nhóm theo mảng công việc, không theo thứ tự phase). KHÔNG rải nội dung migration ra nhiều sub-issue.

## Bước 6 — Bảng link cuối cùng

Cuối lần chạy, in ra 1 bảng liệt kê mọi issue đã đụng tới trong lần chạy này (epic + tất cả sub-issue, dù tạo mới hay update):

```
| # | title | url | parent |
|---|---|---|---|
```

Đồng thời lưu bảng này vào `<plan-path>/issues.md`, để lần chạy sau của skill trên cùng plan có thể đọc trực tiếp thay vì phải search lại trên GitHub.

---

## Hard rules

- Luôn check danh sách sub-issues cache của epic trước để dedupe khi tạo sub-issue (bước 3), chỉ fallback sang `gh issue list --search` khi epic không có title nào khớp; riêng epic thì luôn search trước khi tạo — tránh trùng epic/sub-issue khi chạy lại skill
- REST `sub_issues` là path link chính; fetch danh sách sub-issues của epic một lần cho mỗi lần chạy (cache lại) và bỏ qua việc link nếu `id` dạng số của sub-issue đã có trong danh sách đó — đây là no-op idempotent, không bao giờ coi là lỗi REST cần fallback
- Field `sub_issues_summary`/`subIssuesSummary` của GitHub (hiển thị dạng badge tiến độ trên Project board và issue list) có thể bị stale — đây là bug đã biết của GitHub, không phải dấu hiệu link bị lỗi; danh sách `sub_issues` live (REST hoặc GraphQL tương đương) của issue đó luôn là nguồn authoritative, không bao giờ là cái badge
- Chỉ fallback sang GraphQL `addSubIssue` mutation (với `replaceParent: true`) khi REST fail thật sự và KHÔNG phải lỗi permission; khi REST trả 401/403, STOP và báo lỗi trực tiếp cho user — không bao giờ âm thầm fallback
- Không bao giờ link sub-issue khi số lượng sub-issue cache của epic đã ≥ 100 (giới hạn per-parent của GitHub) — STOP và báo user đóng/tái tổ chức sub-issue hiện có trước; nếu bản thân việc fetch số lượng fail, cảnh báo user và hỏi trước khi tiếp tục, không giả định là 0
- Ngôn ngữ issue luôn phải phi kỹ thuật — không thuật ngữ code, không tên file/hàm/table DB
- Migration luôn đưa vào sub-issue chứa nội dung phase 1, không bao giờ rải ra nhiều sub-issue
- Không bao giờ tạo label mới (`epic` hay bất kỳ label nào khác) mà không xác nhận với user trước
- Gộp các phase nhỏ liên quan thành 1 sub-issue — không tạo mỗi phase 1 issue riêng
- KHÔNG BAO GIỜ abort chỉ vì thiếu `gh` hoặc remote không phải GitHub — degrade theo §2 và vẫn phải giao đủ nội dung issue

## Bước tiếp theo

Nhìn vào kết quả thực tế của lần chạy này và tự đề xuất MỘT hành động tiếp theo hợp lý, 1-2 câu — không chọn theo danh sách cố định. Cân nhắc các skill khác trong bộ này (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) nếu thực sự phù hợp; nếu không cần gì thêm thì nói rõ luôn.
