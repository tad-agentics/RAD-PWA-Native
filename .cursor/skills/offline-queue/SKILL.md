---
name: offline-queue
description: Mutation queueing and replay patterns for RAD — when to queue, TanStack persistence, IndexedDB/AsyncStorage storage, conflict resolution, sync status UI, and Expo parity. Read this during /phase4 when a feature triggers the "Offline-tolerant mutation" complexity signal, and during /feature when building journaling, habit-tracking, or any capture-first UX. Not an agent — a knowledge base the Tech Lead and Frontend/Mobile/Backend Developers consult.
disable-model-invocation: true
---

# Offline Queue — RAD Knowledge Base

For RAD's target app class (life/work apps — journaling, habits, coaching, productivity), users often open the app on commute, in elevators, on planes, or in low-signal areas. If the app silently fails when offline, users learn not to rely on it. This skill encodes the RAD-specific pattern for queuing mutations locally, replaying them on reconnect, and surfacing sync state to users — without inventing a distributed system.

**When to read this:**
- During `/phase4` when a feature is "capture-first" — the primary value is recording the user's input, not serving server-side data (journal entries, habit check-ins, mood logs, voice memos).
- During `/feature [name]` when building any screen where a network failure would lose user data.
- When deciding whether a new mutation should queue or require immediate server confirmation.

**What this skill does NOT cover:**
- True CRDT-based sync (for collaborative editing). RAD is not the right stack — see `.cursor/skills/architecture/SKILL.md` §2.
- Large-file offline upload (>5MB). Separate concern — use resumable upload with signed URLs.
- Offline-first *reads*. RAD uses TanStack Query's normal cache; true offline read requires service worker cache strategies, which are per-feature decisions.

---

## 1. When To Queue (and When Not To)

Not every mutation should queue. Queuing has real cost: conflict risk, UX complexity, storage management. Apply this decision tree **per mutation type**, not per feature.

| Mutation | Queue? | Why |
|---|---|---|
| Create a journal entry | **Yes** | User's value-moment. Losing it = broken trust. No server-side constraint requires immediate write. |
| Check off a habit | **Yes** | Fast, frequent, low-stakes, time-stamped (timestamp is the client clock, not server). |
| Write a mood rating | **Yes** | Same shape as journal/habit — capture-first. |
| Update profile name | **Allow with warning** | Ambiguous if multi-device — last-write-wins usually fine. |
| Delete an entry | **No** | Destructive, irreversible from user POV. Require online. |
| Pay, subscribe, buy credits | **No** | Money. Must be confirmed server-side before UI reflects it. |
| Accept friend request, join group | **No** | Multi-user state. Offline queue loses context. |
| LLM chat message | **Mixed** | The user's message can be queued; the assistant response cannot. See `ai-patterns/SKILL.md` §6. |
| Invite someone to shared resource | **No** | Integrity-critical and surprising to queue. |

**Rule of thumb:** queue if (a) the value is capturing user state, (b) failure to sync is recoverable by the user on reconnect, (c) no other user's state depends on the outcome.

---

## 2. Architecture

```
User action
  │
  ▼
TanStack useMutation
  │   onMutate: optimistic update + generate client_mutation_id
  │   mutationFn: POST to Supabase
  │
  ├── online path: immediate Supabase write, resolve, onSettled clears draft
  │
  └── offline path:
        │
        ▼
      Queue store (IndexedDB on web, AsyncStorage on native)
        │   persist { id, tableName, row, client_mutation_id, queuedAt }
        │
        ▼
      Sync worker (listens for online event)
        │   on reconnect: drain queue in insertion order
        │   for each: POST to Supabase; on success, delete from queue
        │   on permanent failure (4xx non-retryable): surface to user
```

### Key decisions baked into this architecture

- **The queue store is append-only until drained.** Mutations are never edited in the queue — users edit via normal flows, which enqueue new mutations.
- **`client_mutation_id` is the idempotency key.** Every mutation carries a UUID generated on the client. Server-side uniqueness constraint prevents duplicates if the queue replays the same mutation twice.
- **Optimistic UI updates happen immediately regardless of network.** TanStack Query's `onMutate` mutates the local cache; the server catches up later.
- **Queue processing is single-threaded.** Parallel replay causes ordering bugs (e.g., create entry, then update entry, then delete — must replay in order).

