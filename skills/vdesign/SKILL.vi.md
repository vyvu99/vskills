---
name: vdesign
description: "Redesign UI/UX hiện có với chất lượng thực thi cao: tinh tế, hài hòa, hiện đại, thanh lịch, accessible. Mọi lần chạy tự quyết đủ 18 tiêu chí phong cách/cấu trúc (typography, màu, motion, layout, tự do cấu trúc, độ táo bạo, và nhiều hơn nữa) — không hỏi trước — dựa trên research thiết kế 2026 luôn chạy sống và 1 lần đọc real user/task, với tự do sáng tạo + tự do sửa API-layer đầy đủ (DB schema vẫn cấm). Dùng khi nâng cấp UI của một trang/component/feature/PR đã có sẵn."
user-invocable: true
when_to_use: "Kích hoạt khi bạn muốn redesign hoặc nâng cấp UI/UX của một trang, component, feature, hoặc toàn bộ diff/PR hiện có."
argument-hint: "[URL | localhost:PORT/path | component | feature | --pr | --diff | [Image]]"
metadata:
  author: vyvu
  version: "9.0.0"
---

# vdesign — Skill Redesign UI/UX Cá Nhân

Nâng cấp hoặc redesign UI/UX đạt chuẩn thực thi cao — **tinh tế · hài hòa · hiện đại · thanh lịch · accessible** — còn phong cách thật (táo bạo hay tiết chế, khớp hệ thống hiện có hay cố tình tách khỏi nó) tự quyết lại mỗi lần chạy từ research sống và real user/task, không bao giờ hỏi và không bao giờ giả định theo thói quen.

Không còn flag mức độ, không còn toggle `--wow`, không còn Q&A phong cách đầu run. `vdesign <target>` là mode duy nhất — audit-driven: sửa mọi thứ Phase 2 tìm ra, bất kể độ sâu (spacing → cấu trúc → đổi hướng thị giác). Mọi lần chạy đều mở đầu bằng việc Phase 0 tự quyết đủ 18 tiêu chí phong cách/cấu trúc (typography, màu, motion, shape, layout, tự do cấu trúc, độ táo bạo, và nhiều hơn nữa — xem `references/aesthetic-customization.vi.md`), dựa trên Domain Research sống của lần chạy này và bước đọc real user/task (Phase 1 Bước 1), không hỏi. Không còn trần chặn, không còn kiểu "tìm ra rồi nhưng không fix được vì sai mức".

Không migrate tech stack. Không đổi DB schema hay chạy migration. Thay đổi API/service layer thì nằm trong phạm vi khi redesign thực sự cần.

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

## Gu Thẩm Mỹ Cá Nhân (Sàn Chất Lượng)

Đây là từ vựng của user cho chất lượng thực thi — **TẤT CẢ** đều giữ ở mọi lần chạy, bất kể Phase 0 tự quyết ra gì. Chúng chi phối *thực thi tốt đến đâu*, không phải *chọn hướng nào*:

| Từ khóa | Ý nghĩa thực tế trong code |
|---------|--------------------------|
| **Tinh tế (Refined)** | Chi tiết nhỏ đúng chỗ: border-radius nhất quán, icon size đều nhau, text-overflow được xử lý, không có giá trị spacing scale lẻ |
| **Hài hòa (Harmonious)** | Hướng nào Phase 0 đã chốt (khớp hệ thống hiện có hay cố tình tách khỏi nó) được áp dụng nhất quán — không có "ốc đảo cô lập" style tùy tiện trong chính hướng đó; font-size/spacing/component-size theo modular scale/tỷ lệ nhất quán, không dùng giá trị tùy tiện |
| **Hiện đại (Modern)** | Không dùng pattern lỗi thời (table viền kiểu cũ, form label kiểu cũ, button phẳng không có state); tận dụng tốt whitespace |
| **Thanh lịch (Elegant)** | Hierarchy rõ ràng, ít nhiễu thị giác, không trang trí thừa, phân cấp button rõ ràng (primary/ghost/link) |
| **Chiều sâu (Deep)** | Elevation tier rõ ràng, shadow/border/light-source nhất quán — không bao giờ phẳng lì vô hồn, không bao giờ skeuomorphic (trừ khi quyết định Elevation & Shadow rơi tường minh vào flat/monochromatic — thì phẳng nhất quán, không phải phẳng do sơ suất) |
| **Đúng với Design Brief** | Khớp với đúng cái Phase 0 đã tự quyết và chốt — design token và ngôn ngữ thị giác hiện có của project khi đó là quyết định, một hướng cố tình mới khi đó là quyết định. Thực thi nửa vời phiên bản nào cũng đọc ra cẩu thả, không phải tinh tế |
| **Accessible** | Thông tin không bị ẩn; label rõ ràng; icon quan trọng có tooltip; đầy đủ state empty/loading/error |
| **Tiện dụng (Efficient)** | Tối thiểu thao tác/click: bulk action, inline-edit, smart default khi an toàn |

