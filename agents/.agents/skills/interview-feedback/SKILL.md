---
name: interview-feedback
description: Draft and calibrate concise, evidence-based interview feedback from interview questions, notes, transcripts, screenshots, and candidate code. Use when Dexter asks to fill out, revise, shorten, or choose ratings for an interview scorecard, including shadow interviews.
argument-hint: "[interview materials or feedback question]"
---

Draft paste-ready interview feedback grounded in what happened during the interview.

## Workflow

1. Collect the available question, scorecard fields, notes, transcript, code, and candidate level. Read screenshots and linked/internal material when accessible.
2. Separate:
   - candidate behavior and output;
   - interviewer guidance;
   - Dexter's shadow-process questions or observations.
3. Resolve factual gaps before rating. Ask one clarifying question at a time, only when the answer could change the feedback.
4. When code is provided, inspect it and run it locally when practical. Distinguish sample-output success from satisfying the full contract. If the observed run and submitted code disagree, state the discrepancy rather than guessing.
5. Evaluate against the stated level. Track concrete evidence for:
   - approach and decomposition;
   - completion and correctness;
   - optimality;
   - amount of guidance;
   - code cleanliness;
   - requirement gathering, communication, and receptiveness;
   - AI use, if applicable.
6. Calibrate each rubric independently. Do not count one implementation miss against multiple categories unless it directly bears on each. In particular, distinguish failing to implement a written requirement from unclear communication or poor receptiveness.
7. Recommend a rating and briefly explain mixed signals. For combined rubrics, identify which part drives the rating.
8. Draft concise, natural text in Dexter's voice. Lead with the decision, use specific examples, and avoid generic phrases such as "sound building blocks," "provided limited signal," or repeated "at the level/bar" framing.
9. Write the draft under `~/projects/docs/`, never a product repository's docs directory. Use a descriptive filename and keep the scorecard sections easy to copy separately.

## Guardrails

- Treat shadow feedback as an independent signal; do not inflate certainty or mirror the primary interviewer without evidence.
- Do not claim tests passed unless verified or directly observed. Say which examples or test scope passed.
- Attribute hints accurately. Distinguish minor setup help from guidance on core logic.
- Keep strengths even in a No recommendation and weaknesses even in a Yes recommendation.
- Prefer short paragraphs and concrete facts over exhaustive code review.
