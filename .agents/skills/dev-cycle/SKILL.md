---
name: dev-cycle
description: >-
  Executes the disciplined 6-stage engineering development lifecycle: Analyze,
  Plan, Implement, Test, Review, and Fix. Use when designing features, solving
  bugs, resolving layout overflows, refactoring code, or performing multi-step
  codebase modifications to ensure high quality, zero regressions, and clean
  automated verification.
---

# Autonomous Engineering Development Cycle: Analyze, Plan, Implement, Test, Review & Fix

This skill codifies the disciplined, professional engineering workflow for building, refactoring, and debugging applications. It ensures every change is thoroughly understood, systematically implemented, automatedly tested, and verified before completion.

---

## The 6-Stage Engineering Cycle

```
  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
  │ 1. ANALYZE  │ ────> │   2. PLAN   │ ────> │3. IMPLEMENT │
  └─────────────┘       └─────────────┘       └─────────────┘
                                                     │
                                                     ▼
  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
  │   6. FIX    │ <──── │  5. REVIEW  │ <──── │   4. TEST   │
  └─────────────┘       └─────────────┘       └─────────────┘
         │                                           ▲
         └───────────────────────────────────────────┘
```

---

## Stage 1: Analyze (Deep Context & Root Cause)

**Objective**: Understand the exact problem, constraints, and architecture *before* writing or modifying code.

### Guidelines & Actions:
1. **Clarify Intent & Requirements**:
   - Deconstruct the user's prompt into functional requirements, constraints, and visual expectations.
   - If requirements are ambiguous, clarify them early or make sound, standard engineering choices aligned with project conventions.
2. **Inspect Errors & Stack Traces**:
   - If an error or layout overflow occurred (e.g., `RenderFlex overflowed by X pixels` at `path/file.dart:line:col`), read the exact file and lines immediately.
   - Inspect parent constraints (`BoxConstraints`, `UnconstrainedBox`, `Row`, `Column`, `ListView`) to locate why the layout exceeded its available space.
3. **Audit Existing Architecture**:
   - Identify existing domain models, providers/notifiers, repositories, and UI widgets before designing new components.
   - Maintain Clean Architecture separation:
     - **Domain**: Pure business entities, enums, value objects, mathematical calculators (zero UI/Flutter dependencies).
     - **Data / Providers**: State management (Riverpod/BLoC), repositories, serialization, offline caching.
     - **Presentation**: Pages, widgets, custom painters, sheets, dialogs.
4. **Identify Project Invariants**:
   - **Offline-First**: Ensure features work completely offline without mandatory external cloud calls.
   - **Apple/Stage-Ready Aesthetic**: Follow high-contrast, anti-material design (pearl/slate light mode, deep obsidian dark mode, gold/amber `#E5A93C` accent, flat surfaces, subtle borders, no default Material dropshadows or ripple splash).
   - **Responsiveness**: Support iPadOS, macOS, and narrow screen dimensions cleanly without rendering overflow.

---

## Stage 2: Plan (Intentional Design & Strategy)

**Objective**: Formulate an actionable, modular roadmap before executing changes.

### Guidelines & Actions:
1. **Draft Implementation Steps**:
   - Organize tasks sequentially:
     1. Domain layer (entities, enums, pure helper logic)
     2. Provider / State layer (state notifiers, mutations, reactive queries)
     3. Presentation layer (UI components, dialogs, responsive styling)
     4. Automated Tests (unit tests, widget tests, regression tests)
