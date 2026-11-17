---
name: vguide
description: "Writes a user guide that leads a reader who knows nothing about the product from the big picture to each step: why the step exists, what it rests on, what comes before and after, a picture for every step, and who (which working role) does it. One guide per audience, with working roles split even when the product has fewer account roles. Written as short, flowing prose, never as fields or labelled lines. Verifies who can do what from the real code or product, tests the text with a cold reader, and checks it against forbidden content. Output is a Markdown guide, never a change report."
user-invocable: true
when_to_use: "Use when the user wants a usage guide, user manual, handbook or walkthrough for the people who will operate a product or feature, or a revised version of one (fewer documents, different roles, new language, clearer why). Not for release notes, changelogs, 'what was done or fixed' reports, specs (that is vspecs) or developer documentation."
argument-hint: "[product, feature or flow] [audiences and working roles to include] [existing guide to revise]"
metadata:
  author: vyvu
  version: "1.7.0"
---

# User Guide

Read the input:

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty, ask with `AskUserQuestion`: which product, feature or flow; which audiences and which working roles inside each; whether this revises an existing guide; where the file goes if the project has no docs convention.

**Scope:** this skill writes guide files and the images they embed. It never edits source code and never links the guide from code, comments or PR text.

**Output location:** where the user says; otherwise follow the project's docs or reports convention; otherwise `guides/<guide-slug>/`. Write in the language of the user.

## What the guide is

A guide a reader can follow **without help and without prior knowledge of the product**. A step is never just "click X". It says why the step exists, what it rests on (a rule, a law, a school or company decision, a business reason), what the reader has just done and what happens next. It reads like someone walking the reader through the work, in one continuous line from start to finish.

It is not:

- a reference table for people who already know the product (put a short lookup table inside the guide, never instead of the walk-through);
- a report of what was built, changed or fixed;
- a description of how the product looks or how it is built.

Test every paragraph with the cold reader in mind: "why am I doing this, why do I need this, what is this word, what happens after?" If the text does not answer, it is not finished.

## Step 1 - Fix the scope

1. **One guide per audience, not one file per topic.** A user with two audiences gets exactly two guides (for example one for teachers, one for experts). Quick sheets, emergency cards, glossaries, lookup tables, a training schedule and appendices go **inside** the guide they belong to, as sections or last pages. Never scatter the same audience's material over many files. Organizer-only material (decisions the client must take, internal notes) goes to one separate internal note, not into the guide.
2. **List the working roles, not only the account roles.** Verify from the real source (access rules in code, permission tables, menus, seed or demo accounts) which roles the product has. Then list the roles people actually play at the customer (for example class teacher and subject teacher; lead expert and supporting expert). When the product has fewer roles than the customer works with, split the guide by the working roles anyway and say plainly which part is a product fact and which part is a proposed working agreement (mark it so the customer confirms it). Never invent a product feature to fit a working role.
3. Keep only the audiences and roles the user asked for. A revised version that drops one removes its sections whole, renumbers, and removes every mention elsewhere.
4. Reuse an existing guide as a fact base when there is one, but verify its claims against the source; an old guide may be stale or wrong. Keep earlier versions untouched and write the new version beside it with a suffix.

## Step 2 - Gather the facts

1. For each working role, find what it can open, create, edit, only view, and what it never sees. Separate three kinds of work: **in the product**, **done directly by people outside the product** (a phone call, a signature, a meeting, standing beside someone), and **not done by this role**. Check each claim in code or the live product. A step that merely reads or records something in the product is in the product, even if a person does it by judgement.
2. Check every claim of absence ("the system does not count, remind, notify, track, let X see Y") by searching the source for it. State an absence only after the search. Product features that quietly cover a task (automatic reminders, hidden fields, a portal for outsiders) are the usual source of wrong absence claims.
3. Note the exact on-screen words for menus, buttons, tabs, options and messages. Write them in backticks exactly as shown.
4. Collect the limits a reader must know: who sees which data, what stays private, what expires or can be used once, deadlines and who sets them.
5. Collect the **basis** for every step: the rule, law, regulation or agreement that makes the step necessary. Quote it in plain words in the step; keep precise references (document, section, page) in one "Basis" table at the end.

## Step 3 - Pictures

