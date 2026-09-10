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
| `[Image]` / screenshot đính kèm | Phân tích ảnh → trích xuất các thiếu sót về design → áp fix |
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
   - Spawn song song tất cả khía cạnh chưa có cache — mỗi khía cạnh 1 Task/Agent call, tối đa 8, cùng 1 message. Nhóm khía cạnh design-pattern (`ui`/`ux`/`animation`/`layout`/`3d`/`text`) mỗi agent tìm pattern hiện hành (2025-2026) đặc thù cho `<target feature>` trong bối cảnh sản phẩm `<domain>`, chỉ tập trung vào đúng 1 khía cạnh được giao, giữ trong thiên hướng B2B "rõ ràng > gây ấn tượng" (không phải pure Awwwards/portfolio inspiration); report các pattern cụ thể có tên kèm nguồn. Agent `features`/`flow` thì tìm pattern feature hoặc flow hiện hành của competitor/domain cho `<target feature>` trong `<domain>` — nêu rõ chỉ để tham khảo context, KHÔNG phải scope cần implement; agent không được đề xuất thêm các pattern này vào redesign. Lưu mỗi report vào `plans/reports/researcher-vdesign-bold-<slug>-<aspect>-<HHMMSS>.md`
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
- Tìm một component trong project đóng vai trò **tham chiếu chuẩn** (user hay dùng booking form, notes, hoặc trang sessions làm chuẩn) → đọc để học pattern

**Khi user nói "giống X" hoặc "tương tự X":**
→ BẮT BUỘC đọc component/page X trước khi implement — không được đoán pattern

---

### Phase 2: Audit

Duyệt qua từng nhóm — chỉ flag các vấn đề **thực sự ảnh hưởng đến chất lượng visual/UX**:

#### Typography
- [ ] Hierarchy chữ rõ ràng: heading > subheading > body > caption > muted?
- [ ] Font size nhất quán với hệ thống (không trộn text-sm/text-xs tùy tiện)?
- [ ] Line-height và letter-spacing hợp lý?
- [ ] Font size của input field ≥ 16px (tránh bị zoom trên mobile)?

#### Color & Surfaces
- [ ] Dùng CSS vars/Tailwind tokens — không hardcode hex?
- [ ] Background/border/shadow nhất quán với các component cùng loại ở nơi khác trong project?
- [ ] **Contrast — đo, không đoán**: lấy giá trị màu foreground/background thực tế cho từng cặp text/background trong file đang audit (CSS custom properties, Tailwind theme config, hoặc hex/rgb literal trong component). Với mỗi cặp, tính relative luminance theo WCAG cho từng kênh (`L = 0.2126*R + 0.7152*G + 0.0722*B` trên sRGB đã linearize) và contrast ratio `(L1+0.05)/(L2+0.05)`. Báo PASS/FAIL kèm ratio thực tế, đối chiếu 4.5:1 (text thường), 3:1 (text lớn ≥18pt/14pt-bold, và UI non-text như border/icon theo SC 1.4.11). Nếu không resolve được màu bằng static analysis (tính runtime, hoặc từ design system ngoài không có token hiển thị) → báo **"KHÔNG ĐO ĐƯỢC — cần verify thủ công"**, không được ngầm coi là PASS.
- [ ] State active/selected/highlighted có màu phân biệt rõ chưa?
- [ ] **KHÔNG dùng màu mặc định của component** (ví dụ màu xanh mặc định của shadcn) — phải dùng màu primary của hệ thống (`primary`, `accent` tokens)?

#### Chiều sâu & Elevation (Depth & Elevation)
- [ ] Elevation tier được định nghĩa rõ (3-5 level có tên: base/card/elevated-card/overlay) và gán nhất quán — mỗi loại surface luôn dùng đúng 1 tier?
- [ ] Shadow lấy từ token scale cố định (sm/md/lg/xl) — không có giá trị box-shadow tùy tiện?
- [ ] Light source nhất quán trên mọi shadow (cùng hướng/tỷ lệ offset)?
- [ ] Z-index theo scale định nghĩa sẵn (dropdown < sticky < modal < toast) — không có `z-[9999]` tùy tiện; modal/toast render qua portal để tránh stacking-context trap?
- [ ] Card/panel dùng border + shadow nhẹ; shadow nặng chỉ dành cho phần tử nổi (modal, popover, FAB)?
- [ ] Blur/glass effect (nếu có) chỉ dùng cho overlay, không dùng cho surface nội dung chính?
- [ ] Không có stacking trap ngoài ý muốn: sticky/opacity/transform ở cha vô tình cắt dropdown/popover con?

