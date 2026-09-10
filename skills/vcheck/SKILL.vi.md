---
name: vcheck
description: "Chạy typecheck + build + format (+ test tùy chọn) song song cho toàn bộ hoặc một phần package trong repo JS/TS (monorepo hoặc single package). Tự động phát hiện package trong workspace và package manager, không hardcode tên package."
argument-hint: "[package-names...] [--test] [--changed]"
user-invocable: true
when_to_use: "Dùng khi cần typecheck/build (và test) nhanh cho toàn bộ repo hoặc một nhóm package trong monorepo JS/TS (hoặc single package) trước khi commit/PR."
allowed-tools: Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(bun:*), Bash(tsc:*), Bash(turbo:*), Bash(nx:*), Bash(eslint:*), Bash(prettier:*), Bash(biome:*), Bash(git:*)
metadata:
  author: vyvu
  version: "1.2.0"
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

Nếu có `turbo.json` hoặc `nx.json` ở gốc repo, ưu tiên dùng orchestrator cho Bước 1-2: `turbo run typecheck build` (hoặc `nx run-many --target=typecheck,build`) có sẵn cache hit và topological ordering. Ghi nhận đây là đường ưu tiên khi phát hiện; nếu không có thì fallback về cách spawn thủ công từng package bên dưới — chỉ bổ sung, không thay thế hành vi hiện tại.

## Bước 0 — Xác định danh sách package

- Nếu `$ARGUMENTS` chứa `--test`, coi đó là cờ yêu cầu chạy test (xem Bước 4) và loại bỏ nó trước khi parse tên package
- Nếu `$ARGUMENTS` chứa `--changed`, loại bỏ nó và lấy danh sách package từ `git diff --name-only <base>...HEAD` (base = default branch của repo, vd `origin/main`, fallback `main`) thay vì toàn bộ workspace: map từng file thay đổi vào thư mục package chứa nó (các thư mục đã resolve ở điểm 2 bên dưới), loại trùng, rồi dùng danh sách đó
- Nếu `$ARGUMENTS` chứa danh sách tên package → dùng đúng danh sách đó, bỏ qua auto-detect
- Nếu rỗng → auto-detect toàn bộ workspace:
  1. Dùng workspace shape từ Bước -1. **Single-package** → danh sách package chỉ là root package; bỏ qua resolve glob, đi thẳng sang Bước 1. **Monorepo** → tiếp tục với glob pattern từ `pnpm-workspace.yaml` (hoặc field `workspaces` trong `package.json` gốc):
  2. Resolve glob thành danh sách thư mục package thực tế
  3. Với mỗi thư mục, đọc `package.json` con để lấy field `name`
  4. Chỉ giữ lại package có script `build` trong `package.json` VÀ/HOẶC có `tsconfig.json` — package không có gì để check thì loại bỏ

## Bước 1 — Typecheck song song

Sanitize tên package để dùng làm filesystem path trước: thay `/` và `@` bằng `_` (vd: `@app/api` → `_app_api`) — tên package có scope ghi thẳng vào `/tmp/tsc-<package>.log` sẽ lỗi (tạo ra subdirectory ngoài ý muốn, hoặc fail hẳn).

Nếu `turbo`/`nx` được ưu tiên (Bước -1), chạy target typecheck của orchestrator thay vì vòng lặp bên dưới, rồi đọc thẳng output của nó.

Với MỖI package trong danh sách, spawn một background command, bọc trong `time` để log ghi lại wall-time từng package:

```
{ time timeout 600s <pm workspace/root exec template từ Bước -1> <typecheck cmd> ; } > /tmp/tsc-<sanitized-package>.log 2>&1 &
```

`<typecheck cmd>` = script đã resolve ở Bước -1 (`typecheck` → `type-check` → `tsc --noEmit`). Ví dụ minh hoạ:
- pnpm + workspace, không có script `typecheck` → `{ time timeout 600s pnpm --filter <package> exec tsc --noEmit ; } > /tmp/tsc-<sanitized-package>.log 2>&1 &` (mặc định hiện tại, y hệt)
- npm + single-package → `{ time timeout 600s npm exec -- tsc --noEmit ; } > /tmp/tsc-<sanitized-package>.log 2>&1 &`

Spawn tất cả package trước, rồi mới `wait` — KHÔNG chạy tuần tự từng cái một.

