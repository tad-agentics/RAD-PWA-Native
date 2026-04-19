# Onboarding Sequence — [App Name]

Trigger: `auth.users` insert → `send-email` Edge Function schedules this sequence.

Goal: Get the user through the core loop once in the first 24 hours. One monetization nudge, no more.

Length: 3 emails maximum. Cut the third if the user has already converted or performed the core action.

---

## Email 1 — Immediate (T+0)

**Subject:** [6–8 words, references the outcome, no clickbait]

**From:** [Founder name] <[founder@app-domain]>

**Preview text:** [One sentence that completes the subject]

**Body:**
```
Hey [first_name or "there"],

[One sentence: what the app does for them, in their words from the northstar primary user persona.]

[One sentence: the single thing to do right now. Link to the core-loop screen, not the dashboard.]

[Link button: "[Action verb + noun]" → https://[app]/[core-loop-route]]

[Optional: one sentence social proof or reassurance — not marketing copy.]

— [Founder name]
```

**Mock filled example (delete after customizing):**
```
Hey Sam,

Most people finish their first entry in under 3 minutes.

Here's yours: https://[app]/new

[Start your first entry →]

Reply if you get stuck. I read every email.

— Alex
```

---

## Email 2 — T+4 hours (only if user has NOT completed the core action)

**Subject:** [Reference the obstacle, not the feature]

**Body:**
```
[One sentence: acknowledge they haven't completed the core action.]

[One sentence: remove the most likely friction point — pulled from user scenarios in northstar §13.]

[Link button: same target as Email 1]

— [Founder name]
```

Skip this email if `email_events.onboarding_2_suppressed = true` (set when core action completes).

---

## Email 3 — T+24 hours (monetization nudge)

**Subject:** [Reference the value they unlocked or will unlock — not the price]

**Body:**
```
[One sentence: reinforce what they've done or seen.]

[One sentence: introduce the paid tier as removing a specific limitation, not as an upgrade.]

[Link button: "[Action verb]" → https://[app]/pricing]

[Optional: time-boxed incentive ONLY if it's real — no fake urgency.]

— [Founder name]
```

Skip this email if the user has already converted (`profiles.tier != 'free'`).

---

## Wiring notes for Backend Developer

- Edge Function: `supabase/functions/send-email/index.ts` — accepts `{ user_id, sequence: 'onboarding', step: 1 | 2 | 3 }`
- Scheduler: `pg_cron` job polls `email_events` table every 5 minutes, dispatches due emails
- Table: `email_events (user_id, sequence, step, scheduled_at, sent_at, suppressed_at, resend_message_id)`
- Suppression rules:
  - Step 2 suppressed when core-loop completion event fires (app-specific)
  - Step 3 suppressed when `profiles.tier` changes from `free`
- Resend audience: all users are added to a base audience on signup; sequence steps are individual sends (not broadcasts)

---

## Copy quality check

Every email must pass `.cursor/rules/copy-rules.mdc` quality test. Specifically:
- No "Welcome to [App Name]!" — generic greetings are banned
- No feature lists — each email has exactly one ask
- No "we" or "our team" — single-founder voice
- Subject + preview reads as a complete thought
