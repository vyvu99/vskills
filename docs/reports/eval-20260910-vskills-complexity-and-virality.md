# Đánh giá toàn diện `vskills` (lượt 2): độ phức tạp & khả năng lan truyền

**Ngày**: 2026-09-10
**Câu hỏi cần trả lời**: (1) Bộ skills này có phức tạp quá không? (2) Có thể viral không?
**Phương pháp**: đo bằng lệnh trên repo (không ước lượng), đối chiếu chuẩn Anthropic + kênh phân phối thật. Toàn bộ lệnh ở §D.

---

## 0. Kết luận nhanh

**Phức tạp quá không?** — **Không, nếu xét đúng chỗ; có, ở đúng 2 skill.**

Đánh giá trên cây `origin/main` (`347d870`), đã gồm bản `vdesign` v6.0.0 bạn vừa ship.

Progressive disclosure nghĩa là mỗi lần chạy chỉ **một** skill nạp vào context. 8/10 skill nặng 1.071–1.966 token — rất nhẹ so với ngưỡng khuyến nghị 5.000 token. Chỉ **`vreview` (6.832 token) và `vdesign` (7.759 token — tăng từ 6.569 sau v6.0.0)** vượt ngưỡng, và hai skill này chiếm **70% tổng số chỉ thị MUST/NEVER của cả pack** (35/50). Vấn đề không phải "10 skill là nhiều" — mà là **2 skill đang gánh phần của 8 skill còn lại**.

v6.0.0 làm **đúng một nửa**: bề mặt tham số của `vdesign` gọn hẳn (`[--L1|--L2|--L3]` biến mất, chỉ còn `[--wow]`) nhưng thân skill lại **nặng thêm 30 dòng / ~1.190 token** (16 archetype + Phase 4 Verify). Tức là complexity **dịch chuyển** từ chỗ người dùng phải nhớ sang chỗ agent phải đọc — đúng hướng cho người dùng, sai hướng cho ngân sách context.

**Có viral không?** — **Chưa, và lý do không nằm ở chất lượng.** Repo thiếu toàn bộ hạ tầng phân phối: không `.claude-plugin/marketplace.json`, không `plugin.json`, không CI, không `CONTRIBUTING`, không `CHANGELOG`. Trong khi **layout `skills/<name>/SKILL.md` của repo đã tương thích sẵn** với `npx skills add owner/repo --skill <name>` — tức là kênh phân phối lớn nhất của hệ sinh thái đang mở sẵn mà repo chưa cắm vào. Đây là việc ~1 giờ, không phải viết lại.

---

## 1. Về phiên bản được đánh giá — và một lỗi của tôi ở lượt trước

Ở bản nháp trước tôi kết luận *"repo chưa có thay đổi nào, bạn chưa sửa gì"*. **Kết luận đó sai.** Nguyên nhân: workspace của tôi được checkout từ commit `9a32050`, trong khi các bản sửa của bạn nằm trên `origin/main` — và **hai lịch sử này không có tổ tiên chung**:

```
$ git rev-parse origin/main        → 347d870  "chore: stop tracking plans/ directory, add to .gitignore"
$ git rev-parse 9a32050            → 9a32050  (base của workspace tôi)
$ git merge-base 9a32050 origin/main
  (rỗng)                                        ← KHÔNG có common ancestor
$ git merge-base --is-ancestor 9a32050 origin/main && echo YES || echo NO
  NO  → DIVERGED
```

Nên khi tôi chạy `git diff` trong workspace, kết quả đúng là rỗng — nhưng đó là vì tôi đang so với chính cái cây cũ, **không phải vì bạn không sửa gì**. Bài học cho tôi: phải so với `origin/main` trước khi khẳng định "không có thay đổi".

### Bạn đã sửa gì (đọc từ `origin/main`)

`git diff --stat 9a32050 origin/main -- skills/` →

```
skills/vdesign/SKILL.md    | 108 +++++++++++++++++++++++++++++----------------
skills/vdesign/SKILL.vi.md | 108 +++++++++++++++++++++++++++++----------------
2 files changed, 138 insertions(+), 78 deletions(-)
```

Kèm 2 journal mới mà workspace tôi không có: `docs/journals/20260909-vdesign-level-collapse-wow-launch.md` và `docs/journals/20260819-vdesign-bold-8-aspect-expansion.md`. Theo journal 2026-09-09, **`vdesign` đã lên v6.0.0** (breaking change, `version: "6.0.0"` ở dòng 11 — verified):

