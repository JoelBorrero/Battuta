# Battuta Pipeline: Plan → Implement → Adversarial Review

Claude-only, sequential. The main session is the **Planner/Triager**; the `implementer` and `adversary`
subagents (see `.claude/agents/`) run one at a time and communicate only through files in
`.pipeline/<NNN-slug>/`.

## Flow

1. **Plan** (main session): write `01-plan.md` from `templates/01-plan.md`. Record `base_sha`. User approves.
2. **Implement** (`implementer` agent): reads `01-plan.md` + `AGENTS.md` only. Writes code/tests and `02-impl-report.md`. Does NOT commit.
3. **Review** (`adversary` agent): reads plan + `git diff <base_sha>`, runs `flutter analyze` / `flutter test` itself. Writes `03-review.md` with verdict (overwritten each round).
4. **Triage** (main session): accept / reject / defer each finding in `04-triage.md`.
   - `APPROVE` or no accepted blockers/majors → go to step 5.
   - Otherwise → short fix plan appended to `04-triage.md`, back to step 2 (round + 1).
5. **Close** (main session): write `summaries/<NNN-slug>.md` from `templates/summary.md`, delete the task
   folder `<NNN-slug>/`, add every deferred finding to `backlog.md`, then make one Conventional Commit with
   the code, the summary and the backlog.

## The task record

Working files (`<NNN-slug>/01-plan.md` … `04-triage.md`) exist only while a task runs; they are how the agents
hand work to each other. The only file kept per task is `summaries/<NNN-slug>.md`, which describes the **final state**: what changed,
what was already correct, decisions taken and what was deferred. It never retells rounds: if review moved the
change from A to B, the summary only describes B.

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
- Track rounds and rough effort in `04-triage.md` while running (use `/usage` in the app); copy the
  rounds used into the summary front matter when closing.