**KHÔNG** áp dụng thẩm mỹ táo bạo hơn hoặc bảo thủ hơn cái Design Brief tự quyết ở Phase 0 đã thực sự chốt — Design Brief là hợp đồng, không phải gợi ý để lái theo thói quen cá nhân theo hướng nào.

---

## Workflow: Scan → Audit → Fix → Verify

### Phase 0: Xác định phạm vi

1. Parse argument để xác định input mode (xem bảng trên)
2. URL/localhost → **chụp screenshot ngay** bằng bất kỳ screenshot tool nào khả dụng (Playwright MCP, browser tool, v.v.); không có tool nào khả dụng → hỏi user paste screenshot trực tiếp
3. `--pr` → xác định VCS profile theo `~/.claude/skills/_vskills-shared/repo-profile.md` §2 trước (file không tồn tại → coi như full gh mode, đúng hành vi mặc định hiện tại). Full gh mode → `gh pr diff --name-only` để lấy danh sách file. Degraded (thiếu gh / không phải GitHub) → in thông báo §2 và hỏi tên branch, hoặc fallback sang `--diff` (`git diff --name-only`, không cần gh) — rồi tiếp tục vào Phase 1 bình thường.
4. Xác định Project Profile: kiểm tra `.vdesign/profile.md` tại git root của project đích (`git rev-parse --show-toplevel`). Có → đọc và dùng luôn. Không có → suy luận UI library/design tokens từ dependency trong `package.json`, `tailwind.config.*`, và cấu trúc thư mục components. Vẫn mơ hồ → hỏi 1 câu, rồi đề nghị (không ép) lưu câu trả lời vào `.vdesign/profile.md` cho lần sau.
5. Rỗng → hỏi user qua `AskUserQuestion` — **đúng 1 câu**: "Bạn muốn redesign phần nào?"
6. **Domain Research** — luôn luôn, mọi lần chạy, không cần flag, không bị gate bởi tiêu chí nào (đây là nguồn chân lý duy nhất cho mọi pattern được kéo ở Phase 3 — xem "Cách vdesign tự quyết" trong `references/aesthetic-customization.vi.md` để biết đủ taxonomy 18 tiêu chí mà bước này nuôi, tự quyết chứ không hỏi):
   - **Nguồn uy tín thắng SEO rank** — lấy từ gallery/nguồn có curation/giám khảo thật (Awwwards, CSS Design Awards, Site Inspire, case study thật của 1 design studio, mục "Featured" của Behance/Dribbble), không bao giờ lấy từ kết quả blog SEO-rank chung chung. Khi Design Brief (step 7) rơi vào *Game-inspired/Arcade* → ưu tiên nguồn chuyển sang gallery chuyên game UI (Dribbble tag "game UI", GameUIDatabase.com, Behance HUD design) thay vì Awwwards — category Game của Awwwards khá mỏng so với các category thường.
   - Domain slug = domain từ context của Project Profile (ví dụ "B2B Healthcare") + tên feature/trang đích đã resolve ở step 1 (ví dụ "booking form") — slugify (ví dụ `healthcare-booking-form`)
   - Danh sách khía cạnh cố định, luôn đủ 8: `ui` (UI/Visual), `ux` (UX/Interaction), `animation` (Animation/Motion), `layout` (Layout/Responsive), `3d` (pattern 3D/WebGL/spatial-depth), `text` (pattern Typography/microcopy/tone-of-voice), `features` (pattern feature của competitor/domain cho target feature — chỉ để tham khảo, không bao giờ mở rộng scope redesign), `flow` (pattern user-journey của competitor/domain cho target feature — chỉ để tham khảo, không bao giờ mở rộng scope redesign)
   - Cache check theo từng khía cạnh, độc lập: tìm trong `plans/reports/` file `researcher-vdesign-bold-<slug>-<aspect>*.md` đã tạo trong session/ngày hôm nay — có → tái dùng report của khía cạnh đó; không có → đánh dấu cần research mới
   - Spawn song song tất cả khía cạnh chưa có cache — mỗi khía cạnh 1 Task/Agent call, tối đa 8, cùng 1 message. Nhóm khía cạnh design-pattern (`ui`/`ux`/`animation`/`layout`/`3d`/`text`) mỗi agent tìm pattern hiện hành (2025-2026) đặc thù cho `<target feature>` trong bối cảnh sản phẩm `<domain>`, chỉ tập trung vào đúng 1 khía cạnh được giao, theo đúng nguyên tắc nguồn uy tín ở trên — report pattern cụ thể có tên **kèm URL nguồn thật** (site/trang cụ thể đã nghiên cứu, không chỉ tên pattern). Agent `features`/`flow` thì tìm pattern feature hoặc flow hiện hành của competitor/domain cho `<target feature>` trong `<domain>` — nêu rõ chỉ để tham khảo context, KHÔNG phải scope cần implement; agent không được đề xuất thêm các pattern này vào redesign. Lưu mỗi report vào `plans/reports/researcher-vdesign-bold-<slug>-<aspect>-<HHMMSS>.md`
   - **Nghiên cứu visual/kỹ thuật các nguồn hàng đầu (ở tầng orchestrator, không phải research subagent — subagent không có browser tool):** sau khi Domain Research report về, có browser automation (vd `claude-in-chrome`) khả dụng → mở 1-3 URL nguồn giá trị nhất tìm được và (a) chụp screenshot để cảm nhận tổng thể (bố cục, phối màu, hierarchy — đánh giá mà bullet list không truyền tải nổi) và (b) chạy `getComputedStyle()` qua tool thực thi JS của browser trên 1-2 element nổi bật để lấy giá trị design-token thật, chính xác (box-shadow, border-radius, color, transition-duration/easing) — giá trị computed không bị ảnh hưởng bởi CSS production đã minify/obfuscate, khác với việc đọc stylesheet tải về của site đó, vốn thường không đọc được (class name bị hash, không có cấu trúc) nên không đáng để fetch. Merge các giá trị này vào pattern-pull ở Phase 3. Không có browser automation → bước này bị bỏ qua — report pattern-kèm-URL-nguồn dạng text của Domain Research vẫn là sàn bắt buộc, không phải optional.
   - Khía cạnh nào agent lỗi: retry 1 lần. Vẫn lỗi (hoặc `3d`/`features`/`flow` thật sự không khả dụng) → bỏ qua khía cạnh đó, ghi "unavailable" vào Design Brief (step 7) — không bao giờ chặn cả bước này và không bao giờ fallback về pattern cứng (không còn catalog tĩnh nào nữa). Các khía cạnh còn lại (cached, research mới, hoặc ghi unavailable) vẫn tiếp tục bình thường.
