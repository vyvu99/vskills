---
name: vsweep
description: "Chạy một đợt rà soát bug/bảo mật không giám sát, có giới hạn thời gian: chọn mảng còn thiếu tiếp theo, dispatch đúng 1 subagent điều tra mỗi lần, tự sửa các lỗi rõ ràng kèm test và verify sống, và ghi nhận các phát hiện mơ hồ thành quyết định đang chờ thay vì tự đoán. Khi resume, triển khai các quyết định user đưa ra trên những phát hiện đã ghi nhận đó với cùng mức độ kỹ lưỡng — sửa đúng root-cause, có test, verify sống, dọn dẹp, thông báo rõ cho user."
argument-hint: "[--until <HH:MM>|<thời-lượng>] [--resume] [gợi ý mảng/role]"
user-invocable: true
when_to_use: "Gọi khi cần một đợt audit mở, có giới hạn thời gian, không có danh sách task cố định ('kiểm tra toàn hệ thống tới sáng', 'rà bug trong lúc tôi vắng', 'test hết mọi role tới X') hoặc để resume và triển khai các quyết định user đưa ra trên những phát hiện đã ghi nhận từ 1 đợt rà soát trước."
metadata:
  author: vyvu
  version: "1.0.0"
---

Bạn đang chạy một vòng lặp rà soát không giám sát, không phải 1 task làm 1 lần xong. Mỗi vòng chọn 1 mảng còn thiếu, dispatch đúng 1 subagent điều tra, triage report của nó, rồi kiểm tra giờ — lặp lại tới khi đạt điều kiện dừng. Một chế độ RESUME riêng (cùng skill, kích hoạt khi user trở lại với quyết định) triển khai các mục đang chờ đã ghi nhận với đầy đủ mức độ kỹ lưỡng kỹ thuật.

═══════════════════════════════════════════════════════
GIAI ĐOẠN 0 — PHẠM VI
═══════════════════════════════════════════════════════

1. Xác định điều kiện dừng từ đúng lời user: 1 mốc giờ tuyệt đối, 1 khoảng thời lượng, hoặc "tới khi tôi bảo dừng". Thật sự mơ hồ → hỏi 1 lần qua `AskUserQuestion`, không bao giờ tự đoán deadline.
2. Liệt kê mọi role/tài khoản đợt rà soát này sẽ cần (đọc seed script/fixture nếu chưa biết sẵn thông tin đăng nhập) — không bao giờ tự bịa ra 1 cái.
3. Ghi lại server/service nào đang chạy sẵn và port của chúng. Skill này KHÔNG BAO GIỜ tự khởi động hay restart server — kể cả khi vừa được cấp phép bằng lời giữa buổi, nếu user (hoặc project memory) đã có quy tắc thường trực cấm việc đó. Bị chặn vì service đang tắt → nói rõ ra và chuyển sang mảng khác thay vì tìm cách lách qua.
4. Xác định cách đọc dữ liệu thật chỉ-đọc (1 DB client, 1 query admin) để verify sau này, và xác nhận các lệnh phá hoại (migration, reset, xoá hàng loạt) nằm ngoài phạm vi cho phép trừ khi user nói khác.
5. Lấy lại phạm vi đã phủ từ project memory / report cũ trước vòng đầu tiên — đừng khám phá lại cái đã đóng rồi.

═══════════════════════════════════════════════════════
GIAI ĐOẠN 1 — CHỌN MẢNG TIẾP THEO (mỗi vòng)
═══════════════════════════════════════════════════════

Xếp hạng ứng viên, giá trị cao nhất trước:
1. Mảng chưa từng được test sống (chỉ đọc code tĩnh, hoặc chưa rà soát lần nào).
2. Role/dữ liệu chưa test lại từ sau fix hoặc thay đổi dữ liệu gần nhất.
3. Một LĂNG KÍNH hệ thống khác áp lên vùng đã "phủ" rồi — ví dụ "route này có đúng guard như các route anh em không," "cổng chặn của UI có khớp với check thật ở backend không" — không chỉ lặp lại cùng 1 lăng kính.
4. Bất cứ gì 1 report trước đã ghi rõ là chưa xác nhận được hoặc bị cắt ngắn vì hết giờ.

Thật sự không chắc mảng nào giá trị cao nhất → bỏ 1 fork nhanh chỉ để tổng hợp bản đồ phạm vi (cái gì đã đóng, cái gì còn mở) trước khi chọn. Rẻ hơn đoán sai rồi làm trùng việc.

═══════════════════════════════════════════════════════
GIAI ĐOẠN 2 — DISPATCH (1 subagent mỗi lần)
═══════════════════════════════════════════════════════

