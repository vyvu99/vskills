# vskills webapp

Local interactive webapp shared by `vdesign`/`vfix`/`vspecs` for steps that need
a visual UI (colors, fonts, batch diff review) instead of chat-only
`AskUserQuestion`. See `skills/_vskills-shared/webapp-templates.md` for the
JSON contract and how a skill drives this from Claude.

Zero dependencies, zero build step — plain `node:http` + vanilla JS. Nothing
to install; just run it.

## Run manually (debugging)

```bash
node web/server.mjs   # serves both the API and the frontend on :4270
```

Open `http://localhost:4270`.

Port is fixed by default (`4270`); override with `VSKILLS_WEBAPP_PORT` if it's
taken on your machine.

## Tests

```bash
node --test web/server.test.mjs
```