7. **Design Brief** — trước khi đụng vào code: tự quyết đủ 18 tiêu chí từ `references/aesthetic-customization.vi.md` (Thứ tự ưu tiên ở đó: Domain Research của lần chạy này > Project Profile > bước đọc Real User & Purpose ở Phase 1 Bước 1 > Personal Aesthetic Quality Floor) cộng bước đọc persona/task ở Phase 1 Bước 1, rồi tổng hợp thành 1 brief cụ thể 5-10 dòng (xem section Design Brief trong file đó) — tên typeface thật, cách tiếp cận bảng màu thật, timing motion thật, hướng shape/icon/imagery thật, spacing scale thật, hệ thống layout thật, tone thật, mức độ táo bạo thật. Một nhãn-một-từ cho mỗi tiêu chí không phải là brief. Nói rõ ra, ghi 18 quyết định + Design Brief đã tổng hợp vào `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` trước khi Phase 1 bắt đầu, nêu trạng thái step 6 theo từng khía cạnh (cached/fresh/unavailable). Phase 3 đọc lại file này trước khi thực thi, thay vì dựa vào trí nhớ hội thoại. Một lần chạy không tổng hợp (18 quyết định thô, chưa chốt brief) là lý do lớn nhất khiến output vẫn đọc ra generic/an toàn.

---

### Phase 1: Scan

**Bước 1 — Real User & Purpose:** trước khi trace bất kỳ component nào, đọc đúng shape data thật đang chảy vào page/component này — prop types/interface, query/hook/server action nó gọi, và response type hoặc Zod schema của lời gọi đó (đọc type thật, không suy đoán shape field từ những gì đang render) — và kiểm tra xem DB schema backing nó (khi tiếp cận được: file schema Drizzle/Prisma, migration) có field nào chưa từng được fetch không (nuôi cho check Sparse/under-filled ở Phase 2). Rồi đặt mình vào đúng persona thực tế dùng màn hình này — vai trò, mục tiêu task, bối cảnh (gấp hay không, thiết bị, tần suất, trình độ) — suy ra từ tên route/component cộng context của Project Profile (vd "B2B Healthcare: clarity > impressiveness"). Từ đó, phát biểu cụ thể: field/action nào phải nổi bật, cái gì là nhiễu đáng cắt, và cấu trúc hiện tại (table, card grid, list, detail panel, form, kanban board, timeline, masonry/bento grid, split master-detail, calendar/heatmap, comparison matrix, tree/outline, carousel/feed — và nhiều hơn nữa, chọn theo đúng cấu trúc data và task thật sự cần) có thực sự khớp việc persona này đang làm hay đang ép ra 1 hình dạng gượng gạo. Đây là cổng duy nhất quyết định tự do cấu trúc (xem Vòng 0 trong `references/aesthetic-customization.vi.md`): được đổi cấu trúc bất cứ khi nào nó thực sự phục vụ task thật — không bị chặn bởi "tương xứng với cái audit tìm ra" riêng cho các nước đi cấu trúc — nhưng mọi lần đổi cấu trúc phải trace được về 1 lý do cụ thể nêu ở đây, không bao giờ "vì có thể đẹp hơn". Ghi persona, task, và 2-3 quyết định IA kết quả vào `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` cùng với Design Brief, để Phase 3/4 verify dựa vào đó. Audit không có nền tảng này vẫn có nguy cơ đánh bóng sai cấu trúc.

