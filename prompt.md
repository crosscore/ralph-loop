# Agent Instructions

## Context

You are running in the root of the project.
The configuration files for this agent loop are located in the `ralph-loop/` directory.

## Your Task

### Step 0: Check for instruction.md (Natural Language Instructions)

1. Check if `ralph-loop/instruction.md` exists
2. If it exists AND `ralph-loop/prd.json` only contains the example placeholder (US-001 with "Example Story"):
   - Read `ralph-loop/instruction.md`
   - Parse the natural language instructions and convert them into user stories
   - Update `ralph-loop/prd.json` with the generated user stories
   - Set appropriate `branchName` based on the task description
   - Set `passes: false` for all new stories
   - Assign incrementing priorities (1, 2, 3, ...)
3. If `ralph-loop/prd.json` already has real user stories (not the example), skip this step

### Step 1-9: Main Task Loop

1. Read `ralph-loop/prd.json`
2. Read `ralph-loop/progress.txt` (check Codebase Patterns first)
3. Check you're on the correct branch (create if needed, checkout if exists)
4. Pick highest priority story where `passes: false`
5. Implement that ONE story in the project root (`.`), NOT inside `ralph-loop/`
6. Run typecheck and tests (if applicable for the language)
7. Commit: `feat: [ID] - [Title]`
8. Update `ralph-loop/prd.json`: Set `passes: true` for the completed story
9. Append learnings to `ralph-loop/progress.txt`

## Progress Format

APPEND to `ralph-loop/progress.txt`:

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

Add reusable patterns to the TOP of `ralph-loop/progress.txt`:

```
## Codebase Patterns
- Example: Migrations use IF NOT EXISTS
- Example: React useRef<Timeout | null>(null)
```

## Git Operations
- Perform `git commit` and `git push` once a logical unit of modification is completed
- Commit message format: `feat: [ID] - [Title]`

## Stop Condition

If ALL stories pass (check `ralph-loop/prd.json` first), reply with EXACTLY:
<promise>COMPLETE</promise>

Otherwise end your turn normally after committing and updating the tracking files.