1. **Xoá hẳn thang `--L1`/`--L2`/`--L3`** — mặc định giờ = ngữ nghĩa `--L3` cũ (audit-driven, sửa mọi thứ Phase 2 tìm ra, không trần độ sâu). Journal ghi lý do: "real usage confirmed `--L1`/`--L2` were **never invoked in practice**".
2. **Đổi tên `--bold` → `--wow`**, bỏ prerequisite cũ.
3. **Mở rộng archetype catalog 3 → 16 vibes** + kỷ luật "one signature element, boldness must be structural" + bảng 6 pattern.
4. **Phase 2 "Decorative Images" → "Media & Images"**, thêm phát hiện illustration-slop (unDraw/Storyset/DrawKit/Blush/Icons8-Ouch/ManyPixels/Open-Peeps chưa tuỳ biến — dòng 325).
5. **Thêm tầng verify độc lập (Phase 4: Adversarial Verify**, dòng 346**)** — subagent re-audit trạng thái cuối với mắt mới, tách khỏi agent đã viết fix; kèm Self-Check gate về tính tương xứng của fix.

**Mục 5 giải quyết đúng một finding tôi nêu ở lượt trước** (agent tự chấm bài của chính mình). Journal ghi nguyên văn nguyên nhân gốc: "the agent writing the fix also grades its own audit/fix/anti-slop compliance — no independent re-check". Đây là điểm tôi đánh giá cao nhất trong lượt sửa này.

**Hệ quả cho bản đánh giá này:** mọi con số về `vdesign` bên dưới đã được **đo lại trên cây `origin/main`**, không phải trên cây cũ. 9 skill còn lại **không đổi một byte nào** — `git diff --stat 9a32050 origin/main -- skills/` chỉ liệt kê `vdesign`.

Hai việc khác rút ra từ `347d870`:

- **`plans/` giờ nằm trong `.gitignore`** (`.gitignore` trên `origin/main` có 4 dòng, dòng cuối là `plans/`; `git check-ignore -q plans` → exit 0). Nên hai báo cáo này đặt ở **`docs/reports/`** thay vì `plans/reports/` như lượt trước — thêm vào `plans/` sẽ đi ngược quyết định explicit của commit đó.
- `origin/main` có **108 file** so với 123 ở base cũ — chênh đúng 17 file `plans/**` đã bỏ track (verified bằng `git ls-tree -r --name-only | wc -l` + `comm`).

## 2. PHẦN A — Độ phức tạp, đo bằng số

### A1. Chi phí context

**Tầng 1 — listing (luôn nằm trong context, kể cả khi không dùng skill):**

```
tổng ký tự description + when_to_use của 10 skill: 3.982  (~995 tokens)
budget 1% của context 200K   = 2.000 tokens  → pack chiếm ~49%
budget 1% của context 1M     = 10.000 tokens → pack chiếm ~9%
```

→ **Chưa tràn**, nhưng với context 200K thì pack đã ăn gần nửa ngân sách listing. Theo cơ chế đã công bố, khi listing tràn thì Claude Code **cắt description của skill ít dùng nhất trước** — skill vẫn hiện tên nhưng mất keyword và **âm thầm ngừng trigger**. Với 10 skill thì còn chỗ; nếu bạn thêm lên 20–25 skill mà không cắt description thì sẽ bắt đầu mất trigger mà không có lỗi nào báo.

**Tầng 2 — activation (chỉ skill đang chạy):**

| skill | ~token | so với ngưỡng 5.000 |
|---|---|---|
| `vreview` | **6.832** | **VƯỢT +1.832** |
| `vdesign` | **7.759** | **VƯỢT +2.759** (v6.0.0: 6.569 → 7.759) |
| `vcook` | 1.966 | ok |
| `vfix` | 1.876 | ok |
| `vspecs` | 1.437 | ok |
| `vissues` | 1.429 | ok |
| `vplan` | 1.413 | ok |
| `vcheck` | 1.174 | ok |
| `vrules` | 1.088 | ok |
| `vmigrate-rollback` | 1.071 | ok |

→ Đây là bức tranh quan trọng nhất: **8/10 skill rất tinh gọn.** Trung vị ~1.400 token. Hai skill vượt ngưỡng là ngoại lệ, không phải đặc trưng của pack. Nói "bộ skills này quá phức tạp" là sai về mặt số liệu; nói "`vreview` và `vdesign` quá phức tạp" là đúng.

Tổng pack: **2.062 dòng / ~26.045 token** (trước v6.0.0: 2.032 dòng / ~24.855 token). Riêng `vdesign` đi từ 386 → **416 dòng**.

