# vskills

🌐 [English](README.md) | Tiếng Việt

Bộ skill Claude Code cho toàn bộ vòng đời một task lập trình: specs, plan, code, review, sửa. Mỗi skill là một tệp `SKILL.md` thuần, được symlink vào `~/.claude/skills`. Không có lớp plugin, không có tệp cấu hình.

```mermaid
flowchart LR
    idea(["idea / bug"]) --> specs["/vspecs"] --> plan["/vplan"] --> cook["/vcook"] --> review["/vreview"] --> fix["/vreview --fix"] --> ship(["ship"])
    fix -. more issues .-> review
```

## Cài đặt

Cần Claude Code CLI, `git` và `bash`. Tùy chọn: `gh` (skill GitHub), Node.js (webapp, lint rule, `check-skills`), `jq` (eval, hook và dashboard của `jobq`).

```bash
git clone git@github.com:vyvu99/vskills.git && cd vskills
./install.sh
```

| Cờ | Tác dụng |
|---|---|
| `--lang=vi` | Cài bản tiếng Việt của mọi skill |
| `--with-scripts` | Cài thêm lint rule và hàng đợi lệnh `jobq` |
| `--with-claude-md` | Chép thêm `~/.claude/CLAUDE.md` khởi tạo (bỏ qua nếu đã có) |
| `--dry-run` | In ra việc sẽ làm, không đổi gì |

Skill là symlink nên sửa trong repo là sửa skill đã cài. Tệp thật có sẵn ở đích được đổi tên thành `<path>.bak.<timestamp>`, không bao giờ bị xóa. Chạy lại sẽ gỡ các skill đã bị xóa khỏi repo.

## Skills

`*` chỉ chạy khi gọi tay.

| Skill | Chức năng | Ví dụ |
|---|---|---|
| `vspecs` | Viết specs bằng ngôn ngữ thường, cùng bạn chốt các trường hợp biên | `/vspecs Feature: rebooking` |
| `vplan` | Đối chiếu từng case với code (PASS/FAIL/MISSING), viết plan theo pha | `/vplan plans/specs/rebooking.md` |
| `vcook`* | Tạo branch, viết test trước, code, review, mở PR từ plan hoặc task | `/vcook plans/rebooking` |
| `vreview` | Review diff, PR, branch hoặc thư mục ra `.code-review/REPORT.md`; `--fix` sửa theo mức ưu tiên | `/vreview #482` |
| `vtickets`* | Tạo hoặc đồng bộ epic và sub-issue GitHub từ plan | `/vtickets plans/rebooking` |
| `vci` | Format, typecheck, build, lint (thêm test với `--test`) trên repo JS/TS, tự sửa lỗi | `/vci --changed` |
| `vdesign` | Thiết kế lại trang hoặc component: nghiên cứu, audit, sửa, kiểm ở 375/768/1280px | `/vdesign /clients/[id]` |
| `vsweep` | Rà backlog không cần canh đến hạn chót; mục chưa rõ thành quyết định chờ xử lý | `/vsweep --until 06:00` |
| `vrollback`* | Rollback một migration trên database dev cục bộ, có xác nhận | `/vrollback 0007_add_status` |
| `vguide` | Viết hướng dẫn sử dụng theo vai trò cho sản phẩm hoặc tính năng | `/vguide Feature: checkout` |

Cờ và trường hợp biên nằm trong `skills/<name>/SKILL.md`.

## Hàng đợi lệnh (tùy chọn)

`jobq` giữ cho máy luôn mượt khi Claude chạy lệnh nặng: chỉ chạy vài lệnh cùng lúc, giới hạn tự suy ra từ CPU và RAM, và báo các lệnh quá giới hạn thời gian để chia nhỏ.

```bash
./install.sh --with-scripts        # liên kết jobq, stepper, lint-script vào ~/.local/bin
jobq run -- pnpm --filter api test # đưa một lệnh vào hàng đợi
jobq web                           # dashboard trực tiếp
```

Để Claude dùng hàng đợi, chép hook `jobq-guard` vào `~/.claude/settings.json` (cần `jq`). Chi tiết: [`scripts/job-queue/README.vi.md`](scripts/job-queue/README.vi.md).

## Đóng góp

| Đường dẫn | Mục đích |
|---|---|
| `skills/<name>/SKILL.md`, `SKILL.vi.md` | Một skill, bản Anh và bản Việt có cùng số dòng |
| `skills/_vskills-shared/` | Tài liệu tham chiếu dùng chung |
| `claude-md/CLAUDE.md` | Quy tắc khởi tạo cho `--with-claude-md` |
| `evals/` | Eval kích hoạt và hành vi (`scripts/run-evals.sh`, gọi `claude -p`, có tính phí) |
| `web/` | Webapp cục bộ mà `vspecs` và `vreview --fix` dùng |
| `scripts/` | Công cụ tùy chọn: `lint-rules`, `job-queue` |

```bash
mkdir skills/<name>              # thêm SKILL.md và SKILL.vi.md
./install.sh
node scripts/check-skills.js     # frontmatter, độ dài mô tả, cân bằng Anh-Việt
```

Muốn gỡ skill: xóa thư mục, grep các tham chiếu chéo rồi chạy lại `./install.sh`.

## License

[AGPL-3.0](LICENSE). Copyright (c) 2026 vyvu.
