# [PR NN] — Implementation steps (pairing guide)

Status: **Active** | **Complete** | **Blocked**  
Contract: [NN-<contract>.md](NN-<contract>.md)  
Handoff: [NN-session-handoff.md](NN-session-handoff.md)

Incremental build order. **One step per approval; one commit per approved step.**

## Collaboration rules

- **Agent implements one step only**, then stops.
- **User approves** (review diff, run tests), then asks for a commit.
- **Commit** = one commit per step; use message template below.
- **Update session log** after each commit.
- **Do not batch steps.** Do not one-shot the feature.

## [Sub-PR name] — steps

| Step | Scope | Commit message (template) |
| --- | --- | --- |
| **0** | <!-- e.g. module skeleton --> | `[prefix] feature NN-step0: <short>` |
| **1** | <!-- --> | `[prefix] feature NN-step1: <short>` |

**Done when:** <!-- testable checkpoint -->

## Session log

| Step | Status | Commit / notes |
| --- | --- | --- |
| 0 | pending | |
| 1 | pending | |

Update the row when a step is committed. Status: `pending` | `done` | `skipped` | `blocked`.

## Entry points

- **Default:** step 0
- **Alternative:** step <!-- N --> if <!-- reason -->

## Orchestrator / cross-cutting rules

<!-- Constraints that apply across multiple steps; link to contract -->
