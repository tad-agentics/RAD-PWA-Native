---
name: optimize
description: UI performance diagnostics across bundle size, rendering, animations, images, and load time. Generates a scored performance report with severity-tagged findings and remediation paths. Runs as part of /pre-handoff, or invoked standalone when the Tech Lead suspects perf regression. Flags issues for Tech Lead triage — mechanical fixes apply in-scope, design-layer rework routes back through new-feature loop.
disable-model-invocation: true
version: optimize-rad@1.0.0
upstream: impeccable/optimize@2.1.1
license: Apache 2.0 — see NOTICE.md
---

## MANDATORY PREPARATION

Before running this skill, confirm:

- `artifacts/docs/design-context.md` exists (Build Constraints section informs what's acceptable perf-wise)
- `artifacts/docs/design-principles/` exists (consult `responsive-design.md` for mobile perf context)
- The feature has been built and integrated (optimize runs on shipped code, not handoff code)
- `.cursor/rules/frontend.mdc` is loaded — RAD has existing performance rules (React Router v7 Vite config, TanStack Query caching, code-splitting conventions) that this skill's findings must respect

RAD-specific performance priors to anchor findings in:

- **Target mobile devices**: mid-tier Vietnamese Android phones (Xiaomi Redmi / Samsung A-series typical) on 4G
- **Budget**: LCP < 2.5s on 4G, TTI < 3.5s, bundle < 200KB initial JS
- **Cache strategy**: TanStack Query (see `.cursor/skills/caching-strategies/SKILL.md`) — query keys + `staleTime` discipline is how RAD avoids over-fetching
- **Vite + React Router v7 config**: route-level code splitting is built in — don't flag missing splits that the framework already handles

If any context is missing, halt and report.

## RAD scoping

This skill **flags performance issues** and scores them. It does **not auto-implement fixes** during Feature Mode (90% untouched rule). When a finding requires:

- **Mechanical fix** (add `loading="lazy"` to an image, replace `Animated` API with Reanimated on mobile, add `React.memo` to a frequently-rerendering list item): hot-fix in scope. Tech Lead approves; the fix is trivially implementable without design judgment.
- **Design-layer rework** (image is fundamentally too large and needs a different crop / format / art direction; the feature has a loading state that was never designed): route back through `/design new-feature [perf-name]` so the adapter produces the missing design work.
- **Framework config change** (Vite rollup settings, React Router prerender config): Tech Lead owns this; it's outside agent scope.
- **Defer** (the finding is real but the effort-to-impact ratio doesn't justify action this release): document in release notes.

**Never auto-implement non-trivial fixes.** If the fix requires more than a 2-line change or any design judgment, escalate.

### RAD perf baseline

Findings get compared against RAD's baseline, not Impeccable's generic thresholds:

| Metric | Budget | Baseline source |
|---|---|---|
| LCP (4G, mid-tier Android) | < 2.5s | Target for Vietnamese B2C market |
| TTI (4G, mid-tier Android) | < 3.5s | Same |
| Initial JS bundle | < 200KB gzipped | Vite + React Router v7 typical |
| Image total on LCP screen | < 500KB | Mid-tier phone memory pressure |
| Animations | 60fps (UI thread, not JS thread) | RN: Reanimated only. Web: transform/opacity only |
| Query `staleTime` discipline | All queries have explicit `staleTime` | TanStack Query hygiene from caching-strategies skill |

---

Identify and fix performance issues to create faster, smoother user experiences.

## Assess Performance Issues

Understand current performance and identify problems:

1. **Measure current state**:
   - **Core Web Vitals**: LCP, FID/INP, CLS scores
   - **Load time**: Time to interactive, first contentful paint
   - **Bundle size**: JavaScript, CSS, image sizes
   - **Runtime performance**: Frame rate, memory usage, CPU usage
   - **Network**: Request count, payload sizes, waterfall

2. **Identify bottlenecks**:
   - What's slow? (Initial load? Interactions? Animations?)
   - What's causing it? (Large images? Expensive JavaScript? Layout thrashing?)
   - How bad is it? (Perceivable? Annoying? Blocking?)
   - Who's affected? (All users? Mobile only? Slow connections?)

**CRITICAL**: Measure before and after. Premature optimization wastes time. Optimize what actually matters.

## Optimization Strategy

Create systematic improvement plan:

### Loading Performance

**Optimize Images**:
- Use modern formats (WebP, AVIF)
- Proper sizing (don't load 3000px image for 300px display)
- Lazy loading for below-fold images
- Responsive images (`srcset`, `picture` element)
- Compress images (80-85% quality is usually imperceptible)
- Use CDN for faster delivery

```html
<img 
  src="hero.webp"
  srcset="hero-400.webp 400w, hero-800.webp 800w, hero-1200.webp 1200w"
  sizes="(max-width: 400px) 400px, (max-width: 800px) 800px, 1200px"
  loading="lazy"
  alt="Hero image"
/>
```

**Reduce JavaScript Bundle**:
- Code splitting (route-based, component-based)
- Tree shaking (remove unused code)
- Remove unused dependencies
- Lazy load non-critical code
- Use dynamic imports for large components

```javascript
// Lazy load heavy component
const HeavyChart = lazy(() => import('./HeavyChart'));
```

**Optimize CSS**:
- Remove unused CSS
- Critical CSS inline, rest async
- Minimize CSS files
- Use CSS containment for independent regions

**Optimize Fonts**:
- Use `font-display: swap` or `optional`
- Subset fonts (only characters you need)
- Preload critical fonts
- Use system fonts when appropriate
- Limit font weights loaded

```css
@font-face {
  font-family: 'CustomFont';
  src: url('/fonts/custom.woff2') format('woff2');
  font-display: swap; /* Show fallback immediately */
  unicode-range: U+0020-007F; /* Basic Latin only */
}
```

**Optimize Loading Strategy**:
- Critical resources first (async/defer non-critical)
- Preload critical assets
- Prefetch likely next pages
- Service worker for offline/caching
- HTTP/2 or HTTP/3 for multiplexing

### Rendering Performance

**Avoid Layout Thrashing**:
```javascript
// ❌ Bad: Alternating reads and writes (causes reflows)
elements.forEach(el => {
  const height = el.offsetHeight; // Read (forces layout)
  el.style.height = height * 2; // Write
});

// ✅ Good: Batch reads, then batch writes
const heights = elements.map(el => el.offsetHeight); // All reads
elements.forEach((el, i) => {
  el.style.height = heights[i] * 2; // All writes
});
```

**Optimize Rendering**:
- Use CSS `contain` property for independent regions
- Minimize DOM depth (flatter is faster)
- Reduce DOM size (fewer elements)
- Use `content-visibility: auto` for long lists
- Virtual scrolling for very long lists (react-window, react-virtualized)

**Reduce Paint & Composite**:
- Use `transform` and `opacity` for animations (GPU-accelerated)
- Avoid animating layout properties (width, height, top, left)
- Use `will-change` sparingly for known expensive operations
- Minimize paint areas (smaller is faster)

### Animation Performance

**GPU Acceleration**:
```css
/* ✅ GPU-accelerated (fast) */
.animated {
  transform: translateX(100px);
  opacity: 0.5;
}

/* ❌ CPU-bound (slow) */
.animated {
  left: 100px;
  width: 300px;
}
```

**Smooth 60fps**:
- Target 16ms per frame (60fps)
- Use `requestAnimationFrame` for JS animations
- Debounce/throttle scroll handlers
- Use CSS animations when possible
- Avoid long-running JavaScript during animations

**Intersection Observer**:
```javascript
// Efficiently detect when elements enter viewport
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      // Element is visible, lazy load or animate
    }
  });
});
```

### React/Framework Optimization

**React-specific**:
- Use `memo()` for expensive components
- `useMemo()` and `useCallback()` for expensive computations
- Virtualize long lists
- Code split routes
- Avoid inline function creation in render
- Use React DevTools Profiler

**Framework-agnostic**:
- Minimize re-renders
- Debounce expensive operations
- Memoize computed values
- Lazy load routes and components

### Network Optimization

**Reduce Requests**:
- Combine small files
- Use SVG sprites for icons
- Inline small critical assets
- Remove unused third-party scripts

**Optimize APIs**:
- Use pagination (don't load everything)
- GraphQL to request only needed fields
- Response compression (gzip, brotli)
- HTTP caching headers
- CDN for static assets

**Optimize for Slow Connections**:
- Adaptive loading based on connection (navigator.connection)
- Optimistic UI updates
- Request prioritization
- Progressive enhancement

## Core Web Vitals Optimization

### Largest Contentful Paint (LCP < 2.5s)
- Optimize hero images
- Inline critical CSS
- Preload key resources
- Use CDN
- Server-side rendering

### First Input Delay (FID < 100ms) / INP (< 200ms)
- Break up long tasks
- Defer non-critical JavaScript
- Use web workers for heavy computation
- Reduce JavaScript execution time

### Cumulative Layout Shift (CLS < 0.1)
- Set dimensions on images and videos
- Don't inject content above existing content
- Use `aspect-ratio` CSS property
- Reserve space for ads/embeds
- Avoid animations that cause layout shifts

```css
/* Reserve space for image */
.image-container {
  aspect-ratio: 16 / 9;
}
```

## Performance Monitoring

**Tools to use**:
- Chrome DevTools (Lighthouse, Performance panel)
- WebPageTest
- Core Web Vitals (Chrome UX Report)
- Bundle analyzers (webpack-bundle-analyzer)
- Performance monitoring (Sentry, DataDog, New Relic)

**Key metrics**:
- LCP, FID/INP, CLS (Core Web Vitals)
- Time to Interactive (TTI)
- First Contentful Paint (FCP)
- Total Blocking Time (TBT)
- Bundle size
- Request count

**IMPORTANT**: Measure on real devices with real network conditions. Desktop Chrome with fast connection isn't representative.

**NEVER**:
- Optimize without measuring (premature optimization)
- Sacrifice accessibility for performance
- Break functionality while optimizing
- Use `will-change` everywhere (creates new layers, uses memory)
- Lazy load above-fold content
- Optimize micro-optimizations while ignoring major issues (optimize the biggest bottleneck first)
- Forget about mobile performance (often slower devices, slower connections)

## Verify Improvements

Test that optimizations worked:

- **Before/after metrics**: Compare Lighthouse scores
- **Real user monitoring**: Track improvements for real users
- **Different devices**: Test on low-end Android, not just flagship iPhone
- **Slow connections**: Throttle to 3G, test experience
- **No regressions**: Ensure functionality still works
- **User perception**: Does it *feel* faster?

Remember: Performance is a feature. Fast experiences feel more responsive, more polished, more professional. Optimize systematically, measure ruthlessly, and prioritize user-perceived performance.

---

## RAD integration

### Entry points

- **`/pre-handoff` Pass 9** (automatic) — runs after `/harden` (Pass 8)
- **Standalone** — Tech Lead invokes `/optimize [feature-or-screen]` when dogfooding or monitoring flags perf regression, or before high-traffic launch

### Output location

- `artifacts/qa-reports/optimize-[YYYY-MM-DD]-[scope].md`

### Output format

Scored report across 5 dimensions:

1. **Loading speed** — LCP, TTI, FCP measurements if available; route-level splitting; prerender config
2. **Rendering** — component rerender hotspots, missing memoization, layout thrashing, expensive selectors
3. **Animations** — JS-thread vs UI-thread animations (Reanimated on mobile; transform/opacity on web); jank detection
4. **Images** — lazy loading coverage, format choices (AVIF / WebP), width/height attributes, responsive srcsets
5. **Bundle size** — initial JS gzipped, unused imports, tree-shaking gaps, heavy dependencies

Each finding:

- **Severity** — P0 (blocks launch) / P1 (noticeable on target devices) / P2 (polish) / P3 (nice-to-have)
- **Measurement** — specific metric value vs RAD baseline
- **Location** — file + line number, or route + surface
- **Remediation path** — mechanical fix / new-feature loop / framework config change / defer

### Relationship to other QA skills

| Skill | Focus |
|---|---|
| `/audit` | Technical quality across 5 dimensions (a11y, perf, theming, responsive, anti-patterns) |
| `/critique` | UX design quality via persona sub-agents + Nielsen heuristics |
| `/harden` | Production-readiness gaps (edge cases, errors, i18n, empty states) |
| `/optimize` (this skill) | UI performance diagnostics with measurement-backed findings |

**`/audit` vs `/optimize` overlap:** `/audit` includes performance as one of its 5 dimensions scored 0-4. `/optimize` goes deeper — specific measurements, specific remediation paths, anchored in RAD's baseline. Run `/audit` for a broad quality read; run `/optimize` when perf is the specific concern or when `/audit`'s perf score came back ≤ 2.

See `.cursor/skills/caching-strategies/SKILL.md` for RAD's query-caching patterns — many perf findings reduce to "this query doesn't have a `staleTime` and the component is re-mounting" which is a caching-hygiene issue, not a code issue.

---

## Attribution

This skill is adapted from Impeccable's `/optimize`. See `NOTICE.md` for upstream attribution and license terms (Apache 2.0).