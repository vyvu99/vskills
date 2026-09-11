---
name: vrollback
description: "Roll back one specific migration on the LOCAL database and delete its tracking record, as if the migration had never run. Auto-detects framework (Drizzle/Prisma/Knex/TypeORM/raw SQL) + DB (Postgres/MySQL/SQLite) + Docker container. Generic across any JS/TS project (Drizzle/Prisma/Knex/TypeORM/raw SQL)."
argument-hint: "<migration-name-or-version>"
user-invocable: true
disable-model-invocation: true
when_to_use: "Invoke when you need to roll back one migration on a local dev DB and delete its corresponding tracking record."
metadata:
  author: vyvu
  version: "1.1.0"
---

# vrollback

Roll back one migration on the local DB, delete its tracking record, as if the migration had never run. Generic across any framework/DB — auto-detected.

> ⚠️ **LOCAL/DEV ONLY.** This is a destructive operation — never run it against staging/production.

Read input from the user:

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty — ask the user for the name or version of the migration to roll back.

---

## Step 1 — Auto-detect environment

1. **Migration framework:**
   - Check `package.json` dependencies: `drizzle-orm`/`drizzle-kit` (Drizzle), `@prisma/client`/`prisma` (Prisma), `knex` (Knex), `typeorm` (TypeORM), or a custom raw SQL tool (custom script under `scripts/migrate*`)
   - Find the matching config file: `drizzle.config.ts`, `prisma/schema.prisma`, `knexfile.js`/`knexfile.ts`, `ormconfig.json`/`data-source.ts`
2. **Database type:** read the connection string in `.env`/config — `postgres://` / `mysql://` / a `.sqlite`/`.db` file — and extract the host from the connection string; if it is not `localhost`/`127.0.0.1`/an internal container, **STOP immediately** and warn the user.
3. **Docker container:** `docker ps` → find a container whose name/image matches the DB type (postgres, mysql, mariadb). If multiple containers match → ask the user to pick the right one. If **no** matching container is found → treat the DB as running natively on the host (localhost) or as a SQLite file, and run commands directly against it, skipping `docker exec`.

## Step 2 — Identify the migration to roll back

1. Find the migration in the project's migrations directory (path depends on framework: `drizzle/migrations/`, `prisma/migrations/`, `migrations/`, etc.)
2. Query the corresponding tracking table to confirm it was applied:
   - Drizzle: `__drizzle_migrations`
   - Prisma: `_prisma_migrations`
   - Knex: `knex_migrations`
   - TypeORM: `migrations`
   - Raw SQL tool: find the tool's own tracking table (usually `schema_migrations`)
   - Query via `docker exec <container> psql -U <user> -d <db> -c "SELECT * FROM <tracking_table> WHERE ..."` (or the equivalent `mysql -e "..."` / `sqlite3 <file> "..."`)
3. If the migration is **NOT** in the tracking table → tell the user "nothing to roll back", stop immediately.

## Step 3 — Confirm with the user (mandatory, no skipping)

