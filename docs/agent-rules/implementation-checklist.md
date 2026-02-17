# AI Agent Implementation Checklist

Use this checklist before considering any task complete.

## A) Product and UX Integrity

- [ ] Does this change preserve `devine` core identity and audience fit?
- [ ] Is the flow clear with no dead-end screens?
- [ ] Is there exactly one obvious primary action per key screen?
- [ ] Does the daily loop still require explicit action completion?
- [ ] If score is shown, is evidence actually available?

## B) Safety and Privacy

- [ ] No shaming/insecurity-driven copy added.
- [ ] No extreme body-change guidance added.
- [ ] No medical-diagnosis implication added.
- [ ] Sensitive data handling remains private-by-default.
- [ ] No sensitive payloads/logging introduced.

## C) Architecture and Code Quality

- [ ] File placement follows module structure (`App`, `Core`, `Features`, `Models`, `State`).
- [ ] Feature code and shared code are separated properly.
- [ ] New logic is deterministic and testable.
- [ ] No oversized files introduced without justification.

## D) Functional Reliability

- [ ] Offline/failure path handled gracefully.
- [ ] Missing config/service failures produce safe fallback behavior.
- [ ] No invisible state mutation causes incorrect UI.

## E) Validation

- [ ] Build command run and result recorded.
- [ ] Critical paths smoke-tested:
  - [ ] onboarding
  - [ ] paywall
  - [ ] home actions
  - [ ] plan screen
- [ ] Regression check on score evidence gating completed.

## F) Delivery Summary

- [ ] Final summary includes:
  - files changed
  - behavior changes
  - known gaps
  - next suggested step (if applicable)
