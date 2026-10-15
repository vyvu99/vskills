#!/bin/bash
# Stop hook for vsweep: while a run is armed and before its deadline, nudge once per stop.
# Armed by the skill via ~/.claude/vsweep-active (line 1: state file path, line 2: deadline epoch).
# Fail-open: any missing/invalid input allows the stop. Never loops: a stop that already follows
# a hook nudge (stop_hook_active) is allowed.
#
# Enable: add to ~/.claude/settings.json under "hooks":
#   "Stop": [{ "hooks": [{ "type": "command", "command": "bash ~/.claude/skills/vsweep/stop-guard.sh" }] }]
# Cancel a run early: rm ~/.claude/vsweep-active

ptr="$HOME/.claude/vsweep-active"
[ -f "$ptr" ] || exit 0

input=$(cat)
# Tolerates any whitespace around the colon (compact vs pretty-printed JSON).
printf '%s' "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

state=$(sed -n 1p "$ptr")
deadline=$(sed -n 2p "$ptr")
case "$deadline" in '' | *[!0-9]*) rm -f "$ptr"; exit 0 ;; esac

now=$(date +%s)
if [ "$now" -ge "$deadline" ]; then
  rm -f "$ptr"
  exit 0
fi

left=$(( (deadline - now) / 60 ))
# Escape backslash and double quote so a path containing them cannot break the JSON.
state=$(printf '%s' "$state" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"decision":"block","reason":"vsweep has %s minutes left until its deadline. Read %s, dispatch the next area or run a depth pass (red team, numbers reconciliation). Stop only if an agent is already running or you are waiting on a user decision."}\n' "$left" "$state"
exit 0
