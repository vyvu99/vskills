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
7. **Ảnh phải vừa một trang khi in.** Chụp phần màn hình đang thấy hoặc một vùng đã cắt, không chụp cả trang cuộn dài. Ảnh máy tính cao tối đa bằng chiều rộng; ảnh điện thoại cao tối đa khoảng 2,2 lần chiều rộng. Màn dài hơn thì cắt quanh phần bước đó dùng, hoặc tách thành hai ảnh. Nhúng mỗi ảnh với chiều rộng rõ ràng để một ảnh nằm gọn một trang: `<img src="..." alt="..." width="560">` cho ảnh máy tính và ảnh vuông, `width="280"` cho ảnh điện thoại. Không để một ảnh bị cắt sang hai trang.
8. **Ảnh kể cùng một câu chuyện với chữ.** Một bộ dữ liệu thử chạy xuyên mọi ảnh của một vai (cùng người dùng, bản ghi, mã, ngày), nên mã hay tên ở ảnh này xuất hiện nguyên vẹn ở ảnh sau và khớp với chữ của bước. Mỗi bước có thao tác đều có ảnh riêng thể hiện đúng thao tác đó, theo thứ tự bước. Mỗi ảnh có khung đỏ bao đúng thứ bước yêu cầu người đọc dùng hay bấm (mỗi đích một khung, không khung gì khác), và khung được vẽ ngay trên trang trước khi chụp, không vẽ tay sau. Trước khi chụp, tạo dữ liệu bước đó cần qua chính sản phẩm để khung nằm trên nội dung thật, không phải màn trống.

## Bước 4 - Viết hướng dẫn

1. **Tiêu đề** và một câu mở đầu trang trọng: hướng dẫn nói về gì, dành cho những vai nào.
2. **Giới thiệu chung**: mục đích; bảng thuật ngữ ngắn; khi luồng có nhiều chặng thì có bảng (chặng, nội dung, vai thực hiện) kèm sơ đồ luồng nhỏ; một trường hợp minh họa ngắn ở ngôi thứ ba; cách truy cập sản phẩm (tài khoản, đăng nhập, điều hướng chính nằm đâu, chữ trong backtick nghĩa là gì).
3. **Mỗi vai một phần**: đoạn ngắn về vai (làm gì, thấy gì, không thấy gì), các bước đánh số, rồi danh sách "cần nhớ".
4. **Mỗi bước** có tiêu đề (`Bước N`), một câu nói làm gì và để làm gì, tên chính xác cần dùng, sản phẩm làm gì tiếp theo, và ảnh ngay bên dưới.
5. Thông tin an toàn hay tuân thủ người đọc không được bỏ sót (đầu mối khẩn cấp, thao tác không hoàn tác được, xử lý dữ liệu) đặt ở phần của vai gặp tình huống đó.

## Bước 5 - Giữ cho dễ đọc

Hướng dẫn dài được đọc bằng cách tra cứu, không đọc từ đầu đến cuối. Áp dụng trước khi viết, rồi kiểm lại ở Bước 7.

