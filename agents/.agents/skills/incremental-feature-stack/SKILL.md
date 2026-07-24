---
name: incremental-feature-stack
description: >-
  Plan, pair-implement, and ship large multi-PR features incrementally with
  session-portable handoff docs. Use when starting a tech spec, continuing a
  stepped implementation in a fresh chat, splitting a PR stack, or resuming after
  a break. Supports planning-only sessions, pairing sessions, and ship sessions
  as separate agents or chats.
---

# Incremental Feature Stack

Build large features as a **documented PR stack** with **atomic implementation
steps**. Any agent can cold-start from the handoff — no chat history required.

## Session types (jump in / out freely)

| Session | Goal | Reads | Writes before exit |
| --- | --- | --- | --- |
| **Planning** | Decompose feature → PR stack → steps | Existing design docs, module guidance | `overview`, PR contracts, `implementation-steps`, `session-handoff` |
| **Pairing** | Implement **one** approved step | `session-handoff` → `implementation-steps` → PR contract | Code diff (uncommitted until user approves); session log on commit |
| **Review** | Neovim `/review-comments` or design Q&A | Current diff + contract | Code fixes; no commit unless user asks |
| **Ship** | Rebase, split PRs, push, open/update PRs | Handoff branches + `gs log` | Handoff PR URLs; use `dexter-pr-workflow` |

