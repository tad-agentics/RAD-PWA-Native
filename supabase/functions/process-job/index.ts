/**
 * process-job — triggered by DB webhook on INSERT to jobs table
 *
 * Wiring (set up in Supabase Dashboard → Database → Webhooks):
 *   Table: jobs
 *   Event: INSERT
 *   URL: {SUPABASE_URL}/functions/v1/process-job
 *   HTTP Method: POST
 *   Headers: Authorization: Bearer {SUPABASE_SERVICE_ROLE_KEY}
 *
 * Free/paid split:
 *   Paid jobs are processed first — check tier and route accordingly.
 *   At sub-10K DAU a single function handles both tiers sequentially.
 *   When paid latency degrades under free backlog: split into two webhooks
 *   (process-job-free, process-job-paid) with separate concurrency limits.
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

Deno.serve(async (req) => {
  const { record } = await req.json();
  const jobId: string = record.id;

  // Mark as processing
  await supabase
    .from("jobs")
    .update({ status: "processing" })
    .eq("id", jobId);

  try {
    // TODO: replace with actual LLM call
    // Load active workflow prompts
    const { data: workflow } = await supabase
      .from("workflows")
      .select("prompts")
      .eq("is_active", true)
      .single();

    const result = await runLLM(record.input, workflow?.prompts ?? {});

    await supabase
      .from("jobs")
      .update({ status: "completed", output: result })
      .eq("id", jobId);
  } catch (err) {
    await supabase
      .from("jobs")
      .update({ status: "failed", error: String(err) })
      .eq("id", jobId);
  }

  return new Response("ok");
});

async function runLLM(
  input: Record<string, unknown>,
  prompts: Record<string, unknown>
): Promise<Record<string, unknown>> {
  // Replace with actual implementation
  throw new Error("runLLM not implemented");
}
