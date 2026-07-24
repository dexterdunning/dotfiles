# [PR NN / sub-PR name] — session handoff

**Cold-start hub.** Any agent with no chat history starts here.

## Session state

| Field | Value |
| --- | --- |
| `session_state` | `planning` \| `ready_for_implementation` \| `implementing` \| `shipping` \| `blocked` |
| `last_updated` | YYYY-MM-DD |
| `last_session_summary` | What the previous session did (1–2 sentences) |
| `next_step` | **NN-stepM** — one-line scope |
| `blockers` | None, or explicit |

## Worktree

| | |
| --- | --- |
| Path | `/Users/dexter/projects/rippling-worktrees/<name>` |
| Branch | `<branch-name>` |
| Base | `origin/master` — restacked YYYY-MM-DD |
| Open PRs | [#NNNN](url) → base `master` |

## Doc map (read order)

| Doc | Purpose |
| --- | --- |
| [NN-implementation-steps.md](NN-implementation-steps.md) | Step table + **session log** (source of truth for progress) |
| [NN-<contract>.md](NN-<contract>.md) | PR contract + acceptance criteria |
| [implementation-detail.md](../../implementation-detail.md) | Canonical engineering detail (if present) |
| [NN+1-*.md](...) | Next PR — **do not implement yet** |

Plan root: `~/projects/docs/tech-specs/<feature-name>/`

## Closed alignment decisions (do not relitigate)

**Architecture**

- <!-- decision 1 -->
- <!-- decision 2 -->

**In scope for this sub-PR**

- <!-- bullet -->

**Explicitly not in this sub-PR**

- <!-- e.g. PR5 adapters, callsite migration -->

**Punted until prod data**

- <!-- e.g. tuning thresholds -->

## Tests

```bash
CDE_CLI_CONFIG_RIPPLING_MAIN_DIR=<worktree-path> cde local test <test-path>
```

## Copy-paste: pairing session (fresh chat)

```text
Continue [FEATURE] — [sub-PR]. Use @incremental-feature-stack pairing rules.

Read first:
1. ~/projects/docs/tech-specs/<feature>/plan/pr/NN-session-handoff.md
2. ~/projects/docs/tech-specs/<feature>/plan/pr/NN-implementation-steps.md
3. ~/projects/docs/tech-specs/<feature>/plan/pr/NN-<contract>.md

Worktree: <path>
Branch: <branch>
Next: <step-id> — <one-line scope>

Rules:
- ONE step per turn; commit only when I say approve/commit
- Do not implement: <exclusions>

Go step <N>.
```

## Copy-paste: ship session (fresh chat)

```text
Ship [FEATURE] [sub-PR stack]. @incremental-feature-stack + dexter-pr-workflow.

Handoff: ~/projects/docs/tech-specs/<feature>/plan/pr/NN-session-handoff.md
Branches: <list bottom to top>
Action: rebase on origin/master, push, open/update stacked PRs
```

## Copy-paste: resume / status only

```text
Resume [FEATURE]. No prior chat context.

Read session-handoff + implementation-steps session log.
Report: committed steps, uncommitted work, next recommended action.
Do not implement until I confirm.
```