### A2. Mật độ chỉ thị & nhánh rẽ

| skill | cờ `--` | `if` | bullet | MUST/NEVER/DO NOT | CLI ngoài |
|---|---|---|---|---|---|
| `vdesign` | **2** | **38** | **160** | **19** | 3 |
| `vreview` | 12 | 30 | 124 | 16 | 5 |
| `vcook` | 2 | 23 | 40 | 6 | 2 |
| `vfix` | 0 | 20 | 12 | 3 | 3 |
| `vmigrate-rollback` | 0 | 16 | 20 | 0 | **8** |
| `vplan` | 0 | 15 | 16 | 2 | 0 |
| `vissues` | 6 | 12 | 13 | 3 | 2 |
| `vspecs` | 0 | 11 | 25 | 0 | 0 |
| `vcheck` | 4 | 10 | 15 | 0 | 5 |
| `vrules` | 1 | 10 | 14 | 1 | 2 |
| **Tổng** | | **185** | **439** | **50** | |

Đọc bảng này theo 3 cách:

0. **Cột "cờ `--`" của `vdesign` tụt từ 11 xuống 2** — hệ quả trực tiếp của việc xoá thang level. Đây là điểm cộng rõ rệt của v6.0.0 về mặt "người dùng phải nhớ bao nhiêu".
1. **`vdesign` + `vreview` = 284/439 bullet (65%) và 35/50 chỉ thị cưỡng chế (70%).** Nếu bạn muốn giảm độ phức tạp cảm nhận của cả pack, chỉ cần chạm vào 2 file.
2. **`vmigrate-rollback` là skill ngắn nhất (82 dòng, 0 chỉ thị MUST) nhưng chạm nhiều CLI ngoài nhất (8: docker, psql, mysql, sqlite3, prisma, drizzle-kit, knex, typeorm).** Đây là tỉ lệ nguy hiểm ngược: ít ràng buộc bằng văn bản, nhiều bề mặt thực thi thật. Skill destructive nhất pack lại là skill có ít chốt cứng nhất. (Các chốt an toàn của nó nằm trong mục "Hard rules" dạng bullet, không dùng từ khoá MUST — nên bộ đếm không bắt được, nhưng mật độ vẫn thấp.)
3. **50 chỉ thị cưỡng chế trên 10 skill = 5/skill.** Nghiên cứu về verify code-so-với-spec đo được rằng **prompt càng nhiều bước thì phán đoán càng tệ** (RCRR của GPT-4o rơi từ 52,4% xuống 11,0% khi chuyển từ prompt trực tiếp sang prompt 3 bước đầy đủ). Với `vdesign`/`vreview` (19 và 16 chỉ thị), đây không phải chuyện thẩm mỹ — nó có khả năng **làm giảm chất lượng đầu ra**.

### A3. Bề mặt tham số người dùng phải nhớ

```
vcheck             [package-names...] [--test]
vcook              [plan-path | task description] [--issue <number>]
vdesign            [URL | localhost:PORT/path | component | feature | --pr | --diff | [Image]] [--wow]
vfix               [path to report dir, default .code-review/]
vissues            <plan-path>
vmigrate-rollback  <migration-name-or-version>
vplan              [specs-file-path]
vreview            [branches | #PR | PR-URL | --since <dur> | --path <dirs>] [--base <branch>] [--exclude <paths>] [--harvest]
vrules             <PR-number>
vspecs             Feature: [feature name] \n Compare: [product name] (optional)
```

→ **9/10 skill có bề mặt tham số đơn giản** (1 tham số, hoặc 1 cờ). Sau v6.0.0 chỉ còn **`vreview`** (4 nhóm tham số + 3 dạng positional) là nặng; `vdesign` đã giảm từ `7 input mode × 3 level × bold` xuống `7 input mode × 1 cờ`. Đây là chỗ "phức tạp" thật sự mà người dùng cảm nhận được — không phải số dòng, mà là **số lựa chọn phải đưa ra trước khi skill bắt đầu chạy**.

### A4. Đồ thị phụ thuộc giữa các skill

Đo bằng cross-reference trong body (đã loại câu boilerplate "Next steps") + artifact đọc/ghi:

