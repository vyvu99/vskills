---
name: vsweep
description: "Chạy một đợt rà soát không giám sát, có giới hạn thời gian, qua 1 khối việc mở trong codebase: chọn mảng còn thiếu tiếp theo, dispatch đúng 1 subagent mỗi lần, tự hoàn thành việc rõ ràng kèm test và verify sống, và ghi nhận việc mơ hồ thành quyết định đang chờ thay vì tự đoán. Khi resume, triển khai các quyết định user đưa ra trên những mục đã ghi nhận đó với cùng mức độ kỹ lưỡng — sửa đúng root-cause, có test, verify sống, dọn dẹp, thông báo rõ cho user."
argument-hint: "[--until <HH:MM>|<thời-lượng>] [--resume] [gợi ý mảng/phạm vi]"
user-invocable: true
when_to_use: "Gọi khi cần đi qua 1 backlog mở, có giới hạn thời gian, không có danh sách task cố định — audit bug/bảo mật, backlog feature/test/doc, 1 đợt refactor ('kiểm tra toàn hệ thống tới sáng', 'làm hết backlog trong lúc tôi vắng', 'đi hết mọi role tới X') — hoặc để resume và triển khai các quyết định user đưa ra trên phát hiện đã ghi nhận từ 1 đợt trước."
metadata:
  author: vyvu
  version: "1.1.0"
---

Bạn đang chạy một vòng lặp rà soát không giám sát, không phải 1 task làm 1 lần xong. Mỗi vòng chọn 1 việc còn thiếu, dispatch đúng 1 subagent, triage report của nó, rồi kiểm tra giờ — lặp lại tới khi đạt điều kiện dừng. Một chế độ RESUME riêng (cùng skill, kích hoạt khi user trở lại với quyết định) triển khai các mục đang chờ đã ghi nhận với đầy đủ mức độ kỹ lưỡng kỹ thuật.

═══════════════════════════════════════════════════════
GIAI ĐOẠN 0 — PHẠM VI
═══════════════════════════════════════════════════════

1. Xác định điều kiện dừng từ đúng lời user: 1 mốc giờ tuyệt đối, 1 khoảng thời lượng, hoặc "tới khi tôi bảo dừng". Thật sự mơ hồ → hỏi 1 lần qua `AskUserQuestion`, không bao giờ tự đoán deadline.
2. Liệt kê mọi thứ đợt này sẽ cần dùng lại nhiều lần — thông tin đăng nhập, tài khoản, quyền truy cập, tài liệu tham khảo — đọc seed script/fixture/spec nếu chưa biết sẵn. Không bao giờ tự bịa ra 1 cái.
3. Ghi lại server/service nào đang chạy sẵn và port của chúng. Skill này KHÔNG BAO GIỜ tự khởi động hay restart server — kể cả khi vừa được cấp phép bằng lời giữa buổi, nếu user (hoặc project memory) đã có quy tắc thường trực cấm việc đó. Bị chặn vì service đang tắt → nói rõ ra và chuyển sang mảng khác thay vì tìm cách lách qua.
4. Xác định cách verify an toàn cho 1 thay đổi (1 query chỉ-đọc, 1 bản build, 1 preview, 1 lần chạy thử) để dùng sau, và xác nhận các lệnh phá hoại (migration, reset, xoá hàng loạt) nằm ngoài phạm vi cho phép trừ khi user nói khác.
5. Lấy lại tiến độ đã có từ project memory / report cũ trước vòng đầu tiên — đừng khám phá lại cái đã xong rồi.

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
GIAI ĐOẠN 2 — DISPATCH (1 subagent mỗi lần)
═══════════════════════════════════════════════════════

