---
name: expo-native-reference
description: Official React Native and Expo documentation map, plus supplemental library docs (NativeWind, FlashList, Reanimated, TanStack Query, etc.), environment requirements, and EAS/Router vocabulary for RAD mobile work (mobile/, shared/). Use when working on Expo, React Native, native UI libraries, EAS, Router, SDK alignment, or local tooling.
---

# Expo and React Native — official reference for RAD

Use this skill to **route questions to the right official docs** and to remember how native work fits the RAD pipeline. It does not replace repo-specific rules.

## Authority order (always)

1. **`.cursor/rules/mobile.mdc`** — prohibitions, NativeWind rules, Radix → @rn-primitives mapping, patterns for this codebase.
2. **`.cursor/agents/mobile-developer.md`** — Foundation vs Feature mode steps, commits, quality gates.
3. **This skill** — canonical URLs (platform + libraries), system requirements, and when to read which chapter.

If this skill and `mobile.mdc` disagree on **how to write code**, `mobile.mdc` wins. If the question is **which Expo SDK API or EAS command applies**, use the official links below for the SDK version in `mobile/package.json`. For **third-party** libraries, prefer the library’s current docs — versions must match `mobile/package.json` / lockfile.

---

## How native work runs in RAD (no `/mobile` command)

- **Shell + providers + auth + first dev build:** Mobile Developer via **`/foundation`** (after web foundation), see `.cursor/commands/foundation.md`.
- **Per-feature screens:** Mobile Developer via **`/feature [name]`** — **Step 2b — Mobile**, see `.cursor/commands/feature.md`.
- **`pwa-then-native` Phase B:** **`/native-init`** once (workspace + shared extraction + Expo scaffold), then **`/foundation` / `/feature`** as in `.cursor/commands/native-init.md`.
- **Web stays in `src/`**; **native stays in `mobile/`**; **`shared/`** holds cross-platform types, validation, Supabase factory, hooks consumed by both.

---

## React Native (Meta) — concepts and prerequisites

| Topic | URL |
| --- | --- |
| Introduction, prerequisites (JS; React helps), how the doc set works | [Introduction · React Native](https://reactnative.dev/docs/getting-started) |
| Why use a framework; Expo as recommended path | [Environment setup](https://reactnative.dev/docs/environment-setup) |
| Views, native components, core building blocks | [Core Components and Native Components](https://reactnative.dev/docs/intro-react-native-components) |

---

## Expo — hub, toolchain, routing, shipping

| Topic | URL | RAD note |
| --- | --- | --- |
| Documentation home | [Expo Documentation](https://docs.expo.dev/) | Primary doc set for `mobile/` |
| **Create project** — Node LTS, OS support (Windows: PowerShell / [WSL 2](https://expo.fyi/wsl)), `create-expo-app`, **SDK templates** (`--template default@sdk-*`) | [Create a project](https://docs.expo.dev/get-started/create-a-project/) | Align new scaffolds with `mobile/package.json` Expo SDK |
| Simulators, devices, Expo Go vs dev client | [Set up your environment](https://docs.expo.dev/get-started/set-up-your-environment/) | |
| File-based routes, deep links, `expo start` workflow | [Introduction to Expo Router](https://docs.expo.dev/router/introduction/) | Routes live under `mobile/src/app/` |
| Custom native code, beyond Expo Go | [Development builds](https://docs.expo.dev/develop/development-builds/introduction/) | Matches EAS **development** profiles in foundation flows |
| EAS overview | [Expo Application Services](https://docs.expo.dev/eas/) | Also [expo.dev/eas](https://expo.dev/eas) |
| Cloud compile + sign | [EAS Build](https://docs.expo.dev/build/introduction/) | |
| Store upload automation | [EAS Submit](https://docs.expo.dev/submit/introduction/) | |
| OTA JavaScript/asset updates | [EAS Update](https://docs.expo.dev/eas-update/introduction/) | |
| Browser playground (optional) | [Expo Snack](https://snack.expo.dev/) | |

---

## When to open which doc

- **Metro errors, config plugins, specific `expo-*` module APIs** → versioned reference for the **same SDK** as `mobile/package.json`.
- **Navigation layouts, tabs, modals, typed routes** → [Expo Router](https://docs.expo.dev/router/introduction/) + [Router basics](https://docs.expo.dev/router/basics/core-concepts).
- **“Works in Expo Go but not in production”** → [Development builds](https://docs.expo.dev/develop/development-builds/introduction/).
- **TestFlight / Play Console / credentials** → [EAS Submit](https://docs.expo.dev/submit/introduction/) and store guides linked from EAS docs.

---

## Human onboarding (longer checklists)

Tables and account-level setup for Tech Leads also appear in **`RAD-GUIDE.md`** under **React Native and Expo** and **Expo documentation**.
