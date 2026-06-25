# Project Instructions

Always apply the repo-local `coding-guidelines` skill for work in this project.

Authoritative skill path: `.agents/skills/coding-guidelines/SKILL.md`

## Core Rules

- At session start, read `.agents/skills/coding-guidelines/SKILL.md` and follow it for planning, editing, verification, communication, and recovery.
- Prefer correctness over cleverness, and use the smallest change that solves the problem.
- Follow existing project patterns before introducing new abstractions, dependencies, or broad refactors.
- Read the authoritative source and nearby tests before editing.
- For non-trivial work, create or update `tasks/todo.md` with goal, acceptance criteria, a checklist, working notes, verification steps, and results.
- Keep progress auditable: one active item at a time, and mark items complete as work finishes.
- For bug reports, reproduce the issue, isolate the root cause, fix it, add the smallest useful regression coverage, and verify the original report.
- If tests, builds, or behavior checks fail unexpectedly, stop adding features and return to diagnosis before continuing.
- After any user correction or discovered mistake, update `tasks/lessons.md` with the failure mode, detection signal, and prevention rule.
- Review `tasks/lessons.md` at session start and before major refactors when it exists.
- Final responses should include what changed and the verification story. If something could not be verified, say why and give the safest next step.
