# Brainstorm: vdesign --bold domain-specific web research (2026-08-19)

## Problem
User: vdesign `--L3 --bold` (v5.0.0, uncommitted) vẫn chưa đủ tốt — muốn mỗi lần chạy `--bold` phải tham khảo web về UI/UX/animation/layout **theo đúng chủ đề đang redesign**, càng chi tiết càng tốt.

## Scout findings (xem `plans/reports/scout-vdesign-web-research-scope.md`)
- `--bold` hiện có Vibe Commitment + Pattern-pull nhưng chỉ kéo từ 3 archetype **tĩnh** trong `~/.claude/skills/frontend-design/references/premium-design-patterns.md` — không có WebSearch/mimo runtime.
- 3 report research sáng nay (award-site-tech-stack, awwwards-visual-vocabulary, frontend-design-slop-patterns) chính là bước "research web" — nhưng làm 1 lần, đóng băng thành catalog generic, không domain-aware.
- Journal `level-cut-5-to-3` cảnh báo: đã đổi gu vdesign 2 lần/2 ngày, chưa có usage data. User xác nhận vẫn muốn làm gap này ngay vì độc lập với 2 thay đổi trước.

## Requirements chốt qua AskUserQuestion
- Trigger: chỉ khi `--bold` (không áp dụng L2/L3 thường, không áp dụng L1)
- Cơ chế: delegate 1 researcher agent (không gọi WebSearch/mimo inline trong main context)
- Độ chi tiết: 1 researcher agent duy nhất (không chia song song theo khía cạnh)
- Quan hệ với catalog tĩnh: bổ sung lên trên, catalog tĩnh vẫn là baseline/fallback
- Domain detection: auto-detect từ code/content, không hỏi user
- Caching: cache theo domain-slug trong session/ngày, tránh research lại khi redesign nhiều trang cùng domain

## Thiết kế đã duyệt

**Touchpoints:** `skills/vdesign/SKILL.md`, `skills/vdesign/SKILL.vi.md`

### Phase 0 — step 6a "Domain Research" (mới, chỉ khi `--bold`, chạy trước Vibe Commitment)
1. Domain slug = domain từ Project Profile (`.vdesign/profile.md`) + tên feature/target đang redesign → VD `healthcare-booking-form`
2. Cache check: tìm `plans/reports/researcher-vdesign-bold-<slug>*.md` tạo trong session/ngày hiện tại → có thì reuse, skip research
3. Không có cache → spawn 1 researcher agent, prompt tìm UI/UX/animation/layout pattern hiện hành (2025-2026) đặc thù cho `<target feature>` trong `<domain>`, giữ tinh thần B2B "clarity > impressiveness" (không phải pure Awwwards/portfolio) → ghi report `plans/reports/researcher-vdesign-bold-<slug>-<HHMMSS>.md`
4. Research/agent fail → fallback im lặng về catalog tĩnh, note trong short report Phase 4 "domain research unavailable"

### Phase 0 step 6b — Vibe Commitment (giữ cấu trúc, bổ sung input)
Chọn vibe dựa trên catalog tĩnh (baseline) + insight domain research (nếu có) — phải nêu rõ có tham chiếu domain-specific finding nào không.

### Phase 3 — Pattern-pull
Kéo pattern từ catalog tĩnh như hiện tại + merge thêm pattern/insight domain-specific từ research report (nếu có).

## Trade-off đã nêu & user chấp nhận
- Thêm 1 agent-call + vài chục giây mỗi domain mới lần đầu chạy `--bold`
- Thay đổi gu vdesign lần thứ 3 trong 2 ngày, chưa có usage data thực tế — user quyết định vẫn làm vì gap độc lập, không lặp lại sai lầm cũ

## Next steps
- `/ck:plan` để lập kế hoạch implement chi tiết (sửa SKILL.md + SKILL.vi.md, viết researcher prompt template, cache lookup logic)