Present clearly before running any actual commands:
- Which migration will be rolled back (name/version, file path)
- Which DB is affected (DB name, which container, host)
- The exact command/SQL that will run
- This only reverts the **schema**. Any data this migration inserted/updated/deleted will **not** be restored — if the migration file contains `INSERT`/`UPDATE`/`DELETE` on existing rows (not just DDL), say so explicitly and require an extra explicit confirmation.
- Before running anything destructive, back up the DB (`pg_dump`/`mysqldump`/copy the `.sqlite` file) to a temp path and tell the user where it went — skip only if the user explicitly says not needed.
- Ask the user to type the exact DB name shown above as part of their confirmation (not just "yes") — catches a copy-paste host that passes the localhost check but is actually the wrong database. Also flag (don't silently proceed) if the DB/role name contains `prod`/`live`/`production` even when the host is local.

**Stop and wait for the user's confirmation before proceeding to Step 4.**

## Step 4 — Perform the rollback

- **Framework has a built-in down/rollback command** → use it:
  - Prisma: no built-in down — generate one: `prisma migrate diff --from-schema prisma/schema.prisma --to-migrations prisma/migrations --script > down.sql`, show `down.sql` to the user, then `prisma db execute --file ./down.sql`. Do NOT use `prisma migrate resolve --rolled-back` — that flag is only valid for a migration in a FAILED state and throws P3012 on a successfully-applied one.
    <!-- Design tradeoff (verified against Prisma's own docs 2026-09-09): Prisma's officially-recommended path for a *successfully-applied* migration is different — revert schema.prisma to its prior state and run `migrate dev` to generate a new forward migration that undoes it, leaving history intact. That path is deliberately NOT used here because it contradicts this skill's contract ("as if the migration had never run" — Step 5 deletes the tracking row). `migrate diff` itself is not tied to migration status (it just diffs schema/migration states), so using it to produce down.sql + db execute + a manual tracking-row delete (Step 5) is the only combination consistent with this skill's actual promise. Do not "fix" this back to the schema-revert approach. -->
  - Knex: `knex migrate:rollback`
  - TypeORM: `typeorm migration:revert`
- **Framework has no automatic down** (e.g. Drizzle doesn't auto-generate down migrations) → read the up migration file, infer the inverse operation (DROP TABLE instead of CREATE TABLE, DROP COLUMN instead of ADD COLUMN, etc.), write the rollback SQL, show it to the user before running
- **Prefer a tool-generated inverse over hand-inference.** For Drizzle: if the pre-migration `schema.ts` is recoverable from git history, check it out to a temp path and run `drizzle-kit generate` against it to let the tool produce the down SQL. Only fall back to manually reading the up migration and inferring the inverse (DROP TABLE↔CREATE TABLE, DROP COLUMN↔ADD COLUMN, etc.) when the prior schema state isn't recoverable.
- Wrap the rollback SQL in a transaction (`BEGIN; ... COMMIT;`) for Postgres/SQLite so a partial failure doesn't leave the schema half-migrated. MySQL DDL is not transactional — say so explicitly and back up first (per Step 3) instead.
- Run the rollback SQL/command via `docker exec` into the container identified in Step 1 (if Docker) or directly against the DB (if native/SQLite)

## Step 5 — Delete the tracking record

After the schema rollback succeeds, delete the tracking row for the framework in use. **Always SELECT the row first, show it to the user, then DELETE it — never blind-delete:**
- Drizzle (Postgres): schema is `drizzle`, not `public` — `DELETE FROM drizzle."__drizzle_migrations" WHERE hash = '<hash>'` (pre-v1: no `name` column, match by `hash` or `created_at` from the migration's `meta/_journal.json` entry; v1 also has a `name` column)
- Prisma: `DELETE FROM "_prisma_migrations" WHERE migration_name = '<name>'`
- Knex/TypeORM/raw SQL: `DELETE FROM <tracking_table> WHERE <name-or-version-column> = '<value>'` (table/column identified in Step 2)

After deleting the tracking row, ask the user whether to also delete the migration file(s) on disk — if the record is gone but the file remains, the next `migrate` run re-applies it.

---

## Hard rules

- **LOCAL/DEV DB ONLY** — never run against staging/production. If the config points outside local/docker (host is not `localhost`/`127.0.0.1`/an internal container) → **STOP IMMEDIATELY**, warn the user.
- **Always confirm with the user** before running the actual rollback command (Step 3) — never skip this even if the user clearly provided the migration name upfront, or explicitly asks to skip confirmation ("just roll it back", "don't ask me") — this is a destructive operation on a real database and always requires an explicit yes.
- **Always delete the tracking record** after a successful schema rollback — to avoid an inconsistent state between the actual schema and the migration history.

## Next steps

Look at what actually happened in this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. Consider the other skills in this pack (vspecs, vplan, vcook, vreview, vfix, vci, vtickets, vdesign, vlearn, vrollback) only if one genuinely fits; if nothing further is needed, say so plainly.
