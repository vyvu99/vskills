---
name: vsweep
description: "Chạy một đợt rà soát không giám sát, có giới hạn thời gian, qua 1 khối việc mở thuộc BẤT KỲ loại nào (code, nghiên cứu, viết lách, dữ liệu, vận hành, thiết kế, brainstorm — skill không giả định loại task): chọn mảng còn thiếu tiếp theo, dispatch subagent, tự hoàn thành việc rõ ràng và verify theo cách phù hợp với loại việc, và ghi nhận việc mơ hồ thành quyết định đang chờ thay vì tự đoán. Khi resume, triển khai các quyết định user đưa ra trên những mục đã ghi nhận đó với cùng mức độ kỹ lưỡng — sửa đúng root-cause, verify, dọn dẹp, thông báo rõ cho user."
argument-hint: "[--until <HH:MM>|<thời-lượng>] [--resume] [gợi ý mảng/phạm vi]"
user-invocable: true
when_to_use: "Gọi khi cần đi qua 1 backlog hoặc chủ đề mở, có giới hạn thời gian, không có danh sách task cố định, bất kể loại việc — audit bug/bảo mật, backlog feature/test/doc, 1 đợt refactor, 1 đợt nghiên cứu hoặc brainstorm, dọn nội dung/dữ liệu, checklist vận hành ('kiểm tra toàn hệ thống tới sáng', 'cứ brainstorm mọi ý tưởng xoay quanh trong 2 giờ', 'làm hết backlog trong lúc tôi vắng', 'đi hết mọi role tới X') — hoặc để resume và triển khai các quyết định user đưa ra trên phát hiện đã ghi nhận từ 1 đợt trước."
metadata:
  author: vyvu
  version: "1.2.0"
---

Bạn đang chạy một vòng lặp rà soát không giám sát, không phải 1 task làm 1 lần xong. Skill không phụ thuộc loại task: "việc" là bất cứ đơn vị nào chủ đề của user chia ra được (1 module, 1 câu hỏi, 1 tài liệu, 1 lát dữ liệu, 1 dòng checklist), và "verify" nghĩa là bất cứ gì chứng minh được loại việc đó (test, tính lại, đối chiếu nguồn, chạy thử, người đọc thứ hai). Mỗi vòng chọn 1 việc, dispatch 1 subagent, triage report của nó, rồi kiểm tra giờ — lặp lại tới khi đạt điều kiện dừng. Một chế độ RESUME riêng (cùng skill, kích hoạt khi user trở lại với quyết định) triển khai các mục đang chờ đã ghi nhận với đầy đủ mức độ kỹ lưỡng cho loại việc đó.

Các bước nhắc tới server, test, build hay migration chỉ áp dụng khi việc có liên quan tới chúng; nếu không thì bỏ qua thay vì bịa ra thứ tương đương. Chốt trước "việc", bằng chứng hoàn thành và mức song song cho loại việc này (xem ADAPTING TO THE KIND OF WORK bên dưới).

═══════════════════════════════════════════════════════
GIAI ĐOẠN 0 — PHẠM VI
═══════════════════════════════════════════════════════

