---
name: write-spec
description: Create a technical spec through codebase exploration, user interview, and architecture design. Use when user wants to write a tech spec, design doc, or plan a significant engineering change.
argument-hint: [feature or problem area]
---

This skill creates a technical specification document. You may skip steps that aren't necessary for the scope of the change.

## Phase 1: Understand the problem

1. Ask the user for a detailed description of the problem they want to solve, current pain points, and any solution ideas they already have.

2. Explore the codebase to verify their assertions and understand the current architecture. Map out the relevant code paths, data models, and existing patterns. Use the Explore agent for broad searches. Summarize what you found — don't just silently absorb it.

3. Interview the user about their design using the same adversarial style as /grill-me: one question at a time, follow branches, don't accept hand-waving. Focus on:
   - What's in scope vs explicitly out of scope
   - Key constraints and non-goals
   - Failure modes and edge cases
   - Tradeoffs between approaches (present alternatives you found in the codebase)

   Keep going until every decision branch is resolved or explicitly deferred.

## Phase 2: Sketch the architecture

4. Sketch out the major components that need to be built or modified. For each:
   - What it does (interface / contract)
   - How it interacts with existing code
   - What changes vs what stays the same

   Look for opportunities to extract deep modules — components that encapsulate significant functionality behind a simple, testable interface.

5. Check with the user that these components match their expectations. Resolve disagreements before proceeding.

## Phase 3: Write the spec

6. Write the spec using the template below. Save it to the path the user specifies, or default to `~/projects/docs/tech-specs/<slug>.md`.

   The spec should be written for a technical peer — direct, analytical, and justificative. Explain *why* decisions were made, not just what they are. Use "we" for collaborative decisions.

<spec-template>

# [Title]

## 1 Background

### 1.1 Context

What system/feature this relates to. Brief orientation for the reader.

### 1.2 Current Architecture

How the relevant parts work today. Include code paths as call chains where helpful:

```
function_a (module:line)
  -> function_b (module:line)
    -> function_c (module:line)
```

Include class diagrams (mermaid) or interface stubs if they clarify the current state.

### 1.3 Problems

Numbered list of specific problems with the current state. Each should explain *why* it's a problem, not just *what* it is.

### 1.4 Scope

What this spec covers. Explicitly state non-goals.

## 2 Target Architecture

### 2.1 Overview

High-level description of the target state. Include a diagram if the architecture has multiple interacting components.

### 2.2 [Component Name]

For each major component or layer, describe:
- Responsibility and interface
- Key data structures (show as Python stubs or tables)
- Interaction with other components
- Behavior changes from current state

Repeat subsections (2.3, 2.4, ...) for each component.

## 3 Implementation Plan

High-level phases of the work. For each phase, describe:
- What it achieves
- Key milestones or deliverables
- Dependencies on other phases

List any feature flags needed, their names, and their purpose.

For detailed PR breakdown and stacking strategy, use `/incremental-feature-stack` after the spec is finalized.

## 4 Rollout Strategy

Step-by-step rollout plan:
1. Deploy with flag disabled
2. Enable for test company / canary
3. Monitor: [specific metrics and dashboards]
4. Gradual rollout by percentage
5. Cleanup: remove flag, delete old code path

## 5 Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| [What could go wrong] | [How we prevent or recover from it] |

Include expected impact quantification where possible (e.g., "write count drops from 2NF to 2N").

## 6 Open Questions

Numbered list of unresolved questions or deferred decisions. For each, note:
- Why it's unresolved
- When it needs to be resolved
- Current leaning (if any)

## Appendix

Optional. Tradeoff deep-dives, FAQ-style discussion of alternatives considered, links to related docs or prior art.

Use format:
#### A.1 [Question or topic]
**Context:** ...
**Options:** ...
**Decision:** ... (or **My take:** ... if not yet decided)

</spec-template>

## Guidelines for writing

- **Numbered top-level sections**: `## 1 Background`, `## 2 Target Architecture`, etc.
- **Decimal subsections**: `### 1.1 Context`, `### 2.3 Service Layer`
- **Bold callouts** for decisions: `**Decision:**`, `**Non-goals:**`, `**My take:**`
- **Tables** for comparisons, risk matrices, API surfaces
- **Code blocks** for interfaces, data structures, and call chains — but pseudo-code, not full implementations
- **Mermaid diagrams** for class relationships and flow charts where they add clarity
- **Feature flags** named explicitly and linked to rollout phases
- **File paths** shown as module paths: `app/module/submodule/file.py`
- Avoid prescribing implementation details that belong in PRs — the spec defines *what* and *why*, PRs define *how*

7. Present the spec to the user for review. Incorporate feedback until they're satisfied. For a structured pass, use `/review-spec self <path>` (author readiness) or `/review-spec peer <path>` (external feedback).
