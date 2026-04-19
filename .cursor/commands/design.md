## /design

Wrapper for the human-driven Claude Design step. Runs pre-flight on the brief, points the human at the right skill file, and validates the handoff bundle after export. Not an agent dispatch — this command is a checklist with scripted checks.

Usage: `/design` (initial build) · `/design new-feature [name]` · `/design regen [screen]`

---

## Mode A — Initial Build (after `/phase2`)

### Pre-flight

Confirm, then report any misses to the human:

- [ ] `artifacts/docs/claude-design-brief.md` exists and is not empty
- [ ] `artifacts/docs/screen-specs-[app]-v1.md` exists
- [ ] `artifacts/docs/northstar-[app].html` exists
- [ ] `src/design-handoff/` does NOT yet exist (or is empty)
- [ ] Human has access to Claude Design (Pro/Max/Team/Enterprise plan)

### Instructions to the human

Present:

```
Run Claude Design now.

1. Open Claude Design.
2. Paste artifacts/docs/claude-design-brief.md verbatim into the prompt.
3. Add the three-line initial-build prompt from .cursor/skills/claude-design/SKILL.md §1.
4. Iterate until every screen in the brief is rendered and the handoff exports cleanly.
5. Export the handoff bundle into src/design-handoff/.

When done, run /design verify to validate the export against artifacts/docs/handoff-contract.md.
```

### Post-flight — `/design verify`

Run the contract check:

- [ ] `src/design-handoff/App.tsx` or `src/design-handoff/routes.tsx` exists
- [ ] `src/design-handoff/theme.css` exists
- [ ] `src/design-handoff/components/ui/` directory exists with ≥ 5 primitives
- [ ] No `globals.css`, no `app/` (Next.js), no `page.tsx` files
- [ ] Every screen listed in `screen-specs-[app]-v1.md` has a matching file in the handoff

Report file-by-file. On any miss, point the human at the relevant fix in `.cursor/skills/claude-design/SKILL.md` §Failure Modes. On all-pass, record:

```
Append to artifacts/docs/claude-design-log.md — initial-build entry per SKILL.md §Logging Usage.
```

Then: "Handoff verified. Proceed to `/phase4`."

---

## Mode B — `/design new-feature [name]`

### Pre-flight

- [ ] `artifacts/docs/features/[name].md` exists with an approved Frontend Scope
- [ ] `src/design-handoff/new-feature-[name]/` does NOT yet exist
- [ ] Initial `src/design-handoff/` has already been consumed (components in `src/components/ui/`)

### Instructions to the human

```
Open Claude Design, then:

1. Point it at the repo (upload src/components/ui/, src/app.css, src/routes/_app/).
2. Paste the "Incremental" prompt from .cursor/skills/claude-design/SKILL.md §2.
3. Paste the Frontend Scope section from artifacts/docs/features/[name].md.
4. Ask only for the new screens. Do NOT regenerate existing primitives.
5. Export to src/design-handoff/new-feature-[name]/.

When done, run /design verify new-feature [name].
```

### Post-flight — `/design verify new-feature [name]`

- [ ] Export is in `src/design-handoff/new-feature-[name]/`, not overwriting the root handoff
- [ ] No new files in `components/ui/` (Claude Design must reuse existing primitives)
- [ ] No new CSS tokens invented — `theme.css` if present matches `src/app.css`
- [ ] Every screen listed in feature doc's Frontend Scope has a file

Report, and on pass: "Incremental handoff verified. Run `/feature [name]` to dispatch."

---

## Mode C — `/design regen [screen]`

Used after `/visual-audit` flags drift on a specific screen.

### Pre-flight

- [ ] `artifacts/qa-reports/visual-audit-*.md` flags `[screen]` with a "drift" reason
- [ ] `src/design-handoff/regen-[screen]/` does NOT yet exist

### Instructions to the human

```
Open Claude Design, point at the repo, then paste the "Drift Regen" prompt from
.cursor/skills/claude-design/SKILL.md §3 with the screen name filled in.

Export to src/design-handoff/regen-[screen]/ — a single file is fine.
```

### Post-flight — `/design verify regen [screen]`

- [ ] Export is in `src/design-handoff/regen-[screen]/`
- [ ] Mock data shape matches the current mock shape in `src/design-handoff/` (so Supabase wiring still applies)

On pass: "Regen verified. Dispatch Frontend Developer to diff and re-copy the affected route file."

---

## Notes

- This command never writes code. It only runs checks, instructs the human, and logs entries.
- Full prompting patterns, anti-patterns, and failure-mode escalation: `.cursor/skills/claude-design/SKILL.md`.
- Export shape contract: `artifacts/docs/handoff-contract.md`.
