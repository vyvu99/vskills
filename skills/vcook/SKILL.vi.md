---
name: vcook
description: "Implement một feature hoặc fix từ đầu đến cuối, từ đường dẫn plan hoặc mô tả ngắn: tạo branch, viết test trước, code backend và frontend, review đối chiếu CLAUDE.md, chạy test, commit và mở PR. Chạy tường minh bằng /vcook."
argument-hint: "[plan-path | mô tả task] [--issue <number>]"
user-invocable: true
disable-model-invocation: true
when_to_use: "Dùng khi user muốn một task hoặc plan của vplan được implement và mong đợi commit cùng pull request, không chỉ sửa code."
metadata:
  author: vyvu
  version: "2.0.0"
---

Bạn là senior engineer implement task từ đầu đến cuối qua 9 bước dưới đây. Theo dõi các bước bằng checklist (TodoWrite hoặc công cụ task của session) và chỉ đánh dấu xong khi việc của bước đó đã xong; Bước 1 là rule xuyên suốt nên giữ mở đến khi Bước 9 kết thúc.

**Ưu tiên:** chạy /vcook là yêu cầu tường minh của user để tạo branch, commit, push và mở PR, nên các hành động đó không cần xác nhận thêm. Nếu `CLAUDE.md` của project hoặc của user cấm bất kỳ hành động nào (ví dụ "không tự tạo branch hay PR khi chưa hỏi"), rule đó thắng và bạn phải hỏi trước.

**Phạm vi:** chỉ implement đúng những gì plan hoặc mô tả yêu cầu. Cải tiến thêm thì đề xuất chứ không tự làm, và không thêm test, docs hay refactor không được yêu cầu.

Sau khi bị gián đoạn, dựng lại tiến độ từ `git status`, `git diff` so với branch ở Bước 2 và (Mode A) file plan. Trạng thái repo là sự thật, không phải status cũ trong checklist.

## Bước 1 - Delegate việc read-only

Delegate cho subagent khi việc read-only vừa độc lập vừa rộng: đọc plan cùng nhiều vùng code, research docs thư viện, hoặc review nhiều nhóm file riêng biệt đối chiếu CLAUDE.md. Tự làm khi chỉ tra 1-2 file, vì subagent bắt đầu với context rỗng và tốn một brief cùng một bản tóm tắt.

- Subagent độc lập đặt trong cùng 1 message để chạy song song; chia batch theo `_vskills-shared/repo-profile.md` §10.
- Brief nêu mục tiêu, file hoặc vùng trong phạm vi, việc subagent chỉ được đọc, và file báo cáo `{work_context}/plans/reports/<agent-type>-<HHMMSS>-<slug>.md` mà subagent ghi trước khi trả lời (§6). Đọc lại file đó thay vì tin vào câu trả lời.
- Tự viết code implementation trong session này, từng bước một: một writer duy nhất giữ các chỉnh sửa nhất quán.
- Các writer thực sự độc lập trên file khác nhau mỗi người dùng git worktree riêng để working tree không đụng nhau.

## Bước 2 - Xác định branch

1. Branch hiện tại đã khớp task (user chủ ý tiếp tục) -> giữ nguyên.
2. Nếu không: xác định default branch (`repo-profile.md` §9). `git status --porcelain` có output thì hỏi user nên stash, commit hay tiếp tục trên branch hiện tại. Sau đó `git checkout <default_branch>`, `git pull`, `git checkout -b <branch-name>`; tên là kebab-case tiếng Anh mô tả thay đổi, không prefix theo tool hay agent trừ khi repo bắt buộc.

Chốt PR base branch ngay bây giờ, trước khi Bước 5 thêm commit, vì detect bằng merge-base kém tin cậy sau đó. Bước 9 truyền nó vào `gh pr create --base`; default của `gh` luôn nhắm vào default branch, sai với branch stacked.
- Vừa tách từ `<default_branch>` ở bước này -> base là `<default_branch>`.
- Đang ở branch có sẵn và caller đã nói nó tách từ đâu ("checkout từ Y") -> dùng Y; bên dựng branch đã tính 1 lần, tốt hơn suy lại.
- Đang ở branch có sẵn và không ai nói -> với mỗi branch local và remote `b` khác, giữ những branch pass `git merge-base --is-ancestor b HEAD`; branch có `git rev-list --count b..HEAD` nhỏ nhất là parent. Parent là `<default_branch>` (hoặc bản mirror `origin/`) -> base là `<default_branch>`; là branch khác chưa merge -> branch đó là base (stacked PR), vì dùng default branch sẽ kéo commit của predecessor vào diff của PR này.

## Bước 3 - Xác định chế độ input

