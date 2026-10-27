---
name: vsweep
description: "Chạy một đợt quét không người trông, có giới hạn thời gian, qua một khối việc mở thuộc bất kỳ loại nào (audit code, backlog, nghiên cứu, viết lách, dọn dữ liệu, checklist vận hành, brainstorm): chọn khoảng trống tiếp theo, giao subagent, làm xong các mục rõ ràng và kiểm chứng theo cách hợp với loại việc, còn mục mơ hồ thì ghi lại thành quyết định chờ user thay vì đoán. Khi resume, implement các quyết định user đưa cho những mục đã ghi."
argument-hint: "[--until <HH:MM>|<duration>] [--resume] [topic/scope hint]"
user-invocable: true
when_to_use: "Dùng cho một lượt quét mở có deadline mà không có danh sách task cố định: 'audit toàn hệ thống tới sáng', 'brainstorm mọi góc trong 2 giờ', 'làm dần backlog khi tôi đi vắng', 'kiểm tra toàn hệ thống tới sáng', hoặc để implement quyết định của user cho các phát hiện đã ghi từ lượt trước (--resume). Không dùng cho một task đơn lẻ đã rõ."
metadata:
  author: vyvu
  version: "2.0.0"
---

# vsweep

Đây là một vòng lặp, không phải task một lần. Skill không giả định loại việc: "mục việc" là đơn vị mà chủ đề tách ra (một module, một câu hỏi, một tài liệu, một lát dữ liệu, một dòng checklist), và "đã kiểm chứng" là bất cứ thứ gì chứng minh được loại việc đó (một test, một phép tính lại, kiểm tra nguồn, chạy thử, người đọc thứ hai). Mỗi vòng chọn một mục, giao subagent, phân loại báo cáo và xem đồng hồ, cho tới điều kiện dừng. Các bước nhắc tới server, test, build hay migration chỉ áp dụng khi việc có liên quan. Phạm vi là chủ đề của user: không thêm tính năng, test hay tài liệu không được yêu cầu.

```
$ARGUMENTS
```

`--resume` hoặc có quyết định cho các phát hiện đã ghi: đọc `references/resume-mode.md` và làm theo đó thay vì phần quét bên dưới.

## Quy tắc cố định

- Không bao giờ start, restart hay tự phục hồi server/service. Nếu service chết chặn một vùng, nói rõ và quét vùng khác. Quy tắc cố định của user thắng mọi sự cho phép giữa chừng.
- Không bao giờ chạy migration, reset hay xóa hàng loạt trừ khi user yêu cầu đích danh.
- Không bao giờ cho hai agent chạy trên cùng một tài nguyên live dùng chung (phiên browser, lock độc quyền): chúng va nhau và có thể làm sập dev server dùng chung.
- Không bao giờ tự đóng một quyết định chờ user đã ghi; chỉ câu trả lời của user mới đóng được.
- Mở báo cáo bằng văn bản của subagent trước khi tin một phát hiện. Câu trả lời chat bị nén và không được lưu lại.
- Điều user tự kiểm chứng bằng tay thắng mọi thứ agent đọc hay suy ra. Trang vendor, listing trên store hay lời quảng cáo vẫn là chưa kiểm chứng cho tới khi có người dùng thật.

## Giai đoạn 0 — Phạm vi

