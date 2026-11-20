# Webapp interactive step — shared convention
Use when a skill (`vreview --fix`, `vspecs`, ...) needs to ask the user through a visual UI
(color/font/motion, or bulk diff review) instead of text-only `AskUserQuestion`.
The server and frontend live in `~/.claude/vskills-web/` (linked from the repo's `web/` by `install.sh`; see the `README.md` there for manual runs and debugging).

## (a) The 3 field types + sample JSON

A template is sent with `POST /api/step`:

```json
{
  "title": "Aesthetic Customization — Round 1",
  "fields": [ /* array of fields, see the 3 types below */ ]
}
```

When `/api/step` resolves, Claude receives one object `{ [field.id]: value }` — one key per field, all 3 types mixed.

**`/api/step` validates the template immediately, before anything is shown on the web** (empty title/fields,
a field missing `id`/`label`/`type`, unknown `type`, duplicate `id`, `select` without
`options` or an option without `label`/`value`, `renderHint` outside the enum, `renderHint:
"swatch"` with a `value` that is not a real CSS color, `diff-review-list` without `items`
or an item missing a required field). On failure it returns `400` at once (no page opened, nothing
set pending): `{ "error": "invalid template", "details": ["fields[0].label must be a
non-empty string", ...] }`. Read `details`, fix the JSON yourself and call `/api/step` again
— never let the user open a tab and find a broken or empty page before learning the JSON was wrong.

### `select`

| Key | Type | Required | Notes |
|---|---|---|---|
| `id` | string | ✅ | Key in the result object |
| `type` | `"select"` | ✅ | |
| `label` | string | ✅ | Field title |
| `description` | string | — | Rendered **directly above** the option list (not a hidden tooltip) — use it when the options need context before the user can decide |
| `options` | array | ✅ | See the option table below |

**Option** (each element of `options`):

| Key | Type | Required | Notes |
|---|---|---|---|
| `label` | string | ✅ | Displayed text |
| `value` | string | ✅ | Value returned when chosen — MUST be a real hex color if `renderHint: "swatch"`, a real CSS `font-family` if `renderHint: "font-sample"`. Don't send a bare label and leave `renderHint` with nothing to render |
| `renderHint` | `"plain"` \| `"swatch"` \| `"font-sample"` | — | Default `"plain"` (ordinary radio/list). `"swatch"` = show a color chip using `value` as the CSS color. `"font-sample"` = render the label in the font given by `value` |

The returned value is the `option.value` of the chosen option.

```json
{
  "id": "typography",
  "type": "select",
  "label": "Typography",
  "description": "Pick one font pair to represent this criterion.",
  "options": [
    { "label": "IBM Plex Sans / Source Sans 3", "value": "IBM Plex Sans, sans-serif", "renderHint": "font-sample" },
    { "label": "Playfair Display / Fraunces", "value": "Playfair Display, serif", "renderHint": "font-sample" }
  ]
}
```

### `text`

| Key | Type | Required | Notes |
|---|---|---|---|
| `id` | string | ✅ | Key in the result object |
| `type` | `"text"` | ✅ | |
| `label` | string | ✅ | |
| `description` | string | — | Same display rule as `select` |
| `placeholder` | string | — | |

Free input (textarea), for "Other", proposals and open decisions. The returned value
is the entered string (empty if left blank).

```json
{ "id": "catchall", "type": "text", "label": "Anything else you want to adjust?", "placeholder": "Optional" }
```

### `diff-review-list`

| Key | Type | Required | Notes |
|---|---|---|---|
| `id` | string | ✅ | Key in the result object |
| `type` | `"diff-review-list"` | ✅ | |
| `label` | string | ✅ | |
| `items` | array | ✅ | See the item table below |

**Item** (each element of `items`):

| Key | Type | Required | Notes |
|---|---|---|---|
| `id` | string | ✅ | Stable ID within this run (e.g. `SUGGESTION-1`) — used to map decisions back; never rely on index order |
| `before` | string | ✅ | Rendered as its own block that scrolls on its own (a long item doesn't push the others off screen) |
| `after` | string | ✅ | Same rendering rule as `before` |
| `actions` | string[] | ✅ | Usually `["apply", "skip"]` |
| `allowFreeText` | boolean | — | Default `false`. `true` adds an optional input box, used as extra instructions instead of a bare apply/skip |
| `default` | string | — | Action preselected when the page opens — `"apply"` if omitted |

The returned value is an array of `{ id, action, freeText? }` in **exactly the same order** as the original `items`.

```json
{
  "id": "suggestions",
  "type": "diff-review-list",
  "label": "Review suggestions",
  "items": [
    {
      "id": "SUGGESTION-1",
      "before": "problem description + current code",
      "after": "proposed fix",
      "actions": ["apply", "skip"],
      "allowFreeText": true,
      "default": "apply"
    }
  ]
}
```

## (b) One fixed port + health check + background start + open the browser

`vskills-web/` is a plain Node script (`node:http`, 0 dependencies, no `npm install`) —
one process, one port, serving both the frontend and the API.

- Webapp: `http://localhost:4270` (override with env `VSKILLS_WEBAPP_PORT`)

**Before using it, Claude always health-checks first, then starts it if needed:**

```bash
curl -s localhost:4270/api/health
# expected: {"service":"vskills-webapp","ok":true}
```

- Exactly `service: "vskills-webapp"` → the server is already running, use it,
  do NOT start it again.
- No response, a connection error, or a different/missing `service` (the port is taken by
  another service) → start it in the background:

```bash
node ~/.claude/vskills-web/server.mjs &     # Bash run_in_background: true
```

- Wait for the health check to pass, then open the tab: `open http://localhost:4270` (macOS).
- **Write the JSON template to a temp file first** (with the Write tool, not `echo`/heredoc)
  — templates often contain code diffs or free text with backticks, quotes and `$`, and
  pasting them into `-d '<json>'` breaks shell escaping or corrupts the content. Then make the
  interactive call with a single Bash command using `run_in_background: true`, reading the body from the file:

```bash
curl -s -w '\n%{http_code}' -X POST localhost:4270/api/step -H 'content-type: application/json' -d @/path/to/step-template.json
```

  This command **hangs by design** until the user submits on the page — the harness notifies
  Claude when the background command finishes (no polling or sleep loops). The last line of
  stdout is the HTTP status code (thanks to `-w`), the rest is the JSON body — always
  check the status before using the body:
  - `400` → the template is invalid (see section (a)); returned IMMEDIATELY, not after the
    user submits — read `details`, fix the JSON, call again; do NOT ask or open a tab for the user
  - `504` → timed out with no answer — treat it as the user not choosing webapp mode,
    and fall back as described below
  - `200` → the body is the result object `{ [field.id]: value }` — parse that JSON
    to get the user's decisions
- If the user closes the tab without submitting, the command returns a timeout error after
  30 minutes by default (change it with `VSKILLS_WEBAPP_STEP_TIMEOUT_MS`) — the skill should tell the user
  the maximum wait before making the call.
- A timeout or error while waiting → treat it as the user not choosing webapp mode for that step:
  say so briefly, then ask again with `AskUserQuestion` (the old way) instead of retrying
  the webapp or stopping the skill.

## (c) Sample `AskUserQuestion` for choosing the mode

Ask exactly once before the step that needs the webapp (don't ask again each round if
the step loops several times within one skill run):

```
question: "This step has several choices that need to be SEEN (color/font) or reviewed in bulk. Use the interactive webapp, or keep asking through chat as before?"
header: "Interaction mode"
options:
  - label: "Use the interactive webapp (Recommended)"
    description: "Opens a page with real color swatches and fonts, or a bulk diff review — answer once, much faster than many chat rounds"
  - label: "Keep asking through chat (AskUserQuestion)"
    description: "Don't open the webapp; keep asking step by step in chat as now"
```
