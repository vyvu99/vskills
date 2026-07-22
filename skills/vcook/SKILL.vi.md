---
name: vcook
description: "Checklist 9 bước bắt buộc khi implement feature/fix: subagent song song → xác định branch → xác định chế độ plan/no-plan → viết test trước → implement đầy đủ BE+FE → bắt buộc dùng generated SDK client → review đối chiếu CLAUDE.md → test đến khi pass → squash commit + tạo PR từ template. KHÔNG được bỏ qua bước nào."
argument-hint: "[plan-path | mô tả task] [--issue <number>]"
user-invocable: true
when_to_use: "Invoke để implement một feature/fix từ plan có sẵn hoặc từ mô tả nhanh — tự động tạo branch, viết test, code, review, chạy test, commit, và tạo PR."
category: workflow
keywords: [cook, implement, workflow, plan, sdk, commit, pr]
extends: cook
metadata:
  author: vyvu
  version: "1.0.0"
---

Trước tiên, invoke skill `cook` (dùng Skill tool, tên chính xác, không prefix) để chạy workflow implementation nền tảng. Sau đó, bạn là một senior engineer áp dụng checklist 9 bước bắt buộc dưới đây bên trên nó. KHÔNG được bỏ qua bước nào.

**TRƯỚC KHI BẮT ĐẦU:** Tạo checklist 9 bước bằng `TodoWrite` (mỗi item ứng với 1 bước). Sau khi hoàn thành mỗi bước → đánh dấu `completed` trước khi chuyển sang bước tiếp theo. KHÔNG đánh dấu completed trước khi công việc thực sự xong.

═══════════════════════════════════════════════════════
BƯỚC 1: SONG SONG HOÁ VÀO SUBAGENT
═══════════════════════════════════════════════════════

Trước khi thực hiện mỗi bước dưới đây, đánh giá phần nào độc lập → delegate cho các subagent chạy song song trong CÙNG 1 message (không tuần tự nếu không có dependency). Áp dụng xuyên suốt, không chỉ ở đầu:
- Đọc plan + đọc codebase liên quan (bước 3) → subagent song song
- Research pattern/docs cho các thư viện đang dùng → subagent song song
- Review đối chiếu CLAUDE.md trên nhiều file độc lập (bước 7) → subagent song song

Mục đích: giảm token usage của main agent — main agent chỉ tổng hợp kết quả.

═══════════════════════════════════════════════════════
BƯỚC 2: XÁC ĐỊNH BRANCH
═══════════════════════════════════════════════════════

1. Kiểm tra branch hiện tại: nếu tên/nội dung đã khớp với task đang làm (user đang chủ ý tiếp tục trên branch đó) → BỎ QUA bước tạo branch, dùng branch hiện tại.
2. Nếu không khớp:
   - Tự động detect default branch: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||'` → nếu rỗng, thử `git rev-parse --verify main 2>/dev/null` → dùng `main`; nếu `main` không tồn tại → dùng `master`.
   - `git checkout <default_branch>` → `git pull` → `git checkout -b <descriptive-branch-name>`
   - Tên branch: kebab-case, tiếng Anh, mô tả chính xác phạm vi thay đổi (không gắn prefix theo tool/agent trừ khi repo bắt buộc theo convention riêng).

═══════════════════════════════════════════════════════
BƯỚC 3: XÁC ĐỊNH CHẾ ĐỘ INPUT
═══════════════════════════════════════════════════════

Input là 1 trong 2 dạng — tự động detect từ `$ARGUMENTS`:

**Mode A — Có plan path** (ví dụ: `plans/<slug>/`, `plan.md`, `phase-XX-*.md`):
1. Đọc toàn bộ plan + các phase file liên quan.
2. Đọc kỹ các vùng codebase mà plan tham chiếu tới (dùng subagent song song theo bước 1).
3. Cross-check: codebase hiện tại có khớp với assumption của plan không? (file còn tồn tại đúng path, pattern/API còn khớp với mô tả trong plan, dependency chưa đổi...)
4. Nếu có MISMATCH → STOP, trình bày mismatch cụ thể + đề xuất điều chỉnh cho user TRƯỚC khi code. KHÔNG được lệch khỏi plan mà không hỏi.
5. Nếu khớp → chuyển sang bước 4.

**Mode B — Không có plan** (mô tả nhanh, hoặc diff đã tồn tại sẵn — "PR từ trên trời rơi xuống"):
1. Bỏ qua bước đọc plan.
2. Tự xác định scope từ mô tả/diff hiện có.
3. Đặt tên branch (nếu chưa làm ở bước 2) khớp với bản chất thay đổi quan sát được.

═══════════════════════════════════════════════════════
BƯỚC 4: VIẾT TEST CASE + EDGE CASE TRƯỚC KHI CODE
═══════════════════════════════════════════════════════

- **Bắt buộc** với API/backend logic: với mỗi function/endpoint mới hoặc sửa đổi, liệt kê test case TRƯỚC khi viết implementation — happy path + edge case (null/undefined/empty/0/negative/boundary/concurrent).
- **Không bắt buộc** với pure UI (chỉ style/layout, không business logic). Nếu bỏ qua → ghi rõ lý do trong checklist ("pure UI, skipping test-first").

═══════════════════════════════════════════════════════
BƯỚC 5: IMPLEMENT
═══════════════════════════════════════════════════════

