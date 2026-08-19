# Scout: vdesign --bold web-research scope (2026-08-19)

Task: khảo sát trạng thái vdesign hiện tại + research đã có, đối chiếu ý tưởng mới của user (--bold phải research web mọi khía cạnh UI/UX/animation/layout của chủ đề đang redesign, càng chi tiết càng tốt).

## Cấu trúc level hiện tại (uncommitted, sẽ là v5.0.0)
- 3 level tích lũy: `--L1` Light (spacing/state/color/typo, không đụng cấu trúc) → `--L2` Structural (đổi component/grid, giữ hướng thị giác) → `--L3` Full redesign (đổi hướng thị giác, viết lại JSX)
- `--bold` độc lập, bắt buộc đi kèm `--L2`/`--L3`. Vừa refactor hôm nay từ 5 level xuống 3 (xem journal `level-cut-5-to-3`), và refactor `--bold` từ "suspend 3 rules" sang "Vibe Commitment + Pattern-Pull" (xem journal `bold-mode-awwwards-gap`).

## `--bold` hiện tại đã research web CHƯA — nhưng KHÔNG PHẢI mỗi lần chạy
- Phase 0 step 6: bắt buộc "Vibe Commitment" trước khi code — chọn 1 trong 3 archetype tĩnh (Ethereal Glass/Editorial Luxury/Soft Structuralism) từ `~/.claude/skills/frontend-design/references/premium-design-patterns.md`, HOẶC 1 named movement tĩnh (Neo-Brutalism, Immersive 3D...), HOẶC vibe custom từ keyword user cho.
- Phase 3: "Pattern-pull" — kéo 3-5 pattern **có sẵn** từ catalog tĩnh đó (cùng file reference), KHÔNG search web mỗi lần chạy.
- Dependency allowlist (GSAP, Motion, Lenis, Rive...) là danh sách tĩnh hard-code trong SKILL.md, lấy từ research 1 lần hôm nay.
- → Toàn bộ vốn liếng "biết web đang làm gì" nằm ở 1 lần research batch (3 report dưới), rồi đóng băng thành catalog tĩnh trong file skill + file reference của frontend-design. Không có bước live WebSearch/mimo search trong workflow khi user chạy `vdesign --bold` trên 1 dự án cụ thể.

## 2 journal entries — insight chính
- **bold-mode-awwwards-gap**: root cause xác nhận độc lập bởi 3 researcher agent — (1) suspend rule ≠ cho hướng tích cực, (2) workflow Scan→Audit→Fix là maintenance-reactive, award-tier design cần concept-first (vibe trước, pattern sau), (3) rule "hỏi trước khi thêm dependency" chặn đúng GSAP/Lenis/Motion mà 95%+ site đoạt giải dùng. Next Steps ghi rõ: nếu `--L5 --bold` (nay là `--L3 --bold`) vẫn dở sau fix này, nghi phạm tiếp theo là **asset generation** (Imagen-4), KHÔNG PHẢI research-per-run — tức là hướng "research sâu hơn mỗi lần chạy" chưa từng được nêu ra như hướng khắc phục.
- **level-cut-5-to-3**: thuần về gộp level, không liên quan research. Lesson: đã sửa gu 2 lần trong 2 ngày không có usage data — cảnh báo về việc lại thay đổi lần nữa mà chưa có real invocation nào test.

## 3 research report (làm sáng nay, 09:55:09, đã dùng để build bold-mode fix)
- **award-site-tech-stack**: khảo sát lib animation 2025-2026 (GSAP/Motion/Lenis/Rive/R3F), allowlist vs stop-and-ask, bundle size, CWV impact — đã convert thành "Dependency allowlist" tĩnh trong SKILL.md.
- **awwwards-visual-vocabulary**: pattern thị giác/motion 2024-2026 (3D 61% winner, Neo-brutalism, kinetic typography, bento grid...) + AI-slop diagnostic — đã convert thành phần archetype/pattern tĩnh trong `premium-design-patterns.md` (frontend-design skill) mà vdesign reference tới.
- **frontend-design-slop-patterns**: mining lại chính skill `frontend-design` đã có sẵn (reuse-before-build) — anti-slop rules + premium pattern catalog + đề xuất cấu trúc "Vibe → Pattern-pull → Implement → Validate" — đây là report có ảnh hưởng lớn nhất, đã áp trực tiếp vào bold-mode-awwwards-gap fix.

→ **3 report này CHÍNH LÀ lần "research trên mạng" mà user đang đề xuất — nhưng đã làm 1 lần, kết quả đóng băng thành catalog tĩnh dùng chung mọi lần chạy `--bold`, không phải research per-topic/per-run.**

## Gap giữa trạng thái hiện tại và yêu cầu mới của user
User muốn: mỗi lần `--bold` chạy, phải tham khảo web về **chủ đề cụ thể đang redesign** (ví dụ: nếu redesign 1 trang booking y tế → tìm UI/UX/animation/layout đặc thù cho domain đó), càng chi tiết càng tốt — khác với catalog tĩnh generic hiện tại (archetype cố định, pattern cố định, không phân biệt domain của trang đang sửa).

Gap cụ thể:
1. Catalog hiện tại là **generic, không domain-aware** — 3 archetype tĩnh áp dụng như nhau cho mọi loại sản phẩm, không tra cứu riêng theo domain/chủ đề của trang đang redesign.
2. Không có bước gọi `WebSearch`/`mimo__search`/researcher agent **trong workflow runtime** của vdesign — toàn bộ kiến thức đã "đóng băng" từ research 1 lần.
3. Catalog tĩnh sẽ **cũ dần** — research ghi rõ mốc "2025-2026", nhưng SKILL.md không có cơ chế refresh định kỳ.
4. Đối lập trực tiếp với lesson trong journal `level-cut-5-to-3`: vừa cảnh báo đừng sửa gu nữa khi chưa có usage data — nên nếu thêm bước research-per-run, cần cân nhắc kỹ chi phí (tốn agent call + thời gian mỗi lần chạy `--bold`) vs lợi ích (độ chi tiết/tính thời sự/domain-aware hơn).
