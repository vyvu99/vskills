# Result format

How a skill prints its final result in the terminal. Replies are drawn by prismantis, so use markdown blocks that render; keep it short and skip any block with nothing to say.

1. **Verdict first**: one alert, `> [!TIP]` done, `> [!IMPORTANT]` partial or waiting on the user, `> [!WARNING]` blocked or risky. Bold the state word.
2. **Table when there are several items** (packages, spec cases, findings): one row each, status column with ✓ ✗ ○ centered (`:---:`), numbers right-aligned (`---:`). Short cells; long reasons go under the table.
3. **Right block for the data**: steps → task list; time or effort spread → `gantt`; shares → `pie`; counts per item → `xychart-beta` with named series; a branching decision → `mermaid` flowchart. No picture that only repeats the table.
4. **What was checked**: a `> [!NOTE]` with what was really run and seen, and what was not run and why. Reading code only is said as such.
5. **Decisions for the user**: a `> [!IMPORTANT]` box only when one is needed. Each item: the options as bullets, then a bold `Recommendation` line with one reason.
6. Commands the user may run go in a fenced block with a language tag, never inline code. File paths are written as plain `path/to/file.ts` so they stay clickable.
7. **Plain language**: write for a reader who does not know the context. Short sentences, result first, one idea each; name a thing in everyday words before any technical name; put file paths and function names in code after the plain description, never as the subject of a sentence.

Then follow the Next Steps convention in `repo-profile.md` §7.
