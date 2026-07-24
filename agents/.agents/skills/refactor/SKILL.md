---
name: refactor
description: Find and execute architectural improvements — consolidate scattered utils and queries into well-defined service methods. Use for organic exploration of a module or targeted refactoring of specific code into service classes.
argument-hint: [module path or specific file/function to consolidate]
---

Improve codebase architecture by consolidating scattered logic behind well-defined service methods. Supports two modes:

- **Organic exploration**: Point at a module, surface improvement candidates
- **Targeted refactoring**: You know what needs to move, help design the service interface

## Mode 1: Organic Exploration

Use when: `/refactor app/time_tracking/` or `/refactor` with context about an area to explore.

### 1. Explore for friction

Navigate the target area and note friction points — signals that logic is scattered:

- **Shotgun queries**: The same model is queried in multiple utils/views/tasks with slightly different filters
- **Leaky abstractions**: Callers need to know internal details (which fields to `.only()`, what order to chain filters, which context managers to wrap)
- **Logic duplication**: Similar validation, transformation, or branching logic repeated across files
- **Import sprawl**: A single operation requires importing from 3+ utils files
- **Feature flag checks at callsites**: The same `is_enabled()` check repeated in multiple places instead of being encapsulated in a service method
- **Untyped returns**: Functions returning raw dicts, tuples, or mutated inputs instead of typed dataclasses

### 2. Surface candidates

Present a ranked list of consolidation opportunities. For each candidate:

```
### Candidate: [Domain concern name]
**Scattered across**: [list of files where this logic currently lives]
**Access patterns**: [the queries/operations that should be behind service methods]
**Callers**: [who calls this logic today — views, tasks, ETAs, other services]
**Complexity hidden**: [what callers shouldn't need to know]
**Risk**: Low / Medium / High — based on how many callers and how critical the path is
```

Don't propose interfaces yet — just surface the candidates.

### 3. User selects

Ask the user which candidate to pursue. Then proceed to the design phase (same as Mode 2 below).

## Mode 2: Targeted Refactoring

Use when: `/refactor consolidate payroll queries from time_entry_utils into a service` or you've selected a candidate from Mode 1.

### 1. Map the current state

For the target logic, document:

- **Where it lives today**: Every file, function, and query involved
- **Who calls it**: All callsites (views, tasks, ETAs, other services, tests)
- **What it depends on**: Models, other services, feature flags, context managers
- **What side effects it has**: DB writes, ETA scheduling, metrics, event emission

### 2. Design the service interface

Propose a service class following the codebase's established patterns:

**Structure conventions:**
- Static methods only — no instance state
- One service = one domain concern
- Typed return values (frozen dataclasses for immutable results, TypedDict for config/kwargs)
- Feature flag checks inside service methods, not at callsites
- Observability (metrics, structured logging) built into service methods
- Module-level private helpers for internal logic
- File lives in `domain/` directory of the relevant app

**Propose the public API:**

```python
class [DomainConcern]Service:
    @staticmethod
    def method_name(explicit, params, not_kwargs) -> TypedResult:
        """One-line description of what this does."""
        ...
```

For each method:
- What it replaces (which scattered functions/queries)
- What it hides from callers (complexity that moves inside)
- What the return type is and why

### 3. Classify dependencies

For each dependency the new service will have, classify it:

| Dependency | Category | Strategy |
|---|---|---|
| MongoEngine models | Local-substitutable | Test with real test DB |
| Other domain services | In-process | Call directly |
| ETAs / Temporal | Ports & adapters | Service schedules, test mocks the scheduler |
| External APIs | True external | Mock at service boundary |
| Feature flags | In-process | Use `@mock_feature_flag` in tests |

### 4. Plan the migration

Outline how to move callers to the new service:

- **Additive first**: Create the service with new methods (PR 1)
- **Migrate callers**: Update callsites to use service methods (PR 2+)
- **Remove old code**: Delete the scattered functions once all callers are migrated (final PR)
- **Feature flag**: Only gate behavioral changes that have non-trivial revert risk (DB migrations, schema changes, high-risk rollouts). Safe service-level refactors that are cleanly revertible via PR revert do not need a feature flag.

For each callsite migration, note whether it's mechanical (just change the import/call) or requires logic changes.

### 5. Check with the user

Present the proposed service interface and migration plan. Ask:
- Does the service boundary feel right? Too broad or too narrow?
- Are there callers I missed?
- Should any methods be split or combined?
- Does the migration order make sense?

After agreement, the user can feed the result into `/incremental-feature-stack` for PR breakdown or `/write-spec` for a full spec.

## Anti-patterns to watch for

- **Shallow services**: A service that just wraps a queryset without adding any logic or encapsulation. The service should hide something meaningful.
- **God services**: Cramming unrelated concerns into one service because they touch the same model. One service = one domain concern, not one model.
- **Moving without improving**: If the logic moves from utils to a service but the interface is equally complex, you've just relocated the problem. The service should simplify the caller's life.
- **Breaking the access pattern**: If callers need to combine multiple service methods to do what one util function did, the service interface needs redesign.
