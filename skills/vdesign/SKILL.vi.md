---
name: vdesign
description: "Redesign UI/UX của một page, component, feature hoặc PR diff hiện có theo chuẩn tinh tế, hài hòa, accessible. Đọc real user và task, chạy research thiết kế hiện hành, tự quyết 18 tiêu chí phong cách/cấu trúc (không hỏi trước), rồi audit, fix và verify ở 375/768/1280px. Được sửa API-layer; không được đụng DB schema."
user-invocable: true
when_to_use: "Dùng khi user muốn redesign, nâng cấp, hiện đại hóa hoặc làm cho page, component, feature, PR hiện có đẹp và dễ dùng hơn. Không dùng để dựng UI mới từ đầu, review thiết kế chỉ-đọc, hay sửa 1 dòng CSS."
argument-hint: "[URL | localhost:PORT/path | component | feature | --pr | --diff | [Image]]"
metadata:
  author: vyvu
  version: "10.0.0"
---

# vdesign — Redesign UI/UX

Nâng cấp UI hiện có lên chuẩn thực thi cao: tinh tế, hài hòa, hiện đại, thanh lịch, accessible. Phong cách thật (táo bạo hay tiết chế, gần hệ thống hiện tại hay cố tình tách ra) được quyết lại mỗi lần chạy từ research hiện hành và real user/task, nên không bao giờ hỏi và không bao giờ chép theo thói quen.

`vdesign <target>` là mode duy nhất. Nó audit-driven: sửa mọi thứ audit tìm ra, từ spacing lên tới đổi hướng thị giác. Phase 1 tự quyết đủ 18 tiêu chí trong `references/aesthetic-customization.md` và chốt vào Design Brief trước khi đổi bất kỳ dòng code nào.

Ranh giới: giữ tech stack, chỉ đổi những gì audit và brief đòi hỏi (không thêm feature, test, docs ngoài yêu cầu), và không bao giờ đổi DB schema hay chạy migration. Đổi API/service layer nằm trong phạm vi khi redesign cần, vì view tốt hơn thường cần một field mà API chưa từng trả về.

---

## Input modes

| Input | Xử lý |
|-------|-------|
| _(trống)_ | Hỏi đúng 1 câu: "Bạn muốn redesign phần nào?" |
| URL hoặc `localhost:PORT/path` | Screenshot trước, rồi đọc source tương ứng |
| Route path (vd `/clients/[id]?tab=notes`) | Resolve sang file page và component |
| Tên component hoặc feature | Grep tìm file, rồi đọc component tree |
| `[Image]` | Rút ra khoảng cách thiết kế và áp dụng fix. Cặp before/target (hiện trạng + mockup hoặc ảnh đối thủ) thì reference là chuẩn phải vượt; xem "Beating a reference image" ở Phase 3 |
| `--pr` | `gh pr diff --name-only`, redesign mọi file UI trong đó. Cần gh (`repo-profile.md` §2); không có thì fallback `--diff` |
| `--diff` | `git diff --name-only` cho file UI staged và unstaged |

---

## Sàn chất lượng

Các mục này đúng ở mọi lần chạy bất kể Design Brief quyết gì. Chúng quản việc thực thi tốt đến đâu, không quản chọn gì.

| Từ khóa | Nghĩa trong code |
|---------|------------------|
| Refined | Radius nhất quán, icon đều cỡ, xử lý text overflow, không có spacing lệch scale |
| Harmonious | Hướng đã chốt được áp dụng khắp nơi, không có "đảo" lẻ loi; type, spacing, size theo một modular scale |
| Modern | Không pattern lỗi thời (bảng có viền, button phẳng không state); dùng whitespace tốt |
| Elegant | Hierarchy rõ, ít nhiễu, phân cấp button primary/ghost/link nhìn thấy được |
| Deep | Các tầng elevation rõ với nguồn sáng nhất quán; chỉ phẳng khi quyết định Elevation chọn phẳng |
| Đúng brief | Làm nửa vời một trong hai hướng trông cẩu thả, nên thực thi brief trọn vẹn |
| Accessible | Label rõ, icon quan trọng có tooltip, đủ state empty/loading/error |
| Efficient | Ít click hơn: bulk action, inline edit, smart default an toàn |

Design Brief là hợp đồng. Đừng làm kết quả táo bạo hơn hay bảo thủ hơn điều brief đã chốt, vì trượt về thói quen cá nhân là cách chính khiến output thành generic.

---

## Workflow: Scope → Brief → Audit → Fix → Verify

### Phase 0: Scope và đọc