1. **Bảng tra nhanh** ngay sau tiêu đề: các dòng "Tôi muốn ..." kèm vai, phần và bước trả lời, rồi mục lục. Người đọc tới được việc của mình trong một lần nhìn.
2. **Nhóm các bước** của mỗi vai dưới tiêu đề việc ngắn (ví dụ "Gửi yêu cầu", "Theo dõi") thay vì một danh sách phẳng 15 bước trở lên. Giữ số bước liên tục để các chỗ tham chiếu vẫn đúng.
3. **Mỗi bước một ý.** Bước gồm một dòng mục đích, các thao tác đánh số, rồi ảnh. Đoạn dài quá khoảng năm dòng thì tách thành thao tác hoặc chuyển vào bảng.
4. **Bảng cho dữ liệu tra cứu**: danh sách trường, lựa chọn, trạng thái, giới hạn, thời hạn đặt trong bảng (tên, ý nghĩa, ghi chú), không nhồi vào một câu nhiều dấu phẩy.
5. **Mỗi điều nói một lần.** Điều lặp ở nhiều bước hay nhiều vai (số khẩn cấp, giới hạn, ai không làm được gì) chỉ nêu ở một chỗ, các chỗ khác trỏ tới. Bước hai vai dùng chung viết một lần, vai kia chỉ trỏ bằng một dòng và nêu riêng phần khác biệt.
6. **Đặt sơ đồ đúng chỗ dùng**: sơ đồ luồng của vai nào mở đầu phần của vai đó, không gom hết trước phần giới thiệu.
7. **"Cần nhớ" ngắn**: chỉ những điều người đọc dễ bỏ sót, tối đa khoảng bảy dòng mỗi vai, không lặp điều đã có trong bước.
8. **Kiểm độ dài**: nếu sau các quy tắc trên phần của một vai vẫn vượt khoảng 300 dòng hoặc 15 bước, đề nghị user tách thành một tệp cho mỗi vai kèm một tệp mục lục chung; không tự tách khi chưa có câu trả lời.
9. **Đi thẳng vào trọng tâm.** Tiêu đề bước là một hành động; dòng đầu nói cần làm gì. Bỏ phần tả màn hình trông ra sao và mọi nhãn, trạng thái, lựa chọn mà người đọc không phải chọn hay thao tác. Chỉ liệt kê lựa chọn cần quyết định. Trường hợp hiếm thì thành một dòng ở "cần nhớ" hoặc bỏ.
10. **Hạn mức chữ.** Một bước có tối đa khoảng 60 từ ngoài bảng và danh sách. Phần giới thiệu, bảng thuật ngữ, tình huống minh hoạ mỗi phần vượt một màn hình thì cắt còn đúng thuật ngữ và điều các bước thực sự dùng.

## Bước 6 - Giọng văn và nội dung

- Văn phong hành chính, trang trọng, không xưng hô ngôi thứ hai, không từ thân mật, không câu mệnh lệnh kiểu "cứ", "đừng lo", "nhớ".
- Từ ngữ giản dị. Mỗi thuật ngữ giải thích một lần trong bảng thuật ngữ. Không dùng tên nội bộ (giá trị enum, tên hàm, đường dẫn tệp, tên bảng, số ticket).
- Mô tả việc người dùng làm và nhận được, không mô tả màn hình xây thế nào: không màu, hình dạng, kiểu thành phần, bố cục, cách cuộn hay thu gọn, phím tắt, tooltip.
- Không code hay định danh kỹ thuật, không lịch sử phiên bản, không "nay hoạt động như...".
- Không có mục về lỗi và không có ảnh lỗi. Hướng dẫn chỉ nêu cách làm đúng.
- Không ngôn ngữ changelog: "đã thêm", "đã sửa", "đổi thành", "trước đây".
- Không nói hướng dẫn dành cho người ở trình độ hay hiểu biết nào.

## Bước 7 - Kiểm tra rồi bàn giao

1. Tìm trong văn bản các nội dung bị cấm: vai đã bỏ, từ thân mật, ngôi thứ hai, từ về màu/bố cục/thành phần, đường dẫn tệp, thông tin đăng nhập.
2. Kiểm mọi đường dẫn ảnh tồn tại và mỗi bước có ảnh khi có ảnh.
3. Kiểm Bước 5: có bảng tra nhanh, các bước đã nhóm, không đoạn nào quá khoảng năm dòng, không điều nào lặp ở hai chỗ, mỗi sơ đồ nằm trong phần của vai. Kiểm kích thước ảnh: không ảnh nào cao quá tỷ lệ ở Bước 3, mọi ảnh đều có chiều rộng. Kiểm không bước nào vượt hạn mức chữ.
4. Kiểm mọi khẳng định về ai làm được gì với nguồn sự thật ở Bước 1.
5. Mở tệp cho user và đưa đường dẫn. Báo đã kiểm gì và chưa kiểm gì (ví dụ ảnh chụp ở vai khác).

## Quy tắc

- Không bịa bước, nút, lệnh hay giới hạn. Điều gì không xác nhận được từ sản phẩm thì bỏ ra và nói trong bàn giao.
- Không đảo quyết định user đã chốt về vai, thứ tự hay câu chữ.
- Giữ nguyên bản cũ khi viết bản mới; ghi bản mới cạnh bản cũ với hậu tố phiên bản.