---

## 3. Schema

Every table that accepts queued writes gets a `client_mutation_id` column:

```sql
ALTER TABLE journal_entries
  ADD COLUMN client_mutation_id uuid UNIQUE;

ALTER TABLE habit_check_ins
  ADD COLUMN client_mutation_id uuid UNIQUE;
```

The UNIQUE constraint guarantees idempotency: a retried INSERT returns a conflict, which the client treats as success.

**Why UUID and not auto-increment?** Because the client generates the ID before seeing the server. An auto-increment ID wouldn't exist in the queue; the client needs to reference the row in the UI immediately.

**RLS consequence:** the UNIQUE constraint is per-table, not per-user. If you worry about leaking that a given UUID already exists (side-channel), add `(user_id, client_mutation_id) UNIQUE` instead. For consumer B2C apps the plain UNIQUE is fine.

---

## 4. Web — IndexedDB Queue (via `idb`)

```typescript
// src/lib/offline-queue.ts
import { openDB, IDBPDatabase } from 'idb';

type QueuedMutation = {
  id: string;                  // client_mutation_id
  table: string;               // 'journal_entries'
  op: 'insert' | 'update';     // no delete — see §1
  row: Record<string, unknown>;
  userId: string;
  queuedAt: number;            // ms since epoch
  attempts: number;
};

let dbPromise: Promise<IDBPDatabase> | null = null;
function getDb() {
  if (!dbPromise) {
    dbPromise = openDB('rad-queue', 1, {
      upgrade(db) {
        db.createObjectStore('mutations', { keyPath: 'id' });
      },
    });
  }
  return dbPromise;
}

export async function enqueue(m: Omit<QueuedMutation, 'queuedAt' | 'attempts'>) {
  const db = await getDb();
  await db.put('mutations', { ...m, queuedAt: Date.now(), attempts: 0 });
}

export async function peekQueue(userId: string): Promise<QueuedMutation[]> {
  const db = await getDb();
  const all = await db.getAll('mutations');
  return all.filter((m) => m.userId === userId).sort((a, b) => a.queuedAt - b.queuedAt);
}

export async function removeFromQueue(id: string) {
  const db = await getDb();
  await db.delete('mutations', id);
}

export async function incrementAttempts(id: string) {
  const db = await getDb();
  const m = await db.get('mutations', id);
  if (m) await db.put('mutations', { ...m, attempts: m.attempts + 1 });
}
```

### TanStack mutation hook

```typescript
// src/hooks/useJournalEntry.ts
export function useAddJournalEntry() {
  const qc = useQueryClient();
  const { user } = useAuth();

  return useMutation({
    mutationFn: async (input: { text: string }) => {
      const row = {
        client_mutation_id: crypto.randomUUID(),
        user_id: user!.id,
        text: input.text,
        created_at: new Date().toISOString(),
      };

      if (!navigator.onLine) {
        await enqueue({
          id: row.client_mutation_id,
          table: 'journal_entries',
          op: 'insert',
          row,
          userId: user!.id,
        });
        return row;            // optimistic — UI treats as success
      }

      const { data, error } = await supabase
        .from('journal_entries')
        .insert(row)
        .select()
        .single();

      if (error) {
        // Server rejected but we're online — decide: enqueue for retry, or surface?
        if (isTransient(error)) {
          await enqueue({ id: row.client_mutation_id, table: 'journal_entries', op: 'insert', row, userId: user!.id });
          return row;
        }
        throw error;           // permanent error — surface to user
      }

      return data;
    },

    onMutate: async (input) => {
      await qc.cancelQueries({ queryKey: ['journal', user!.id] });
      const prev = qc.getQueryData(['journal', user!.id]);
      qc.setQueryData(['journal', user!.id], (old: any[] = []) => [{ ...input, _pending: true }, ...old]);
      return { prev };
    },

    onError: (err, input, ctx) => {
      qc.setQueryData(['journal', user!.id], ctx?.prev);
    },

    onSuccess: (row) => {
      qc.setQueryData(['journal', user!.id], (old: any[] = []) => {
        return old.map((e) => (e.client_mutation_id === row.client_mutation_id ? row : e));
      });
    },
  });
}
```

### Sync worker