- Đúng 1 agent đang chạy bất cứ khi nào task đụng tới 1 tài nguyên mà chính phiên này cũng đang điều khiển trực tiếp — browser automation là trường hợp phổ biến nhất: 2 agent cùng lái 1 browser sẽ va tab/session và có thể làm sập dev server chung dưới tải gộp. Task chỉ đọc code tĩnh có thể chạy mà không cần ràng buộc này, nhưng mặc định vẫn 1-lần-1-agent trừ khi việc rõ ràng độc lập.
- Mọi prompt dispatch phải tự đủ thông tin — 1 agent mới không nhớ gì từ cuộc trò chuyện này. Luôn kèm:
  - Thông tin đăng nhập/tài khoản chính xác agent cần cho task này.
  - 1 danh sách ngắn "đã xác nhận rồi, đừng khám phá lại" lấy từ các vòng trước.
  - Ràng buộc cứng nguyên văn: không bao giờ khởi động/restart server, không bao giờ chạy migration hay lệnh phá hoại dữ liệu, dừng lại (không retry mù quáng) nếu service sập giữa task.
  - Đường dẫn + quy tắc đặt tên file report chính xác cần ghi vào, và hợp đồng đóng bắt buộc: `Status: DONE | DONE_WITH_CONCERNS | BLOCKED` kèm 1 dòng `Summary`.
- Không poll 1 agent đang chạy bằng các lần chờ ngắn liên tục — 1 lần dispatch đã tự đánh thức lại phiên này khi xong. Chỉ chờ chủ động khi không có gì đang chạy và thứ còn lại chỉ là chờ đồng hồ chạm tới điều kiện dừng.

═══════════════════════════════════════════════════════
GIAI ĐOẠN 3 — TRIAGE (sau khi mỗi report về)
═══════════════════════════════════════════════════════

Đọc đúng file report thật agent đã ghi ra — 1 câu trả lời chat ngắn đôi khi quá nén để mang đủ 1 phát hiện thật, và nó cũng không phải cái tồn tại lâu dài. Xếp mỗi phát hiện vào đúng 1 trong các nhóm:

- **Sửa ngay** — an toàn, đúng root-cause, khớp 1 pattern đã có sẵn ở chỗ khác trong codebase. Mở rộng hoặc thêm 1 test lẽ ra phải fail trước khi có fix, chạy lại nó.
- **Sửa ngay + verify sống** — như trên, nhưng cho bất cứ gì liên quan phân quyền/IDOR: cũng phải chạy thử qua app thật đang sống (không chỉ unit test) theo CẢ 2 chiều — ca bị chặn giờ fail đúng, và ca hợp lệ cùng phạm vi vẫn thành công.
- **Ghi nhận thành quyết định đang chờ** — 1 trade-off fail-open-hay-fail-closed, 1 ranh giới phạm vi, "đây là chủ đích hay là bug." Không bao giờ tự đoán. Ghi lại tình huống tác động cụ thể, root cause, và 2-3 phương án xử lý có tên; vẫn tiếp tục rà mảng khác khi mục này còn mở.
- **Đã biết rồi** — trùng với cái đã sửa hoặc đã ghi nhận. Ghi chú lại, đi tiếp.

1 report trước đó ghi "chưa xác nhận được" hay "không tái hiện được" chính nó cũng là 1 phát hiện thật — mang sự không chắc chắn đó đi tiếp một cách trung thực, đừng lặng lẽ tự kết luận theo hướng nào.

═══════════════════════════════════════════════════════
GIAI ĐOẠN 4 — KỶ LUẬT REGRESSION
═══════════════════════════════════════════════════════

Sau mỗi đợt sửa trực tiếp, và luôn trước khi tổng kết dừng: chạy toàn bộ test suite cộng mọi gate riêng của project (type-check, lint, bất kỳ gate contract/boundary nào project định nghĩa) — không chỉ test của riêng mảng vừa chạm, vì các fix cộng dồn qua nhiều file suốt 1 đợt dài. Để ý riêng 1 lỗi kiểu dữ liệu mà test runner chỉ transpile sẽ không bắt được nhưng gate type-check thật của project sẽ bắt; test xanh không có nghĩa fix đã xong nếu project có 1 gate chặt hơn.

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
2. Gửi đúng 1 bản tổng kết gộp, trực tiếp trong cuộc trò chuyện (không tạo file tổng kết mới trừ khi quy ước riêng của project yêu cầu), gồm: lỗi bảo mật/phân quyền đã sửa, bug chức năng đã sửa, bất kỳ fix tình cờ cho bug có sẵn trong bộ test, phát hiện có nhưng chủ động để mở chờ quyết định (kèm các phương án có tên), và bất cứ gì 1 đợt rà soát đã gắn cờ nhưng không xác nhận được. Theo đúng quy ước report riêng của project nếu có (ngôn ngữ thường, không định danh kỹ thuật, đóng khung theo tình huống) kể cả khi bản thân đợt rà soát mang tính kỹ thuật.
3. Chỉ gửi thông báo cho user nếu có gì cần quyết định hay chú ý khi họ trở lại — không gửi ping "xong việc" thường quy.

