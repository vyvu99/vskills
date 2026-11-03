---
name: vtickets
description: "Tạo hoặc đồng bộ một epic issue GitHub cùng các sub-issue được link từ một thư mục plan (plan.md + phase-XX-*.md), dùng gh CLI và REST sub_issues API. Nội dung issue phi kỹ thuật, migration gom vào một sub-issue, chạy lại thì cập nhật chứ không tạo trùng. Chạy tường minh bằng /vtickets <plan-path>."
argument-hint: "<plan-path>"
user-invocable: true
disable-model-invocation: true
when_to_use: "Dùng khi user muốn biến một plan có sẵn thành epic GitHub kèm sub-issue, hoặc đồng bộ lại epic đã tạo sau khi plan thay đổi."
metadata:
  author: vyvu
  version: "2.0.0"
---

# vtickets

Biến một thư mục plan thành epic GitHub kèm các sub-issue được link. Skill này tạo và sửa issue thật nên chỉ chạy khi user gọi. Phạm vi là các issue và `<plan-path>/issues.md`, không đổi code.

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` rỗng, hỏi thư mục plan (ví dụ `plans/<slug>/`).

## Bước 0 — VCS profile

Đọc `~/.claude/skills/_vskills-shared/repo-profile.md` §2; file không có thì giả định GitHub + gh. Ở full gh mode, làm tiếp bên dưới. Ở chế độ degraded hoặc local-only, in thông điệp vtickets của §2 (link sub-issue là API riêng của GitHub), chỉ làm Bước 1 và 4, rồi in body epic và sub-issue sẵn để dán, đánh dấu sub-issue chứa migration theo Bước 5. Thiếu `gh` không bao giờ làm dừng cả lượt chạy.

## Bước 1 — Đọc plan

Đọc `<plan-path>/plan.md` và mọi `phase-XX-*.md`. Ghi nhận tên feature, các phase, và phase nào đụng database hay migration.

## Bước 2 — Tìm hoặc tạo epic

Dùng kết quả đầu tiên của chuỗi sau, check rẻ nhất trước:

1. `<plan-path>/issues.md` tồn tại: lấy số epic từ đó (chỉ đúng trên cùng máy).
2. Tìm theo marker, sống sót qua clone mới. Mọi epic tạo ở đây có `<!-- vplan: <plan-slug> -->` ở dòng đầu body, với `<plan-slug>` là basename kebab-case của thư mục plan. Marker giữ tên `vplan` cũ vì đổi tên sẽ làm mồ côi các epic đã có. Search của GitHub là fuzzy nên chỉ coi kết quả là ứng viên, và xác nhận đúng chuỗi trong `body` của từng cái:
   ```bash
   gh issue list --search "\"vplan: <plan-slug>\" in:body" --state all --json number,title,url,body
   ```
3. Tìm theo title, cho epic có trước marker hoặc bị sửa mất marker. Title khớp rõ ràng thì đó là epic:
   ```bash
   gh issue list --search "<keyword from plan name>" --state all --json number,title,url,labels
   ```
4. Không thấy gì: kiểm tra `gh label list`. Có `epic` thì tạo với `--label epic`. Chưa có thì hỏi user trước khi tạo label, vì label là trạng thái dùng chung của repo.
5. Tạo epic. Body issue là text nhiều dòng có dấu nháy và backtick, nên ghi body (dòng marker trước, rồi nội dung Bước 4) vào file tạm và truyền bằng `--body-file`:
   ```bash
   gh issue create --title "<feature name, English>" --body-file <temp-file> --label epic
   ```

## Bước 3 — Tạo, cập nhật và link sub-issue

1. Gom phase thành sub-issue theo vùng việc (cùng layer hoặc cùng lát cắt feature). Mỗi phase nhỏ một sub-issue chỉ tạo nhiễu. Đặt title từ một template cố định như `<Area name> (Phase N-M)`, để bước dedupe ở mục 3 khớp đúng title ở mỗi lần chạy lại.
2. Mỗi lượt chạy, lấy danh sách sub-issue hiện tại của epic đúng một lần và dùng lại cho dedupe, check đã link và check giới hạn:
   ```bash
   gh api repos/<owner>/<repo>/issues/<epic_number>/sub_issues --paginate --jq '.[] | {id,number,title}'
   ```
   Nếu lệnh fail, đừng giả định 0 sub-issue; báo user là không xác minh được các link và hỏi trước khi link bất cứ gì. Nếu danh sách đã có 100 mục (giới hạn mỗi parent của GitHub tại thời điểm viết), dừng và bảo user đóng hoặc sắp xếp lại sub-issue trước.
3. Dedupe từng sub-issue dự kiến bằng khớp title chính xác với danh sách đã cache và dùng lại cái khớp. Chỉ khi epic không có cái nào khớp mới search title trong repo (có thể sót title mà GitHub chuẩn hóa):
   ```bash
   gh issue list --search "<planned title>" --state all --json number,title,url
   ```
4. Đã có: đọc nội dung hiện tại trước; nếu khác nội dung dự kiến của lượt này thì hỏi một lần (`AskUserQuestion`) trước khi ghi đè, vì người dùng hay sửa tay nội dung issue, rồi cập nhật bằng `gh issue edit <number> --body-file <temp-file>`. Mới: `gh issue create --title "<title, English>" --body-file <temp-file>`.
5. Link từng sub-issue (có sẵn hoặc mới tạo):
   - Lấy `id` dạng số (không phải number, không phải node ID): `gh api repos/<owner>/<repo>/issues/<sub_issue_number> --jq .id`.
   - Id đã nằm trong danh sách cache: đã link, bỏ qua im lặng. Đây là kết quả bình thường khi chạy lại.
   - Nếu không, link bằng REST; `replace_parent` cũng chuyển sub-issue từ parent khác sang:
     ```bash
     gh api repos/<owner>/<repo>/issues/<epic_number>/sub_issues -F sub_issue_id=<numeric_id> -F replace_parent=true
     ```
   - 201: đã link. 401/403: dừng và báo đúng lỗi, vì GraphQL sẽ fail y hệt và fallback sẽ che mất lỗi token. Lỗi khác: làm theo `references/graphql-fallback.md`.
6. Hỏi một lần (`AskUserQuestion`) có đặt milestone theo phase và label theo vùng việc không. Có: `gh issue edit <number> --milestone "<milestone>" --add-label "<label>"`. Không: đừng hỏi lại.

## Bước 4 — Nội dung issue

Epic và sub-issue dùng ngôn ngữ thường, không có tên file, hàm, bảng hay biến, vì người đọc là người làm sản phẩm. Ngôn ngữ body theo `repo-profile.md` §4; title luôn là tiếng Anh. Body sub-issue không có marker.

```md
## Current problem
<vấn đề hoặc khoảng trống user gặp>

## Desired outcome
<sau khi xong, user làm được gì>

## Scope
<cái gì trong phạm vi, cái gì ngoài>
```

## Bước 5 — Migration

Nếu plan đổi database, đặt toàn bộ nội dung migration vào đúng một sub-issue chứa nội dung phase 1 (không nhất thiết là cái tạo đầu tiên, vì Bước 3 gom theo vùng việc). Rải ra nhiều sub-issue sẽ làm mất ràng buộc về thứ tự.

## Bước 6 — Xác minh và báo cáo

Lấy lại danh sách sub-issue của epic (lệnh ở Bước 3) và so với các sub-issue dự kiến trong lượt này; danh sách live mới là nguồn đúng, còn badge tiến độ `sub_issues_summary` có thể trễ. Báo mọi link bị thiếu. Sau đó in và lưu vào `<plan-path>/issues.md` bảng mọi issue đã động tới:

```
| # | title | url | parent |
|---|---|---|---|
```

Lượt chạy bị gián đoạn phục hồi bằng cách chạy lại `/vtickets <plan-path>`, vì việc tìm và link tự dựng lại trạng thái từ GitHub và `issues.md`.

Làm theo quy ước Next Steps trong `_vskills-shared/repo-profile.md` §7.
