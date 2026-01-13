# Agent Instructions

## Context

You are running in the root of the project.
The configuration files for this agent loop are located in the `scripts/ralph-loop/` directory.

## Your Task

1. Read `scripts/ralph-loop/prd.json`
2. Read `scripts/ralph-loop/progress.txt` (check Codebase Patterns first)
3. Check you're on the correct branch (create if needed, checkout if exists)
4. Pick highest priority story where `passes: false`
5. Implement that ONE story in the project root (`.`), NOT inside `scripts/ralph-loop/`
6. Run typecheck and tests (if applicable for the language)
7. Commit: `feat: [ID] - [Title]`
8. Update `scripts/ralph-loop/prd.json`: Set `passes: true` for the completed story
9. Append learnings to `scripts/ralph-loop/progress.txt`

## Progress Format

APPEND to `scripts/ralph-loop/progress.txt`:

```
## [Date] - [Story ID]
- What was implemented
- Files changed
- **Learnings:**
  - Patterns discovered
  - Gotchas encountered
---
```

## Codebase Patterns

Add reusable patterns to the TOP of `scripts/ralph-loop/progress.txt`:

```
## Codebase Patterns
- Example: Migrations use IF NOT EXISTS
- Example: React useRef<Timeout | null>(null)
```

## Git Operations
- Perform `git commit` and `git push` once a logical unit of modification is completed
- Commit message format: `feat: [ID] - [Title]`

## Stop Condition

If ALL stories pass (check `scripts/ralph-loop/prd.json` first), reply with EXACTLY:
<promise>COMPLETE</promise>

Otherwise end your turn normally after committing and updating the tracking files.
