---
name: vci
description: "Chạy format, typecheck, build và lint (thêm test khi có --test) song song cho toàn bộ hoặc một phần package của repo JS/TS, tự sửa lỗi tìm được và chỉ chạy lại package vừa sửa. Tự nhận diện package manager và các package trong workspace. Dùng trước khi commit/PR, hoặc khi được hỏi liệu mọi thứ còn compile và build được không."
argument-hint: "[package-names...] [--test] [--changed]"
user-invocable: true
when_to_use: "Dùng khi user muốn typecheck, build, lint hoặc test toàn repo hay một nhóm package trước khi commit, ví dụ 'chạy typecheck và build', 'sau refactor này mọi thứ còn build được không'. Không dùng để giải thích code, review PR hay viết test."
allowed-tools: Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(tsc:*), Bash(turbo:*), Bash(nx:*), Bash(eslint:*), Bash(prettier:*), Bash(biome:*), Bash(git:*), Bash(timeout:*), Bash(gtimeout:*), Bash(command:*), Bash(mkdir:*), Bash(cat:*), Bash(echo:*), Bash(wait:*)
metadata:
  author: vyvu
  version: "2.0.0"
---

# vci

Kiểm tra repo JS/TS (monorepo hoặc single package) bằng format, typecheck, build và lint, thêm test khi được yêu cầu. Skill này có sửa file: formatter ghi đè file và các check lỗi sẽ được sửa. Phạm vi chỉ là các check, không thêm tính năng, test hay tài liệu không được yêu cầu.

```
$ARGUMENTS
```

## 1. Xác định profile và danh sách package

Đọc `~/.claude/skills/_vskills-shared/repo-profile.md` §1 để biết package manager (`pm`), workspace shape và tên script. File không có thì giả định pnpm + workspace. Nếu §1 báo đây không phải project JS/TS, dừng và nói rõ.

Danh sách package, khớp trường hợp đầu tiên:
- Có tên trong `$ARGUMENTS` (sau khi bỏ `--test` và `--changed`): dùng đúng các tên đó.
- `--changed`: map `git diff --name-only <default-branch>...HEAD` sang package chứa file, loại trùng. Package phụ thuộc vào chúng không được tính, nên ưu tiên chế độ affected của orchestrator khi áp dụng bước 2.
- Còn lại là toàn workspace: resolve glob trong `pnpm-workspace.yaml` hoặc `workspaces`, đọc `name` từng `package.json`, giữ package có script `build` hoặc `tsconfig.json`. Repo single package thì chỉ có root.

Nếu có `turbo.json` hoặc `nx.json`, dùng orchestrator cho các check ở bước 3 (`turbo run typecheck build lint --filter=<pkg>` hoặc `--affected`, `nx run-many --target=...`). Nó có cache hit và đúng thứ tự phụ thuộc, và bạn đọc output của nó thay vì log từng package.

## 2. Format trước

Format trước các check để chúng kiểm tra đúng code cuối cùng. Dùng cái đầu tiên áp dụng được: script `format`/`format:fix` ở root, `prettier --write .`, `biome check --write .`, `eslint --fix .`.

## 3. Chạy các check song song

Không có orchestrator thì chạy từng stage một (typecheck, rồi build, rồi lint, rồi test), mọi package của một stage chạy song song. Mỗi stage một lệnh Bash, đặt timeout của Bash tool là 600000 ms để một package treo không làm `wait` treo theo:

```bash
mkdir -p /tmp/vci
(<pm exec template> <cmd>; echo "exit=$?") > /tmp/vci/<stage>-<safe-name>.log 2>&1 &
# ...một dòng cho mỗi package...
wait
```

- `<safe-name>`: tên package với `/` và `@` đổi thành `_`, vì tên scoped để nguyên sẽ làm hỏng đường dẫn log.
- Chỉ thêm tiền tố `timeout 600` (hoặc `gtimeout 600`) khi `command -v` tìm thấy; macOS gốc không có cả hai, và timeout của Bash tool đã bao phần này.
- Lệnh theo stage: typecheck dùng `typecheck`, rồi `type-check`, rồi `tsc --noEmit`; build dùng script `build` của package và bỏ qua package không có; lint dùng `lint`, rồi `lint:check`, rồi `eslint .`; test (chỉ khi có `--test`) ưu tiên `test:run`/`test:ci` hơn `test` chạy watch.
- Package không có `tsconfig.json` thì không có typecheck, đó không phải lỗi.

Đọc những dòng cuối của từng log. Lỗi: sửa nguyên nhân, rồi chạy lại đúng package và stage đó. Test fail thì không bao giờ bị bỏ qua hay nới lỏng; sửa hoặc báo cáo.

## 4. Xác minh và báo cáo

Sau lần sửa cuối, chạy lại các stage liên quan tới file đã sửa cho những package đó, để trạng thái cuối được chứng minh chứ không giả định. In một bảng, mỗi package một dòng: typecheck, build, lint, test (pass, fail, hoặc skipped kèm lý do), thêm các file formatter đã đổi. Stage nào không chạy được (thiếu script, lỗi tooling) thì nói rõ thay vì báo pass.

Làm theo quy ước Next Steps trong `_vskills-shared/repo-profile.md` §7.
