# OMP preferences

Use native OMP task/wait/todo, grep/glob/read/edit, and agent history tools. Shared skills describe intent; translate harness-specific operations to the available OMP tools and report missing capabilities rather than inventing them.

## Delegation and cost

- Delegate bounded, independently useful work only. Do small inspections and aggregations directly.
- Use at most two workers concurrently and no nested worker delegation. Request medium worker reasoning; ask before changing model policy.
- Give each worker explicit write boundaries, acceptance criteria, and a compact result schema covering findings, changed files, validation, blockers, and next action.
- Target a checkpoint within 10 minutes. The hard worker limit is 30 minutes; the request-budget notice starts at 40 requests and forced stop at 60. Do not assign a task that requires exceeding these limits.
- Inspect saved output before resuming. At a genuine phase boundary, use a compact evidence-based handoff rather than preserving an unrelated investigation. Do not redo the worker's investigation in the parent.
- Context maintenance starts at 180k tokens, below the observed 272k gateway pricing cliff. This is not a billing cap and a large single tool response can overshoot it.
- Use focused native reads/searches. Redirect verbose commands and tests to log files, then inspect bounded summaries. Do not dump full test logs, broad repository searches, model catalogs, or auth-bearing command lines into context.
- Use native background completion/wait instead of repeated sleep/status polling. Report partial results and blockers before running out of budget.

## Compatibility and safety

- Shared personal guidance is loaded from AGENTS.md. Follow root and nearest repository guidance as usual.
- Do not assume another harness's tools, packages, browser sessions, or authentication are available.
- Do not attach to a user's browser without permission.