1. Xác định điều kiện dừng từ đúng lời user: 1 mốc giờ tuyệt đối, 1 khoảng thời lượng, hoặc "tới khi tôi bảo dừng". Thật sự mơ hồ → hỏi 1 lần qua `AskUserQuestion`, không bao giờ tự đoán deadline.
2. Liệt kê mọi thứ đợt này sẽ cần dùng lại nhiều lần — thông tin đăng nhập, tài khoản, quyền truy cập, tài liệu tham khảo — đọc seed script/fixture/spec nếu chưa biết sẵn. Không bao giờ tự bịa ra 1 cái.
3. Ghi lại server/service nào đang chạy sẵn và port của chúng. Skill này KHÔNG BAO GIỜ tự khởi động hay restart server — kể cả khi vừa được cấp phép bằng lời giữa buổi, nếu user (hoặc project memory) đã có quy tắc thường trực cấm việc đó. Bị chặn vì service đang tắt → nói rõ ra và chuyển sang mảng khác thay vì tìm cách lách qua.
4. Xác định cách verify an toàn cho 1 thay đổi (1 query chỉ-đọc, 1 bản build, 1 preview, 1 lần chạy thử) để dùng sau, và xác nhận các lệnh phá hoại (migration, reset, xoá hàng loạt) nằm ngoài phạm vi cho phép trừ khi user nói khác.
5. Lấy lại tiến độ đã có từ project memory / report cũ trước vòng đầu tiên — đừng khám phá lại cái đã xong rồi.
6. Tạo STATE FILE `{reports}/vsweep-<slug>-state.md` (`{reports}` = thư mục report của project, ví dụ `plans/reports/`) trước khi dispatch bất cứ gì. Nó chứa: giờ bắt đầu và `DEADLINE` (lấy từ `date`, không ước lượng), bản đồ phạm vi (1 checkbox mỗi mảng), mục **Quyết định của user (cố định)** trích nguyên văn lời user — không bao giờ đảo ngược mà không hỏi — và các phát hiện đã chốt tới giờ. Đọc lại nó sau mỗi lần context bị nén và trỏ mọi prompt dispatch vào nó thay vì gõ lại ngữ cảnh.
7. Bật stop guard (xem GIAI ĐOẠN 5): `printf '%s\n%s\n' "<đường dẫn state file>" "$(( $(date +%s) + <số giây> ))" > ~/.claude/vsweep-active` (vô hại nếu chưa cài hook stop-guard — chỉ là 1 file không ai đọc).

═══════════════════════════════════════════════════════
GIAI ĐOẠN 1 — CHỌN MẢNG TIẾP THEO (mỗi vòng)
═══════════════════════════════════════════════════════

Xếp hạng ứng viên, giá trị cao nhất trước:
1. Mảng chưa từng chạm tới, hoặc chỉ mới xem trên giấy — chưa thật sự dispatch 1 subagent vào đó.
2. Mảng chưa xem lại từ sau 1 thay đổi gần đó (1 fix, 1 bump dependency, 1 đổi schema/spec).
3. Một LĂNG KÍNH hệ thống khác áp lên vùng đã "phủ" rồi — ví dụ "component này có đúng pattern như các component anh em không," "doc còn khớp với cái code đang thật sự làm không" — không chỉ lặp lại cùng 1 lăng kính.
4. Bất cứ gì 1 report trước đã ghi rõ là chưa xác nhận được hoặc bị cắt ngắn vì hết giờ.

Thật sự không chắc mảng nào giá trị cao nhất → bỏ 1 fork nhanh chỉ để tổng hợp bản đồ phạm vi (cái gì xong, cái gì còn mở) trước khi chọn. Rẻ hơn đoán sai rồi làm trùng việc.

═══════════════════════════════════════════════════════
GIAI ĐOẠN 2 — DISPATCH (mặc định: 1 subagent mỗi lần)
═══════════════════════════════════════════════════════

- Đúng 1 agent đang chạy bất cứ khi nào task đụng tới 1 tài nguyên mà chính phiên này cũng đang điều khiển trực tiếp — browser automation là trường hợp phổ biến nhất: 2 agent cùng lái 1 browser sẽ va tab/session và có thể làm sập dev server chung dưới tải gộp. Task chỉ đọc tĩnh có thể chạy mà không cần ràng buộc này, nhưng mặc định vẫn 1-lần-1-agent trừ khi việc rõ ràng độc lập.
- Mọi prompt dispatch phải tự đủ thông tin — 1 agent mới không nhớ gì từ cuộc trò chuyện này. Luôn kèm:
  - Mọi thông tin đăng nhập/tài khoản/tài liệu tham khảo agent cần cho task này, nếu có.
  - 1 danh sách ngắn "đã xác nhận rồi, đừng khám phá lại" lấy từ các vòng trước.
  - Ràng buộc cứng nguyên văn: không bao giờ khởi động/restart server, không bao giờ chạy migration hay lệnh phá hoại dữ liệu, dừng lại (không retry mù quáng) nếu service sập giữa task.
  - Đường dẫn + quy tắc đặt tên file report chính xác cần ghi vào, và hợp đồng đóng bắt buộc: `Status: DONE | DONE_WITH_CONCERNS | BLOCKED` kèm 1 dòng `Summary`.
  - Hợp đồng report: mở đầu report bằng `TL;DR` ≤20 dòng (để triage đọc phần đầu và grep phần còn lại), và PHẢI GHI FILE — trả lời chat dài mà không có file là dispatch thất bại; resume agent (`SendMessage`) để nó lưu file.