Every step has a picture. A reader with no prior knowledge needs to see the screen, and a step without a picture is the most common complaint.

1. Use a local, demo or staging copy with test data. Take test credentials from the project's own seed or example files; never write a password into the guide, the chat, a note or a commit. When the demo data does not match the customer's real setting (school level, class names, company name), adapt the demo data reversibly (record original values, ship a revert) so the pictures match the customer's world.
2. Capture each role's screens while logged in as that role. One test dataset runs through every picture of a role: the same person, record, code and dates, so a name in one picture appears unchanged in the next and matches the running example in the text.
3. Each action step has its own picture in step order. Each picture has a red frame around exactly what the step asks the reader to use (one frame per target, nothing else framed), drawn on the page before capture, never added by hand afterwards. Next to each frame a number badge in the order of the actions and at most about six words naming the action, drawn on the page itself, high contrast, large enough at the printed width (about 11 px or more at 560 px; 280 px for phone), never covering what it points to or a neighbouring control, no personal data.
4. Pictures fit one printed page: desktop at most as tall as wide; phone at most about 2.2 times as tall as wide. Embed with an explicit width: `<img src="..." alt="..." width="560">` for desktop, `width="280"` for phone. Name files by role and step (`<role>-<nn>-<topic>.jpg`). Check every referenced file exists.
5. Create the data a step needs through the product before capture, so the frame sits on real content, not an empty state. No error screens, no half-loaded pages. Do not capture a state that contradicts the order of the story (for example a record already marked done in a step that comes before the one that finishes it).
6. **Overview diagrams.** Make three or four diagram images (static HTML rendered to PNG at 1440 px, readable at 560 px): the path of one case through the whole process with who does what and why; the urgent case in three steps; who sees and does what, per working role; the schedule when the guide includes a learning path. Draw them from verified facts, never from memory.
7. A step with no picture yet carries the hidden marker `<!--ANH-THIEU: what to capture-->` right after it; every marker is replaced before delivery. A step done only by people outside the product carries `<!--KHONG-ANH-->`.
8. A product with no screen (CLI, API) uses short command and output blocks instead of images.

## Step 4 - Write the guide

Structure of one guide:

1. **Title** and one opening sentence.
2. **Read in one minute:** what the product is and what it is for (three sentences), what the reader will do (three or four bullets), what is most urgent and where it is.
3. **Quick-find table** ("I want to ..." with working role, section and step), the most urgent task first.
4. **Big picture** (section 1): the overview diagram, the path told in plain words, why the reader's role stands where it stands, what each word the reader will meet means (one line each, explained at first use, with a short glossary at the end only for lookup), the **running example** (one fictional person or case used in every section and matching the pictures), and the table "who does which step" by working role.
5. **Working roles section:** one short block per working role: what the role is in the product and in practice, what it sees, what it does in the product, what it does directly, what it does not do, the first thing to do on taking the role. Say which parts are product facts and which are proposed agreements to confirm.
6. **The urgent case** right after the big picture, not buried in the middle.
7. **Stages** in the real order of the work. Each stage opens with one short paragraph in plain sentences: where the stage sits in the path (point at the diagram), why the organisation has it, and what the reader holds when it is done. No three-line template, no labelled lines.
8. **Each step** (`**Step N. Title is an action.**`) is one short paragraph of flowing prose, three to five sentences, written the way a colleague would explain it aloud. The paragraph carries the thread without labels: it starts from what the reader has just done and what is still missing, says why this step is needed and what rule or agreement it rests on, tells what to do and, when needed, what each button is for, and ends with what the product does next and who takes over. The working role that does the step is named inside the first sentence ("The class teacher opens ..."); where a step is split between roles, the sentence says so. The picture follows the paragraph. The text does not repeat clicks already numbered in the picture.
9. **Q&A "Why?"** near the end: eight to ten questions a newcomer will surely ask, each as a bold question followed by a two to four sentence answer in prose with its basis. No "Q:" or "A:" prefixes.
10. **Glossary**, **What the organisation still has to confirm** (one table, each open point once), **Basis** (table: claim, rule or document, section or page), and where the guide covers training, a short **Learning path** for the role (why short sessions, a schedule diagram, a table of sessions with what the learner can do afterwards).
11. Printable material the reader needs at hand (an emergency card) is the last page of the guide.

