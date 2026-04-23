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
   - Design tool wins/losses → append to `artifacts/studio/design-tool-log.md` if observed 2+ times
   - Email subject-line or CTA wins (post-launch sessions only) → `artifacts/studio/email-log.md`
   - Landing conversion wins → `artifacts/studio/landing-log.md`
   - Confirmed anti-patterns → `artifacts/studio/anti-patterns.md`
   - If nothing qualifies, write "No studio contributions this session." in the memory block. Never skip the check.
5. **If a design tool session ran today**, the Product Designer (or whoever drove it) must have appended a per-app entry to `artifacts/docs/design-tool-log.md` with the required header block — `prompts_consumed: [N]`, `tool_version: [version|date|unknown]`, `shape_mismatch: [yes|no]` (H1 + H4). Do not close the session without this entry. If the entry is missing, prompt the human to add it before continuing.
6. **Design tool rollup** (H1 + H4 — runs every session, regardless of whether the design tool was used today; applies to any adapter implementing H1/H4 gates — today that's the `claude-design-adapter`):
   ```bash
   bash .cursor/skills/design-adapters/claude-design-adapter/scripts/rollup-prompt-budget.sh
   ```
   Include the rollup output in the session-end report:
   - Status `OK` → no action.
   - Status `WARN` (≥ 40 prompts in last 30 days) → flag in the report so the next session knows to plan for fewer/bigger briefs.
   - Status `BLOCK` for budget (≥ 50 prompts) → flag prominently; `/design` will refuse new runs until the window rolls or the Tech Lead overrides.
   - Status `BLOCK` for drift (≥ 3 consecutive `shape_mismatch: yes`) → open `artifacts/issues/handoff-contract-v3.md` immediately and assign the Tech Lead. The handoff contract has likely fallen out of date with the design tool's actual output.

## Report to human

```
Session closed. Memory written to agent-workspace/memory/[today].md.
Completed: [list]
In progress: [list]
Next session starts with: [first action]

Design tool rollup (last 30 days): [status from Step 6]
  prompts_consumed: [N] / 50 (warn at 40)
  shape_mismatch streak: [N] / 3
[If WARN/BLOCK: include the script's recommendation block verbatim]
```