- Các task độc lập chỉ-đọc/nghiên cứu (không đụng tài nguyên sống dùng chung) được chạy song song, tối đa ~3 cái cùng lúc; mỗi cái có file report riêng và chủ đề không chồng nhau.
- Không poll 1 agent đang chạy bằng các lần chờ ngắn liên tục — 1 lần dispatch đã tự đánh thức lại phiên này khi xong. Chỉ chờ chủ động khi không có gì đang chạy và thứ còn lại chỉ là chờ đồng hồ chạm tới điều kiện dừng.

═══════════════════════════════════════════════════════
GIAI ĐOẠN 3 — TRIAGE (sau khi mỗi report về)
═══════════════════════════════════════════════════════

Đọc đúng file report thật agent đã ghi ra — 1 câu trả lời chat ngắn đôi khi quá nén để mang đủ 1 phát hiện thật, và nó cũng không phải cái tồn tại lâu dài. Xếp mỗi phát hiện vào đúng 1 trong các nhóm:

- **Làm ngay** — an toàn, đúng root-cause, khớp 1 pattern đã có sẵn ở chỗ khác trong codebase. Mở rộng hoặc thêm 1 test lẽ ra phải fail trước khi có fix, chạy lại nó.
- **Làm ngay + verify sống** — như trên, nhưng bất cứ khi nào đọc tĩnh không đủ bằng chứng (ràng buộc truy cập, 1 thay đổi hành vi, 1 thay đổi UI): chạy thử qua app thật đang sống theo CẢ 2 chiều — ca trước đây bị lỗi giờ hoạt động đúng, và ca đã hoạt động đúng vẫn tiếp tục đúng.
- **Ghi nhận thành quyết định đang chờ** — 1 trade-off thiết kế, 1 ranh giới phạm vi, 1 yêu cầu thật sự không rõ chỉ từ code/spec, "đây là chủ đích hay là thiếu sót." Không bao giờ tự đoán. Ghi lại tình huống/tác động cụ thể, root cause, và 2-3 phương án xử lý có tên; vẫn tiếp tục rà mảng khác khi mục này còn mở.
- **Đã biết rồi** — trùng với cái đã xong hoặc đã ghi nhận. Ghi chú lại, đi tiếp.

1 report trước đó ghi "chưa xác nhận được" hay "không tái hiện được" chính nó cũng là 1 phát hiện thật — mang sự không chắc chắn đó đi tiếp một cách trung thực, đừng lặng lẽ tự kết luận theo hướng nào.

Trước khi ghi 1 phát hiện, tự verify ít nhất 1 khẳng định then chốt mỗi report (grep file, mở nguồn được trích, tính lại phép toán). Khẳng định từ trang store, trang nhà cung cấp hay quảng cáo là chưa verify cho tới khi có người dùng thử thật — 1 lần kiểm tra thực tế của user vượt mọi listing. Ghi mỗi report đã triage vào state file (phát hiện đã chốt, đính chính report trước, câu hỏi mới cho user).

═══════════════════════════════════════════════════════
GIAI ĐOẠN 4 — KỶ LUẬT REGRESSION
═══════════════════════════════════════════════════════

