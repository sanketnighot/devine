# Tech Stack

This document defines the current and planned stack for `devine`.

## 1) Apple App Layer

- Language: Swift
- UI Framework: SwiftUI (primary)
- Project Tooling: Xcode 26.x
- Deployment Targets:
  - iOS 26+
  - iPadOS 26+
- Architecture style: modular SwiftUI app with feature-driven folders.

## 2) App Module Structure

- `App/`
  - app root, routing, and tab shell.
- `Core/`
  - shared utilities, legal surfaces, helpers.
- `Features/`
  - feature-specific screens and flows.
- `Models/`
  - domain entities and value types.
- `State/`
  - central observable app state and adaptation logic.

## 3) Backend (Planned/Primary)

- Firebase Auth
- Firestore
- Cloud Functions (or Cloud Run where needed)
- Firebase Storage
- Firebase Analytics
- Remote Config + A/B testing

## 4) AI Platform (Planned/Primary)

- Primary model family: Google Gemini (multimodal, server-orchestrated).
- Model abstraction required for future swapping.
- Prompt registry with versioning and controlled rollouts.
- Structured JSON outputs with schema validation and repair loop.

## 5) Data and Security Baseline

- Private-by-default data model.
- No client-side model API keys.
- Server-side orchestration for AI calls.
- Minimal sensitive logs.
- Explicit user consent for photos and health integrations.

## 6) Observability and Quality

- Crash monitoring: Firebase Crashlytics (planned).
- Analytics taxonomy for onboarding, paywall, daily loop, and social.
- AI quality tracking (schema pass rate, fallback rate, latency).

## 7) Testing Strategy

- Unit tests for domain/state logic.
- UI tests for critical flows:
  - onboarding
  - paywall behavior
  - daily action completion
  - mirror check-in
- Build validation via `xcodebuild` in CI.

## 8) Planned Integrations

- Apple Health (consent-first, read-scoped).
- Oura and additional integrations (future phase).
- Widgets and lock-screen surfaces (already part of roadmap/spec).