1. Parse input mode. Target là URL hoặc localhost thì screenshot ngay bằng công cụ browser sẵn có; không có công cụ nào thì nhờ user dán screenshot.
2. `--pr`: resolve VCS profile theo `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (không có file: coi như full gh mode). Degraded mode: in thông báo §2, rồi hỏi tên branch hoặc fallback `--diff`.
3. Project Profile: dùng `.vdesign/profile.md` ở git root (`git rev-parse --show-toplevel`) nếu có. Không có thì suy ra UI library và design token từ `package.json`, `tailwind.config.*` và thư mục components. Vẫn mơ hồ: hỏi 1 câu và đề nghị lưu đáp án vào `.vdesign/profile.md`.
4. **Đọc Real User & Purpose.** Đọc data shape thật cấp cho target: prop type, query/hook/server action nó gọi, và response type hoặc Zod schema (đọc type; output đã render che mất field không dùng). Khi file DB schema với tới được, ghi lại field chưa từng được fetch; sparse check ở Phase 2 dùng chúng. Rồi đứng vào góc nhìn persona (vai trò, mục tiêu task, áp lực thời gian, thiết bị, trình độ) suy từ tên route và context trong profile. Nêu rõ field hay action nào phải nổi bật, cái gì là nhiễu, và cấu trúc hiện tại (table, card grid, kanban, timeline, master-detail, bento, calendar, comparison matrix, tree, feed, hay gì mà data và task đòi hỏi) có hợp persona đó không.
5. Lần đọc này là cổng duy nhất của structural freedom: restructure bất cứ khi nào nó phục vụ task thật, và mỗi restructure phải truy được về một lý do cụ thể nêu ở đây. Ghi persona, task và 2-3 quyết định information architecture vào `plans/reports/vdesign-brief-<slug>-<HHMMSS>.md`.

---

### Phase 1: Research, Brief và scan

Design Brief phụ thuộc vào lần đọc Phase 0 và research bên dưới, nên cả hai đến trước. Không chọn pattern trước khi có brief, vì kết quả sẽ là mớ hỗn hợp thay vì một thiết kế.

**Domain Research.** Slug = domain từ profile + target feature (vd `healthcare-booking-form`).

- Co aspect theo cỡ target, vì fan-out rộng cho target nhỏ tốn nhiều hơn giá trị thu về:
  - Một component hoặc PR diff từ 3 file trở xuống: `ui`, `ux`.
  - Một page hoặc feature (mặc định): thêm `animation`, `layout`, `text`.
  - Cả page nhiều cluster hoặc cả một flow: thêm `3d` (chỉ khi brief có thể dùng chiều sâu không gian), `features`, `flow`. Hai cái cuối chỉ là context tham khảo, không bao giờ mở rộng phạm vi redesign.
- Tái dùng theo từng aspect: file `plans/reports/researcher-vdesign-bold-<slug>-<aspect>*.md` tạo trong session này hoặc hôm nay tính là hit.
- Spawn mỗi aspect miss một subagent, tất cả trong một message. Mỗi brief phải nêu: aspect và target feature trong domain của nó; mục tiêu (pattern hiện hành có tên, không phải lời khuyên chung chung); nguồn (gallery có curate hoặc có giám khảo, case study studio thật như Awwwards, CSS Design Awards, Site Inspire, Behance/Dribbble Featured; brief Game-inspired thì dùng gallery game-UI); output (pattern có tên kèm URL nguồn thật, lưu vào `plans/reports/researcher-vdesign-bold-<slug>-<aspect>-<HHMMSS>.md`); và ranh giới (chỉ research, không sửa code, không đề xuất mở rộng scope cho `features`/`flow`).
- Nghiên cứu top-hit, do bạn làm vì subagent không có browser: nếu có browser automation, mở 1-3 URL nguồn tốt nhất, screenshot để xem bố cục và hierarchy, rồi đọc `getComputedStyle()` trên 1-2 element nổi bật (box-shadow, radius, color, transition). Giá trị computed không bị CSS minified làm mờ. Không có browser tool thì bỏ qua; báo cáo dạng text là mức sàn.
- Aspect lỗi thì retry 1 lần, vẫn lỗi thì ghi "unavailable" trong brief và thay bằng profile cộng sàn chất lượng. Không bao giờ quay về danh sách pattern học thuộc.

**Design Brief.** Quyết đủ 18 tiêu chí theo thứ tự ưu tiên trong `references/aesthetic-customization.md` (Domain Research, rồi Project Profile, rồi lần đọc Real User & Purpose, rồi sàn chất lượng). Sau đó viết brief cụ thể 5-10 dòng: tên typeface thật, hướng palette, timing motion, hướng shape/icon/imagery, spacing scale, layout system, tone, mức táo bạo. Một nhãn một từ cho mỗi tiêu chí không phải brief. Lưu 18 quyết định và brief vào cùng `vdesign-brief-<slug>-<HHMMSS>.md`, kèm trạng thái từng aspect (cached, fresh, bỏ qua theo cỡ, unavailable). Phase 3 đọc lại file này thay vì tin vào trí nhớ hội thoại.

**Component tree.** Trace cả cây, không chỉ một file:

```
Target component/page
  └── local components (level 1) → read
        └── local sub-components (level 2) → read
              └── dừng ở UI library components (package UI của chính project, shadcn, MUI, Radix)
