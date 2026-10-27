---
name: vrollback
description: "Rolls back one specific migration on the local development database and deletes its tracking row, so the database looks as if the migration never ran. Detects the framework (Drizzle, Prisma, Knex, TypeORM, raw SQL), the database (Postgres, MySQL, SQLite) and the Docker container, and refuses any non-local target. Run it explicitly as /vrollback <migration>."
argument-hint: "<migration-name-or-version>"
user-invocable: true
disable-model-invocation: true
when_to_use: "Use when the user wants to undo one migration on a local dev database and clear its migration-history record. Never for staging or production."
metadata:
  author: vyvu
  version: "2.0.0"
---

# vrollback

Reverts one migration's schema on the local database and removes its tracking row. Destructive, so it runs only on a local or dev database, only after the user confirms (Step 3), and only for the one migration asked for. Do not touch other migrations or application data.

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty, ask for the migration name or version.

## Step 1 — Detect the environment

1. Framework: check `package.json` for `drizzle-orm`/`drizzle-kit`, `@prisma/client`/`prisma`, `knex`, `typeorm`, or a custom script under `scripts/migrate*`. Find its config: `drizzle.config.ts`, `prisma/schema.prisma` and `prisma.config.ts`, `knexfile.*`, `ormconfig.json`/`data-source.ts`.
2. Target database: read the connection string from `.env` or the config and extract the host. The host must be `localhost`, `127.0.0.1` or a local container. Anything else, or a connection string you cannot read: stop and warn the user. This refusal is absolute because a rollback on a shared database is not recoverable by this skill.
3. Docker: `docker ps` for a container matching the database type. Several matches: ask which. None: the database runs natively or is a SQLite file, so run commands directly without `docker exec`.

## Step 2 — Find the migration and confirm it was applied

1. Locate the migration file in the project's migrations directory.
2. Query the tracking table through `docker exec <container> psql -U <user> -d <db> -c "..."` (or `mysql -e`, `sqlite3 <file>`): Drizzle `drizzle.__drizzle_migrations` (the `drizzle` schema, not `public`), Prisma `_prisma_migrations`, Knex `knex_migrations`, TypeORM `migrations`, raw SQL tools usually `schema_migrations`.
3. Not in the tracking table: tell the user there is nothing to roll back and stop.

## Step 3 — Confirm with the user (always, even if they ask to skip it)

This is a destructive operation on a real database, so a clear migration name or a "just do it" does not replace the confirmation. Show:
- The migration (name or version, file path) and the target (database name, container, host).
- The exact command or SQL that will run.
- That only the schema is reverted. If the migration file has `INSERT`/`UPDATE`/`DELETE` on existing rows, say the data is not restored and require a second confirmation.
- A backup taken first (`pg_dump`, `mysqldump`, or a copy of the `.sqlite` file) to a temp path, with that path shown, unless the user says it is not needed.

Ask the user to type the exact database name. This catches a host that passes the local check but is the wrong database. If the database or role name contains `prod`, `live` or `production`, flag it and do not proceed silently. Wait for the answer before Step 4.

## Step 4 — Roll back the schema

Tool-specific flags change between versions, so check the installed version's docs when a command fails.
- Prisma has no down command. Generate one with `prisma migrate diff --from-schema prisma/schema.prisma --to-migrations prisma/migrations --script > down.sql`, show `down.sql`, then `prisma db execute --file ./down.sql`. Do not use `prisma migrate resolve --rolled-back`: it only applies to failed migrations and errors with P3012 on an applied one. Prisma's own recommended path (revert the schema and generate a forward migration) keeps history, which contradicts "as if it never ran", so it is not used here.
- Knex: `knex migrate:down <name>`, not `migrate:rollback`, which reverts the whole last batch.
- TypeORM: `typeorm migration:revert` reverts only the last executed migration. If the target is not the last, use the manual SQL path.
- Drizzle and raw SQL have no automatic down. Prefer a tool-generated inverse: if the previous `schema.ts` is in git history, check it out to a temp path and run `drizzle-kit generate` against it. Otherwise read the up file, write the inverse SQL (`DROP TABLE` for `CREATE TABLE`, and so on) and show it before running.
- On Postgres and SQLite wrap the SQL in `BEGIN; ... COMMIT;` so a failure leaves no half-reverted schema. MySQL DDL is not transactional, so say that and rely on the backup.
- Run it through `docker exec` into the Step 1 container, or directly for a native database or SQLite.

## Step 5 — Delete the tracking row

After the schema rollback succeeds, SELECT the row, show it to the user, then DELETE it. Never delete blind. Without this the history and the schema disagree and the next `migrate` re-applies the migration.
- Drizzle (Postgres): `DELETE FROM drizzle."__drizzle_migrations" WHERE hash = '<hash>'`. Before v1 there is no `name` column, so match `hash` or `created_at` from the `meta/_journal.json` entry.
- Prisma: `DELETE FROM "_prisma_migrations" WHERE migration_name = '<name>'`.
- Knex removes its own row on `migrate:down`, so a SELECT that finds nothing means skip the DELETE. TypeORM and raw SQL: `DELETE FROM <tracking_table> WHERE <column> = '<value>'`.

Then ask whether to delete the migration file on disk too; if it stays, the next `migrate` run re-applies it.

## Step 6 — Verify

Run the framework's status command (or a schema query) and a `SELECT` on the tracking table. Report that the schema change is gone and the row is absent, with the output. If a check cannot run, say which.

Follow the Next Steps convention in `_vskills-shared/repo-profile.md` §7.