**Bước 2 — Duyệt Component Tree:** trace component tree — không chỉ đọc 1 file:

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

**Bước 3 — Khi user nói "giống X" hoặc "tương tự X":**
→ BẮT BUỘC đọc component/page X trước khi implement — không được đoán pattern

**Bước 4 — Component Inventory (chỉ khi target là cả trang/URL có từ 2 cụm component trở lên; bỏ qua với target là 1 component đơn lẻ hoặc PR diff — những target đó giữ nguyên flow Fix cũ, 1 lượt duy nhất ở Phase 3):** liệt kê mọi INSTANCE component hiển thị trên trang thành 1 danh sách đánh số — không chỉ liệt kê theo loại (3 stat card là 3 dòng riêng, không phải 1 mục "stat card"). Gom nhóm instance liền kề nhau trong render tree, cùng vai trò thị giác/cấu trúc, thành cụm (vd 3 stat card xếp hàng = 1 cụm; data table bên dưới = 1 cụm riêng; nav = cụm riêng của nó). Ghi danh sách này, kèm checkbox cho từng instance, vào `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` dưới 1 section mới `## Component Inventory` — Phase 3 chọn cụm pilot từ đây, Phase 4 verify mọi checkbox đã được xử lý trước khi báo cáo xong.

---

### Phase 2: Audit

Đọc toàn bộ `references/audit-checklist.vi.md` và duyệt qua từng nhóm — chỉ flag các vấn đề **thực sự ảnh hưởng đến chất lượng visual/UX**. File đó cũng có lưu ý về cú pháp tuỳ framework (shorthand Tailwind/React chỉ mang tính minh họa, dịch sang stack thật của project).

<!-- Checklist đầy đủ ~150 item (Typography đến Sticky & Scroll Behavior) nằm ở references/audit-checklist.vi.md — tách ra để giữ thân skill gọn nhẹ. -->

Ghi toàn bộ danh sách findings (item đã check/đã flag, cộng danh sách ứng viên content-density) vào cùng file `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` (append thêm section `## Audit Findings`) trước khi Phase 3 bắt đầu. Khi Component Inventory ở Phase 1 đã chạy, gắn thêm cho mỗi finding thuộc cụm nào (từ danh sách inventory) để Phase 3 biết cụm nào có nhiều finding nhất.

---

### Phase 3: Fix

**Pilot cụm trước, rồi mới lan rộng (chỉ khi Component Inventory ở Phase 1 đã chạy — target là cả trang/URL có ≥2 cụm). Target là 1 component đơn lẻ hoặc PR diff thì không có Component Inventory — đi thẳng vào "Fix mọi thứ Phase 2 tìm ra" bên dưới, áp dụng 1 lượt cho toàn bộ target, không có bước pilot.**

1. Chọn cụm được gắn nhiều finding nhất từ Phase 2 làm pilot — hòa thì chọn cụm xuất hiện trước trong danh sách Component Inventory.
2. Redesign sâu riêng cụm pilot — toàn bộ nội dung bên dưới trong section Phase 3 này (thực thi Design Brief, boldness pattern, hard rule, anti-slop gate) áp dụng đầy đủ cho cụm này.
3. Trình cụm pilot cho user duyệt trước khi đụng tới bất kỳ component nào khác trong inventory: URL/localhost → chụp screenshot, show before/after; không có → mô tả cách xử lý cụ thể (màu, spacing, motion) và show diff code của riêng cụm pilot. Hỏi qua `AskUserQuestion`: duyệt / chỉnh sửa (user nêu rõ muốn đổi gì) / thử hướng khác.
4. Chỉnh sửa hoặc đổi hướng → làm lại pilot theo feedback đó, trình lại. Cap 3 vòng — quá 3 vòng thì hỏi "duyệt kèm bất đồng đã nêu, hay dừng lại".
5. Sau khi duyệt: lan CÙNG ngôn ngữ thiết kế (màu, elevation, radius, spacing scale, motion — không copy y hệt giá trị) cho từng item còn lại trong Component Inventory, tick từng cái khi xong. Component khác loại với pilot vẫn giữ đúng pattern riêng của nó (table vẫn là table, form vẫn là form) chỉ restyle theo ngôn ngữ đó, không ép theo đúng hình dạng của pilot.
6. Cập nhật checkbox Component Inventory trong `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` khi từng item hoàn tất — Phase 4 verify dựa vào đây.

**Đổi ý giữa chừng cho 1 tiêu chí.** Phase 3 phát hiện 1 quyết định tự quyết ở Phase 0 không còn phù hợp (vd đã chốt *Giữ token hiện có* nhưng giờ có gap thật cần thêm accent màu mới) → không cần hỏi, chỉ cần tự quyết lại đúng tiêu chí đó theo cùng Thứ tự ưu tiên quyết định (`references/aesthetic-customization.vi.md`), cập nhật lại dòng tổng hợp của tiêu chí đó trong file Design Brief kèm lý do mới, tiếp tục Phase 3 từ chỗ đang dừng. Ghi mọi lần đổi ý vào báo cáo cuối để user thấy cái gì đã đổi và vì sao.

