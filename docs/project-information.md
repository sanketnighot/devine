# Project Information (Detailed)

## 1) Product Identity

- App name: `devine` (lowercase only).
- Platform: iOS + iPadOS.
- Product type: AI-first personal growth app ("Glow Up OS").
- Positioning: premium, supportive, private-by-default, and execution-focused.

## 2) Core Mission

`devine` helps users progress from current state toward 100/100 through adaptive, sustainable daily actions.

Primary order of focus:
- Outside (visual/aesthetic/physical presentation).
- Inside (wellness signals) as integrations and confidence improve.

## 3) Primary Audience

- Main audience: girls ages 14-28.
- UX expectation: high taste, minimal clutter, strong polish.
- Safety expectation: no shaming, no insecurity amplification, no harmful extremes.

## 4) Product Principles

- Feel value in under 60 seconds.
- Photo is optional.
- No fake precision: numeric Glow Score only with evidence.
- Daily loop must be lightweight and believable.
- Progress must be clear, motivating, and calm.
- Social must be non-toxic by architecture, not by policy text alone.

## 5) Core Experience Model

### A) Onboarding

- Lightweight, progressive, and trust-first.
- Request minimal inputs first: primary goal + optional evidence.
- Explain why each data input helps.
- No dead ends (always back/continue path).

### B) Scoring + Credibility

- Show Glow Score only when evidence exists.
- Show confidence and evidence context where possible.
- Never imply medical diagnosis.

### C) Plan Definition

Plan is not a static schedule.

Plan = `CurrentStateEstimate + GoalTrajectory + NextBestActions`

- CurrentStateEstimate: what we know now, with confidence.
- GoalTrajectory: range estimate (`min`, `likely`, `max`) and confidence.
- NextBestActions: max 3 core actions/day.

### D) Daily Loop

- "3 Perfect Actions" max per day.
- Explicit completion flow (no fake completion).
- Streak + subtle celebration.
- Next action should be obvious in one tap.

### E) Mirror Check-in (Optional)

- Optional daily check-in.
- Private by default.
- Used to adapt plan with supportive language.

## 6) Social and Multiplayer Constraints

Allowed:
- Private support circles.
- Co-op challenges.
- Positive accountability.

Not allowed:
- Appearance leaderboards.
- Public hotness ranking.
- Follower-count status hierarchy.

## 7) Monetization Constraints

- Early paywall is acceptable.
- Paywall must be dismissible to limited mode.
- Must not trap user in a paywall loop.
- Restore purchases must always be available.

## 8) Safety + Privacy Baseline

- Private by default.
- Explicit consent for photos and integrations.
- No shaming language.
- No extreme body-change recommendations.
- Under-18 defaults must remain stricter.
- Minimize sensitive data retention and logging.

## 9) Engineering and Architecture Goals

- Deterministic and testable flows.
- Graceful degradation for:
  - offline conditions
  - paywall/store failures
  - missing integrations
  - missing remote config
- Modular codebase (`App`, `Core`, `Features`, `Models`, `State`).

## 10) Current Source-of-Truth Specs in Repo Root

- `AGENTS.md`
- `WORLD_CLASS_UPGRADE_PLAN.md`
- `PLAN_WORLD_CLASS_SPEC.md`
- `TABS_100_REBUILD_SPEC.md`
- `MODEL_REGISTRY.md`
