# Tabs 100 Rebuild Spec

This document defines what each tab must do to reach production quality.

## Home

### Primary Goal

Create momentum in under 10 seconds.

### Required Elements

- Top-level status:
  - evidence-backed score card or score-unavailable card
- Primary CTA:
  - "Start next action"
- 3 Perfect Actions list:
  - explicit completion flow
  - no auto-complete
- Streak card:
  - current streak
  - compact progress cue
- Mirror entry point:
  - always accessible

### Failure States

- If actions cannot refresh:
  - show cached actions
  - show refresh control
- If no evidence:
  - show guidance card
  - hide numeric score

## Plan

### Primary Goal

Explain why this is the right plan today.

### Required Elements

- CurrentStateEstimate
- GoalTrajectory range and confidence
- NextBestActions
- Stability metadata
- Evidence ledger

## Social

### Primary Goal

Drive adherence through belonging without toxic comparison.

### Required Elements

- Support Circles (private)
- Glow Challenges (co-op)
- No ranking UI
- Report + block affordances

### Safety Rules

- No public appearance scoring.
- No global leaderboards.
- No harassment-tolerant messaging defaults.

## Profile

### Primary Goal

Build trust and control.

### Required Elements

- Subscription status + manage/upgrade path
- Account linking entry points (Apple + Google)
- Terms and Privacy viewable in-app
- Language and notification controls
- Account delete and safety controls

## Cross-Tab Requirements

- Offline grace:
  - show last known good state
- Consistent state transitions:
  - deterministic, testable behavior
- Accessibility baseline:
  - Dynamic Type
  - VoiceOver labels
  - reduced motion fallback

