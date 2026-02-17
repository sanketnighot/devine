# Plan Tab 100/100 Spec

This document defines the required behavior and UX for the `Plan` tab.

## Objective

Make the plan feel real, adaptive, and trustworthy in one glance.

## Plan Data Contract

Every active plan view must display:

- `CurrentStateEstimate`
  - score if confidence threshold is met
  - confidence value
  - plain-language interpretation
- `GoalTrajectory`
  - `min_weeks`
  - `likely_weeks`
  - `max_weeks`
  - confidence level
- `NextBestActions`
  - max 3 for current day
  - each action has rationale and expected effort
- `Stability`
  - theme lock duration
  - latest adjustment severity
- `EvidenceLedger`
  - evidence used (timestamped)
  - evidence missing
  - last refresh timestamp

## Adaptation Rules

- Do not thrash plan themes.
- Theme lock:
  - lock core theme for at least 7 days unless safety trigger.
- Adjustment severity:
  - `minor_tweak`: wording, sequence, or intensity changes.
  - `resequence`: reorder weekly focus.
  - `pivot`: strategic shift after repeated misses/plateau.

## Trigger Matrix

- New mirror check-in:
  - update current estimate
  - recompute next best actions
  - preserve weekly theme by default
- Repeated misses (>= 3 recent misses):
  - lower friction
  - potentially `resequence` or `pivot`
- Plateau detection:
  - if no progress over configured window, change lever not volume
- New integration signal:
  - increase confidence if signal quality improves

## Empty and Degraded States

- No evidence:
  - show no numeric score
  - show exact CTA to add first evidence
- Offline:
  - show cached plan
  - visible "Last updated" timestamp
- AI failure:
  - keep previous plan
  - mark refresh pending

## Acceptance Criteria

- Given no evidence, when user opens Plan, then no numeric score is displayed.
- Given evidence exists, when Plan loads, then CurrentStateEstimate and confidence are visible.
- Given repeated misses, when daily refresh runs, then action friction decreases without adding more actions.
- Given offline mode, when Plan opens, then cached content renders with last-updated label.
