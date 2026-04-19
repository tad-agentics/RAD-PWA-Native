# Re-engagement Sequence — [App Name]

Trigger: Nightly `pg_cron` job selects users where `last_active_at < now() - interval '7 days'` AND no re-engagement email sent in the last 30 days.

Goal: Bring the user back to the core loop once. If they don't return after this sequence, do not re-enter for 60 days.

Length: 2 emails maximum.

---

## Email 1 — Day 7 inactive

**Subject:** [Reference something they did or almost did — not "we miss you"]

**From:** [Founder name] <[founder@app-domain]>

**Body:**
```
[One sentence: reference a specific thing they did or were working on — pull from their actual data when possible, otherwise reference the core loop generically.]

[One sentence: what they'd see / get if they came back now. Concrete, not abstract.]

[Link button: deep link to the exact screen they last visited, or to the core-loop screen]

— [Founder name]
```

**Example with personalization:**
```
Hey Sam,

Your last entry on April 12 was about [topic]. You never came back to finish it.

[Finish your April 12 entry →]

— Alex
```

**Example without personalization (less effective — prefer the above):**
```
Hey,

It's been a week since your last [core-action]. Here's where you left off:

[Open [App Name] →]

— Alex
```

Supabase query for the personalized variant:
```sql
SELECT u.id, u.email, p.first_name, e.last_entry_topic, e.last_entry_date
FROM auth.users u
JOIN profiles p ON p.user_id = u.id
LEFT JOIN (
  SELECT user_id, topic AS last_entry_topic, created_at::date AS last_entry_date
  FROM entries
  WHERE created_at = (SELECT MAX(created_at) FROM entries WHERE user_id = entries.user_id)
) e ON e.user_id = u.id
WHERE u.last_sign_in_at < now() - interval '7 days'
  AND NOT EXISTS (
    SELECT 1 FROM email_events
    WHERE user_id = u.id AND sequence = 'reengagement'
      AND sent_at > now() - interval '30 days'
  )
LIMIT 500;
```

---

## Email 2 — Day 14 inactive (only if Email 1 did not trigger a return)

**Subject:** [One-word subject referencing the unused value — e.g., "Unused", "Waiting", "Still there"]

**Body:**
```
[One sentence: a single specific fact about their account — credits remaining, entries saved, progress made. Pull from real data.]

[Optional: one sentence of value add — a tip, a new feature that directly solves a problem they had.]

[Link button: same deep link as Email 1]

[One line: "Reply if you don't want these — I'll stop." Single-opt-out.]

— [Founder name]
```

If Email 2 doesn't return the user, suppress re-engagement for 60 days. Log `email_events.next_reengagement_eligible_at = now() + interval '60 days'`.

---

## Wiring notes for Backend Developer

- Cron schedule: `0 9 * * *` (daily, 9am UTC) via Supabase `pg_cron`
- Batch size: 500 users per run to stay within Resend free-tier limits (upgrade when scale requires)
- Deep link handling: Edge Function generates a signed token for deep links that pre-authenticates the user for 1 click (reduces friction)
- Unsubscribe: every email includes Resend's auto-inserted `List-Unsubscribe` header. No custom unsub page required for transactional behavioral emails, but monitor spam reports weekly.

---

## Anti-patterns

- No "We miss you" — generic and ignored
- No "Here's what's new" — feature announcements are a separate sequence
- No discount bombs — undermines the core value proposition
- No daily re-sends — aggressive frequency kills future deliverability
