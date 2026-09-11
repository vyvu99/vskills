---
name: vdesign
description: "Redesign UI/UX hiện có theo gu thẩm mỹ cá nhân: tinh tế, hài hòa, hiện đại, thanh lịch, nhất quán với hệ thống. Dùng khi nâng cấp UI của một trang/component/feature/PR đã có sẵn."
user-invocable: true
when_to_use: "Kích hoạt khi bạn muốn redesign hoặc nâng cấp UI/UX của một trang, component, feature, hoặc toàn bộ diff/PR hiện có."
argument-hint: "[URL | localhost:PORT/path | component | feature | --pr | --diff | [Image]] [--wow]"
metadata:
  author: vyvu
  version: "7.0.0"
---

# vdesign — Skill Redesign UI/UX Cá Nhân

Nâng cấp hoặc redesign UI/UX theo một gu thẩm mỹ nhất quán: **tinh tế · hài hòa · hiện đại · thanh lịch · nhất quán với hệ thống**.

Không còn flag mức độ. `vdesign <target>` là mode nền duy nhất — audit-driven: sửa mọi thứ Phase 2 tìm ra, bất kể độ sâu (spacing → cấu trúc → đổi hướng thị giác). Không còn trần chặn, không còn kiểu "tìm ra rồi nhưng không fix được vì sai mức".

`--wow` (tùy chọn) — mở khóa mức độ táo bạo thẩm mỹ tầm Awwwards trên nền mode mặc định; xem Vibe Archetype Catalog và Phase 3 bên dưới.

Không đổi tech stack. Không phá logic/state/API.

---

## Các dạng Input (7 loại)

| Input | Xử lý |
|-------|------------|
| _(rỗng)_ | Hỏi user 1 câu: "Bạn muốn redesign phần nào?" |
| `localhost:PORT/path` hoặc URL | Chụp screenshot trước → rồi đọc các file source tương ứng |
| Route path (ví dụ `/clients/[id]?tab=notes`) | Resolve ra file pages/components tương ứng |
| Tên component/feature (ví dụ `TreatmentPlanWizard`) | Grep để tìm file → đọc toàn bộ component tree |
| `[Image]` / screenshot đính kèm | Phân tích ảnh → trích xuất các thiếu sót về design → áp fix. Nếu có nhiều ảnh tạo thành cặp before/target (trạng thái hiện tại + 1 reference đầy tham vọng — mockup, screenshot đối thủ, hoặc concept do AI tạo) → coi reference là mức cần đạt, không chỉ tham khảo — xem "Vượt qua ảnh reference" ở Phase 3 |
| `--pr` | `gh pr diff` để lấy các file đã thay đổi → redesign toàn bộ file UI trong đó (cần gh, §2 của `repo-profile.md`; không có → fallback sang `--diff`) |
| `--diff` | `git diff --name-only` để lấy staged/unstaged → redesign các file UI |

---

## Gu Thẩm Mỹ Cá Nhân (Không thương lượng)

Đây là từ vựng của user — **TẤT CẢ** phải đạt theo mặc định, không phải chọn vài cái ngẫu nhiên. Chỉ tạm ngưng áp dụng khi `--wow` được truyền tường minh (xem Phase 3):

| Từ khóa | Ý nghĩa thực tế trong code |
|---------|--------------------------|
| **Tinh tế (Refined)** | Chi tiết nhỏ đúng chỗ: border-radius nhất quán, icon size đều nhau, text-overflow được xử lý, không có giá trị spacing scale lẻ |
| **Hài hòa (Harmonious)** | Màu, font, spacing khớp với phần còn lại của project; không phải "ốc đảo cô lập" tự mang style riêng; font-size/spacing/component-size theo modular scale/tỷ lệ nhất quán, không dùng giá trị tùy tiện |
| **Hiện đại (Modern)** | Không dùng pattern lỗi thời (table viền kiểu cũ, form label kiểu cũ, button phẳng không có state); tận dụng tốt whitespace |
| **Thanh lịch (Elegant)** | Hierarchy rõ ràng, ít nhiễu thị giác, không trang trí thừa, phân cấp button rõ ràng (primary/ghost/link) |
| **Chiều sâu (Deep)** | Elevation tier rõ ràng, shadow/border/light-source nhất quán — không bao giờ phẳng lì vô hồn, không bao giờ skeuomorphic |
| **Nhất quán với hệ thống** | Khớp với design tokens, component pattern, và ngôn ngữ thị giác của project — **đây là yêu cầu quan trọng nhất** |
| **Accessible** | Thông tin không bị ẩn; label rõ ràng; icon quan trọng có tooltip; đầy đủ state empty/loading/error |
| **Tiện dụng (Efficient)** | Tối thiểu thao tác/click: bulk action, inline-edit, smart default khi an toàn |
| **Sáng tạo khi được phép** | Được phép tạo hình ảnh khác biệt khi user yêu cầu "làm gì đó khác cho đa dạng" — nhưng vẫn phải nhất quán về spacing/màu |

