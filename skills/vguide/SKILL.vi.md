---
name: vguide
description: "Viết tài liệu hướng dẫn dẫn người chưa biết gì về sản phẩm đi từ bức tranh toàn cảnh tới từng bước: vì sao có bước đó, nó dựa vào đâu, trước và sau nó là gì, mỗi bước có ảnh, và ai (vai vận hành nào) làm. Mỗi đối tượng đọc một tài liệu, chia vai vận hành ngay cả khi sản phẩm có ít vai tài khoản hơn. Viết bằng văn xuôi ngắn, liền mạch, không viết kiểu biểu mẫu hay dòng có nhãn. Xác minh ai làm được gì từ code hoặc sản phẩm thật, cho người đọc thử không biết gì, rồi kiểm văn bản với danh sách nội dung bị cấm. Kết quả là tệp Markdown hướng dẫn, không bao giờ là báo cáo đã làm gì."
user-invocable: true
when_to_use: "Dùng khi user muốn tài liệu hướng dẫn sử dụng, sổ tay hay hướng dẫn từng bước cho người vận hành một sản phẩm hay tính năng, hoặc bản sửa của nó (ít tài liệu hơn, vai khác, ngôn ngữ khác, rõ lý do hơn). Không dùng cho release notes, changelog, báo cáo 'đã làm, đã sửa gì', specs (đó là vspecs) hay tài liệu cho lập trình viên."
argument-hint: "[sản phẩm, tính năng hoặc luồng] [các đối tượng và vai vận hành cần có] [hướng dẫn có sẵn cần sửa]"
metadata:
  author: vyvu
  version: "1.7.0"
---

# Tài liệu hướng dẫn sử dụng

