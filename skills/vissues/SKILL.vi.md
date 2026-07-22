---
name: vissues
description: "Tạo/đồng bộ 1 GitHub epic issue + sub-issues từ 1 plan directory, dùng gh CLI + GraphQL addSubIssue. Nội dung issue phi kỹ thuật, migration được gộp vào sub-issue 1. Idempotent — chạy lại không tạo trùng."
argument-hint: "<plan-path>"
user-invocable: true
when_to_use: "Dùng khi cần tạo hoặc đồng bộ GitHub epic + sub-issues từ 1 plan có sẵn (plan.md + phase-XX-*.md)."
category: workflow
keywords: [github, issues, epic, sub-issues, graphql]
metadata:
  author: vyvu
  version: "1.0.0"
---

# vissues

Tạo hoặc đồng bộ 1 GitHub epic issue + sub-issues từ 1 plan directory, dùng `gh` CLI. Idempotent — chạy lần thứ hai sẽ update thay vì tạo trùng.

Đọc input từ user:

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` rỗng — hỏi user đường dẫn đến plan directory (ví dụ `plans/<slug>/`).

---

## Bước 1 — Đọc plan

- Đọc `<plan-path>/plan.md` + TẤT CẢ các file `<plan-path>/phase-XX-*.md` liên quan
- Hiểu toàn bộ scope: tên feature, các phase, và phase nào đụng đến database/migration

## Bước 2 — Tìm/tạo Epic issue

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
5. Lấy node ID của epic (cần trước khi link sub-issues ở Bước 3):
   ```
   gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id}}}' -f owner=<owner> -f repo=<repo> -F number=<epic_number>
   ```

## Bước 3 — Tạo/cập nhật sub-issues

1. Gom các phase của plan thành sub-issues theo mảng công việc — **KHÔNG** tạo mỗi phase nhỏ 1 sub-issue riêng; các phase liên quan (cùng layer, cùng feature slice) phải gộp vào 1 sub-issue. Tránh tạo quá nhiều issue.
2. Với MỖI sub-issue định tạo — search trước để tránh trùng khi skill chạy lại (chế độ update):
   ```
   gh issue list --search "<planned title>" --state all --json number,title,url
   ```
3. Nếu đã tồn tại → update nội dung theo phase tương ứng:
   ```
   gh issue edit <number> --body "<new content>"
   ```
   Nếu chưa tồn tại → tạo mới:
   ```
   gh issue create --title "<title, in English>" --body "<content, see Step 4>"
   ```
4. Lấy node ID của sub-issue (query GraphQL tương tự Bước 2, thay `<number>`)
5. Link nó với epic — **QUAN TRỌNG: chỉ gọi addSubIssue cho các sub-issue MỚI TẠO hoặc CHƯA được link**, bỏ qua bước này với các sub-issue đã link từ lần chạy trước:
   ```
   gh api graphql -f query='mutation($issueId:ID!,$subIssueId:ID!){addSubIssue(input:{issueId:$issueId,subIssueId:$subIssueId}){issue{title}subIssue{title}}}' -f issueId=<epic_node_id> -f subIssueId=<sub_issue_node_id>
   ```

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

Nếu plan có thay đổi database → đưa TOÀN BỘ nội dung liên quan đến migration vào **sub-issue đầu tiên** (tương ứng với phase 1 của plan). KHÔNG rải nội dung migration ra nhiều sub-issue.

---

## Hard rules

- Luôn search trước khi tạo (`gh issue list --search`) — tránh trùng epic/sub-issue khi chạy lại skill
- Luôn lấy node ID qua query GraphQL TRƯỚC khi gọi `addSubIssue` — mutation cần global ID (chuỗi base64), không phải số issue
- Ngôn ngữ issue luôn phải phi kỹ thuật — không thuật ngữ code, không tên file/hàm/table DB
- Migration luôn đưa vào sub-issue 1, không bao giờ rải ra nhiều sub-issue
- Không bao giờ tạo label mới (`epic` hay bất kỳ label nào khác) mà không xác nhận với user trước
- Gộp các phase nhỏ liên quan thành 1 sub-issue — không tạo mỗi phase 1 issue riêng

## Bước tiếp theo

Nhìn vào kết quả thực tế của lần chạy này và tự đề xuất MỘT hành động tiếp theo hợp lý, 1-2 câu — không chọn theo danh sách cố định. Cân nhắc các skill khác trong bộ này (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) nếu thực sự phù hợp; nếu không cần gì thêm thì nói rõ luôn.
