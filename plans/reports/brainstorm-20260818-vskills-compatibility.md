# Brainstorm: generalize vskills compatibility

## Problem
Repo tagline = "opinionated checklists" nhưng lock-in cứng vào stack cá nhân (pnpm/TS/Next.js/gh CLI/tiếng Việt). Chưa có pain point thực tế — robust hoá phòng ngừa trước khi mở repo cho use case khác + dùng trên project khác của chính tác giả.

## Scope found (scout)
- `vcheck` — hardcode `pnpm --filter`, `pnpm-workspace.yaml`. Không fallback npm/yarn/bun, không có single-package mode.
- `vdesign` — Next.js-only guidance (`<Link>`/`<Image>`).
- `vcook`, `vreview`, `vissues`, `vrules`, `vdesign` — phụ thuộc `gh` CLI, GitHub-only.
- `vreview` — file filter/boilerplate-skip nghiêng TS/TSX (`*.ts`/`*.tsx`, lockfile list thiếu Cargo.lock/go.sum/poetry.lock/Gemfile.lock).
- `vcook` Step 9 — hardcode "PR description viết tiếng Việt", không đọc từ CLAUDE.md.
- `vmigrate-rollback` — đã generic tốt (multi-ORM/multi-DB detect), không cần sửa.
- `scripts/lint-rules/` — đã tự nhận personal + opt-in (`--with-scripts`), không cần sửa.

## Decisions (user-confirmed)
- Mục tiêu: cả dùng cá nhân đa project + mở cho người khác, ưu tiên không phá default behavior hiện tại (pnpm/GitHub/TS/tiếng Việt).
- DRY: tách file dùng chung `skills/_shared/repo-profile.md`, sửa `install.sh` để symlink thêm (không duplicate detect logic ở 6 file).
- VCS: chỉ graceful degrade (detect thiếu `gh`/không phải GitHub → báo rõ + hướng dẫn thủ công, không crash). KHÔNG build GitLab support (`glab`) đợt này — YAGNI, chưa có pain point.

## Approach

### `skills/_shared/repo-profile.md` (mới, plain reference doc, không phải skill invokable)
4 section, mỗi skill trỏ vào section liên quan thay vì duplicate:

1. **Package manager + workspace shape** — detect qua `packageManager` field → lockfile (pnpm-lock.yaml/yarn.lock/bun.lockb/package-lock.json); workspace qua `pnpm-workspace.yaml`/`workspaces` field, fallback single-package. Command template per manager (pnpm/yarn/npm/bun × workspace/root).
2. **VCS host + CLI** — `git remote get-url origin` → match host. GitHub + `gh` available → dùng như cũ. Khác → graceful degrade: 1 dòng cảnh báo + hướng dẫn thủ công, tiếp tục phần còn lại của skill.
3. **Ngôn ngữ/framework** — extension trong diff (.ts/.py/.go...) + dep trong package.json (next/nuxt/astro...). Không detect được → generic, không assume Next.js.
4. **PR/communication language** — CLAUDE.md project (`## Ngôn ngữ`/`## Language`) → global `~/.claude/CLAUDE.md` → default English.

### Sửa từng skill (trỏ vào repo-profile.md, không duplicate)
- `vcheck` — thay block lệnh pnpm cứng → resolve §1 + nhánh single-package.
- `vcook` — Step 9 wrap §2 (gh) + §4 (PR language) thay hardcode tiếng Việt.
- `vreview` — `gh pr view` wrap §2; file filter/boilerplate-skip mở rộng theo §3.
- `vissues` — gh GraphQL sub-issues wrap §2 degrade.
- `vrules` — đọc PR comment qua gh wrap §2.
- `vdesign` — Next.js guidance gate theo §3; gh usage wrap §2.

### `install.sh`
Loại trừ `_shared/` khỏi loop symlink-per-SKILL.md hiện tại; thêm dòng symlink riêng `skills/_shared` → `~/.claude/skills/_shared` (luôn cài, không opt-in — 6 skill phụ thuộc cứng).

## Verification
Với repo pnpm + GitHub + gh CLI + TS + CLAUDE.md tiếng Việt (case hiện tại của tác giả): mọi detection resolve đúng y hệt hành vi cũ — default behavior không đổi.

## Next
`/ck:plan` từ report này — phases theo từng skill sửa (vcheck, vcook, vreview, vissues, vrules, vdesign) + phase riêng cho `_shared/repo-profile.md` + `install.sh` (nên là phase đầu, các phase sau phụ thuộc vào nó).
