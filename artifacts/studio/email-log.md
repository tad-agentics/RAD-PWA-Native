# Email — Studio Winners Log

Running log of email patterns that won across apps. Updated by the Backend Developer or Tech Lead after every shipped app accumulates at least 30 days of send data.

Read this before scaffolding any new app's retention sequences (see `artifacts/templates/email-sequences/`).

---

## Entry format

```
### [YYYY-MM-DD] [app-slug] — [sequence name]

**Send volume:** [count over window]
**Window:** [30d / 60d / etc.]
**Provider:** Resend

**Subject line winner:**
- "[subject]" — [open rate %] ([n] sends)

**CTA winner:**
- "[button copy]" — [click rate %] ([n] sends)

**Timing winner:**
- [day offset, send hour UTC, user-local or not]

**What we'd change next time:**
- [One-line lesson.]
```

---

## Entries

*No entries yet. First shipped app's 30-day email data will seed this log.*

---

## Consolidated subject-line patterns

Once 2+ apps confirm a pattern, promote to this section. The next app's sequences inherit these as defaults.

- _(empty — promote after 2+ confirmations)_

---

## Consolidated CTA patterns

- _(empty — promote after 2+ confirmations)_

---

## Consolidated timing rules

- _(empty — promote after 2+ confirmations)_

---

## Anti-patterns (what not to do)

Studio-wide rejections — previously tried, didn't work. Do not re-try unless there's a clear reason the context is different.

- _(empty — will populate as losses are logged)_
