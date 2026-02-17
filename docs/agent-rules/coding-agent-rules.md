# Coding AI Agent Rules

This file defines mandatory implementation behavior for coding AI agents working on `devine`.

## 1) Product Invariants (Do Not Break)

- App name remains `devine` (lowercase).
- Photo is optional.
- Do not show numeric Glow Score without evidence.
- Paywall must be dismissible to limited mode.
- Do not re-loop paywall immediately after dismissal.
- Never add public appearance ranking mechanics.

## 2) Architecture Rules

- Keep code modular under:
  - `App/`
  - `Core/`
  - `Features/`
  - `Models/`
  - `State/`
- New features go inside `Features/<FeatureName>/`.
- Shared logic should not live inside feature view files.
- Avoid giant files; split views/state/models early.

## 3) Safety and Language Rules

- Do not ship shaming language.
- Do not ship extreme body-change advice.
- Do not imply medical diagnosis.
- Under-18-safe defaults must remain stricter.

## 4) UI/UX Rules

- Every flow needs clear continue/back path.
- Primary action per screen must be obvious.
- Respect reduced motion and Dynamic Type.
- Avoid placeholder fake progress that appears "completed" without user action.

## 5) Data and Security Rules

- Do not add model API keys to client app code.
- Do not log raw sensitive payloads (photo urls, health details).
- Keep sensitive operations server-side.
- Use explicit consent for sensitive integrations.

## 6) State and Determinism

- Flows must be deterministic and testable.
- Handle offline and missing-config cases gracefully.
- No hidden side effects from unrelated UI events.

## 7) Testing Rules

For each significant change, agents must verify:
- Build passes via `xcodebuild`.
- Critical path still works:
  - onboarding
  - paywall
  - home daily loop
  - plan view
- No regression in evidence-gating for score display.

## 8) PR/Change Description Requirements

Every AI-generated change summary should include:
- files changed
- behavior changed
- safety/privacy impact
- test/build command and outcome

## 9) Escalation Rules for Uncertain Decisions

When unclear, agents should:
1. keep current product invariants,
2. choose safer option by default,
3. clearly list assumption in the final summary.
