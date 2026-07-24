# Dexter Preferences

- Be concise by default: skip filler, avoid long preambles, and prefer bullets or compact summaries.
- Expand when the task is complex, when tradeoffs matter, or when Dexter asks for detail.
- For tool-heavy work, summarize findings instead of narrating every command.
- Preserve exact details that matter for code changes: file paths, line numbers, commands, errors, and test results.
- For Rippling PR templates, use `N/A` for the JIRA section when there is no ticket instead of `TODO`.

# Communication Style

- Do not narrate internal deliberation, uncertainty, or tool-choice debates.
- Avoid phrases like “I’m thinking…”, “I’m curious…”, “I’ll keep tweaking…”.
- If uncertain, state the concrete uncertainty, current evidence, and next action.
- Prefer concise status updates over stream-of-consciousness.

# Editing Discipline

- Use dedicated edit/patch tools for localized file changes whenever possible.
- Do not use ad hoc Perl/Python/sed scripts for edits unless:
  - the edit tool cannot express the change cleanly, or
  - the change is mechanical across many files.
- If using a script to edit files, say why it is safer than the edit tool.
- If Dexter says not to fix yet (or only explain / investigate), explain only. Wait for an explicit go-ahead before editing code or tests.
- When removing or changing a service API parameter, grep all call-site families (including naming twins like Cached vs QuickCached), not only sites touched earlier. After rebasing onto master, re-grep — new call sites may still use the old arity.

# Stacked PRs & Cloud Agents

- When fixing the base of a stacked PR, restack and force-push every upper branch before treating the stack as green. Do not leave upper PRs pointing at an old base tip.
- Cloud agents often 403 when requesting GitHub reviewers. Do not loop on review-request API calls. Tell Dexter to set reviewers manually, and ask which reviewers if not already specified.

# Debugging Discipline

- Do not “keep tweaking” tests or internals speculatively.
- Before modifying tests to fix failures, identify whether the failure is from production behavior, test setup, stale fixture/preseed, cache/global state, or mocking.
- If the proposed fix touches global state, ContextVars, request caches, feature flag caches, decorators, or private internals, pause and ask before editing unless explicitly requested.
- Prefer minimal production changes and minimal tests that verify the intended behavior.

# Anti-Spiral / Check-In Policy

When a task starts going off-track, stop and check in instead of continuing to iterate.

Check in before proceeding if any of these happen:
- A focused fix expands into debugging unrelated infrastructure/test setup.
- The same test or command fails more than 2 times after attempted fixes.
- More than 20 minutes pass without clear progress.
- For slow test/debug loops, 10 minutes pass or 2 failed runs occur, whichever comes first.
- You are about to change tests substantially to make them pass.
- You are considering touching internals, caches, global state, decorators, or framework behavior.
- Test failures appear flaky/stateful or differ between single-test and full-file runs.
- The production code fix is simple but validation is becoming complex.

When checking in, provide:
- What changed so far.
- The exact command(s) run and current failures.
- Your best hypothesis.
- 2-3 options, including “stop here / hand off”.
- A recommendation.

Do not keep making speculative edits after hitting a check-in trigger.

# Coding Paradigms

Personal design taste. Apply on every coding task unless Dexter overrides. Prefer these over inventing new structure.

1. **Prefer platform primitives over custom control flow.** Use existing enqueue/dedupe/timeout/status APIs when they already solve the problem. Don’t invent retry/MISSING/re-lookup layers on top.

2. **Simplify leftover design first.** Assume prior iterations left misdirection. Delete intermediate state machines, remappers, and “just in case” branches before adding new structure.

3. **Immutable next-state loops.** For poll/orchestrate/batch flows: build `next_state` from `state` each pass. Don’t mutate in place; don’t encode “next action” enums unless the action is actually part of the loop.

4. **Defer side effects until the decision is final.** Fallback, finalize, and metric emission happen after the wait/loop ends (or at the moment the outcome is known)—not mid-loop via secondary merge passes.

5. **Emit/record inline when the fact is already known.** Don’t collect into a remapping dict just to translate again. If you have `(key, outcome)` at the match site, use it there.

6. **No thin wrappers that re-derive caller context.** If the caller already has the id/key/handle, don’t wrap and look it up again.

7. **Types and unions live at the use site.** Constrain accepted strategies/args on the function that takes them. Don’t invent shared alias types until multiple call sites truly share the contract.

8. **Prefer existing constants/modules over parallel Literals.** Match/dispatch on the real module constants; avoid string/`Literal` duplicates of things already named.

9. **Dispatch nested by early-return discriminant.** Order match arms so the cheapest discriminator short-circuits (e.g. kind → mode → details). Prefer full nested match over `match` + inner `if` when enumeration is intentional; split arms for completeness.

10. **Locals are private by default.** Underscore anything not part of the intentional public surface. Helpers that must stay module-level live next to their consumer, not as a pseudo-API above the class.

11. **Name helpers for the caller’s decision.** Name booleans/sets after what the caller branches on (“completed / readable / should reload”), not internal mythology (“success”, “value available”).

12. **Gate at the control boundary.** Feature flags / pilots belong where behavior is chosen (call site), not buried inside the library that implements the path. Use the flag shape that actually gives the intended control (coarse vs per-target).

13. **Log severity matches control flow.** If you’re not raising, don’t `exception`-log. Prefer `warning`/`info` for handled fallbacks.

14. **No narrative / temporal comments.** Don’t leave comments that restate the code or narrate the change (“was previously…”, “address review feedback”). Prefer clearer structure and names. Use the strip-temporal-comments skill when cleaning a diff.

15. **Confirm design forks before coding.** When a review comment or architectural choice has more than one reading, align on intent in chat before editing.