## Step 5 - Keep it easy to read

1. **Say it once** where it is first needed and point to it afterwards; but a fact the reader needs in an urgent moment is repeated where the moment happens.
2. **Group steps** under stage headings; keep step numbers continuous so references stay valid.
3. **One idea per step.** A paragraph longer than about five lines is split. Tables hold reference data (fields, options, statuses, limits, deadlines).
4. **Short and clear.** A step runs about fifty to ninety words. Understanding comes from a clear order of sentences, not from length: cut anything that does not help the reader act or understand, and move reference detail into a table.
5. **Put each diagram where it is used** and point to it again at the head of each stage.
6. **Length check:** aim for a guide a person can read in one sitting. When one guide exceeds about thirty printed pages, cut text first (repetition, long explanations), then offer to move lookup material to its end; do not create extra files without the user's answer.
7. **Prose, not forms.** Never write lines shaped like `Label: content` or italic lead-ins (Why:, Do:, Then:, Who does it:, Up to now:) to organise a step, a stage or a role block. Role blocks are short paragraphs too. Bold is for step titles and questions only. Tables are for lookup data, not for pieces of a story.
8. Explain each unfamiliar word the first time it appears, in one sentence beside it.
9. **Write it as a professional procedure manual, not a story.** No named characters, no invented example case, no scenes. Order: purpose and who it is for; the roles and what each may do; what must be ready before starting; one numbered procedure per task, in real order, each step an action in the product plus the result the reader should see and, where the product cannot do it, the human action stated plainly; then quick reference, rules, troubleshooting, glossary and basis. Urgent procedures come first and are marked. A short reason or legal basis sits in one sentence inside the step, never in a labelled field. Keep human work and clicks in separate sentences.
10. **Plain sentences.** A sentence carries one idea and stays near twenty words or fewer; a paragraph stays at four sentences or fewer; a paragraph introduces at most one new word, explained in the same sentence; definitions never go into nested brackets; open points the customer must confirm are not scattered through the story but gathered in one table at the end (the printed card is the only place that keeps blanks to fill).
11. **Short lists when the user asks for them.** When the user asks for short lists instead of prose, a step is its title followed by two to four bullets of one short sentence each (what is needed, why, what to choose or type, what happens next), with no labels and no colon-style fields.

## Step 6 - Tone and content rules

