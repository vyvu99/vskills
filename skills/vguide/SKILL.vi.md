---
name: vguide
description: "Viết tài liệu hướng dẫn sử dụng trang trọng cho bất kỳ sản phẩm, tính năng hay luồng nào (web, mobile, desktop, CLI, công cụ nội bộ): chia theo vai người dùng, bước đánh số, mỗi bước có giải thích, có ảnh chụp khi sản phẩm có màn hình. Xác minh ai làm được gì từ code hoặc sản phẩm thật, rồi kiểm văn bản với danh sách nội dung bị cấm. Kết quả là tệp Markdown hướng dẫn, không bao giờ là báo cáo đã làm gì."
user-invocable: true
when_to_use: "Dùng khi user muốn tài liệu hướng dẫn sử dụng cho người vận hành một sản phẩm hay tính năng, hoặc bản sửa của nó (ít vai hơn, phạm vi khác, ngôn ngữ khác). Không dùng cho release notes, changelog, báo cáo 'đã làm, đã sửa gì', specs (đó là vspecs) hay tài liệu cho lập trình viên."
argument-hint: "[sản phẩm, tính năng hoặc luồng] [các vai hoặc đối tượng cần có] [hướng dẫn có sẵn cần sửa]"
metadata:
  author: vyvu
  version: "1.1.0"
---

# Tài liệu hướng dẫn sử dụng

