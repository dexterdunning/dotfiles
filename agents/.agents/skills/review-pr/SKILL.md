---
name: review-pr
description: Review a PR against architectural and code quality standards. Produces actionable feedback on structure, decomposition, testing, and patterns. Use when reviewing someone else's PR or checking your own before requesting review.
argument-hint: [PR number, URL, or branch name]
---

Review a pull request against this codebase's architectural standards and produce specific, actionable feedback.

## 1. Load the PR

$ARGUMENTS

If a PR number or URL was provided, fetch it with `gh pr view <number>` and `gh pr diff <number>`. If a branch name was given, diff against the base branch. If nothing was provided, check if the current branch has an open PR.

Read the PR description to understand the stated intent. Then read the full diff.

## 2. Understand the change

Before critiquing, understand what the PR is trying to do:

- What problem does it solve?
- What's the scope of the change?
- Is this a refactor, feature, bug fix, or cleanup?

Explore the surrounding codebase to understand the context the author was working in. Don't review in a vacuum — understand the constraints.

## 3. Review against standards

Evaluate the PR across these dimensions. Only flag issues that are actually present — don't force-fit every category.

### Architecture & Decomposition

- **Service consolidation**: Is new query/business logic going into utils or scattered across files when it should be behind a service method? Look for logic that belongs in `domain/` service classes.
- **Interface quality**: Are service methods using typed return values (dataclasses, TypedDict) or returning raw dicts/tuples? Are parameters explicit or buried in `**kwargs`?
- **Single responsibility**: Does each new class/service cover one domain concern, or is it becoming a grab-bag?
- **Deep over shallow**: Is the new abstraction hiding meaningful complexity, or is it a thin wrapper that doesn't simplify the caller's life?

### Safety & Rollout

- **Feature flag gating**: Only flag missing feature flags when the change has non-trivial revert risk (DB migrations, schema changes, high-risk behavioral rollouts). Do NOT flag PRs that are safely revertible via PR revert — a feature flag is not needed there.
- **Expand-contract**: For interface changes, is the migration safe across deploy windows? New params should be optional with fallbacks before callers are updated.
- **ETA compatibility**: Are ETA signature changes backward-compatible? (Adding params, even kwargs with defaults, can break during deployment windows.)
- **Rollback story**: Can this be reverted cleanly? If not, is there a roll-forward plan?

### Testing

- **Behavior over implementation**: Do tests verify observable outcomes, or are they coupled to internal function calls and mock assertions?
- **Parity testing**: For refactors with V1/V2 paths, are there tests asserting equivalence?
- **Mocking discipline**: Are mocks limited to system boundaries, or are internal collaborators being mocked?
- **Coverage of the new path**: If a feature flag was added, is it defaulted to `true` in test config so CI exercises the new code?

### Code Quality

- **Composable primitives**: Are large functions broken into independently callable steps, or is everything inline in one monolith?
- **Observability**: Are new code paths instrumented with metrics, structured logging, or access tracking where appropriate?
- **Import hygiene**: Are imports at the top of the file? Dynamic imports only for circular dependency avoidance?
- **Naming**: Do function names describe what they do from the caller's perspective, not how they do it?

### What NOT to flag

- Style nitpicks that a linter would catch (formatting, import ordering)
- Minor naming preferences that don't affect clarity
- "I would have done it differently" without a concrete improvement
- Missing docstrings or type annotations on code that wasn't changed in this PR

## 4. Produce the review

Organize feedback by severity:

### Must fix
Issues that would cause bugs, data corruption, deploy failures, or significant maintenance burden. These block merge.

### Should fix
Architectural improvements that make the code meaningfully better — consolidation opportunities, missing feature flags, test gaps. These are worth addressing before merge but aren't blockers.

### Consider
Suggestions for improvement that the author can take or leave. Alternative approaches, potential future simplifications, patterns to be aware of.

### What's good
Call out things the PR does well. Specific, not generic — "Good use of parity testing between V1/V2" not "looks good overall."

For each piece of feedback:
- **Quote the specific code** (file and line range)
- **Explain why** it's an issue, not just what to change
- **Suggest a concrete fix** — show what the improved code would look like, or reference a pattern from the codebase

## 5. Present and optionally post

Present the review to the user. Ask if they want to:
- Post comments directly to the PR via `gh pr review`
- Adjust any feedback before posting
- Skip posting and just use the review as notes

When posting, use `gh pr review <number> --comment --body "..."` for general feedback, or individual line comments where the GitHub API supports it.
