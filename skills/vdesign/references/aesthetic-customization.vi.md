# Checklist Quyết Định Thiết Kế

vdesign tự quyết mọi trục dưới đây, mỗi lần chạy — không còn `AskUserQuestion`,
không còn user chọn mỗi lần. Đây là taxonomy + thứ tự ưu tiên quyết định mà vdesign
dùng để điền vào Design Brief (`SKILL.md` Phase 0 bước 7): 18 tiêu chí chia 6 nhóm,
bao phủ mọi trục thực sự thay đổi diện mạo/cảm giác của 1 bản redesign. Chỉ bỏ qua
tiêu chí nào thật sự không áp dụng được cho target (vd Dark Mode Stance khi project
không có hệ theming nào, hoặc Data & Table Density khi target không có bề mặt
data-heavy nào — nói rõ lý do, đừng ép ra 1 quyết định không có câu trả lời thật).

Nguồn đứng sau danh sách này: v0 (Vercel), Galileo AI, Framer AI, Material Design 3 /
Theme Builder, Relume, Figma design tokens, Fluent 2 / Atlassian / Cloudscape / SAP
Fiori design systems, Ant Design, Carbon Design System, Linear, nghiên cứu empty-state
của Nielsen Norman Group, bài viết về CSS `corner-shape` của Smashing Magazine — không
phải tự nghĩ ra, và không phải catalog cố định phải học thuộc: coi các option bên dưới
là sàn, không phải trần — chọn 1 option riêng cho project khi nó khớp rõ ràng hơn bất
kỳ option liệt kê ở đây.

## Thứ tự ưu tiên quyết định

Với mỗi tiêu chí, quyết theo thứ tự này và nêu rõ cái nào thực sự dẫn tới lựa chọn
(không bao giờ "thấy hợp thì chọn"):

1. **Domain Research của chính lần chạy này** (`SKILL.md` Phase 0 bước 6, luôn chạy)
   — 1 finding cụ thể, hiện hành (2026) cho đúng aspect/domain này thắng mọi default
   chung chung bên dưới.
2. **Project Profile** — design token hiện có, dependency trong `package.json`, mục
   "Good reference UI", component code đã đọc. Dùng khi có lý do thật để giữ nhất
   quán, không phải mặc định.
3. **Real User & Purpose** (`SKILL.md` Phase 1 bước 1) — persona thật và task thật
   mà màn hình này phục vụ; quyết định mật độ, tone, và việc chọn hướng táo bạo hay
   tiết chế có thực sự khớp bối cảnh không (vd 1 tool B2B lâm sàng và 1 app wellness
   tiêu dùng sẽ ra 2 câu trả lời khác nhau cho cùng 1 tiêu chí).
4. **Personal Aesthetic Quality Floor** (`SKILL.md`) — khi không có tín hiệu mạnh từ
   mục 1-3 (greenfield, không có tiền lệ), chọn option phổ biến/bảo thủ nhất cho trục
   đó thay vì đoán táo bạo, và nói rõ lý do.

## Vòng 0 — Tự do cấu trúc

0. **Tự do cấu trúc** — cấu trúc của page/component được phép đổi tới mức nào, không
   chỉ styling. Quyết định chủ yếu bởi bước Real User & Purpose ở Phase 1
   (`SKILL.md`), không phải file này: được phép đổi cấu trúc (merge/sắp lại/tách
   section, đổi view-type) bất cứ khi nào cấu trúc hiện tại thật sự không khớp task
   thật — không bị chặn bởi "proportional với audit tìm ra" riêng cho các thay đổi
   cấu trúc — nhưng mọi lần đổi cấu trúc phải trace được về 1 lý do cụ thể từ bước
   đọc đó, không phải "vì có thể đẹp hơn."

## Vòng 1 — Nền tảng thị giác

1. **Typography** — hướng typeface chính và giọng cỡ chữ.
   - *Minimal/Professional* — trung tính, kỹ thuật; đại diện: `IBM Plex Sans, sans-serif` (IBM Plex, Source Sans 3)
   - *Bold/Editorial* — đặc trưng, có thương hiệu; đại diện: `Playfair Display, serif` (Playfair Display, Fraunces, Clash Display)
   - *Code/Technical* — dev-tool, sáng tạo; đại diện: `JetBrains Mono, monospace` (JetBrains Mono, Fira Code, Space Grotesk)
   - *Startup/Modern* — đương đại, thân thiện; đại diện: `Inter Tight, sans-serif` (Satoshi, Cabinet Grotesk, Inter Tight)
2. **Triết lý bảng màu** — cách xây bảng màu.
   - *Giữ nguyên token hiện có* — nhất quán hoàn toàn với codebase hiện tại, không đổi brand color nào trong lần chạy này
   - *Chỉ thêm accent* — giữ primary, thêm đúng 1 accent mới; token primary/base giữ nguyên
   - *Redesign toàn bộ palette* — palette mới từ brand color, xây lại từ đầu, mọi color token trong phạm vi đều có thể đổi
   - *Dynamic/auto-generated* — palette do tool sinh ra kèm accessibility tích hợp sẵn (kiểu Material Theme Builder), tự do ngang với redesign toàn bộ
