# Result format

How a skill prints its final result in the terminal. Replies are drawn by prismantis, so use markdown blocks that render. The reader does not know the context and wants the whole session at a glance: keep it short and skip any block with nothing to say.

**Pick the size by the work.** A one- or two-sentence answer needs no frame. Work that edited files, ran commands or took several steps gets blocks 1-3 and 5. Audits, blocked runs and anything the user must decide get all of them.

1. **Session strip** (only when the session has two or more tasks, or one is still open): a task list that adds up over the session, one line of up to ten words per task. Done tasks stay so the whole session shows; a task waiting on the user ends with "— waiting on you". Past eight lines, fold older ones into "N tasks done earlier". Never invent a task to fill it.
2. **Verdict**: one alert, `> [!TIP]` done, `> [!IMPORTANT]` partial or waiting on the user, `> [!WARNING]` blocked or risky. Bold the state word. For short work, say in the same sentence what was run and seen, and what was not run.
3. **What you need to do**: one line right under the verdict: the user's next action, or "You need to do nothing." Never leave the user's part at the bottom.
4. **Body, only when there are several items** (packages, spec cases, findings): one table, one row each, status column with ✓ ✗ ○ centered (`:---:`), numbers right-aligned (`---:`). Short cells; long reasons go under the table. Other data: steps → task list; time or effort spread → `gantt`; shares → `pie`; counts per item → `xychart-beta` with named series; a branching decision → `mermaid` flowchart. No picture that only repeats the table.
5. **What was checked**: a separate `> [!NOTE]` only when the result is long or something unrun is worth worrying about: what was really run and seen, what was not run and why. Reading code only is said as such. Do not repeat what the verdict already said.
6. **Decisions for the user**: a `> [!IMPORTANT]` box only when one is needed. Each item: the options as bullets with their consequences, then a bold `Recommendation` line with one reason and "say `go` to take it". Silence is not consent: stop and wait.
7. Commands the user may run go in a fenced block with a language tag, never inline code. File paths are written as plain `path/to/file.ts` so they stay clickable.
8. **Plain language**: short sentences, result first, one idea each; name a thing in everyday words before any technical name; put file paths and function names in code after the plain description, never as the subject of a sentence.

When the user asks for a session summary or hands the work over, print a `kanban` with three columns (done, open, dropped), one line and a short reason per card, then two or three plain sentences on what matters most.

Then follow the Next Steps convention in `repo-profile.md` §7.
