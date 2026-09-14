# Aesthetic Customization

Chạy ở **mọi** lần gọi `vdesign` — không có flag nào gate nó. Trước khi Phase 3 đụng vào code, dẫn user qua 4 vòng `AskUserQuestion` (≤4 câu/vòng, 14 tiêu chí tổng) phủ hết mọi trục thật sự làm thay đổi diện mạo và cảm giác của bản redesign. Agent không tự âm thầm chọn hướng; user luôn là người chọn, tường minh, mỗi lần chạy. Chỉ bỏ qua tiêu chí nào không áp dụng được về mặt cấu trúc cho target (ví dụ Dark Mode Stance khi project không hề có hệ thống theming nào — nói rõ điều đó, đừng hỏi 1 câu không có câu trả lời thật).

Nguồn của danh sách này: v0 (Vercel), Galileo AI, Framer AI, Material Theme Builder, Relume, Figma design tokens, các design system Fluent 2 / Atlassian / Cloudscape / SAP Fiori, bài viết của Smashing Magazine về CSS `corner-shape`, và thực hành creative-brief chuẩn — không bịa từ đầu, và không phải catalog cố định để học thuộc: coi các lựa chọn bên dưới là sàn, không phải trần — đề xuất 1 lựa chọn riêng cho project khi nó rõ ràng hợp hơn.

## Vòng 1 — Nền Tảng Thị Giác

1. **Typography** — hướng typeface chính và giọng điệu kích cỡ.
   - *Minimal/Professional* (IBM Plex, Source Sans 3) — trung tính, technical
   - *Bold/Editorial* (Playfair Display, Fraunces, Clash Display) — đặc trưng, có bản sắc
   - *Code/Technical* (JetBrains Mono, Fira Code, Space Grotesk) — dev-tool, sáng tạo
   - *Startup/Modern* (Satoshi, Cabinet Grotesk, Inter Tight) — hiện đại, thân thiện
2. **Triết lý bảng màu** — cách xây bảng màu.
   - *Giữ token hiện có* — nhất quán hoàn toàn với codebase hiện tại
   - *Chỉ thêm accent* — giữ primary, thêm 1 accent brand mới
   - *Redesign toàn bộ bảng màu* — bảng màu mới từ brand color, xây lại từ đầu
   - *Dynamic/tự sinh* — bảng màu do tool sinh, có sẵn accessibility (kiểu Material Theme Builder)
3. **Triết lý motion/animation** — UI mang bao nhiêu chuyển động.
   - *Minimal* — chỉ transition 150-300ms, không micro-interaction
   - *Balanced* — transition + vài micro-interaction chính (hover, page transition)
   - *Expressive* — reveal so le, page load được dàn dựng, micro-interaction có cảm xúc
   - *Utilitarian* — motion chỉ để báo state change, không bao giờ trang trí
4. **Hệ thống elevation & shadow** — cách xây chiều sâu.
   - *Flat/minimal* — không shadow hoặc rất nhẹ, phân tách bằng stroke/border
   - *Layered (soft + sharp)* — kết hợp shadow ambient + directional cho chiều sâu tự nhiên
   - *Strong elevation* — shadow rõ nét, nhiều lớp, z-axis hierarchy rõ ràng
   - *Monochromatic/minimal* — dùng opacity + stroke thay shadow

## Vòng 2 — Bề Mặt & Cá Tính

5. **Background & texture** — cách xử lý nền trang/section.
   - *Solid color* — tối giản, content-first
   - *Gradient nhẹ* — có chiều sâu mà không lấn át
   - *Pattern hình học/SVG* — cá tính brand, playful hoặc technical
   - *Hiệu ứng khí quyển* — layered/blur/mesh, dùng backdrop-filter
6. **Shape language & border radius** — góc bo như 1 tín hiệu cá tính.
   - *Sharp/geometric* (0-2px) — chuyên nghiệp, uy tín, technical
   - *Soft rounded* (8-12px) — thân thiện, dễ tiếp cận, hiện đại
   - *Playful/soft* (16px+) — ấm áp, chào đón, thoải mái
   - *Squircle/premium* (CSS `corner-shape`) — hybrid playful-premium
7. **Style iconography** — cách dựng icon, không chỉ chọn bộ icon nào.
   - *Outline* — nét mảnh, không fill, sạch và linh hoạt
   - *Filled* — đậm, solid, dễ nhận ra
   - *Hand-drawn/playful* — nét lỏng, độ dày biến thiên, độc đáo
   - *Geometric/minimal* — lưới chuẩn, hình học hoàn hảo, technical
