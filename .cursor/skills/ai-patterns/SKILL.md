---
name: ai-patterns
description: LLM integration patterns on the RAD stack — streaming, cost accounting, prompt management, agent UX, idempotency and fallback. Read this during /phase4 when a feature triggers the "AI / LLM integration" complexity signal, and during /feature when building LLM-backed screens. Not an agent — a knowledge base the Tech Lead and Frontend/Backend Developers consult.
disable-model-invocation: true
---

# AI Integration Patterns — RAD Knowledge Base

RAD is built for **AI-powered B2C and B2B2C apps** that help people with life and work. Almost every feature wave will touch an LLM call. This skill encodes the patterns that work on the RAD stack (Supabase Edge Functions + TanStack React Query + React SPA + optional Expo) so the Tech Lead and developers don't have to re-derive them per feature.

**When to read this:**
- During `/phase4` when the complexity scan flags **AI / LLM integration** (streaming, agent loops, cost metering, or LLM-driven workflows).
- During `/feature [name]` when a screen shows LLM output (chat, generation, analysis, summarization).
- When adding a new model (Claude, GPT, Gemini, or any OpenRouter-routed model — **the transport is always OpenRouter**, RAD does not install provider SDKs directly).

**What this skill does NOT cover:**
- Model selection or prompt engineering itself (that's a product question, not an architecture one).
- Fine-tuning or training pipelines (out of scope for RAD's target app class).
- Vector DB / embeddings for large-scale RAG (if the app needs >100k documents, consider pushing search to an external service — see `architecture/SKILL.md` §2).

---

## 1. LLM Streaming — The Core Pattern

Most AI-powered UX benefits from streaming: tokens arrive progressively, the user sees the model thinking, and perceived latency drops from "seconds of nothing" to "instant feedback."

### Architecture

```
Browser (React)
  │  1. POST /functions/v1/chat  { threadId, message }
  │     Authorization: Bearer <user JWT>
  ▼
Supabase Edge Function (Deno)
  │  2. Verify JWT, check rate limit, load thread context from Postgres
  │  3. Stream from OpenRouter (OpenAI-compatible API, stream: true)
  │  4. Write each token to response body as Server-Sent Event
  │  5. On completion: persist assistant message + record usage row
  ▼
Browser (React)
  │  6. fetch() with ReadableStream → parse SSE frames → setState(tokens)
  │  7. On stream close: react-query invalidates thread list query
```

### Edge Function skeleton (streaming)

```typescript
// supabase/functions/chat/index.ts
// All LLM calls route through OpenRouter (OpenAI-compatible API).
// Do not install @anthropic-ai/sdk or other provider SDKs — one transport, one billing path.
import OpenAI from 'npm:openai';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const OPENROUTER_BASE_URL = 'https://openrouter.ai/api/v1';
const MODEL = 'anthropic/claude-opus-4-7';  // OpenRouter model slug — provider/model

Deno.serve(async (req) => {
  const { threadId, message } = await req.json();

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response('Unauthorized', { status: 401 });

  // Rate limit BEFORE calling the model — see §3
  const allowed = await checkRateLimit(supabase, user.id);
  if (!allowed) return new Response('Rate limit exceeded', { status: 429 });

  const client = new OpenAI({
    apiKey: Deno.env.get('OPENROUTER_API_KEY')!,
    baseURL: OPENROUTER_BASE_URL,
    defaultHeaders: {
      'HTTP-Referer': Deno.env.get('APP_URL') ?? '',  // OpenRouter attribution
      'X-Title': Deno.env.get('APP_NAME') ?? 'rad-app',
    },
  });

  const stream = await client.chat.completions.create({
    model: MODEL,
    stream: true,
    stream_options: { include_usage: true },  // usage arrives in final chunk
    max_tokens: 2048,
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },  // loaded from prompts/ — see §4
      ...(await loadThread(supabase, threadId, user.id)),
    ],
  });

  const encoder = new TextEncoder();
  const body = new ReadableStream({
    async start(controller) {
      let fullText = '';
      let inputTokens = 0;
      let outputTokens = 0;

      try {
        for await (const chunk of stream) {
          const delta = chunk.choices[0]?.delta?.content;
          if (delta) {
            fullText += delta;
            controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text: delta })}\n\n`));
          }
          if (chunk.usage) {
            inputTokens = chunk.usage.prompt_tokens ?? 0;
            outputTokens = chunk.usage.completion_tokens ?? 0;
          }
        }

        // Persist + record usage AFTER stream completes — see §3
        await persistAssistantMessage(supabase, threadId, user.id, fullText);
        await recordUsage(supabase, user.id, MODEL, inputTokens, outputTokens);

        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ done: true })}\n\n`));
      } catch (err) {
        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ error: err.message })}\n\n`));
      } finally {
        controller.close();
      }
    },
  });

  return new Response(body, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
});
```

### React client skeleton (streaming)

```typescript
// src/hooks/useStreamingChat.ts
export function useStreamingChat(threadId: string) {
  const [streaming, setStreaming] = useState('');
  const [isStreaming, setIsStreaming] = useState(false);
  const abortRef = useRef<AbortController | null>(null);
  const qc = useQueryClient();

  async function send(message: string) {
    abortRef.current = new AbortController();
    setIsStreaming(true);
    setStreaming('');

    try {
      const res = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/chat`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${(await supabase.auth.getSession()).data.session?.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ threadId, message }),
        signal: abortRef.current.signal,
      });

      if (!res.ok) throw new Error(await res.text());
      if (!res.body) throw new Error('No response stream');

      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });

        const frames = buffer.split('\n\n');
        buffer = frames.pop() ?? '';

        for (const frame of frames) {
          if (!frame.startsWith('data: ')) continue;
          const payload = JSON.parse(frame.slice(6));
          if (payload.text) setStreaming((s) => s + payload.text);
          if (payload.error) throw new Error(payload.error);
          if (payload.done) qc.invalidateQueries({ queryKey: ['thread', threadId] });
        }
      }
    } finally {
      setIsStreaming(false);
      setStreaming('');
      abortRef.current = null;
    }
  }

  function stop() {
    abortRef.current?.abort();
  }

  return { send, stop, streaming, isStreaming };
}
```

### Key rules

- **TanStack Query does not cache the live stream.** Use `useState` for in-flight tokens; invalidate a `useQuery(['thread', threadId])` on completion so persisted history re-fetches.
- **Always abort on unmount** to prevent leaked connections and double-billing.
- **Persist the assistant message from the Edge Function** — not from the client. The client's stream may drop mid-way; the server is the source of truth.
- **Write the usage row in the same Edge Function invocation** that completes the stream. Atomicity matters for billing.

---

## 2. SSE vs WebSocket — Pick SSE

For almost every B2C AI app, **SSE (Server-Sent Events) is the right choice** over WebSocket:

| Dimension | SSE | WebSocket |
|---|---|---|
| Direction | Server → Client only | Bidirectional |
| Protocol | Plain HTTP + text | Upgrade handshake, binary |
| Reconnection | Browser handles automatically | Manual |
| Supabase Edge Function support | Native (ReadableStream) | Not in standard Edge Functions |
| Proxies and CDNs | Passes cleanly through Vercel/Cloudflare | Often problematic |

**Use WebSocket only when:** you need true bidirectional streaming (e.g., voice conversation with barge-in), or you need <50ms round-trip and are willing to run a dedicated WS server outside Supabase.

---

## 3. Token and Cost Accounting

LLM calls cost money. Unmetered usage in a B2C app kills margin fast. RAD apps must track per-user usage from day one.

### Schema

```sql
-- Usage log — append-only, one row per LLM call
CREATE TABLE llm_usage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider text NOT NULL DEFAULT 'openrouter',  -- transport — always 'openrouter' in RAD
  model text NOT NULL,                           -- OpenRouter slug: 'anthropic/claude-opus-4-7', 'openai/gpt-4o', 'google/gemini-2.5-pro'
  input_tokens int NOT NULL,
  output_tokens int NOT NULL,
  cost_usd numeric(10, 6) NOT NULL,    -- computed server-side from a rate table
  feature text NOT NULL,               -- 'chat', 'summarize', 'generate-image-caption'
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX llm_usage_user_created ON llm_usage (user_id, created_at DESC);

-- Rate table — prices per million tokens, updated as providers change pricing
CREATE TABLE llm_pricing (
  model text PRIMARY KEY,
  input_usd_per_mtok numeric(10, 6) NOT NULL,
  output_usd_per_mtok numeric(10, 6) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

RLS: users can read their own `llm_usage`, can insert nothing (Edge Function uses service role). Admin dashboard reads all rows.

### Rate limits

Two kinds, both enforced in the Edge Function before calling the provider:

1. **Per-window rate limit** — e.g., 20 messages / 5 min / user. Prevents runaway loops on the client or abuse.
2. **Monthly cost cap** — e.g., $1/user/month for free tier. Triggers paywall or model downgrade when hit.

```typescript
async function checkRateLimit(sb, userId: string): Promise<boolean> {
  const { count } = await sb
    .from('llm_usage')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('created_at', new Date(Date.now() - 5 * 60 * 1000).toISOString());
  return (count ?? 0) < 20;
}
```

### Credit-based metering (if app monetizes LLM usage directly)

If the app charges credits per call (common for B2C generative tools), extend the credit-billing pattern from `architecture/SKILL.md` §3:

- Compute credit cost **before** the call based on estimated tokens (input length + max_tokens).
- Debit optimistically in the same transaction as the `llm_usage` row.
- On stream abort/error, credit back the unused portion proportionally.

---

## 4. Prompt Management

Prompts are code. Treat them like code.

### Where prompts live

```
supabase/functions/
  chat/
    index.ts
    prompts/
      system.md             ← versioned in git
      examples/
        happy-path.json
        edge-case-empty-context.json
```

- **One prompt file per feature**, not one giant `prompts.ts` dict.
- **Markdown, not TypeScript template literals** — easier to diff, easier to review.
- **Load at cold start**, not per request: `const SYSTEM_PROMPT = await Deno.readTextFile('./prompts/system.md');`

### Changing a prompt

Prompt changes are PRs. Every prompt PR includes:
1. The old and new prompt side by side.
2. At least 3 example inputs and their old-prompt and new-prompt outputs.
3. A reason for the change (user feedback, eval result, cost reduction).

No live prompt editing from a database or admin UI in RAD. If the app needs A/B testing on prompts, do it via feature flag (`prompt_variant: 'v2'`) in the Edge Function, not via DB rows.

### Environment-specific overrides

If the dev Edge Function should use a cheaper model or a shorter system prompt, use env vars:

```typescript
const model = Deno.env.get('LLM_MODEL') ?? 'claude-opus-4-7';
const systemPromptPath = Deno.env.get('LLM_SYSTEM_PROMPT_PATH') ?? './prompts/system.md';
```

Never hardcode "if dev" branches in the prompt file.

---

## 5. Agent UX Patterns

B2C users judge AI UX harshly. The following are table stakes.

### Thinking indicator before first token

The user should see "thinking" immediately on submit, not a blank screen until the first token arrives. Show a skeleton or "..." until `streaming.length > 0`, then swap to streaming text.

### Progressive rendering

Render partial markdown as tokens arrive. Use a markdown library that tolerates incomplete input (`react-markdown` with `remark-gfm` handles most cases). Don't wait for stream close to render.

### Stop button

Always-visible during streaming. Calls `abortController.abort()`. The server-side persists what arrived so far — do not discard partial output on abort.

### Error + retry

On error:
- Show the partial response that arrived (don't discard).
- Offer "Retry" which re-sends the same user message with the assistant message stub removed.
- Offer "Edit and retry" which returns the user's last message to the input for editing.

### Citations / sources (RAG apps)

If the app uses retrieval, stream citations as a second SSE event type:

```typescript
data: {"text": "According to your notes "}
data: {"citation": {"source_id": "uuid", "title": "Meeting with Lan", "snippet": "..."}}
data: {"text": "you scheduled the call for..."}
```

Client renders citations as inline chips and lists them at the message bottom. Always clickable to open the source.

### Tool-use indicators (agentic apps)

If the model uses tools (calendar read, email send, DB query), show each tool call as a status line:

```
🔍 Searching your notes...
📅 Checking calendar for Thursday...
✏️  Drafting reply...
```

Each tool call is a separate SSE event (`{"tool": "calendar_read", "status": "running"}` → `{"tool": "calendar_read", "status": "done"}`).

---

## 6. Idempotency and Fallback

LLM calls fail. Network drops. Providers have outages. Plan for it.

### Retry on mid-stream failure

If the stream closes before completion:
- Do NOT retry automatically — the user may not want to pay twice.
- Offer a one-click "Continue from where it stopped" that sends the partial assistant response back to the model with a `<continue>` instruction.

### Model fallback

Maintain a fallback chain per feature:

```typescript
const MODELS = ['claude-opus-4-7', 'claude-sonnet-4-6', 'claude-haiku-4-5'];
for (const model of MODELS) {
  try {
    return await callModel(model, prompt);
  } catch (err) {
    if (isRetryableError(err)) continue;
    throw err;
  }
}
throw new Error('All models unavailable');
```

Log the fallback in `llm_usage.model` so you know when you're degrading UX.

### Cache for deterministic prompts

If the same user asks the same question with `temperature: 0`, cache by `hash(system + messages + model)`:

```sql
CREATE TABLE llm_cache (
  cache_key text PRIMARY KEY,  -- sha256(system + messages + model)
  response text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

TTL via a `pg_cron` job that deletes `created_at < now() - interval '30 days'`.

Don't cache creative/variable prompts — it defeats the point.

---

## 7. Safety

### Content moderation

- **Input moderation:** cheap pre-filter (banned words, obvious prompt-injection patterns) in the Edge Function. For user-generated content, call a moderation model via OpenRouter (e.g. `openai/omni-moderation-latest`) before the main call — same transport, same billing path.
- **Output moderation:** relevant only for public-facing content (shared pages, generated images). For private chat, skip.

### PII in logs

Never log full prompts or responses to standard server logs — they contain user PII. Log only: `user_id`, `feature`, `input_tokens`, `output_tokens`, `latency_ms`, `status`. Full conversations live in the messages table with RLS.

### Prompt injection

For RAD's typical app class (consumer life/work), prompt injection is **low risk** — the user IS the attacker and they're only attacking themselves. But if the app processes third-party content (emails, documents from contacts):
- Mark user content clearly in the prompt: `<user_input>...</user_input>`.
- Instruct the model to ignore instructions inside `<user_input>` tags.
- Do NOT give the model tools that take destructive actions (delete, send, pay) without explicit user confirmation for each action.

---

## 8. RAD Stack Mapping Summary

| Concern | Where it lives |
|---|---|
| LLM transport | `openai` npm package pointed at `https://openrouter.ai/api/v1` inside Edge Functions (Deno). Do not install provider SDKs (`@anthropic-ai/sdk`, `@google/generative-ai`, etc.) — one transport, one billing path. |
| System prompts | `supabase/functions/[feature]/prompts/*.md` |
| Secrets | Edge Function env: `OPENROUTER_API_KEY` — never in the client bundle. No per-provider keys. |
| Model selection | OpenRouter model slug (`anthropic/claude-opus-4-7`, `openai/gpt-4o`, `google/gemini-2.5-pro`) passed to `client.chat.completions.create({ model })` |
| Streaming transport | SSE via `ReadableStream` in Edge Function response |
| In-flight tokens (UI) | `useState` in a custom hook (not TanStack Query) |
| Persisted thread history | Supabase table + `useQuery(['thread', id])` — invalidated on stream done |
| Usage tracking | `llm_usage` table, written by Edge Function service-role client; `provider` always `openrouter`, `model` is the OpenRouter slug |
| Rate limits | Edge Function check against `llm_usage` before the OpenRouter call |
| Cost cap | Edge Function monthly cost SUM check, returns 402 Payment Required when hit |
| Cache | `llm_cache` table for deterministic calls |
| Fallback chain | Array of OpenRouter model slugs in Edge Function; logged in `llm_usage.model` |

---

## 9. Anti-Patterns

- **Calling LLM providers from the client.** Leaks API keys, bypasses rate limits, no usage tracking. Always go through an Edge Function.
- **Unmetered streaming.** A user with a broken client loop can drain $100 of credits in minutes. Rate limit + cost cap before every call.
- **TanStack Query caching the live stream.** TanStack is for resource state, not stream state. Use `useState` during the stream, invalidate on completion.
- **Storing prompts in Postgres.** Prompts are code; they belong in git, reviewed via PR, deployed via Edge Function releases.
- **Discarding partial responses on error.** Users hate losing "almost complete" output. Persist partials server-side; let the user decide to retry, keep, or edit.
- **Auto-retrying on mid-stream failure.** Double-billing without consent. Always confirm with the user.
- **Logging full conversations to server logs.** PII leak. Log metadata only.
- **One giant system prompt for all features.** Prompts should be per-feature, co-located with the Edge Function that uses them. Shared context goes in a small `shared/context.md` included by each prompt.

---

## 10. Phase 4 Checklist for AI Features

When the complexity scan flags a feature as AI / LLM integration, the tech spec for that feature must answer:

- [ ] **Streaming or single-shot?** If streaming, SSE pattern from §1.
- [ ] **Which model(s)?** Primary + fallback chain.
- [ ] **Rate limit and cost cap values.** Specific numbers, not "TBD."
- [ ] **Usage schema.** Does `llm_usage` need new fields (e.g., `feature_variant` for A/B test)?
- [ ] **Credit cost** (if monetized). Per-call debit strategy, partial refund on abort.
- [ ] **Prompt files.** Paths in `supabase/functions/`, with initial content committed.
- [ ] **Idempotency.** What happens on retry? Is there a `client_message_id` to deduplicate?
- [ ] **Fallback.** Which models, in what order. When to degrade silently vs when to surface to user.
- [ ] **Agent UX.** Thinking indicator, stop button, retry, citations (if RAG), tool-use indicators (if agentic).
- [ ] **Safety.** Is the content user-private or shareable? Is there third-party input that needs injection mitigation?
- [ ] **Cache.** Is this call deterministic enough to cache? TTL?

If any box is blank, the tech spec is incomplete — dispatch Research Agent Mode 2 to close the gap before approving Phase 4.