**Mode A - `$ARGUMENTS` là đường dẫn plan** (`plans/<slug>/`, `plan.md`, `phase-XX-*.md`):
1. Đọc toàn bộ plan và các phase file, rồi các vùng code nó tham chiếu (áp dụng delegate ở Bước 1).
2. Kiểm tra code còn khớp assumption của plan: file đúng path, API và pattern như mô tả, dependency chưa đổi. Nếu stamp `Generated against commit` của `plan.md` lệch HEAD, re-verify trước các file:line của case PASS.
3. Lệch -> dừng, trình bày chỗ lệch kèm đề xuất điều chỉnh, rồi chờ. Không tự lệch khỏi plan.

**Mode B - mô tả hoặc diff có sẵn:** tự quyết phạm vi từ đó và đặt tên branch theo thay đổi nếu Bước 2 chưa làm.

## Bước 4 - Test trước

Với mỗi function hoặc endpoint mới/sửa có logic API hoặc backend:
1. Liệt kê test hiện có chạm vào code đó (grep file test, theo import).
2. Viết test cho happy path và edge case (null, rỗng, 0, âm, biên, đồng thời).
3. Chạy và xác nhận test fail trước khi implement; test pass ngay thì chẳng chứng minh gì, viết lại. Ghi output fail vào item checklist (output dài ghi vào `{work_context}/plans/reports/vcook-test-log-<HHMMSS>.md`).

Việc thuần UI (chỉ style hoặc layout, không có business logic) được bỏ qua test-first; ghi "pure UI, skipping test-first" vào checklist.

## Bước 5 - Implement

- Làm theo plan (Mode A) hoặc mô tả (Mode B).
- Khi cả backend và frontend bị ảnh hưởng thì implement cả hai; backend đổi mà UI chưa phản ánh là chưa xong.

## Bước 6 - Dùng API client được generate

- Mọi lời gọi API phía client đi qua generated SDK, vì `fetch` hay `axios` thô bỏ qua contract có type mà việc regenerate giữ đồng bộ.
- Tìm SDK: script `sdk:generate`, `api:generate` hoặc `codegen` trong `package.json`, hoặc thư mục `generated/`, `__generated__/`, `sdk/`.
- Route mới thiếu response schema -> thêm schema vào package schema dùng chung, chạy lệnh generate, rồi mới viết code frontend.
- Không có tầng SDK -> dùng API client sẵn có của project (vẫn không dùng fetch thô) hoặc hỏi user.

## Bước 7 - Review đối chiếu CLAUDE.md

- Áp dụng rule trong `CLAUDE.md` của project và của user ngay khi code.
- Trước khi commit, đối chiếu diff cuối với toàn bộ các rule đó (subagent theo từng nhóm file độc lập, Bước 1). Lần đối chiếu này chính là review; chỉ thêm subagent reviewer riêng khi thay đổi lớn hoặc rủi ro cao.

## Bước 8 - Verify

- Chạy full test suite của mọi package bị chạm, không chỉ test liên quan, cộng typecheck và lint nếu project có. Báo coverage delta nếu repo theo dõi coverage.
- Fail thì sửa root cause và chạy lại đến khi pass hết. Không skip, làm yếu hay mock test để ra xanh.
- Nếu thay đổi gọi được qua HTTP hoặc CLI, gọi thật một lần và đưa output thật vào báo cáo. Nếu cần server chưa chạy thì không tự start; nhờ user start hoặc báo "chưa chạy thử" kèm lý do.
- Nếu không chạy được test, typecheck hay lệnh run nào ở đây, nói rõ trong báo cáo và đánh dấu thay đổi là chưa verify.

## Bước 9 - Commit và mở PR

Xác định VCS profile trước (`repo-profile.md` §2; nếu thiếu file thì giả định GitHub với `gh`).

**Commit:** message tiếng Anh theo conventional commit (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`), mỗi nhóm thay đổi logic một commit. Hơn 5 commit thì cân nhắc squash các commit liên quan. In `git log --oneline <base>..HEAD` trước khi push để user thấy danh sách cuối.

**PR:**
- Caller nói "chỉ commit, không PR" (ví dụ pipeline mở 1 PR cho nhiều task) -> commit rồi dừng: không push, không PR, không sửa issue.
- Theo đúng `.github/pull_request_template.md` nếu có, không thì Summary / Changes / Test plan. Title tiếng Anh, ngắn gọn.
- Ngôn ngữ description: `repo-profile.md` §4. Viết cho người không phải engineer: tác động tới user và business, không jargon code.
- Full gh mode -> `gh pr create --base <base từ Bước 2>`. Degraded hoặc local-only -> push branch, in message vcook của §2 và title cùng body đã soạn để user dán. Soạn body ở cả hai chế độ.
- Issue liên quan (từ plan hoặc `--issue`): đặt `Closes #<issue>` ở đầu body PR; ở full gh mode thêm link PR vào cuối body issue bằng `gh issue edit`, không thì báo user tự thêm.

## Next steps

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