```typescript
// src/lib/sync-worker.ts
let draining = false;

export function startSyncWorker(userId: string) {
  window.addEventListener('online', () => drain(userId));
  // Also drain on app focus, in case online event missed
  window.addEventListener('focus', () => { if (navigator.onLine) drain(userId); });
  // Initial drain on load
  if (navigator.onLine) drain(userId);
}

async function drain(userId: string) {
  if (draining) return;
  draining = true;
  try {
    const queue = await peekQueue(userId);
    for (const m of queue) {
      if (m.attempts >= 5) {
        surfacePermanentFailure(m);
        await removeFromQueue(m.id);
        continue;
      }
      try {
        if (m.op === 'insert') {
          const { error } = await supabase.from(m.table).insert(m.row);
          // 23505 = unique_violation → idempotent replay, treat as success
          if (error && error.code !== '23505') throw error;
        } else if (m.op === 'update') {
          const { error } = await supabase.from(m.table).update(m.row).eq('client_mutation_id', m.id);
          if (error) throw error;
        }
        await removeFromQueue(m.id);
      } catch (err) {
        await incrementAttempts(m.id);
        if (!isTransient(err)) {
          surfacePermanentFailure(m);
          await removeFromQueue(m.id);
        }
        // If transient, leave in queue — next online/focus event retries
        break;  // stop drain on first error to preserve ordering
      }
    }
  } finally {
    draining = false;
  }
}
```

---

## 5. Native — AsyncStorage Queue (Expo)

Same API, different storage. The `shared/` workspace holds the abstract queue interface; web and mobile provide concrete implementations.

```typescript
// shared/lib/offline-queue-contract.ts
export interface QueueAdapter {
  enqueue(m: QueuedMutation): Promise<void>;
  peek(userId: string): Promise<QueuedMutation[]>;
  remove(id: string): Promise<void>;
  incrementAttempts(id: string): Promise<void>;
}
```

```typescript
// mobile/src/lib/offline-queue-native.ts
import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY = 'rad-queue:v1';

async function readAll(): Promise<QueuedMutation[]> {
  const raw = await AsyncStorage.getItem(KEY);
  return raw ? JSON.parse(raw) : [];
}

async function writeAll(all: QueuedMutation[]) {
  await AsyncStorage.setItem(KEY, JSON.stringify(all));
}

export const nativeQueue: QueueAdapter = {
  async enqueue(m) {
    const all = await readAll();
    all.push(m);
    await writeAll(all);
  },
  async peek(userId) {
    return (await readAll()).filter((m) => m.userId === userId).sort((a, b) => a.queuedAt - b.queuedAt);
  },
  async remove(id) {
    await writeAll((await readAll()).filter((m) => m.id !== id));
  },
  async incrementAttempts(id) {
    const all = await readAll();
    const i = all.findIndex((m) => m.id === id);
    if (i >= 0) { all[i].attempts += 1; await writeAll(all); }
  },
};
```

Network detection uses `@react-native-community/netinfo`:

```typescript
import NetInfo from '@react-native-community/netinfo';

NetInfo.addEventListener((state) => {
  if (state.isConnected && state.isInternetReachable) drain(userId);
});
```

The sync worker logic is otherwise identical to web.

---

## 6. Conflict Resolution

Queued mutations replay in order, but multi-device users create real conflicts. Three strategies, picked per table:

### Last-write-wins (default for capture tables)

`journal_entries`, `habit_check_ins`: whichever write reaches the server last overwrites. Usually fine — these are user-owned, timestamped, and single-value per moment.

### User picks on conflict (for unique per-day entries)

If the table enforces `UNIQUE (user_id, entry_date)` (e.g., daily mood entry), a second queued entry for the same day will 23505 on replay. Strategy:

1. Detect the 23505 on replay.
2. Fetch the server row.
3. If queue row and server row differ, surface a dialog: *"Your mood for today was also saved from another device. Keep [this version] or [that version]?"*
4. Apply user's choice, drop the rejected mutation.

### Server-authoritative with reconciliation (rare)

If the server rejects due to a rule violation (e.g., habit streak calculation changed), treat the queued mutation as failed; surface it with the server's reason; user decides.

**Don't invent a general conflict resolver.** Ship per-table strategies as the feature needs them.

---