Fix mọi thứ Phase 2 tìm ra — spacing, state, swap component, đổi cấu trúc grid/layout, đổi hoàn toàn hướng thị giác đều nằm trong scope mặc định; không còn trần chặn độ sâu. Độ sâu vẫn phải *tương xứng* với cái thực sự hỏng: 1 finding chỉ về spacing không cho phép viết lại toàn bộ JSX (xem Anti-Patterns — "viết lại toàn bộ layout khi chỉ cần chỉnh một phần"). Điều này áp dụng cả chiều ngược lại — 1 layout thật sự chung chung/lặp lại (mọi section render giống hệt nhau bất kể nó thực sự chứa/làm gì) tự nó là 1 finding ở tầm cấu trúc (View-type fit của Information Architecture, silent-drift check của Proportion & Scale Harmony), không phải hình dạng cần giữ nguyên vì thận trọng; đổi cấu trúc để mỗi section khớp với nội dung thật của nó mới là fix *tương xứng* ở đây, không phải 1 rewrite không ai yêu cầu. Riêng thay đổi cấu trúc/view-type theo đúng bước đọc Real User & Purpose ở Phase 1 Bước 1, không theo trần "tương xứng" này (xem Vòng 0 trong `references/aesthetic-customization.vi.md`): đổi cấu trúc bất cứ khi nào nó thực sự phục vụ task thật mà bước đọc đó phát hiện ra, không có trần "tương xứng với audit" cho riêng nước đi cấu trúc — nhưng vẫn phải trace được về lý do cụ thể đó, không bao giờ chỉ vì audit thấy có vấn đề fit đáng nhắc tới.