**Rule:** Progress lives in **files**, not conversation. End every session by
updating `session-handoff.md` (see [Session exit checklist](#session-exit-checklist)).

**Rule:** A pairing agent must **not** assume prior chats. Read handoff first;
trust the session log over user memory.

## Where artifacts live

Default (Rippling large features):

```text
~/projects/docs/tech-specs/<feature-name>/
  plan/
    overview.md
    pr/
      README.md              # PR stack index
      NN-<name>.md           # PR contract per number
      NN-implementation-steps.md
      NN-session-handoff.md
```

Keep plan docs **outside the worktree** so they survive worktree cleanup. Link
worktree path and branch names in handoff only.

Use [templates/](templates/) when bootstrapping a new feature.

## Phase 0 — Planning session

Do this in a **planning chat** (can be a different agent than implementation).

1. **Program overview** — phases, PR dependencies, exit criteria
   ([templates/overview.md](templates/overview.md))
2. **Per-PR contract** — goal, requirements, approach, acceptance criteria,
   explicit exclusions, explored-not-chosen variants
   ([templates/pr-contract.md](templates/pr-contract.md))
3. **Split large PRs** — if one PR is >1 review story or ~500+ LOC in one file,
   define sub-PRs (e.g. 4a work unit, 4b coordination, 4b-1/2/3 further split)
4. **Implementation steps** — numbered steps, commit message templates, empty
   session log ([templates/implementation-steps.md](templates/implementation-steps.md))
5. **Session handoff** — worktree, branches, closed decisions, copy-paste prompts
   ([templates/session-handoff.md](templates/session-handoff.md))

Set handoff `session_state: ready_for_implementation` and `next_step` before
ending the planning session.

### PR split checklist

Split when **any** apply:

- [ ] More than one semantic story in one diff
- [ ] No testable checkpoint before the next layer
- [ ] Public API mixed with internal loop mechanics
- [ ] Safety/observability (fallback, metrics) blocks core review

**Good splits:** infrastructure → internals → public API → safety net.

**Bad splits:** thin wrapper vs implementation; arbitrary commit boundaries.

## Phase 1 — Cold-start pairing session

Paste the **pairing prompt** from handoff (or build from template below). Agent
reads **in order**:

1. `NN-session-handoff.md` — closed decisions, worktree, next step
2. `NN-implementation-steps.md` — session log + step table
3. PR contract for current sub-PR
4. Nearest module `CLAUDE.md` / `AGENTS.md`

Then implement **exactly one step** and **stop without committing**.

### Pairing loop

```text
implement ONE step → STOP (no commit)
  → user reviews / /review-comments / design Q&A
  → user: "commit" / "approve" / "commit step N"
  → ONE commit (template message + Co-Authored-By)
  → update session log row in implementation-steps.md
  → update session-handoff.md (next step, last session note)
  → STOP (do not start next step unless user asks)
```

### User signals

| User says | Agent does |
| --- | --- |
| `go step N` / `next step` | Implement step N only; stop for review |
| `commit` / `approve` | Commit current step; update docs; stop |
| `/review-comments` | Fix Neovim comments; no commit unless asked |
| Design question | Answer; may edit current step; no commit unless asked |
| `split PRs` / `restack` | Switch to **Ship** workflow (Phase 3) |

### Collaboration rules (non-negotiable)

- One step per turn; do not batch steps
- Do not one-shot the whole feature
- Do not relitigate **closed decisions** in handoff
- Do not implement exclusions listed in PR contract (e.g. "not PR5")
- Flag-off / no-callsite paths must match production behavior

## Phase 2 — Review session

Can be same or different chat. No implementation-steps change unless code changed.

1. Run `review-comments-export` (if Neovim flow)
2. Fix each comment; `review-comments-resolve`
3. Re-export to verify clean
4. Summarize per file; **do not commit** unless user asks

## Phase 3 — Ship session

Use with `dexter-pr-workflow` and `dexter-worktree-workflow`.

1. `git fetch origin master` → rebase stack from bottom up
2. If splitting mid-flight: cut branches at semantic commits; `gs branch track`
3. Force-push only when user approved restack
4. Open stacked PRs bottom-up; link in handoff
5. Update handoff: PR URLs, `session_state: shipped` or `implementing` (if more steps)

## Session exit checklist

Before ending **any** session, update `NN-session-handoff.md`:

```markdown
| Field | Example |
| --- | --- |
| `session_state` | `planning` \| `ready_for_implementation` \| `implementing` \| `shipping` \| `blocked` |
| `last_updated` | ISO date |
| `last_session_summary` | "Committed 4b-step6; orchestrator round tests green" |
| `next_step` | `4b-step7` — one-line scope |
| `worktree` / `branch` | paths and active branch |
| `open_prs` | links if any |
| `blockers` | empty or explicit |
```

Update `NN-implementation-steps.md` session log when a step is **committed**.

## Copy-paste prompts

### Planning session (new feature)

```text
Plan a multi-PR feature stack using @incremental-feature-stack.

Feature: [name]
Design context: [paths or brief]
Worktree will be: ~/projects/rippling-worktrees/[name]

Deliver:
- plan/overview.md + plan/pr/README.md
- PR contract for first implementable PR
- implementation-steps + session-handoff for that PR

Do not write application code. End with pairing prompt for step 0.
```

### Pairing session (fresh chat — no prior context)

```text
Continue [FEATURE] — [sub-PR name]. Use @incremental-feature-stack pairing rules.

Read first (in order):
1. [path]/NN-session-handoff.md
2. [path]/NN-implementation-steps.md
3. [path]/NN-<contract>.md

Worktree: [absolute path]
Branch: [branch]
Next: [step-id] — [one-line scope]

Rules:
- ONE step per turn; stop for review; commit only when I say approve/commit
- Do not implement: [exclusions from handoff]

Go step [N].
```

### Ship session (fresh chat)

```text
Ship [FEATURE] stack using @incremental-feature-stack + dexter-pr-workflow.

Read: [path]/NN-session-handoff.md
Action: rebase on origin/master, [split if needed], push, open/update stacked PRs
Branches: [list]
```

### Resume after long break

```text
Resume [FEATURE]. I have no prior chat context.

Read session-handoff + implementation-steps session log.
Tell me: current step, what's committed, what's uncommitted, recommended next action.
Do not implement until I confirm.
```

## Composes with

| Skill | When |
| --- | --- |
| `dexter-worktree-workflow` | Create worktree, `gs branch track` |
| `dexter-pr-workflow` | PR template, labels, stack submit |
| `review-comments` | Neovim review between steps |

## Reference example

See [examples/deferred-field-funnel.md](examples/deferred-field-funnel.md) — the
funnel PR4 stack (4a → 4b-1 → 4b-2 → 4b-3) that motivated this skill.

## Templates

| File | Purpose |
| --- | --- |
| [templates/overview.md](templates/overview.md) | Program-level PR roadmap |
| [templates/pr-contract.md](templates/pr-contract.md) | Single PR requirements |
| [templates/implementation-steps.md](templates/implementation-steps.md) | Steps + session log |
| [templates/session-handoff.md](templates/session-handoff.md) | Cold-start hub |