**KHÔNG** áp dụng thẩm mỹ portfolio/avant-garde. Kể cả redesign toàn bộ vẫn phải phục vụ bối cảnh sản phẩm B2B: **rõ ràng > gây ấn tượng**.

---

## Vibe Archetype Catalog (`--wow`)

16 triết lý thiết kế có tên, hiện hành (2025-2026) để chốt ở bước Vibe Commitment của Phase 0. Chọn ĐÚNG MỘT — không bao giờ trộn 3+ triết lý trên cùng 1 trang (xem anti-slop gate). Rating giả định bối cảnh mặc định "rõ ràng > gây ấn tượng" của skill này — bỏ qua cột B2B-Viable khi project đích rõ ràng là consumer/portfolio.

| # | Archetype | Thẩm mỹ cốt lõi | B2B-Viable | Motion | Risk |
|---|---|---|---|---|---|
| 1 | Neo-Brutalist Bold | Đường nét dày, contrast cao, hình khối thô | Yes | Low | Low |
| 2 | Maximalist Editorial | Nhiều lớp, rực rỡ, bố cục dày đặc | Selective | Medium | Medium |
| 3 | Ethereal Glass | Frosted, trong mờ, depth mềm | Yes | Low | Very Low |
| 4 | Soft Neumorphic | Shadow mềm, tactile, 3D-subtle | Yes | Low | Very Low |
| 5 | Kinetic/Motion-First | Reveal có animation, micro-interaction | Yes | High | Medium |
| 6 | Chromatic Dopamine | Màu saturated táo bạo, exuberant | Accent only | Medium | High |
| 7 | Surreal Narrative | Photo-real + phi thực tế, dreamlike | Hero only | Low | High |
| 8 | Organic Asymmetric | Đường cong, biophilic, hình dạng tự nhiên | Yes | Low | Very Low |
| 9 | Maximal Minimal | Nền trắng + 1-2 điểm nhấn táo bạo | Yes (best) | Low | Very Low |
| 10 | Flow-First System | Journey-driven, progressive disclosure | Yes | Medium | Very Low |
| 11 | Bento Interactive | Grid modular, block chơi được | Yes | Medium | Low |
| 12 | Typography-Dominant | Type oversized, custom typeface, hierarchy | Yes | Low | Very Low |
| 13 | Authentic Humanist | Custom craft, giọng điệu thật, anti-stock | Yes (critical) | Low | Very Low |
| 14 | Data-Adaptive | Personalized, context-aware, thông minh | Yes | Medium | Medium |
| 15 | Retro-Nostalgic | 70s/80s, ấm áp, texture vintage | Niche | Low | High |
| 16 | Spatial 3D | Depth, parallax, storytelling nhiều lớp | Yes | High | Medium |

---

## Workflow: Scan → Audit → Fix → Verify

### Phase 0: Xác định phạm vi