```

Với mỗi file ghi lại class đang dùng, component library có dùng đúng variant không, layout pattern, motion hiện có, và state nào trong loading, empty, error, hover, focus, active, disabled đang có. Đọc thêm design token (`tailwind.config`, `globals.css`) và một component tham chiếu tốt (mục "Good reference UI" của profile, không có thì component bóng bẩy nhất codebase).

Khi user nói "giống X", đọc X trước, vì đoán pattern của nó sẽ cho kết quả trật.

**Component Inventory** (chỉ cho cả page hoặc URL có từ 2 component cluster trở lên): liệt kê mọi instance nhìn thấy thành checkbox đánh số (ba stat card là ba mục) và gom các instance liền kề cùng vai trò thành cluster. Append vào file brief dưới `## Component Inventory`. Phase 3 chọn pilot từ đây và Phase 4 kiểm từng ô.

---

### Phase 2: Audit

Đọc trọn `references/audit-checklist.md` và đi qua từng category. Chỉ flag vấn đề ảnh hưởng chất lượng thị giác hoặc UX. Append findings (đã kiểm, bị flag, và danh sách ứng viên content-density) vào file brief dưới `## Audit Findings`; khi có inventory thì tag mỗi finding với cluster của nó.

---

### Phase 3: Fix

Sửa mọi thứ Phase 2 tìm ra. Spacing, state, đổi component, restructure layout và đổi hướng thị giác đều trong phạm vi. Giữ độ sâu tương xứng: finding chỉ về spacing không cho phép viết lại JSX. Ngoại lệ là layout generic mà mọi section đều là cùng một cái hộp bất kể nội dung; đó tự nó là finding cấu trúc, nên restructure cho khớp nội dung. Thay đổi cấu trúc theo lần đọc Phase 0, không theo giới hạn tương xứng.

**Pilot trước (chỉ khi có inventory).** Component đơn hoặc PR diff bỏ qua bước này và sửa một lượt.
1. Lấy cluster nhiều finding nhất (hòa: cái đứng đầu inventory) và redesign ở độ sâu đầy đủ.
2. Trình bày trước khi đụng cái khác: target URL thì có screenshot before/after, còn lại thì mô tả cụ thể kèm diff của pilot. Hỏi qua `AskUserQuestion`: approve, adjust, hoặc thử hướng khác. Tối đa 3 vòng, sau đó hỏi approve kèm bất đồng đã ghi hay dừng.
3. Sau khi duyệt, lan cùng ngôn ngữ thiết kế (màu, elevation, radius, spacing scale, motion; không phải giá trị chép nguyên) sang phần còn lại, tick từng ô. Table vẫn là table, được restyle, không ép theo hình dạng của pilot.

**Thực thi brief.** Brief táo bạo (Experimental hoặc Trend-forward) cho phép typography scale riêng, layout bất đối xứng, motion tùy biến và khoảnh khắc hoàn thành giàu biểu cảm; brief tiết chế (Brand-centric hoặc Functional) ở gần hệ thống hiện có. Tiết chế vẫn nghĩa là toàn bộ audit dẫn dắt việc restyle: component không có bug nào vẫn có thể trượt check hierarchy hay depth. Nguyên tắc usability (đủ state, giới hạn lựa chọn hiển thị, chỉ confirm hành động phá hủy) là sàn mà độ táo bạo phải vượt qua.

**Một signature element.** Khi brief táo bạo, chốt một nước đi (kỷ luật màu, một typeface, ngôn ngữ motion, phong cách minh họa, hoặc một cử chỉ layout bất đối xứng) và giữ phần còn lại tiết chế xung quanh. Táo bạo rải mỏng đọc còn generic hơn một nước đi chốt hẳn, và nó phải mang tính cấu trúc (scale, contrast, motion làm rõ nghĩa), không bao giờ chỉ để trang trí. Lớp grain CSS/SVG dưới 10% opacity là tùy chọn texture không cần dependency.