```
ĐỘC LẬP (chạy được ngay, không cần gì):
  vcheck · vdesign · vmigrate-rollback · vrules · vspecs          (5/10)

CHUỖI:
  vspecs ──plans/specs/<slug>.md──▶ vplan ──plans/<slug>/──▶ vcook     (HARD: vplan từ chối tự tạo specs)
                                     └────────────────────▶ vissues    (HARD: Step 1 bắt buộc đọc plan.md)
  vreview ──.code-review/──▶ vfix                                      (SOFT: vfix có fallback hỏi user)

PHỤ THUỘC CỜ INSTALL (không phải skill khác):
  vreview / vfix      ← ~/.claude/scripts/lint-rules     (--with-scripts;   fallback {"error":...})
  vreview/vcook/vrules ← ~/.claude/CLAUDE.md             (--with-claude-md; fallback English)

PHỤ THUỘC NGOÀI REPO (điểm gãy):
  vdesign --wow       ← ~/.claude/skills/frontend-design/references/*.md   (2 tham chiếu, KHÔNG cài được từ repo này)
```

→ **Đây là điểm tốt bất ngờ.** 5/10 skill hoàn toàn độc lập, và chỉ có **3 liên kết cứng** (`vspecs→vplan`, `vplan→vissues`, `vdesign --wow→frontend-design`). Một "pack 10 skill" thường rối vì mọi skill gọi mọi skill; pack này thì không. Đồ thị gần như là một đường thẳng + vài nút rời.

**Nhưng** hệ quả của đồ thị này với câu hỏi viral là quan trọng: **giá trị của pack nằm ở chuỗi, mà chuỗi thì không lan truyền được.** Không ai chia sẻ "hãy cài 4 skill theo đúng thứ tự và chạy đúng pipeline của tôi". Người ta chia sẻ **một** skill giải quyết **một** nỗi đau. `vcheck` và `vmigrate-rollback` là 2 skill duy nhất trong repo có thể đứng một mình và được chia sẻ ngay.

### A5. Các skill có tranh nhau trigger không? — **Không**

Đo cosine similarity giữa `description + when_to_use` của từng cặp (45 cặp):

```
0.22  vplan  vs vspecs   (chung: add, cases, codebase, create, existing, feature, file, read)
0.14  vissues vs vplan
0.10  vdesign vs vspecs
0.09  vcheck vs vmigrate-rollback / vreview vs vrules / vissues vs vspecs
0.08  vcook vs vplan / vrules vs vspecs
```

Và số từ khoá **chỉ xuất hiện ở 1 skill duy nhất** (càng nhiều càng dễ trigger đúng):

```
vfix 33/47 · vmigrate-rollback 28/34 · vreview 27/46 · vcook 26/42 · vrules 17/30
vplan 16/37 · vcheck 15/26 · vdesign 15/20 · vissues 15/27 · vspecs 10/24
```

→ **Cặp trùng cao nhất chỉ 0,22** (vplan/vspecs) — thấp, và trùng đó là hợp lý vì chúng đứng cạnh nhau trong pipeline thật. Mỗi skill có 10–33 từ khoá đặc trưng. **Routing của pack này khoẻ.** Đây là thứ nhiều repo skill lớn làm hỏng và bạn thì không.

### A6. Vậy "phức tạp quá không?" — kết luận

| Câu hỏi | Trả lời | Căn cứ |
|---|---|---|
| 10 skill có phải quá nhiều? | **Không** | Listing ~995 token = 49% budget 200K, còn chỗ; routing không xung đột (max 0,22) |
| Pack có rối vì skill gọi skill? | **Không** | 5/10 độc lập; chỉ 3 liên kết cứng |
| Skill có quá dài? | **2/10 có** | `vreview` 6.832 và `vdesign` 7.759 token, vượt ngưỡng 5.000 |
| Có quá nhiều chỉ thị cưỡng chế? | **Tập trung ở 2 skill** | `vdesign` 19 + `vreview` 16 = 70% cả pack |
| Người dùng có phải nhớ nhiều? | **1/10 nặng** | chỉ `vreview` (4 nhóm tham số + 3 dạng positional). `vdesign` đã gọn lại ở v6.0.0 |
| Có phức tạp "vô ích" không? | **Có, ở tầng siêu dữ liệu** | `category`/`keywords` trên **9** skill và `extends` trên **4** skill là **field không tồn tại trong spec** → không được đọc. Đây là độ phức tạp thuần tuý trang trí |

**Một câu:** pack không phức tạp — **2 skill trong pack phức tạp**, và phần phức tạp còn lại là **siêu dữ liệu chết**.

