---
name: vrollback
description: "Rollback đúng một migration trên database local/dev và xóa dòng tracking của nó, để database trông như migration chưa từng chạy. Tự nhận diện framework (Drizzle, Prisma, Knex, TypeORM, raw SQL), database (Postgres, MySQL, SQLite) và Docker container, và từ chối mọi target không phải local. Chạy tường minh bằng /vrollback <migration>."
argument-hint: "<migration-name-or-version>"
user-invocable: true
disable-model-invocation: true
when_to_use: "Dùng khi user muốn hoàn tác một migration trên database dev local và xóa bản ghi lịch sử migration của nó. Không bao giờ dùng cho staging hay production."
metadata:
  author: vyvu
  version: "2.0.0"
---

# vrollback

Hoàn tác schema của một migration trên database local và xóa dòng tracking của nó. Skill này phá hủy dữ liệu nên chỉ chạy trên database local/dev, chỉ sau khi user xác nhận (Bước 3), và chỉ cho đúng migration được yêu cầu. Không đụng migration khác hay dữ liệu ứng dụng.

```
$ARGUMENTS
```

Nếu `$ARGUMENTS` rỗng, hỏi tên hoặc version của migration.

## Bước 1 — Nhận diện môi trường

1. Framework: xem `package.json` có `drizzle-orm`/`drizzle-kit`, `@prisma/client`/`prisma`, `knex`, `typeorm`, hoặc script tự viết dưới `scripts/migrate*`. Tìm config: `drizzle.config.ts`, `prisma/schema.prisma` và `prisma.config.ts`, `knexfile.*`, `ormconfig.json`/`data-source.ts`.
2. Database đích: đọc connection string từ `.env` hoặc config và lấy host. Host phải là `localhost`, `127.0.0.1` hoặc container local. Khác đi, hoặc không đọc được connection string: dừng và cảnh báo user. Lấy host từ giá trị lệnh migration thật sự dùng (biến `.env` đang nạp hoặc địa chỉ container đang publish), không lấy từ dòng ví dụ hay dòng đã comment. Lệnh từ chối này là tuyệt đối vì rollback trên database dùng chung thì skill này không khôi phục được.
3. Docker: `docker ps` tìm container khớp loại database. Nhiều kết quả: hỏi chọn cái nào. Không có: database chạy native hoặc là file SQLite, chạy lệnh trực tiếp, không dùng `docker exec`.

## Bước 2 — Tìm migration và xác nhận đã được apply

1. Tìm file migration trong thư mục migrations của project.
2. Query bảng tracking qua `docker exec <container> psql -U <user> -d <db> -c "..."` (hoặc `mysql -e`, `sqlite3 <file>`): Drizzle `drizzle.__drizzle_migrations` (schema `drizzle`, không phải `public`), Prisma `_prisma_migrations`, Knex `knex_migrations`, TypeORM `migrations`, tool raw SQL thường là `schema_migrations`.
3. Không có trong bảng tracking: báo user là không có gì để rollback rồi dừng. Đã có migration mới hơn được apply (có thể phụ thuộc migration này): liệt kê chúng và hỏi trước khi tiếp tục.

## Bước 3 — Xác nhận với user (luôn luôn, kể cả khi họ bảo bỏ qua)

Đây là thao tác phá hủy trên database thật, nên tên migration rõ ràng hay câu "cứ làm đi" không thay được bước xác nhận. Hiển thị:
- Migration (tên hoặc version, đường dẫn file) và đích (tên database, container, host).
- Lệnh hoặc SQL chính xác sẽ chạy.
- Chỉ schema được hoàn tác. Nếu file migration có `INSERT`/`UPDATE`/`DELETE` trên dòng đã có, nói rõ dữ liệu không được khôi phục và yêu cầu xác nhận lần hai.
- Một bản backup làm trước (`pg_dump`, `mysqldump`, hoặc copy file `.sqlite`) vào đường dẫn tạm, hiển thị đường dẫn đó, trừ khi user nói không cần.

Yêu cầu user gõ đúng tên database. Việc này bắt được trường hợp host qua được check local nhưng sai database. Nếu tên database hoặc role chứa `prod`, `live` hay `production`, cảnh báo và không im lặng đi tiếp. Chờ câu trả lời rồi mới sang Bước 4.

## Bước 4 — Rollback schema

Cờ lệnh của từng tool đổi theo version, nên khi lệnh fail hãy xem tài liệu của version đang cài.
- Prisma không có lệnh down. Sinh bằng `prisma migrate diff --from-schema prisma/schema.prisma --to-migrations prisma/migrations --script > down.sql`, cho user xem `down.sql`, rồi `prisma db execute --file ./down.sql`. Không dùng `prisma migrate resolve --rolled-back`: nó chỉ áp dụng cho migration fail và báo lỗi P3012 với migration đã apply. Cách Prisma khuyến nghị (revert schema rồi sinh migration tiến) giữ lại lịch sử, mâu thuẫn với "như chưa từng chạy", nên không dùng ở đây.
- Knex: `knex migrate:down <name>`, không phải `migrate:rollback` vì lệnh đó revert cả batch cuối.
- TypeORM: `typeorm migration:revert` chỉ revert migration chạy gần nhất. Nếu target không phải cái cuối, dùng đường SQL thủ công.
- Drizzle và raw SQL không có down tự động. Ưu tiên inverse do tool sinh: nếu `schema.ts` trước đó có trong lịch sử git, checkout ra đường dẫn tạm và chạy `drizzle-kit generate` trên đó. Nếu không, đọc file up, viết SQL ngược (`DROP TABLE` cho `CREATE TABLE`, v.v.) và cho xem trước khi chạy.
- Trên Postgres và SQLite bọc SQL trong `BEGIN; ... COMMIT;` để lỗi không để lại schema revert dở. DDL của MySQL không có transaction, nên nói rõ điều đó và dựa vào backup.
- Chạy qua `docker exec` vào container ở Bước 1, hoặc trực tiếp với database native hay SQLite.

## Bước 5 — Xóa dòng tracking

Sau khi rollback schema thành công, SELECT dòng đó, cho user xem, rồi mới DELETE. Không bao giờ xóa mù. Không làm bước này thì lịch sử và schema lệch nhau, và lần `migrate` sau sẽ apply lại migration.
- Drizzle (Postgres): `DELETE FROM drizzle."__drizzle_migrations" WHERE hash = '<hash>'`. Trước v1 không có cột `name`, nên khớp theo `hash` hoặc `created_at` từ entry trong `meta/_journal.json`.
- Prisma: `DELETE FROM "_prisma_migrations" WHERE migration_name = '<name>'`.
- Knex tự xóa dòng của nó khi `migrate:down`, nên SELECT không thấy gì thì bỏ qua DELETE. TypeORM và raw SQL: `DELETE FROM <tracking_table> WHERE <column> = '<value>'`.

Sau đó hỏi có xóa luôn file migration trên đĩa không; nếu file còn, lần `migrate` sau sẽ apply lại nó.

## Bước 6 — Xác minh

Chạy lệnh status của framework (hoặc query schema) và một `SELECT` trên bảng tracking. Báo rằng thay đổi schema đã mất và dòng tracking không còn, kèm output. Check nào không chạy được thì nói rõ là check nào.

Làm theo quy ước Next Steps trong `_vskills-shared/repo-profile.md` §7.