1. Parse argument để xác định input mode (xem bảng trên)
2. Nếu có URL/localhost → **chụp screenshot ngay** bằng bất kỳ screenshot tool nào khả dụng (Playwright MCP, browser tool, v.v.); nếu không có tool nào khả dụng, hỏi user paste screenshot trực tiếp
3. Nếu có `--pr` → xác định VCS profile theo `~/.claude/skills/_vskills-shared/repo-profile.md` §2 trước (nếu file không tồn tại, coi như full gh mode — đúng hành vi mặc định hiện tại). Full gh mode → `gh pr diff --name-only` để lấy danh sách file. Degraded (thiếu gh / không phải GitHub) → in thông báo §2 và hỏi user tên branch, hoặc fallback sang `--diff` (`git diff --name-only`, không cần gh) — rồi tiếp tục vào Phase 1 bình thường.
4. Xác định Project Profile: kiểm tra `.vdesign/profile.md` tại git root của project đích (`git rev-parse --show-toplevel`). Có → đọc và dùng luôn. Không có → suy luận UI library/design tokens từ dependency trong `package.json`, `tailwind.config.*`, và cấu trúc thư mục components. Vẫn mơ hồ → hỏi 1 câu, rồi đề nghị (không ép) lưu câu trả lời vào `.vdesign/profile.md` cho lần sau.
5. Nếu rỗng → hỏi user qua `AskUserQuestion` — **đúng 1 câu**
6. Nếu có `--wow` → **Domain Research**, trước Vibe Commitment:
   - Domain slug = domain từ context của Project Profile (ví dụ "B2B Healthcare") + tên feature/trang đích đã resolve ở step 1 (ví dụ "booking form") — slugify (ví dụ `healthcare-booking-form`)
   - Danh sách khía cạnh cố định, luôn đủ 8: `ui` (UI/Visual), `ux` (UX/Interaction), `animation` (Animation/Motion), `layout` (Layout/Responsive), `3d` (pattern 3D/WebGL/spatial-depth), `text` (pattern Typography/microcopy/tone-of-voice), `features` (pattern feature của competitor/domain cho target feature — chỉ để tham khảo, không bao giờ mở rộng scope redesign), `flow` (pattern user-journey của competitor/domain cho target feature — chỉ để tham khảo, không bao giờ mở rộng scope redesign)
   - Cache check theo từng khía cạnh, độc lập: tìm trong `plans/reports/` file `researcher-vdesign-bold-<slug>-<aspect>*.md` đã tạo trong session/ngày hôm nay — có → tái dùng report của khía cạnh đó; không có → đánh dấu khía cạnh cần research mới
   - Spawn song song tất cả khía cạnh chưa có cache — mỗi khía cạnh 1 Task/Agent call, tối đa 8, cùng 1 message. Nhóm khía cạnh design-pattern (`ui`/`ux`/`animation`/`layout`/`3d`/`text`) mỗi agent tìm pattern hiện hành (2025-2026) đặc thù cho `<target feature>` trong bối cảnh sản phẩm `<domain>`, chỉ tập trung vào đúng 1 khía cạnh được giao — chủ động lấy từ các gallery site đoạt giải thật (Awwwards Site/Mobile/Developer of the Day và Honorable Mentions, lọc theo category khớp `<domain>` nếu gallery hỗ trợ; CSS Design Awards và Site Inspire làm nguồn thay thế khi Awwwards có ít coverage cho domain đó) thay vì chỉ đọc lại mô tả pattern trừu tượng; report pattern cụ thể có tên **kèm URL nguồn thật** (site/trang cụ thể đã nghiên cứu, không chỉ tên pattern). Agent `features`/`flow` thì tìm pattern feature hoặc flow hiện hành của competitor/domain cho `<target feature>` trong `<domain>` — nêu rõ chỉ để tham khảo context, KHÔNG phải scope cần implement; agent không được đề xuất thêm các pattern này vào redesign. Lưu mỗi report vào `plans/reports/researcher-vdesign-bold-<slug>-<aspect>-<HHMMSS>.md`
   - **Nghiên cứu visual/kỹ thuật các nguồn hàng đầu (ở tầng orchestrator, không phải research subagent — subagent không có browser tool):** sau khi Domain Research report về, nếu có browser automation (vd `claude-in-chrome`) khả dụng trong môi trường này, mở 1-3 URL nguồn giá trị nhất tìm được và (a) chụp screenshot để cảm nhận tổng thể (bố cục, phối màu, hierarchy — đánh giá mà bullet list không truyền tải nổi) và (b) chạy `getComputedStyle()` qua tool thực thi JS của browser trên 1-2 element nổi bật để lấy giá trị design-token thật, chính xác (box-shadow, border-radius, color, transition-duration/easing) — giá trị computed không bị ảnh hưởng bởi CSS production đã minify/obfuscate, khác với việc cố đọc stylesheet tải về của site đó, vốn thường không đọc được (class name bị hash, không có cấu trúc) nên không đáng để fetch. Merge các giá trị cụ thể này vào pattern-pull ở Phase 3. Nếu không có browser automation, bước này bị bỏ qua — report pattern-kèm-URL-nguồn dạng text của Domain Research vẫn là sàn bắt buộc, không phải optional.
   - Khía cạnh nào agent lỗi hoặc không khả dụng: `ui`/`ux`/`animation`/`layout`/`text` fallback im lặng về section catalog tĩnh tương ứng (Cards and Containers / Micro-Interactions / Scroll Animations / Layout and Grids / Typography and Text trong `premium-design-patterns.md`); `3d`/`features`/`flow` không có catalog tĩnh để fallback — khía cạnh đó vắng mặt hoàn toàn khỏi các bước sau, ghi nhận "unavailable" (khác với "fallback"). Các khía cạnh còn lại (cached, research mới, hoặc fallback) vẫn tiếp tục bình thường; không fail toàn bộ bước domain research chỉ vì 1 khía cạnh lỗi
7. Nếu có `--wow` → **Vibe Commitment**, trước khi đụng vào code: chốt MỘT archetype từ Vibe Archetype Catalog ở trên, một vibe tùy chỉnh từ keyword tham chiếu/mood của user, hoặc một vibe được gợi ý từ các report domain research ở step 6 (cached và/hoặc mới, tối đa 8 report — report `features`/`flow`, nếu có, chỉ dùng làm context khi chốt vibe, VD "competitor dùng flow từng bước → vibe nên hỗ trợ guided layout", và không bao giờ được dùng để mở rộng scope redesign sang feature/bước flow mới) nếu có. Nếu user không chỉ định, đề xuất archetype phù hợp nhất với domain của project và nói rõ trước khi implement — nêu rõ những khía cạnh nào đã dẫn tới lựa chọn đó và trạng thái của chúng (cached/fresh/fallback về catalog tĩnh/unavailable). Một lần chạy `--wow` không có điểm neo (chưa chốt vibe) là lý do lớn nhất khiến output vẫn đọc ra generic/an toàn.

---

### Phase 1: Scan (Duyệt Component Tree)

**BẮT BUỘC** phải trace component tree — không chỉ đọc 1 file:

```
Target component/page
  └── Import local components (level 1) → đọc
        └── Import local sub-components (level 2) → đọc
              └── Dừng ở component thuộc UI library (@etaro/ui, shadcn, MUI, Radix)
```

