# Milestone Sequence — [App Name]

Trigger: Product-specific event fires (`entries.count = 10`, `streaks.current = 7`, `billing.first_successful_payment`, etc.) → inserts row into `email_events` with `sequence = 'milestone'` and `milestone_key = '[specific]'`.

Goal: Reinforce the dopamine moment. Convert emotional peak into behavioral lock-in — share, refer, upgrade, or cross-promote another studio product.

Length: 1 email per milestone. No follow-ups. This is a reward email, not a drip.

---

## Generic milestone template

**Subject:** [Use the milestone itself as the subject — "10 entries", "7-day streak", "First paid month"]

**From:** [Founder name] <[founder@app-domain]>

**Body:**
```
[One sentence: name the milestone in a way that honors the effort. Not "Congrats!" — that's generic.]

[One sentence: reference what this typically means for users at this stage, or one thing they've unlocked.]

[Link button: ONE action — share, refer, upgrade, or try another studio app.]

[Optional: one sentence from you as the founder, human tone.]

— [Founder name]
```

---

## Variant A — Activation milestone (first core action)

**Trigger:** First successful completion of the core loop (user-defined per app)

**Subject:** Your first [core-action-noun]

**Body:**
```
You finished your first [core-action].

Most people who finish one finish five within two weeks. That's not a sales pitch — it's the pattern.

[Keep going →]

— [Founder name]
```

---

## Variant B — Streak / retention milestone

**Trigger:** `streaks.current = 7` (or 14, 30 — configure per app)

**Subject:** 7 days straight

**Body:**
```
Seven days in a row. [Specific reference to their most consistent category / type of use, if available.]

[If app has a share feature: "Share your streak →" → deep link to share screen]
[If app has a referral program: "Get a friend started →"]
[Otherwise: "See your full progress →"]

— [Founder name]
```

---

## Variant C — Monetization milestone (first paid month)

**Trigger:** `billing.first_successful_payment`

**Subject:** Thanks for going [tier name]

**Body:**
```
You just unlocked [specific benefit of the paid tier — not the feature list].

If anything isn't working the way you expected, reply to this email. Every reply lands in my inbox directly.

[One link: to the paid-tier-only feature most likely to deliver perceived value in week 1]

— [Founder name]
```

No receipt info in this email — provider-generated receipt is a separate transactional send.

---

## Variant D — Cross-studio promotion (compounding asset)

**Trigger:** User hits a high-value milestone AND studio has shipped another app relevant to this user

**Subject:** [Name of the other studio app] — [one-line pitch]

**Body:**
```
[One sentence: reference the milestone they just hit, framed as "since you're the kind of person who [thing that correlates with the new app]".]

[One sentence: what the other studio app does for them.]

[Link: to the other app's landing, with a ref code embedded — e.g., ?ref=[current-app-slug]]

— [Founder name]
```

This is the compounding asset in action — each app's list becomes a distribution channel for the next. Only send when the persona overlap is real. Never mass-cross-promote every new user.

---

## Wiring notes for Backend Developer

- `email_events` extended with `milestone_key` column (text, nullable)
- Dedupe: unique index on `(user_id, sequence, milestone_key)` prevents double-fires
- Event producer: Postgres triggers on the relevant tables insert into `email_events`; `send-email` Edge Function batch-polls and dispatches
- Variant D requires a `studio_apps` config table (list of studio apps + persona match rules) — only populate this once the studio has ≥ 2 shipped apps

---

## Studio log

After every shipped app, review milestone open/click rates and append winners to `artifacts/docs/emails/studio-log.md`. The next app's milestone sequence inherits the subject-line patterns that worked.
