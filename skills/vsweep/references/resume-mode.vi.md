# Chế độ resume: implement các quyết định đã ghi

Dùng khi user quay lại với những câu trả lời ngắn cho các mục chờ quyết định mà một lượt quét đã ghi. Các bước viết cho code. Với loại việc khác, giữ nguyên ý định (đọc mới trạng thái hiện tại, cùng pattern với các mục anh em, một check fail trước và pass sau, kiểm chứng thật, kiểm lại toàn bộ lần cuối) và đổi công cụ. Phạm vi là các mục đã ghi mà user đã trả lời, không gì khác.

1. Khớp mỗi câu trả lời với mục đã ghi theo nội dung, không theo thứ tự giả định. Hỏi một lần nếu việc ghép thật sự mơ hồ.
2. Với mỗi mục, đọc code hiện tại mới; bản ghi trước có thể đã cũ. Dùng lại pattern có sẵn cho cùng loại vấn đề. Nếu cơ chế thẳng không áp dụng được (ví dụ một field bị mã hóa nên không thể là filter ở tầng database), dùng biến thể tối thiểu và để comment giải thích đánh đổi.
3. Mở rộng file test hay helper có sẵn cho vùng đó (parametrize, đừng thêm cái song song) với ca hồi quy và một ca lẽ ra fail trước thay đổi.
4. Kiểm chứng đầu-cuối (app thật, build, preview, thứ gì chứng minh được) theo hai chiều trước khi sang mục kế tiếp.
5. Nếu việc kiểm chứng ghi dòng vào dataset dùng chung hoặc dev, chạy lại full suite, vì test cùng môi trường có thể assert đúng số lượng live. Nếu nó bị hỏng vì vậy, chỉ xóa đúng các dòng lượt này tạo ra, không bao giờ xóa thứ cũ hơn, rồi xác nhận lại xanh.
6. Lần theo mỗi đường lỗi mới tới thông điệp user thực sự thấy, qua tầng response thật, vì chuỗi cho người thường không phải lúc nào cũng là thứ backend trả nguyên văn. Thay thông báo chung chung bằng thông báo riêng cho ca mới, nhất quán với các ca anh em, và coi chừng toast bị lặp khi cả callback lẫn một check thủ công riêng cùng bắn cho một lỗi.
7. Khi xong mọi mục, chạy lint và format cùng full regression suite trên mọi thứ đã đụng tới trước khi báo xong. Gate nào không chạy được thì nói rõ.