Bất kể loại việc, các thay đổi cộng dồn phải được kiểm tra lại toàn bộ 1 lần trước bản tổng kết dừng: verify mọi thứ đã chạm cùng nhau, không chỉ từng mục riêng lẻ. Với code nghĩa là (với loại việc khác, thay bằng phép kiểm tra toàn bộ tương đương): sau mỗi đợt thay đổi trực tiếp, và luôn trước khi tổng kết dừng, chạy toàn bộ test suite cộng mọi gate riêng của project (type-check, lint, build, bất kỳ gate contract/boundary nào project định nghĩa) — không chỉ test của riêng mảng vừa chạm, vì các thay đổi cộng dồn qua nhiều file suốt 1 đợt dài. Để ý riêng 1 lỗi kiểu dữ liệu mà test runner chỉ transpile sẽ không bắt được nhưng gate type-check thật của project sẽ bắt; test xanh không có nghĩa fix đã xong nếu project có 1 gate chặt hơn.

═══════════════════════════════════════════════════════
GIAI ĐOẠN 5 — KIỂM SOÁT VÒNG LẶP
═══════════════════════════════════════════════════════

Kiểm tra đồng hồ thật (`date`, không bao giờ tự ước lượng thời gian đã trôi) so với DEADLINE trong state file sau mỗi vòng.
- Chưa tới → chọn mảng tiếp theo (Giai đoạn 1), dispatch (Giai đoạn 2), tiếp tục.
- Đã tới → dừng ngay, kể cả đang giữa suy nghĩ. Không bắt đầu "thêm 1 cái nữa cho chắc." Xoá `~/.claude/vsweep-active`.

Quy tắc chống nghỉ giữa chừng (1 skill không ép được 1 lượt tiếp tục; các quy tắc này giữ cho nó chạy):
- Không bao giờ viết "tiếp theo tôi sẽ X" rồi kết thúc lượt — gọi tool cho X ngay trong cùng lượt. Triage và lần dispatch tiếp theo thuộc cùng 1 lượt.
- Chỉ được kết thúc lượt khi có ≥1 agent đang chạy (nó xong sẽ đánh thức lại) hoặc đang chờ user quyết. Không có gì đang chạy và chưa tới deadline → dispatch ngay.
- User nhắn giữa chừng: trả lời trong 1-2 dòng, rồi tiếp tục vòng lặp ngay trong cùng lượt.
- Phủ xong bản đồ phạm vi trước deadline → làm lượt chiều sâu, không độn thời gian: red team trên mọi report (mâu thuẫn giữa các report, số không có nguồn, khẳng định dựa trên listing chưa ai dùng thử), đối chiếu số, 1 lăng kính mới trên vùng đã phủ. Nếu giá trị biên rõ ràng thấp, hỏi user có nên dừng sớm không thay vì lấp đầy giờ.
- Stop guard: `stop-guard.sh` (cạnh file này) là 1 Stop hook tuỳ chọn. Khi `~/.claude/vsweep-active` tồn tại và deadline còn ở tương lai, nó nhắc 1 lần mỗi lần dừng kèm lý do để tiếp tục; nó fail-open và không bao giờ lặp vô hạn (cho phép lần dừng thứ hai). Bật bằng cách thêm hook trong comment đầu `stop-guard.sh` vào `~/.claude/settings.json`. Hủy sớm 1 đợt chạy bằng `rm ~/.claude/vsweep-active`. Bật bằng cách thêm hook trong comment ở đầu `stop-guard.sh` vào `~/.claude/settings.json`. Huỷ 1 đợt sớm bằng `rm ~/.claude/vsweep-active`.

═══════════════════════════════════════════════════════
THÍCH ỨNG THEO LOẠI VIỆC
═══════════════════════════════════════════════════════