Đọc đầu vào:

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` trống, hỏi bằng `AskUserQuestion`: sản phẩm, tính năng hay luồng nào; đối tượng nào và trong mỗi đối tượng có những vai vận hành nào; có phải bản sửa của hướng dẫn cũ không; tệp để ở đâu nếu dự án chưa có quy ước tài liệu.

**Phạm vi:** skill này viết các tệp hướng dẫn và ảnh chúng nhúng. Không bao giờ sửa mã nguồn, không dẫn tới hướng dẫn từ code, comment hay mô tả PR.

**Nơi để kết quả:** theo user nói; nếu không thì theo quy ước tài liệu hay báo cáo của dự án; nếu không có thì `guides/<slug-hướng-dẫn>/`. Viết bằng ngôn ngữ của user.

## Hướng dẫn là gì

Một hướng dẫn mà người đọc làm theo được **không cần ai giúp và không cần biết trước sản phẩm**. Một bước không bao giờ chỉ là "bấm X". Nó nói vì sao bước đó có, nó dựa vào đâu (quy định, luật, quyết định của trường hay công ty, lý do nghiệp vụ), người đọc vừa làm xong gì và tiếp theo sẽ ra sao. Đọc như có người đi cùng giảng giải, một mạch từ đầu đến cuối.

Nó không phải:

- bảng tra cứu cho người đã biết sản phẩm (đặt một bảng tra ngắn bên trong hướng dẫn, không bao giờ thay cho phần đi từng bước);
- báo cáo về điều đã xây, đã đổi hay đã sửa;
- mô tả màn hình trông ra sao hay sản phẩm được xây thế nào.

Thử từng đoạn với người đọc chưa biết gì: "tại sao tôi làm việc này, tại sao cần cái này, chữ này là gì, xong thì sao?". Nếu chữ không trả lời được thì chưa xong.

## Bước 1 - Chốt phạm vi

1. **Mỗi đối tượng một hướng dẫn, không phải mỗi chủ đề một tệp.** User có hai đối tượng thì nhận đúng hai hướng dẫn (ví dụ một cho giáo viên, một cho chuyên gia). Tờ tra nhanh, thẻ khẩn cấp, bảng thuật ngữ, bảng tra cứu, lịch đào tạo và phụ lục nằm **bên trong** hướng dẫn của đối tượng đó, thành phần hoặc trang cuối. Không rải tài liệu của một đối tượng ra nhiều tệp. Tài liệu chỉ cho người tổ chức (việc khách hàng phải quyết, ghi chú nội bộ) đi vào một ghi chú nội bộ riêng, không đưa vào hướng dẫn.
2. **Liệt kê vai vận hành, không chỉ vai tài khoản.** Xác minh từ nguồn thật (quy tắc truy cập trong code, bảng quyền, menu, tài khoản seed hay demo) sản phẩm có những vai nào. Rồi liệt kê vai người ta thực sự đóng ở nơi khách hàng (ví dụ giáo viên chủ nhiệm và giáo viên bộ môn; chuyên gia chính và chuyên gia phụ). Khi sản phẩm có ít vai hơn cách khách hàng làm việc, vẫn chia hướng dẫn theo vai vận hành và nói thẳng phần nào là sự thật của sản phẩm, phần nào là quy ước đề xuất để khách hàng xác nhận (đánh dấu để họ xác nhận). Không bịa tính năng sản phẩm cho khớp vai vận hành.
3. Chỉ giữ đối tượng và vai user yêu cầu. Bản sửa bỏ một vai thì bỏ nguyên phần của vai đó, đánh số lại, và bỏ mọi nhắc tới ở chỗ khác.
4. Dùng hướng dẫn cũ làm nền sự thật khi có, nhưng kiểm lại từng khẳng định với nguồn; hướng dẫn cũ có thể lỗi thời hoặc sai. Giữ nguyên bản cũ và ghi bản mới cạnh nó với hậu tố.

## Bước 2 - Thu thập sự thật

1. Với mỗi vai vận hành, tìm xem nó mở, tạo, sửa, chỉ xem được gì và không bao giờ thấy gì. Tách ba loại việc: **trong sản phẩm**, **người làm trực tiếp ngoài sản phẩm** (gọi điện, ký, họp, đứng cạnh ai đó), và **vai này không làm**. Kiểm từng khẳng định trong code hoặc sản phẩm thật. Bước chỉ đọc hay ghi lại điều gì đó trong sản phẩm là việc trong sản phẩm, dù người làm bằng phán đoán.
2. Kiểm mọi khẳng định về sự vắng mặt ("hệ thống không đếm, không nhắc, không báo, không tự theo dõi, không cho X thấy Y") bằng cách tìm trong nguồn. Chỉ nêu sự vắng mặt sau khi đã tìm. Tính năng âm thầm lo một việc (nhắc tự động, trường ẩn, cổng cho người ngoài) là nguồn thường gặp của khẳng định vắng mặt sai.
3. Ghi chữ chính xác trên màn hình của menu, nút, tab, lựa chọn, thông báo. Viết trong backtick đúng như hiển thị.
4. Thu các giới hạn người đọc phải biết: ai thấy dữ liệu nào, điều gì giữ riêng tư, điều gì hết hạn hay dùng một lần, thời hạn và ai đặt.
5. Thu **căn cứ** cho từng bước: quy định, luật, thỏa thuận làm cho bước đó cần thiết. Nêu bằng lời thường ngay trong bước; tham chiếu chính xác (tài liệu, mục, trang) gom vào một bảng "Căn cứ" ở cuối.

## Bước 3 - Hình ảnh

Mọi bước đều có ảnh. Người đọc chưa biết gì cần thấy màn hình, và bước không có ảnh là lời phàn nàn thường gặp nhất.

1. Dùng bản local, demo hay staging với dữ liệu thử. Lấy thông tin đăng nhập thử từ tệp seed hay mẫu của dự án; không bao giờ ghi mật khẩu vào hướng dẫn, chat, ghi chú hay commit. Khi dữ liệu demo không khớp bối cảnh thật của khách hàng (cấp học, tên lớp, tên công ty), chỉnh dữ liệu demo theo cách hoàn tác được (ghi lại giá trị gốc, kèm cách hoàn tác) để ảnh khớp thế giới của khách hàng.
2. Chụp màn hình của từng vai khi đăng nhập đúng vai đó. Một bộ dữ liệu thử chạy xuyên mọi ảnh của một vai: cùng người, bản ghi, mã, ngày, để tên ở ảnh này xuất hiện nguyên vẹn ở ảnh sau và khớp với ví dụ xuyên suốt trong chữ.
3. Mỗi bước có thao tác có ảnh riêng theo thứ tự bước. Mỗi ảnh có khung đỏ bao đúng thứ bước yêu cầu dùng (mỗi đích một khung, không khung gì khác), khung vẽ ngay trên trang trước khi chụp, không vẽ tay sau. Cạnh mỗi khung có huy hiệu số theo thứ tự thao tác và tối đa khoảng sáu từ nêu việc, vẽ ngay trên trang, tương phản cao, đủ lớn ở chiều rộng khi in (khoảng 11 px trở lên khi ảnh hiển thị 560 px; 280 px với ảnh điện thoại), không che phần nó chỉ tới hay điều khiển bên cạnh, không chứa dữ liệu cá nhân.
4. Ảnh phải vừa một trang khi in: ảnh máy tính cao tối đa bằng chiều rộng; ảnh điện thoại cao tối đa khoảng 2,2 lần chiều rộng. Nhúng với chiều rộng rõ ràng: `<img src="..." alt="..." width="560">` cho ảnh máy tính, `width="280"` cho ảnh điện thoại. Đặt tên tệp theo vai và bước (`<vai>-<nn>-<chủ-đề>.jpg`). Kiểm mọi tệp được dẫn tới đều tồn tại.
5. Trước khi chụp, tạo dữ liệu bước đó cần qua chính sản phẩm để khung nằm trên nội dung thật, không phải màn trống. Không ảnh lỗi, không trang tải dở. Không chụp trạng thái mâu thuẫn với thứ tự câu chuyện (ví dụ một bản ghi đã xong ở bước đứng trước bước làm xong nó).
6. **Sơ đồ tổng quan.** Làm ba hay bốn ảnh sơ đồ (HTML tĩnh chụp ra PNG rộng 1440 px, đọc được ở 560 px): đường đi của một trường hợp qua cả quy trình, ai làm gì và vì sao; tình huống khẩn cấp trong ba bước; ai thấy và làm gì theo từng vai vận hành; lịch khi hướng dẫn có lộ trình học. Vẽ từ sự thật đã kiểm, không vẽ từ trí nhớ.
7. Bước chưa có ảnh mang dòng ẩn `<!--ANH-THIEU: cần chụp gì-->` ngay sau nó; mọi dòng này phải được thay trước khi giao. Bước chỉ do người làm trực tiếp ngoài sản phẩm mang `<!--KHONG-ANH-->`.
8. Sản phẩm không có màn hình (CLI, API) dùng khối lệnh và kết quả ngắn thay cho ảnh.

## Bước 4 - Viết hướng dẫn

Cấu trúc của một hướng dẫn:

1. **Tiêu đề** và một câu mở đầu.
2. **Đọc trong 1 phút**: sản phẩm là gì và để làm gì (ba câu), người đọc sẽ làm những việc nào (ba hay bốn gạch), điều gấp nhất là gì và ở đâu.
3. **Bảng tra nhanh** ("Tôi muốn ..." kèm vai vận hành, phần và bước), việc gấp nhất đứng đầu.
4. **Bức tranh toàn cảnh** (phần 1): sơ đồ tổng quan, đường đi kể bằng lời thường, vì sao vai của người đọc đứng ở chỗ đó, từng chữ người đọc sẽ gặp nghĩa là gì (mỗi chữ một dòng, giải thích ngay lần đầu gặp; bảng thuật ngữ ngắn ở cuối chỉ để tra lại), **ví dụ xuyên suốt** (một người hay một trường hợp giả dùng ở mọi phần và khớp với ảnh), và bảng "ai làm bước nào" theo vai vận hành.
5. **Phần các vai vận hành:** mỗi vai một đoạn ngắn bằng văn xuôi: vai đó là gì trong sản phẩm và trong thực tế, thấy gì, làm gì trong sản phẩm, làm gì trực tiếp, không làm gì, và việc đầu tiên khi nhận vai. Nói rõ phần nào là sự thật của sản phẩm, phần nào là thỏa thuận đề xuất cần xác nhận.
6. **Tình huống khẩn cấp** ngay sau bức tranh toàn cảnh, không chôn ở giữa.
7. **Các chặng** theo đúng thứ tự công việc thật. Mỗi chặng mở bằng một đoạn ngắn bằng câu thường: chặng nằm ở đâu trên đường đi (chỉ vào sơ đồ), vì sao tổ chức có chặng này, và xong chặng thì người đọc có gì trong tay. Không khuôn ba dòng, không dòng có nhãn.
8. **Mỗi bước** (`**Bước N. Tiêu đề là một hành động.**`) là một đoạn văn xuôi ngắn liền mạch, ba tới năm câu, viết như đồng nghiệp giảng giải bằng lời. Đoạn văn mang mạch mà không cần nhãn: bắt đầu từ điều người đọc vừa làm xong và còn thiếu gì, nói vì sao cần bước này và nó dựa vào quy định hay thỏa thuận nào, nói làm gì và khi cần thì mỗi nút để làm gì, rồi kết bằng việc sản phẩm làm tiếp và ai nhận việc. Vai vận hành làm bước được nêu ngay trong câu đầu ("Giáo viên chủ nhiệm mở ..."); bước chia giữa các vai thì câu nói rõ điều đó. Ảnh đứng sau đoạn văn. Chữ không lặp lại các cú bấm đã có số trong ảnh.
9. **Hỏi đáp "Tại sao?"** gần cuối: tám tới mười câu người mới chắc chắn thắc mắc, mỗi câu là một câu hỏi in đậm theo sau là câu trả lời hai tới bốn câu bằng văn xuôi kèm căn cứ. Không tiền tố "H:" hay "Đ:".
10. **Bảng thuật ngữ**, **Điều tổ chức còn phải xác nhận** (một bảng, mỗi điểm một lần), **Căn cứ** (bảng: khẳng định, quy định hay tài liệu, mục hoặc trang), và khi hướng dẫn gồm đào tạo thì có **Lộ trình học** ngắn cho vai (vì sao học theo buổi ngắn, sơ đồ lịch, bảng các buổi kèm điều người học làm được sau buổi).
11. Tài liệu in người đọc cần để sẵn tay (thẻ khẩn cấp) là trang cuối của hướng dẫn.

## Bước 5 - Giữ cho dễ đọc

1. **Mỗi điều nói một lần** ở chỗ cần nó đầu tiên rồi trỏ tới; nhưng điều người đọc cần ngay lúc gấp thì nhắc lại đúng chỗ lúc gấp đó xảy ra.
2. **Nhóm các bước** dưới tiêu đề chặng; giữ số bước liên tục để các chỗ tham chiếu vẫn đúng.
3. **Mỗi bước một ý.** Đoạn dài quá khoảng năm dòng thì tách. Bảng dùng cho dữ liệu tra cứu (trường, lựa chọn, trạng thái, giới hạn, thời hạn).
4. **Ngắn và rõ.** Một bước khoảng năm mươi tới chín mươi từ. Hiểu được nhờ thứ tự câu rõ ràng chứ không nhờ dài: bỏ mọi thứ không giúp người đọc làm hay hiểu, và chuyển chi tiết tra cứu vào bảng.
5. **Đặt sơ đồ đúng chỗ dùng** và trỏ lại ở đầu mỗi chặng.
6. **Kiểm độ dài:** nhắm tới hướng dẫn một người đọc xong trong một lần ngồi. Khi một hướng dẫn vượt khoảng ba mươi trang in, cắt chữ trước (lặp, giải thích dài), rồi đề nghị chuyển phần tra cứu xuống cuối; không tạo thêm tệp khi chưa có câu trả lời của user.
7. **Văn xuôi, không biểu mẫu.** Không viết dòng dạng `Nhãn: nội dung` hay câu dẫn in nghiêng (Vì sao:, Làm gì:, Xong thì:, Ai làm:, Đến lúc này:) để tổ chức một bước, một chặng hay một khối vai. Khối vai cũng là đoạn văn ngắn. In đậm chỉ dành cho tiêu đề bước và câu hỏi. Bảng chỉ để tra cứu, không để chia nhỏ một câu chuyện.
8. Giải thích mỗi chữ lạ ngay lần đầu xuất hiện, trong một câu ngay cạnh.
9. **Viết như sổ tay quy trình chuyên nghiệp, không kể chuyện.** Không nhân vật có tên, không ví dụ tình huống bịa, không chia cảnh. Thứ tự: mục đích và đối tượng đọc; các vai và việc mỗi vai được làm; cần chuẩn bị gì trước khi bắt đầu; mỗi tác vụ một quy trình đánh số theo đúng thứ tự thật, mỗi bước là một hành động trong sản phẩm kèm kết quả người đọc phải thấy, và nơi sản phẩm không làm được thì nói rõ việc phải làm bằng người; rồi tra nhanh, quy định, xử lý sự cố, thuật ngữ và căn cứ. Quy trình khẩn đặt trước và đánh dấu. Lý do hay căn cứ pháp lý nằm trong một câu của bước, không thành trường có nhãn. Việc làm bằng người và thao tác bấm ở câu riêng.
10. **Câu đơn giản.** Một câu một ý, khoảng hai mươi từ trở xuống; một đoạn tối đa bốn câu; một đoạn đưa vào tối đa một chữ mới, giải thích ngay trong câu đó; không giải thích bằng ngoặc lồng nhau; điều khách hàng còn phải xác nhận không rải trong câu chuyện mà gom một bảng ở cuối (thẻ in là nơi duy nhất giữ chỗ trống để điền).
11. **List ngắn khi user yêu cầu.** Khi user muốn list ngắn thay vì văn xuôi, một bước là tiêu đề rồi hai tới bốn gạch, mỗi gạch một câu ngắn (cần gì, vì sao, chọn hay nhập gì, sau đó ra sao), không nhãn, không trường kiểu dấu hai chấm.

## Bước 6 - Giọng văn và nội dung

- Văn phong tự nhiên, lịch sự, bằng ngôn ngữ của người đọc. Gọi người đọc bằng cách xưng hô tự nhiên cho đối tượng đó (ví dụ "thầy cô" với giáo viên), hoặc ngôi thứ ba ("chuyên gia"), nhất quán trong một hướng dẫn. Không lời đệm, không "đừng lo", không nhận xét về trình độ hay hiểu biết của người đọc.
- Từ ngữ giản dị. Không dùng tên nội bộ (giá trị enum, tên hàm, đường dẫn tệp, tên bảng, số ticket) hay tên mã của tính năng.
- Mô tả việc người đọc làm và nhận được, không mô tả màn hình xây thế nào: không màu, hình dạng, kiểu thành phần, bố cục, cách cuộn hay thu gọn, phím tắt, tooltip, trừ khi màu là tên của một trạng thái người đọc phải xử lý.
- Không lịch sử phiên bản, không "nay hoạt động như...", không ngôn ngữ changelog ("đã thêm", "đã sửa", "đổi thành", "trước đây").
- Không có mục về lỗi và không có ảnh lỗi. Hướng dẫn chỉ nêu cách làm đúng. Câu trả lời trong hỏi đáp giải thích vì sao có một quy tắc không phải là mục về lỗi.
- Viết bằng văn xuôi liền mạch. Các câu nối nhau ("Sau đó ...", "Vì ...", "Khi xong ..."); người đọc không bao giờ được thấy mình đang đọc một biểu mẫu đã điền.
- Không bao giờ trình bày thỏa thuận làm việc như sự thật của sản phẩm, và không trình bày giới hạn của sản phẩm như một thiếu sót: nêu như một sự thật kèm cách làm tạm.
- Mọi điểm khách hàng phải quyết đều đánh dấu `[Cần xác nhận: ...]` (bằng ngôn ngữ của người đọc), giữ tối thiểu trong thân bài và gom một lần vào bảng "điều còn phải xác nhận".
- **Từ nhẹ nhàng với chủ đề nhạy cảm.** Khi hướng dẫn nói về trẻ em, sức khỏe hay rủi ro, dùng từ bình tĩnh và tôn trọng: "ý nghĩ tự tử", "tự làm hại bản thân", "cần hỗ trợ khẩn"; không dùng cách nói trần trụi như "muốn chết", "tự làm đau mình". Không biến người thành nhãn ("em khẩn", "em đỏ"); nói "em cần hỗ trợ khẩn", "em được hệ thống gợi ý màu `Đỏ`". Tránh từ chỉ bệnh hay chẩn đoán và từ gây sợ ("nguy hiểm tính mạng", "bỏ mặc"). Câu hỏi hay trích dẫn chính thức giữ nguyên văn và nói rõ là trích. Tên nút, tên nhãn giữ đúng như sản phẩm hiển thị.
- **Ngắn nhưng không cộc lốc.** Ngắn không có nghĩa là cụt. Mỗi câu có chủ ngữ rõ và động từ đầy đủ, các câu nối nhau bằng từ nối ngắn ("Khi", "Nếu", "Sau đó", "Nhờ vậy"). Tránh câu cụt, chuỗi mệnh lệnh không nối, ô bảng chỉ một từ, gạch đầu dòng chỉ là cụm danh từ. Một bước gồm hai đến bốn câu trọn vẹn: hành động, kết quả hoặc điều cần để ý, và lý do nếu cần. Sửa cộc lốc bằng cách hoàn chỉnh câu và cắt chỗ lặp ở nơi khác, để hướng dẫn không dài thêm quá vài phần trăm. Xấu: "Tắt ô này, mở ca ở bước 10." Tốt hơn: "Chuyên gia tắt ô này rồi mở ca ở bước 10."
- **Chỉ đứng ở góc nhìn người đọc.** Nói người đọc thấy gì trên màn hình, làm gì và thấy kết quả ra sao. Không kể sản phẩm làm gì hay phản ứng thế nào bên trong ("hệ thống gửi", "đếm", "gắn cờ", "tự động ...", ai nhận gì và vì sao, trạng thái hay bộ đếm nội bộ). Chỉ nhắc phản ứng của sản phẩm khi người đọc cần nó để quyết định việc mình làm, và khi đó nói bằng kết quả họ thấy ("có thông báo trong hệ thống"), không nói bằng cơ chế.
- **Từ chỉ người trong nghề mới hiểu.** Thay từ của giao diện hay lập trình bằng cách người đọc sẽ nói thành lời. Cái chuông là "thông báo trong hệ thống", không bao giờ viết "chuông"; tương tự với huy hiệu, toast, popup, dropdown, công tắc, cờ, kích hoạt, phiên, token và mọi từ giống vậy. Giữ nguyên tên nút, thẻ và nhãn như màn hình hiện, đặt trong dấu backtick, vì người đọc phải khớp được. Trước khi giao, liệt kê mọi từ như vậy trong hướng dẫn và sửa hết, không chỉ chỗ đã được chỉ ra.

## Bước 7 - Kiểm tra rồi bàn giao

1. **Sự thật.** Kiểm từng khẳng định ai làm được gì, từng khẳng định vắng mặt, từng tên nút và từng điều kiện với nguồn. Phân loại lại mọi việc "làm trực tiếp": không việc nào sản phẩm đã làm được lại nằm trong danh sách làm trực tiếp.
2. **Nội dung bị cấm.** Tìm trong văn bản vai đã bỏ, lời đệm, từ về bố cục và màu, đường dẫn tệp, tên nội bộ, thông tin đăng nhập, từ kiểu changelog, và dòng giống biểu mẫu (dòng bắt đầu bằng một nhãn ngắn rồi dấu hai chấm, hoặc câu dẫn in nghiêng kết thúc bằng dấu hai chấm). Chạy script kiểm của dự án nếu có; không thì viết một script (mọi ảnh tồn tại, mọi ảnh có chiều rộng và không cao hơn giới hạn, có bảng tra nhanh, từ cấm) để kiểm lặp lại được.
3. **Ảnh.** Mọi bước có ảnh hoặc dấu; không dấu nào còn lại khi giao trừ khi user chấp nhận; mở xem ít nhất sáu ảnh mẫu: huy hiệu không che gì, chữ khớp huy hiệu, không trạng thái lỗi, không dữ liệu cá nhân thật, thứ tự câu chuyện đúng.
4. **Đọc thử.** Giao hướng dẫn đã xong cho một người đọc mới (subagent không có ngữ cảnh) đóng vai người chưa biết gì về sản phẩm, để họ liệt kê mọi chỗ thiếu câu trả lời cho "vì sao", "chữ này là gì", "tiếp theo ra sao" hay "ai làm việc này", mọi chỗ nhảy bước, mọi mâu thuẫn, và mọi chỗ đọc thấy máy móc như biểu mẫu. Sửa rồi đọc lại tới khi danh sách trống hoặc chỉ còn điều user phải quyết.
5. **Vai.** Kiểm mỗi vai vận hành có đoạn riêng ngắn, mỗi bước nêu ai làm ngay trong câu, và mỗi sự thật sản phẩm được tách khỏi mỗi thỏa thuận đề xuất.
6. **Tài liệu.** Đếm số tệp giao: mỗi đối tượng một (cộng ghi chú nội bộ nếu có). Hướng dẫn cần tệp thứ hai mới hiểu được thì chưa xong.
7. Mở tệp cho user và đưa đường dẫn. Báo đã kiểm gì và chưa kiểm gì (ví dụ ảnh chụp ở vai khác, khẳng định chỉ đọc từ code), và điểm nào còn chờ khách hàng.

## Bài học sau khi viết lại một hướng dẫn năm lần

- Người đọc chê hình thức trước nội dung. Dòng có nhãn bị coi là máy móc, nhân vật và cảnh bịa bị coi là thừa với người làm nghề, văn xuôi dài bị coi là khó đọc. Sổ tay quy trình đánh số, mỗi bước có một dòng kết quả, là dạng cán bộ chấp nhận; bắt đầu từ đó thay vì tìm ra bằng cách loại dần.
- Đổi hình thức mà không đụng tới sự thật: giữ nguyên số bước, tên nút, ảnh và bảng căn cứ, để mọi chỗ tham chiếu ("xem bước 12") còn đúng sau khi viết lại.
- Đặt quy trình khẩn ngay sau bảng vai trò, đánh dấu rõ, việc làm bằng người đi trước, thao tác bấm đi sau.
- Mỗi sự thật chỉ nói ở một chỗ. Lặp giữa câu chuyện, bảng và hỏi đáp là thứ đẩy hướng dẫn từ 6.000 lên 8.000 từ.
- Cưỡng chế hình thức bằng script (dòng có nhãn, độ dài bước, ảnh đủ, từ cấm) và chạy sau mỗi lần viết lại; cảm nhận của người đọc không phải là phép kiểm.
- Đọc thử tìm ra câu khó hiểu chứ không phán xét hình thức; hỏi user về hình thức một lần, bằng một phần mẫu, trước khi viết lại cả hướng dẫn.
- Khi có bản phát ở nơi khác (Drive, thư mục chia sẻ), thay bản đó sau lần kiểm cuối và nói rõ bản nào là bản hiện hành.
- Đưa cả từ nhạy cảm và lối viết cộc lốc vào script kiểm (danh sách từ trần trụi, các gạch đầu dòng hoặc ô bảng không có động từ), để giọng văn được kiểm giống như hình thức.
- Khi một hướng dẫn bị chê khó hiểu, nguyên nhân thường là từ của giao diện hay của đội làm sản phẩm, hoặc câu nói về việc hệ thống làm bên trong; audit cả hướng dẫn cho cả hai loại, sửa hết, và đưa các từ tìm được vào script kiểm.

## Quy tắc

- Không bịa bước, nút, lệnh hay giới hạn. Điều gì không xác nhận được từ sản phẩm thì bỏ ra và nói trong bàn giao.
- Không đảo quyết định user đã chốt về vai, thứ tự, câu chữ hay số tài liệu.
- Giữ nguyên bản cũ khi viết bản mới; ghi bản mới cạnh bản cũ.
- Không bao giờ xoá hay ghi đè tệp user không yêu cầu; khi thay bản đã tải lên nơi khác thì hỏi trước.
