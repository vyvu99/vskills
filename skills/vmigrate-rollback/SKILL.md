---
name: vmigrate-rollback
description: "Roll back one specific migration on the LOCAL database and delete its tracking record, as if the migration had never run. Auto-detects framework (Drizzle/Prisma/Knex/TypeORM/raw SQL) + DB (Postgres/MySQL/SQLite) + Docker container. Generic across any JS/TS project (Drizzle/Prisma/Knex/TypeORM/raw SQL)."
argument-hint: "<migration-name-or-version>"
user-invocable: true
when_to_use: "Invoke when you need to roll back one migration on a local dev DB and delete its corresponding tracking record."
category: database
keywords: [migration, rollback, database, local, docker]
metadata:
  author: vyvu
  version: "1.1.0"
---

# vmigrate-rollback

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

**Stop and wait for the user's confirmation before proceeding to Step 4.**

## Step 4 — Perform the rollback

- **Framework has a built-in down/rollback command** → use it:
  - Prisma: `prisma migrate resolve` + `prisma migrate diff` (Prisma has no true automatic down — evaluate case by case)
  - Knex: `knex migrate:rollback`
  - TypeORM: `typeorm migration:revert`
- **Framework has no automatic down** (e.g. Drizzle doesn't auto-generate down migrations) → read the up migration file, infer the inverse operation (DROP TABLE instead of CREATE TABLE, DROP COLUMN instead of ADD COLUMN, etc.), write the rollback SQL, show it to the user before running
- Run the rollback SQL/command via `docker exec` into the container identified in Step 1 (if Docker) or directly against the DB (if native/SQLite)

## Step 5 — Delete the tracking record

After the schema rollback succeeds → `DELETE FROM <tracking_table> WHERE ...` via `docker exec` (if Docker) or directly against the DB (if native/SQLite) to remove the corresponding row, so the next `migrate` run treats this migration as if it never ran.

---

## Hard rules

- **LOCAL/DEV DB ONLY** — never run against staging/production. If the config points outside local/docker (host is not `localhost`/`127.0.0.1`/an internal container) → **STOP IMMEDIATELY**, warn the user.
- **Always confirm with the user** before running the actual rollback command (Step 3) — never skip this even if the user clearly provided the migration name upfront, or explicitly asks to skip confirmation ("just roll it back", "don't ask me") — this is a destructive operation on a real database and always requires an explicit yes.
- **Always delete the tracking record** after a successful schema rollback — to avoid an inconsistent state between the actual schema and the migration history.

## Next steps

Look at what actually happened in this run and suggest ONE sensible next action in 1-2 sentences — don't pick from a fixed list. Consider the other skills in this pack (vspecs, vplan, vcook, vreview, vfix, vcheck, vissues, vdesign, vrules, vmigrate-rollback) only if one genuinely fits; if nothing further is needed, say so plainly.
