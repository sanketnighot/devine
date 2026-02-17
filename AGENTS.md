# devine - Agent Operating Spec

This repository is building `devine` from scratch.

Use this file as the primary product and engineering guardrail when implementing features, copy, and architecture.

## Product North Star

- Deliver felt value within 60 seconds.
- Keep users safe, supported, and never shamed.
- Make progress feel real through small daily actions.
- Preserve privacy by default and explicit consent for sensitive data.

## Identity

- App name: `devine` (lowercase only).
- Platform: iOS + iPadOS.
- Primary audience: girls ages 14-28.
- Core promise: AI-first Glow Up OS with daily adaptive plans.

## Core Product Rules

- Outside-first progression:
  - Primary: physical / visual / aesthetic improvements.
  - Secondary: inside wellness signals as data coverage grows.
- Daily loop:
  - 3 Perfect Actions max per day.
  - Streak + calm celebration.
  - Fast check-in, not overwhelming workflow.
- Plan definition:
  - Plan = `CurrentStateEstimate + GoalTrajectory + NextBestActions`.
  - Plan is adaptive, not static.
  - Every adjustment declares severity:
    - `minor_tweak`
    - `resequence`
    - `pivot`

## Non-Negotiable UX Rules

- Photo is optional.
- If photo/evidence is missing, do not show a fake numeric Glow Score.
- Every screen must have a clear continue/back path.
- Paywall must be dismissible to limited mode.
- Do not loop paywall immediately after dismissal.

## Social Rules

- No public appearance rankings.
- No hotness leaderboards.
- No follower-count status systems.
- Use private circles, co-op challenges, and positive interactions.

## Safety and Privacy Rules

- Never use shaming or insecurity-driven language.
- No extreme body-change advice.
- No medical diagnosis claims.
- Treat under-18 users with stricter defaults.
- Minimize retention of sensitive media and never log sensitive payloads.

## AI Platform Rules

- Server-orchestrated AI only; no API keys on client.
- Strict JSON schema output required.
- Deterministic repair loop for invalid output.
- Safe fallback response required on repeated failure.
- Model routing and prompt versions controlled remotely.

## Engineering Guardrails

- Keep flows deterministic and testable.
- Prefer graceful degradation for:
  - offline states
  - StoreKit failures
  - missing remote config
  - missing optional integrations
- Build modularly:
  - `Features/`
  - `Core/`
  - `Services/`
  - `AI/`
  - `Widgets/`

## Source-of-Truth Companion Docs

- `WORLD_CLASS_UPGRADE_PLAN.md`
- `PLAN_WORLD_CLASS_SPEC.md`
- `TABS_100_REBUILD_SPEC.md`
- `MODEL_REGISTRY.md`
