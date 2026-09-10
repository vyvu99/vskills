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

## Motion & Interaction

1 ảnh reference tĩnh (mockup, screenshot đối thủ, concept AI) bị đóng băng — không thể hiện được transition. Code thật thì có thể, và đây là 1 trong những cách rõ nhất để vượt qua 1 ảnh reference tĩnh, không chỉ khớp mặt nhìn. Giữ mọi chuyển động GPU-safe (chỉ `transform`/`opacity`, không bao giờ `width`/`height`/`top`/`left`) và trong khoảng 150-350ms — quiet polish là để cảm nhận, không phải để trình diễn.

- **Selection Transition** — dot-fill và màu viền của Radio-Card animate vào (150-250ms ease-out) khi được chọn, thay vì snap ngay lập tức. Bản thân fill có thể scale từ 0 lên full thay vì chỉ xuất hiện.
- **Progress Fill Animation** — fill của progress bar animate mượt tới giá trị mới khi tiến bước (250-350ms ease-out), không bao giờ jump-cut. Implementation GPU-safe: track width cố định, phần tử fill bên trong animate bằng `transform: scaleX(progress)` (`transform-origin: left`), không animate trực tiếp `width`.
- **Selected-Card Settle** — card của option vừa được chọn có 1 scale pulse rất nhẹ (vd `scale(1.02)` → `scale(1)`, ~150ms) khi chọn, củng cố Selected-State Warmth bằng motion, không chỉ bằng màu.
- **Icon Chip Entrance** — chip của Icon Anchor fade/scale vào sau khi container mount xong (stagger ngắn, delay ~80-120ms), thay vì xuất hiện đồng thời với mọi thứ khác — sequencing nhỏ đọc ra như được cân nhắc kỹ.
- **Tactile Press Feedback** — mọi bề mặt có thể chạm (radio-card, button, chip) có `scale(0.98)` khi `:active` — xác nhận thao tác chạm đã ghi nhận trước khi kết quả async về.
- **Completion Moment** — khi thực sự hoàn thành 1 flow (không phải mọi action nhỏ), 1 tín hiệu ăn mừng ngắn gọn, tiết chế (check-mark vẽ vào mềm mại, scale/fade nhẹ trên icon hoàn thành) là hợp lý — đây là lựa chọn vibe có chủ đích, không phải "không cần thiết", nhưng chỉ 1 khoảnh khắc/flow, không rải rác.
- **Reduced-motion guard** — mọi pattern ở đây vẫn cần fallback `prefers-reduced-motion` (đổi state ngay lập tức, không animation) theo category audit Animation & Motion gốc — quiet polish không bao giờ bỏ qua điều này.

## Khi nào dùng tier này thay vì catalog ồn ào

- Vibe là Soft Neumorphic / Organic Asymmetric / Maximal Minimal / Authentic Humanist / Flow-First System → kéo chủ yếu từ đây.
- Vibe là Neo-Brutalist / Chromatic Dopamine / Kinetic-Motion-First / Spatial 3D → kéo chủ yếu từ `premium-design-patterns.md`, dùng tier này rất hạn chế nếu có (1 icon anchor vẫn có thể hợp; tinted sub-card thường không khớp vibe brutalist).
- Dù chọn nhánh nào: không bao giờ kết hợp quá 2-3 pattern của tier này trong 1 view — quiet polish mất tác dụng nếu mọi thứ đều có tint, chip, và sparkle cùng lúc.
