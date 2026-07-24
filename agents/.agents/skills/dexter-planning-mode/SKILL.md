---
name: dexter-planning-mode
description: Use when Dexter wants to investigate a problem, shape ambiguous work, define requirements, explore assumptions, make decisions, or decide whether the output should be an implementation plan, bug fix plan, design doc, postmortem, explainer, or other documentation. Emphasizes iterative discovery over one-shot plan generation.
---

# Dexter Planning Mode

Use this skill for ambiguous work where the right output is not known yet. Do not jump straight to a full plan or document.

## Core Principle

Planning is a discovery loop, not a one-shot document.

Your job is to help Dexter progressively harden understanding:

1. Ask questions, investigate code/data, gather metrics, and inspect existing behavior.
2. Identify the issue, product gap, feature opportunity, design problem, or documentation need.
3. Evolve requirements, assumptions, constraints, open questions, and decision points.
4. Keep concise notes on what has been learned.
5. Only then decide what artifact is needed: implementation plan, bug fix plan, design doc, postmortem, explainer, review checklist, or no artifact yet.

## Anti-Patterns

Avoid these failure modes:

- Do not one-shot a complete plan from vague context.
- Do not run long autonomous loops without checking in.
- Do not bury Dexter in a giant doc before key decisions are made.
- Do not treat early hypotheses as settled requirements.
- Do not let stale investigation details pollute the working summary.
- Do not keep pursuing a path after evidence contradicts it.

## Operating Loop

Work in short loops. Each loop should end with a compact checkpoint and an explicit next choice.

### 1. Frame the Work

Start by classifying the shape of the request. Use tentative labels:

- Bug / regression
- Product gap
- New feature
- Refactor / architecture improvement
- Design doc / technical spec
- Postmortem / incident analysis
- Explainer / communication artifact
- Unknown / needs triage

If the classification is uncertain, say so and ask the smallest useful clarifying question.

### 2. Gather Evidence

Use investigation appropriate to the task:

- Read relevant code and docs.
- Inspect tests and call paths.
- Review diffs, PRs, logs, metrics, dashboards, tickets, or Slack context when available.
- Identify current behavior vs expected behavior.
- Look for prior art and existing conventions.

Prefer targeted investigation. If broad exploration is needed, state the search boundary first.

### 3. Maintain Working Notes

Keep a concise working note in the conversation. If the effort grows, ask whether to write it to a file.

Use this structure:

```markdown
## Working Notes

### Problem / Opportunity
- ...

### Evidence
- ...

### Hardened Requirements
- ...

### Assumptions
- ...

### Open Questions
- ...

### Decision Points
- ...

### Risks / Edge Cases
- ...

### Candidate Artifacts
- Implementation plan / bug plan / design doc / postmortem / explainer / other
```

Rules for notes:

- Keep bullets short.
- Separate facts from assumptions.
- Promote assumptions to requirements only after confirmation or strong evidence.
- Remove or mark superseded hypotheses when they are invalidated.
- Prefer updating the note over appending endless new summaries.

### 4. Ask for Decisions at Branch Points

When a meaningful fork appears, stop and ask Dexter to choose or confirm.

Examples:

- “Is the goal to preserve current behavior or change the product behavior?”
- “Should we optimize for a minimal fix or use this as a refactor boundary?”
- “Is this doc for implementation alignment, stakeholder explanation, or postmortem learning?”
- “Do we need metrics before choosing an approach?”

Ask one or a small set of related questions at a time. Do not dump a huge questionnaire unless Dexter asks for it.

### 5. Decide the Artifact Last

Before producing any substantial artifact, present a decision checkpoint:

```markdown
## Checkpoint

What we know:
- ...

Still open:
- ...

Decision points:
- ...

Recommended next artifact:
- <artifact type>

Options:
1. Continue investigation
2. Draft a lightweight outline
3. Create the full artifact
4. Switch artifact type
```

Only create the full artifact after Dexter chooses or clearly asks for it.

## Artifact Guidance

### Bug Fix Plan

Include:

- Repro / observed behavior
- Expected behavior
- Suspected root cause
- Evidence gathered
- Minimal fix
- Test plan
- Rollout / rollback risk
- Open questions

### Feature Implementation Plan

Include:

- User problem / product goal
- Requirements and non-goals
- Existing system constraints
- Proposed approach
- Alternatives considered
- Milestones / PR breakdown
- Test plan
- Rollout, metrics, and risks

### Design Doc / Spec

Include:

- Context and problem statement
- Goals / non-goals
- Current architecture
- Proposed architecture
- Alternatives
- Decision points
- Migration / rollout plan
- Observability
- Risks and open questions

### Postmortem / Incident Analysis

Include:

- Timeline
- Impact
- Detection
- Root cause and contributing factors
- What went well / poorly
- Corrective actions
- Prevention and monitoring
- Open follow-ups

### Explainer

If the best artifact is a visual explainer, use `dexter-visual-explainer` after confirming the outline.

## Context Hygiene

When the conversation gets long:

- Create a fresh checkpoint summary.
- Mark stale hypotheses as superseded.
- Ask Dexter whether to compact, start a new session, or write notes to a file.
- Prefer a small durable notes file over retaining every investigation detail in chat.

Suggested file names when Dexter wants a file:

- `.pi/plans/<topic>-notes.md` for repo-local planning notes
- `~/projects/docs/<topic>/notes.md` for personal/non-repo notes

Do not create files unless the user asks or the session is clearly becoming too large and Dexter agrees.
