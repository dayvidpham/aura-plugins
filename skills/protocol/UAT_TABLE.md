---
references:
  followup_epic: aura-plugins-2tj
  original_urd: aura-plugins-umi
  original_request: aura-plugins-bj1
  code_review_round: aura-plugins-e0j
---

## Questions and Responses

### Round 1, Q1: Theme Scope (multiSelect)

**Q:** Which follow-up themes should be IN SCOPE for this follow-up epic? (The 11 IMPORTANT findings deduplicate to 4
themes below)

| # | Option | Description |
|---|--------|-------------|
| Q1.1 | Error handling (Recommended) | Bare except Exception in workflow.run() swallows TransitionError silently + bare
except in mutation test. 3 findings across all 3 reviewers. Highest consensus — clear correctness gap. |
| Q1.2 | Constraint completeness | check_all() only aggregates 5 of 22 C-* constraints + check_severity_tree() missing
positive case. 4 findings. Architectural gap in constraint enforcement surface. |
| Q1.3 | Type safety hardening | EpochState.current_role is str instead of RoleId + TYPE_CHECKING Protocol docs. 3
findings. Breaks the strongly-typed enum invariant established everywhere else. |
| Q1.4 | Temporal integration testing | No WorkflowEnvironment sandbox test + timestamp coupling. 2 findings. AC6/AC7
currently tested via state machine only, not actual Temporal signal delivery. |

**A:** ALL FOUR THEMES: Error handling, Constraint completeness, Type safety hardening, Temporal integration testing.

---

### Round 1, Q2: MINOR Finding Scope (singleSelect)

**Q:** Should the 8+ MINOR findings (test helpers, dict typing, field naming, etc.) be included in this follow-up or
deferred?

| # | Option | Description |
|---|--------|-------------|
| Q2.1 | Bundle with IMPORTANT | Address MINOR findings alongside their IMPORTANT siblings in the same slices — less
overhead, one pass. |
| Q2.2 | Defer to later | Keep MINOR severity groups open but do not plan work for them now. Address opportunistically or
 in a future pass. |
| Q2.3 | Close as won't-fix | Close MINOR severity groups — these are polish items that do not affect correctness or
architecture. |

**A:** Bundle with IMPORTANT. Address MINOR findings alongside their IMPORTANT siblings in the same slices — less
overhead, one pass.

---

### Round 1, Q3: Constraint Coverage Target (singleSelect)

**Q:** For constraint completeness: check_all() only covers 5/22 constraints. What coverage target do you want?

| # | Option | Description |
|---|--------|-------------|
| Q3.1 | All 22 C-* constraints | Full coverage — check_all() aggregates every constraint defined in schema.xml. Most
thorough but largest scope. |
| Q3.2 | Transition-relevant subset | Only add constraints that are checkable against EpochState at transition time. Some
 C-* constraints are documentation-level and may not map to runtime checks. |
| Q3.3 | Keep 5, document gap | Keep current 5 methods, add docstring/comment explaining which constraints are not
runtime-checkable and why. Smallest scope. |

**A:** All 22 C-* constraints. Full coverage — check_all() aggregates every constraint defined in schema.xml.

---

### Round 1, Q4: Catch-All (multiSelect)

**Q:** Anything else about the follow-up scope, constraints, or priorities?

| # | Option | Description |
|---|--------|-------------|
| Q4.1 | Must not break 475 tests | All changes must be backwards-compatible with existing test suite. |
| Q4.2 | Minimize new dependencies | No new pip packages — only stdlib + existing deps (temporalio, pytest). |
| Q4.3 | Nothing else | Covered everything above. |

**A:** Must not break 475 tests + Minimize new dependencies. No new pip packages — only stdlib + existing deps
(temporalio, pytest)
