/**
 * Compute a deterministic SHA-256 fingerprint from an input object.
 * Keys are sorted before hashing — order of input properties does not matter.
 * Use this to detect duplicate submissions before creating expensive jobs.
 *
 * Usage:
 *   const hash = await computeFingerprint({ birth_date: "1990-01-01", gender: "male" })
 *   // Insert into jobs.fingerprint_hash — UNIQUE constraint handles race conditions
 */
export async function computeFingerprint(
  inputs: Record<string, unknown>
): Promise<string> {
  const sorted = JSON.stringify(inputs, Object.keys(inputs).sort());
  const buf = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(sorted)
  );
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
