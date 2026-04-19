# /session-end

Close the session — append the end block to today's memory and update project state.

## Steps

1. Append a `## Session end` block to `agent-workspace/memory/[today].md`:
   - Completed: list finished + committed work with commit hashes
   - In progress: what is mid-flight and exact resume point
   - Decisions: spec deviations, architectural calls, human approvals received
   - Next: start here → exact first action for the next session
2. Update `agent-workspace/ACTIVE_CONTEXT.md` — reflect current focus and any workstream status changes
3. Update `artifacts/plans/project-plan.md` — check off any completed phases or features
4. **Studio contribution check** — scan the session for patterns worth promoting:
   - Claude Design wins/losses → append to `artifacts/studio/claude-design-log.md` if observed 2+ times
   - Email subject-line or CTA wins (post-launch sessions only) → `artifacts/studio/email-log.md`
   - Landing conversion wins → `artifacts/studio/landing-log.md`
   - Confirmed anti-patterns → `artifacts/studio/anti-patterns.md`
   - If nothing qualifies, write "No studio contributions this session." in the memory block. Never skip the check.

## Report to human

```
Session closed. Memory written to agent-workspace/memory/[today].md.
Completed: [list]
In progress: [list]
Next session starts with: [first action]
```