8. **Style illustration & imagery** — cách (và có nên) đại diện người/khái niệm bằng hình ảnh.
   - *Photography/realistic* — chân thực, tập trung độ tin cậy
   - *Abstract/geometric* — hình khối và màu, không đại diện literal
   - *Hand-painted/character* — illustration tùy chỉnh, mascot, cảm xúc
   - *Minimal/icon-based* — chỉ dùng icon, content vẫn là trọng tâm

## Vòng 3 — Cấu Trúc

9. **Mật độ thông tin & chế độ spacing.**
   - *Compact* (grid 4px) — data-heavy, dashboard, bảng dày đặc
   - *Comfortable* (grid 8px) — mặc định cân bằng
   - *Spacious* (gutter 16-24px) — editorial, thoáng, cảm giác premium
10. **Mật độ component & cách tiếp cận grid.**
    - *Tight* (4-8px) — chính xác, technical
    - *Standard* (8-12px) — cân bằng, phổ biến nhất
    - *Generous* (16px+) — dễ đọc, editorial
    - *Flexible/organic* — không grid chặt, flow-based
11. **Cấu trúc layout & breakpoint.**
    - *12-column chuẩn* — linh hoạt, responsive, mặc định ngành
    - *8-column* — section táo bạo hơn, component to hơn
    - *Fluid/theo viewport* — gutter theo phần trăm, scale hữu cơ
    - *Container cố định* — kinh điển, max-width được kiểm soát
12. **Lập trường dark mode.**
    - *Chỉ light mode* — đơn giản, thẩm mỹ light hiện đại
    - *Chỉ dark mode* — hiện đại, tool tập trung/dùng ban đêm
    - *Auto toggle* — theo system preference + override thủ công (best practice mặc định)
    - *Dual-design* — content area light + chrome dark (hybrid, dễ đọc)

## Vòng 4 — Hướng Đi

13. **Cá tính brand & giọng điệu** — cách UI "nói chuyện", kể cả microcopy.
    - *Professional/Ruler* — uy quyền, có cấu trúc, trang trọng
    - *Playful/Jester* — vui, bất ngờ, microcopy tinh nghịch
    - *Empathetic/Caregiver* — ấm áp, ngôn ngữ hỗ trợ
    - *Adventurous/Explorer* — táo bạo, thử nghiệm, giọng tò mò
14. **Độ táo bạo thẩm mỹ / hướng đi tổng thể** — cái núm chính mọi thứ khác scale theo.
    - *Brand-centric/cohesive* — mọi quyết định phục vụ 1 bản sắc rõ ràng, nhất quán; bám sát hệ thống hiện có của project
    - *Experimental/bold* — vượt chuẩn, lựa chọn bất ngờ, tự do sáng tạo thật sự, có thể tách hẳn khỏi hệ thống hiện có
    - *Functional/minimalist* — content-first, không trang trí ngoài những gì rõ ràng cần
    - *Trend-forward* — chủ động lấy từ trào lưu thiết kế thật hiện hành (2025-2026)

## Câu trả lời dẫn tới gì

- **Domain Research** (Phase 0, bước sau) chỉ chạy khi đáng chi phí: tiêu chí 14 trả lời *Trend-forward* hoặc *Experimental/bold*, hoặc các câu trả lời khác của user tường minh gọi tới "cái gì đang thật sự hiện hành". *Brand-centric* hoặc *Functional/minimalist* bỏ qua bước này — không có gì sống để lấy làm căn cứ, dùng thẳng các câu trả lời.
- **Phase 3 Fix** thực thi Design Brief (xem bên dưới), không phải 1 flag. Mọi chỗ flag `--wow` cũ từng mở khóa (màu brand mới, dependency mới, motion trang trí, đổi cấu trúc layout) giờ được mở hay không tùy vào tiêu chí tương ứng ở trên, theo từng lần chạy, tường minh — không bao giờ suy đoán.
- Hard rule kỹ thuật (accessibility, không đổi tech stack, không phá logic/API, motion GPU-safe) không bao giờ bị ảnh hưởng bởi câu trả lời nào ở đây — đó là ràng buộc an toàn/kỹ thuật, không phải thẩm mỹ.

## Design Brief

Sau cả 4 vòng, viết 1 brief ngắn gọn cụ thể (5-10 dòng, không phải 1 nhãn-một-từ cho mỗi tiêu chí) dịch 14 câu trả lời — cộng kết quả Domain Research nếu có chạy — thành quyết định cụ thể: tên typeface thật, cách tiếp cận bảng màu thật, timing/easing motion thật, hướng shape/icon/imagery thật, spacing scale thật, hệ thống layout thật, tone thật, và mức độ táo bạo thật. Nói rõ ra trước khi Phase 1 bắt đầu. Đây là nguồn sự thật duy nhất Phase 3 thực thi theo — 1 đống 14 câu trả lời thô chưa tổng hợp không phải là brief.
