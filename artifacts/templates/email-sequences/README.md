# Email Sequences — Template

These are the **studio-level email sequences** every RAD app ships with on day one. Email is the compounding asset — each app's list becomes a distribution surface for the next app.

Locked provider: **Resend** (see `.env.example` `RESEND_API_KEY`, setup.md §3).

Three sequences, always scaffolded during `/foundation` when northstar §11 lists email as part of the retention mechanic:

| Sequence | Trigger | Purpose |
|---|---|---|
| `onboarding.md` | User signs up | First-24h activation, core loop education, one monetization nudge |
| `reengagement.md` | User inactive ≥ 7 days | Win-back, reference to unused value, soft CTA |
| `milestone.md` | User hits a product milestone | Reinforce dopamine moment, cross-sell studio products |

## How to use

1. Read the northstar — extract app name, core loop, primary user, retention hook.
2. For each sequence, copy the template file into `artifacts/docs/emails/[sequence].md` and fill in the per-app blanks.
3. Backend Developer wires the Edge Function trigger (`supabase/functions/send-email/`) to fire the sequence via Resend.
4. Store sent-state in Supabase (`email_events` table) to avoid double-sends.

## What ships on day one

Auth transactional emails (signup confirmation, password reset, magic link) are provider defaults or Supabase Auth templates — not part of these sequences. These three sequences are **behavioral**, not transactional.

## Studio compounding

After each app ships, append what worked to `artifacts/docs/emails/studio-log.md`:
- Subject lines with > 40% open rate
- CTA copy with > 10% click rate
- Timing tweaks (day offsets, send hour)

The next app starts from the studio log, not from scratch. This is how the studio gets faster with each ship.

## Anti-bloat

No drip sequences longer than 5 emails. No "newsletter" sequences. No educational content that isn't directly tied to the core loop. If it doesn't drive activation, retention, or revenue, cut it.
