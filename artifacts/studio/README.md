# Studio — Compounding Assets

This directory is the **studio layer** — assets that carry across every app the studio ships. Individual apps consume these and contribute learnings back.

Unlike `artifacts/docs/` (per-app outputs) and `artifacts/templates/` (per-app scaffolds), nothing here is app-specific. Every file in `artifacts/studio/` is a dictionary of patterns the next app starts from.

## Files

| File | Purpose | Updated by |
|---|---|---|
| `claude-design-log.md` | Prompt patterns that produced clean handoffs; failure modes encountered; brief structures that worked | Product Designer on every `/design` session end |
| `email-log.md` | Subject lines, CTA copy, timing, and open/click rates that won across apps | Backend Developer / Tech Lead after every shipped app's first 30-day email data |
| `landing-log.md` | Landing-page section stacks, headline formulas, trust-bar patterns, FAQ themes that converted | Product Designer + DevOps Agent during `/dogfood` and post-launch |
| `anti-patterns.md` | Things that looked clever at build time but hurt the product post-launch | Anyone, after a post-mortem |

## Workflow

- **At `/office-hours` entry:** Tech Lead reads `artifacts/studio/` entries relevant to the incoming northstar. Patterns that applied before are nominated for reuse.
- **At `/phase2`:** Product Designer reads `claude-design-log.md` before writing the brief. Winning prompt structures inform the new brief.
- **At `/foundation`:** Backend Developer reads `email-log.md` before scaffolding retention sequences. Subject lines and timings default to studio winners.
- **At `/dogfood` + post-launch:** contributors append new wins and losses back into the relevant log.

## Anti-bloat

- Do not paste entire briefs / emails — keep entries short (winning pattern + one-line why).
- Do not commit app-specific content here. If it names an app, it belongs in that app's `artifacts/docs/`.
- If a pattern stops winning, delete it. Stale winners mislead the next ship.

## Compounding rule

An app ships → its learnings go into studio → the next app starts from those learnings, not from scratch. The studio gets faster with each ship **only if the contribution step is non-optional**. `/session-end` and `/pre-handoff` both remind the contributor to update studio logs.