2. **Anticipate Edge Cases**:
   - Month/year boundaries, leap years, daylight savings for calendar logic.
   - Empty collections, null values, rapid successive user inputs.
   - Extreme screen widths (narrow mobile screens vs. 12.9" iPad Pro / macOS).
3. **Track Progress with a Checklist**:
   - Use an explicit task list to communicate progress to the user and keep track of completed versus remaining items.

---

## Stage 3: Implement (Surgical & Idiomatic Execution)

**Objective**: Execute changes with high precision, maintaining code quality and system integrity.

### Guidelines & Actions:
1. **Surgical File Edits**:
   - Use targeted edit tools (`edit_file` / `write_file`).
   - Avoid rewriting entire files when changing specific methods or widgets.
2. **Preserve Documentation & Code Integrity**:
   - Preserve all existing comments, docstrings, and unrelated functionality unless explicitly requested.
3. **Idiomatic Dart 3 & Flutter Standards**:
   - Use pattern matching, switch expressions, sealed classes, and records where appropriate.
   - Use `const` constructors where applicable to optimize widget rebuilds.
   - Use custom `Container` decorations, `RoundedRectangleBorder`, and clean dividers instead of standard Material elevation.
4. **Prevent Layout Overflows**:
   - Wrap unbounded flex children in `Expanded` or `Flexible`.
   - Use `Wrap` with `runSpacing` for dynamic chip/button rows.
   - Provide `SingleChildScrollView` inside dialogs or bottom sheets that contain forms or dynamic lists.

---

## Stage 4: Test (Automated Multi-Layer Verification)

**Objective**: Verify correctness through automated CLI test execution.

### Verification Sequence:
1. **Targeted Unit / Widget Tests**:
   - Run tests specifically covering the modified feature first:
     ```bash
     flutter test test/features/<feature>/
     ```
   - Ensure the new functionality is verified and existing behavior remains intact.
2. **Static Code Analysis**:
   - Run static analysis across the entire project:
     ```bash
     flutter analyze
     ```
   - Guarantee **0 issues found** (zero errors, zero warnings, zero lints).
3. **Full Project Regression Test Suite**:
   - Run the complete project test suite:
     ```bash
     flutter test
     ```
   - Guarantee **100% test pass rate** across all suites.

---

## Stage 5: Review (Inspection & Quality Gate)

**Objective**: Perform a comprehensive code and UX audit before declaring work complete.

### Audit Checklist:
- [ ] **Git Diff Inspection**: Run `git status` and `git diff` to ensure only intended files were modified and no temporary files, debug prints, or unused imports were left behind.
- [ ] **Requirement Check**: Re-read the user's initial prompt and verify that every single item and sub-requirement has been addressed.
- [ ] **Aesthetic & UX Polish**:
  - Light mode & Dark mode contrast verified.
  - Proper touch target sizes ($\ge 44 \times 44$ pt).
  - No striped yellow/black RenderFlex overflow bars.
- [ ] **Offline-First Validation**: Verify no unintended network dependencies were introduced.

---

## Stage 6: Fix (Closed-Loop Remediation)

**Objective**: Systematically resolve any discrepancies discovered in Stage 4 or Stage 5.

### Remediation Protocol:
1. **Never Guess or Ignore Failures**:
   - If a test fails or `flutter analyze` reports an issue, read the exact log and failure description.
   - Pinpoint the exact line and assertion mismatch.
2. **Apply Focused Fix**:
   - Adjust the underlying calculation, state transition, or layout widget constraint.
3. **Re-Test Immediately**:
   - Re-run Stage 4 (Targeted Test $\rightarrow$ `flutter analyze` $\rightarrow$ `flutter test`).
4. **Repeat the Loop**:
   - Continue until the entire test suite passes cleanly with 0 analysis issues.

---

## Stage 7: Checkpoint & Git Delivery

**Objective**: Create a clean, reproducible Git history and concise delivery summary.

### Standard Git Workflow:
```bash
git status
git add lib/ test/
git commit -m "<type>(<scope>): <concise description>"
git push origin <branch>
```

### Commit Types:
- `feat`: New feature or user capability
- `fix`: Bug fix or layout overflow resolution
- `refactor`: Code reorganization without behavioral changes
- `test`: Adding or updating test suites
- `style`: Visual styling, theme updates, UI polish

### Response Format to User:
- Provide a concise summary of the implementation.
- Include clickable markdown links (`file:///...`) to all modified and newly created files.
- Report the test results (e.g. `275/275 tests passed`, `flutter analyze: 0 issues`).
