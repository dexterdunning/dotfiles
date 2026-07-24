# Example: Deferred field compute funnel

Reference implementation of `@incremental-feature-stack`. Plan docs live **outside**
the Rippling worktree.

## Plan location

```text
~/projects/docs/tech-specs/deferred-field-compute-funnel/
  plan/
    overview.md
    pr/
      README.md
      04-funnel-core.md           # PR contract
      04-implementation-steps.md  # steps + session log
      04-session-handoff.md       # cold-start hub
      05-async-service-surface.md # next PR (do not implement in PR4)
  implementation-funnel-eta.md      # canonical engineering detail
```

## Worktree (implementation)

```text
/Users/dexter/projects/rippling-worktrees/tanda-deferred-field-funnel
```

## PR stack (as shipped)

```text
master
  └── 4a — work unit (steps 0–4)     #513723
        └── 4b-1 — enqueue (step 5)  #514494
              └── 4b-2 — orchestrator (steps 6–7)  #514495
                    └── 4b-3 — request + fallback (steps 8–10)  #514496
```

## What worked

| Pattern | How it showed up |
| --- | --- |
| Planning vs pairing | Plan docs + closed decisions written first; implementation chat used copy-paste handoff prompt |
| One step per turn | 11 commits across 4a + 4b; user approved each |
| Session log | `04-implementation-steps.md` table updated after commits |
| Mid-flight PR split | User asked to split 4b → negotiated 5 \| 6–7 \| 8–10 in a **ship** conversation |
| Design digressions | Literal types, dispatch shape, successor ETA — resolved in chat, then committed as one step |
| Review sessions | `/review-comments` between steps without losing place in session log |

## Pairing prompt used (PR4 session start)

```text
# PR4 — Deferred field funnel coordinator (pairing session)

Implement incrementally. PR4 funnel core only — not PR5 _async adapters.

Read first:
1. .../04-session-handoff.md
2. .../04-implementation-steps.md
3. .../04-funnel-core.md
4. .../implementation-funnel-eta.md

Worktree: .../tanda-deferred-field-funnel
Rules: ONE step per turn; [tanda] commits; do not one-shot.

Go step 0.
```

## Session hopping in practice

- **Planning chat(s):** overview, PR4 contract, 4a/4b split, step table, handoff
- **Pairing chat(s):** steps 0–10 across multiple days; fresh chats used handoff `next_step`
- **Ship chat:** restack on master + 4b → 4b-1/2/3 split + open PRs

No single chat held the full context — **files did**.