Với mỗi file đọc, xác định:
- Các Tailwind class đang dùng (spacing, color, typography)
- Component từ UI library: dùng đúng variant chưa? đã customize chưa?
- Layout pattern: flex/grid/absolute positioning
- Animation/transition hiện có
- Các state hiện có: loading, empty, error, hover, focus, active, disabled

**Đồng thời thu thập:**
- `tailwind.config` hoặc CSS vars (`globals.css`) → design tokens
- Tìm một component trong project đóng vai trò **tham chiếu chuẩn** — kiểm tra mục "Good reference UI" trong Project Profile trước (xem section Project Profile bên dưới); không có → suy ra từ component tinh chỉnh/nhất quán nhất trong codebase → đọc để học pattern

**Khi user nói "giống X" hoặc "tương tự X":**
→ BẮT BUỘC đọc component/page X trước khi implement — không được đoán pattern

---

### Phase 2: Audit

Đọc toàn bộ `references/audit-checklist.vi.md` và duyệt qua từng nhóm — chỉ flag các vấn đề **thực sự ảnh hưởng đến chất lượng visual/UX**. File đó cũng có lưu ý về cú pháp tuỳ framework (shorthand Tailwind/React chỉ mang tính minh họa, dịch sang stack thật của project).

<!-- Checklist đầy đủ ~100 item (Typography đến Sticky & Scroll Behavior) nằm ở references/audit-checklist.vi.md — tách ra để giữ thân skill gọn nhẹ. -->

---

### Phase 3: Fix

Fix mọi thứ Phase 2 tìm ra — spacing, state, swap component, đổi cấu trúc grid/layout, đổi hoàn toàn hướng thị giác đều nằm trong scope mặc định; không còn trần chặn độ sâu. Độ sâu vẫn phải *tương xứng* với cái thực sự hỏng: 1 finding chỉ về spacing không cho phép viết lại toàn bộ JSX (xem Anti-Patterns — "viết lại toàn bộ layout khi chỉ cần chỉnh một phần").

**`--wow` (tùy chọn)**

