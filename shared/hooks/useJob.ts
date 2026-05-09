import { useEffect } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useSupabase } from "../api/supabase-context";

type JobStatus = "pending" | "processing" | "completed" | "failed";

interface Job {
  id: string;
  status: JobStatus;
  tier: "free" | "paid";
  input: Record<string, unknown>;
  output: Record<string, unknown> | null;
  error: string | null;
  created_at: string;
}

const TERMINAL = new Set<JobStatus>(["completed", "failed"]);

/**
 * Subscribe to a job by ID.
 * - Polls every 3s while status is non-terminal
 * - Self-cancels polling once status is completed or failed
 * - Realtime subscription pushes updates the moment the row changes
 */
export function useJob(jobId: string | null) {
  const supabase = useSupabase();
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ["jobs", jobId],
    queryFn: async () => {
      if (!jobId) return null;
      const { data, error } = await supabase
        .from("jobs")
        .select("*")
        .eq("id", jobId)
        .single();
      if (error) throw error;
      return data as Job;
    },
    enabled: !!jobId,
    refetchInterval: (query) => {
      const status = query.state.data?.status;
      if (!status || TERMINAL.has(status)) return false;
      return 3000;
    },
  });

  // Realtime subscription — push update the moment the row changes
  useEffect(() => {
    if (!jobId) return;
    const channel = supabase
      .channel(`job-${jobId}`)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "jobs",
          filter: `id=eq.${jobId}`,
        },
        (payload) => {
          queryClient.setQueryData(["jobs", jobId], payload.new);
        }
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [jobId, supabase, queryClient]);

  return query;
}
