---
name: vcheck
description: "Chạy typecheck + build (+ test tùy chọn) song song cho toàn bộ hoặc một phần package trong pnpm monorepo, dùng background command. Tự động phát hiện package trong workspace, không hardcode tên package."
argument-hint: "[package-names...]"
user-invocable: true
when_to_use: "Dùng khi cần typecheck/build (và test) nhanh cho toàn bộ monorepo hoặc một nhóm package trong pnpm monorepo trước khi commit/PR."
category: workflow
keywords: [typecheck, build, tsc, pnpm, monorepo, ci]
metadata:
  author: vyvu
  version: "1.0.0"
---

# vcheck

Chạy typecheck + build (+ test tùy chọn) song song cho các package trong pnpm monorepo, dùng background command + `wait`. Generic — không hardcode tên package.

Đọc input từ user:

```
$ARGUMENTS
```

---

## Bước 0 — Xác định danh sách package

- Nếu `$ARGUMENTS` chứa danh sách tên package → dùng đúng danh sách đó, bỏ qua auto-detect
- Nếu rỗng → auto-detect toàn bộ workspace:
  1. Đọc field `packages:` trong `pnpm-workspace.yaml` (hoặc field `workspaces` trong `package.json` gốc nếu file đó không tồn tại) để lấy glob pattern
  2. Resolve glob thành danh sách thư mục package thực tế
  3. Với mỗi thư mục, đọc `package.json` con để lấy field `name`
  4. Chỉ giữ lại package có script `build` trong `package.json` VÀ/HOẶC có `tsconfig.json` — package không có gì để check thì loại bỏ

## Bước 1 — Typecheck song song

Với MỖI package trong danh sách, spawn một background command:

```
pnpm --filter <package> exec tsc --noEmit > /tmp/tsc-<package>.log 2>&1 &
```

Spawn tất cả package trước, rồi mới `wait` — KHÔNG chạy tuần tự từng cái một.

Sau `wait`, đọc từng `/tmp/tsc-<package>.log`:
- Không có lỗi → báo pass
- Có lỗi → trích xuất file:line + message cụ thể, fix, rồi recheck **chỉ package vừa fix** (chạy lại đúng 1 lệnh tsc cho package đó, không chạy lại toàn bộ danh sách)

## Bước 2 — Build song song

Tương tự bước 1, spawn một background command cho mỗi package:

```
pnpm --filter <package> build > /tmp/build-<package>.log 2>&1 &
```

Spawn tất cả → `wait` → parse log từng package (pass/fail). Package fail → fix, recheck chỉ package đó.

## Bước 3 — Format

Đọc scripts trong `package.json` gốc, tìm format script (`format`, `format:fix`, ...) theo thứ tự ưu tiên đó, chạy script đầu tiên tìm thấy.

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
