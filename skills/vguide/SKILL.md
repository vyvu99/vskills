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

## Step 4 - Write the guide

1. **Title** and one formal opening sentence: what the guide covers and which roles it serves.
2. **General introduction**: purpose; a short glossary table of the terms the reader will meet; when the flow has stages, a table (stage, content, role that performs it) with a small flow diagram; one short illustrative case in the third person; how to access the product (account, sign-in, where the main navigation is, what text in backticks means).
3. **One section per role**: a short paragraph on the role (what it does and sees, what it does not), numbered steps, then a "points to remember" list.
4. **Each step** has a heading (`Step N`), a sentence saying what to do and why, the exact names to use, what the product does next, and the image directly below.
5. Safety or compliance information the reader must not miss (emergency contacts, irreversible actions, data handling) goes in the section of the role that meets it.

## Step 5 - Tone and content rules

- Formal, impersonal, administrative register. No second person, no chatty words, no commands such as "just", "don't worry", "remember to".
- Plain words. Explain each term once in the glossary. Do not use internal names (enum values, function names, file paths, table names, ticket numbers).
- Describe what the user does and gets, not how the screen is built: no colors, shapes, component styles, layout, scrolling or collapsing behavior, keyboard shortcuts, tooltips.
- No code or technical identifiers, no version history, no "now it works like...".
- No section about errors and no error images. The guide states the working way only.
- No changelog language: "added", "fixed", "changed to", "previously".
- Never say who the guide is for in terms of the reader's skill or knowledge.

## Step 6 - Verify, then hand over

1. Search the text for forbidden content: removed roles, casual words, second person, color/layout/component words, file paths, credentials.
2. Check every image path exists, and that each step has its image where one exists.
3. Check each claim about who can do what against the source of truth from Step 1.
4. Open the file for the user and give its path. Report what was checked and what was not (for example images captured under a different role).

## Rules

- Never fabricate steps, buttons, commands or limits. If something cannot be confirmed from the product, leave it out and say so in the hand-over.
- Never reverse a decision the user already made about roles, order or wording.
- Keep the earlier version untouched when writing a new one; write the new version beside it with a version suffix.
