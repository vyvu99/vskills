---
name: vguide
description: "Writes a formal user guide for any product, feature or flow (web, mobile, desktop, CLI, internal tool): organized by user role, numbered steps, each step explained, screenshots where the product has a screen. Verifies who can do what from the real code or product, then checks the text against a list of forbidden content. Output is a plain Markdown guide, never a change report."
user-invocable: true
when_to_use: "Use when the user wants a usage guide, user manual or walkthrough for the people who will operate a product or feature, or a revised version of one (fewer roles, different scope, new language). Not for release notes, changelogs, 'what was done or fixed' reports, specs (that is vspecs) or developer documentation."
argument-hint: "[product, feature or flow] [roles or audiences to include] [existing guide to revise]"
metadata:
  author: vyvu
  version: "1.1.0"
---

# User Guide

Read the input:

```
$ARGUMENTS
```

If `$ARGUMENTS` is empty, ask with `AskUserQuestion`: which product, feature or flow; which roles to cover; whether this revises an existing guide; where the file goes if the project has no docs convention.

**Scope:** this skill writes one Markdown guide and the images it embeds. It never edits source code and never links the guide from code, comments or PR text.

**Output location:** where the user says; otherwise follow the project's existing docs or reports convention; otherwise `guides/<guide-slug>/guide.md` with images in `guides/<guide-slug>/images/`. Write in the language of the user.

## What the guide is

A **usage guide a reader can follow without help**, suitable to hand to management, a customer or a regulator. It says what each kind of user can do, in which order, and what happens next. It is not:

- a report of what was built, changed or fixed;
- a description of how the product looks or how it is built;
- a message about the reader or the writer ("this document is written for beginners").

If the user says "this is not a report of what was done", remove every sentence about the work itself, not just the headings.

## Step 1 - Fix the scope

1. List the user roles (or audiences) the product has. Verify against the source of truth, not against an old guide: access rules in code, permission tables, menus, seed or demo accounts, or the running product when there is no code.
2. Keep only the roles the user asked for. A revised version that drops roles removes those sections whole, renumbers the rest, and removes every mention of them elsewhere (tables, notes, "who sees what" lines).
3. Reuse an existing guide as the base when there is one. Keep its steps and explanations; change only what the user asked to change.

## Step 2 - Gather the facts

1. For each role, find what it can open, create, edit or only view, and what it cannot see. State only what the product allows.
2. Note the exact on-screen or on-command words for menus, buttons, tabs, options, commands and messages. Write them in backticks exactly as shown.
3. Collect the limits a reader must know: who sees which data, what stays private, what expires or can be used once.

## Step 3 - Capture images (when the product has a screen)

1. Use a local, demo or staging copy with test data. Take test credentials from the project's own seed or example files; never write a password into the guide, the chat, a note or a commit.
2. Capture each role's screens while logged in as that role. A capture from another role shows a different menu; note that when it cannot be avoided.
3. When updating an existing guide, capture again only the screens that changed.
4. Name files by role and step (`<role>-<nn>-<topic>.jpg`). Check every referenced file exists.
5. No error screens, no error messages, no half-loaded pages. Wait until the page has finished loading.
6. A product with no screen (CLI, API) uses short command and output blocks instead of images.
7. **Images must fit one page when printed.** Capture the visible screen or a cropped region, never a whole scrolling page. A desktop capture is at most as tall as it is wide; a phone capture is at most about 2.2 times as tall as wide. When a screen is longer, crop around what the step uses, or split it into two images. Embed each image with an explicit width so one image fits one page: `<img src="..." alt="..." width="560">` for desktop and square captures, `width="280"` for phone captures. Never let an image be split across two pages.
8. **Images tell the same story as the text.** One test dataset runs through every image of a role (the same user, record, code and dates), so a code or name in one image appears unchanged in the next and matches the text of the step. Every step that has an action has its own image showing that action, in step order. Each image has a red frame around exactly what the step asks the reader to use or click (one frame per target, nothing else framed), and the frame is drawn on the page itself before capture, never added by hand afterwards. Before capture, create the data the step needs through the product, so the frame sits on real content, not an empty state.
9. **Say the step inside the image.** Next to each red frame the page itself carries a short callout drawn before capture: a number badge in the order of the actions (1, 2, 3 when one image has several targets) and at most about six words naming the action ("Chọn Đăng ký", "Nhập lý do"). Same language as the guide, high contrast, large enough to read at the printed width (about 11 px or more once the image is shown at 560 px, 280 px for phone), never covering the content it points to, no personal data. The callout repeats the step's action, it does not add new information, so the guide still reads correctly without the images.

## Step 4 - Write the guide