**v6.0.0 đã dịch chuyển complexity đúng hướng cho người dùng** (bề mặt tham số gọn hơn, bỏ được thang level không ai dùng, có verify độc lập) **nhưng chưa giảm được complexity tổng** (`vdesign` nặng thêm 1.190 token). Việc còn lại thuần tuý là cơ học: đẩy phần nội dung tham khảo (16 archetype, checklist Phase 2 = 166 dòng) sang `references/` để nó chỉ nạp khi cần.

---

## 3. PHẦN B — Có viral không?

### B1. Kênh phân phối: repo đang thiếu gì (đã verify bằng `ls`/`glob`)

```
.claude-plugin/ present:      False     → không phải plugin, không phải marketplace
plugin.json present:          False
marketplace.json present:     False
.github/workflows:            NONE      → không CI, không validate khi có PR
CONTRIBUTING.md:              False
CHANGELOG.md:                 False
```

Ba kênh phân phối thật của hệ sinh thái, và trạng thái của repo với từng kênh:

| Kênh | Cách người dùng cài | vskills sẵn chưa? |
|---|---|---|
| **Skills CLI** (`npx skills`, Vercel Labs — "npm cho agent") | `npx skills add vyvu99/vskills --skill vcheck -a claude-code` | **GẦN SẴN.** CLI đọc layout `skills/<name>/SKILL.md` — repo đã đúng layout. Chưa verify được là có chạy thật không (xem §D) |
| **Claude Code plugin marketplace** | `/plugin marketplace add vyvu99/vskills` → `/plugin install vskills@vskills` | **CHƯA.** Cần `.claude-plugin/marketplace.json` ở gốc repo + `.claude-plugin/plugin.json`. Format đã có trong docs chính thức |
| **Cài tay** | `git clone` + `./install.sh` | **Đang là cách duy nhất.** Đây là cách có ma sát cao nhất |

Chi tiết quan trọng về plugin: `.claude-plugin/` **chỉ chứa manifest**, mọi thứ khác (`skills/`, `agents/`, `hooks/`, `.mcp.json`) nằm ở gốc plugin — và "the most common mistake is placing functional directories inside `.claude-plugin/`". Cấu trúc hiện tại của vskills (`skills/` ở gốc) **đã khớp**, chỉ cần thêm 2 file JSON.

### B2. Công thức của repo lan truyền được — và vskills lệch ở đâu

Quan sát từ các bảng xếp hạng/danh sách skill phổ biến, nhóm thắng rơi vào **đúng 3 dạng**:

| Dạng | Ví dụ trong các listing | Vì sao lan |
|---|---|---|
| **Một ý tưởng, một file** | một `CLAUDE.md` duy nhất; skill "cắt 65% token"; skill "chống AI slop" | Mô tả được trong 1 câu tweet. Cài 1 lệnh. Không cần hiểu hệ sinh thái |
| **Mega-library + installer** | collection 227 skill / 13 category; library 1.600+ skill | Giá trị ở số lượng + search. Người dùng cài 1–2 skill, không cài cả bộ |
| **Chính chủ / vendor** | `anthropics/skills`, Google, Vercel, Trail of Bits, DuckDB | Ăn theo thương hiệu + có trong awesome-list mặc định |

> Ghi chú trung thực: các nguồn xếp hạng sao **mâu thuẫn nhau nghiêm trọng** (cùng một repo `superpowers` được 3 nguồn khác nhau báo là 40,9K, 94K và 228.740 star). Nên tôi **không dùng số star làm dữ liệu** — chỉ dùng **cấu trúc** của nhóm thắng, thứ nhất quán giữa các nguồn.

**vskills không thuộc dạng nào trong 3 dạng đó.** Nó là dạng thứ 4: *"pipeline cá nhân có quan điểm, gồm 10 skill khớp nhau"*. Dạng này có giá trị thật (và README hiện tại giải thích rất tốt), nhưng nó đòi người đọc **hiểu cả pipeline trước khi thấy giá trị của bất kỳ phần nào** — đó là định nghĩa của ma sát lan truyền.

### B3. 12 điểm nghẽn cụ thể, xếp theo (tác động ÷ công sức)

