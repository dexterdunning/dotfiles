---
name: explainer
argument-hint: [topic]
description: Build an interactive HTML explainer for a concept — diagrams first, progressive disclosure for complex flows. Use when the user asks for a "visual", "diagram", "walkthrough", "explainer", an "HTML visual", or wants to "make this clickable / interactive" for a topic just discussed.
---

Build an HTML explainer for: $ARGUMENTS

## Principle: diagrams over text

The user prefers visuals to prose. If you can show it as a timeline, a sequence of states, a decision tree, a flow, or a labeled diagram — do that, and let the text be captions and legends only. Long paragraphs of explanation are a failure mode. If you find yourself writing a third sentence in a row, replace it with a diagram.

## Principle: progressive disclosure for complex flows

If a topic has multiple steps, branches, or edge cases, let the reader move through them one at a time rather than dumping everything at once. Pick the technique that fits:

- **Scenarios / cases stacked vertically** — one diagram per case, badge headers (good/bad/neutral). Best when 3–6 parallel-but-distinct situations need to be compared (e.g. the shift-start scenarios A/B/C/D).
- **Native `<details>` collapsibles** — for "here's the deep detail if you want it." No JS. Best for FAQ-style or "show the code" reveal.
- **Tabs (small JS)** — for parallel views of the same thing (e.g. "user perspective" vs "system perspective", "before" vs "after"). Two-three tabs max.
- **Step-through with Prev/Next (small JS)** — for a sequential walk where each step builds on the prior (e.g. tracing a request through 7 services, animating a state machine). Always show step counter ("3 / 7") and allow keyboard ← →.
- **Hover / click-to-reveal annotations** — when a single diagram has many labelable parts. Click a node, see its detail in a side panel.

Default to scenarios stacked vertically unless the topic is clearly sequential.

## Iteration order: outline → mermaid → HTML

HTML is the final form. Iterating in HTML for structural decisions is
expensive — each "move section X before Y" or "swap which scenario leads" is
a big chunk of nested `<div>` / `<section>` rewrite even when the underlying
idea barely moves. SVG diagrams are worse: coordinates change as soon as you
add or remove a node. Lock the cheap things first.

**Default workflow for any explainer:**

1. **Outline in chat.** Two or three sentences: section list, tab structure,
   what each tab contains. Example: *"Tabs: 1·pieces, 2·lifecycle, 3·scenarios,
   4·failures, 5·rollout, 6·open. Scenario tab has A/B/C/D stacked. Failures
   tab leads with the May 13 timeline."* The user eyeballs it, locks
   structure, you proceed. No file written yet.

2. **Mermaid for architecture / sequence / flow diagrams.** Paste mermaid
   blocks in chat, iterate until topology is right. Mermaid is dramatically
   less text than the equivalent SVG (`A --> B` vs ~5 lines of SVG with
   coords), which makes "is this the right set of components and connections?"
   a cheap question to answer. **Simplify aggressively before promoting** —
   if a node group can collapse without losing meaning, collapse it. The final
   SVG inherits whatever the mermaid said, so trimming here saves both ends.

3. **Plain text sketches for visual compositions** that mermaid can't
   express well: scenario cards with badges + side text, timelines with
   state dots, interactive overlays. Describe in one line: *"scenario card:
   web srv → queue → shadow, badge=bad, side text about the conflict."*

4. **Promote to HTML.** Translate mermaid → hand-rolled SVG, build the
   compositions, wire any interactivity. Use HTML for the visual treatment,
   not the thinking.

**When to add a `draft.md` step:**

For big explainers (5+ sections, multiple diagrams, complex argument), draft
prose in `~/projects/docs/<topic>/draft.md` after the outline lock but before
HTML promotion. Useful when:

- You expect substantial rework on the *prose* (not just structure)
- The user wants to read through the argument before any visual polish
- Multiple people will review

For most explainers, the outline + mermaid steps catch the structural
problems without needing a markdown draft. Don't write `draft.md`
prophylactically — only when there's a concrete reason.

**When to skip even the outline step:** the user already drew or pasted a
diagram, or the topic is one mechanism in one diagram. Go straight to HTML.

## Save location

Always save under `~/projects/docs/`. Decide the subdirectory by asking, in order:

1. **Is there an active investigation folder we're already working in?** (e.g. the conversation has been building docs under `~/projects/docs/<thing>/`.) If yes, save the explainer there as a sibling file. Do not ask — just save.
2. **Could it fit in an existing folder?** Run `ls ~/projects/docs/` and look for an obvious home. If you find one or two plausible candidates, ask the user: "Save under existing folder `X` or create a new one `Y`?"
3. **No clear home?** Suggest a new subdirectory name (kebab-case, scoped to the topic) and confirm with the user before creating.

Never save explainers to `~/.claude/`, a product repo, or the project root.

File naming: `<topic>_explainer.html` or just `<descriptive_name>.html` — lowercase, underscores or hyphens.

## After saving

1. **Open in browser immediately.** Run `open <path>` (macOS) to launch in the user's default browser. The Launch preview panel is unreliable for HTML/SVG; opening directly is the default, not a fallback.

2. **Ask if they want the file copied to clipboard for sharing.** After opening, ask one sharp question — something like: *"Copy the file to your clipboard so you can paste it into Slack/email?"* — and wait for a yes/no.

3. **If yes, copy the file (not the path) to clipboard** so it pastes as a file attachment, not as a string. Use:
   ```bash
   osascript -e 'tell application "Finder" to set the clipboard to (POSIX file "<path>")'
   ```
   Confirm with a one-line response like *"Copied — paste into Slack/email."*