1. Xác định điều kiện dừng từ lời user: một mốc giờ, một khoảng thời lượng, hoặc "tới khi tôi bảo dừng". Nếu thật sự mơ hồ, hỏi một lần bằng `AskUserQuestion` thay vì đoán deadline.
2. Quyết định và ghi lại ba điều cho loại việc này: **vùng** mà một vòng phủ (module, câu hỏi, chương, bảng, dòng checklist); **bằng chứng hoàn thành** (test fail-rồi-pass cộng một check runtime, nguồn bạn tự mở, người đọc thứ hai, đếm lại, chạy thử; lời agent tự nói không bao giờ tính); **song song** (các mục độc lập chỉ đọc có thể chạy cạnh nhau, mọi thứ đụng tài nguyên live dùng chung chạy từng cái một).
3. Ghi lại service nào đang chạy và port của chúng, cách kiểm chứng một thay đổi an toàn (query chỉ đọc, build, preview, chạy thử), và rằng thao tác phá hủy bị cấm trừ khi user nói khác. Lấy credential hay tài liệu tham chiếu cần cho việc từ seed script, fixture hoặc spec, không bao giờ tự bịa.
4. Lấy tiến độ trước đó từ project memory và các báo cáo cũ, để không khám phá lại việc đã xong.
5. Tạo state file `{reports}/vsweep-<slug>-state.md` (`{reports}` là thư mục reports của project, ví dụ `plans/reports/`) trước khi giao việc. Nó chứa giờ bắt đầu và `DEADLINE` (lấy từ `date`, không bao giờ ước lượng), coverage map (một checkbox mỗi vùng), ba quyết định ở bước 2, mục **User decisions (sticky)** trích nguyên văn lời user (không đảo ngược nếu chưa hỏi), và các phát hiện đã chốt. Đọc lại sau mỗi lần context bị nén, và trỏ prompt giao việc vào nó thay vì gõ lại ngữ cảnh.
6. Bật stop guard: `printf '%s\n%s\n' "<state file path>" "$(( $(date +%s) + <seconds> ))" > ~/.claude/vsweep-active`. Việc này vô hại nếu hook chưa được cài, vì nó chỉ là một file. `stop-guard.sh` đọc đúng hai dòng này (đường dẫn state, epoch của deadline).

## Giai đoạn 1 — Chọn vùng tiếp theo

Giá trị cao nhất trước:
1. Vùng chưa từng đụng tới, hoặc mới chỉ xem trên giấy.
2. Vùng chưa xem lại kể từ một thay đổi gần đó (một bản sửa, nâng dependency, đổi spec).
3. Một góc nhìn hệ thống khác trên vùng đã phủ (ví dụ "cái này có theo pattern các anh em của nó dùng không", "tài liệu còn khớp với code không"), không phải thêm một lượt với cùng góc nhìn.
4. Bất cứ thứ gì báo cáo trước đã đánh dấu là chưa xác nhận hoặc bị cắt dở.

Nếu chưa rõ vùng nào giá trị nhất, chạy một subagent rẻ chỉ để lập coverage map trước khi chọn; việc đó tốn ít hơn làm trùng.

## Giai đoạn 2 — Giao việc

Mặc định một subagent chạy tại một thời điểm. Các mục độc lập chỉ đọc, không có tài nguyên live dùng chung, có thể chạy song song tối đa 3 cái (nhiều hơn thì khâu phân loại thành nút cổ chai và tải tăng), mỗi cái có file báo cáo riêng và chủ đề không chồng lấn. Agent mới không biết gì về cuộc trò chuyện này, nên brief nào cũng gồm:
- Mục tiêu và đúng một vùng.
- Credential hay tài liệu nó cần, và danh sách ngắn "đã xác nhận, đừng khám phá lại" từ các vòng trước.
- Các quy tắc cố định ở trên, nguyên văn, và: dừng chứ đừng thử lại mù quáng nếu một service sập.
- Đường dẫn báo cáo và mẫu đặt tên chính xác, một `TL;DR` tối đa 20 dòng ở đầu (để khâu phân loại đọc phần đầu và grep phần còn lại), và hợp đồng kết thúc `Status: DONE | DONE_WITH_CONCERNS | BLOCKED` kèm một dòng `Summary`.
- Rằng file báo cáo phải được ghi; trả lời chat dài mà không có file là giao việc thất bại, nên resume agent (`SendMessage`) để nó lưu lại.

Đừng polling agent đang chạy bằng các lần chờ ngắn: khi nó xong, session này tự được đánh thức. Chỉ chờ chủ động khi không có gì đang chạy và chỉ còn đồng hồ.

## Giai đoạn 3 — Phân loại

Đọc báo cáo bằng văn bản, rồi xếp mỗi phát hiện vào đúng một nhóm:
- **Làm ngay**: an toàn, sửa tận gốc, khớp pattern đã có ở chỗ khác. Thêm hoặc chạy check lẽ ra fail trước thay đổi, rồi chạy lại.
- **Làm ngay và kiểm chứng thật**: như trên, nhưng đọc tĩnh chưa đủ làm bằng chứng (quy tắc truy cập, đổi hành vi hay UI, con số phụ thuộc dữ liệu live). Chạy thử hai chiều: ca đang hỏng giờ chạy đúng và ca đang đúng vẫn còn đúng.
- **Ghi thành quyết định chờ user**: một đánh đổi, ranh giới phạm vi, yêu cầu không rõ từ code hay spec, "cố ý hay là thiếu sót". Ghi kịch bản cụ thể, nguyên nhân gốc và 2-3 phương án có tên, rồi tiếp tục quét.
- **Đã biết**: trùng lặp. Ghi chú và đi tiếp.

