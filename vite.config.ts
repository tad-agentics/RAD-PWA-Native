import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";
import tsconfigPaths from "vite-tsconfig-paths";

/** Split heavy vendors so chunks cache independently and initial parse stays smaller on mobile. */
function manualChunks(id: string) {
  if (!id.includes("node_modules")) return;
  // Rollup IDs may use backslashes on Windows — normalize before segment checks.
  const n = id.replace(/\\/g, "/");
  if (n.includes("@radix-ui")) return "radix-ui";
  if (n.includes("@tanstack")) return "tanstack";
  if (n.includes("@supabase")) return "supabase";
  if (n.includes("lucide-react")) return "icons";
  if (n.includes("motion") || n.includes("framer-motion")) return "motion";
  if (n.includes("react-router") || n.includes("@remix-run")) return "react-router";
  // Match the real `react` package only (`.../node_modules/react/...`), not loose `/react/`
  // (avoids odd substring matches). `react-dom` is a different folder: `react-dom/...`.
  if (
    n.includes("node_modules/react-dom") ||
    n.includes("node_modules/scheduler/") ||
    n.includes("node_modules/react/")
  )
    return "react-vendor";
  return "vendor";
}

// PWA — locked to vite-plugin-pwa (Workbox-based, battle-tested for Vite).
// /foundation wires the plugin into the plugins array below based on deployment mode.
// See artifacts/docs/handoff-contract.md and .cursor/commands/foundation.md Step 0.
// import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks,
      },
    },
  },
  plugins: [
    tailwindcss(),
    reactRouter(),
    tsconfigPaths(),

    // PWA plugin — uncomment during /foundation (mode ∈ pwa | pwa-then-native).
    // Locked config; do not change without updating handoff-contract.md + foundation.md.
    // VitePWA({
    //   registerType: "autoUpdate",
    //   manifest: false, // Use static public/manifest.json (written by Backend Foundation)
    //   workbox: {
    //     globPatterns: ["**/*.{js,css,html,ico,png,svg,woff2}"],
    //     navigateFallback: "/index.html",
    //     navigateFallbackAllowlist: [/^\/app/],
    //   },
    // }),
  ],
});