3. **Triết lý motion/animation** — UI mang bao nhiêu chuyển động.
   - *Minimal* — chỉ transition 150-300ms, không micro-interaction
   - *Balanced* — transition + vài micro-interaction chính (hover, page transition)
   - *Expressive* — stagger reveal, page load có dàn dựng, micro-interaction giàu cảm xúc
   - *Utilitarian* — motion chỉ để báo state change, không bao giờ trang trí
4. **Hệ thống elevation & shadow** — cách xây độ sâu.
   - *Flat/minimal* — không shadow hoặc rất nhẹ, phân tách bằng stroke/border
   - *Layered (soft + sharp)* — kết hợp ambient + directional shadow cho độ sâu tự nhiên
   - *Strong elevation* — shadow rõ nét, nhiều lớp, z-axis hierarchy rõ ràng
   - *Monochromatic/minimal* — dùng opacity + stroke thay vì shadow

## Vòng 2 — Bề mặt & Cá tính

5. **Background & texture** — xử lý nền page/section.
   - *Màu đặc* — tối giản, content-first
   - *Gradient nhẹ* — có chiều sâu mà không lấn át
   - *Pattern hình học/SVG* — cá tính thương hiệu, playful hoặc technical
   - *Hiệu ứng khí quyển* — layered/blur/mesh, dựa trên backdrop-filter
6. **Ngôn ngữ hình khối & border radius** — góc bo như 1 tín hiệu cá tính.
   - *Sắc/hình học* (0-2px) — chuyên nghiệp, có thẩm quyền, kỹ thuật
   - *Bo mềm* (8-12px) — thân thiện, dễ gần, hiện đại
   - *Playful/soft* (16px+) — ấm áp, chào đón, casual
   - *Squircle/premium* (CSS `corner-shape`) — lai giữa playful và premium
7. **Phong cách iconography** — cách xây icon, không chỉ bộ icon nào.
   - *Outline* — nét mảnh, rỗng fill, sạch và linh hoạt
   - *Filled* — đậm, đặc, dễ nhận ra
   - *Hand-drawn/playful* — nét tay, weight không đều, độc đáo
   - *Geometric/minimal* — lưới nghiêm ngặt, hình học hoàn hảo, kỹ thuật
8. **Phong cách illustration & imagery** — cách (và có hay không) biểu diễn người/khái niệm.
   - *Photography/realistic* — chân thực, thiên về tin cậy
   - *Abstract/geometric* — hình khối và màu, không tả thực
   - *Hand-painted/character* — illustration custom, mascot, giàu cảm xúc
   - *Minimal/icon-based* — chỉ dùng icon, nội dung vẫn là trọng tâm

## Vòng 3 — Cấu trúc

9. **Mật độ thông tin & spacing mode.**
   - *Compact* (grid 4px) — data-heavy, dashboard, bảng dày
   - *Comfortable* (grid 8px) — mặc định cân bằng
   - *Spacious* (gutter 16-24px) — editorial, nhiều khoảng thở, cảm giác premium
10. **Mật độ component & cách tiếp cận grid.**
    - *Tight* (4-8px) — chính xác, kỹ thuật
    - *Standard* (8-12px) — cân bằng, phổ biến nhất
    - *Generous* (16px+) — dễ đọc, editorial
    - *Flexible/organic* — không grid cứng, theo flow
11. **Cấu trúc layout & breakpoint.**
    - *12-cột chuẩn* — linh hoạt, responsive, mặc định ngành
    - *8-cột* — section táo bạo hơn, component lớn hơn
    - *Fluid/theo viewport* — gutter theo %, scale hữu cơ
    - *Container cố định* — cổ điển, max-width kiểm soát được
12. **Lập trường dark mode.**
    - *Chỉ light mode* — đơn giản, thẩm mỹ sáng đương đại
    - *Chỉ dark mode* — hiện đại, hợp tool dùng ban đêm/focus
    - *Auto toggle* — theo system + override thủ công (best practice mặc định)
    - *Dual-design* — vùng nội dung sáng + chrome tối (đọc dễ kiểu hybrid)

## Vòng 4 — Hướng đi

13. **Cá tính thương hiệu & tone giọng** — cách UI "nói chuyện", kể cả microcopy.
    - *Professional/Ruler* — có thẩm quyền, chặt chẽ, trang trọng
    - *Playful/Jester* — vui, bất ngờ, microcopy tinh nghịch
    - *Empathetic/Caregiver* — ấm áp, ngôn ngữ nâng đỡ
    - *Adventurous/Explorer* — táo bạo, thử nghiệm, tò mò
