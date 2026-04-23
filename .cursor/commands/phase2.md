# /phase2

Dispatch the Product Designer to produce screen specs and the design brief.

## Pre-flight checks

Before dispatching, confirm:
- [ ] `artifacts/docs/northstar-[app].html` exists
- [ ] `artifacts/docs/emotional-design-system.md` exists
- [ ] `artifacts/docs/screen-specs-[app]-v1.md` does NOT exist (not already run)

If any check fails: report to human, do not dispatch.

## Dispatch

Launch Product Designer subagent with:

```
Task: Phase 2 — Screen Specs + Design Brief

Read:
- .cursor/agents/product-designer.md (your identity and domain)
- .cursor/skills/wireframes/SKILL.md (your full Phase 2 instructions)
- .cursor/rules/copy-rules.mdc (copy formula, screen-context rules, forbidden words — all copy must be production-ready)
- agent-workspace/ACTIVE_CONTEXT.md
- artifacts/docs/northstar-[app].html
- artifacts/docs/emotional-design-system.md

Produce:
1. artifacts/docs/screen-specs-[app]-v1.md — screen metadata for every screen
2. artifacts/docs/design-brief.md — structured input for human to use in the configured design tool (see artifacts/design-tool.config.json + the adapter's SKILL.md)

Follow the Phase 2 skill instructions exactly.
Signal completion by confirming both files are written.
```

## After completion

1. Update `agent-workspace/ACTIVE_CONTEXT.md`
2. Present to human: "Screen specs + design brief complete. Run `/design` to enter the configured design tool with pre-flight checks, export the handoff bundle, then `/design verify` before approving Phase 4."
3. Wait for human to run `/design` → export to `src/design-handoff/` → `/design verify` passes → approval, before dispatching `/phase4`
4. On approval: commit `docs(phase2): screen specs + design brief complete`