Báo cáo nói "chưa xác nhận" hay "không tái hiện được" tự nó là một phát hiện; mang sự không chắc chắn đó đi tiếp. Trước khi ghi lại bất cứ gì, tự kiểm chứng một khẳng định then chốt mỗi báo cáo (grep file, mở nguồn được trích, tính lại con số). Rồi cập nhật state file: các phát hiện đã chốt, chỉnh sửa cho báo cáo trước, câu hỏi mới cho user.

Chạy một lượt đối kháng (tìm mâu thuẫn giữa các báo cáo, con số không có nguồn, khẳng định chưa ai kiểm tay) khoảng mỗi 3-4 báo cáo và một lần trước bản tổng kết cuối, đưa cho nó báo cáo gốc, không phải kết luận của bạn.

## Giai đoạn 4 — Điều khiển vòng lặp

Sau mỗi vòng, so đồng hồ thật (`date`, không bao giờ ước lượng) với `DEADLINE`. Chưa tới: về Giai đoạn 1. Đã tới: dừng ngay, dù đang nghĩ dở, và xóa `~/.claude/vsweep-active`.

Một skill không ép được lượt chạy tiếp tục, nên hãy giữ nó chuyển động:
- Gọi tool cho bước kế tiếp ngay trong cùng lượt thay vì viết "tiếp theo tôi sẽ X" rồi kết thúc lượt.
- Kết thúc lượt chỉ ổn khi có ít nhất một agent đang chạy (nó xong sẽ đánh thức bạn) hoặc bạn đang chờ quyết định của user. Không có gì đang chạy mà deadline còn mở nghĩa là giao việc ngay.
- Tin nhắn của user giữa chừng được trả lời một hai dòng, rồi vòng lặp tiếp tục ngay trong lượt đó.
- Phủ xong sớm: làm các lượt chiều sâu, không độn cho đủ giờ (red-team mọi báo cáo, đối soát con số, góc nhìn mới trên vùng đã phủ). Nếu giá trị biên rõ ràng thấp, hỏi có nên dừng sớm không.
- Stop guard: `stop-guard.sh` cạnh file này là Stop hook tùy chọn. Khi `~/.claude/vsweep-active` tồn tại và deadline còn phía trước, nó nhắc một lần mỗi lần dừng, fail-open, và cho phép lần dừng thứ hai nên không bao giờ lặp. Bật bằng cách thêm hook trong comment ở đầu script vào `~/.claude/settings.json`. Hủy một lượt chạy bằng `rm ~/.claude/vsweep-active`.

## Giai đoạn 5 — Kiểm chứng cuối

Trước bản tổng kết khi dừng, kiểm lại mọi thứ đã đụng tới cùng nhau, không phải từng mục riêng lẻ, vì thay đổi tích lũy qua một lượt chạy dài. Với code: full test suite và mọi gate của project (typecheck, lint, build, mọi check ranh giới). Test runner chỉ transpile có thể bỏ sót lỗi type mà typecheck thật bắt được, nên test xanh một mình chưa nghĩa là xong. Với loại việc khác, chạy check toàn bộ tương đương. Gate nào không chạy được thì nói trong bản tổng kết.

## Giai đoạn 6 — Dừng và bàn giao

1. Xóa `~/.claude/vsweep-active` nếu còn, rồi chạy một lượt kiểm tra tổng thể trên mọi thứ đã đổi (liệt kê status hoặc diff) và xác nhận mỗi file bị đụng truy được về một thay đổi giải thích được.
2. Đưa một bản tổng kết hợp nhất ngay trong cuộc trò chuyện, không tạo file mới trừ khi project yêu cầu: cái gì đã chốt và kiểm chứng thế nào, cái gì chưa kiểm chứng, mâu thuẫn tìm thấy, mọi thứ sửa tiện tay, và một bảng quyết định cho user xếp theo mức độ chặn công việc (kèm các phương án có tên). Theo quy ước báo cáo của project nếu có.
3. Chỉ thông báo user nếu có gì cần họ quyết khi quay lại, không phải một tin "xong" thường lệ.

Làm theo quy ước Next Steps trong `_vskills-shared/repo-profile.md` §7.
