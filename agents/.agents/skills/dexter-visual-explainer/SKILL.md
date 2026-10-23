---
name: dexter-visual-explainer
description: Use when Dexter asks for a visual, diagram, walkthrough, explainer, HTML visual, clickable explanation, or interactive reference for a concept, flow, incident, PR, or code path.
---

# Dexter Visual Explainer

Build visual-first explainers. Prefer diagrams, timelines, state machines, and interactive progressive disclosure over prose.

## Principles

- Diagrams carry the explanation; text is captions, legends, and short takeaways.
- Use progressive disclosure for complex flows.
- Avoid long paragraphs. If a third sentence is forming, replace it with a visual structure.
- Keep the output self-contained when producing HTML.

## Default Workflow

1. Confirm the topic if the request is ambiguous.
2. Propose a tiny outline: sections, tabs, or step-through shape.
3. For architecture or sequence flows, sketch Mermaid first and iterate until topology is right.
4. Promote to a self-contained HTML file only after the structure is clear.
5. Verify the result visually, preferably with the Codex Browser plugin for local files/localhost when available.

Skip the outline when Dexter already provided a clear diagram or asks for one small visual.

## Save Location

- Prefer `~/projects/docs/<topic>/` for personal explainers.
- If the conversation already has an active docs folder, save there.
- If the destination is unclear, suggest a concise kebab-case folder and ask before creating it.
- Do not save personal explainers into a repo unless Dexter explicitly asks for a repo artifact.

## HTML Rules

- Single self-contained HTML file.
- No external CSS, JS, fonts, or CDN.
- Use system fonts.
- Light theme by default.
- Use SVG for geometric diagrams and CSS/HTML for timelines/cards.
- Use small JavaScript only for tabs, step-through controls, or click-to-reveal annotations.
- Include keyboard support for step-through views when practical.

## Useful Patterns

- Multiple scenarios: stacked scenario cards with status badges.
- Sequential trace: step-through with previous/next and counter.
- Decision logic: decision tree with branches.
- State changes: timeline or state-machine diagram.
- Compare two paths: side-by-side or two/three tabs.
- Anatomy of a system: labeled SVG with click-to-reveal details.

## Style Defaults

```text
Background: #fafaf7
Ink:        #1a1a1a
Muted:      #6b6b6b
Rule:       #d0d0c8
Primary:    #4a90d4
Focus:      #d4651a
Good:       #2e7d32
Bad:        #b00020
```

## After Creating

- Tell Dexter the absolute file path.
- If browser verification was possible, mention it.
- Ask before copying files to clipboard or using OS-level GUI actions that require approval.
