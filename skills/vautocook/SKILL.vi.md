---
name: vautocook
description: "Tự động thực thi từng sub-issue của 1 GitHub epic theo thứ tự, mỗi sub-issue chạy như 1 phiên /vcook headless cô lập với branch + PR riêng, sắp theo dependency, resume được, fail-fast. Dựa trên 2 script đi kèm (plan_tasks.py, run_tasks.py) gọi ra `claude -p --dangerously-skip-permissions` cho từng task — rủi ro cao, luôn hiện kế hoạch cho user xác nhận trước khi chạy."
argument-hint: "<epic_url>"
user-invocable: true
disable-model-invocation: true
when_to_use: "Dùng khi đã có sẵn epic + sub-issues (ví dụ do vtickets tạo) và muốn triển khai tự động, lần lượt từng cái, không cần ngồi canh từng lượt /vcook."
metadata:
  author: vyvu
  version: "1.0.0"
---

Tự động triển khai từng sub-issue của 1 GitHub epic, tuần tự, không cần người canh. Mỗi sub-issue chạy như 1 phiên `/vcook` cô lập ở chế độ headless (`claude -p --dangerously-skip-permissions`) — có branch riêng, PR riêng, không hỏi lại ai giữa chừng. Dựa trên 2 script đi kèm trong thư mục `scripts/` của skill này; file này chỉ là hướng dẫn *khi nào và chạy sao*, bản thân nó không phải script.

Đọc input từ user:

```
$ARGUMENTS
```

`$ARGUMENTS` rỗng — hỏi user URL của epic issue (ví dụ epic vừa được `vtickets` tạo).

---

## Bước 0 — Xác định VCS profile + điều kiện tiên quyết

Đọc `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (nếu không có → giả định GitHub + gh). Không ở full gh mode → **STOP** — toàn bộ cơ chế của skill này (lấy sub-issues, mở PR) là API riêng của GitHub, không có fallback; báo user sửa `gh` auth trước.

Đồng thời kiểm tra `claude` đã có trong PATH và đã login (các script gọi ra nó 1 lần mỗi task): `which claude` lỗi → STOP, báo user cài/login Claude Code CLI trước.

## Bước 1 — Sinh kế hoạch task (chỉ đọc, an toàn)

```bash
python3 ~/.claude/skills/vautocook/scripts/plan_tasks.py <epic_url>
```

- Lấy sub-issues của epic qua GitHub GraphQL API.
- Chạy DUY NHẤT 1 lần gọi `claude -p` headless để nhờ sắp xếp sub-issues thành chuỗi tuần tự (mỗi task chỉ phụ thuộc đúng task ngay trước nó) và đặt tên branch cho từng task.
- Phát hiện sub-issue đã xong (issue đã đóng + có PR đã merge vào default branch của repo) và đánh dấu `status: "done"` để bước 3 bỏ qua.
- Ghi `tasks.json` cạnh script — trạng thái scratch cục bộ cho lần chạy pipeline này, không phải plan artifact; đừng commit hay trỏ code/PR comment vào đó.

Bước này không sửa code và không mở gì cả — chạy thoải mái không cần hỏi trước.

## Bước 2 — Hiện kế hoạch, xin xác nhận rõ ràng

Đọc `tasks.json` vừa sinh, in danh sách task đã sắp thứ tự (số issue, title, tên branch, chuỗi phụ thuộc) cho user. **STOP và xin xác nhận rõ ràng trước Bước 3 — đây là gate bắt buộc, không phải tuỳ chọn:** Bước 3 chạy các phiên code hoàn toàn tự động với `--dangerously-skip-permissions`, tự push branch và mở PR thật, chạy nối tiếp nhau, không xác nhận từng task khi đã bắt đầu. Nêu rõ:
- Bao nhiêu task đang pending, bao nhiêu đã done.
- Đây là fail-fast — 1 task fail thì dừng cả pipeline; task đã done vẫn giữ nguyên.
- `tasks.json` có thể sửa tay (đổi thứ tự, sửa dependency sai, sửa tên branch sai) trước Bước 3 — đó chính là lý do tách 2 script riêng.

## Bước 3 — Chạy pipeline

Chỉ sau khi user xác nhận:

```bash
python3 ~/.claude/skills/vautocook/scripts/run_tasks.py
```

- Với mỗi task pending, theo thứ tự: checkout branch của nó (từ default branch, hoặc từ branch của task phụ thuộc nếu task đó chưa merge — chuỗi PR chồng lên nhau), điền `scripts/prompt.md` với ngữ cảnh của task, rồi chạy `claude -p <prompt> --dangerously-skip-permissions --output-format stream-json --verbose`. Phiên bên trong đó chạy `/vcook` trên issue ở chế độ headless (không dừng lại hỏi; tự xử lý ambiguity theo root-cause/KISS/DRY, ghi quyết định vào PR body) và được kỳ vọng tự tạo commit + PR qua Step 9 của chính `/vcook`.
- Sau khi phiên bên trong kết thúc, kiểm tra branch đã có PR chưa; `/vcook` chưa mở được PR → fallback: tự push branch và mở 1 PR tối giản (không gọi thêm AI cho fallback này).
- **Resume:** Ctrl+C hoặc crash giữa chừng để lại task ở `status: "running"` trong `tasks.json` — chạy lại `run_tasks.py` sẽ tự reset về `pending` và tiếp tục từ đó.
- **Fail-fast:** task kết thúc mà không có PR sẽ dừng cả lượt chạy; sửa nó (hoặc sửa `tasks.json`) rồi chạy lại để tiếp tục.
- Khi xong, in ra **thứ tự merge** — vì task sau chồng lên branch của task trước, nên PR phải merge từ trên xuống, từng level một, rebase giữa các level.

## Bước 4 — Báo cáo

Tóm tắt những gì đã chạy: task nào xong trong lượt này kèm URL PR, task nào còn `pending`/`failed`, và thứ tự merge từ output Bước 3. Không được im lặng dừng giữa epic mà không nói rõ task nào chặn lại.

---

## Hard rules

- **Không bao giờ** chạy Bước 3 mà chưa có user xác nhận rõ ràng danh sách task ở Bước 2 — `--dangerously-skip-permissions` cho từng task nghĩa là không còn ai canh sau khi bắt đầu.
- **Không bao giờ** tự sửa tay field `status` trong `tasks.json` để ép 1 task thành done/skip — task nào cần bỏ qua thì báo user tự sửa file; việc bỏ task nào là quyết định của họ, không phải của skill này.
- Mỗi phiên `/vcook` bên trong là **phiên mới, cô lập hoàn toàn** — không thấy được cuộc hội thoại này. Input duy nhất của nó là template `prompt.md` đã điền (URL issue, URL epic, branch, parent branch, số issue) — không gì khác từ cuộc hội thoại này truyền sang.
- Pipeline chỉ hoạt động trên GitHub (GraphQL sub-issues, `gh pr create`) — không có chế độ degraded/non-GitHub; STOP của §2 áp dụng ở Bước 0, không phải giữa chừng.
- `tasks.json` là trạng thái scratch cho lượt chạy pipeline này, không phải plan artifact.

## Bước tiếp theo

Theo convention "Next steps" chung tại `_vskills-shared/repo-profile.md` §7.
