---
name: vrollback
description: "Rollback một migration cụ thể trên database LOCAL và xóa tracking record của nó, như thể migration đó chưa từng chạy. Tự động detect framework (Drizzle/Prisma/Knex/TypeORM/raw SQL) + DB (Postgres/MySQL/SQLite) + Docker container. Generic cho mọi project JS/TS (Drizzle/Prisma/Knex/TypeORM/raw SQL)."
argument-hint: "<migration-name-or-version>"
user-invocable: true
disable-model-invocation: true
when_to_use: "Dùng khi cần rollback một migration trên local dev DB và xóa tracking record tương ứng của nó."
metadata:
  author: vyvu
  version: "1.1.0"
---

# vrollback

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
- Thao tác này chỉ revert **schema**. Data mà migration đã insert/update/delete sẽ **không** được khôi phục — nếu file migration có `INSERT`/`UPDATE`/`DELETE` trên row hiện có (không chỉ DDL), phải nói rõ điều này và yêu cầu user xác nhận thêm một lần nữa.
- Trước khi chạy bất kỳ thao tác destructive nào, backup DB (`pg_dump`/`mysqldump`/copy file `.sqlite`) vào một temp path và báo cho user biết đường dẫn — chỉ bỏ qua khi user chủ động nói không cần.
- Yêu cầu user gõ đúng tên DB đã hiển thị ở trên như một phần của xác nhận (không chỉ "yes") — để bắt trường hợp copy-paste nhầm host, host vẫn pass check localhost nhưng thực ra là sai database. Đồng thời cảnh báo (không được tự ý tiếp tục) nếu tên DB/role chứa `prod`/`live`/`production` dù host là local.

**Dừng lại và chờ user xác nhận trước khi tiếp tục sang Bước 4.**

## Bước 4 — Thực hiện rollback

- **Framework có sẵn built-in down/rollback command** → dùng nó:
  - Prisma: không có down tự động sẵn — phải tự generate: `prisma migrate diff --from-schema prisma/schema.prisma --to-migrations prisma/migrations --script > down.sql`, hiển thị `down.sql` cho user, sau đó `prisma db execute --file ./down.sql`. KHÔNG dùng `prisma migrate resolve --rolled-back` — flag này chỉ hợp lệ cho migration đang ở trạng thái FAILED, dùng trên migration đã apply thành công sẽ throw lỗi P3012.
    <!-- Design tradeoff (đã verify với docs chính thức của Prisma ngày 2026-09-09): Đường dẫn Prisma khuyến nghị chính thức cho một migration đã apply thành công lại khác — revert `schema.prisma` về trạng thái trước đó rồi chạy `migrate dev` để sinh ra một migration forward mới undo lại thay đổi đó, giữ nguyên history. Cách đó CỐ Ý không được dùng ở đây vì nó mâu thuẫn với hợp đồng của skill này ("như thể migration chưa từng chạy" — Bước 5 xóa tracking row). Bản thân `migrate diff` không phụ thuộc vào trạng thái migration (nó chỉ diff schema/migration state), nên dùng nó để sinh down.sql + db execute + xóa thủ công tracking row (Bước 5) là combination duy nhất khớp với đúng lời hứa của skill này. KHÔNG "fix" lại về cách revert schema.prisma. -->
  - Knex: `knex migrate:rollback`
  - TypeORM: `typeorm migration:revert`
- **Framework không có down tự động** (ví dụ Drizzle không tự sinh down migration) → đọc file up migration, suy ra thao tác nghịch đảo (DROP TABLE thay vì CREATE TABLE, DROP COLUMN thay vì ADD COLUMN, v.v.), viết rollback SQL, hiển thị cho user trước khi chạy
- **Ưu tiên dùng inverse do tool tự sinh hơn là suy luận thủ công.** Với Drizzle: nếu `schema.ts` trước migration còn recover được từ git history, checkout nó ra một temp path rồi chạy `drizzle-kit generate` với schema đó để tool tự sinh down SQL. Chỉ fallback sang đọc thủ công up migration và suy ra inverse (DROP TABLE↔CREATE TABLE, DROP COLUMN↔ADD COLUMN, v.v.) khi không recover được schema state trước đó.
- Bọc rollback SQL trong transaction (`BEGIN; ... COMMIT;`) với Postgres/SQLite để tránh trường hợp fail giữa chừng làm schema bị half-migrated. DDL của MySQL không transactional — phải nói rõ điều này và backup trước (theo Bước 3) thay vì dùng transaction.
- Chạy rollback SQL/command qua `docker exec` vào container đã xác định ở Bước 1 (nếu dùng Docker) hoặc chạy trực tiếp vào DB (nếu native/SQLite)

## Bước 5 — Xóa tracking record

Sau khi rollback schema thành công, xóa tracking row tương ứng với framework đang dùng. **Luôn SELECT row đó trước, hiển thị cho user, rồi mới DELETE — không bao giờ blind-delete:**
- Drizzle (Postgres): schema là `drizzle`, không phải `public` — `DELETE FROM drizzle."__drizzle_migrations" WHERE hash = '<hash>'` (pre-v1: không có cột `name`, match theo `hash` hoặc `created_at` lấy từ entry tương ứng trong `meta/_journal.json` của migration; v1 có thêm cột `name`)
- Prisma: `DELETE FROM "_prisma_migrations" WHERE migration_name = '<name>'`
- Knex/TypeORM/raw SQL: `DELETE FROM <tracking_table> WHERE <name-or-version-column> = '<value>'` (table/column đã xác định ở Bước 2)

Sau khi xóa tracking row, hỏi user có muốn xóa luôn file migration trên disk không — nếu record đã mất mà file vẫn còn, lần `migrate` tiếp theo sẽ apply lại migration đó.

---

## Hard rules

- **CHỈ DÙNG CHO LOCAL/DEV DB** — KHÔNG BAO GIỜ chạy trên staging/production. Nếu config trỏ ra ngoài local/docker (host không phải `localhost`/`127.0.0.1`/một internal container) → **DỪNG NGAY LẬP TỨC**, cảnh báo user.
- **LUÔN xác nhận với user** trước khi chạy rollback command thật (Bước 3) — KHÔNG BAO GIỜ bỏ qua bước này kể cả khi user đã cung cấp rõ tên migration ngay từ đầu, hoặc user chủ động yêu cầu bỏ qua xác nhận ("cứ rollback đi", "khỏi hỏi") — đây là thao tác destructive trên database thật, luôn cần user xác nhận rõ ràng ("yes").
- **LUÔN xóa tracking record** sau khi rollback schema thành công — để tránh trạng thái không đồng nhất giữa schema thực tế và migration history.

## Bước tiếp theo

Nhìn vào kết quả thực tế của lần chạy này và tự đề xuất MỘT hành động tiếp theo hợp lý, 1-2 câu — không chọn theo danh sách cố định. Cân nhắc các skill khác trong bộ này (vspecs, vplan, vcook, vreview, vfix, vci, vtickets, vdesign, vlearn, vrollback) nếu thực sự phù hợp; nếu không cần gì thêm thì nói rõ luôn.
