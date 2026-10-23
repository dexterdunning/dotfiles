---
name: interview-feedback
description: Draft and calibrate concise, evidence-based interview feedback from interview questions, notes, transcripts, screenshots, and candidate code. Use when asked to fill out, revise, shorten, or choose ratings for an interview scorecard, including shadow interviews.
argument-hint: "[interview materials or feedback question]"
---

Draft paste-ready interview feedback grounded in what happened during the interview.

**Optional local supplement:** if `~/.agents/skill-overrides/interview-feedback/instructions.md` exists, read it first — it carries the local question/rubric reference paths, the company scorecard structure, the destination overrides, and the calibrated voice examples. Without it, apply the generic workflow below with rubrics the user supplies.

## Workflow

1. Collect the available question, scorecard fields, notes, transcript, code, and candidate level. Read screenshots and linked material when accessible, using the appropriate MCP tooling for internal doc/wiki links.
2. Separate:
   - candidate behavior and output;
   - interviewer guidance;
   - the user's shadow-process questions or observations.
3. Resolve factual gaps before rating. Ask one clarifying question at a time, only when the answer could change the feedback. Confirm the candidate's actual coding language before finalizing (e.g. the language dropdown); if the transcript/artifacts disagree with the intended field, flag it rather than silently following either.
4. When code is provided, inspect it and run it locally when practical. Distinguish sample-output success from satisfying the full contract. If the observed run and submitted code disagree, state the discrepancy rather than guessing. Verify any Big-O claims against the data structures actually used (e.g. balanced-tree insert/lookup = O(log n); hash map = amortized O(1)) and record O(1) vs O(log n) misstatements as explicit Weaknesses evidence.
5. Evaluate against the stated level. Track concrete evidence for:
   - approach and decomposition;
   - completion and correctness;
   - optimality;
   - amount of guidance;
   - code cleanliness;
   - requirement gathering, communication, and receptiveness;
   - AI use, if applicable.
6. Calibrate each rubric independently and against the actual rubric, not assumptions. Read the local synced rubric copy when one exists (see supplement) — it has the per-part prompts, strength categories, automatic-failure rules, and per-level bars. It may explicitly allow things you'd otherwise penalize. Fall back to pulling the rubric from its documented source when permitted.
7. Recommend a rating and briefly explain mixed signals. For combined rubrics, identify which part drives the rating.
8. Draft concise, natural text in the user's voice. Lead with the decision, use specific examples, and avoid generic phrases such as "sound building blocks," "provided limited signal," or repeated "at the level/bar" framing.
9. Write the draft to the configured scratchpad directory (see supplement; otherwise `~/Desktop/interview-scratchpad/feedback/` or a user-specified folder). Use a descriptive filename (e.g. `name-level-question.md`) and keep the scorecard sections easy to copy separately. Never write into a product repository's docs directory.

## Scorecard drafting (generic structure)

When drafting for a Coding/Algo interview scorecard, produce sections that can each be pasted separately:

- **Overall rating** — Strong No / No / Yes / Strong Yes. Recommend one; when mixed signals make an adjacent rating defensible, name it and say what tips the scale.
- **Overall feedback** — short paragraph (2–4 sentences) leading with the decision, and explicitly naming the strongest counterbalancing strength even when the rating is a No.
- **Question / language** — one-liners; use the exact dropdown question name when known.
- **Per-part assessment** — one labeled block per question part attempted; state explicitly when later parts were never reached. Within each block use plain-text labeled bullets: Strengths / Weaknesses / Completion / Correctness-risk / Guidance. Do not bold these labels or the completion summary; Markdown bolding interferes with pasting into the scorecard. Put a complexity or completeness misstatement in its own Weaknesses bullet rather than burying it in prose.
- **Code cleanliness** — Pass/Fail dropdown recommendation plus justification with specific examples; one theme plus 1–2 examples, don't re-list bugs already covered per-part.
- **Requirements, communication, and receptiveness** — Pass/Fail dropdown recommendation plus justification. This is a combined rubric; name which leg drives the rating.
- **AI usage** — brief description of how the candidate used the assistant, with positive or negative signal observed. For negative signal, prefer a constructive, future-oriented framing over pure criticism. Still record red-flag patterns (didn't understand/read their own code, trusted bad tests). Skip if not an AI interview.
- **Leveling assessment** — usually `n/a` unless there is evidence the candidate fits a different level.

## Guardrails

- Treat shadow feedback as an independent signal; do not inflate certainty or mirror the primary interviewer without evidence.
- Do not claim tests passed unless verified or directly observed. Say which examples or test scope passed.
- Attribute hints accurately. Distinguish minor setup help from guidance on core logic.
- Keep strengths even in a No recommendation and weaknesses even in a Yes recommendation.
- Prefer short paragraphs and concrete facts over exhaustive code review.
- Don't credit OOP intent from announced plans — judge the delivered code.
- Be conservative attributing comprehension of interviewer probes from the transcript alone; prefer neutral phrasing.
- For barely-used assistants, follow the rubric's shared note: describe the minimal use factually rather than claiming the assistant was never opened. If live observation conflicts with transcript inference, the user's version wins.
- Question dropdowns: match the exact dropdown option text.

## Style calibration

- No intensifiers or hedges: "his design was good", not "genuinely good" / "really solid".
- In weaknesses, name the simpler alternative concretely and constructively.
- Requirements justification: concrete positive evidence only — no meta-commentary about where misses are counted, no verbosity hedges.