- Đúng 1 agent đang chạy bất cứ khi nào task đụng tới 1 tài nguyên mà chính phiên này cũng đang điều khiển trực tiếp — browser automation là trường hợp phổ biến nhất: 2 agent cùng lái 1 browser sẽ va tab/session và có thể làm sập dev server chung dưới tải gộp. Task chỉ đọc tĩnh có thể chạy mà không cần ràng buộc này, nhưng mặc định vẫn 1-lần-1-agent trừ khi việc rõ ràng độc lập.
- Mọi prompt dispatch phải tự đủ thông tin — 1 agent mới không nhớ gì từ cuộc trò chuyện này. Luôn kèm:
  - Mọi thông tin đăng nhập/tài khoản/tài liệu tham khảo agent cần cho task này, nếu có.
  - 1 danh sách ngắn "đã xác nhận rồi, đừng khám phá lại" lấy từ các vòng trước.
  - Ràng buộc cứng nguyên văn: không bao giờ khởi động/restart server, không bao giờ chạy migration hay lệnh phá hoại dữ liệu, dừng lại (không retry mù quáng) nếu service sập giữa task.
  - Đường dẫn + quy tắc đặt tên file report chính xác cần ghi vào, và hợp đồng đóng bắt buộc: `Status: DONE | DONE_WITH_CONCERNS | BLOCKED` kèm 1 dòng `Summary`.
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

═══════════════════════════════════════════════════════
GIAI ĐOẠN 4 — KỶ LUẬT REGRESSION
═══════════════════════════════════════════════════════

Sau mỗi đợt thay đổi trực tiếp, và luôn trước khi tổng kết dừng: chạy toàn bộ test suite cộng mọi gate riêng của project (type-check, lint, build, bất kỳ gate contract/boundary nào project định nghĩa) — không chỉ test của riêng mảng vừa chạm, vì các thay đổi cộng dồn qua nhiều file suốt 1 đợt dài. Để ý riêng 1 lỗi kiểu dữ liệu mà test runner chỉ transpile sẽ không bắt được nhưng gate type-check thật của project sẽ bắt; test xanh không có nghĩa fix đã xong nếu project có 1 gate chặt hơn.

═══════════════════════════════════════════════════════
GIAI ĐOẠN 5 — KIỂM SOÁT VÒNG LẶP
═══════════════════════════════════════════════════════

Kiểm tra đồng hồ thật (không bao giờ tự ước lượng thời gian đã trôi) so với điều kiện dừng sau mỗi vòng.
- Chưa tới → chọn mảng tiếp theo (Giai đoạn 1), dispatch (Giai đoạn 2), tiếp tục.
- Đã tới → dừng ngay, kể cả đang giữa suy nghĩ. Không bắt đầu "thêm 1 cái nữa cho chắc."

═══════════════════════════════════════════════════════
GIAI ĐOẠN 6 — DỪNG → CHUYỂN GIAO
═══════════════════════════════════════════════════════

1. Chạy 1 lượt rà soát cuối trên mọi thứ đã đổi trong đợt này (1 bảng status/diff) — xác nhận mọi file bị chạm đều có 1 lý do thay đổi giải thích được trước khi tới tay user.
2. Gửi đúng 1 bản tổng kết gộp, trực tiếp trong cuộc trò chuyện (không tạo file tổng kết mới trừ khi quy ước riêng của project yêu cầu), gồm: cái gì đã làm xong, cái gì tình cờ được sửa luôn trên đường đi, cái gì chủ động để mở chờ quyết định (kèm các phương án có tên), và bất cứ gì đã gắn cờ nhưng không xác nhận được. Theo đúng quy ước report riêng của project nếu có (ngôn ngữ thường, không định danh kỹ thuật, đóng khung theo tình huống) kể cả khi bản thân đợt rà soát mang tính kỹ thuật.
3. Chỉ gửi thông báo cho user nếu có gì cần quyết định hay chú ý khi họ trở lại — không gửi ping "xong việc" thường quy.

═══════════════════════════════════════════════════════
CHẾ ĐỘ RESUME — TRIỂN KHAI CÁC QUYẾT ĐỊNH ĐÃ GHI NHẬN
═══════════════════════════════════════════════════════

Kích hoạt khi user trở lại với câu trả lời ngắn gọn cho các mục đang chờ mà Giai đoạn 3 đã ghi nhận.

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

═══════════════════════════════════════════════════════
BƯỚC TIẾP THEO
═══════════════════════════════════════════════════════

Nhìn vào cái đợt này thực sự tìm ra và đã làm, rồi gợi ý ĐÚNG 1 hành động tiếp theo hợp lý trong 1-2 câu — đừng chọn từ 1 danh sách cố định. 1 lượt `vreview` trên mọi thứ đã chạm, hay `vci` để kiểm tra typecheck/build lần cuối, là 2 lựa chọn hay gặp nếu không có gì khác nổi bật hơn.