14. **Độ táo bạo thẩm mỹ / hướng đi tổng thể** — cái núm chính mọi thứ khác scale theo. Không còn mặc định khóa về "bám sát hệ thống" — Domain Research luôn chạy mỗi lần, nên chọn hướng mà finding của lần chạy này + bước Real User & Purpose thực sự ủng hộ:
    - *Brand-centric/cohesive* — mọi quyết định phục vụ 1 identity nhất quán, bám sát hệ thống hiện có của project
    - *Experimental/bold* — phá chuẩn, lựa chọn bất ngờ, tự do sáng tạo thật sự, có thể rời hẳn hệ thống hiện có
    - *Functional/minimalist* — content-first, không trang trí ngoài mức cần cho rõ ràng
    - *Trend-forward* — chủ động kéo từ xu hướng thiết kế thực tế hiện hành (2025-2026) mà Domain Research của lần chạy này tìm ra
    - *Game-inspired/Arcade* — panel kiểu HUD, glow/neon accent, feedback tactile chunky (squash/bounce khi nhấn), motion nặng-đã-tay; art direction mượn từ game UI, không phải cơ chế gamification (không thêm điểm/level/streak)

## Vòng 5 — Nội dung & State

15. **Mật độ data & table** — cách xây bề mặt data-heavy (bảng, dashboard, list).
    - *Spreadsheet-dense* (kiểu Cloudscape/Fiori) — tối đa row/màn hình, cell compact, chrome sort/filter luôn hiện
    - *Card/row-hybrid* — ngữ nghĩa table nhưng mỗi row đọc như mini-card (avatar, badge, nhiều khoảng thở hơn)
    - *Chart-first dashboard* — trực quan hóa data (chart/sparkline) trước bảng thô, bảng chỉ để drill-down
    - *Minimal/inline* — data gói trong văn xuôi hoặc list đơn giản, không chrome table trừ khi dataset đòi hỏi
16. **Phong cách form & input** — xử lý thị giác + tương tác của input, không chỉ màu.
    - *Floating label* (Material) — label animate vào input khi focus/fill
    - *Top label + helper text* (Fluent, Carbon) — label luôn hiện phía trên, helper/error text bên dưới
    - *Inline/borderless* (minimal, kiểu Linear) — underline hoặc không border, label như placeholder
    - *Grouped/segmented* — field liên quan nhóm thị giác trong 1 card có viền, nhịp field-to-field rõ ràng
17. **Phong cách state empty/loading/error** — cách UI biểu diễn "chưa có gì"/"đang xử lý"/"có lỗi".
    - *Skeleton screen* — placeholder xám hình-content khi loading, khớp layout cuối cùng
    - *Spinner/minimal* — spinner hoặc progress bar đơn giản, không mô phỏng layout
    - *Illustrated* — illustration/icon custom + copy thân thiện cho state empty/error (cảm giác onboarding)
    - *Text-only/utilitarian* — thông báo text thuần, không illustration, nhanh nhất để build, visual weight thấp nhất

## Cách vdesign tự quyết

- **Tự do cấu trúc** (Vòng 0) được dẫn dắt bởi bước Real User & Purpose ở Phase 1,
  không đoán từ danh sách này — xem ghi chú ở mục đó.
- **Domain Research** (`SKILL.md` Phase 0 bước 6) giờ luôn chạy mỗi lần, bất kể tiêu
  chí 14 (độ táo bạo) rơi vào hướng nào — nó là 1 input cho quyết định, không còn bị
  nó gate.
- **Phase 3 Fix** thực thi Design Brief (bên dưới) — mọi trục trước đây được 1 flag
  hoặc 1 câu trả lời của user mở khóa, giờ được mở khóa bởi Thứ tự ưu tiên quyết định
  ở trên, nêu rõ ràng trong brief, không bao giờ để ngầm hiểu.
- Hard technical rule (accessibility, motion GPU-safe, không đổi DB schema/migration)
  không bao giờ bị ảnh hưởng bởi quyết định nào ở đây — đó là ràng buộc an
  toàn/kỹ thuật, không phải lựa chọn thẩm mỹ. Thay đổi API/service layer NẰM TRONG
  phạm vi khi 1 quyết định ở trên cần tới (vd expose 1 field cho lựa chọn data/table
  density mới) — xem Hard rules của `SKILL.md`.

## Design Brief

Sau khi quyết xong cả 18 tiêu chí (tự quyết, không hỏi), viết 1 brief ngắn cụ thể
(5-10 dòng, không phải 1 nhãn-1-từ cho mỗi tiêu chí) dịch các quyết định đó — cộng
finding của Domain Research và bước đọc Real User & Purpose — thành lựa chọn cụ thể:
tên typeface thật, cách tiếp cận palette thật, timing/easing motion thật, hướng
shape/icon/imagery thật, spacing scale thật, hệ thống layout thật, tone thật, mức độ
táo bạo thật, và (khi áp dụng) cách xử lý data/table, form, empty/loading/error thật.
Nói rõ ra trước khi Phase 1 bắt đầu. Đây là nguồn chân lý duy nhất mà Phase 3 thực
thi theo — 1 đống 18 quyết định thô chưa tổng hợp không phải là brief.
