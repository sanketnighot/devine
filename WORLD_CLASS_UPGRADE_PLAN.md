# World-Class Upgrade Plan

This is the execution roadmap for building `devine` from a fresh repo to production readiness.

## Phase 0 - Foundation (Week 1)

- Set up app shell:
  - Onboarding -> Paywall -> Main tabs routing.
  - Limited mode fallback when paywall is dismissed.
- Establish design token baseline:
  - color roles
  - typography scale
  - spacing scale
  - haptic intents
- Add deterministic state container for:
  - goal
  - daily actions
  - streak
  - score evidence

## Phase 1 - Credible Core Loop (Weeks 2-3)

- Implement Home loop:
  - single primary CTA ("Start next action")
  - explicit action player
  - no auto-complete behavior
- Implement score credibility guardrail:
  - no numeric score unless evidence exists
- Add mirror check-in flow:
  - optional
  - private-by-default
  - supportive, non-judgmental output
- Implement streak behavior:
  - timezone-safe day boundary
  - one increment per day

## Phase 2 - Plan Engine UX (Weeks 3-4)

- Build Plan tab around:
  - CurrentStateEstimate
  - GoalTrajectory (min/likely/max + confidence)
  - NextBestActions
  - Evidence ledger
  - Stability policy (theme lock + adjustment severity)
- Add plan history timeline with adjustment records.
- Add offline cache + last-updated indicators.

## Phase 3 - Monetization + Trust (Weeks 4-5)

- Implement StoreKit 2 subscription flow:
  - product loading
  - purchase
  - restore
  - entitlement checks
- Ensure paywall behavior:
  - early placement after aha moment
  - dismissible to limited mode
  - no immediate re-loop after dismissal
- Embed in-app legal screens for Terms and Privacy.

## Phase 4 - Social MVP (Weeks 5-6)

- Build Support Circles:
  - private groups
  - member limits
  - invite flow
- Build co-op Glow Challenges:
  - group check-ins
  - no ranking mechanics
- Add moderation primitives:
  - report
  - block
  - auto-hide for reporter

## Phase 5 - AI Platform Hardening (Weeks 6-8)

- Move all AI generation server-side.
- Add schema validation and deterministic repair loop.
- Add prompt registry and model routing through remote config.
- Add observability:
  - schema pass rate
  - latency by workflow
  - fallback rate

## Phase 6 - Launch Readiness

- QA matrix for:
  - offline
  - permission denial
  - locale changes
  - reduced motion
  - large text
- App Review readiness:
  - subscription disclosures
  - restore purchases
  - privacy labeling
  - age rating updates
- Rollout:
  - phased release
  - crash alerts
  - conversion/retention dashboards
