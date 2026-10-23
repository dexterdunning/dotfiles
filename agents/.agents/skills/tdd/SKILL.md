---
name: tdd
description: Test-driven development adapted to this codebase's patterns. Red-green-refactor with composable primitives, feature-flag gating, and parity testing. Use when building features or refactoring with a test-first approach.
argument-hint: [feature or behavior to implement]
---

# Test-Driven Development

If `~/.agents/skill-overrides/tdd/instructions.md` exists, read it for local test runners, flag configuration, and mock helpers. Otherwise use the workflow below with repository-provided equivalents. Local supplements do not override repository policy or safety requirements.

Build features and refactors test-first, using this codebase's patterns for decomposition, safety, and verification.

## Philosophy

**Test behavior, not implementation.** A good test describes what the system does from the caller's perspective. It survives internal refactors because it doesn't care about the internal structure — only the observable outcome (field state, return values, metrics emitted, side effects triggered).

**Mock at system boundaries only.** Mock external APIs, third-party services, and infrastructure (time, randomness). Don't mock your own classes or internal collaborators — let the real code run. When a dependency is hard to test against, that's a signal to improve the interface, not to add a mock.

**Deep modules over shallow modules.** A deep module hides significant complexity behind a small, stable interface. When decomposing, ask:
- Can the number of methods/params be reduced?
- Can more complexity be hidden internally?
- Is this interface testable without knowing the implementation?

A few composable primitives with clear contracts beat many fine-grained functions that leak implementation details.

## Workflow

### 1. Design the interface

Before writing any code, figure out the public contract:

- What are the inputs and outputs?
- What are the composable primitives? (e.g., `check_staleness`, `compute_field_value`, `persist_to_deferred_fields` — each independently callable, composable into higher-level operations)
- What return types make the contract explicit? Prefer dataclasses or typed results over raw tuples/dicts.
- Where do feature flags gate the new path? (Only needed if the change has non-trivial revert risk — skip for safe refactors.)

Check with the user: "Here's the interface I'm proposing. Does this match your expectations?"

### 2. Red-Green loop

Work in vertical slices — one test, one implementation, repeat.

```
RED:   Write a test for the first behavior → test fails
GREEN: Write minimal code to make it pass → test passes
       Repeat for each behavior
```

**Rules:**
- One test at a time. Each test responds to what you learned from the last cycle.
- Only write enough code to pass the current test. Don't anticipate future tests.
- If you're refactoring existing code, the first test should be a **parity test**: assert the new path produces identical results to the old path under the same inputs.

**What to test at each level:**
- **Primitives**: Test each composable primitive in isolation. Input → output, no side effects to verify.
- **Composition**: Test the composed operation end-to-end. Set up real state, run the operation, assert on observable outcomes.
- **Parity**: When introducing a V2 path alongside V1, test that both produce identical results (field state, metrics, side effects).

### 3. Refactor

After tests are green, refactor. In this codebase, refactoring often means:

- **Extract composable primitives** from monolithic functions. Each primitive should be a static method or standalone function with a clear contract.
- **Introduce a feature-flagged V2 path** only when the change has non-trivial revert risk (e.g., behavioral changes that can't be cleanly reverted by reverting the PR). For safe refactors with low revert risk, skip the feature flag and ship the V2 path directly.
- **Expand-contract for interface changes**: add the new parameter as optional with a fallback (PR 1), thread it through all callers (PR 2), make it required and remove the fallback (PR 3).

Never refactor while RED. Get to GREEN first, then restructure.

### 4. Verify

Before considering the work done:

- [ ] All new code is exercised by tests (feature flag defaulted to `true` in test config)
- [ ] Parity tests pass if this is a refactor (V1 vs V2 equivalence)
- [ ] Tests describe behavior in their names ("user can X", "returns Y when Z"), not implementation ("calls function A")
- [ ] No mocks of internal collaborators — only system boundaries
- [ ] Each test would survive an internal refactor without changes

## Patterns from this codebase

### Decomposition into composable primitives

When an existing function is too large or does too many things, extract the steps into independently callable primitives:

```python
# Before: monolithic ~80-line function
def _getValueForField(self, ...):
    # staleness check, compute, persist all inline

# After: composable primitives
def check_staleness(...) -> bool: ...
def compute_field_value(...) -> ComputeResult: ...
def persist_to_deferred_fields(...) -> None: ...

# V2 composes them
def _getValueForFieldV2(self, ...):
    if not check_staleness(...):
        return cached_value
    result = compute_field_value(...)
    persist_to_deferred_fields(result, ...)
    return result.new_field
```

### Feature-flag gated V2

Gate the new path so it can be enabled incrementally:

```python
def _getValueForField(self, ...):
    if is_enabled("field-engine-v2", company):
        return self._getValueForFieldV2(...)
    # original V1 logic untouched
```

Configure the repository's test feature flags so CI exercises V2; use the local supplement for any repository-specific flag-default file.

### Parity testing

Assert old and new paths produce identical outcomes:

```python
def test_v1_v2_recompute_parity(self):
    # Setup: create documents with deferred fields

    # Run V1 (flag off)
    with mock_feature_flag("flag", False):
        v1_state = run_and_capture_state()

    # Reset, run V2 (flag on)
    with mock_feature_flag("flag", True):
        v2_state = run_and_capture_state()

    # Assert equivalence
    assert v1_state.deferred_fields == v2_state.deferred_fields
    assert v1_state.metrics == v2_state.metrics
```

### Expand-contract for interface changes

When changing a function signature that has callers deployed on different versions:

1. **Expand**: Add the new parameter as optional with a backward-compatible fallback
2. **Thread**: Update all callers to pass the new parameter
3. **Contract**: Make the parameter required, remove the fallback

Each step is a separate PR with its own deploy order.

## Checklist per cycle

```
[ ] Test written before implementation
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Implementation is minimal for this test
[ ] No speculative features added
[ ] Test would survive an internal refactor
```
