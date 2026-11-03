# job-queue

Hàng đợi FIFO giới hạn tài nguyên (số lệnh, CPU, RAM) của các lệnh nặng (test, build, typecheck, e2e) chạy cùng lúc trên máy. Chỉ cần bash.

```bash
jobq run -- pnpm --filter api test            # xếp hàng, tối đa 2 lệnh cùng lúc (JOBQ_SLOTS)
jobq run -s 1 -t 600 -- pnpm check-types      # -s số slot, -t timeout (giây), -w thời gian chờ tối đa
jobq budget cpu=6 mem=8000 jobs=3             # ngân sách hiện tại (đổi là có hiệu lực ngay với lệnh đang chờ)
jobq max cpu=6 mem=9000 jobs=4                # TRẦN CỨNG: ngân sách không bao giờ vượt qua
jobq stats                                    # lệnh nào nặng: số lần chạy, CPU/RAM lớn nhất, thời gian
jobq run --cost cpu=3,mem=2000 -- <lệnh>      # khai sẵn điểm nặng cho lệnh chưa có lịch sử
jobq status                                   # ai đang chạy, ai đang chờ, load + RAM trống
jobq clean                                    # dọn slot/ticket của tiến trình đã chết
./check-jobq                                  # PASS/FAIL tự kiểm tra (~12s, nhẹ)
```

```bash
lint-script path/to/check-x.sh                # ép khuôn chung; FAIL <file>: <lý do>, exit 1
stepper plans/scripts/x/steps                 # chạy 01-*.sh, 02-*.sh... mỗi bước qua jobq; lỗi thì dừng, chạy lại để tiếp
stepper <dir> --from 03 | --reset | -t 1200   # bắt đầu từ bước 03 | xoá trạng thái | timeout mỗi bước
```

Script mới bắt đầu từ `template.sh`. Script nặng (>120 dòng, >2 phút, nhiều pha) phải tách thành `NN-tên.sh` rồi chạy bằng `stepper`.

Cài: `./install.sh --with-scripts` (link `~/.claude/scripts/job-queue`), rồi `ln -s ~/.claude/scripts/job-queue/jobq ~/.local/bin/jobq`.

## Hành vi
- Mỗi lệnh có điểm nặng (CPU, RAM) = số đo lớn nhất trong 5 lần chạy gần nhất của cùng lệnh (đo mỗi 2 giây trên cả nhóm tiến trình, lưu ở `~/.cache/jobq/history.tsv`). Chưa có lịch sử → mặc định 2 nhân, 2000MB.
- Lệnh vào khi tổng điểm đang chạy + điểm của nó ≤ ngân sách và số lệnh < `jobs`; lệnh nặng hơn cả ngân sách vẫn chạy khi hàng trống.
- Ngân sách bị kẹp dưới trần `max`; cấu hình lưu ở `~/.cache/jobq/config` (biến môi trường `JOBQ_*` thắng).
- Đo CPU dựa trên `ps %cpu` nên chỉ gần đúng; tiến trình con tự tách nhóm (vd. Chrome) có thể không được tính.
- Lệnh thứ 3 trở đi chờ tới lượt; thứ tự gần đúng FIFO (độ phân giải 1 giây).
- Lệnh thứ 2 trở lên chỉ bắt đầu khi load < 75% số core và RAM trống ≥ 1500MB; lệnh đầu tiên luôn được chạy để hàng đợi không kẹt khi máy bận việc khác.
- Lệnh chạy với `nice 10` + `taskpolicy -b` (macOS), `NODE_OPTIONS` giới hạn heap 3GB, `UV_THREADPOOL_SIZE=2`, và biến `JOBQ_WORKERS=2` để script con đọc.
- Quá timeout (mặc định 900s) → giết cả cây tiến trình, exit 124. Ctrl-C hoặc kill `jobq` cũng giải phóng slot và giết lệnh con.
- Lệnh con gọi `jobq` lần nữa thì chạy thẳng (đã giữ slot), không tự kẹt.
- Biến cấu hình: `JOBQ_SLOTS`, `JOBQ_TIMEOUT`, `JOBQ_WAIT`, `JOBQ_MAX_LOAD`, `JOBQ_MIN_FREE_MB`, `JOBQ_NODE_MB`, `JOBQ_DIR`.

## Lỗi hay gặp
- Exit 75: chờ quá `JOBQ_WAIT` giây. Chạy `jobq status`; nếu có slot treo mà tiến trình đã chết thì `jobq clean`.
- Lệnh lâu hơn 900s (e2e dài) bị giết: tăng `-t`.
- Không giới hạn được tiến trình con tự spawn nhiều worker; vẫn phải truyền `--concurrency=2` / `--maxWorkers=2` / `--workers=2` cho turbo/vitest/jest/playwright.
- Hàng đợi chung cho cả máy: dev server của user (api/web) không đi qua `jobq`, nhưng chúng làm load tăng nên lệnh thứ 2 sẽ chờ lâu hơn.

## Hook chặn chạy thẳng
`jobq-guard` (đã gắn vào `~/.claude/settings.json`, PreToolUse/Bash) chặn `pnpm test|build|check-types`, `turbo`, `vitest`, `jest`, `playwright test`, `tsc`, `next build`, `docker build` khi không đi qua `jobq run`. Bản sao lưu settings cũ: `settings.json.bak-jobq`. Gỡ: xoá mục cuối của `hooks.PreToolUse`.