- Bám sát plan (Mode A) hoặc mô tả (Mode B).
- Nếu ảnh hưởng cả BE lẫn FE → implement ĐẦY ĐỦ CẢ HAI, không để BE xong mà UI chưa reflect (FE/BE Balance).
- Nếu phát hiện improvement phù hợp trong lúc code → đề xuất với user, KHÔNG tự ý mở rộng scope ngoài plan/mô tả.

═══════════════════════════════════════════════════════
BƯỚC 6: BẮT BUỘC DÙNG GENERATED SDK/API CLIENT
═══════════════════════════════════════════════════════

- Mọi API call phía client/web-app → PHẢI dùng generated SDK. Raw `fetch`/`axios` là CẤM.
- Tự động detect xem SDK có tồn tại không:
  - grep `package.json` tìm script `sdk:generate` / `api:generate` / `codegen`
  - hoặc tìm thư mục `generated/`, `__generated__/`, `sdk/`, hoặc pattern đặc trưng của Fern/openapi-generator/orval
- Route BE mới trả về `void`/thiếu response schema → thêm response schema vào shared schema package TRƯỚC, rồi chạy generate command đã tìm được (tối thiểu map trên BE nếu FE chưa cần dùng ngay).
- Không tìm thấy generate script/SDK directory → project không có SDK layer riêng, dùng API client hiện có của project (vẫn KHÔNG raw fetch/axios trực tiếp) hoặc hỏi user nếu chưa rõ.

═══════════════════════════════════════════════════════
BƯỚC 7: REVIEW ĐỐI CHIẾU CLAUDE.md
═══════════════════════════════════════════════════════

- Đọc `~/.claude/CLAUDE.md` (nếu chưa nắm rõ), tự áp dụng rule liên quan NGAY TRONG LÚC code (TypeScript, Styling, Form Fields, Backend, Frontend, File & Folder Structure...) — không đợi một pass review riêng mới sửa.
- Trước khi commit → double-check diff cuối cùng đối chiếu với rule (dùng subagent song song nếu có nhiều file độc lập).
- Không cần một subagent review riêng nữa nếu đã làm đúng ngay từ đầu.

═══════════════════════════════════════════════════════
BƯỚC 8: CHẠY TEST, FIX ĐẾN KHI PASS
═══════════════════════════════════════════════════════

- Chạy test suite liên quan (unit/integration theo convention của project).
- Nếu fail → fix root cause (không patch triệu chứng) → chạy lại.
- Lặp lại đến khi pass 100%. KHÔNG được skip test fail để commit nhanh hơn, KHÔNG dùng mock/fake data/tricks để giả vờ pass.

═══════════════════════════════════════════════════════
BƯỚC 9: COMMIT + TẠO PR
═══════════════════════════════════════════════════════

**Commit:**
- Message tiếng Anh, conventional commit format (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`).
- Squash thành số lượng commit hợp lý, gom theo logical change — KHÔNG tạo nhiều commit nhỏ lẻ rải rác.

**PR:**
- Đọc `.github/pull_request_template.md` của project (nếu có) → PR body PHẢI theo đúng template đó. Nếu không có → dùng format mặc định hợp lý (Summary / Changes / Test plan).
- Title: tiếng Anh, ngắn gọn.
- Description: **viết bằng tiếng Việt**, không thuật ngữ kỹ thuật — dành cho người đọc không phải engineer, tập trung vào tác động user/business, không dùng code jargon.
- Nếu có GitHub issue liên quan (từ plan hoặc user cung cấp số issue):
  - Thêm `Closes #<issue>` ở ĐẦU PR body
  - `gh issue edit <issue>` để append link tới PR vào CUỐI issue body

---

## Hard rules

- **KHÔNG được bỏ qua bước nào** trong 9 bước — kể cả khi task trông "đơn giản"
- **Codebase lệch so với plan** → dừng lại, trình bày mismatch + đề xuất, chờ user xác nhận. TUYỆT ĐỐI KHÔNG lệch khỏi plan mà không hỏi
- **Test fail** → fix root cause đến khi pass 100%, KHÔNG commit khi test đang fail, KHÔNG mock/fake để né test
- **Commit** → squash hợp lý theo logical change, KHÔNG spam nhiều commit nhỏ
- **API call phía client** → LUÔN dùng generated SDK, raw fetch/axios CẤM; thiếu response schema → thêm schema + regenerate SDK trước khi viết code FE
- **Scope** → bám sát chặt scope của plan/mô tả; improvement thêm → đề xuất, không tự ý mở rộng scope
- **PR description** → tiếng Việt, không thuật ngữ kỹ thuật, theo đúng `.github/pull_request_template.md` nếu có
- **Test-first** → bắt buộc với API/backend logic, không bắt buộc với pure UI (phải ghi rõ lý do khi bỏ qua)

## Bước tiếp theo

Khi PR đã mở, báo user hướng đi phù hợp với tình huống:
- Chưa chạy typecheck/build cho thay đổi này → đề xuất `/vcheck` trước khi xin review.
- Diff lớn hoặc đụng logic nhạy cảm → đề xuất `/vreview` để tự review trước khi người khác review.
- Có plan/issue liên quan chưa track trên GitHub → đề xuất `/vissues <plan-path>`.
- Không rơi vào trường hợp nào ở trên → PR đã sẵn sàng, không cần thêm skill nào nữa.