4. **If no, just acknowledge.** Don't push further.

## What goes in every explainer

1. **Title + one-sentence lede** — explains the "what" and "why" in under 30 words.
2. **Glossary or 'what's a X' opener** — quickly define non-obvious terms before they show up in diagrams.
3. **The visual core** — the actual diagrams. This is most of the page.
4. **Legend** — color/shape key, near the first diagram. Doesn't need to repeat for every diagram if styling is consistent.
5. **"Why it matters" or "The takeaway"** — a short closing section that ties the visuals back to the original question.
6. **Link out to the fix / code / PR / doc** if one exists — bottom of page.

## HTML structure rules

- **Single self-contained file.** No external CSS, no external JS, no CDN, no fonts. Inline everything. The file should work offline and from `file://`.
- **System font stack** (`-apple-system, BlinkMacSystemFont, ...`) for everything except code, which uses `"SF Mono", Menlo, Consolas, monospace`.
- **Width cap** — `max-width: 1100px; margin: 40px auto;` on `body`. Don't let lines run forever.
- **Light theme by default.** Background near-white (`#fafaf7`), ink near-black (`#1a1a1a`), muted gray for captions. Use a small accent palette — not a rainbow.
- **No bootstrap, no tailwind, no D3, no Mermaid as a remote include.** If you need Mermaid, inline the JS bundle — but prefer hand-rolled SVG / CSS positioning for tighter control.
- **SVG for anything geometric** (arrows, nodes, networks). CSS-positioned divs for timelines and bar-like layouts.
- **Code samples** in `<pre>` blocks with dark background. Real code, not pseudocode, when referencing a specific function.

## Quick pattern library

When the topic fits one of these shapes, reach for the matching pattern:

| Topic shape | Pattern |
|---|---|
| "When does this happen?" with multiple scenarios | Stacked scenarios with badges (see `~/projects/docs/deferred-field-or-fanout/shift_start_explainer.html`) |
| "How does X flow through the system?" | Sequenced step-through with Prev/Next, one frame per hop |
| "What are the branches in this decision?" | SVG decision tree with click-to-expand nodes |
| "How does state change over time?" | Timeline with state markers, or state-machine SVG with active-state highlight |
| "Compare A and B" | Side-by-side two-column layout, or tabs |
| "What does each piece of this thing do?" | One labeled SVG/photo + click-anywhere annotations |

## Style guide (compact)

```
Background:   #fafaf7
Ink:          #1a1a1a
Muted:        #6b6b6b
Rule line:    #d0d0c8
Primary:      #4a90d4 (blue)
Accent:       #d4651a (orange) — use for "this is the focus"
Good:         #2e7d32 / fill #c8e6c9
Bad:          #b00020 / fill #f6c6c6
Neutral fill: #ffe9c7 / border #c89a4a
```

Badges:

```html
<span class="badge good">valid</span>
<span class="badge bad">empty filter</span>
```

```css
.badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.3px;
}
.badge.good { background: #c8e6c9; color: #2e7d32; }
.badge.bad  { background: #f6c6c6; color: #b00020; }
```

## Step-through pattern (when you reach for it)

```html
<div id="steps">
  <div class="step active" data-step="1"><!-- frame 1 --></div>
  <div class="step" data-step="2"><!-- frame 2 --></div>
  <!-- ... -->
</div>
<div class="step-controls">
  <button id="prev">←</button>
  <span id="counter">1 / N</span>
  <button id="next">→</button>
</div>
<script>
  const steps = [...document.querySelectorAll('.step')];
  let i = 0;
  const render = () => {
    steps.forEach((s, idx) => s.classList.toggle('active', idx === i));
    document.getElementById('counter').textContent = `${i+1} / ${steps.length}`;
  };
  document.getElementById('next').onclick = () => { i = Math.min(i+1, steps.length-1); render(); };
  document.getElementById('prev').onclick = () => { i = Math.max(i-1, 0); render(); };
  document.addEventListener('keydown', e => {
    if (e.key === 'ArrowRight') document.getElementById('next').click();
    if (e.key === 'ArrowLeft')  document.getElementById('prev').click();
  });
</script>
<style>.step { display: none; } .step.active { display: block; }</style>
```

## Don'ts

- Don't open with three paragraphs of background. Cut to the visual.
- Don't use emojis as content. Badges, colors, and SVG icons carry the signal.
- Don't reproduce code verbatim if a small annotated snippet would do. Reference the file path + line number instead.
- Don't write tutorials. The user already knows the domain — they want a visual reference, not training material.
- Don't ask "should I add X" mid-build. Make the call, save the file, the user will tell you if it's off.

## Process

1. Confirm the topic. If the user just said "make a visual" with no specifics, ask one sharp clarifying question: "What's the question this should answer?"
2. **Outline in chat.** Section list / tab structure / what's in each. Two or three sentences. Wait for the user to lock it. See **Iteration order**.
3. **Mermaid in chat for each architectural diagram.** Iterate on topology. Simplify aggressively. The user confirms each before promotion.
4. Pick the save location per the rules in **Save location**.
5. (Optional, for big explainers) draft prose as `draft.md` in the folder — see the **Iteration order** section for when this is worth it.
6. Promote to HTML. Translate mermaid to hand-rolled SVG. Build visual compositions. Keep prose to captions and legends.
7. Save and open in the browser. Tell the user the path.
