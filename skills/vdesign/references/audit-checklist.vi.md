# Checklist Audit Phase 2

Đọc toàn bộ file này ở Phase 2 và duyệt qua từng nhóm — chỉ flag các vấn đề **thực sự ảnh hưởng đến chất lượng visual/UX**. Tách ra khỏi `SKILL.vi.md` để giữ thân skill gọn nhẹ — mọi nhóm ở đây vẫn là 1 phần bắt buộc của workflow Scan → **Audit** → Fix → Verify.

**Lưu ý cú pháp tuỳ framework:** các item bên dưới viết theo shorthand Tailwind/React (`grid-cols-*`, `sm:`, `group-hover:`, `next/image`, v.v.) vì đây là stack phổ biến nhất trong các project của bộ skill này — coi đây là minh họa cho khái niệm CSS/UX bên dưới, không phải yêu cầu literal. Với stack khác (CSS Modules, Chakra, styled-components, Vue/Svelte, CSS thuần), dịch từng item sang cơ chế tương đương (vd `sm:` → mixin/media query breakpoint riêng của project; `grid-cols-1 sm:grid-cols-2` → bất kỳ cách collapse cột responsive nào; `next/image` → component ảnh có size riêng của project, cùng tính điều kiện đã áp dụng cho component ảnh qua §3 của `repo-profile.md`).

---

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
- [ ] Component cùng variant (mọi button primary, mọi input) có cùng height/padding — không lệch âm thầm giữa các instance? Verify qua class/style dùng chung thật sự, không chỉ nhìn qua bằng mắt.
- [ ] Vertical rhythm: khoảng cách giữa các block xếp chồng là bội số của base line-height, không tùy tiện?
- [ ] Căn chỉnh optical của icon: glyph thị giác của icon (không phải container box của nó, thường có padding sẵn bên trong) được căn giữa theo cap-height/x-height của text bên cạnh — container tự căn giữa với chính nó vẫn có thể nhìn lệch tâm so với text?
- [ ] Mọi giá trị spacing/radius trong diff resolve về đúng token đã khai báo (Tailwind scale, CSS var) — không dùng giá trị "gần đúng" token (`p-[15px]` "gần bằng" `p-4`) làm vỡ lưới âm thầm?

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
- [ ] **Kiểm tra sparse/trống trải**: view có đọc ra trống/thiếu so với whitespace của nó trong khi data/props/API response bên dưới đã có field chưa được render? Đánh dấu là cơ hội tăng content-density — không bao giờ bịa data để lấp chỗ trống, và không bao giờ tự thêm (xem Phase 3/4 của `SKILL.vi.md`: đề xuất content-density luôn cần user duyệt trước, mọi lúc).

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
- [ ] **Kiểm tra illustration slop**: illustration unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps chưa customize trong hero/empty-state/onboarding → flag là slop, ngang tier với gradient tím-xanh/Inter-only (xem anti-slop gate trong `SKILL.vi.md`). Fix theo tier: hand-drawn custom > line-art/sketch > isometric 3D > flat đã customize kỹ (đổi palette + pose riêng, không dùng scene stock) > geometric/abstract > bỏ hẳn illustration.
- [ ] **Hero video** (nếu có): `muted autoplay loop playsinline` + poster tĩnh fallback (JPEG); swap sang ảnh tĩnh trên mobile (`max-width: 768px`) để bảo vệ LCP.
- [ ] **Responsive art direction** (khi mobile/desktop cần bố cục khác nhau, không chỉ là scale nhỏ lại): dùng `<picture>` + `<source>` theo media-query để crop khác nhau, không phải một ảnh bị co giãn bằng CSS.

#### Riêng cho Form/Wizard
- [ ] Stepper: chiều cao gọn, không lãng phí không gian dọc
- [ ] Layout form: label + input canh đều nhất quán
- [ ] Validation error: hiện ngay dưới field, không chỉ ở trên đầu
- [ ] Wizard nhiều bước: chỉ báo tiến trình rõ ràng
- [ ] Tham chiếu: dùng mục "Good reference UI" trong Project Profile làm chuẩn vàng cho pattern form/wizard — không có → form được làm tốt nhất đã có sẵn trong project

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