#### Layout & Spacing
- [ ] Padding/gap dùng spacing scale nhất quán (không có giá trị lẻ kiểu `p-[13px]`)?
- [ ] Responsive chắc chắn: mobile-first, không bị scroll ngang?
- [ ] Đúng pattern container layout: `container → header fixed → content overflow-y-auto → footer/input fixed`?
- [ ] Không dùng `h-screen` — dùng `min-h-[100dvh]`?
- [ ] Max-width container đặt đúng chỗ?
- [ ] Alignment nhất quán (không trộn left/center tùy tiện)?

#### Components
- [ ] Dùng đúng component từ UI library thay vì raw HTML?
- [ ] Phân cấp button rõ ràng: primary (filled) vs secondary (outline/ghost) vs tertiary (link/text)?
- [ ] Icon nhất quán (cùng library, cùng size)?
- [ ] Card: tránh `border + shadow + white bg` chung chung nếu density cao — dùng spacing/divider thay thế?
- [ ] Form field dùng wrapper `Form*` từ UI library (`FormTextField`, `FormSelectField`, v.v.)?
- [ ] Icon dùng theo mapping ngữ nghĩa nhất quán — cùng 1 icon luôn mang đúng 1 ý nghĩa/action xuyên suốt app, không đổi tùy tiện?
- [ ] Button/control chỉ dùng icon (icon-only) có accessible label (`aria-label` hoặc tương đương) — không chỉ dựa vào bản thân icon?

#### Hài hòa Tỷ lệ (Proportion & Scale Harmony)
- [ ] Font-size toàn trang/component bám theo 1 modular scale duy nhất (base × ratio^n: Perfect Fourth 1.333 / Major Third 1.25 / Golden Ratio 1.618) — không có size chen giữa tùy tiện?
- [ ] Giá trị spacing (padding/margin/gap) đều là bội số của base grid dự án (8px, phụ 4px) — không có giá trị lẻ kiểu `p-[13px]`?
- [ ] Số lượng giá trị khác nhau giữ trong giới hạn: ≤6-7 font-size, ≤10 spacing, ≤3-4 border-radius trên 1 trang/component — flag giá trị "orphan" chỉ dùng đúng 1 lần?
- [ ] Kích thước icon tỷ lệ với chữ liền kề — icon-height ≈ line-height của chữ bên cạnh?
- [ ] Component cùng variant (mọi button primary, mọi input) có cùng height/padding — không lệch âm thầm giữa các instance?
- [ ] Vertical rhythm: khoảng cách giữa các block xếp chồng là bội số của base line-height, không tùy tiện?

#### Component tự style của bên thứ ba (Third-party Self-styled Components)
Áp dụng khi gặp component có `import 'lib/styles.css'` hoặc tự inject CSS riêng: rich text editor (CKEditor, TipTap, Quill), code editor (Monaco, CodeMirror), date/color picker, react-select, map component, v.v.

- [ ] **Kiểm tra double border**: wrapper div có tự thêm `border`/`shadow` không? Nếu wrapper thêm border VÀ component cũng tự có border riêng → double border. Chỉ một bên được sở hữu ranh giới thị giác.
- [ ] **Ownership rõ ràng**: wrapper div sở hữu border/focus ring/error state → phải null hết border bên trong component. Hoặc ngược lại: component tự style → wrapper không thêm gì.
- [ ] **Focus state**: focus ring chỉ quản lý ở đúng một nơi — wrapper (qua JS state `onFocus`/`onBlur`) hoặc CSS của component (`:focus-within`), không phải cả hai.
- [ ] **Disabled state**: disabled phải phản ánh cả trên visual của wrapper (opacity/pointer-events), không chỉ pass prop `disabled` vào component.

**Khi wrapper sở hữu border — fix theo thứ tự này:**
1. Override CSS custom properties của lib tại class wrapper: `--ck-color-base-border: transparent`, `--select-border: transparent`, v.v.
2. Scope `border: none !important; box-shadow: none !important` qua class wrapper cho các element bên trong lib
3. Wrapper quản lý focus state qua React `useState` + `onFocus`/`onBlur`, không dùng CSS `:has(.ck-focused)`

