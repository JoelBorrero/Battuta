---
description: Autonomous Overnight Runner for Battuta Post-MVP Queue (.ai/NIGHT_QUEUE.md)
---

# `/overnight` — Autonomous 6-Stage Battuta Execution Loop

You are executing the unattended overnight build for **Battuta**. You must process uncompleted tasks (`[ ]`) in `.ai/NIGHT_QUEUE.md` sequentially using the 6-stage lifecycle (`Analyze → Plan → Implement → Test → Review → Fix`) without stopping to ask the user questions.

## Core Invariants (Non-Negotiable)
1. **Follow `AGENTS.md` and `.agents/skills/dev-cycle/SKILL.md`** for every task.
2. **Baseline Safety**: Before starting Task 1, create branch `git checkout -b ai/nightly-2026-11-06` and run `./scripts/overnight_gate.sh` to confirm the 275-test baseline is green.
3. **Zero Blocking Questions**: If an edge case arises, choose the simplest offline-first, pure-Dart option, document the decision in `.ai/MORNING_BRIEFING.md`, and continue.
4. **3-Strike Circuit Breaker**: For any task, if `./scripts/overnight_gate.sh` fails **3 consecutive fix attempts** in Stage 6:
   - Run `git reset --hard HEAD` and `git clean -fd lib/ test/` to restore the last green task checkpoint.
   - Mark the task `[!]` (Halted) in `.ai/NIGHT_QUEUE.md`.
   - Record the failure reason in `.ai/MORNING_BRIEFING.md`.
   - Immediately proceed to the next `[ ]` task in `.ai/NIGHT_QUEUE.md`.

---

## Execution Loop (Repeat for Each `[ ]` Task in `.ai/NIGHT_QUEUE.md`)

### Stage 1 & 2: Analyze & Plan (Write to `.ai/CURRENT_STEP_SPEC.md`)
1. Read ONLY the specific `[ ]` task from `.ai/NIGHT_QUEUE.md` and inspect the directly referenced files in `lib/` and `test/`.
2. Overwrite `.ai/CURRENT_STEP_SPEC.md` (keep under 60 lines) with:
   - Exact files to create/modify.
   - Exact class names, method signatures, and constructors matching Battuta's Feature-First Clean Architecture.
   - UI theme rules if touching presentation (`#121316` dark, `#F8F9FA` light, `#E5A93C` amber, 1px border, >=44pt touch target, zero `RenderFlex` overflow).

### Stage 3 & 4: Implement & Test
1. Implement the domain/data/presentation files defined in `.ai/CURRENT_STEP_SPEC.md`.
2. Write comprehensive unit/widget tests in `test/` covering normal flows and edge cases.
3. Run `./scripts/overnight_gate.sh`.

### Stage 5 & 6: Review, Fix & Checkpoint
1. Audit `git diff` against Battuta invariants:
   - Are there any default Material shadows/elevations or non-compliant colors?
   - Are all streams/controllers properly disposed?
   - Could any Row/Column overflow on narrow constraints?
2. If `./scripts/overnight_gate.sh` or the self-audit fails, apply surgical fixes (up to 3 strikes).
3. **Once `./scripts/overnight_gate.sh` outputs `✅ GATE PASSED`**:
   - Mark the task `[x]` in `.ai/NIGHT_QUEUE.md`.
   - Append a completion entry to `.ai/MORNING_BRIEFING.md` (include test count delta, files touched, and any architectural assumptions made).
   - Commit the green checkpoint:
     ```bash
     git add lib/ test/ .ai/
     git commit -m "feat(nightly): complete [TASK-ID] - [short title]"
     ```
4. Move immediately to the next `[ ]` task in `.ai/NIGHT_QUEUE.md` until all tasks are `[x]` or `[!]`.