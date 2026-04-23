---
name: push-notifications
description: Push notification patterns on the RAD stack — Web Push for PWA, Expo Push for native, unified subscription schema, Supabase trigger → Edge Function send pipeline, permission UX, and deep-link handling. Read this during /phase4 when a feature triggers the "Push notifications" complexity signal, and during /feature when building notification-driven flows (habit reminders, payment confirmations, coaching nudges). Not an agent — a knowledge base the Tech Lead and Backend/Frontend/Mobile Developers consult.
disable-model-invocation: true
---

# Push Notifications — RAD Knowledge Base

Push notifications are core to RAD's target app class (habits, journaling, coaching, productivity). Done well, they drive retention. Done poorly, they get the app uninstalled. This skill encodes the RAD-specific patterns for Web Push (PWA) and Expo Push (native) so delivery, permission UX, and deep-link handling are consistent across both platforms.

**When to read this:**
- During `/phase4` when the complexity scan flags **Push notifications** (any feature that pushes info to the user outside an active session).
- During `/feature [name]` when building reminder, nudge, confirmation, or re-engagement flows.
- When adding a new notification type or migrating between providers.

**What this skill does NOT cover:**
- In-app toast / banner notifications (use `sonner` — Claude Design's default).
- Email notifications (see `.cursor/skills/architecture/SKILL.md` §3 domain patterns for transactional email).
- SMS (use the payment/comms provider's SMS API directly from an Edge Function; usually too narrow to warrant its own skill).

---

## 1. Platform Matrix

| Platform | Transport | Prerequisite | Delivery service | Notes |
|---|---|---|---|---|
| **Web (Android Chrome/Firefox/Edge)** | Web Push (VAPID) | Service worker registered; user grants permission | Push Service (Mozilla/Google) | Works on any installed PWA or active tab |
| **Web (iOS Safari 16.4+)** | Web Push (VAPID) | PWA **must be added to Home Screen** first; then permission can be requested | Apple Push Notification service | iOS requires installed PWA — do NOT prompt in a browser tab, it will fail silently |
| **Native (iOS, Android)** | Expo Push Token | Expo dev/prod build with `expo-notifications`; permission granted at runtime | Expo Push Service → APNs/FCM | Works only on real devices or development builds — Expo Go cannot receive prod push reliably |

**Consequence:** RAD supports two subscription families side-by-side. The database has one table; the Edge Function selects the right transport per subscription row.

---

## 2. Schema

```sql
CREATE TYPE push_platform AS ENUM ('web', 'ios', 'android');

CREATE TABLE push_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  platform push_platform NOT NULL,

  -- Web Push fields (null for native)
  endpoint text,                              -- Push service URL
  p256dh text,                                -- base64 public key
  auth text,                                  -- base64 auth secret

  -- Expo Push fields (null for web)
  expo_token text,                            -- ExponentPushToken[...]

  device_label text,                          -- "Chrome on MacBook", "iPhone 15"
  locale text DEFAULT 'en',                   -- for localized payloads
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT web_fields_complete CHECK (
    (platform = 'web' AND endpoint IS NOT NULL AND p256dh IS NOT NULL AND auth IS NOT NULL AND expo_token IS NULL)
    OR (platform IN ('ios', 'android') AND expo_token IS NOT NULL AND endpoint IS NULL)
  ),
  CONSTRAINT unique_web_endpoint UNIQUE (endpoint),
  CONSTRAINT unique_expo_token UNIQUE (expo_token)
);

CREATE INDEX push_subs_user ON push_subscriptions (user_id);
```

**RLS:**
- User can SELECT, INSERT, DELETE their own rows. UPDATE only `last_seen_at` and `device_label`.
- Edge Function (service role) reads all rows for send pipeline.

**Per-user notification preferences** live in a separate table because they're app-logic, not transport:

```sql
CREATE TABLE notification_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  habit_reminders boolean NOT NULL DEFAULT true,
  coaching_nudges boolean NOT NULL DEFAULT true,
  payment_confirmations boolean NOT NULL DEFAULT true,
  quiet_hours_start time,                       -- e.g. 22:00
  quiet_hours_end time,                         -- e.g. 07:00
  timezone text NOT NULL DEFAULT 'UTC'          -- IANA (Asia/Ho_Chi_Minh)
);
```

---

## 3. Permission UX — The Single Most Important Section

**Permission is asked once and denied forever.** Burn the prompt on app load and you burn retention. Follow these rules.

### Rule 1: Never prompt on first load

Native browsers remember dismiss. iOS Safari requires the PWA to be installed first. Asking immediately looks desperate and loses trust.

### Rule 2: Prompt after a value moment

The user just completed a habit check-in, journaled for the third time, set their first goal, finished onboarding step 3 of 4. That's when asking *"Want a gentle reminder at 8pm daily?"* makes sense.

Implementation:

```typescript
// src/hooks/useNotificationGate.ts
export function useNotificationGate() {
  const { user } = useAuth();
  const { data: entries } = useRecentEntries(user?.id);
  const { data: subs } = usePushSubscriptions(user?.id);

  // Ask only after user has 3+ entries and no active subscription
  const shouldAsk = (entries?.length ?? 0) >= 3 && (subs?.length ?? 0) === 0;

  // Also check browser-level state — don't re-ask if already denied
  const permission = typeof Notification !== 'undefined' ? Notification.permission : 'default';
  const browserBlocks = permission === 'denied';

  return { shouldAsk: shouldAsk && !browserBlocks, permission };
}
```

### Rule 3: iOS Safari needs a custom pre-prompt

Because iOS needs the PWA installed first, the flow is:

1. Detect: `!window.matchMedia('(display-mode: standalone)').matches` (not installed).
2. Show a dismissable in-app card: *"Add [App] to your Home Screen to get reminders. Tap the share icon → 'Add to Home Screen'."* with an illustration.
3. After install (standalone mode detected on next visit), ask for notification permission.

Don't show install prompts on desktop — they're dead-end there for Web Push too (desktop Safari doesn't support Web Push yet as of 2026).

### Rule 4: Always include a one-tap disable path

Settings screen has `notification_preferences` toggles. Disabling a preference is NOT the same as revoking the push subscription. A user who wants habit reminders only should still have the subscription. Edge Function send pipeline filters by preferences before sending.

---

## 4. Client Subscription Flow

### Web — service worker registration

```typescript
// src/lib/web-push.ts
export async function subscribeWebPush(userId: string) {
  const registration = await navigator.serviceWorker.register('/sw.js');
  const existing = await registration.pushManager.getSubscription();
  if (existing) return existing;

  const sub = await registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: urlB64ToUint8Array(import.meta.env.VITE_VAPID_PUBLIC_KEY),
  });

  const payload = sub.toJSON();
  await supabase.from('push_subscriptions').insert({
    user_id: userId,
    platform: 'web',
    endpoint: payload.endpoint!,
    p256dh: payload.keys!.p256dh,
    auth: payload.keys!.auth,
    device_label: navigator.userAgent.includes('Mac') ? 'Chrome on Mac' : 'Web browser',
  });

  return sub;
}
```

Service worker (`public/sw.js`):

```javascript
self.addEventListener('push', (event) => {
  const { title, body, url, tag } = event.data?.json() ?? {};
  event.waitUntil(self.registration.showNotification(title, {
    body,
    icon: '/icons/icon-192.png',
    badge: '/icons/badge-96.png',
    tag,
    data: { url },
  }));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = event.notification.data?.url ?? '/';
  event.waitUntil(clients.openWindow(url));
});
```

### Native — Expo registration

```typescript
// mobile/src/lib/expo-push.ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';

export async function subscribeExpoPush(userId: string) {
  if (!Device.isDevice) return null;

  const { status: existing } = await Notifications.getPermissionsAsync();
  let finalStatus = existing;
  if (existing !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }
  if (finalStatus !== 'granted') return null;

  const token = (await Notifications.getExpoPushTokenAsync({
    projectId: process.env.EXPO_PUBLIC_EAS_PROJECT_ID,
  })).data;

  await supabase.from('push_subscriptions').upsert({
    user_id: userId,
    platform: Platform.OS,  // 'ios' | 'android'
    expo_token: token,
    device_label: `${Device.manufacturer} ${Device.modelName}`,
  }, { onConflict: 'expo_token' });

  return token;
}
```

Android requires a channel (Expo handles this but you set the channel importance):

```typescript
if (Platform.OS === 'android') {
  await Notifications.setNotificationChannelAsync('default', {
    name: 'Default',
    importance: Notifications.AndroidImportance.HIGH,
    sound: 'default',
  });
}
```

---

## 5. Send Pipeline (Supabase → Edge Function → Push Service)

Two trigger styles. Use both as needed.

### Style A: Event-driven (preferred)

Database trigger calls `pg_net` to invoke an Edge Function when a row that should notify is inserted.

```sql
CREATE OR REPLACE FUNCTION notify_on_habit_reminder()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM net.http_post(
    url := current_setting('app.send_push_url'),
    headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.service_role_key')),
    body := jsonb_build_object('reminder_id', NEW.id)
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER habit_reminder_enqueued
AFTER INSERT ON habit_reminders
FOR EACH ROW EXECUTE FUNCTION notify_on_habit_reminder();
```

App config for the trigger (set once per env):

```sql
ALTER DATABASE postgres SET app.send_push_url = 'https://[project].supabase.co/functions/v1/send-push';
ALTER DATABASE postgres SET app.service_role_key = 'eyJhbGc...';  -- use Vault in prod
```

### Style B: Scheduled (pg_cron)

For recurring reminders ("every day at 8pm in user's timezone"):

```sql
SELECT cron.schedule(
  'habit-reminders-hourly',
  '0 * * * *',  -- top of every hour
  $$
    INSERT INTO habit_reminders (user_id, habit_id, scheduled_for)
    SELECT user_id, id, now()
    FROM habits h
    JOIN notification_preferences p ON p.user_id = h.user_id
    WHERE p.habit_reminders = true
      AND is_within_time_window(h.remind_at, p.timezone, p.quiet_hours_start, p.quiet_hours_end)
  $$
);
```

The trigger from Style A fires on the new rows.

### Edge Function: `send-push`

```typescript
// supabase/functions/send-push/index.ts
import webpush from 'npm:web-push';
import { createClient } from 'jsr:@supabase/supabase-js@2';

webpush.setVapidDetails(
  'mailto:ops@yourapp.com',
  Deno.env.get('VAPID_PUBLIC_KEY')!,
  Deno.env.get('VAPID_PRIVATE_KEY')!,
);

Deno.serve(async (req) => {
  const { reminder_id } = await req.json();

  const sb = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  const { data: reminder } = await sb
    .from('habit_reminders')
    .select('*, habits(name)')
    .eq('id', reminder_id)
    .single();

  const { data: prefs } = await sb
    .from('notification_preferences')
    .select('*')
    .eq('user_id', reminder.user_id)
    .single();

  if (!prefs?.habit_reminders) return new Response('skipped by prefs', { status: 200 });

  const { data: subs } = await sb
    .from('push_subscriptions')
    .select('*')
    .eq('user_id', reminder.user_id);

  const payload = {
    title: `Time for ${reminder.habits.name}`,
    body: "Tap to log it in under 10 seconds.",
    url: `/app/habits/${reminder.habit_id}`,
    tag: `habit-${reminder.habit_id}`,   // dedupe on client
  };

  const results = await Promise.allSettled(subs!.map((s) => sendOne(s, payload)));

  // Cleanup: remove subscriptions that returned 410 Gone
  for (let i = 0; i < results.length; i++) {
    const r = results[i];
    if (r.status === 'rejected' && isExpired(r.reason)) {
      await sb.from('push_subscriptions').delete().eq('id', subs![i].id);
    }
  }

  return new Response(JSON.stringify({ sent: results.filter(r => r.status === 'fulfilled').length }));
});

async function sendOne(sub: any, payload: any) {
  if (sub.platform === 'web') {
    return webpush.sendNotification({
      endpoint: sub.endpoint,
      keys: { p256dh: sub.p256dh, auth: sub.auth },
    }, JSON.stringify(payload));
  }

  // Expo push
  const res = await fetch('https://exp.host/--/api/v2/push/send', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
    body: JSON.stringify({
      to: sub.expo_token,
      title: payload.title,
      body: payload.body,
      data: { url: payload.url },
      sound: 'default',
    }),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

function isExpired(err: any): boolean {
  // Web Push returns 404 or 410 when subscription is dead
  // Expo returns DeviceNotRegistered in the response
  return err?.statusCode === 410 || err?.statusCode === 404
    || (err?.message ?? '').includes('DeviceNotRegistered');
}
```

---

## 6. Deep-Link Handling

Every notification carries a `url` in its payload. Both platforms need to route that URL back into the app.

### Web

Service worker `notificationclick` handler (shown in §4) opens `clients.openWindow(url)`. React Router handles the route on load.

### Native (Expo)

```typescript
// mobile/src/app/_layout.tsx
import * as Notifications from 'expo-notifications';
import { useRouter } from 'expo-router';
import { useEffect } from 'react';

export default function RootLayout() {
  const router = useRouter();

  useEffect(() => {
    const sub = Notifications.addNotificationResponseReceivedListener((response) => {
      const url = response.notification.request.content.data?.url;
      if (typeof url === 'string') router.push(url);
    });
    return () => sub.remove();
  }, [router]);

  // ...
}
```

The `url` format is the same on both platforms (`/app/habits/[id]`) because Expo Router uses file-based routes that mirror web paths in RAD.

---

## 7. Testing

- **Local web:** use `curl` or the Supabase dashboard to call `send-push` with a test `reminder_id`. Open DevTools → Application → Service Workers to inspect.
- **Local native:** `expo-notifications` has `scheduleNotificationAsync` for local test; use `expo push:send` CLI for server-style tests.
- **Staging:** a `/admin/push-test` internal page (auth-gated, admin-only) that invokes the Edge Function with arbitrary payloads.
- **Never test in prod with a broadcast.** Always scope to the tester's own `user_id`.

---

## 8. Anti-Patterns

- **Prompting for permission on first page load.** Burn rate >90%. Wait for a value moment.
- **One notification per DB write.** Batch related events (e.g., 5 friends reacted → one notification, not five).
- **Ignoring `last_seen_at`.** A subscription that hasn't been refreshed in 60+ days is probably dead. Clean up periodically.
- **Sending without preference check.** Users who disabled reminders in settings expect them off. Preferences filter before send, not after receipt.
- **Non-actionable notifications.** Every notification should have a concrete next step — a deep link to the exact screen for the action, not the app root.
- **Localizing after send.** The send pipeline looks up `push_subscriptions.locale` (mirrored from `notification_preferences.timezone` at subscribe time) and renders `title`/`body` from localized templates. Don't send English to a Vietnamese user.
- **No quiet hours.** Even motivated users hate 3am pings. Respect `quiet_hours_start`/`quiet_hours_end` in the user's timezone.
- **Holding notification content in app code only.** Long-running reminders need to survive app updates. The *template* is code; the *scheduled content* should be in DB rows so an old subscription still resolves correctly.
- **Forgetting iOS PWA install prerequisite.** Asking for permission in iOS Safari tab is a silent failure.

---

## 9. Phase 4 Checklist for Push Features

When a feature needs push, the tech spec must answer:

- [ ] **Trigger style** — event (DB trigger) or scheduled (pg_cron)?
- [ ] **Preference key** in `notification_preferences` that governs this notification type.
- [ ] **Value-moment gate** — when in the UX flow will we ask for permission?
- [ ] **Quiet hours policy** — respected, or is this time-critical (e.g., payment confirmation)?
- [ ] **Payload template** — title, body, url (deep link), tag (for deduping), per supported locale.
- [ ] **Platform scope** — web only, native only, or both. (Default: both for RAD's target apps.)
- [ ] **Idempotency** — what stops a duplicate notification on trigger retry? (Usually a `sent_at` column on the trigger source row.)
- [ ] **Cleanup** — 410/404/DeviceNotRegistered responses delete the subscription row.
- [ ] **Admin test path** — how staging can trigger this for a specific user.

Incomplete checklist blocks Phase 4 approval.

---

## 10. RAD Stack Mapping Summary

| Concern | Where it lives |
|---|---|
| Web Push subscribe | `src/lib/web-push.ts` + `public/sw.js` |
| Expo Push subscribe | `mobile/src/lib/expo-push.ts` |
| Unified subscription table | `push_subscriptions` (Postgres) |
| Preferences | `notification_preferences` (Postgres) |
| Trigger → send | Postgres trigger → `pg_net` → `supabase/functions/send-push/` |
| VAPID keys | Edge Function env: `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY` (private is server-only) |
| Public VAPID key (client) | `VITE_VAPID_PUBLIC_KEY` (safe to ship in bundle) |
| Expo project ID | `EXPO_PUBLIC_EAS_PROJECT_ID` |
| Deep-link handler (web) | Service worker `notificationclick` |
| Deep-link handler (native) | `Notifications.addNotificationResponseReceivedListener` in `mobile/src/app/_layout.tsx` |
| Permission gate hook (shared pattern) | `src/hooks/useNotificationGate.ts` + `mobile/src/hooks/useNotificationGate.ts` (parallel implementations; identical API) |