═══════════════════════════════════════════════════════
CHẾ ĐỘ RESUME — TRIỂN KHAI CÁC QUYẾT ĐỊNH ĐÃ GHI NHẬN
═══════════════════════════════════════════════════════

Kích hoạt khi user trở lại với câu trả lời ngắn gọn cho các mục đang chờ mà Giai đoạn 3 đã ghi nhận.

1. Khớp mỗi câu trả lời với đúng mục đã ghi nhận theo nội dung, không theo thứ tự giả định; hỏi 1 lần nếu việc khớp thật sự mơ hồ.
2. Với mỗi mục: đọc code HIỆN TẠI thật mới — không bao giờ triển khai từ ký ức của bản ghi cũ. Tái dùng pattern đã có sẵn ở chỗ khác trong codebase cho cùng loại vấn đề; khi cơ chế thẳng đó không áp dụng được (ví dụ 1 field bị mã hoá nên không thể lọc ở tầng database), chọn biến thể tối thiểu cần thiết và để lại comment giải thích trade-off.
3. Mở rộng file/helper test đã có sẵn cho mảng đó (tham số hoá nó, không tạo 1 bản song song trùng lặp) với cả ca regression và 1 ca lẽ ra phải fail trước khi có fix.
4. Verify sống qua app thật theo cả 2 chiều (ca bị chặn giờ bị chặn, ca hợp lệ vẫn hoạt động) trước khi chuyển sang mục tiếp theo.
5. Nếu verify sống ghi ra hàng dữ liệu thật vào 1 dataset chung/dev, chạy lại toàn bộ suite sau đó — 1 test cùng môi trường có thể assert đúng số liệu sống. Bị vỡ vì việc đó → chỉ xoá ĐÚNG các hàng đợt này tạo ra, không bao giờ đụng cái có từ trước, rồi xác nhận lại xanh.
6. Lần theo mọi đường lỗi mới tới đúng thông báo hiển thị cho user, không chỉ dừng ở code backend — kiểm tra tầng response/serialization thật, vì chuỗi thông báo cho người đọc thường không phải cái được trả nguyên văn. Thay thông báo chung chung bằng 1 thông báo riêng cho ca mới, khớp với cách các ca anh em đã xử lý trong cùng component đó; để ý tránh hiện 2 toast/thông báo trùng khi cả callback lẫn 1 check tay riêng sau cùng lệnh gọi đều có thể cùng bắn cho 1 lỗi.
7. Lượt cuối khi mọi mục xong: lint/format cộng toàn bộ regression suite trên mọi thứ đã chạm, trước khi báo xong.

═══════════════════════════════════════════════════════
QUY TẮC CỨNG
═══════════════════════════════════════════════════════

- Không bao giờ tự khởi động, restart, hay tự khôi phục 1 server/service — báo rõ điểm bị chặn và tiếp tục rà mảng khác.
- Không bao giờ chạy migration, reset, hay lệnh phá hoại dữ liệu hàng loạt mà không có user yêu cầu đích danh.
- Không bao giờ chạy 2 agent cùng lúc lên cùng 1 tài nguyên sống dùng chung (browser session, khoá độc quyền).
- Không bao giờ tin riêng câu trả lời chat của 1 subagent cho bất cứ gì liên quan phân quyền — mở file report nó đã ghi ra.
- Không bao giờ tự âm thầm giải quyết 1 quyết định đang chờ đã ghi nhận — chỉ câu trả lời của chính user mới đóng được nó.
- Không bao giờ để các thay đổi cộng dồn của 1 đợt dài bỏ qua 1 lượt regression đầy đủ cuối cùng.

═══════════════════════════════════════════════════════
BƯỚC TIẾP THEO
═══════════════════════════════════════════════════════

Nhìn vào cái đợt rà soát này thực sự tìm ra và đã sửa, rồi gợi ý ĐÚNG 1 hành động tiếp theo hợp lý trong 1-2 câu — đừng chọn từ 1 danh sách cố định. 1 lượt `vreview` trên mọi thứ đã chạm, hay `vci` để kiểm tra typecheck/build lần cuối, là 2 lựa chọn hay gặp nếu không có gì khác nổi bật hơn.