- Natural, respectful register in the reader's language. Address the reader with the natural term of address for that audience (for example "thầy cô" for teachers in Vietnamese), or the third person ("chuyên gia"), consistently within a guide. No chatty fillers, no "don't worry", no remarks about the reader's skill or knowledge.
- Plain words. Do not use internal names (enum values, function names, file paths, table names, ticket numbers) or the product's code names for features.
- Describe what the reader does and gets, not how the screen is built: no colours, shapes, component styles, layout, scrolling or collapsing behaviour, keyboard shortcuts, tooltips, unless a colour is the name of a status the reader must act on.
- No version history, no "now it works like...", no changelog language ("added", "fixed", "changed to", "previously").
- No section about errors and no error images. The guide states the working way only. A Q&A answer explaining why a rule exists is not an error section.
- Write in flowing prose. Sentences connect to each other ("After that ...", "Because ...", "When this is done ..."); a reader should never feel they are reading a filled-in form.
- Never present a working agreement as a product fact, and never present a product limit as a failing: say it as a fact with the workaround.
- Every open point the customer must decide is marked `[Confirm: ...]` (in the reader's language), kept to the minimum in the body and collected once in the "still to confirm" table.
- **Gentle wording on sensitive subjects.** When the guide deals with children, health or risk, use calm, respectful words: "suicidal thoughts", "self-harm", "needs urgent support", never blunt phrases such as "wants to die", "hurts himself" or "a red kid". Never turn a person into a label ("the urgent child", "a red student"); say "a student with an urgent flag" or "a student the system marks Red". Avoid words that name illnesses or diagnoses, and words that frighten ("life-threatening", "abandoned"). Keep official questions and quotations word for word and say they are quoted. Keep button and label names exactly as the product shows them.
- **Short but never curt.** Short is not the same as clipped. Every sentence has a clear subject and a full verb, and sentences join with a small connector ("When", "If", "After that", "This way"). Avoid bare fragments, stacks of commands with no link, one-word table cells and noun-only bullets. A step is two to four complete sentences: the action, the result or what to watch for, and the reason when needed. Fix curtness by completing the sentence and cutting repetition elsewhere, so the guide does not grow by more than a few percent. Bad: "Turn off the box, open the case at step 10." Better: "The specialist turns off the box and then opens the case at step 10."
- **The reader's point of view only.** Say what the reader sees on the screen, what they do and what result they see. Do not narrate what the product does or how it reacts inside ("the system sends", "counts", "flags", "automatically ...", who receives what and why, internal states or counters). Mention a product reaction only when the reader needs it to decide what to do, and then say it as the result they see ("a notification appears in the system"), not as a mechanism.
- **Words only insiders understand.** Replace interface or developer jargon with the plain thing the reader would say aloud. The bell is "a notification in the system", never "the bell"; the same goes for badge, toast, popup, dropdown, toggle, flag, trigger, session, token and any similar word. Keep button, tab and label names exactly as the screen shows them, in backticks, because the reader must match them. Before delivery, list every such word found in the guide and fix them all, not only the one that was pointed out.

## Step 7 - Verify, then hand over

1. **Facts.** Check each claim about who can do what, each absence claim, each button name and each condition against the source. Classify every "done directly" item again: nothing the product already does may sit in the "done directly" list.
2. **Forbidden content.** Search the text for removed roles, filler, layout and colour words, file paths, internal names, credentials, changelog words, and form-like lines (a line that starts with a short label and a colon, or an italic lead-in ending in a colon). Run the project's check script if it has one; otherwise write one (every image exists, every image has a width and is not taller than its limit, quick-find table present, forbidden words) so the check can be repeated.
3. **Pictures.** Every step has a picture or a marker; no marker is left at delivery unless the user accepted it; open a sample of at least six pictures and look: badges cover nothing, text matches the badge, no error state, no real personal data, the story order holds.
4. **Cold read.** Give the finished guide to a fresh reader (a subagent with no context) in the role of a person who knows nothing about the product, and have it list every place where the answer to "why", "what is this word", "what happens next" or "who does this" is missing, every jump between steps, every contradiction. Fix and read again until the list is empty or only contains items the user must decide.
5. **Roles.** Check that every working role has its own short block, every step names who does it inside its sentences, and each product fact is told apart from each proposed agreement.
6. **Documents.** Count the files delivered: one per audience (plus the internal note, if any). A guide that needs a second file to be understood is not finished.
7. Open the files for the user and give the paths. Report what was checked, what was not (for example pictures taken under a different role, claims read only from code), and which points still wait for the customer.

## Lessons from rewriting one guide five times

- Form beats content in the reader's eyes. Labelled fields read as mechanical, invented characters and scenes read as filler to professional staff, and long prose reads as hard. A numbered procedure manual with a short result line per step is what working staff accept; start there instead of finding it by elimination.
- Change the form without touching the facts: keep step numbers, button names, pictures and the basis table fixed, so every cross-reference ("see step 12") stays true after a rewrite.
- Put the urgent procedure straight after the roles table, marked, with the human actions first and the clicks after.
- Say each fact in one place. Repeats between the story, the tables and the Q&A were what pushed a guide from 6,000 to 8,000 words.
- Enforce the form with a script (labelled lines, step length, pictures present, forbidden words) and run it after every rewrite; a reader's impression is not a check.
- A cold read finds unclear sentences, not bad form; ask the user about form once, with one sample section, before rewriting a whole guide.
- When a distribution copy exists elsewhere (Drive, a shared folder), replace it after the final check and say which copy is current.
- Put the sensitive and the curt wording into the checking script too (a list of blunt words, and fragments such as bullets or cells with no verb), so tone is checked the same way as form.
- When a guide is judged hard to understand, the cause is often a word from the interface or the build team, or a sentence about what the system does inside; audit the whole guide for both kinds, fix them all, and add the words found to the checking script.

## Rules

- Never fabricate steps, buttons, commands or limits. If something cannot be confirmed from the product, leave it out and say so in the hand-over.
- Never reverse a decision the user already made about roles, order, wording or the number of documents.
- Keep earlier versions untouched when writing a new one; write the new version beside it.
- Never trash or overwrite files the user did not ask you to; when replacing uploaded copies elsewhere, ask first.
