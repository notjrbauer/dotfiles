---
paths:
  - "**/*.{ts,tsx,js,jsx,svelte,vue}"
---

# Frontend and TypeScript

Functionality and correctness first; modern, typed, accessible code; no legacy cargo-cult. Verify any version-specific claim against the primary source before citing it — pins rot. When a widely-repeated pattern is outdated, say so plainly and name what replaced it.

## Current idiom by framework
- **React 19**: Actions, `use()`, `useActionState`, `useOptimistic`, `useFormStatus`, `ref` as a prop, Server Components + Server Functions where the framework supports them (Next.js App Router, Waku). The React Compiler is production-usable — lean on it instead of hand-memoizing.
- **Svelte 5** with **runes** — `$state`, `$derived`, `$props`, `$effect`, `$bindable`. `export let` and top-level `$:` are legacy. SvelteKit for routing/SSR.
- **Vue 3.5** — Composition API + `<script setup>`, `defineModel`, `useTemplateRef`, reactive props destructure. Pinia for state, Nuxt for full-stack.
- **Solid** — true fine-grained signals (`createSignal`/`createMemo`/`createResource`), no VDOM, no dependency arrays. SolidStart for SSR.
- **Vite** (Rolldown-powered; `baseline-widely-available` default browser target, `environments` API) with Vitest riding on it.
- **TypeScript**: `satisfies`, `const` type params, template-literal types, discriminated unions. `strict: true`, `noUncheckedIndexedAccess`, `verbatimModuleSyntax`, `moduleResolution: "bundler"`. The Go-native TS 7 compiler is the answer when compile speed matters.
- **Node LTS**: native `fetch`/Undici, `--watch`, built-in test runner, native TS type-stripping — but Vitest/Playwright remain the real testing stack. ESM only; no new CommonJS.
- **Web platform (Baseline)**: `:has()`, container queries, native CSS nesting, cascade layers, `oklch()`, `text-wrap: balance/pretty`, subgrid, the **Popover API** and `<dialog>`, **View Transitions** (same-doc Baseline; cross-document shipping), scroll-driven animations. CSS **anchor positioning** is still uneven — feature-detect. Reach for the platform before a library.

## What separates expert from novice
- **TypeScript & ESM first.** Model domains with precise types; make illegal states unrepresentable. No `any` slipping through; `unknown` + narrowing at boundaries. Ship ESM, no default-export cults, tree-shakeable modules.
- **Framework-appropriate reactivity & data.** Signals in Solid/Svelte/Vue; in React, prefer derived state and Server Components/Actions over reflexive client state. Fetch on the server or in a proper data layer (TanStack Query, framework loaders, `createResource`), never a raw `useEffect` fetch. Kill request waterfalls with parallel loads and Suspense/streaming.
- **Forms** with native validation + progressive enhancement: React 19 Actions / `useActionState`, SvelteKit form actions, Vue `defineModel`. Uncontrolled-by-default; validate on the server too.
- **Routing** via the framework's router (App Router, SvelteKit, TanStack Router, Vue Router) with typed params, nested layouts, and loaders that parallelize data.
- **Performance = Core Web Vitals discipline.** Watch LCP/INP/CLS. Bundle discipline: measure before adding deps, code-split routes, lazy-load below the fold, `import()` heavy widgets, prefer platform CSS over JS. Server-render, stream, and hydrate selectively (islands where the framework offers it).
- **Accessibility is functionality.** Semantic HTML first; ARIA only to fill real gaps, never to paper over a `<div onClick>`. Keyboard operable, visible focus, labeled controls, correct roles, `prefers-reduced-motion`. Test with the keyboard and the accessibility tree.
- **Testing.** Vitest for units, Testing Library for component behavior (query by role/text, assert user-visible outcomes — not implementation), Playwright for e2e and cross-browser. Test behavior, not internals.

## Anti-patterns you refuse
`useEffect` as a data-fetching or derived-state tool; request waterfalls; `<div>` soup with click handlers; premature/duplicated client state that mirrors server data; hydration mismatches from non-deterministic render or reading `window` during SSR; hand-rolled memo noise the React Compiler makes moot; barrel files that wreck tree-shaking; `any`; class components and CJS in greenfield code; reaching for a 40kB library to do what `:has()` or the Popover API does natively.

## Verify
Match the framework, conventions, and tooling actually in use. Add a Vitest/Testing Library or Playwright test when it protects behavior. Run the project's typecheck/lint/test if available and report results. State assumptions and trade-offs briefly; give a recommendation, not a menu.

## Hand off
Security-first review before merge → `code-reviewer`. Profiling beyond routine CWV/bundle hygiene → `/perf`.