| # | Điểm nghẽn | Bằng chứng trong repo | Sửa |
|---|---|---|---|
| 1 | **Không có `marketplace.json`/`plugin.json`** | verified `False` | 2 file JSON, ~1h → mở kênh `/plugin install` |
| 2 | **Không có `npx skills` badge/one-liner trong README** | README chỉ có `git clone` + `./install.sh` | 1 dòng README |
| 3 | **`install.sh` ghi vào `~/.claude` (global), không phải project-level** | `SKILLS_DST="$HOME/.claude/skills"` | Thêm `--project` ghi vào `.claude/skills/`. Skills CLI khuyến nghị rõ "always install at project-level, never `-g`" |
| 4 | **Claude-Code-only.** `install.sh` chỉ symlink vào `~/.claude/skills` | verified | SKILL.md là chuẩn mở (agentskills.io); thêm target `.agents/skills/`, `.codex/skills/`, `.cursor/skills/`, `.github/skills/` → mở rộng đối tượng ngay |
| 5 | **`--lang=vi` không tương thích `npx skills`** — CLI luôn cài `SKILL.md`, không biết `SKILL.vi.md` | `install.sh` tự map `SKILL.vi.md → SKILL.md` | Xuất bản bản EN làm mặc định; VI thành variant có tài liệu riêng, đừng đặt cùng cấp |
| 6 | **Không CI** | `.github/workflows: NONE` | 1 workflow chạy check giới hạn dòng/cap description/field hợp lệ/rule executable — chính là `check-skills.sh` tôi đề xuất lượt trước |
| 7 | **3 rule script không bao giờ chạy** (trong đó `be-update-no-org-scope` chống cross-tenant) | verified `-rw-r--r--`, `run.sh` có `[[ -x ]] \|\| continue` | `chmod +x`, 1 phút. Nếu ai đó fork và phát hiện ra, đây là thứ giết uy tín |
| 8 | **9/70 rule thiếu entry registry** → severity fallback `'unknown'/'warning'` | verified `merge-reports.js:65` | Bổ sung registry |
| 9 | **`vdesign --wow` gãy nếu không có skill `frontend-design`** | 2 tham chiếu `~/.claude/skills/frontend-design/...` (dòng 320, 325), không cài được từ repo | Inline bản tối thiểu |
| 10 | **Không `CHANGELOG`** trong khi skill có `metadata.version` (vdesign đã 5.2.0, 2 breaking change trong 2 ngày theo journal) | verified | Thêm CHANGELOG |
| 11 | **`vreview` description chứa cả workflow** → agent có thể không đọc body | 385 ký tự mô tả đủ 6 phase | Viết lại thành "làm gì + khi nào" |
| 12 | **Không skill nào có `disable-model-invocation`** → Claude có thể tự gọi `vmigrate-rollback` (destructive nhất pack) | verified | 5 skill side-effect |

**Nhận xét về #1–#5:** năm điểm nghẽn lớn nhất **không đòi sửa một dòng skill nào**. Chúng là việc đóng gói. Đây là lý do tôi nói "chưa viral được, và lý do không nằm ở chất lượng".

### B4. Cái gì trong repo này **có** khả năng lan

Xếp theo "một người lạ có cài và chia sẻ nó trong 60 giây không":

| Skill | Khả năng đứng một mình | Vì sao |
|---|---|---|
| **`vmigrate-rollback`** | ⭐ cao nhất | Nỗi đau phổ quát, ai cũng từng dính: rollback migration local. Tự detect Drizzle/Prisma/Knex/TypeORM + Docker. Không skill phổ biến nào làm việc này. **Nhưng phải sửa #7/M1/M2 trước** — currently sai cơ chế Prisma và Drizzle tracking |
| **`vcheck`** | ⭐ cao | "typecheck + build song song cả monorepo, auto-detect package manager". Đơn giản, an toàn, dùng được ngay. Nhẹ nhất pack (1.174 token) |
| **`vdesign`** | trung bình | Chủ đề hot (chống AI slop), nhưng đang phụ thuộc skill ngoài và vượt token |
| **`vreview`** | trung bình | Giá trị cao nhưng 6.832 token + cần `CLAUDE.md` + cần lint-rules → nhiều điều kiện trước khi thấy giá trị |
| `vspecs`/`vplan`/`vcook`/`vfix`/`vissues` | thấp khi tách rời | Giá trị nằm ở chuỗi. Tách ra thì thành "một cách làm trong nhiều cách" |
| `vrules` | thấp | Ý tưởng hay (CLAUDE.md tự cải thiện) nhưng là vector bảo mật nếu không có trust boundary |

**Chiến lược hợp lý:** đừng viral cả pack. **Viral `vmigrate-rollback` và `vcheck` như hai skill độc lập**, để chúng kéo người ta vào repo, rồi README giới thiệu phần còn lại như "và đây là pipeline đầy đủ nếu bạn muốn". Đó chính xác là cách các mega-library trong listing hoạt động — người dùng đến vì 1 skill, ở lại vì catalog.

### B5. Kế hoạch 30 ngày, xếp thứ tự

