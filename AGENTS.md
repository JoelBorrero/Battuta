# Battuta Autonomous Engineering Standards

All agentic pair programming work in this repository must strictly adhere to the **6-Stage Engineering Development Cycle**:

## 1. Operating Lifecycle: Analyze → Plan → Implement → Test → Review → Fix

Every task, whether adding a new feature, fixing a bug, resolving a layout overflow, or refactoring existing logic, must follow these steps:

1. **ANALYZE**:
   - Inspect the codebase, read relevant files, and understand the existing architecture before writing or modifying code.
   - For bug reports or layout errors (e.g. `RenderFlex overflowed by X pixels`), locate the exact file, line number, and constraint hierarchy.
   - Respect project invariants (offline-first, Clean Architecture, Apple/stage-ready design).

2. **PLAN**:
   - Formulate a clear, structured sequence: Domain entities/pure logic → State providers/notifiers → Presentation widgets → Automated tests.
   - Anticipate boundary cases, edge dates (e.g., month/year rollovers), empty states, and responsive layout constraints.

3. **IMPLEMENT**:
   - Make precise, surgical modifications using `edit_file` / `write_file`.
   - Preserve documentation integrity (comments, docstrings, and unrelated working code).
   - Follow idiomatic Dart 3 standards (pattern matching, switch expressions, records, const constructors).

4. **TEST**:
   - Always verify changes with automated tests:
     - Run targeted feature tests: `flutter test test/features/<feature>/`
     - Run static analysis: `flutter analyze` (must yield **0 issues found**)
     - Run full test suite: `flutter test` (must achieve **100% pass rate**)

5. **REVIEW**:
   - Inspect `git status` and `git diff` to confirm no unwanted changes, debug print logs, or temporary files remain.
   - Validate UX polish: verify responsiveness, touch targets ($\ge 44 \times 44$), color contrast, and zero layout overflows.

6. **FIX**:
   - If any test fails, analysis flags a warning, or review catches a defect, diagnose the exact failure log immediately.
   - Apply a targeted fix and re-run the test suite until everything is completely clean. Never skip or suppress failures.

---

## 2. Core Architectural & Design Invariants

- **Offline-First**: All core music reading, setlists, band calendar, and OMR functionality must work locally without external server dependencies.
- **Visual Aesthetic (Anti-Material)**:
  - High-contrast, stage-ready design tailored for iPadOS and macOS.
  - Light mode: Pearl background (`#F8F9FA`), pure white cards (`#FFFFFF`) with 1px border (`#E1E4E8`), charcoal slate text (`#1A1C20`).
  - Dark mode: Deep obsidian background (`#121316`), elevated obsidian cards with 1px borders, crisp off-white text.
  - Primary Accent: Stage amber/gold (`#E5A93C`).
  - Flush surfaces, no default Material elevations/drop shadows, no ripple ink splash effects.
- **Responsive Layouts**:
  - Always wrap flexible row/column children in `Expanded`, `Flexible`, or `Wrap` with `runSpacing` to avoid RenderFlex overflows across different iPad and desktop window dimensions.
- **Git Commits**:
  - Use Conventional Commits (`feat(...)`, `fix(...)`, `refactor(...)`, `test(...)`, `style(...)`).