Sau `wait`, đọc từng `/tmp/tsc-<sanitized-package>.log`:
- Không có lỗi → báo pass, kèm wall-time mà `time` in ở cuối log
- Có lỗi → trích xuất file:line + message cụ thể, fix, rồi recheck **chỉ package vừa fix** (chạy lại đúng 1 lệnh tsc cho package đó, không chạy lại toàn bộ danh sách)
- Nếu package không có `tsconfig.json`, coi lỗi đó là "không có config typecheck" chứ không phải lỗi type, và skip/báo cáo tương ứng thay vì coi đó là bug trong code

## Bước 2 — Build song song

Sanitize tên package để dùng làm filesystem path trước: thay `/` và `@` bằng `_` (vd: `@app/api` → `_app_api`) — tên package có scope ghi thẳng vào `/tmp/build-<package>.log` sẽ lỗi (tạo ra subdirectory ngoài ý muốn, hoặc fail hẳn).

Nếu `turbo`/`nx` được ưu tiên (Bước -1), chạy target build của orchestrator thay vì vòng lặp bên dưới, rồi đọc thẳng output của nó.

Tương tự bước 1, spawn một background command cho mỗi package, bọc trong `time`:

```
{ time timeout 600s <pm workspace/root exec template từ Bước -1> <build script> ; } > /tmp/build-<sanitized-package>.log 2>&1 &
```

`<build script>` = script `build` khai báo của package đó (Bước -1 — không có fallback raw; package không có script `build` thì bị skip, không chạy bằng lệnh thay thế). Ví dụ minh hoạ: pnpm + workspace → `{ time timeout 600s pnpm --filter <package> build ; } > /tmp/build-<sanitized-package>.log 2>&1 &` (mặc định hiện tại, y hệt).

Spawn tất cả → `wait` → parse log từng package (pass/fail, kèm wall-time). Package fail → fix, recheck chỉ package đó.

## Bước 2.5 — Lint song song

Resolve script lint theo đúng cách typecheck/build đang dùng (pattern Bước -1): `lint` → `lint:check` → fallback trực tiếp `eslint .` nếu không có script nào.

Với MỖI package trong danh sách, spawn một background command:

```
timeout 600s <pm workspace/root exec template từ Bước -1> <lint cmd> > /tmp/lint-<sanitized-package>.log 2>&1 &
```

Spawn tất cả → `wait` → parse log từng package (pass/fail). Package fail → fix, recheck chỉ package đó — quy tắc giống Bước 1-2.

## Bước 3 — Format

Thử lần lượt, dừng ở lựa chọn đầu tiên áp dụng được:
1. Script format trong `package.json` gốc (`format`, `format:fix`, ...) qua root template từ Bước -1
2. `prettier --write .` nếu `prettier` là devDependency ở đâu đó trong workspace
3. `biome check --write .` nếu `@biomejs/biome` là devDependency
4. `eslint --fix .` nếu không có lựa chọn nào ở trên, làm phương án cuối cùng

## Bước 4 — Test (chỉ khi user yêu cầu hoặc `$ARGUMENTS` chứa `--test`)

- Xác định test script trong `package.json` của từng package cần test — ưu tiên non-watch mode (`test:run`, `test:ci`, `test -- --run`, ...) hơn plain `test` nếu nghi ngờ mặc định là watch mode
- Chạy background + `wait`, giống bước 1-2 (thêm prefix `timeout 600s`)
- Fail → fix, recheck chỉ package đó, lặp lại đến khi pass — **KHÔNG BAO GIỜ** bỏ qua test failure vì bất kỳ lý do gì

---

## Quy tắc bắt buộc

- LUÔN spawn mọi package bằng background `&` rồi mới `wait` — KHÔNG BAO GIỜ chạy package tuần tự từng cái một
- KHÔNG BAO GIỜ hardcode bất kỳ tên package cụ thể nào trong logic — mọi danh sách phải đến từ argument hoặc workspace auto-detect
- Package fail → recheck chỉ package đó sau khi fix, không chạy lại toàn bộ danh sách
- KHÔNG BAO GIỜ bỏ qua test failure để đi tiếp bước khác — PHẢI fix và recheck đến khi pass
- Bọc mọi background command trong `timeout 600s` (hoặc `gtimeout` trên macOS) — package bị treo không được làm treo toàn bộ `wait`

## Bước tiếp theo

Nhìn vào kết quả thực tế của lần chạy này và tự đề xuất MỘT hành động tiếp theo hợp lý, 1-2 câu — không chọn theo danh sách cố định. Cân nhắc các skill khác trong bộ này (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) nếu thực sự phù hợp; nếu không cần gì thêm thì nói rõ luôn.