1. **Title** and one formal opening sentence: what the guide covers and which roles it serves.
2. **General introduction**: purpose; a short glossary table of the terms the reader will meet; when the flow has stages, a table (stage, content, role that performs it) with a small flow diagram; one short illustrative case in the third person; how to access the product (account, sign-in, where the main navigation is, what text in backticks means).
3. **One section per role**: a short paragraph on the role (what it does and sees, what it does not), numbered steps, then a "points to remember" list.
4. **Each step** has a heading (`Step N`), a sentence saying what to do and why, the exact names to use, what the product does next, and the image directly below.
5. Safety or compliance information the reader must not miss (emergency contacts, irreversible actions, data handling) goes in the section of the role that meets it.

## Step 5 - Keep it easy to read

A long guide is read by looking things up, not top to bottom. Apply these before writing, then check them in Step 7.

1. **Quick-find table** right after the title: rows "I want to ..." with the role, section and step that answers it, then a contents list. Every reader reaches their task in one look.
2. **Group the steps** of each role under short task headings (for example "Sending a request", "Following up") instead of one flat list of 15 or more steps. Keep step numbers continuous so references stay valid.
3. **One idea per step.** A step is a short purpose line, numbered actions, then the image. A paragraph longer than about five lines is split into actions or moved into a table.
4. **Tables for reference data**: lists of fields, options, statuses, limits and deadlines go in a table (name, meaning, note), not in a sentence with many commas.
5. **Say it once.** Facts repeated in several steps or roles (emergency numbers, limits, who cannot do what) are stated in one place and pointed to from the others. A step that two roles share is written once and referenced by the other role in one line, with only the role-specific difference spelled out.
6. **Put each diagram where it is used**: a role's flow diagram opens that role's section, not a block of all diagrams before the introduction.
7. **Short "points to remember"**: only facts a reader could miss, at most about seven lines per role, none already stated in a step.
8. **Length check**: if one role's section exceeds roughly 300 lines or 15 steps after these rules, offer the user a split into one file per role plus a shared index, and do not split without their answer.
9. **Get to the point.** A step title is an action; the first line says what to do. Leave out what the screen looks like and any label, status or option the reader does not have to choose between or act on. List only the options that need a decision. A rare case becomes one line under "points to remember" or is dropped.
10. **Word budget.** A step has at most about 60 words outside tables and lists. If the introduction, glossary or illustrative case grow past a screen each, cut them to the terms and facts the steps actually use.
11. **The image carries the clicks, the text carries the rest.** When an image has numbered callouts, the step text does not repeat the clicks. It keeps only what the image cannot show: the purpose in one line, conditions and limits (required, maximum, who can), and what happens next. A step that was a numbered list of clicks becomes one sentence that points to the numbers ("Làm theo các số 1 đến 3 trong ảnh") plus those extras. Every instruction the reader needs to act must still be in the callouts, so the callout labels are written first and the step text is trimmed to match. Target at most about 35 words per step outside tables; drop option lists that the image already shows unless the reader must choose among them by name.

## Step 6 - Tone and content rules

- Formal, impersonal, administrative register. No second person, no chatty words, no commands such as "just", "don't worry", "remember to".
- Plain words. Explain each term once in the glossary. Do not use internal names (enum values, function names, file paths, table names, ticket numbers).
- Describe what the user does and gets, not how the screen is built: no colors, shapes, component styles, layout, scrolling or collapsing behavior, keyboard shortcuts, tooltips.
- No code or technical identifiers, no version history, no "now it works like...".
- No section about errors and no error images. The guide states the working way only.
- No changelog language: "added", "fixed", "changed to", "previously".
- Never say who the guide is for in terms of the reader's skill or knowledge.

## Step 7 - Verify, then hand over

1. Search the text for forbidden content: removed roles, casual words, second person, color/layout/component words, file paths, credentials.
2. Check every image path exists, and that each step has its image where one exists.
3. Check Step 5: the quick-find table exists, steps are grouped, no paragraph over about five lines, no fact repeated in two places, each diagram sits in its role section. Check image sizes: no image taller than the ratios in Step 3, every image embedded with a width. Check every image carries a numbered callout for each frame. Check no step exceeds the word budget. Check step text does not repeat what the numbered callouts already say.
4. Check each claim about who can do what against the source of truth from Step 1.
5. Open the file for the user and give its path. Report what was checked and what was not (for example images captured under a different role).

## Rules

- Never fabricate steps, buttons, commands or limits. If something cannot be confirmed from the product, leave it out and say so in the hand-over.
- Never reverse a decision the user already made about roles, order or wording.
- Keep the earlier version untouched when writing a new one; write the new version beside it with a version suffix.
