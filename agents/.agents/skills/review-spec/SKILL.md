---
name: review-spec
description: >-
  Review a tech spec or design doc against Dexter's design-review criteria.
  Supports self-review (gaps + proposed edits) and peer-review (prioritized
  findings only). Use when reviewing a tech spec, design doc, or design review;
  or when asked for /review-spec.
argument-hint: [self|peer] [path or topic]
---

Review a technical specification. Two modes share one checklist; they differ in voice and whether edits are proposed.

## Args

$ARGUMENTS

Parse:
1. **Mode** — `self` or `peer`. If omitted, infer: Dexter's own docs under `~/projects/docs/` or "my spec" → `self`; someone else's doc / "peer review" / "review their" → `peer`. If still unclear, ask once.
2. **Target** — file path, directory (prefer `design.md` / `reviewed_version.md` / main `*.md`), URL, or topic. Default search: `~/projects/docs/tech-specs/`. If missing, ask once.

Do not create or overwrite files unless mode is `self` **and** Dexter explicitly asks to apply edits.

## Modes

### `self` — author readiness review

Goal: get the doc ready to share.

- Voice: direct, second-person ("you", "this section").
- For each Gap: say what's missing and **propose concrete section text** (or a surgical rewrite of an existing paragraph).
- End with: (1) Pass/Gap/N/A table, (2) top edits ranked by impact, (3) ask whether to apply edits to the file.
- Do **not** write the file until Dexter confirms.

### `peer` — reviewer feedback

Goal: help the author improve; do not take over the doc.

- Voice: constructive peer review ("the design…", "consider…").
- Output prioritized findings only. Optional suggested wording in a short quote block is fine; do not produce a full rewrite.
- Do **not** edit their file.
- Separate **blocking** (should resolve before approval) from **non-blocking** / nits.

## Process

### 1. Load and orient

Read the target doc (and closely linked sibling docs if the main doc points at them for metrics, punchlist, or appendix). Summarize in 2–4 bullets: problem, proposed approach, scope/non-goals, rollout posture.

### 2. Classify lenses

Pick zero or more **conditional lenses** from the doc's actual architecture (do not force all):

| Lens | When |
|------|------|
| **API / service surface** | New or changed HTTP/RPC/service methods, serializers |
| **Async / events / ETA** | Queues, domain events, ETA/Temporal, funnels, AUA |
| **Persistence** | New collections/tables, schema, read/write patterns, backfill |
| **Ops / runbooks** | Manual SOPs, redrive, admin actions, capacity |

Skip AWS/Lambda/Sev-2/lake-ETL orthodoxy unless the doc is actually that stack.

### 3. Spot-check the codebase (when cheap)

If the doc claims existing call chains, module paths, or "we already have X":

- Verify 1–3 critical claims against the repo.
- If a claim is wrong or stale, mark Gap and cite evidence.
- Do not boil the ocean; prefer targeted greps/reads.

### 4. Apply the checklist

For each item: **Pass**, **Gap**, or **N/A** (with one-line reason for N/A).

Only mark Gap when something material is missing or unjustified. Do not nitpick style if the substance is clear.

### 5. Emit the review

Use the output format below. Cap narrative; prefer the table + ranked findings.

---

## Core checklist (always)

A design doc must (1) communicate a coherent plan and (2) justify decisions over relevant alternatives on shared criteria.

### Clarity & requirements

- [ ] A new teammate can understand the goal without tribal knowledge; prose is appropriately brief
- [ ] Problems explain *why* they matter, not only *what* is wrong
- [ ] Goals and **non-goals** / v1 cuts are explicit
- [ ] Success is measurable (KPIs, rollout metrics, or clear acceptance signals) — or N/A with justification

### Architecture

