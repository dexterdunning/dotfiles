---
name: html-slides
argument-hint: "[topic or content to turn into slides]"
description: Build HTML slide decks with Reveal.js and visual-first explanations. Use when asked for HTML slides, a presentation deck, a tech talk, an architecture presentation, an incident review, or a proposal to present. For a standalone interactive reference rather than a presentation, use the explainer skill instead.
---

# HTML slides

Turn the supplied content into a single HTML presentation that opens in a browser without a build step. Keep the workflow simple: **outline → meaningful visuals → HTML → browser check**.

**Optional local supplement:** if `~/.agents/skill-overrides/html-slides/instructions.md` exists, read it first — it may add local theme tokens, fonts, destination overrides, and browser tooling policy. It never overrides repository policy or safety requirements in this skill. Without it, use the neutral styling below.

Read `assets/deck-template.html` relative to this skill before building. Copy its shell and replace the example slides; adapt layouts to the content rather than forcing every slide into cards. The template uses Reveal.js 5.2.1 from a CDN: it is a single-file deck, **not offline/self-contained**. Keep fonts local/system and diagrams inline. If offline output is requested, inline the required framework assets and verify without network access; do not silently call a CDN-backed file offline.

## 1. Shape the story

- Establish what the audience already knows, what they need to understand or do afterward, this session's role, and what will be shown live. Use the conversation and supplied material; ask one question only when a consequential part is unclear. Don't turn a handoff to experienced owners into an introductory tutorial.
- Propose a short outline showing **part → subsection → slide purpose → visual/example** where those levels are useful. Size the deck to the content and duration, not a fixed slide count. More focused slides can be clearer than fewer compressed slides.
- Read the titles in sequence before building. Introduce concepts before using them; make each slide contribute something new. Add an overview or subsection introduction when the subject changes, without inserting a divider for every slide.
- Proceed with a clear brief or end-to-end request. Pause for agreement only when framing, argument, or topology has a consequential unresolved fork. Context → mechanism/finding → evidence/tradeoffs → takeaway/ask is a useful sequence, not a mandatory schema.
- A plain topic heading ("Retry behavior") is fine; use a takeaway heading for a supported finding. One main idea per slide. Prefer short text, but include enough explanation to make the visual understandable without narration. Split crowded content rather than shrinking it to fit.
- Use a recurring real example when it helps continuity. A worked example should establish what happened, what the evidence explains, and the resulting action/outcome—or the correct investigation boundary. Distinguish immediate mitigation from later follow-up; name the control that actually changed.
- Never invent metrics, dates, owners, quotes, thresholds, product behavior, or claims of safety. Label illustrative code/scenarios as illustrative; don't manufacture a historical before-state. Distinguish measured results, proposals, and assumptions.
- Keep verification bookkeeping in working notes. Resolve or omit material unsupported claims; show uncertainty on-slide when it affects interpretation or action. Don't conceal an evidence gap in notes or add generic research disclaimers to every caption. Update stale caveats when facts are confirmed.
- Read linked material before claiming it supports the deck. Put sources next to evidence or in references; operational buttons should lead to the actual control or investigation view, not merely its source code. Don't launch unrelated investigations to fill slides.
- For live dashboard walkthroughs, blind exercises, or historical case studies, read `references/live-walkthroughs.md`. Keep that specialized workflow out of ordinary decks.

### Write like the presenter

Apply this to headings, slide text, captions, and speaker notes. Adapt the template's content to the supplied material.