**Chỉ lấy pattern từ báo cáo research của lần chạy này** (`ui`, `ux`, `animation`, `layout`, `3d`, `text`). `features` và `flow` chỉ cung cấp thông tin cho brief, không phải nguồn pattern.

**Beating a reference image.** Khớp các thủ pháp của nó trước (grouping, tầng màu, iconography, nước đi layout), rồi vượt ở chỗ ảnh tĩnh không cạnh tranh được: nhất quán xuyên cả flow, motion thật, spacing và contrast đo được, responsive và accessibility thật.

**Revisit giữa chừng.** Nếu lúc thực thi thấy một quyết định không còn hợp (vd *Keep existing tokens* nhưng khoảng trống thật cần một accent), quyết lại đúng tiêu chí đó theo cùng thứ tự ưu tiên, cập nhật dòng của nó trong file brief, tiếp tục, và liệt kê trong báo cáo cuối.

**Dependency.** Kiểm `package.json` trước. Thư viện motion chuẩn cho loại việc này (GSAP với ScrollTrigger, Motion, Lenis, scroll-driven animations gốc và View Transitions, Rive, Lottie) hợp với quyết định motion *Expressive* hoặc *Balanced*. Three.js/React Three Fiber (650KB+), Barba.js, công cụ trả phí và shader tùy biến cần user duyệt vì trọng lượng hoặc chi phí. Nếu hướng dẫn của chính project (vd CLAUDE.md) yêu cầu hỏi trước khi thêm bất kỳ dependency nào, quy tắc đó thắng: hỏi một lần cho cả bộ.

**Anti-slop gate.** Áp dụng mọi lần chạy, vì brief tiết chế nghĩa là tiết chế, không phải generic. Fail lần chạy nếu có: Inter/Roboto là typeface duy nhất, gradient tím-xanh chiếm vai trò chủ đạo, 3 card giống hệt trở lên trong một hàng, tên hay số giả ("John Doe", 50%, $100), copy startup sáo rỗng ("Elevate", "Seamless", "Next-Gen"), nền `#000000` thuần, thiếu hover/focus state, và minh họa flat stock chưa chỉnh (unDraw, Storyset, DrawKit, Blush, Icons8 Ouch, ManyPixels, Open Peeps). Thứ tự ưu tiên minh họa, tốt nhất trước: vẽ tay tùy biến, line-art, isometric 3D, flat chỉnh sâu, hình học/trừu tượng, không dùng. Một icon line hoặc duotone nhỏ (32px trở xuống) tùy biến, đặt có chủ đích, không phải slop.

**Hard rules**, kèm lý do:
- Làm trong stack hiện có; migrate framework nằm ngoài phạm vi.
- DB schema và migration cấm đụng. Đổi API/service được phép khi redesign cần.
- Phơi bày nội dung chỉ xin một lần xác nhận gộp: gom các field chưa render hoặc chưa fetch từ Phase 0 và Phase 2 vào một `AskUserQuestion` ("nối N field này: tất cả / một số / không"), rồi implement các field được chấp nhận end to end. Đây là quyết định về dữ liệu chứ không phải thẩm mỹ, nên cần một lần đồng ý dù style thì không.
- Ẩn bằng opacity/visibility, không unmount, để state của component được giữ.
- Dùng design token, không hardcode hex, để theming còn hoạt động. Màu brand mới chỉ khi quyết định Color là *Accent only*, *Full palette* hoặc *Dynamic*, và không bao giờ dùng màu mặc định của library (vd shadcn blue) khi project có primary riêng.
- Dùng "Good reference UI" của profile làm chuẩn khi brief là Brand-centric.
- Viết mobile-first và override bằng `sm:`/`lg:`; responsive được verify ở Phase 4.
- Wrapper quanh component third-party đã tự style: wrapper sở hữu mọi visual state (border, ring, disabled opacity); null border và shadow bên trong bằng CSS-variable override.
- Ưu tiên HTML gốc (`<button>`, `<dialog>`, `<details>`, `<label for>`) hơn ARIA. Chỉ thêm `role`/`aria-*` khi HTML gốc không diễn đạt được, và khi đó thêm đủ bộ role, state, property, vì ARIA nửa vời tệ hơn không có.
- Chỉ animate `transform` và `opacity` (không width, height, top, left), để motion chạy trên GPU và LCP mobile nằm trong ngân sách.
- Chỉ thêm toast khi là khoảnh khắc hoàn thành có chủ đích; tiêu chí là chủ đích, không phải tối giản.
- Accessibility (contrast, focus ring, đủ state) không bao giờ đánh đổi lấy style.

---

### Phase 4: Verify