Đọc đầu vào:

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` trống, hỏi bằng `AskUserQuestion`: sản phẩm, tính năng hay luồng nào; gồm những vai nào; có phải bản sửa của hướng dẫn có sẵn không; đặt tệp ở đâu nếu dự án chưa có quy ước tài liệu.

**Phạm vi:** skill này chỉ ghi một tệp Markdown hướng dẫn và các ảnh nó nhúng. Không sửa mã nguồn, không dẫn liên kết tới hướng dẫn từ code, comment hay mô tả PR.

**Nơi ghi tệp:** theo chỉ định của user; nếu không có thì theo quy ước tài liệu hoặc báo cáo sẵn có của dự án; nếu cũng không có thì `guides/<guide-slug>/guide.md`, ảnh trong `guides/<guide-slug>/images/`. Viết bằng ngôn ngữ của user.

## Tài liệu này là gì

**Hướng dẫn sử dụng mà người đọc tự làm theo được**, đủ chỉn chu để đưa cho cấp trên, khách hàng hay cơ quan quản lý. Nói mỗi loại người dùng làm được gì, theo thứ tự nào, làm xong thì chuyện gì xảy ra. Đây không phải:

- báo cáo đã xây gì, đổi gì, sửa gì;
- mô tả sản phẩm trông ra sao hay được xây thế nào;
- lời nói về người đọc hay người viết ("tài liệu này viết cho người mới").

Khi user nói "đây không phải báo cáo đã làm gì", bỏ mọi câu nói về công việc đã làm, không chỉ bỏ tiêu đề.

## Bước 1 - Chốt phạm vi

1. Liệt kê các vai (hoặc nhóm người dùng) của sản phẩm. Kiểm theo nguồn sự thật, không dựa vào hướng dẫn cũ: quy tắc truy cập trong code, bảng phân quyền, menu, tài khoản seed hoặc demo, hoặc chính sản phẩm đang chạy nếu không có code.
2. Chỉ giữ các vai user yêu cầu. Bản sửa bỏ bớt vai thì bỏ nguyên phần của vai đó, đánh lại số, và xóa mọi chỗ nhắc tới vai đó (bảng, ghi chú, dòng "ai xem gì").
3. Có hướng dẫn cũ thì dùng làm nền. Giữ các bước và lời giải thích, chỉ đổi đúng phần user yêu cầu.

## Bước 2 - Thu thập sự thật

1. Với từng vai, tìm xem vai đó mở, tạo, sửa hay chỉ xem được gì, và không thấy gì. Chỉ viết điều sản phẩm cho phép.
2. Ghi đúng chữ trên màn hình hay trên dòng lệnh của menu, nút, tab, lựa chọn, lệnh, thông báo. Viết trong dấu backtick đúng như hiển thị.
3. Gom các giới hạn người đọc cần biết: ai thấy dữ liệu nào, điều gì được giữ kín, điều gì hết hạn hay chỉ dùng một lần.

## Bước 3 - Chụp ảnh (khi sản phẩm có màn hình)

1. Dùng bản local, demo hoặc staging có dữ liệu thử. Tài khoản thử lấy từ tệp seed hoặc tệp ví dụ của dự án; không ghi mật khẩu vào hướng dẫn, tin nhắn, ghi chú hay commit.
2. Chụp màn hình của mỗi vai khi đang đăng nhập đúng vai đó. Ảnh chụp ở vai khác có menu khác; ghi chú lại nếu không tránh được.
3. Khi cập nhật hướng dẫn có sẵn, chỉ chụp lại màn hình đã đổi.
4. Đặt tên tệp theo vai và bước (`<vai>-<nn>-<chủ đề>.jpg`). Kiểm mọi tệp được nhắc tới đều tồn tại.
5. Không chụp màn hình lỗi, thông báo lỗi, trang đang tải dở. Chờ trang tải xong.
6. Sản phẩm không có màn hình (CLI, API) dùng khối lệnh và kết quả ngắn thay cho ảnh.

## Bước 4 - Viết hướng dẫn

1. **Tiêu đề** và một câu mở đầu trang trọng: hướng dẫn nói về gì, dành cho những vai nào.
2. **Giới thiệu chung**: mục đích; bảng thuật ngữ ngắn; khi luồng có nhiều chặng thì có bảng (chặng, nội dung, vai thực hiện) kèm sơ đồ luồng nhỏ; một trường hợp minh họa ngắn ở ngôi thứ ba; cách truy cập sản phẩm (tài khoản, đăng nhập, điều hướng chính nằm đâu, chữ trong backtick nghĩa là gì).
3. **Mỗi vai một phần**: đoạn ngắn về vai (làm gì, thấy gì, không thấy gì), các bước đánh số, rồi danh sách "cần nhớ".
4. **Mỗi bước** có tiêu đề (`Bước N`), một câu nói làm gì và để làm gì, tên chính xác cần dùng, sản phẩm làm gì tiếp theo, và ảnh ngay bên dưới.
5. Thông tin an toàn hay tuân thủ người đọc không được bỏ sót (đầu mối khẩn cấp, thao tác không hoàn tác được, xử lý dữ liệu) đặt ở phần của vai gặp tình huống đó.

## Bước 5 - Giọng văn và nội dung

- Văn phong hành chính, trang trọng, không xưng hô ngôi thứ hai, không từ thân mật, không câu mệnh lệnh kiểu "cứ", "đừng lo", "nhớ".
- Từ ngữ giản dị. Mỗi thuật ngữ giải thích một lần trong bảng thuật ngữ. Không dùng tên nội bộ (giá trị enum, tên hàm, đường dẫn tệp, tên bảng, số ticket).
- Mô tả việc người dùng làm và nhận được, không mô tả màn hình xây thế nào: không màu, hình dạng, kiểu thành phần, bố cục, cách cuộn hay thu gọn, phím tắt, tooltip.
- Không code hay định danh kỹ thuật, không lịch sử phiên bản, không "nay hoạt động như...".
- Không có mục về lỗi và không có ảnh lỗi. Hướng dẫn chỉ nêu cách làm đúng.
- Không ngôn ngữ changelog: "đã thêm", "đã sửa", "đổi thành", "trước đây".
- Không nói hướng dẫn dành cho người ở trình độ hay hiểu biết nào.

## Bước 6 - Kiểm tra rồi bàn giao

1. Tìm trong văn bản các nội dung bị cấm: vai đã bỏ, từ thân mật, ngôi thứ hai, từ về màu/bố cục/thành phần, đường dẫn tệp, thông tin đăng nhập.
2. Kiểm mọi đường dẫn ảnh tồn tại và mỗi bước có ảnh khi có ảnh.
3. Kiểm mọi khẳng định về ai làm được gì với nguồn sự thật ở Bước 1.
4. Mở tệp cho user và đưa đường dẫn. Báo đã kiểm gì và chưa kiểm gì (ví dụ ảnh chụp ở vai khác).

## Quy tắc

- Không bịa bước, nút, lệnh hay giới hạn. Điều gì không xác nhận được từ sản phẩm thì bỏ ra và nói trong bàn giao.
- Không đảo quyết định user đã chốt về vai, thứ tự hay câu chữ.
- Giữ nguyên bản cũ khi viết bản mới; ghi bản mới cạnh bản cũ với hậu tố phiên bản.