- Concrete, direct, conversational: something the presenter would say to coworkers, not polished keynote copy. Keep technical precision without turning everything into jargon.
- Preserve useful phrasing from the presenter's supplied notes, messages, and explanations. Edit for clarity and length, not to replace their language with generic slogans. Don't invent personal anecdotes or opinions to simulate their voice.
- Name what happened and why it matters. Prefer "The counter covers the arrow" over "Create a seamless navigation experience."
- Avoid forced rhetoric: repeated "not X, but Y" constructions, punchy three-part slogans, rhetorical questions, and obligatory inspirational closing slides. Use a real contrast when the content warrants it, not as a writing formula.
- Skip inflated language such as "unlock," "transform," "seamless," "powerful," "journey," and "game-changing" unless quoting relevant source material. Remove filler like "It's important to note" and "Let's dive in."
- Headings can simply name the topic. Don't turn an engineering explanation into marketing or narrate the presentation's own technique.
- Notes are factual reminders in visual order: "Retries can deliver the same job twice. The storage boundary deduplicates by job ID." Avoid coaching such as "Walk the audience through the importance of idempotency."
- Before saving, read the copy as spoken language. Replace anything that sounds like marketing, a motivational poster, or an agent explaining its own presentation. Preserve necessary nuance; don't cut facts just to sound punchy.

## 2. Make the explanation visual

These deck-specific visual principles overlap with explainer-style workflows; this skill does not require loading another skill.

- A visual must explain a relationship or mechanism. A colored box around bullets is not enough. A title or closing slide can be typographic; don't add decoration just to satisfy a quota.
- Choose the right shape:

| Content | Visual |
|---|---|
| Request or execution flow | Labeled nodes and arrows |
| State changes or incident | Timeline / state transition |
| Decision logic | Small branching tree |
| Before vs. after | Side-by-side diagrams with the same topology |
| Parallel scenarios | Two or three clearly labeled cases |
| Evidence | Honest chart with units, period, baseline, and source |
| Options | Compact comparison table |

- Inspect supplied visuals first. State what a diagram must explain before drawing it; labeled boxes alone don't explain a mechanism. For complex architecture/sequence diagrams, sketch Mermaid to settle components and edges, then simplify before SVG. Show it to the user only if topology needs agreement. No remote Mermaid runtime in the final deck.
- Keep actor and control boundaries accurate: who submits, waits, polls, computes, stores and reads the result. Separate status/progress paths from data paths where they differ. A caption cannot repair a misleading arrow.
- Define unfamiliar terms before using them; keep a small legend near the first diagram. Prefer plain-English labels over unexplained identifiers.
- Draw geometric visuals in inline SVG, with unique IDs for markers and accessible `<title>`/`<desc>`. Use HTML/CSS for timelines, comparisons, and layouts. Keep arrow direction and status semantics consistent.
- Use Reveal fragments only when sequencing helps explain the mechanism. Prefer highlighting successive parts of one stable diagram to hiding the whole slide. Don't automatically fragment every bullet.
- Reveal owns arrow/Space navigation. Don't build a separate Prev/Next keyboard handler. No hover-only essential information or nested interactive tab systems by default.

## 3. Build readable slides

- Neutral, professional presentation styling: light background, dark ink, restrained accent highlights. The template's tokens (`--slide-*`) are a usable starting point; a local supplement may supply alternate theme tokens. Keep fonts local/system stacks; don't fetch unlicensed fonts or fabricate official logos or corporate identity.
- Use accents as background/line highlights with dark text, not as text on white. Status colors need words/shapes as well as color. No gradients, emoji filler, decorative gauges, or gratuitous animations.
- On the **1280×720 design canvas**, start around body 24–28px, headings 44–68px and table cells 24px. Technical code/labels/captions can use 20–22px when readable. These are starting points, not rigid minima: Reveal scales the whole canvas, and SVG viewBox scaling can change effective text size. Check the actual presentation viewport; don't make every label huge or shrink crowded content into illegibility.
- Use explicit pixel sizes for text, not nested `em` reductions. SVG labels must be comparably readable after viewBox scaling. Keep short code excerpts with wrapped lines and a source reference; don't paste whole functions.
- Prefer left alignment and generous whitespace. Use two columns when comparison warrants it, not as a default for every slide. No shrinking text, `overflow: hidden`, or scrollable boxes to conceal content that doesn't fit.
- Leave Reveal's section positioning intact. Style an inner `.slide-content` wrapper; don't add `position: relative` to the slide sections or override their transforms.
- Default to minimal motion; honor `prefers-reduced-motion`. All facts must remain legible without animation.
- Use Reveal's built-in scroll view for desk reading (`?view=scroll`); don't build a second navigation/layout system. Keep the template's Reading/Slides link. Allow built-in mobile scroll activation.

