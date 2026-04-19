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
- [ ] **Repo is linked in Claude Design** — human has connected the GitHub repo or attached the local directory via Claude Design's Import button. Without the link, Claude Design invents tokens and primitives instead of matching the existing system. This is the single biggest quality lever — never skip.

### Instructions to the human

Present:

```
Run Claude Design now.

1. Open Claude Design. Confirm the repo link shows your project name in the
   workspace sidebar — if not, link it now via Import → GitHub or Local Directory.
2. Paste artifacts/docs/claude-design-brief.md verbatim into the prompt.
3. Add the three-line initial-build prompt from .cursor/skills/claude-design/SKILL.md §1.
4. Iterate until every screen in the brief is rendered and the handoff exports cleanly.
5. Export TWO artifacts:
   a) ZIP — extract into src/design-handoff/
   b) Claude Code handoff bundle — copy the bundle URL or paste the implementation
      notes / token metadata into artifacts/docs/claude-design-handoff-notes.md
   The ZIP is the source of truth for code; the handoff metadata is supplementary
   context the Frontend agent reads alongside.

When done, run /design verify to validate the export against artifacts/docs/handoff-contract.md.
```

### Post-flight — `/design verify`

Run the contract check:

- [ ] `src/design-handoff/App.tsx` or `src/design-handoff/routes.tsx` exists
- [ ] `src/design-handoff/theme.css` exists
- [ ] `src/design-handoff/components/ui/` directory exists with ≥ 5 primitives
- [ ] No `globals.css`, no `app/` (Next.js), no `page.tsx` files
- [ ] None of the discard-list files in `artifacts/docs/handoff-contract.md` §Discard list are present (delete on sight)
- [ ] Every screen listed in `screen-specs-[app]-v1.md` has a matching file in the handoff
- [ ] `artifacts/docs/claude-design-handoff-notes.md` is populated with implementation notes / token metadata from the Claude Code handoff bundle (not blank)
- [ ] **Token freshness (enforces the repo-link mandate):**
  ```bash
  bash .cursor/skills/claude-design/scripts/verify-handoff-tokens.sh initial src/design-handoff
  ```
  Exit 0 → pass. Exit 1 → BLOCKING: tokens don't match EDS §5 roles, meaning the repo/EDS wasn't linked in Claude Design. Re-link, regenerate, re-run verify.

Report file-by-file. On any miss, point the human at the relevant fix in `.cursor/skills/claude-design/SKILL.md` §Failure Modes. On all-pass, record:

```
Append an entry to artifacts/docs/claude-design-log.md using the template in that file.
If the pattern is likely to repeat across apps, also flag it for promotion to
artifacts/studio/claude-design-log.md at /session-end.
```

Then: "Handoff verified. Proceed to `/phase4`."

---

## Mode B — `/design new-feature [name]`

### Pre-flight

- [ ] `artifacts/docs/features/[name].md` exists with an approved Frontend Scope
- [ ] `src/design-handoff/new-feature-[name]/` does NOT yet exist
- [ ] Initial `src/design-handoff/` has already been consumed (components in `src/components/ui/`)
- [ ] **Repo link in Claude Design is current** — if the link was set up before the initial build, re-sync so Claude Design sees the post-Foundation `src/components/ui/`, `src/app.css`, and `src/routes/_app/` as the current source of truth. Stale links cause primitive duplication.

### Instructions to the human

```
Open Claude Design, then:

1. Confirm the repo link is current (re-sync if needed). The link is mandatory —
   without it, Claude Design will regenerate primitives instead of reusing them.
2. Paste the "Incremental" prompt from .cursor/skills/claude-design/SKILL.md §2.
3. Paste the Frontend Scope section from artifacts/docs/features/[name].md.
4. Ask only for the new screens. Do NOT regenerate existing primitives.
5. Export ZIP into src/design-handoff/new-feature-[name]/.
6. Append the handoff bundle's implementation notes for these screens into
   artifacts/docs/claude-design-handoff-notes.md (under a new Feature section).

When done, run /design verify new-feature [name].
```

### Post-flight — `/design verify new-feature [name]`

- [ ] Export is in `src/design-handoff/new-feature-[name]/`, not overwriting the root handoff
- [ ] No new files in `components/ui/` (Claude Design must reuse existing primitives)
- [ ] Every screen listed in feature doc's Frontend Scope has a file
- [ ] **Token freshness (enforces the repo-link mandate):**
  ```bash
  bash .cursor/skills/claude-design/scripts/verify-handoff-tokens.sh new-feature src/design-handoff/new-feature-[name]
  ```
  Exit 0 → pass (no theme.css, or every token already in `src/app.css`). Exit 1 → BLOCKING: the handoff invents tokens, meaning the repo link was stale/absent. Re-sync the link in Claude Design, regenerate, re-run.

Report, and on pass: "Incremental handoff verified. Run `/feature [name]` to dispatch."

---

## Mode C — `/design regen [screen]`

Used after `/visual-audit` flags drift on a specific screen.

### Pre-flight

- [ ] `artifacts/qa-reports/visual-audit-*.md` flags `[screen]` with a "drift" reason
- [ ] `src/design-handoff/regen-[screen]/` does NOT yet exist
- [ ] **Repo link in Claude Design is current** — without it, the regen drifts further. Re-sync if needed.

### Instructions to the human

```
Open Claude Design with the repo link current, then paste the "Drift Regen"
prompt from .cursor/skills/claude-design/SKILL.md §3 with the screen name
filled in.

Export to src/design-handoff/regen-[screen]/ — a single file is fine.
```

### Post-flight — `/design verify regen [screen]`

- [ ] Export is in `src/design-handoff/regen-[screen]/`
- [ ] Mock data shape matches the current mock shape in `src/design-handoff/` (so Supabase wiring still applies)
- [ ] **Token freshness (enforces the repo-link mandate):**
  ```bash
  bash .cursor/skills/claude-design/scripts/verify-handoff-tokens.sh regen src/design-handoff/regen-[screen]
  ```
  Exit 0 → pass. Exit 1 → BLOCKING: regen invents tokens (repo link stale). Re-sync link, regenerate, re-run.

On pass: "Regen verified. Dispatch Frontend Developer to diff and re-copy the affected route file."

---

## Notes

- This command never writes code. It only runs checks, instructs the human, and logs entries.
- Full prompting patterns, anti-patterns, and failure-mode escalation: `.cursor/skills/claude-design/SKILL.md`.
- Export shape contract: `artifacts/docs/handoff-contract.md`.