1. **Viewport (375, 768, 1280px).** Với mỗi thay đổi layout, load route ở từng độ rộng (resize bằng browser tool hoặc `page.setViewportSize` trong Playwright), screenshot, và chạy check này; có overflow hay nội dung bị cắt thì quay lại Phase 3:
   ```js
   [...document.querySelectorAll('body *')].filter(e => e.getBoundingClientRect().right > innerWidth + 1).slice(0, 5)
   ```
   Danh sách rỗng cộng `document.documentElement.scrollWidth <= innerWidth` nghĩa là không overflow ngang; rồi kiểm bằng mắt rằng không có gì bị cắt, xếp sai, hay touch target dưới 44px. Target component không có route: render nó ở nơi project preview component. Không có browser hay trang chạy được: nói rõ chưa verify viewport, nêu các độ rộng, và không báo là đã verify.
2. Target URL: so screenshot before và after ở 1280px. Input là ảnh: xác nhận code khớp ý ảnh.
3. Chạy format script của project, cùng typecheck hoặc lint nếu có, và sửa những gì redesign làm hỏng.
4. **Accessibility.** Nếu có `@axe-core/playwright` hoặc `axe-core` (hoặc user cho thêm), chạy với route và in violations. Không thì in các bước kiểm thủ công cho user, vì chỉ nhìn bằng mắt không verify được accessibility.
5. **Adversarial verify**, chỉ khi fix đụng cấu trúc (đổi component, restructure layout, đổi hướng), brief táo bạo, hoặc fix logic UX đụng interaction state. Spawn một subagent mới với diff, `references/audit-checklist.md` và anti-slop gate, chỉ-đọc, không thấy lập luận của bạn. Nó trả PASS hoặc danh sách vấn đề còn lại, fix làm quá phạm vi, và vi phạm slop. Lưu báo cáo vào `plans/reports/vdesign-adversarial-<slug>-<HHMMSS>.md`. Có vấn đề thì fix và chạy lại 1 lần.
6. **Self-check** (inline): độ sâu fix tương xứng; mọi audit category áp dụng được đã xử lý hoặc đánh dấu không áp dụng; anti-slop gate thực sự được kiểm; kết quả khớp brief đã chốt; mọi ô inventory được tick hoặc đánh dấu không áp dụng kèm một lý do.
7. **Xác nhận phơi bày nội dung**, chỉ khi có ứng viên được flag: hỏi câu gộp duy nhất từ Hard rules, rồi nối các field được chấp nhận qua API và UI trước khi báo cáo.
8. **Báo cáo ngắn**: "Redesigned [X]. Main changes:" với 3-5 bullet, rồi một dòng nêu brief đã chốt (mức táo bạo và 1-2 tiêu chí định hình nó), trạng thái research từng aspect, kết quả viewport, và kết quả adversarial nếu có chạy. Liệt kê mọi revisit giữa chừng và mọi thứ chưa verify.

Ghi chú Next.js: ảnh ghi đè cùng đường dẫn dưới `public/` có thể vẫn hiện bản cũ vì optimizer cache theo URL và size. Hard-refresh hoặc xóa `.next/cache/images` trước khi sửa tiếp.

---

## Project Profile

Thứ tự resolve nằm ở Phase 0. Profile là bảng ngắn các ràng buộc; hình dạng điển hình:

| Ràng buộc | Chi tiết |
|-----------|----------|
| UI library | Package UI của chính project cộng shadcn/ui; dùng trước HTML thô |
| Design token | CSS variable trong `globals.css`; không thêm màu mới |
| Thư viện motion | vd Framer Motion đã cài |
| Context | vd B2B healthcare: rõ ràng hơn ấn tượng |
| Good reference UI | Hai ba màn hình làm tốt để học pattern |
| Form field | Dùng form wrapper của project, không viết boilerplate thô |

## Pitfalls ngoài audit checklist

- Viết lại cả layout khi chỉ cần chỉnh một phần; nó che mất thay đổi thật và dễ gây regression.
- Line-clamp copy dài ngắn khác nhau trong các card song song; cân lại độ dài copy mới là fix gốc cho card lệch nhau.
- Đổi cấu trúc hoặc thêm field không có liên kết tới lần đọc Phase 0; tự do sáng tạo không phải giấy phép tùy tiện.
- Viết code trước khi có brief; chọn pattern trước tạo ra mớ hỗn hợp.
- Chạy lại research cho aspect đã cache cùng slug; lãng phí subagent.
- Báo xong mà không có screenshot khi đã có URL.

## Bước tiếp theo

Theo quy ước Next Steps trong `_vskills-shared/repo-profile.md` §7.