Tạm ngưng TOÀN BỘ dè dặt thẩm mỹ VÀ tương tác trong lần chạy này — không chỉ 3 mục liệt kê trước đây, và không chỉ mặt hình ảnh. Nghĩa là: không còn thiên hướng "rõ ràng > gây ấn tượng", không còn cấm thẩm mỹ portfolio/avant-garde, không còn dè dặt vì domain nhạy cảm (context y tế/giáo dục/trẻ em KHÔNG có nghĩa là phải giảm nhiệt — rõ ràng và accessibility được enforce riêng ở dưới như hard rule kỹ thuật, không phải phanh thẩm mỹ), và cũng không còn mặc định "giữ tương tác chuẩn/kín đáo/generic". Art direction riêng biệt, typography scale biểu cảm, layout độc đáo/bất đối xứng, motion tùy chỉnh, điểm nhấn trang trí (icon anchor, khung lồng tông nhạt — xem `references/quiet-polish-patterns.vi.md`), khoảnh khắc chọn/hoàn thành/feedback biểu cảm (xem section Motion & Interaction trong file đó) đều được cho phép trọn vẹn — 1 transition thật sự thú vị hay 1 khoảnh khắc hoàn thành đáng ăn mừng không phải "không cần thiết", đó chính là mục đích. Cái vẫn còn là sàn, không phải trần: nguyên tắc usability ở Phase 2 (đủ state bắt buộc, giới hạn số lựa chọn hiển thị theo Hick's Law, confirm chỉ cho action phá hủy) — đây là sàn usability, không phải sự dè dặt, và độ táo bạo vẫn phải vượt qua sàn này chứ không được bỏ qua nó. Cái vẫn cấm hoàn toàn: hard rule kỹ thuật bên dưới (accessibility, tech stack, logic/API, motion GPU-safe, dependency allowlist) — đó là ràng buộc an toàn/kỹ thuật, không phải giới hạn sáng tạo, và không bao giờ bị tạm ngưng.

**Vượt qua ảnh reference, không chỉ khớp nó.** Khi input có ảnh reference/target (mockup đầy tham vọng, screenshot đối thủ, hoặc concept do AI tạo — xem Input Modes) thay vì chỉ ảnh "before" cần fix, coi đó là mức cần đạt, rồi vượt qua nó ở những trục mà ảnh tĩnh về bản chất không cạnh tranh nổi: nhất quán xuyên suốt mọi màn hình trong cùng flow (không chỉ 1 màn được cho xem), motion/interaction thật (ảnh tĩnh bị đóng băng — xem section Motion & Interaction trong quiet-polish-patterns.vi.md), độ chính xác đo được (đúng lưới spacing/tỉ lệ contrast — mockup tĩnh thường có sai lệch nhỏ chưa đo mà bản triển khai thật không nên lặp lại), và responsive/accessibility thật (mockup chỉ cần đẹp ở 1 kích thước cố định). Khớp các device cụ thể của nó trước (nhóm khung, tầng màu, iconography, nước đi layout), rồi thắng ở những trục này — đừng dừng lại ở mức ngang bằng.

Bắt buộc phải có Vibe Commitment từ Phase 0 step 7 trước — chốt vibe rồi mới kéo pattern. Không được kéo pattern trước rồi mới ngụy biện ra vibe sau.

**Một điểm nhấn duy nhất, không rải rác táo bạo.** Chốt MỘT nước đi táo bạo — kỷ luật màu, custom typeface, ngôn ngữ motion, illustration style riêng, hoặc layout bất đối xứng — rồi giữ mọi thứ khác kiềm chế xung quanh nó. Táo bạo nửa vời (mỗi thứ một ít) đọc ra generic HƠN là cam kết trọn vẹn vào một thứ; đây là lý do #1 khiến output `--wow` vẫn đọc ra an toàn trong thực tế. Táo bạo phải mang tính **cấu trúc** (typography scale, contrast, motion-as-clarity, giọng điệu riêng), không bao giờ chỉ là trang trí.

Kéo pattern từ 6 pattern có tên sau (award-winning B2B, không phải portfolio/consumer):

| Pattern | Cách hoạt động | Vì sao B2B-safe |
|---|---|---|
| Strategic Accent Boldness | Nền trung tính + 1-2 điểm nhấn táo bạo đã chốt | Rõ ràng vẫn là chính; táo bạo đọc ra có chủ đích |
| Authentic Voice + Human Craft | Ảnh/illustration custom, copy chân thật, anti-stock | Tính xác thực tạo credibility, không phải trang trí |
| Bold Typography-First | Type oversized custom/variable; hierarchy chỉ qua size/weight | Táo bạo nằm ở khung xương, không phải ornament |
| High-Contrast Disciplined | Đen/trắng hoặc màu bão hòa sâu, đường dày, không gradient/blur | Sự trực tiếp đọc ra tự tin, không liều lĩnh |
| Motion-First Clarity | Mọi animation đều làm rõ (đổi state, hierarchy); tối đa 1-2 tương tác tinh vi mỗi trang | Motion tín hiệu sự tinh vi, không gây xao nhãng |
| Product-Centric Hero | UI/screenshot sản phẩm thật làm hero, không phải illustration | Tự tin + minh bạch, không phô diễn |

CSS/SVG grain-texture overlay (opacity <10%, `<feTurbulence>` hoặc CSS `filter`) cũng là một kỹ thuật `--wow` khả dụng — không cần dependency mới.

**Kéo pattern, không chỉ audit-fix.** Sau khi chốt vibe, kéo từ 6 pattern trên cộng arsenal của vibe đó — nếu `~/.claude/skills/frontend-design/references/premium-design-patterns.md` tồn tại, đọc file đó để có catalog đầy đủ (navigation, layout, card, scroll-driven animation, kinetic typography, micro-interaction); nếu không có, dùng archetype pattern trong `references/anti-slop-minimum.vi.md` thay thế. **Luôn đọc thêm `references/quiet-polish-patterns.vi.md`** — 1 tier tiết chế (khung lồng tông nhạt, icon anchor, eyebrow tag, radio-card) cho khi vibe cần sự ấm áp/tinh tế hơn là táo bạo; đây là bổ sung thường trực merge thêm vào catalog trên, không phải fallback khi catalog thiếu — cộng thêm pattern/insight domain-specific từ các report domain research nhóm design-pattern ở Phase 0 step 6 hiện có cho lần chạy này (`ui`/`ux`/`animation`/`layout`/`3d`/`text`, tối đa 6 — report `features`/`flow` không nằm trong nhóm này, chúng chỉ để tham khảo cho Vibe Commitment, không phải nguyên liệu kéo pattern). Merge tất cả với catalog tĩnh, không thay thế. Audit ở Phase 2 vẫn chạy (bắt state hỏng/a11y/responsive) nhưng dưới `--wow` nó là sàn, không phải trần — output được đánh giá bằng độ đặc trưng của điểm nhấn DUY NHẤT đã chốt, không chỉ bằng việc không còn lỗi.

**Dependency allowlist — thêm thẳng, không cần hỏi:** GSAP (+ ScrollTrigger), Motion (Framer Motion), Lenis (smooth scroll), CSS scroll-driven animation gốc / View Transitions API, Rive, Lottie — bộ công cụ chuẩn de-facto của site đoạt giải 2025-2026.
**Vẫn phải dừng lại hỏi:** React Three Fiber/Three.js (650KB+ — chỉ khi 3D thực sự là cốt lõi của concept), Barba.js, bất kỳ tool trả phí/SaaS nào ngoài Rive, custom WebGL/GLSL shader.

**Anti-slop gate trước khi báo done** — nếu `~/.claude/skills/frontend-design/references/anti-slop-rules.md` tồn tại, đọc file đó để có checklist đầy đủ; nếu không có, dùng điều kiện fail trong `references/anti-slop-minimum.vi.md` thay thế. Tối thiểu fail run nếu có: Inter/Roboto là font duy nhất, gradient tím-xanh là thẩm mỹ chủ đạo, 3+ card giống hệt nhau trong một hàng, tên/số placeholder ("John Doe", số tròn 50%/$100), copy sáo rỗng kiểu startup ("Elevate", "Seamless", "Next-Gen"), background `#000000` thuần, thiếu hover/focus state, **illustration flat stock chưa customize** (unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps không đổi palette/pose — ngang tier với gradient tím; fix theo tier: hand-drawn custom > line-art/sketch > isometric 3D > flat đã customize kỹ > geometric/abstract > bỏ illustration). **Ngoại lệ — không tính slop**: 1 icon nhỏ (≤32px) dạng line/duotone custom, đặt có chủ đích làm điểm neo trang trí (ví dụ cạnh tiêu đề), KHÔNG phải illustration stock scene — được khuyến khích, không bị flag — xem pattern Icon Anchor trong `references/quiet-polish-patterns.vi.md`.

Vẫn bắt buộc kể cả khi `--wow`: accessibility (contrast, focus ring, đầy đủ state), không migrate tech stack, không đổi logic/state/API, chỉ dùng motion GPU-safe (`transform`/`opacity` — không animate `width`/`height`/`top`/`left`; LCP mobile của B2B vốn đã sát ngưỡng, bold không được phá budget đó).

**Quy tắc cứng (áp dụng cho mọi lần chạy, kể cả `--wow`):**
- ✅ Làm việc trong tech stack hiện có — KHÔNG migrate framework
- ✅ KHÔNG phá logic/state/API — chỉ đổi presentation layer
- ✅ Ngoại lệ: fix thuộc category UX Efficiency và Content Design & Error Prevention (Phase 2) được phép chạm frontend interaction state/hooks/localStorage — xem scope carve-out dưới mục UX Efficiency. Vẫn không được đụng backend/API/data-model.
- ✅ **Đề xuất content-density không bao giờ tự áp dụng, ở bất kỳ mode nào**: nếu check "sparse/trống trải" ở Information Architecture (Phase 2) đánh dấu có data thật chưa render đáng đưa lên, gộp thành 1 danh sách đề xuất ngắn, cụ thể (tên field + vị trí sẽ đặt — không bao giờ bịa/placeholder) và trình qua `AskUserQuestion` ở Phase 4 để user chấp nhận/từ chối từng mục, trước khi thêm gì cả. Đây là quyết định content/product, không phải thẩm mỹ — luôn ở dạng đề xuất bất kể `--wow`.
- ✅ Kiểm tra `package.json` trước khi thêm dependency — trừ dependency allowlist của `--wow` ở trên, được thêm thẳng
- ✅ Khi ẩn (không xóa) → dùng opacity/visibility, không unmount
- ✅ Dùng Tailwind tokens — không hardcode hex
- ✅ Dùng mục "Good reference UI" trong Project Profile làm chuẩn tham chiếu — không có → component đẹp nhất đã có sẵn trong project
- ✅ **Responsive là bắt buộc**: mọi thay đổi layout PHẢI verify ở 3 viewport — mobile (375px), tablet (768px), desktop (1280px); viết mobile-first, rồi override bằng sm:/lg:
- ✅ Component styled bởi bên thứ ba (có `import 'lib/*.css'`) bọc trong wrapper div → wrapper sở hữu TOÀN BỘ visual state (border, ring, disabled opacity); null hết border/shadow bên trong component qua override CSS var + scoped `!important`
- ✅ **Kỷ luật ARIA**: ưu tiên native HTML (`<button>`, `<dialog>`, `<details>`, `<label for>`) hơn ARIA. Chỉ thêm `role`/`aria-*` khi native HTML không diễn đạt được tương tác, và khi đã thêm phải đảm bảo đủ bộ role+state+property — không bao giờ thêm ARIA attribute "phòng khi"
- ❌ KHÔNG thêm animation phức tạp nếu Motion/Framer chưa có sẵn trong project — ngoại lệ: dưới `--wow`, áp dụng dependency allowlist ở trên thay vì rule này
- ❌ KHÔNG thêm màu brand mới — chỉ dùng token hiện có (ngoại lệ: `--wow` được phép thêm accent mới nếu vibe đã chốt yêu cầu)
- ❌ KHÔNG dùng màu mặc định của component library (shadcn blue) nếu project đã có màu primary riêng
- ❌ KHÔNG thêm toast notification không cần thiết (ngoại lệ: dưới `--wow`, 1 khoảnh khắc ăn mừng/hoàn thành có chủ đích, nằm trong vibe đã chốt, KHÔNG tính là "không cần thiết" — tiêu chí là có chủ đích hay không, không phải có tối giản hay không)
- ❌ KHÔNG đổi logic/API/state management

---

### Phase 4: Verify

1. Nếu ban đầu có URL/localhost → chụp screenshot sau khi fix, so sánh before/after
2. Nếu có ảnh input → verify code có khớp ý đồ của ảnh không
3. Chạy `pnpm format` (nếu project có)
4. **Verify accessibility**: nếu project đã có (hoặc user cho phép thêm) `@axe-core/playwright` hoặc `axe-core` thường, chạy một script ngắn nhắm vào route/component đang audit và in ra violations. Nếu không có sẵn, in ra lệnh manual-check tương đương để user tự chạy — review visual/manual thủ công không được là verification duy nhất cho accessibility.
5. Nếu bạn vừa edit trực tiếp một file ảnh dưới `public/` (ghi đè cùng path, tên không đổi) và user báo "không thấy thay đổi" → đừng vội sửa code/ảnh lần nữa; báo user hard-refresh hoặc xóa `.next/cache/images` + restart dev server trước — Next.js Image Optimizer cache theo URL+size, không theo nội dung file, nên fix nhiều khả năng đã đúng nhưng vẫn đang serve bản cache cũ
6. **Adversarial Verify** (subagent — chỉ khi Fix thực sự đụng structural/JSX-level: swap component, đổi cấu trúc grid/layout, đổi hướng thị giác — HOẶC có dùng `--wow` — HOẶC fix thuộc category UX Efficiency / Content Design & Error Prevention có chạm frontend state/interaction logic): spawn 1 subagent mới hoàn toàn, đưa diff, checklist audit của Phase 2, và (nếu `--wow`) anti-slop gate. Subagent tự audit lại state cuối cùng một cách độc lập — không tiếp cận reasoning của lần chạy này — và báo PASS hoặc list vấn đề còn sót (audit item vẫn hỏng, fix vượt quá cái thực sự cần, vi phạm anti-slop). Có vấn đề → quay lại Phase 3 fix, chạy lại bước này 1 lần. Mirror theo đúng Phase 4 Adversarial Pass của `vreview` trong cùng bộ skill này.
7. **Self-Check** (inline, mọi lần chạy, không cần subagent): trước khi viết báo cáo ngắn, xác nhận — (a) độ sâu fix tương xứng với cái Phase 2 thực sự tìm ra, không có rewrite ngoài yêu cầu; (b) mọi category Phase 2 áp dụng được đã xử lý hoặc đánh dấu rõ not-applicable; (c) nếu có `--wow`, anti-slop gate (kể cả illustration check) đã thực sự được kiểm tra, không chỉ ngầm hiểu.
8. **Đề xuất content-density** (chỉ khi check sparse/trống trải ở Phase 2 có đánh dấu): trước báo cáo ngắn, trình danh sách đã gộp qua `AskUserQuestion` — mỗi item là 1 field/data point thật chưa render, mỗi item được chấp nhận/từ chối độc lập. Không bao giờ thêm bất kỳ item nào vào code khi chưa có câu trả lời rõ ràng của user ở đây, bất kể mode.
9. **Báo cáo ngắn gọn**: "Đã redesign [X]. Thay đổi chính: [liệt kê 3-5 bullet points]"
   - Không summary dài
   - Chỉ nêu các thay đổi đáng kể
   - Nếu có chạy `--wow`: thêm 1 dòng trạng thái theo từng khía cạnh (đủ 8) của Phase 0 step 6, cộng kết quả PASS/có-vấn-đề của Adversarial Verify — VD "ui: fresh, ux: cached, animation: fallback (agent không khả dụng), layout: fresh, 3d: unavailable, text: cached, features: fresh, flow: unavailable; Adversarial Verify: PASS"

---

## Project Profile

Xác định theo thứ tự này trước Phase 1:
1. `.vdesign/profile.md` tại git root của project đích — nếu có, đọc và dùng luôn.
2. Không có → suy luận từ dependency trong `package.json`, `tailwind.config.*`, và thư mục components.
3. Vẫn mơ hồ → hỏi 1 câu, rồi đề nghị (không ép) lưu câu trả lời vào `.vdesign/profile.md` cho lần sau.

### Ví dụ — Project Profile của eTARO (chỉ minh họa hình dạng, không phải mặc định)

| Ràng buộc | Chi tiết |
|------------|----------|
| UI library | `@etaro/ui` (packages/ui) + shadcn/ui — luôn dùng trước khi viết raw HTML |
| Design tokens | CSS vars trong `globals.css` — không thêm màu mới |
| Motion library | Magic UI + Framer Motion đã có sẵn — dùng được cho micro-animation |
| Context | B2B Healthcare: **rõ ràng > gây ấn tượng**, **đơn giản > sáng tạo** |
| UI tham chiếu tốt | Booking form, trang Sessions, Notes UI — học pattern từ đây |
| Font | Theo config hiện có — không đổi |
| Form field | BẮT BUỘC dùng `FormTextField`, `FormSelectField`, v.v. — không viết boilerplate raw |

---

## Anti-Patterns (KHÔNG được làm)

- ❌ Viết lại toàn bộ layout khi chỉ cần "chỉnh" một phần
- ❌ Thêm animation lòe loẹt cho app healthcare (trừ khi `--wow` đang bật — xem câu suspend ở Phase 3; rule motion GPU-safe vẫn áp dụng)
- ❌ Copy design sáng tạo từ landing page/portfolio vào product UI (trừ khi `--wow` đang bật — xem câu suspend ở Phase 3)
- ❌ Đổi màu brand chỉ vì "đẹp hơn" — chỉ dùng token
- ❌ Hỏi user trước khi đọc code — scout trước, chỉ hỏi khi thực sự cần
- ❌ Fix padding nhưng làm hỏng responsiveness
- ❌ Báo "xong" mà không verify qua screenshot (khi có URL)
- ❌ Dùng trơ `grid-cols-2` hoặc `grid-cols-3` không có collapse cho mobile (`grid-cols-1 sm:grid-cols-2`)
- ❌ Dùng width cố định (`w-[320px]`) không có responsive fallback
- ❌ Ẩn element bằng `hidden sm:block` mà không có phương án thay thế cho mobile
- ❌ Action chỉ hover (`group-hover:opacity-100`) không có fallback hiển thị trên mobile
- ❌ Modal/Dialog height cố định trên mobile — gây tràn content
- ❌ Element fixed đáy không có `pb-safe` / `env(safe-area-inset-bottom)`
- ❌ Ảnh dùng `objectPosition` mặc định khi subject bị crop mất trên mobile
- ❌ Animate opacity của component con — chỉ container
- ❌ Unmount component để ẩn nó — dùng CSS visibility/opacity nếu cần giữ state
- ❌ Dùng raw HTML element thay vì component `@etaro/ui`
- ❌ Dùng màu mặc định của shadcn/MUI khi project đã có token màu primary riêng
- ❌ Thêm toast notification không cần thiết (trừ khi `--wow` đang bật và đó là khoảnh khắc ăn mừng/hoàn thành có chủ đích — xem câu suspend ở Phase 3)
- ❌ Để scrollbar ăn vào chiều rộng content — luôn dùng overlay/transparent scrollbar
- ❌ Style tab không nhất quán trong cùng một trang — kiểm tra tính nhất quán tab xuyên component
- ❌ Đoán pattern của component "giống X" — BẮT BUỘC đọc X trước
- ❌ `float` / `shape-outside` bên trong container `flex` hoặc `grid` — không có tác dụng, browser âm thầm bỏ qua (không error, không warning), gây layout hỏng khó hiểu
- ❌ Overlay trang trí (shine border, border beam, floating badge, glow) không có `z-index` tường minh — sibling có `position: relative` xuất hiện sau trong DOM sẽ đè lên nó do stacking theo thứ tự DOM khi `z-index: auto`
- ❌ Ảnh full-bleed dùng `object-contain` mà không khớp `aspect-ratio` của container với tỉ lệ thực tế của file ảnh — bị letterbox hai bên dù container đã full width
- ❌ Chỉ set `h-full` trên wrapper của grid item mà quên set luôn trên khung visual bên trong (border/bg/shadow) — card vẫn lệch chiều cao dù grid đã stretch item bằng nhau
- ❌ Ép `line-clamp`/height cố định lên copy có độ dài khác nhau giữa các card song song thay vì cân bằng lại độ dài text — line-clamp chỉ là band-aid, cân bằng lại copy mới là fix gốc thực sự cho "sự hài hòa"
- ❌ Chạy `--wow` mà không chốt vibe trước (Phase 0 step 7) — bold không có điểm neo vẫn đọc ra là generic/an toàn; chọn pattern trước khi chọn hướng chỉ tạo ra một mớ hổ lốn, không phải một thiết kế mạch lạc
- ❌ Research lại một khía cạnh đã có cache trong session/ngày cho cùng domain-slug (Phase 0 step 6) — kiểm tra `plans/reports/` theo từng khía cạnh trước, chỉ khía cạnh chưa có cache mới spawn agent mới
- ❌ Trộn nhiều giá trị font-size/spacing/border-radius hơn mức cho phép mà không bám theo scale nào — giá trị lẻ tùy tiện phá vỡ sự hài hòa tỷ lệ
- ❌ Surface phẳng lì 1 tier duy nhất khắp trang, không có phân biệt elevation — mọi thứ đọc ra cùng 1 độ sâu thị giác
- ❌ Shadow quá tay/skeuomorphic trong bối cảnh B2B — sửa quá đà từ phẳng sang rối mắt
- ❌ List/table chỉ có action từng-cái-một, không có bulk/multi-select khi action đó đáng lẽ batch được
- ❌ Confirm dialog cho action reversible, rủi ro thấp — nên dùng undo thay vì confirm
- ❌ Label button chung chung ("Submit", "OK") khi có thể dùng label cụ thể theo outcome
- ❌ Validate 1 field mỗi lần gõ phím thay vì khi blur — gây nhấp nháy error message lúc đang gõ
- ❌ Tái dùng giá trị shadow/contrast của light mode cho dark mode mà không re-verify
- ❌ Chôn thông tin/action ưu tiên cao nhất dưới fold trên dashboard dày đặc
- ❌ Chọn density row của table tùy tiện thay vì khớp với đối tượng user thật (casual vs power-user)

## Bước tiếp theo

Nhìn vào kết quả thực tế của lần chạy này và tự đề xuất MỘT hành động tiếp theo hợp lý, 1-2 câu — không chọn theo danh sách cố định. Cân nhắc các skill khác trong bộ này (vspecs, vplan, vcook, vreview, vfix, vci, vtickets, vdesign, vlearn, vrollback) nếu thực sự phù hợp; nếu không cần gì thêm thì nói rõ luôn.
