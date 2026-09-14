# Game-inspired/Arcade Patterns (Cảm Hứng Game)

Một tier pattern cho khi tiêu chí Aesthetic Boldness (14) của Design Brief là *Game-inspired/Arcade* — art direction mượn từ game UI (HUD panel, glow/neon accent, tactile juice), không bao giờ là fallback cho các lựa chọn boldness khác và không merge mặc định như `quiet-polish-patterns.vi.md`. Chỉ đọc file này khi tiêu chí 14 trả lời tường minh *Game-inspired/Arcade*.

**Ranh giới scope — chỉ art direction, không phải cơ chế gamification.** Tier này nói về UI trông và cảm giác thế nào (ngôn ngữ thị giác/cảm xúc), không bao giờ về thêm điểm, level, streak, achievement, hay hệ thống unlock — đó là quyết định sản phẩm/tính năng, nằm ngoài phạm vi redesign bất kể tiêu chí này trả lời gì.

Khoảng trống mà file này vá: catalog ồn ào (`premium-design-patterns.md`) giả định "táo bạo = năng lượng editorial/landing-page" (glassmorphism, kinetic type, particle field). Game-inspired giả định "táo bạo = năng lượng tactile/responsive" — mọi bề mặt tương tác tự xác nhận bản thân về mặt vật lý, khung HUD cho cấu trúc cảm giác diegetic, và motion mang trọng lượng thay vì chỉ easing mượt.

## Panel & Bề Mặt

- **HUD Corner-Bracket Panel** — góc của 1 panel nội dung có accent dạng bracket ngắn (kiểu `┌ ┐` / `└ ┘`, stroke 2-3px, màu accent) thay vì viền tròn/vuông đầy đủ, đọc ra như khung reticle ngắm hoặc menu game. Implementation: 4 pseudo-element `::before`/`::after` nhỏ cho mỗi góc (cặp `border-left`/`border-top` absolute-positioned), không phải border đầy đủ trên container — giữ thân panel mở về mặt thị giác.
- **Chunky Tactile Border** — border dày (3-4px), bão hòa hoàn toàn trên bề mặt tương tác (button, card, input focus) thay vì hairline 1px mảnh — đọc ra như 1 vật thể vật lý, có thể bấm, thay vì 1 element web phẳng. Kết hợp `box-shadow` dày offset khớp màu (`4px 4px 0 var(--accent)`, không blur) cho cảm giác chiều sâu "cel-shaded" chunky.

## Phản Hồi & Điểm Nhấn

- **Glow/Neon Accent Border** — border/ring của 1 element tương tác mang glow `box-shadow` bão hòa (`0 0 12px 2px var(--accent)`, opacity 40-60%) khi hover/focus/active, thay vì chỉ đổi màu phẳng — đọc ra như trạng thái được cấp năng lượng, "đang bật". Giữ 1 màu glow duy nhất/view (token accent), không bao giờ nhiều tông neon cạnh tranh nhau.
- **Satisfying Press Ripple** — khi tap/click, 1 ripple hình tròn dùng `opacity`+`transform: scale()` lan ra từ điểm bấm rồi fade out (200-300ms), xác nhận thao tác đã ghi nhận — GPU-safe qua pseudo-element animate chỉ trên `transform`/`opacity`, không bao giờ dùng ripple library thật đụng vào layout.

## Motion & Interaction

Giữ mọi chuyển động GPU-safe (chỉ `transform`/`opacity`, không bao giờ `width`/`height`/`top`/`left`) — game-feel là về *trọng lượng*, không phải thời lượng; nghiêng về overshoot/spring easing (`cubic-bezier(0.34, 1.56, 0.64, 1)`) thay vì transition tuyến tính dài hơn.

- **Squash/Bounce Button Press** — khi `:active`, button scale xuống và squash nhẹ (`scale(0.94, 0.90)`, ~80ms), rồi bật lại vượt quá 100% trước khi ổn định (`scale(1.02)` → `scale(1)`, overshoot easing) khi thả tay — xác nhận thao tác bấm với trọng lượng vật lý, không chỉ dampen phẳng `scale(0.98)`.
- **Progress-Fill Weighty Easing** — fill của progress/XP-bar animate qua `transform: scaleX(progress)` (không bao giờ `width`) với easing overshoot để hơi vượt quá mức fill mục tiêu rồi ổn định lại, thay vì ease-out phẳng — đọc ra như đà (momentum), không phải tick đồng hồ đo tuyến tính.
- **Reduced-motion guard** — mọi pattern ở đây vẫn cần fallback `prefers-reduced-motion` (đổi state ngay lập tức, không squash/bounce/overshoot) theo category audit Animation & Motion gốc — game-feel không bao giờ bỏ qua điều này.

## Khi nào dùng tier này

- Tiêu chí 14 (Aesthetic Boldness) trả lời *Game-inspired/Arcade* → kéo chủ yếu từ đây, merge cùng kết quả Domain Research (step 7) nếu có chạy.
- Bất kỳ câu trả lời nào khác cho tiêu chí 14 → file này không áp dụng; dùng `premium-design-patterns.md` (năng lượng táo bạo/đồ họa) hoặc `quiet-polish-patterns.vi.md` (năng lượng ấm áp/tiết chế) thay thế.
- Ngay cả trong 1 lần chạy *Game-inspired/Arcade*: đừng chồng hết mọi pattern lên mọi bề mặt — 1 xử lý HUD-bracket cho panel cấu trúc, phản hồi tactile/glow trên đường tương tác chính, là đủ; lạm dụng tất cả cùng lúc đọc ra như ồn ào, không phải năng lượng.
