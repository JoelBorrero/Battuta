# Battuta Pipeline: Plan → Implement → Adversarial Review

Claude-only, sequential. The main session is the **Planner/Triager**; the `implementer` and `adversary`
subagents (see `.claude/agents/`) run one at a time and communicate only through files in
`.pipeline/<NNN-slug>/`.

## Flow

1. **Plan** (main session): write `01-plan.md` from `templates/01-plan.md`. Record `base_sha`. User approves.
2. **Implement** (`implementer` agent): reads `01-plan.md` + `AGENTS.md` only. Writes code/tests and `02-impl-report.md`. Does NOT commit.
3. **Review** (`adversary` agent): reads plan + `git diff <base_sha>`, runs `flutter analyze` / `flutter test` itself. Writes `03-review.md` with verdict.
4. **Triage** (main session): accept / reject / defer each finding in `04-triage.md`.
   - `APPROVE` or no accepted blockers/majors → one Conventional Commit, done.
   - Otherwise → short fix plan appended to `04-triage.md`, back to step 2 (round + 1).

## Rules

- Max **3 rounds**. Still blocked after round 3 → stop and escalate to the user (the plan was probably wrong).
- Only **blocker** and **major** findings block. Minor/nit never trigger another round.
- Every finding needs `file:line` + a concrete failing scenario, or it is downgraded to nit.
- The adversary never edits code. The implementer never expands scope beyond the plan; deviations go in the impl report.
- No branches/worktrees (see `AGENTS.md`); `base_sha` is the review baseline.

## Quota discipline

- Plans are short: acceptance criteria and file list, not essays.
- Implementer runs on Sonnet; adversary on Sonnet (switch to a stronger model only for risky changes).
- Skip the full pipeline for trivial changes (typos, one-line fixes): just do them.
- Each task folder has a `Usage` line in `04-triage.md`: record rounds and rough effort
  (use `/usage` in the app) so you can see what a pipeline run actually costs.
