# devine – Project Context for Claude Code

When working in this repo, follow **AGENTS.md** as the primary product and engineering guardrail. This file gives orientation and conventions; for full rules see `AGENTS.md` and `docs/`.

## About This Project

**devine** (lowercase only) is an AI-first “Glow Up OS” iOS/iPadOS app for girls 14–28. Swift/SwiftUI, Xcode 26.x, iOS/iPadOS 26+. Single-window SwiftUI app: onboarding → paywall (dismissible) → main tabs. Plan = `CurrentStateEstimate + GoalTrajectory + NextBestActions`; daily loop = max 3 Perfect Actions, explicit completion, streak, optional mirror check-in.

## Key Directories

- `devin/App/` – app root, `AppRootView`, `MainTabsView` (Home, Plan, Social, Profile)
- `devin/State/` – `DevineAppModel` (single `ObservableObject` for plan, actions, mirror, streak, paywall flags)
- `devin/Features/` – per-feature SwiftUI: Home, Plan, Social, Profile, Onboarding, Paywall, Mirror
- `devin/Core/` – design system (`DevineTheme`), storage, services, legal, extensions
- `devin/Models/` – DTOs and enums (plan, mirror, goals, actions)
- `docs/` – project info, tech stack, theme/design system, agent rules

## Architecture and Conventions

- **State:** One `DevineAppModel` created in `AppRootView` with `@StateObject`; pass as `@ObservedObject` where needed.
- **Navigation:** `NavigationStack` per tab; sheets for modals (actions, mirror check-in, legal); `navigationDestination(isPresented:)` for pushed flows.
- **UI:** Use semantic tokens from `DevineTheme.Colors` only (e.g. `bgPrimary`, `surfaceCard`, `textPrimary`, `ctaPrimary`). Do not use raw hex in feature code. See `docs/theme-and-design-system.md`.
- **New feature:** Add under `Features/<FeatureName>/`. New storage under `Core/Storage/`, new services under `Core/Services/`.
- **No:** API keys on client; shaming/insecurity language; numeric Glow Score without evidence; public ranking mechanics.

## Standards

- Modular layout: `App/`, `Core/`, `Features/`, `Models/`, `State/`.
- Flows deterministic and testable; graceful degradation for offline, StoreKit, missing config.
- Every screen: clear continue/back; one obvious primary action. Photo optional; paywall dismissible; no paywall re-loop.
- Before shipping: run build; smoke-test onboarding, paywall, home actions, plan; confirm score evidence gating. See `docs/agent-rules/implementation-checklist.md`.

## Common Commands

```bash
# Build (from repo root; adjust scheme if needed)
xcodebuild -scheme devin -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Source-of-Truth Docs

- **Product/eng guardrails:** `AGENTS.md`
- **Roadmap:** `WORLD_CLASS_UPGRADE_PLAN.md`
- **Tab behavior:** `TABS_100_REBUILD_SPEC.md`
- **Plan contract:** `PLAN_WORLD_CLASS_SPEC.md`
- **AI models:** `MODEL_REGISTRY.md`
- **Detail:** `docs/project-information.md`, `docs/tech-stack.md`, `docs/theme-and-design-system.md`, `docs/agent-rules/coding-agent-rules.md`

## Notes

- Rule priority: (1) `AGENTS.md`, (2) `docs/agent-rules/coding-agent-rules.md`, (3) feature/spec docs.
- Under-18 defaults must stay stricter; no medical diagnosis claims; minimize sensitive data retention and logging.