**Tuần 1 — sửa cái sai (không sửa thì đừng phát hành):**
1. `chmod +x` 3 rule + bổ sung 9 entry registry
2. Sửa `vmigrate-rollback` Prisma (`migrate diff` + `db execute`, vì `migrate resolve --rolled-back` chỉ áp dụng cho migration **đã fail**) và Drizzle (`drizzle."__drizzle_migrations"`, match theo `hash`/`created_at`, không phải `name`)
3. `disable-model-invocation: true` cho `vmigrate-rollback`, `vcook`, `vfix`, `vissues`, `vrules`
4. Trust boundary cho `vrules` (comment PR là untrusted, không được ghi instruction vào `CLAUDE.md`)

**Tuần 2 — đóng gói (mở kênh phân phối):**
5. `.claude-plugin/marketplace.json` + `.claude-plugin/plugin.json`
6. Dòng `npx skills add vyvu99/vskills --skill vcheck -a claude-code` lên đầu README + badge
7. `.github/workflows/validate.yml` chạy `check-skills.sh`
8. `install.sh --project` (ghi vào `.claude/skills/`)

**Tuần 3 — giảm độ phức tạp ở đúng 2 chỗ:**
9. Tách `vreview` 767 dòng → `SKILL.md` ~250 dòng + `references/` (5 file prompt)
10. Chuyển checklist Phase 2 của `vdesign` (dòng 129→294, **166 dòng**) sang `references/audit-checklist.md`
11. Viết lại `description` của `vreview`
12. Xoá `category`/`keywords`/`extends` (field chết) trên cả 10 skill

**Tuần 4 — mở rộng đối tượng:**
13. `install.sh --agent=codex|cursor|copilot` (target `.codex/skills/`, `.cursor/skills/`, `.github/skills/`)
14. `CHANGELOG.md` + `CONTRIBUTING.md`
15. Submit vào 1–2 awesome-list và `skills.sh`
16. Viết 3 eval đầu tiên (theo khuôn Anthropic: with-skill vs baseline, đo token/time/pass-rate)

---

## 4. PHẦN C — Finding lượt trước: cái nào v6.0.0 đã xử lý, cái nào còn nguyên

**Đã được xử lý bởi v6.0.0 (không cần làm lại):**

| Finding lượt trước | v6.0.0 làm gì | Verified trên `origin/main` |
|---|---|---|
| Agent tự chấm bài của chính mình (audit + fix + anti-slop cùng một context) | Thêm **Phase 4: Adversarial Verify** — subagent re-audit trạng thái cuối độc lập, loop về Phase 3 nếu còn lỗi | `### Phase 4: Verify` ở dòng **346** |
| Thang `--L1/--L2/--L3` là overhead không ai dùng | Xoá hẳn; mặc định = ngữ nghĩa `--L3` cũ | `argument-hint` chỉ còn `[--wow]` |
| "Boldness" chung chung, output vẫn generic | 16 archetype + kỷ luật "one signature element, boldness must be structural" + bảng 6 pattern | journal 2026-09-09, mục 3 |
| Thiếu phát hiện stock-illustration slop | Phase 2 "Media & Images" + danh sách 7 nguồn illustration + thang fix theo tier | dòng **325** |

**Còn nguyên (đo lại trên `origin/main`, không phải trên cây cũ):**

| ID | Nội dung | Bằng chứng verify lại |
|---|---|---|
| X8.1 | 3 rule script không executable → `be-update-no-org-scope` (chống cross-tenant) không bao giờ chạy | `git ls-tree origin/main scripts/lint-rules/rules/` → **67× `100755` + 3× `100644`**; đúng 3 tên: `be-audit-unknown-fallback`, `be-update-no-org-scope`, `fe-json-stringify-memo-deps` |
| X8.2 | 9/70 rule thiếu entry `rule-registry.json` → severity fallback `'unknown'/'warning'` | script đối chiếu chạy trên `origin/main`: registry 61 entry / 70 rule file |
| M2 | `vmigrate-rollback` Step 4: `prisma migrate resolve --rolled-back` chỉ dùng cho migration đã fail | skill không đổi (`git diff --stat` không liệt kê) |
| M1 | `vmigrate-rollback` Step 5: Drizzle tracking ở schema `drizzle`, cột `hash`/`created_at` | như trên |
| X5/RU1 | `vrules` ghi input untrusted vào `~/.claude/CLAUDE.md` — vector persistence | như trên |
| X1 | `disable-model-invocation` thiếu trên 5 skill side-effect | `grep -rl 'disable-model-invocation' skills/` → **rỗng** |
| **D1** | `vdesign` dùng 44×44px; WCAG 2.2 AA là **24×24 CSS px** (SC 2.5.8) | **vẫn còn sau v6.0.0** — dòng **238**: "Touch targets ≥ 44×44px for every interactive element" |
| X9/S8 | `vspecs` lệch 1 dòng EN(147)/VI(148) | script parity chạy lại, vẫn in DRIFT |
| X2 | `category`/`keywords`/`extends` là field chết | `grep -rl` → `category`/`keywords` **9** skill, `extends` **4** skill |
| D9 | `vdesign --wow` phụ thuộc skill `frontend-design` ngoài repo, không có fallback | **2** tham chiếu ở dòng 320, 325 |

