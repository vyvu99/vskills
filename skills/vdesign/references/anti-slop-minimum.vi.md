# Catalog Anti-Slop Tối Thiểu

Catalog pattern và checklist anti-slop dự phòng cho `--wow`, chỉ dùng khi `~/.claude/skills/frontend-design/references/{premium-design-patterns,anti-slop-rules}.md` chưa được cài trên máy này. Viết độc lập cho `vdesign` từ kiến thức UI/UX và anti-slop-design phổ thông, đã được công nhận rộng rãi — không lấy từ catalog của `frontend-design`.

## Archetype pattern (dự phòng cho catalog pattern đầy đủ)

Chọn pattern khớp với vibe đã chốt (Phase 0 step 7) và áp dụng nhất quán trên navigation, layout, card, motion, typography — không chỉ một bề mặt.

1. **Editorial / Magazine Layout** — grid bất đối xứng, pull-quote hoặc số thứ tự section cỡ lớn, whitespace rộng rãi, hierarchy dẫn dắt bằng typography (size/weight làm việc chính, không phải màu). Card: ảnh full-bleed + caption, không viền đồng nhất. Navigation: tối giản, chỉ text, brand ở top-left + link căn phải. Motion: nội dung fade/slide vào khi scroll, không nảy. Micro-interaction: underline khi hover link, không ripple cho button.
2. **Brutalist / High-Contrast** — nền đen/trắng thuần (hoặc 1 màu bão hòa), viền dày 2-4px thay vì shadow, bo góc sắc hoặc tối thiểu, một typeface display đậm duy nhất cho heading. Card: viền cứng, rõ ràng, không blur/gradient. Navigation: lộ cấu trúc — đường grid hiện rõ, divider sắc nét. Motion: chuyển cảnh dứt khoát (snap), không easing mềm. Micro-interaction: đảo màu khi hover/focus thay vì nâng shadow.
3. **Soft / Organic** — bo góc lớn (12px+), shadow nhiều lớp mềm hoặc bề mặt frosted-glass, palette pastel/muted, divider section cong thay vì thẳng. Card: shadow mềm + bo góc, scale nhẹ khi hover. Navigation: active indicator dạng pill. Motion: transition có easing, hơi đàn hồi (200-350ms ease-out). Micro-interaction: đổi scale/opacity nhẹ khi hover, không đảo màu gắt.

## Điều kiện fail anti-slop (dự phòng cho checklist đầy đủ)

Fail run `--wow` nếu bất kỳ điều nào sau còn tồn tại khi báo done — cùng 8 điều kiện skill này đã coi là sàn bắt buộc:

1. Inter hoặc Roboto là typeface duy nhất (cảm giác mặc định, chưa chốt giọng riêng)
2. Gradient tím-xanh là thẩm mỹ chủ đạo
3. 3+ card giống hệt nhau trong một hàng, không có hierarchy thị giác giữa chúng
4. Tên/số placeholder còn sót ("John Doe", số tròn 50%/$100)
5. Copy sáo rỗng kiểu startup ("Elevate", "Seamless", "Next-Gen") trong heading/CTA
6. Background `#000000` thuần (dùng token near-black thay thế)
7. Thiếu hover/focus state trên phần tử tương tác
8. Illustration flat stock chưa customize (unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps không đổi palette/pose) — fix theo tier: hand-drawn custom > line-art/sketch > isometric 3D > flat đã customize kỹ > geometric/abstract > bỏ illustration
