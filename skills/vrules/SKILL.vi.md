---
name: vrules
description: "Phân tích các comment review của Claude bot trên một PR, đối chiếu với các rule hiện có trong ~/.claude/CLAUDE.md, và đề xuất rule mới để lấp khoảng trống — giúp CLAUDE.md tự cải thiện dựa trên pattern review thực tế."
argument-hint: "<số-PR>"
user-invocable: true
when_to_use: "Dùng sau khi Claude bot đã review xong một PR, khi muốn chắt lọc các pattern lặp lại thành rule mới cho CLAUDE.md."
category: meta
keywords: [claude-md, rules, pr-review, self-improvement]
metadata:
  author: vyvu
  version: "1.0.0"
---

# vrules

Chắt lọc rule mới cho `~/.claude/CLAUDE.md` từ các pattern lặp lại trong comment review của Claude bot trên một PR — một vòng lặp tự cải thiện cho file rule global.

Đọc input từ user:

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` rỗng — hỏi user muốn phân tích PR số mấy.

---

## Bước 1 — Trích xuất rule hiện có

Đọc TOÀN BỘ `~/.claude/CLAUDE.md`. Trích xuất từng rule/bullet thành danh sách đánh số (giữ nguyên section gốc, ví dụ `[Backend-12]`, `[TypeScript-3]`) — dùng để đối chiếu ở Bước 3. KHÔNG tóm tắt hay diễn giải lại nội dung rule.

## Bước 2 — Lấy comment review của Claude bot

Xác định host + `<owner>/<repo>` theo `~/.claude/skills/_vskills-shared/repo-profile.md` §2 (parse chuẩn dùng chung; nếu file không tồn tại, tự suy ra `<owner>/<repo>` trực tiếp từ `git remote get-url origin` — đúng hành vi mặc định hiện tại); hỏi user nếu vẫn không rõ.

```bash
gh pr view <số-PR> --json comments,reviews
gh api repos/<owner>/<repo>/pulls/<số-PR>/comments
gh api repos/<owner>/<repo>/pulls/<số-PR>/reviews
```

Không phải GitHub hoặc thiếu `gh` → in thông báo §2 dành cho vrules (`⚠️ không lấy được comment review vì thiếu gh — paste nội dung vào, tôi sẽ tiếp tục từ Bước 3`) rồi tiếp tục Bước 3 với comment user paste vào. Bước 1 (đọc `~/.claude/CLAUDE.md`) và Bước 3-5 không cần host access gì cả, nên skill vẫn hữu ích ~80% dù thiếu `gh`.

Lọc theo author là bot review tự động (thường có hậu tố `[bot]` hoặc tên app tuỳ chỉnh). Nếu không chắc chắn tên account bot chính xác → hỏi user trước khi lọc, KHÔNG đoán.

## Bước 3 — Cluster pattern

Nhóm comment theo loại vấn đề lặp lại (ví dụ: thiếu null check, N+1 query, sót console.log, thiếu loading state) — KHÔNG liệt kê từng comment riêng lẻ.

Với mỗi pattern, đếm số lần xuất hiện trong PR này.

Đối chiếu từng pattern với danh sách rule ở Bước 1:
- **Đã được rule hiện có cover rõ ràng** → bỏ qua, ghi chú "already covered by [số-section]" để user biết rule đó đang hoạt động đúng như thiết kế
- **Chưa được cover, hoặc rule hiện có quá hẹp** → đây là gap, chuyển sang Bước 4

## Bước 4 — Đề xuất rule mới

Với mỗi gap:
- Viết rule CÀNG GENERIC CÀNG TỐT — không mô tả theo case cụ thể của PR này (ví dụ KHÔNG viết "đừng quên null check trong getUserById" mà viết "mọi function nhận input từ DB/external API → PHẢI check null/undefined trước khi truy cập field")
- Nêu rõ rule nên thuộc section nào trong CLAUDE.md hiện có (Backend, Frontend, TypeScript, Styling, Form Fields, ...) — không tạo section mới nếu rule fit vào section đã có
- Kèm số lần xuất hiện trong PR này (để user đánh giá pattern có xứng đáng thành rule chung hay không — xem Hard Rules)

Trình bày toàn bộ đề xuất cho user, **hỏi xác nhận từng rule một trước khi patch** — KHÔNG BAO GIỜ tự động sửa CLAUDE.md khi chưa được approve.

## Bước 5 — Patch (chỉ sau khi user approve)

Patch CLAUDE.md theo đúng rule Document Updates đã định nghĩa sẵn trong chính file đó:
- Patch inline vào section liên quan
- KHÔNG thêm section "Fixed" / "Changelog" / "Update" mới ở cuối file
- Không giữ version history, không ghi ngày tháng trong nội dung rule

---

## Hard Rules

- **LUÔN hỏi xác nhận** trước khi patch CLAUDE.md — KHÔNG BAO GIỜ tự sửa dù user đã approve định hướng chung; mỗi rule PHẢI được approve riêng
- Rule đề xuất **BẮT BUỘC phải generic**, không gắn với case cụ thể của PR đang phân tích
- Chỉ pattern lặp lại **≥2 lần** trong PR mới đủ điều kiện đề xuất thành rule chung — 1 lần xuất hiện là edge case, không tự đề xuất thành rule; nếu chỉ có 1 lần, nêu rõ số lần và để user tự quyết định có thêm hay không
- KHÔNG BAO GIỜ đoán tên account bot khi không chắc — hỏi user
- Không dump raw comment vào output — chỉ trình bày pattern đã cluster
- Thiếu `gh` là degrade, không phải dừng — các bước cluster/đề xuất (3-5) chạy trên comment user paste vào

## Bước tiếp theo

Nhìn vào kết quả thực tế của lần chạy này và tự đề xuất MỘT hành động tiếp theo hợp lý, 1-2 câu — không chọn theo danh sách cố định. Cân nhắc các skill khác trong bộ này (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) nếu thực sự phù hợp; nếu không cần gì thêm thì nói rõ luôn.
