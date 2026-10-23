---
name: worklog-review
description: Turn synthesized worklog into a filled performance self-review (MYPR/CPR), question by question
argument-hint: "[MYPR 2026 | CPR 2026] [--level SWE-II] [--reviewee NAME]"
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*), Write(*), Edit(*), WebFetch(*), AskUserQuestion(*)
---

Convert worklog evidence into actual review-form answers. This is the step AFTER
`worklog-summary` (which produces perf-ready project stories). Run `worklog-summary` first to
get the story base, then use this to fill the real form.

Unlike worklog-summary (which synthesizes stories), this skill is **form-aware**: it works one
question at a time against the actual review questions, applies the grading rubric, calibrates
ownership, enforces the review window, matches the user's tone, and checks cross-cycle
continuity. It is a coach, not a ghostwriter.

## Input

$ARGUMENTS — the review cycle and optional metadata:
- `MYPR 2026` / `CPR 2026` — which cycle. The cycle defines the **hard review window** and the
  question set.
- `--level` — e.g. SWE-II. Used for level-calibration signals (see Continuity).
- If absent, ask the user.

## Setup (do once per review)

1. **Confirm the review window and treat it as strict.** MYPR 2026 = Feb 1 – Jul 31 2026. Do not
   use out-of-window work as primary evidence. Note: a recent high-visibility incident that lands
   just AFTER the window (e.g. an Aug incident after a Jul 31 cutoff) is tempting but out of
   scope; its in-window precursor (the design/rollout that caused it) is fair game.
2. **Get the actual questions + subtext.** Ask the user to paste them (screenshots fine — read
   the image). Do NOT invent the question set. The subtext/rubric columns are what graders read
   for; capture them verbatim into the notes.
3. **Fetch the authoritative rubric when reachable.** If Atlassian/Confluence MCP is connected,
   pull the HR guide and any values/leadership rubric pages (search CQL) and cite them. The
   "what good looks like" and "red flags" per principle directly shape framing.
4. **Confirm reviewee context:** level/title, manager, people-manager or IC. (People-manager
   reviews need a management-capability thread; IC reviews don't.)

## Per-question loop (follow for each question, one at a time)

1. Show the question + its subtext verbatim.
2. Map candidate worklog stories onto the question's rubric prompts. Present candidates with a
   rough impact hook, the user's likely **ownership level** (direct owner / main driver /
   strategic driver / contributor / enabler), and what needs confirmation. Do NOT draft yet.
3. **Probe for ownership and the truth.** Ask pointed questions to separate personal ownership
   from team/cross-functional outcomes (see Ownership calibration). Get the user to confirm,
   merge, reweight, or cut. Record decisions.
4. **Fill metric gaps on demand.** When the user supplies a dashboard, actually explore it (use a
   Datadog-investigation skill if available). Watch for honesty traps: a big number may be a
   2-day spike, not a baseline — say so and frame it as such. Flex-log retention is ~50 days, so
   long before/after baselines may be unavailable; don't fabricate one.
5. Draft the answer.
6. Add an **Evidence and context check** block (strongest support / needs more context /
   watchouts / suggested follow-ups). Be candid; flag overclaim risk.
7. Iterate with the user until content is locked. Tone can be deferred to a final pass.

## Ownership calibration (the highest-value step)

Reviewers punish overstated ownership. For each achievement:
- Ask who else drove/reviewed it. Name their role ("Vihari oversaw/reviewed; I was main driver").
- Distinguish "I enabled X" from "I owned X." For platform migrations (e.g. DB sharding), the
  enabling team member should NOT claim they led the migration — say "did the enabling work;
  Infra owned the cluster move."
- Prefer **leadership/peer-attributed** impact claims over self-claims. If a senior person said
  "this caused all 3 incidents," quote and attribute them rather than asserting it yourself.
- A "first-of-its-kind / hottest collection / golden customer" framing is a strong scope signal —
  surface it, but only if true.

## Tone

- Ask the user how they want to sound. Default: infer from their Slack/worklog writing — plain,
  direct, first-person, technical, no flourish.
- Strip AI-isms from the prose bodies: em-dashes, "it's not X, it's Y" constructions, "delve",
  "leverage", over-hedging. Em-dashes in bolded section *headers* are fine.
- Use metrics that carry weight, stated once, plainly. Do not stack numbers for volume.
- The user may want a register "more polished than Slack but still distinctly me" — plain and
  direct, complete sentences, conversational-professional.

## Cross-cycle continuity (level-calibration)

Read the user's previous review (ask for it). Watch for:
- **Repeated Leadership Principle.** Re-using a principle is GOOD if framed as "same principle,
  bigger scope" (continuity + leveling). Say that explicitly to preempt "didn't you use this
  before?"
- **A principle that reads as a re-label of a previous one.** E.g. last cycle's "Go and See"
  (hands-on depth) vs this cycle's "Are Right, A Lot" (diagnosis) can look identical. If so,
  either sharpen the new one to be clearly about judgment-under-ambiguity, or pick a different
  principle.
- **Level signal.** For someone pushing toward the next level, prefer principles/stories that
  signal next-level scope (architecture bets, cross-team customer ownership, developing others)
  over table-stakes depth at the current level. Call this out and let the user choose.
- **Q&A consistency across answers.** If a "growth area" in one answer was claimed as "fixed"
  in another, align the tense (improving now vs keep growing) so they don't contradict.

## Output

Maintain two files in `~/.worklog/reviews/`:
- `<cycle>-self-review.md` — working notes: questions verbatim, rubric, candidate themes,
  confirmed decisions, drafts, evidence checks, and the decision rationale for any contested
  framing.
- `<cycle>-self-review-FINAL.md` — clean copy-paste answers only (no evidence checks / notes),
  written on request.

## Guardrails

- One question at a time; never draft before at least one confirm/edit exchange on that question.
- Never invent metrics, stakeholder feedback, or incidents. Label inference and ask to confirm.
- Keep related workstreams distinct to avoid double-counting (e.g. a point-fix vs the later
  re-architecture; the incidents a fix *resolved* vs the incident-response portfolio).
- Cite the rubric/guide sources you used in plain language.