**Thực thi Design Brief.** Design Brief tự quyết ở step 7 Phase 0 — không phải 1 flag, không phải câu trả lời của user — quyết định lần chạy này táo bạo hay tiết chế đến đâu, dựa trên Domain Research của lần chạy này và bước đọc Real User & Purpose ở Phase 1 Bước 1. Brief rơi vào *Experimental/bold* hoặc *Trend-forward* → art direction riêng biệt, typography scale biểu cảm, layout độc đáo/bất đối xứng, motion tùy chỉnh, điểm nhấn trang trí, khoảnh khắc chọn/hoàn thành/feedback biểu cảm đều chính đáng — 1 transition thật sự thú vị hay 1 khoảnh khắc hoàn thành đáng ăn mừng không phải "không cần thiết", đó chính là cái brief đòi hỏi. Brief rơi vào *Brand-centric/cohesive* hoặc *Functional/minimalist* → giữ tiết chế và bám sát hệ thống hiện có. Tiết chế không có nghĩa là chỉ audit-fix — checklist đầy đủ của Phase 2 (thứ bậc typography, elevation/depth, cân đối tỷ lệ, nội dung dư thừa/lỗi thời) vẫn dẫn dắt Phase 3 trên mọi component trong phạm vi, chỉ là thực thi không kèm động tác trang trí; 1 component không có bug chức năng nào vẫn có thể fail các check này và cần restyle. Dù hướng nào: cái vẫn còn là sàn, không phải trần: nguyên tắc usability ở Phase 2 (đủ state bắt buộc, giới hạn số lựa chọn hiển thị theo Hick's Law, confirm chỉ cho action phá hủy) — độ táo bạo vẫn phải vượt qua sàn này chứ không được bỏ qua nó. Cấm hoàn toàn bất kể brief là gì: hard rule kỹ thuật bên dưới (accessibility, tech stack, đổi DB schema/migration, motion GPU-safe) — ràng buộc an toàn/kỹ thuật, không phải lựa chọn thẩm mỹ, không quyết định nào ở trên đụng vào được.

**Vượt qua ảnh reference, không chỉ khớp nó.** Input có ảnh reference/target (mockup đầy tham vọng, screenshot đối thủ, hoặc concept do AI tạo — xem Input Modes) thay vì chỉ ảnh "before" cần fix → coi đó là mức cần đạt, rồi vượt qua nó ở những trục mà ảnh tĩnh về bản chất không cạnh tranh nổi: nhất quán xuyên suốt mọi màn hình trong cùng flow (không chỉ 1 màn được cho xem), motion/interaction thật (ảnh tĩnh bị đóng băng — finding về motion pattern hiện hành của Domain Research lần chạy này là nguồn cho việc này, không phải catalog tĩnh), độ chính xác đo được (đúng lưới spacing/tỉ lệ contrast — mockup tĩnh thường có sai lệch nhỏ chưa đo mà bản triển khai thật không nên lặp lại), và responsive/accessibility thật (mockup chỉ cần đẹp ở 1 kích thước cố định). Khớp các device cụ thể của nó trước (nhóm khung, tầng màu, iconography, nước đi layout), rồi thắng ở những trục này — đừng dừng lại ở mức ngang bằng.

Bắt buộc phải có Design Brief từ Phase 0 step 7 trước — chốt brief rồi mới kéo pattern. Không được kéo pattern trước rồi mới ngụy biện ra brief sau.

**Khi brief đòi táo bạo: một điểm nhấn duy nhất, không rải rác táo bạo.** Chốt MỘT nước đi táo bạo — kỷ luật màu, custom typeface, ngôn ngữ motion, illustration style riêng, hoặc layout bất đối xứng — rồi giữ mọi thứ khác kiềm chế xung quanh nó. Táo bạo nửa vời (mỗi thứ một ít) đọc ra generic HƠN là cam kết trọn vẹn vào một thứ; lý do #1 khiến output táo bạo vẫn đọc ra an toàn trong thực tế. Táo bạo phải mang tính **cấu trúc** (typography scale, contrast, motion-as-clarity, giọng điệu riêng), không bao giờ chỉ là trang trí.

CSS/SVG grain-texture overlay (opacity <10%, `<feTurbulence>` hoặc CSS `filter`) cũng là một kỹ thuật khả dụng khi brief đòi hỏi — không cần dependency mới.

**Kéo pattern chỉ từ Domain Research của chính lần chạy này, không bao giờ từ catalog tĩnh.** Sau khi chốt Design Brief, kéo pattern cụ thể từ chính các report Domain Research của lần chạy này (khía cạnh `ui`/`ux`/`animation`/`layout`/`3d`/`text`, Phase 0 step 6 — report `features`/`flow` chỉ để tham khảo cho Design Brief, không bao giờ là nguyên liệu kéo pattern) — pattern thật, có tên, có trích nguồn từ nguồn uy tín 2026 của lần chạy này, không phải 1 cuốn công thức thuộc lòng. Khía cạnh nào ghi "unavailable" (research lỗi, xem step 6) → fallback về Project Profile + Personal Aesthetic Quality Floor cho phần đó, không bao giờ fallback về pattern cứng. Audit ở Phase 2 luôn chạy đầy đủ — bao gồm thứ bậc thị giác, tỷ lệ, elevation, và cân đối nội dung, không chỉ bắt state hỏng/a11y/responsive; khi brief táo bạo nó là sàn, không phải trần, chồng thêm lên phần đó — output được đánh giá bằng độ đặc trưng của điểm nhấn DUY NHẤT đã chốt, không chỉ bằng việc không còn lỗi.

**Dependency allowlist — thêm thẳng, không cần hỏi, khi lựa chọn Motion/Animation tự quyết là *Expressive* hoặc *Balanced*:** GSAP (+ ScrollTrigger), Motion (Framer Motion), Lenis (smooth scroll), CSS scroll-driven animation gốc / View Transitions API, Rive, Lottie — bộ công cụ chuẩn de-facto của site đoạt giải 2025-2026.
**Vẫn phải dừng lại hỏi, bất kể brief:** React Three Fiber/Three.js (650KB+ — chỉ khi 3D thực sự là cốt lõi của concept), Barba.js, bất kỳ tool trả phí/SaaS nào ngoài Rive, custom WebGL/GLSL shader.

**Anti-slop gate trước khi báo done — mọi lần chạy, bất kể brief** (chọn *Functional/minimalist* nghĩa là tiết chế, không phải generic) — `~/.claude/skills/frontend-design/references/anti-slop-rules.md` tồn tại → đọc file đó để có checklist đầy đủ; không có → danh sách bên dưới là sàn. Tối thiểu fail run nếu có: Inter/Roboto là font duy nhất, gradient tím-xanh là thẩm mỹ chủ đạo, 3+ card giống hệt nhau trong một hàng, tên/số placeholder ("John Doe", số tròn 50%/$100), copy sáo rỗng kiểu startup ("Elevate", "Seamless", "Next-Gen"), background `#000000` thuần, thiếu hover/focus state, **illustration flat stock chưa customize** (unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps không đổi palette/pose — ngang tier với gradient tím; fix theo tier: hand-drawn custom > line-art/sketch > isometric 3D > flat đã customize kỹ > geometric/abstract > bỏ illustration). **Ngoại lệ — không tính slop**: 1 icon nhỏ (≤32px) dạng line/duotone custom, đặt có chủ đích làm điểm neo trang trí (ví dụ cạnh tiêu đề), KHÔNG phải illustration stock scene — được khuyến khích, không bị flag.

Vẫn bắt buộc bất kể brief: accessibility (contrast, focus ring, đầy đủ state), không migrate tech stack, không đổi DB schema/migration, chỉ dùng motion GPU-safe (`transform`/`opacity` — không animate `width`/`height`/`top`/`left`; LCP mobile vốn đã sát ngưỡng, bold không được phá budget đó).

**Quy tắc cứng (áp dụng cho mọi lần chạy, bất kể brief):**
- ✅ Làm việc trong tech stack hiện có — KHÔNG migrate framework
- ✅ API/service layer được tự do sửa khi redesign thực sự cần — thêm/đổi endpoint, đổi response shape, đổi logic service. DB schema/migration vẫn ngoài phạm vi dù trường hợp nào.
- ✅ **Quyết định lộ nội dung chỉ cần 1 xác nhận gộp, không im lặng, không duyệt từng item**: check "sparse/trống trải" ở Information Architecture (Phase 2) và bước đọc Real User & Purpose ở Phase 1 Bước 1 gộp data thật chưa render/chưa fetch đáng đưa lên (kể cả field tồn tại ở tầng DB nhưng chưa từng được fetch) thành 1 danh sách ngắn trước khi Phase 4 ship — trình thành 1 `AskUserQuestion` duy nhất ("nối N field này — tất cả / một phần / không") thay vì hỏi từng field, rồi implement các field được chấp nhận xuyên suốt (API/service layer + UI). Đây là quyết định lộ dữ liệu, không thuần thẩm mỹ, nên vẫn cần 1 xác nhận dù chỗ khác đã tự do hoàn toàn.
- ✅ Kiểm tra `package.json` trước khi thêm dependency — trừ dependency allowlist ở trên, thêm thẳng được khi lựa chọn Motion đòi hỏi
- ✅ Khi ẩn (không xóa) → dùng opacity/visibility, không unmount
- ✅ Dùng Tailwind tokens — không hardcode hex
- ✅ Dùng mục "Good reference UI" trong Project Profile làm chuẩn tham chiếu khi Design Brief rơi vào *Brand-centric/cohesive* — không có → component đẹp nhất đã có sẵn trong project; brief *Functional/minimalist*, *Experimental/bold*, hoặc *Trend-forward* có thể tách khỏi chuẩn này
- ✅ **Responsive là bắt buộc**: mọi thay đổi layout PHẢI verify ở 3 viewport — mobile (375px), tablet (768px), desktop (1280px); viết mobile-first, rồi override bằng sm:/lg:
- ✅ Component styled bởi bên thứ ba (có `import 'lib/*.css'`) bọc trong wrapper div → wrapper sở hữu TOÀN BỘ visual state (border, ring, disabled opacity); null hết border/shadow bên trong component qua override CSS var + scoped `!important`
- ✅ **Kỷ luật ARIA**: ưu tiên native HTML (`<button>`, `<dialog>`, `<details>`, `<label for>`) hơn ARIA. Chỉ thêm `role`/`aria-*` khi native HTML không diễn đạt được tương tác, và khi đã thêm phải đảm bảo đủ bộ role+state+property — không bao giờ thêm ARIA attribute "phòng khi"
- ❌ KHÔNG thêm animation phức tạp nếu Motion/Framer chưa có sẵn trong project — ngoại lệ: dependency allowlist ở trên áp dụng khi lựa chọn Motion đòi hỏi
- ❌ KHÔNG thêm màu brand mới — chỉ dùng token hiện có, trừ khi quyết định Color Palette là *Accent colors only* (accent mới) hoặc *Full palette redesign*/*Dynamic* (bảng màu mới hoàn toàn)
- ❌ KHÔNG dùng màu mặc định của component library (shadcn blue) nếu project đã có màu primary riêng
- ❌ KHÔNG thêm toast notification không cần thiết — ngoại lệ: 1 khoảnh khắc ăn mừng/hoàn thành có chủ đích mà Design Brief thực sự đòi hỏi KHÔNG tính là "không cần thiết" — tiêu chí là có chủ đích hay không, không phải có tối giản hay không
- ❌ KHÔNG đổi DB schema hay chạy migration

---

### Phase 4: Verify

1. Ban đầu có URL/localhost → chụp screenshot sau khi fix, so sánh before/after
2. Có ảnh input → verify code có khớp ý đồ của ảnh không
3. Chạy script format của project (nếu có)
4. **Verify accessibility**: project đã có (hoặc user cho phép thêm) `@axe-core/playwright` hoặc `axe-core` thường → chạy một script ngắn nhắm vào route/component đang audit, in ra violations. Không có sẵn → in ra lệnh manual-check tương đương để user tự chạy — review visual/manual thủ công không được là verification duy nhất cho accessibility.
5. Vừa edit trực tiếp một file ảnh dưới `public/` (ghi đè cùng path, tên không đổi) và user báo "không thấy thay đổi" → đừng vội sửa code/ảnh lần nữa; báo user hard-refresh hoặc xóa `.next/cache/images` + restart dev server trước — Next.js Image Optimizer cache theo URL+size, không theo nội dung file, nên fix nhiều khả năng đã đúng nhưng vẫn đang serve bản cache cũ
6. **Adversarial Verify** (subagent — chỉ khi Fix thực sự đụng structural/JSX-level: swap component, đổi cấu trúc grid/layout, đổi hướng thị giác — HOẶC tiêu chí độ táo bạo của Design Brief là *Experimental/bold* hoặc *Trend-forward* — HOẶC fix thuộc category UX Efficiency / Content Design & Error Prevention có chạm frontend state/interaction logic): spawn 1 subagent mới hoàn toàn, đưa diff, checklist audit của Phase 2, và anti-slop gate. Subagent tự audit lại state cuối cùng một cách độc lập — không tiếp cận reasoning của lần chạy này — và báo PASS hoặc list vấn đề còn sót (audit item vẫn hỏng, fix vượt quá cái thực sự cần, vi phạm anti-slop). Có vấn đề → quay lại Phase 3 fix, chạy lại bước này 1 lần. Lưu report vào `plans/reports/vdesign-adversarial-<slug>-<HHMMSS>.md` trước khi orchestrator hành động dựa trên nó. Mirror theo đúng Phase 4 Adversarial Pass của `vreview` trong cùng bộ skill này.
7. **Self-Check** (inline, mọi lần chạy, không cần subagent): trước khi viết báo cáo ngắn, xác nhận — (a) độ sâu fix tương xứng với cái Phase 2 thực sự tìm ra, không có rewrite ngoài yêu cầu; (b) mọi category Phase 2 áp dụng được đã xử lý hoặc đánh dấu rõ not-applicable; (c) anti-slop gate (kể cả illustration check) đã thực sự được kiểm tra, không chỉ ngầm hiểu; (d) kết quả cuối cùng thực sự khớp Design Brief từ Phase 0 step 7, không phải bản tiết chế hơn hay táo bạo hơn brief đó; (e) khi Component Inventory ở Phase 1 đã chạy, mọi item trong đó đã được tick xong trong `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` hoặc ghi rõ lý do "không áp dụng" — không được bỏ sót component nào một cách âm thầm.
8. **Xác nhận lộ nội dung** (chỉ khi check sparse/trống trải ở Phase 2 hoặc Phase 1 Bước 1 có đánh dấu): đọc danh sách ứng viên đã gộp từ section `## Audit Findings` trong `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md` trước khi hỏi. Trước báo cáo ngắn, trình cả danh sách thành 1 `AskUserQuestion` DUY NHẤT ("nối N field này — tất cả / một phần / không"), không hỏi từng field. Nếu trả lời "tất cả"/"một phần" → nối các field được chấp nhận qua API/service layer và UI trước khi báo xong (xem Hard rules của `SKILL.vi.md`) — không bao giờ tự thêm khi chưa có xác nhận này.
9. **Báo cáo ngắn gọn**: "Đã redesign [X]. Thay đổi chính: [liệt kê 3-5 bullet points]"
   - Không summary dài
   - Chỉ nêu các thay đổi đáng kể
   - 1 dòng nêu Design Brief đã chốt (gọn — mức độ táo bạo + 1-2 tiêu chí ảnh hưởng nhiều nhất đến kết quả), cộng trạng thái Domain Research theo từng khía cạnh (cached/fresh/unavailable), cộng kết quả PASS/có-vấn-đề của Adversarial Verify khi có chạy

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
- ❌ Thêm toast notification không cần thiết (1 khoảnh khắc ăn mừng/hoàn thành có chủ đích mà Design Brief thực sự đòi hỏi không tính là "không cần thiết" — xem Phase 3)
- ❌ Để scrollbar ăn vào chiều rộng content — luôn dùng overlay/transparent scrollbar
- ❌ Style tab không nhất quán trong cùng một trang — kiểm tra tính nhất quán tab xuyên component
- ❌ Đoán pattern của component "giống X" — BẮT BUỘC đọc X trước
- ❌ `float` / `shape-outside` bên trong container `flex` hoặc `grid` — không có tác dụng, browser âm thầm bỏ qua (không error, không warning), gây layout hỏng khó hiểu
- ❌ Overlay trang trí (shine border, border beam, floating badge, glow) không có `z-index` tường minh — sibling có `position: relative` xuất hiện sau trong DOM sẽ đè lên nó do stacking theo thứ tự DOM khi `z-index: auto`
- ❌ Ảnh full-bleed dùng `object-contain` mà không khớp `aspect-ratio` của container với tỉ lệ thực tế của file ảnh — bị letterbox hai bên dù container đã full width
- ❌ Chỉ set `h-full` trên wrapper của grid item mà quên set luôn trên khung visual bên trong (border/bg/shadow) — card vẫn lệch chiều cao dù grid đã stretch item bằng nhau
- ❌ Ép `line-clamp`/height cố định lên copy có độ dài khác nhau giữa các card song song thay vì cân bằng lại độ dài text — line-clamp chỉ là band-aid, cân bằng lại copy mới là fix gốc thực sự cho "sự hài hòa"
- ❌ Đổi cấu trúc hoặc thêm field mới mà không trace được về 1 nhu cầu cụ thể từ bước đọc Real User & Purpose (Phase 1 Bước 1) — tự do sáng tạo/API đầy đủ không phải là giấy phép cho sự tùy tiện
- ❌ Bỏ qua việc tổng hợp các tiêu chí tự quyết ở Phase 0 step 7 thành Design Brief thật trước khi đụng code — 1 lần chạy không có điểm neo vẫn đọc ra là generic/an toàn; chọn pattern trước khi chọn hướng chỉ tạo ra một mớ hổ lốn, không phải một thiết kế mạch lạc
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

Theo convention Next Steps trong `_vskills-shared/repo-profile.md` §7.