Vòng lặp giống nhau cho mọi loại việc; chỉ có ba thứ đổi. Quyết định chúng ở Giai đoạn 0 và ghi vào state file:
1. **Mảng** — 1 vòng phủ cái gì: 1 module hoặc endpoint (code), 1 câu hỏi hoặc chủ đề (nghiên cứu/brainstorm), 1 chương hoặc mục (viết lách), 1 bảng hoặc lát dữ liệu (dữ liệu), 1 dòng checklist (vận hành).
2. **Bằng chứng xong** — cái gì khiến 1 mục "xong": test fail-rồi-pass và 1 check lúc chạy (code), 1 nguồn bạn tự mở hoặc 1 con số tính lại (nghiên cứu), 1 người đọc thứ hai hoặc fact check (viết lách), 1 lần đếm lại hoặc diff (dữ liệu), 1 lần chạy thử (vận hành). Không bao giờ chấp nhận lời agent làm bằng chứng.
3. **Song song** — các mục độc lập chỉ-đọc/nghiên cứu có thể chạy cạnh nhau (Giai đoạn 2); bất cứ gì đụng tài nguyên sống dùng chung vẫn 1-lần-1.

Không phụ thuộc loại việc:
- Chạy 1 lượt đối kháng (tìm mâu thuẫn giữa các report, số không có nguồn, khẳng định chưa ai tự kiểm tra) sau khoảng mỗi 3-4 report và 1 lần trước bản tổng kết cuối; đưa nó các report thô, không đưa kết luận của bạn.
- Sự thật do người tự tay verify vượt mọi thứ agent đọc hay suy ra. Trích chúng vào mục cố định của state file.
- Bản tổng kết cuối: cái gì đã chốt (và verify bằng cách nào), cái gì chưa verify, mâu thuẫn tìm thấy, và 1 bảng quyết định cho user xếp theo mức độ chặn công việc.

═══════════════════════════════════════════════════════
GIAI ĐOẠN 6 — DỪNG → CHUYỂN GIAO
═══════════════════════════════════════════════════════

1. Tắt stop guard (`rm -f ~/.claude/vsweep-active`) nếu file còn đó, rồi chạy 1 lượt rà soát cuối trên mọi thứ đã đổi trong đợt này (1 bảng status/diff) — xác nhận mọi file bị chạm đều có 1 lý do thay đổi giải thích được trước khi tới tay user.
2. Gửi đúng 1 bản tổng kết gộp, trực tiếp trong cuộc trò chuyện (không tạo file tổng kết mới trừ khi quy ước riêng của project yêu cầu), gồm: cái gì đã làm xong, cái gì tình cờ được sửa luôn trên đường đi, cái gì chủ động để mở chờ quyết định (kèm các phương án có tên), và bất cứ gì đã gắn cờ nhưng không xác nhận được. Theo đúng quy ước report riêng của project nếu có (ngôn ngữ thường, không định danh kỹ thuật, đóng khung theo tình huống) kể cả khi bản thân đợt rà soát mang tính kỹ thuật.
3. Chỉ gửi thông báo cho user nếu có gì cần quyết định hay chú ý khi họ trở lại — không gửi ping "xong việc" thường quy.

═══════════════════════════════════════════════════════
CHẾ ĐỘ RESUME — TRIỂN KHAI CÁC QUYẾT ĐỊNH ĐÃ GHI NHẬN
═══════════════════════════════════════════════════════

Kích hoạt khi user trở lại với câu trả lời ngắn gọn cho các mục đang chờ mà Giai đoạn 3 đã ghi nhận. Các bước dưới đây viết cho code; với loại việc khác giữ nguyên ý định (đọc lại trạng thái hiện tại, cùng pattern như các mục anh em, 1 check fail trước và pass sau, 1 lần verify thật, 1 lượt kiểm tra lại toàn bộ cuối cùng) và đổi công cụ.