**Lưu ý về D1:** đây là finding duy nhất trong nhóm P0 mà v6.0.0 **đã chạm vào đúng file nhưng không sửa**. Dòng 238 vẫn nằm trong checklist Phase 2 vừa được rework. Sửa 1 dòng: `≥ 44×44px` → `≥ 24×24 CSS px (WCAG 2.2 SC 2.5.8 AA); 44×44 là khuyến nghị iOS, không phải ngưỡng AA`.

---

## 5. PHẦN D — Lệnh đã chạy & phần chưa kiểm chứng

**Đã chạy ở lượt này:**

```bash
# phát hiện phân kỳ lịch sử
git rev-parse origin/main; git rev-parse 9a32050
git merge-base 9a32050 origin/main                 # rỗng -> không có common ancestor
git merge-base --is-ancestor 9a32050 origin/main   # exit 1 -> DIVERGED
git log --oneline 9a32050..origin/main             # 347d870
git diff --stat 9a32050 origin/main -- skills/ scripts/ install.sh claude-md/
git ls-tree -r --name-only {9a32050,origin/main} | wc -l; comm -13 / comm -23
git show origin/main:.gitignore
git show origin/main:docs/journals/20260909-vdesign-level-collapse-wow-launch.md
git ls-tree origin/main scripts/lint-rules/rules/  # mode 100644 vs 100755

# đo lại toàn bộ trên cây origin/main (git archive -> /tmp/om)
python3   # dòng / token / cờ -- / if / bullet / MUST-class / CLI ngoài, per skill
python3   # argument-hint, dead fields, version, EN-VI parity, listing cost
python3   # cosine similarity 45 cặp description; từ khoá đặc trưng per skill
python3   # cross-skill reference (loại boilerplate 'Next steps') + artifact đọc/ghi
awk       # span Phase 2 trong vdesign
ls / grep # .claude-plugin, .github, CONTRIBUTING.md, CHANGELOG.md
```

**Một cái bẫy tôi đã suýt báo sai — ghi lại để khỏi lặp:** `git archive origin/main | tar -x` **strip exec bit** (GNU tar áp umask `0022` khi extract với non-root). Trên cây extract, cả **70** rule hiện `-rw-r--r--`, trông như "toàn bộ rule không chạy được". Đó là artifact của cách extract. Nguồn thật là `git ls-tree`, và nó nói **67× `100755` + 3× `100644`**. Worktree sandbox của tôi cũng bị strip y hệt, nên finding "3 rule không executable" ở lượt trước vẫn đúng — nhưng nó đúng **nhờ git index**, không nhờ `ls -l`.

**Chưa kiểm chứng được ở môi trường này:**

- **`npx skills add vyvu99/vskills --skill vcheck` có chạy thật không.** Tôi chỉ đối chiếu layout của repo (`skills/<name>/SKILL.md`) với layout mà Skills CLI tài liệu hoá. Chưa chạy CLI thật. **Nên thử đầu tiên ở tuần 2**, vì nếu CLI không nhận layout thì điểm #2 ở §B3 phải đổi cách làm.
- **`claude plugin validate`** — chưa viết `marketplace.json` nên chưa validate được.
- **Số star của các repo khác** — ba nguồn cho ba số khác nhau cho cùng một repo, nên tôi không dùng làm dữ liệu.
- **Hành vi runtime của skill** — mọi nhận xét về cách skill hành xử là suy ra từ việc đọc `SKILL.md` và journal, không phải từ một phiên Claude Code thật. Riêng **chi phí của Phase 4 Adversarial Verify** thì chính journal của bạn cũng ghi là "shipped blind... cost to be measured" — cả hai bên đều chưa có số.
- **Command template yarn/npm/bun** trong `repo-profile.md` §1 — chính file đó tự nhận là chưa verify trên monorepo thật.