#### States (Phải có đủ)
- [ ] **Loading**: skeleton hoặc spinner trong component, không được để trắng — hình dạng skeleton phải phản ánh đúng layout content thật (skeleton của card phải giống card, không phải khối xám chung chung); với content nhiều phần, reveal dần theo tiến trình (outline → text → ảnh) thay vì reveal 1 lần
- [ ] **Empty**: empty state có message rõ ràng + CTA nếu cần
- [ ] **Error**: error message dễ đọc, không lộ stack trace
- [ ] **Hover**: các item có action (button, row) có hover state
- [ ] **Focus**: focus ring hiển thị rõ cho keyboard navigation
- [ ] **Active/Selected**: item được chọn có chỉ báo thị giác
- [ ] **Disabled**: button disabled có look phân biệt rõ + cursor-not-allowed

#### UX Efficiency & Giảm Thao Tác (UX Efficiency & Reduced Interaction)
- [ ] Số lựa chọn hiển thị cùng lúc ≤5-7 (Hick's Law) — nhiều hơn thì group lại hoặc progressive disclosure?
- [ ] Form hiển thị cùng lúc >7 field → chia step hoặc collapsible section?
- [ ] List/table có action lặp lại theo hàng → hỗ trợ multi-select + bulk action, không chỉ từng-cái-một?
- [ ] Sửa 1 field đơn giản (status, tên) không bắt buộc điều hướng sang trang/modal riêng nếu inline-edit khả thi?
- [ ] Action rủi ro thấp, reversible (toggle, archive) → làm luôn + undo, không cần confirm dialog; chỉ action phá hủy/không hoàn tác mới cần bước confirm?
- [ ] Giá trị hay dùng lại (filter cuối, lựa chọn cuối) được nhớ ở client-side (localStorage/session) thay vì reset mỗi lần?
- [ ] Feedback cho mọi action xuất hiện trong vòng 400ms (Doherty Threshold) — optimistic update hoặc loading indicator, không bao giờ chờ im lặng?
- [ ] Dropdown/select có >10 option thì có ô search/filter, không phải cuộn tay?

**Scope carve-out (chỉ áp dụng cho category UX Efficiency + Content Design & Error Prevention):** fix trong 2 category này (multi-select/bulk action, inline-edit, nhớ state client-side, optimistic UI, đổi validation-timing, input masking) được phép chạm **frontend interaction state** (React state/hooks, localStorage) — vẫn KHÔNG được gọi backend endpoint mới, đổi data model, hay sửa server logic. Nếu fix thực sự cần API mới (vd: bulk-delete endpoint thật) → ghi vào báo cáo cuối là "backend dependency", không tự chế workaround client-side giả lập.

#### Kiến Trúc Thông Tin & Khả Năng Quét (Information Architecture & Scannability)
- [ ] Content above-the-fold trên trang/dashboard dày đặc ưu tiên thông tin giá trị cao nhất ở top-left (F-pattern) — KPI/action quan trọng không bị chôn dưới fold?
- [ ] Chiều cao row của bảng dữ liệu dày đặc khớp với đối tượng dùng thật: mặc định comfortable (~48-52px, ít row/viewport hơn) cho user hỗn hợp/thỉnh thoảng dùng, option compact (~28-32px) cho power-user/analyst — không chọn tùy tiện?
- [ ] List/table nhiều item có cách quét thông tin chính mà không cần mở từng row (chọn cột, badge tóm tắt) — không ép phải drill-down từng row để so sánh cơ bản?
- [ ] Dashboard dày đặc dùng progressive disclosure: overview trước, drill-down chi tiết sau, không render hết mọi thứ cùng lúc?

#### Accessibility (WCAG 2.2)
- [ ] **2.4.11 Focus Not Obscured**: element đang focus có bao giờ bị che khuất hoàn toàn sau sticky header/cookie banner/overlay khác không?
- [ ] **2.5.7 Dragging Movements**: mọi tương tác drag-and-drop có phương án thay thế bằng click/tap không (không chỉ drag)?
- [ ] **3.3.8 Accessible Authentication**: flow đăng nhập có tránh chặn paste password, và tránh yêu cầu giải câu đố nhận thức mà không có phương án thay thế không?
- [ ] Tab order khớp thứ tự đọc thị giác/logic, không phải thứ tự DOM-insertion tình cờ?
- [ ] Có skip-to-content link là element focusable đầu tiên trên trang có navigation/header lặp lại?
- [ ] Composite widget (tabs, menu, combobox) hỗ trợ điều hướng arrow-key trong nội bộ widget (roving tabindex) theo WAI-ARIA APG, không chỉ Tab đơn thuần?
- [ ] Escape đóng modal/popover đang ở trên cùng, đúng convention chuẩn?

#### Animation & Motion
- [ ] Animation chỉ dùng khi có **ý nghĩa**: hover reveal, chuyển state, vào trang
- [ ] Không animate opacity của **component con** — chỉ animate container bọc ngoài
- [ ] Khi ẩn component nhưng cần giữ state → dùng `opacity-0 w-0` / `visibility: hidden`, **KHÔNG unmount**
- [ ] Action bar/toolbar → chỉ hiện khi hover (`group-hover:opacity-100`)
- [ ] Thời lượng animation: tinh tế (150-300ms), không quá lòe loẹt cho app B2B
- [ ] Có guard `prefers-reduced-motion` nếu dùng CSS animation

#### Media & Ảnh (banner, hero character, background art, video)
- [ ] Nếu ảnh cần full-bleed (trải rộng hết chiều rộng container) dùng `object-contain` → container BẮT BUỘC phải set `aspect-ratio` (hoặc `style={{ aspectRatio: 'W/H' }}`) khớp đúng tỉ lệ width/height thực tế của file ảnh (đọc qua PIL/`sips -g pixelWidth -g pixelHeight`, không được đoán) — nếu tỉ lệ container và ảnh không khớp, `object-contain` sẽ tạo letterbox hai bên dù width đã full
- [ ] Với full-bleed chấp nhận crop nhẹ thay vì tính aspect-ratio → dùng `object-cover` với `mask-image: linear-gradient(to bottom, transparent, black 10%, black 90%, transparent)` để fade cạnh và giấu vết crop cứng
- [ ] Nếu illustration cần "phình to" mà không chiếm layout space của sibling (text/button) → set `position: absolute` (không phải flex/grid item bình thường); nhưng vẫn phải dành chỗ cho text bên cạnh qua `max-width: calc(100% - Npx)` hoặc padding khớp với kích thước ảnh, để tránh đè lên text
- [ ] `float` + `shape-outside` (kỹ thuật text tự động bọc quanh contour của ảnh) CHỈ hoạt động khi element là con trực tiếp của một **block container** — **không có tác dụng gì bên trong `flex`/`grid`** (browser âm thầm bỏ qua `float`, không warning/error). Nếu parent bắt buộc là flex, dùng `absolute` + reserve `max-width` thay vì float
- [ ] Nhiều card cùng hàng có illustration cần căn thẳng mép trên hoặc dưới → anchor container bằng `top-0`/`bottom-0` (không phải cả hai) VÀ set `object-position` khớp cùng phía (`object-top`/`object-bottom`) — không dựa vào việc tỉ lệ tự nhiên của các ảnh tình cờ khớp nhau, vì mỗi ảnh nguồn thường có content margin/bbox khác nhau
- [ ] Card cao bằng nhau trong `grid` (grid tự động stretch item bằng nhau) nhưng khung visual bên trong (border/bg/shadow) chỉ tự resize theo content → phải set `h-full` trên CẢ wrapper ngoài (grid item) LẪN khung visual bên trong, nếu không card vẫn lệch chiều cao dù grid item đã stretch đúng
- [ ] Overlay động (shine border, border beam, glow, floating badge) không có `z-index` tường minh → sibling có `position: relative` xuất hiện SAU trong DOM sẽ đè lên overlay, vì `z-index: auto` giữa các element positioned xếp chồng theo thứ tự DOM, không theo "cái nào định làm nổi lên trên"; luôn gán `z-index` tường minh cho overlay animation/decoration
- [ ] **Kiểm tra illustration slop**: illustration unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps chưa customize trong hero/empty-state/onboarding → flag là slop, ngang tier với gradient tím-xanh/Inter-only (xem anti-slop gate). Fix theo tier: hand-drawn custom > line-art/sketch > isometric 3D > flat đã customize kỹ (đổi palette + pose riêng, không dùng scene stock) > geometric/abstract > bỏ hẳn illustration.
- [ ] **Hero video** (nếu có): `muted autoplay loop playsinline` + poster tĩnh fallback (JPEG); swap sang ảnh tĩnh trên mobile (`max-width: 768px`) để bảo vệ LCP.
- [ ] **Responsive art direction** (khi mobile/desktop cần bố cục khác nhau, không chỉ là scale nhỏ lại): dùng `<picture>` + `<source>` theo media-query để crop khác nhau, không phải một ảnh bị co giãn bằng CSS.

#### Riêng cho Form/Wizard
- [ ] Stepper: chiều cao gọn, không lãng phí không gian dọc
- [ ] Layout form: label + input canh đều nhất quán
- [ ] Validation error: hiện ngay dưới field, không chỉ ở trên đầu
- [ ] Wizard nhiều bước: chỉ báo tiến trình rõ ràng
- [ ] Tham chiếu: booking form (create-booking) là **chuẩn vàng** trong hệ thống

#### Content Design & Phòng Ngừa Lỗi (Content Design & Error Prevention)
- [ ] Label button nêu rõ outcome cụ thể (verb + object, vd "Tạo báo cáo") — không dùng label chung chung ("Submit", "OK") khi có thể cụ thể hơn?
- [ ] Error message nêu rõ cái gì sai VÀ bước tiếp theo cần làm — không chỉ nói "Dữ liệu không hợp lệ"?
- [ ] Validation timing: không validate mỗi lần gõ phím — validate khi blur trước, sau đó (nếu lỗi) mới re-validate liên tục theo change cho tới khi hết lỗi?
- [ ] Với field cần đúng format (phone, date, currency), format kỳ vọng hiển thị TRƯỚC khi user gõ (placeholder/hint), không chỉ lộ ra sau khi báo lỗi?
- [ ] Input masking/constraint ngăn nhập sai ngay từ đầu khi khả thi (vd: date picker chặn ngày không hợp lệ) thay vì chỉ dựa vào validate sau khi đã nhập?
- [ ] Copy của empty-state và success-message có context + hành động tiếp theo rõ ràng, không chỉ nêu trạng thái?
- [ ] Label của action phá hủy/rủi ro cao nêu rõ hậu quả cụ thể (vd "Xóa 12 bản ghi" thay vì chỉ "Xóa")?

**Scope:** các item về validation-timing và input-masking dùng chung scope carve-out frontend-only với UX Efficiency ở trên.

#### Riêng cho Table/List
- [ ] Table header: typography phân biệt rõ với data row
- [ ] Có row hover state chưa?
- [ ] Có empty state khi không có data?
- [ ] Pagination UI đủ dùng chưa?
- [ ] Action column: hiện khi hover hay luôn hiển thị?
- [ ] Responsive: các cột ít quan trọng có ẩn trên mobile không?

#### Mobile & Responsive

**Chiến lược breakpoint (Tailwind mobile-first):**
- [ ] Style cơ bản viết cho mobile trước — `sm:` / `md:` / `lg:` là override cho màn hình lớn hơn, không phải ngược lại
- [ ] Dùng breakpoint chuẩn của project: `sm` 640px · `md` 768px · `lg` 1024px · `xl` 1280px — không thêm breakpoint tùy tiện
- [ ] Mỗi thay đổi ở breakpoint phải có lý do rõ ràng: layout collapse, tăng font scale, mở sidebar, v.v.

**Layout & Grid:**
- [ ] Grid nhiều cột BẮT BUỘC phải collapse: `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3` — không được để trơ `grid-cols-3`
- [ ] Flex row trên desktop → `flex-col` trên mobile: `flex flex-col sm:flex-row`
- [ ] Layout sidebar: sidebar `hidden lg:block` + content full-width trên mobile, hoặc dùng Sheet/Drawer
- [ ] Không dùng width fixed/absolute (ví dụ `w-[320px]`) mà không có responsive fallback
- [ ] Container max-width đặt đúng chỗ: `max-w-5xl mx-auto px-4` — px-4 mobile, px-6 sm+

**Scale typography:**
- [ ] Heading scale theo viewport: `text-xl sm:text-2xl lg:text-3xl` — không cố định một size cho mọi viewport
- [ ] Body text không cần đổi size qua các viewport (text-sm/text-base đã ổn)
- [ ] Font-size của input/textarea ≥ 16px trên mobile để tránh iOS tự động zoom

**Touch & Interaction:**
- [ ] Touch target ≥ 44×44px cho mọi element interactive (button, link, checkbox, toggle)
- [ ] Tương tác chỉ dùng hover BẮT BUỘC phải có fallback cho mobile: action button luôn hiển thị, không chỉ `group-hover:`
- [ ] Khoảng cách giữa các touch target: gap ≥ 8px để tránh lỗi bấm nhầm

**Overflow & Scroll:**
- [ ] Không bị scroll ngang trên mobile (`overflow-x-hidden` ở root nếu cần)
- [ ] Table trên mobile: wrapper `overflow-x-auto` hoặc collapse thành layout dạng card
- [ ] Text/email/URL dài: `truncate` hoặc `break-all` trên mobile — không để nó tràn ra ngoài

**Ảnh & Media:**
- [ ] Component ảnh có size tường minh + container có size tường minh — không bị layout shift. Tên component tuỳ theo framework detect được (§3 của `repo-profile.md`): Next.js → `next/image` với `fill`; Nuxt → `NuxtImg`; Astro → `astro:assets` `<Image>`; generic → component ảnh riêng của project với width/height tường minh hoặc container aspect-ratio, hỏi user nếu không tìm ra. Tính điều kiện §3 này áp dụng tương tự cho bất kỳ API đặc thù framework nào khác nêu trong checklist.
- [ ] Ảnh decorative/hero: `objectPosition` đảm bảo subject vẫn thấy được khi crop trên mobile
- [ ] Size responsive của avatar/thumbnail: `size-8 sm:size-10` nếu cần

**Navigation & Modal:**
- [ ] Dropdown menu: đủ rộng trên mobile, không bị cắt
- [ ] Modal/Dialog: full-screen hoặc `max-h-[90dvh] overflow-y-auto` trên mobile — không dùng height cố định
- [ ] Sheet trồi từ dưới lên trên mobile thay vì Dialog căn giữa
- [ ] Sticky header có chiều cao gọn hơn trên mobile (`py-2 sm:py-4`)

**Safe areas (iOS/Android):**
- [ ] Element fixed đáy: `pb-safe` hoặc `padding-bottom: env(safe-area-inset-bottom)` trên iOS
- [ ] Fixed đầu: `pt-safe` nếu cần tránh notch
- [ ] Không dùng `h-screen` — dùng `min-h-[100dvh]` để tránh vấn đề với chrome của trình duyệt mobile

**Spacing responsive:**
- [ ] Padding section: `py-6 sm:py-8 lg:py-12` — mobile thường cần ít whitespace hơn desktop
- [ ] Padding card: `p-4 sm:p-5 lg:p-6` — không cố định padding lớn cho mọi viewport
- [ ] Grid gap: `gap-3 sm:gap-4 lg:gap-6`

#### Theming & Dark Mode
Chỉ áp dụng nếu project có dark mode / theme toggle. Bỏ qua hẳn category này nếu project chỉ có light-mode.
- [ ] Contrast ratio được re-verify riêng cho dark mode — cặp màu pass ở light mode KHÔNG được mặc định coi là pass ở dark?
- [ ] Background dark mode tránh dùng `#000000` thuần — dùng tông tối mềm (vd khoảng `#121212`-`#1E1E1E`) để tránh hiện tượng halation?
- [ ] Shadow ở dark mode dùng opacity cao hơn (~40-70%) hoặc elevation-tint (màu surface sáng hơn theo tier) thay vì tái dùng giá trị shadow của light mode?
- [ ] Ảnh/icon/illustration có thích ứng dark mode (không có viền trắng quanh PNG trong suốt, không có icon tối-trên-tối khó đọc)?

#### Scrollbar
- [ ] Scrollbar không ăn vào chiều rộng content → dùng overlay scrollbar (plugin Tailwind `scrollbar-thin` hoặc CSS `scrollbar-width: thin; scrollbar-color: transparent transparent` kèm hiện ra khi `:hover`)
- [ ] Background scrollbar: transparent
- [ ] Nút scroll-to-bottom (nếu có): đặt canh giữa, gần input, không fixed ở góc phải

#### Tooltip & Popover
- [ ] Style tooltip nhất quán toàn project — không để mặc định chưa style?
- [ ] Tooltip của chart: format/style nhất quán, có text-justify cho nội dung tiếng Việt?
- [ ] Popover: có animation opacity + bo góc khớp hệ thống style (không dùng mặc định của shadcn nếu project đã customize)?
- [ ] Tooltip chỉ dùng khi thực sự cần — nếu UI đã đủ rõ ràng, bỏ tooltip

#### Badge & Tag
- [ ] Badge gọn, không quá khổ so với nội dung?
- [ ] Badge có thể ghim lên viền trên của card khi cần tách biệt thị giác không?
- [ ] Màu badge dùng semantic token (status, category), không hardcode?

#### Tab & Navigation
- [ ] Các tab trong cùng page/card phải khớp style với nhau — kiểm tra tính nhất quán tab xuyên component?
- [ ] Tab ngày/giờ có khớp với tab header của calendar khi cùng scope không?
- [ ] Sidebar trong Sheet/Drawer: có nhất quán với sidebar chính của hệ thống không?

#### Sticky & Scroll Behavior
- [ ] Nút back / header có thu gọn gọn gàng khi sticky lúc scroll không?
- [ ] Sticky header có che mất content bên dưới không (đủ padding-top cho content)?

---

### Phase 3: Fix

Fix mọi thứ Phase 2 tìm ra — spacing, state, swap component, đổi cấu trúc grid/layout, đổi hoàn toàn hướng thị giác đều nằm trong scope mặc định; không còn trần chặn độ sâu. Độ sâu vẫn phải *tương xứng* với cái thực sự hỏng: 1 finding chỉ về spacing không cho phép viết lại toàn bộ JSX (xem Anti-Patterns — "viết lại toàn bộ layout khi chỉ cần chỉnh một phần").

**`--wow` (tùy chọn)**

Tạm ngưng chỉ trong lần chạy này: "KHÔNG áp dụng thẩm mỹ portfolio/avant-garde", thiên hướng mặc định "rõ ràng > gây ấn tượng", và anti-pattern "Copy design sáng tạo từ landing page/portfolio vào product UI" — cho phép art direction riêng biệt, typography scale biểu cảm hơn, layout độc đáo/bất đối xứng, motion tùy chỉnh.

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

**Kéo pattern, không chỉ audit-fix.** Sau khi chốt vibe, kéo từ 6 pattern trên cộng arsenal của vibe đó — nếu `~/.claude/skills/frontend-design/references/premium-design-patterns.md` tồn tại, đọc file đó để có catalog đầy đủ (navigation, layout, card, scroll-driven animation, kinetic typography, micro-interaction); nếu không có, dùng archetype pattern trong `references/anti-slop-minimum.vi.md` thay thế — cộng thêm pattern/insight domain-specific từ các report domain research nhóm design-pattern ở Phase 0 step 6 hiện có cho lần chạy này (`ui`/`ux`/`animation`/`layout`/`3d`/`text`, tối đa 6 — report `features`/`flow` không nằm trong nhóm này, chúng chỉ để tham khảo cho Vibe Commitment, không phải nguyên liệu kéo pattern). Merge tất cả với catalog tĩnh, không thay thế. Audit ở Phase 2 vẫn chạy (bắt state hỏng/a11y/responsive) nhưng dưới `--wow` nó là sàn, không phải trần — output được đánh giá bằng độ đặc trưng của điểm nhấn DUY NHẤT đã chốt, không chỉ bằng việc không còn lỗi.

**Dependency allowlist — thêm thẳng, không cần hỏi:** GSAP (+ ScrollTrigger), Motion (Framer Motion), Lenis (smooth scroll), CSS scroll-driven animation gốc / View Transitions API, Rive, Lottie — bộ công cụ chuẩn de-facto của site đoạt giải 2025-2026.
**Vẫn phải dừng lại hỏi:** React Three Fiber/Three.js (650KB+ — chỉ khi 3D thực sự là cốt lõi của concept), Barba.js, bất kỳ tool trả phí/SaaS nào ngoài Rive, custom WebGL/GLSL shader.

**Anti-slop gate trước khi báo done** — nếu `~/.claude/skills/frontend-design/references/anti-slop-rules.md` tồn tại, đọc file đó để có checklist đầy đủ; nếu không có, dùng điều kiện fail trong `references/anti-slop-minimum.vi.md` thay thế. Tối thiểu fail run nếu có: Inter/Roboto là font duy nhất, gradient tím-xanh là thẩm mỹ chủ đạo, 3+ card giống hệt nhau trong một hàng, tên/số placeholder ("John Doe", số tròn 50%/$100), copy sáo rỗng kiểu startup ("Elevate", "Seamless", "Next-Gen"), background `#000000` thuần, thiếu hover/focus state, **illustration flat stock chưa customize** (unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps không đổi palette/pose — ngang tier với gradient tím; fix theo tier: hand-drawn custom > line-art/sketch > isometric 3D > flat đã customize kỹ > geometric/abstract > bỏ illustration).

Vẫn bắt buộc kể cả khi `--wow`: accessibility (contrast, focus ring, đầy đủ state), không migrate tech stack, không đổi logic/state/API, chỉ dùng motion GPU-safe (`transform`/`opacity` — không animate `width`/`height`/`top`/`left`; LCP mobile của B2B vốn đã sát ngưỡng, bold không được phá budget đó).

**Quy tắc cứng (áp dụng cho mọi lần chạy, kể cả `--wow`):**
- ✅ Làm việc trong tech stack hiện có — KHÔNG migrate framework
- ✅ KHÔNG phá logic/state/API — chỉ đổi presentation layer
- ✅ Ngoại lệ: fix thuộc category UX Efficiency và Content Design & Error Prevention (Phase 2) được phép chạm frontend interaction state/hooks/localStorage — xem scope carve-out dưới mục UX Efficiency. Vẫn không được đụng backend/API/data-model.
- ✅ Kiểm tra `package.json` trước khi thêm dependency — trừ dependency allowlist của `--wow` ở trên, được thêm thẳng
- ✅ Khi ẩn (không xóa) → dùng opacity/visibility, không unmount
- ✅ Dùng Tailwind tokens — không hardcode hex
- ✅ Dùng component đẹp nhất trong project (booking form, notes UI) làm chuẩn tham chiếu
- ✅ **Responsive là bắt buộc**: mọi thay đổi layout PHẢI verify ở 3 viewport — mobile (375px), tablet (768px), desktop (1280px); viết mobile-first, rồi override bằng sm:/lg:
- ✅ Component styled bởi bên thứ ba (có `import 'lib/*.css'`) bọc trong wrapper div → wrapper sở hữu TOÀN BỘ visual state (border, ring, disabled opacity); null hết border/shadow bên trong component qua override CSS var + scoped `!important`
- ✅ **Kỷ luật ARIA**: ưu tiên native HTML (`<button>`, `<dialog>`, `<details>`, `<label for>`) hơn ARIA. Chỉ thêm `role`/`aria-*` khi native HTML không diễn đạt được tương tác, và khi đã thêm phải đảm bảo đủ bộ role+state+property — không bao giờ thêm ARIA attribute "phòng khi"
- ❌ KHÔNG thêm animation phức tạp nếu Motion/Framer chưa có sẵn trong project — ngoại lệ: dưới `--wow`, áp dụng dependency allowlist ở trên thay vì rule này
- ❌ KHÔNG thêm màu brand mới — chỉ dùng token hiện có (ngoại lệ: `--wow` được phép thêm accent mới nếu vibe đã chốt yêu cầu)
- ❌ KHÔNG dùng màu mặc định của component library (shadcn blue) nếu project đã có màu primary riêng
- ❌ KHÔNG thêm toast notification không cần thiết
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
8. **Báo cáo ngắn gọn**: "Đã redesign [X]. Thay đổi chính: [liệt kê 3-5 bullet points]"
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
- ❌ Thêm animation lòe loẹt cho app healthcare
- ❌ Copy design sáng tạo từ landing page/portfolio vào product UI
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
- ❌ Thêm toast notification không cần thiết
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

Nhìn vào kết quả thực tế của lần chạy này và tự đề xuất MỘT hành động tiếp theo hợp lý, 1-2 câu — không chọn theo danh sách cố định. Cân nhắc các skill khác trong bộ này (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) nếu thực sự phù hợp; nếu không cần gì thêm thì nói rõ luôn.