## 7. Sync Status UI

Users need to trust the queue. Surface state.

### Per-row indicator

Entries created offline render with a subtle badge until confirmed:

```tsx
{entry._pending ? (
  <span className="text-xs text-muted-foreground">
    <Cloud className="h-3 w-3 inline" /> Saving…
  </span>
) : null}
```

Remove when `onSuccess` replaces the optimistic row with the server row.

### Global sync indicator

A small pill in the header showing queue depth:

```tsx
{queueDepth > 0 ? (
  <Badge variant="secondary">
    {isOnline ? `Syncing ${queueDepth}` : `${queueDepth} pending`}
  </Badge>
) : null}
```

### Permanent failure surface

If a mutation hits `attempts >= 5` or a non-retryable error, show a modal or sticky banner with the full content and options: *Retry*, *Edit and retry*, *Discard*. Never silently drop user data.

---

## 8. Anti-Patterns

- **Queuing destructive mutations.** Deletes, unsubscribes, payments must be online-only. Offline UI for these is a "retry when connected" message, not a queue.
- **Using auto-increment IDs.** Client needs a stable ID before server confirmation. UUID or short-hash.
- **Single shared queue for all features.** Fine for small apps; becomes a footgun as app grows (one broken mutation blocks unrelated features). Consider per-table queues once you have >5 queueable tables.
- **Silent drops.** If you drop a mutation after 5 attempts without showing the user, you've broken the contract. Always surface.
- **Queue grows unbounded.** Enforce a soft cap (100 pending mutations) and surface: *"You've been offline a long time. Some entries are waiting to sync."*
- **Optimistic UI without rollback.** Every optimistic mutation must define `onError` rollback. Otherwise bad writes linger in the UI after reload.
- **Relying on `navigator.onLine` alone.** It reports the OS network state, not Supabase reachability. A device can be on hotel Wi-Fi (`online: true`) but unable to reach the internet. Always try the request; enqueue on failure.
- **No ordering guarantees.** If you parallelize the drain, a delete-then-create can arrive out of order and destroy data. Drain is strictly serial.
- **Mixing queued and non-queued mutations without clear UX.** If the user can't tell which actions survive offline and which don't, they'll lose trust in both.

---

## 9. Phase 4 Checklist for Queueable Features

When a feature has queueable mutations, the tech spec must answer:

- [ ] **Which mutation types queue** (name each; use the §1 table as the default map).
- [ ] **Schema changes** — every queued table has `client_mutation_id uuid UNIQUE`.
- [ ] **Conflict strategy per table** — LWW, user-picks, or server-authoritative.
- [ ] **Retry cap** and what happens at the cap (surface to user as … ).
- [ ] **Drain trigger points** — `online` event, focus event, app launch; anything else?
- [ ] **Queue depth UX** — per-row badge, global indicator, permanent-failure modal.
- [ ] **Optimistic update shape** — what fields are filled client-side (`created_at`, `id`)?
- [ ] **Cross-platform parity** — web uses IndexedDB, native uses AsyncStorage, contract in `shared/`.
- [ ] **Testing plan** — throttle to offline in DevTools, flush queue, verify replay.

Incomplete checklist blocks Phase 4 approval.

---

## 10. RAD Stack Mapping Summary

| Concern | Where it lives |
|---|---|
| Queue contract (abstract) | `shared/lib/offline-queue-contract.ts` |
| Web queue impl (IndexedDB via `idb`) | `src/lib/offline-queue.ts` |
| Native queue impl (AsyncStorage) | `mobile/src/lib/offline-queue-native.ts` |
| Sync worker (web) | `src/lib/sync-worker.ts`, started in `src/lib/auth.tsx` after session loads |
| Sync worker (native) | `mobile/src/lib/sync-worker.ts`, started in `mobile/src/app/_layout.tsx` |
| Network detection (web) | `navigator.onLine` + `online`/`offline` events + focus retry |
| Network detection (native) | `@react-native-community/netinfo` |
| Idempotency column | `client_mutation_id uuid UNIQUE` on every queueable table |
| Optimistic updates | TanStack `useMutation` `onMutate`/`onSuccess`/`onError` per feature |
| Queue depth signal | `usePendingMutations()` hook that wraps `peek(userId)` with a query refetch interval |