### Speaker notes — optional

The template has no speaker notes or notes plugin by default. Add them only when requested or supplied. Use short factual bullets in the slide's visual order—usually 3–5, fewer when appropriate. No coaching paragraphs, transcript, forced audience questions or hidden evidence gaps.

```html
<aside class="notes">
  <ul>
    <li>The queue can deliver the same job again.</li>
    <li>The worker passes the same job ID on each attempt.</li>
    <li>Storage saves the ID with the change to reject duplicates.</li>
  </ul>
</aside>
```

Load the **same pinned version** of `plugin/notes/notes.js` and register `RevealNotes` in `plugins`. HTML comments do not populate speaker view. Explain **S** opens speaker view, and serve over localhost for this feature. Notes are presenter-only in the normal view, **not confidential**: anyone with the HTML can read them. Never put secrets in the file. If one-screen presenting requires a separate prep reference, provide it when requested.

## 4. Revise an existing deck

- Read the current deck and requested changes first; don't rebuild from the template or an older session's remembered version. Record the edit scope, accepted/frozen material, and any authorized global corrections.
- For substantial multi-session work, keep one current outline/decision record with section order, accepted terminology and parked questions. Update it instead of creating a new set of planning artifacts for every revision.
- Carry accepted corrections across related decks where relevant, without rewriting their accepted content. After reordering, read the title sequence and check subsection labels, numbering, references and conclusions.
- Preserve untouched diagrams, evidence and runtime unless the requested change requires them. Use one canonical deck and cache-busting query parameters for preview iterations, rather than accumulating near-identical variants.

## 5. Save and check

- Honor an explicit destination. Otherwise use the active `~/projects/docs/<topic>/` folder, or create an obvious kebab-case topic folder there; ask only if the destination is ambiguous. Filename: `<topic>-slides.html`.
- Don't put personal decks in a product repo, commit them, or create a PR unless asked. Never overwrite an existing deck without reading it first.
- **Browser QA and capability detection:** check the deck in a real browser. If a managed/scriptable browser tool is configured (check the available tools; a local supplement may name the preferred one), drive the QA there rather than launching an OS browser. If only an OS browser exists, do not steal focus without permission. If no browser verification is available, say so explicitly — never report a mental check as visual verification.
- For initial builds, major structural changes and final delivery, check **every slide**, including fully revealed fragments. For small copy/link changes, check the affected slides and relevant interactions. Inspect clipping, overlaps, arrow endpoints, readable labels/code/URLs and frame margins. Measure bounds against the slide canvas; `scrollHeight` misses absolutely positioned/SVG content. Inspect screenshots for diagrams; accessibility snapshots alone aren't sufficient.
- Exercise forward/back navigation and Reading/Slides views, and spot-check a smaller viewport. Keep the slide counter bottom-left, separate from the bottom-right navigation arrows; verify they don't overlap. Inspect failed asset requests and console errors. If notes were requested, check the notes view over localhost.
- If offline output was requested, also verify with network access disabled.
- Report the absolute file path, a brief description, and controls: arrows/Space to advance, Reading for scroll view, **S only if notes are enabled**. Mention the CDN/network requirement. No extra sharing/clipboard prompts unless asked.

### Sharing copies

When a notes-free upload copy is requested, create a clearly named copy such as `<topic>-team.html`; preserve the presenter original. Remove all note content, including `aside.notes` and `data-notes`, plus notes plugin wiring and obsolete speaker controls/cues. Verify zero notes, working navigation/reading view, and unchanged original files. Keep slide content and answers unless their removal was requested. Retain the CDN/network disclosure; stripping notes does not make the deck offline.

## Scope

Use this skill for presentations, including live walkthroughs and exercises. Use `explainer` when the deliverable is a browsable interactive reference with branching navigation, tabs or deep detail. Examples alone don't make a deck an explainer. Don't import its page-sized badges, custom keyboard controls, mandatory approval steps or offline constraint.
