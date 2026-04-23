# NOTICE — audit skill

This skill is adapted from the Impeccable project's `/audit` skill.

## Attribution

- Original project: Impeccable — Design fluency for AI harnesses
- Source: https://github.com/pbakaus/impeccable
- Website: https://impeccable.style
- Upstream version imported: 2.1.1
- Upstream path: `.cursor/skills/audit/SKILL.md`
- License: Apache License, Version 2.0
- Import date: 2026-04-23

## License

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

## Adaptations

The original Impeccable `/audit` skill was adapted for RAD as follows:

1. **MANDATORY PREPARATION** rewritten to require RAD's own context files
   (`artifacts/docs/design-context.md` and `artifacts/docs/design-principles/`)
   instead of invoking `/impeccable teach`. RAD ships the reference library
   directly — see `artifacts/docs/design-principles/NOTICE.md` for upstream
   attribution of those files.

2. **Anti-Patterns dimension** rewired from "the impeccable skill" to RAD's
   own anti-pattern sources: `artifacts/docs/design-principles/` per-dimension
   slop tells and `.cursor/rules/design-system.mdc` §AI Slop Guard.

3. **Report format** extended with a `Reference cited` field per finding,
   anchoring each issue to a specific `design-principles/` file and section.

4. **Suggested command** field replaced with **Suggested owner**, routing
   fixes to RAD agents (`frontend-developer`, `backend-developer`,
   `qa-agent`) rather than Impeccable's slash-command catalog. RAD's Tech
   Lead dispatches agents; Impeccable's harness routes to commands.

5. **RAD integration** section added describing the two entry points
   (`/pre-handoff` Pass 6, or standalone) and the relationship to RAD's
   other QA skills (`/critique`, `/harden`, `/optimize`, `/visual-audit`).

6. **Output location** fixed at `artifacts/qa-reports/audit-[YYYY-MM-DD]-[scope].md`
   to integrate with RAD's artifact conventions.

7. The 5-dimension diagnostic scan (Accessibility, Performance, Theming,
   Responsive Design, Anti-Patterns), the 0-4 scoring rubric, the rating
   bands, and the P0-P3 severity format are preserved verbatim from the
   upstream skill.
