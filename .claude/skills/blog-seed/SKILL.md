---
name: blog-seed
description: Use when the user wants to capture a "blog seed" or blog idea — raw material for a future blog post — from the current work session, either starting a new seed or adding material to an existing one, invoked with a hook or angle (optionally naming an existing seed file to append to). Homelab posts get written elsewhere (Obsidian / blog repo); this only collects feedstock into blog/seeds/.
---

# Blog Seed

## Overview

Capture raw material ("a seed") for a blog post from the current work session,
built around a hook the user gives. The finished post is written elsewhere
(Obsidian / the blog repo); this only produces feedstock in `blog/seeds/`.

**Core principle: the USER picks what goes in.** Two selection rounds, never
one-shot. Your job is to surface candidates and assemble the chosen ones — not to
decide the content yourself.

## When to Use

- User invokes with a hook/angle, e.g. `/blog-seed how Ansible and OpenTofu handle idempotency`.
- Work or discussion has happened that's worth turning into a post.

Not for: writing the finished post (done elsewhere), or internal decision records
(those go in `docs/`).

## Procedure

The user's argument is the hook. It may also name an **existing seed to add to** —
via an `@`-mention or a path (e.g. `/blog-seed @blog/seeds/foo.md more on X`). Build
the seed around the hook. **Interactive: you STOP and wait for the user's selection
at two gates. Never write the file in one pass.**

### 1. Resolve the target

- **Named existing seed** — the args include a seed path (`@…` or a path/filename)
  → that exact file is the target. Read it now; you'll append to it.
- **No path given** — derive a slug from the hook and check `blog/seeds/`. If an
  existing seed plausibly covers the same topic, ask *"Append to `<existing>`
  instead of a new seed?"* before continuing. Otherwise it's a new file.

Slug matching is exact — a differently-worded hook won't match an existing seed by
slug. Don't fork a duplicate by accident: when adding to prior work, prefer an
`@`-path; when unsure, `ls blog/seeds/` and check.

### 2. Harvest from context

Pull points relevant to the hook from this conversation's **established outputs** —
decisions reached, conclusions, facts stated. NOT the exploratory middle-reasoning.
If the conversation is thin on the hook, say so plainly and lean on step 3.

**Appending? Dedup first.** Read the target seed and don't present points it already
contains as new. If a point overlaps, list it separately, flagged already-captured,
so the user can choose to skip it.

Present as a numbered list, each one line, tagged `[insight]` or `[challenge]`.

**STOP.** Ask: "Which go in the seed? (e.g. `1,3,4`)" Wait for the pick before continuing.

### 3. Augment

After the user picks, add **new** suggestions from two sources:

- **Research** — a light, targeted lookup on the hook (find-docs / ctx7, or web)
  for authoritative points the conversation didn't cover. Actually look it up —
  don't punt with "fetch docs later." Keep it tight; not a deep-research run.
- **Overlooked** — angles already present in the conversation the user didn't flag.

Present as a second numbered list, tagged `[research]` or `[overlooked]`.

**STOP.** Ask which to add. Wait for the pick.

### 4. Write

Assemble **only** the user's picks into the target from step 1 — the named append
target, or a new `blog/seeds/<slug>.md` (slug = kebab from hook, repo conventions
e.g. OpenTofu not Terraform; user can override). Use `blog/_template.md`:

- `## Insights` / `## Challenges` — harvest + augment picks, bucketed.
- `## Related` — docs, commit SHAs, files, and research links from the augment round.
- New seed also needs `# <title>` (from the hook, tightened — confirm if unsure) and
  `## Hook / angle` (the hook, lightly framed).

**Appending: read-modify-write.** Add picks under the matching existing sections;
preserve everything already in the file. Never clobber.

Show the path. Done — the seed carries enough for the user to go write the real post
elsewhere.

## Output Shape

A seed is bullet points and pointers, **not prose paragraphs**. Material to mine,
not a draft. Do not polish it into a mini-post.

## Common Mistakes

- **One-shotting the file** — skips both selection gates. The user chooses; you
  don't auto-include everything you found. Both STOPs are mandatory.
- **Forking a duplicate seed** — when the user means "add to that seed," resolve the
  target first (step 1). A differently-worded hook won't slug-match an existing file;
  prefer an `@`-path, or `ls blog/seeds/` and confirm.
- **Re-suggesting captured points** — on append, dedup against the target's current
  contents; don't offer points it already holds as if new.
- **Clobbering on append** — read-modify-write, preserve existing content.
- **Mining reasoning instead of outputs** — pull conclusions and decisions, not the
  exploratory back-and-forth.
- **Skipping the research** — the augment round must actually look something up,
  especially when context is thin. "Fetch docs later" is a punt.
- **Writing a finished post** — it's a seed. Bullets and links, not paragraphs.
