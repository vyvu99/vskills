---
name: vmigrate-rollback
description: "Rollback một migration cụ thể trên database LOCAL và xóa tracking record của nó, như thể migration đó chưa từng chạy. Tự động detect framework (Drizzle/Prisma/Knex/TypeORM/raw SQL) + DB (Postgres/MySQL/SQLite) + Docker container. Generic cho mọi project JS/TS (Drizzle/Prisma/Knex/TypeORM/raw SQL)."
argument-hint: "<migration-name-or-version>"
user-invocable: true
when_to_use: "Dùng khi cần rollback một migration trên local dev DB và xóa tracking record tương ứng của nó."
category: database
keywords: [migration, rollback, database, local, docker]
metadata:
  author: vyvu
  version: "1.1.0"
---

# vmigrate-rollback

Rollback một migration trên local DB, xóa tracking record của nó, như thể migration đó chưa từng chạy. Generic cho mọi framework/DB — tự động detect.

> ⚠️ **CHỈ DÙNG CHO LOCAL/DEV.** Đây là thao tác destructive — KHÔNG BAO GIỜ chạy trên staging/production.

Đọc input từ user:

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` rỗng — hỏi user tên hoặc version của migration cần rollback.

---

## Bước 1 — Tự động detect environment

1. **Migration framework:**
   - Kiểm tra dependencies trong `package.json`: `drizzle-orm`/`drizzle-kit` (Drizzle), `@prisma/client`/`prisma` (Prisma), `knex` (Knex), `typeorm` (TypeORM), hoặc custom raw SQL tool (custom script dưới `scripts/migrate*`)
   - Tìm config file tương ứng: `drizzle.config.ts`, `prisma/schema.prisma`, `knexfile.js`/`knexfile.ts`, `ormconfig.json`/`data-source.ts`
2. **Loại database:** đọc connection string trong `.env`/config — `postgres://` / `mysql://` / file `.sqlite`/`.db` — và trích xuất host từ connection string; nếu host không phải `localhost`/`127.0.0.1`/một internal container → **DỪNG NGAY LẬP TỨC** và cảnh báo user.
3. **Docker container:** `docker ps` → tìm container có tên/image khớp với loại DB (postgres, mysql, mariadb). Nếu có nhiều container khớp → hỏi user chọn container đúng. Nếu **không** có container nào khớp → coi DB như đang chạy native trên host (localhost) hoặc là file SQLite, chạy command trực tiếp, bỏ qua `docker exec`.

## Bước 2 — Xác định migration cần rollback

1. Tìm migration trong thư mục migrations của project (đường dẫn tùy framework: `drizzle/migrations/`, `prisma/migrations/`, `migrations/`, v.v.)
2. Query tracking table tương ứng để xác nhận migration đã được apply:
   - Drizzle: `__drizzle_migrations`
   - Prisma: `_prisma_migrations`
   - Knex: `knex_migrations`
   - TypeORM: `migrations`
   - Raw SQL tool: tìm tracking table riêng của tool đó (thường là `schema_migrations`)
   - Query qua `docker exec <container> psql -U <user> -d <db> -c "SELECT * FROM <tracking_table> WHERE ..."` (hoặc tương đương `mysql -e "..."` / `sqlite3 <file> "..."`)
3. Nếu migration **KHÔNG** có trong tracking table → báo user "không có gì để rollback", dừng ngay lập tức.

## Bước 3 — Xác nhận với user (bắt buộc, không được bỏ qua)

Trình bày rõ ràng trước khi chạy bất kỳ command thật nào:
- Migration nào sẽ được rollback (tên/version, đường dẫn file)
- DB nào bị ảnh hưởng (tên DB, container nào, host)
- Command/SQL chính xác sẽ được chạy

**Dừng lại và chờ user xác nhận trước khi tiếp tục sang Bước 4.**

## Bước 4 — Thực hiện rollback

- **Framework có sẵn built-in down/rollback command** → dùng nó:
  - Prisma: `prisma migrate resolve` + `prisma migrate diff` (Prisma không có down tự động thực sự — đánh giá theo từng trường hợp)
  - Knex: `knex migrate:rollback`
  - TypeORM: `typeorm migration:revert`
- **Framework không có down tự động** (ví dụ Drizzle không tự sinh down migration) → đọc file up migration, suy ra thao tác nghịch đảo (DROP TABLE thay vì CREATE TABLE, DROP COLUMN thay vì ADD COLUMN, v.v.), viết rollback SQL, hiển thị cho user trước khi chạy
- Chạy rollback SQL/command qua `docker exec` vào container đã xác định ở Bước 1 (nếu dùng Docker) hoặc chạy trực tiếp vào DB (nếu native/SQLite)

## Bước 5 — Xóa tracking record

Sau khi rollback schema thành công → `DELETE FROM <tracking_table> WHERE ...` qua `docker exec` (nếu dùng Docker) hoặc chạy trực tiếp vào DB (nếu native/SQLite) để xóa row tương ứng, để lần `migrate` tiếp theo coi migration này như chưa từng chạy.

---

## Hard rules

- **CHỈ DÙNG CHO LOCAL/DEV DB** — KHÔNG BAO GIỜ chạy trên staging/production. Nếu config trỏ ra ngoài local/docker (host không phải `localhost`/`127.0.0.1`/một internal container) → **DỪNG NGAY LẬP TỨC**, cảnh báo user.
- **LUÔN xác nhận với user** trước khi chạy rollback command thật (Bước 3) — KHÔNG BAO GIỜ bỏ qua bước này kể cả khi user đã cung cấp rõ tên migration ngay từ đầu, hoặc user chủ động yêu cầu bỏ qua xác nhận ("cứ rollback đi", "khỏi hỏi") — đây là thao tác destructive trên database thật, luôn cần user xác nhận rõ ràng ("yes").
- **LUÔN xóa tracking record** sau khi rollback schema thành công — để tránh trạng thái không đồng nhất giữa schema thực tế và migration history.

## Bước tiếp theo

Nhìn vào kết quả thực tế của lần chạy này và tự đề xuất MỘT hành động tiếp theo hợp lý, 1-2 câu — không chọn theo danh sách cố định. Cân nhắc các skill khác trong bộ này (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) nếu thực sự phù hợp; nếu không cần gì thêm thì nói rõ luôn.