- [ ] Current architecture is accurate enough to orient (call chains, interfaces, or diagrams as needed)
- [ ] Target architecture names components by **business purpose**, with responsibilities and contracts
- [ ] Add / remove / modify vs today is clear
- [ ] Avoids premature generalization (YAGNI); complexity is justified or deferred
- [ ] Maps to code packages / ownership boundaries at a useful level (not full file lists)
- [ ] Concurrency / races addressed or explicitly accepted with self-heal/mitigation
- [ ] Failure modes, recovery, and blast radius addressed or N/A
- [ ] Backwards compatibility / migration story if changing an existing system
- [ ] Backfill / seeding specified if replacing or introducing durable state that must exist for old data
- [ ] Authn/authz for humans and systems touched by the design — or N/A

### Alternatives

- [ ] Relevant alternatives are real (meet the requirements), not strawmen
- [ ] Proposed design is justified on **shared matrices** tied to goals/NFRs
- [ ] Requirements were pressure-tested for simplicity (maybe a smaller FR unlocks a better design)

### Delivery

- [ ] Implementation phases / milestones follow from the design; boundaries are understandable
- [ ] Feature flags / gating named when rollout risk warrants it
- [ ] Rollout steps include monitor → canary/gradual → cleanup (flag/old path removal)
- [ ] Observability follows the FRs/NFRs (success/failure, latency/duration, capacity/contention as relevant)
- [ ] Critical paths are designed to be testable; test notes cover integration-critical behavior (not unit-certifying every leaf)
- [ ] Open questions list resolve-by timing and current leaning where possible

### Conditional lenses (only if classified)

**API / service surface**

- [ ] Request/response (or service method) contracts defined
- [ ] Concurrent writers / idempotency / pagination called out when relevant
- [ ] Aligns with existing module conventions (not generic REST trivia)

**Async / events / ETA**

- [ ] Trigger/event (or enqueue) contract and source defined
- [ ] Downstream consumers / waiters identified
- [ ] Poison / failure handling and redrive posture defined or N/A
- [ ] Ordering / concurrency model stated (serial vs parallel) with justification
- [ ] Reconciliation / full reload if consuming periodic change data — or N/A

**Persistence**

- [ ] Schema / document shape defined at the level needed to review
- [ ] Read and write patterns match the features
- [ ] Volume growth / hotspot risk addressed at a practical level
- [ ] Technology choice justified in *this* ecosystem (Mongo/etc.), not "unfamiliar with X"

**Ops / runbooks**

- [ ] Manual SOPs justified and minimized; automation preferred
- [ ] Operator utilities (redrive, replay, debug reproduction) described when failure is expected operationally

---

## Output format

```markdown
## Spec review (`self`|`peer`)

**Doc:** <path>
**One-liner:** <what this proposes>
**Lenses:** <list or none>

### Checklist

| Item | Result | Note |
|------|--------|------|
| … | Pass/Gap/N/A | … |

### Findings (priority order)

1. **[Blocking|Non-blocking]** <title> — <why it matters>
   - <self only:> proposed edit under section X: …
   - <peer only:> suggestion: …

### Codebase spot-checks

- <claim> → confirmed / stale / wrong (<evidence>)

### Open questions that should be resolved before approval

1. …
```

For `self`, after findings ask: apply edits to the file?

---

## Relationship to other skills

| Skill | When to use instead / after |
|-------|-----------------------------|
| `write-spec` | Creating a new spec from scratch |
| `grill-me` | Interactive interrogation before or instead of a written review |
| `incremental-feature-stack` | After the spec is solid enough to break into PRs |
| `review-pr` | Code review of an implementation PR, not the design doc |

If the doc is too vague to review, say so and recommend `grill-me` or `dexter-planning-mode` rather than inventing substance.

## Anti-patterns

- Treating the checklist as a mandatory essay for every item — N/A freely when irrelevant
- Demanding AWS/Lambda/Sev-2/ETL-lake artifacts for Rippling Django/Mongo/ETA designs
- Re-estimating story points
- Rewriting a peer's spec unbidden
- Style-only nits when Pass on substance
- One-shotting a "fixed" full doc in `self` mode without a Pass/Gap table and confirmation to write