1. Khớp mỗi câu trả lời với đúng mục đã ghi nhận theo nội dung, không theo thứ tự giả định; hỏi 1 lần nếu việc khớp thật sự mơ hồ.
2. Với mỗi mục: đọc code HIỆN TẠI thật mới — không bao giờ triển khai từ ký ức của bản ghi cũ. Tái dùng pattern đã có sẵn ở chỗ khác trong codebase cho cùng loại vấn đề; khi cơ chế thẳng đó không áp dụng được (ví dụ 1 field bị mã hoá nên không thể lọc ở tầng database), chọn biến thể tối thiểu cần thiết và để lại comment giải thích trade-off.
3. Mở rộng file/helper test đã có sẵn cho mảng đó (tham số hoá nó, không tạo 1 bản song song trùng lặp) với cả ca regression và 1 ca lẽ ra phải fail trước khi có thay đổi.
4. Verify đầu-cuối (app thật, 1 bản build, 1 preview — bất cứ gì thật sự chứng minh được) theo cả 2 chiều trước khi chuyển sang mục tiếp theo.
5. Nếu verify ghi ra hàng dữ liệu thật vào 1 dataset chung/dev, chạy lại toàn bộ suite sau đó — 1 test cùng môi trường có thể assert đúng số liệu sống. Bị vỡ vì việc đó → chỉ xoá ĐÚNG các hàng đợt này tạo ra, không bao giờ đụng cái có từ trước, rồi xác nhận lại xanh.
6. Lần theo mọi đường lỗi mới tới đúng thông báo hiển thị cho user, không chỉ dừng ở code backend — kiểm tra tầng response/serialization thật, vì chuỗi thông báo cho người đọc thường không phải cái được trả nguyên văn. Thay thông báo chung chung bằng 1 thông báo riêng cho ca mới, khớp với cách các ca anh em đã xử lý trong cùng component đó; để ý tránh hiện 2 toast/thông báo trùng khi cả callback lẫn 1 check tay riêng sau cùng lệnh gọi đều có thể cùng bắn cho 1 lỗi.
7. Lượt cuối khi mọi mục xong: lint/format cộng toàn bộ regression suite trên mọi thứ đã chạm, trước khi báo xong.

═══════════════════════════════════════════════════════
QUY TẮC CỨNG
═══════════════════════════════════════════════════════

- Không bao giờ tự khởi động, restart, hay tự khôi phục 1 server/service — báo rõ điểm bị chặn và tiếp tục rà mảng khác.
- Không bao giờ chạy migration, reset, hay lệnh phá hoại dữ liệu hàng loạt mà không có user yêu cầu đích danh.
- Không bao giờ chạy 2 agent cùng lúc lên cùng 1 tài nguyên sống dùng chung (browser session, khoá độc quyền).
- Không bao giờ tin riêng câu trả lời chat của 1 subagent cho bất cứ gì mà tính đúng đắn quan trọng — mở file report nó đã ghi ra.
- Không bao giờ tự âm thầm giải quyết 1 quyết định đang chờ đã ghi nhận — chỉ câu trả lời của chính user mới đóng được nó.
- Không bao giờ để các thay đổi cộng dồn của 1 đợt dài bỏ qua 1 lượt regression đầy đủ cuối cùng.
- Không bao giờ kết thúc 1 lượt bằng 1 câu "tiếp theo tôi sẽ…" chưa thực hiện khi deadline còn mở và không có gì đang chạy.
- Không bao giờ coi 1 listing store, trang nhà cung cấp hay khẳng định quảng cáo là đã verify; báo cáo dùng thử thực tế của user vượt nó.

═══════════════════════════════════════════════════════
BƯỚC TIẾP THEO
═══════════════════════════════════════════════════════

Nhìn vào cái đợt này thực sự tìm ra và đã làm, rồi gợi ý ĐÚNG 1 hành động tiếp theo hợp lý trong 1-2 câu — đừng chọn từ 1 danh sách cố định. 1 lượt `vreview` trên mọi thứ đã chạm, hay `vci` để kiểm tra typecheck/build lần cuối, là 2 lựa chọn hay gặp nếu không có gì khác nổi bật hơn.
