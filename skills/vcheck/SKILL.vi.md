---
name: vcheck
description: "Chạy typecheck + build (+ test tùy chọn) song song cho toàn bộ hoặc một phần package trong repo JS/TS (monorepo hoặc single package). Tự động phát hiện package trong workspace và package manager, không hardcode tên package."
argument-hint: "[package-names...]"
user-invocable: true
when_to_use: "Dùng khi cần typecheck/build (và test) nhanh cho toàn bộ repo hoặc một nhóm package trong monorepo JS/TS (hoặc single package) trước khi commit/PR."
category: workflow
keywords: [typecheck, build, tsc, pnpm, npm, yarn, bun, monorepo, ci]
metadata:
  author: vyvu
  version: "1.0.0"
---

# vcheck

Chạy typecheck + build (+ test tùy chọn) song song cho các package trong repo JS/TS (monorepo hoặc single package), dùng background command + `wait`. Generic — không hardcode tên package hay package manager.

Đọc input từ user:

```
$ARGUMENTS
```

---

## Bước -1 — Xác định repo profile

Đọc `~/.claude/skills/_vskills-shared/repo-profile.md` §1 (nếu có) để xác định package manager (`pm`), workspace shape, và tên script typecheck/build/format. Nếu file không tồn tại, giả định pnpm + workspace (`pnpm --filter <pkg> exec …`) — mặc định hiện tại. Nếu §1 báo "not a JS/TS project", dừng ở đây và nói rõ — vcheck không có gì để làm trong repo không phải JS/TS.

## Bước 0 — Xác định danh sách package

- Nếu `$ARGUMENTS` chứa danh sách tên package → dùng đúng danh sách đó, bỏ qua auto-detect
- Nếu rỗng → auto-detect toàn bộ workspace:
  1. Dùng workspace shape từ Bước -1. **Single-package** → danh sách package chỉ là root package; bỏ qua resolve glob, đi thẳng sang Bước 1. **Monorepo** → tiếp tục với glob pattern từ `pnpm-workspace.yaml` (hoặc field `workspaces` trong `package.json` gốc):
  2. Resolve glob thành danh sách thư mục package thực tế
  3. Với mỗi thư mục, đọc `package.json` con để lấy field `name`
  4. Chỉ giữ lại package có script `build` trong `package.json` VÀ/HOẶC có `tsconfig.json` — package không có gì để check thì loại bỏ

## Bước 1 — Typecheck song song

Với MỖI package trong danh sách, spawn một background command:

```
<pm workspace/root exec template từ Bước -1> <typecheck cmd> > /tmp/tsc-<package>.log 2>&1 &
```

`<typecheck cmd>` = script đã resolve ở Bước -1 (`typecheck` → `type-check` → `tsc --noEmit`). Ví dụ minh hoạ:
- pnpm + workspace, không có script `typecheck` → `pnpm --filter <package> exec tsc --noEmit > /tmp/tsc-<package>.log 2>&1 &` (mặc định hiện tại, y hệt)
- npm + single-package → `npm exec -- tsc --noEmit > /tmp/tsc-<package>.log 2>&1 &`

Spawn tất cả package trước, rồi mới `wait` — KHÔNG chạy tuần tự từng cái một.

Sau `wait`, đọc từng `/tmp/tsc-<package>.log`:
- Không có lỗi → báo pass
- Có lỗi → trích xuất file:line + message cụ thể, fix, rồi recheck **chỉ package vừa fix** (chạy lại đúng 1 lệnh tsc cho package đó, không chạy lại toàn bộ danh sách)

## Bước 2 — Build song song

Tương tự bước 1, spawn một background command cho mỗi package:

```
<pm workspace/root exec template từ Bước -1> <build script> > /tmp/build-<package>.log 2>&1 &
```

`<build script>` = script `build` khai báo của package đó (Bước -1 — không có fallback raw; package không có script `build` thì bị skip, không chạy bằng lệnh thay thế). Ví dụ minh hoạ: pnpm + workspace → `pnpm --filter <package> build > /tmp/build-<package>.log 2>&1 &` (mặc định hiện tại, y hệt).

Spawn tất cả → `wait` → parse log từng package (pass/fail). Package fail → fix, recheck chỉ package đó.

## Bước 3 — Format

Đọc scripts trong `package.json` gốc, tìm format script (`format`, `format:fix`, ...) theo thứ tự ưu tiên đó, chạy script đầu tiên tìm thấy qua root template từ Bước -1 (`pnpm exec <script>` / `npm exec -- <script>` / `yarn <script>` / `bun <script>`).

## Bước 4 — Test (chỉ khi user yêu cầu hoặc chỉ định qua argument)

- Xác định test script trong `package.json` của từng package cần test — ưu tiên non-watch mode (`test:run`, `test:ci`, `test -- --run`, ...) hơn plain `test` nếu nghi ngờ mặc định là watch mode
- Chạy background + `wait`, giống bước 1-2
- Fail → fix, recheck chỉ package đó, lặp lại đến khi pass — **KHÔNG BAO GIỜ** bỏ qua test failure vì bất kỳ lý do gì

---

## Quy tắc bắt buộc

- LUÔN spawn mọi package bằng background `&` rồi mới `wait` — KHÔNG BAO GIỜ chạy package tuần tự từng cái một
- KHÔNG BAO GIỜ hardcode bất kỳ tên package cụ thể nào trong logic — mọi danh sách phải đến từ argument hoặc workspace auto-detect
- Package fail → recheck chỉ package đó sau khi fix, không chạy lại toàn bộ danh sách
- KHÔNG BAO GIỜ bỏ qua test failure để đi tiếp bước khác — PHẢI fix và recheck đến khi pass

## Bước tiếp theo

Nhìn vào kết quả thực tế của lần chạy này và tự đề xuất MỘT hành động tiếp theo hợp lý, 1-2 câu — không chọn theo danh sách cố định. Cân nhắc các skill khác trong bộ này (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) nếu thực sự phù hợp; nếu không cần gì thêm thì nói rõ luôn.
