# Quiet Polish Patterns (Tinh Chỉnh Tĩnh Lặng)

Một tier pattern cho `--wow`, nằm giữa mặc định B2B phẳng và catalog Awwwards ồn ào (`premium-design-patterns.md`). Dùng khi vibe đã chốt cần sự ấm áp/thân thiện/tinh tế thay vì táo bạo — form sức khỏe/giáo dục/consumer, luồng onboarding, khảo sát — không phải hero landing page. Luôn đọc và merge thêm cùng catalog đầy đủ đang áp dụng (`premium-design-patterns.md` hoặc archetype của `anti-slop-minimum.vi.md`) — đây là bổ sung thường trực, không phải dự phòng.

Khoảng trống mà file này vá: catalog ồn ào giả định "ấn tượng hơn = effect to hơn" (glassmorphism panel, particle explosion, kinetic type). Quiet polish giả định "ấn tượng hơn = được cân nhắc kỹ hơn" — những nước đi nhỏ, tiết chế, mang cảm giác con người, đọc ra như sự chăm chút, không phải trang trí vì trang trí.

## Nhóm & Lồng khung

- **Tinted Sub-Card** — 1 khối nội dung nổi bật (câu hỏi highlight, callout, summary) được cho khung riêng: tông màu nhạt lệch 1-2 bậc so với nền trang (không trắng-trên-trắng gắt), bo góc lớn (16-24px), không viền nặng — tách biệt đến từ tông màu + khoảng cách, không phải đường viền cứng. Khác với thêm elevation tier mới nặng shadow.
- **Secondary Background Tint** — nền trang tự nó có tông màu rất nhạt, độ bão hòa rất thấp (thoáng chút brand hue, vd `hsl(brand-hue, 15%, 97%)`) thay vì trắng/xám thuần, để content card chính nổi lên như "cái đáng chú ý" trên nền tĩnh, thay vì mọi thứ cùng 1 màu trắng phẳng.
- **Decorative Corner Wash** — 1 blob gradient radial rất mềm, bán kính lớn (opacity 5-10%, brand hue) tràn ra 1 góc card/section — thêm chiều sâu mà không cần shadow, không bao giờ cạnh tranh contrast với nội dung.

## Điểm neo & Iconography

- **Icon Anchor** — 1 icon nhỏ (≤32px) dạng line/duotone custom đặt cạnh tiêu đề hoặc section header làm điểm nhấn thân thiện (vd icon quyển sách cạnh "Bộ công cụ", icon trái tim cạnh CTA). KHÔNG phải illustration stock scene — 1 glyph, 1 màu (hoặc 2 tone), đặt có chủ đích. Đây là nước đi #1 khiến redesign cảm giác "được chăm chút" mà không đọc ra là trang trí sáo rỗng.
- **Soft Icon Chip** — icon anchor nằm trong 1 chip tròn/bo góc nhỏ có nền tint (cùng họ tông với nền trang), cho nó 1 elevation nhỏ riêng mà không cần viền cứng.
- **Sparkle/Accent Mark** — 1 glyph trang trí rất nhỏ (sparkle, cụm chấm, nét flourish ngắn) đặt cạnh heading hoặc icon chip — dùng tối đa 1 lần/view, thuần tín hiệu ấm áp, không bao giờ mang nghĩa quan trọng.

## Nhãn & Typography

- **Eyebrow Tag** — 1 pill badge nhỏ phía trên heading hoặc câu hỏi (`rounded-full px-2.5 py-0.5 text-xs`, nền tint khớp section) mang nhãn ngắn ("Câu 1", "Bước 2") — thay cho prefix text thường "Nhãn:" bằng 1 tag có elevation nhẹ, tách biệt thị giác rõ.
- **Two-Weight Hierarchy** — ghép title đậm/cỡ lớn hơn với subtitle ngay bên dưới nhẹ hơn, nhỏ hơn, màu muted rõ rệt — chỉ cần thêm 1 bậc weight/màu khác biệt cũng đọc ra như typography được cân nhắc, thay vì 1 khối text cùng cỡ phẳng lì.

## State chọn & Input

- **Radio-Card** — thay toggle/pill-button dạng segmented bằng card cho mỗi option (full-width hoặc nửa width): viền bo góc, padding rộng rãi, chỉ báo dạng dot đặc (hoặc checkmark) bên trái — dot fill đặc + viền đổi màu accent khi được chọn. Đọc ra chủ động và thân thiện với thao tác chạm hơn cặp toggle viền trơn.
- **Selected-State Warmth** — card của option được chọn có nền tint mềm (không chỉ đổi màu viền) để trạng thái chọn rõ ngay từ cái nhìn đầu, không cần nhìn kỹ mới thấy.

## Khi nào dùng tier này thay vì catalog ồn ào

- Vibe là Soft Neumorphic / Organic Asymmetric / Maximal Minimal / Authentic Humanist / Flow-First System → kéo chủ yếu từ đây.
- Vibe là Neo-Brutalist / Chromatic Dopamine / Kinetic-Motion-First / Spatial 3D → kéo chủ yếu từ `premium-design-patterns.md`, dùng tier này rất hạn chế nếu có (1 icon anchor vẫn có thể hợp; tinted sub-card thường không khớp vibe brutalist).
- Dù chọn nhánh nào: không bao giờ kết hợp quá 2-3 pattern của tier này trong 1 view — quiet polish mất tác dụng nếu mọi thứ đều có tint, chip, và sparkle cùng lúc.
