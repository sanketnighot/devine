# UI/UX Implementation Plan — Missing Spec Features

All features below are specified in agentprompt.md but not yet built. This plan is UI/UX only — we build the views, components, and visual interactions using existing model data (or sensible mock data where the backend doesn't exist yet). No backend/AI work.

Everything must feel quirky, fun, engaging, addictive — aligned with the "Soft Power" aesthetic, Duolingo-level dopamine, and the girls 14–28 audience.

---

## Phase 1: Milestone Countdown + Streak Enhancement

**Why first:** Tiny effort, huge dopamine payoff. The spec says "Next milestone countdown" on the dashboard. The `StreakCard` already exists — we just need to make it *exciting*.

### 1A. Add milestone countdown to StreakCard

**File:** `devin/Core/DesignSystem/Components/StreakFlame.swift`

Edit `StreakCard` to add a milestone countdown line below the progress bar:

- Define milestone thresholds: `[3, 7, 14, 21, 30, 50, 100]`
- Compute `nextMilestone` = first threshold > current `streakDays`
- Compute `daysToGo` = `nextMilestone - streakDays`
- Show below the progress bar:
  - If `daysToGo > 0`: Text like **"3 more days to your 7-day streak 🔥"** in `.caption` weight `.semibold`, `textSecondary` color
  - If user just *hit* a milestone (streakDays is exactly a milestone): show **"You hit 7 days! Legend."** in `successAccent` with a subtle scale-in animation
- The MiniProgressBar should now track progress toward the *next milestone* (not the fixed weekly goal of 5). So progress = `(streakDays - previousMilestone) / (nextMilestone - previousMilestone)`.

### 1B. Streak milestone celebration in HomeView

**File:** `devin/Features/Home/HomeView.swift`

- Add a check: if `model.streakDays` is exactly a milestone value AND hasn't been celebrated this session
- Trigger `CelebrationOverlay` with milestone-specific copy:
  - 3 days: "3 days in! You're building momentum."
  - 7 days: "A full week! You're unstoppable."
  - 14 days: "Two weeks straight! This is becoming you."
  - 21 days: "21 days — they say that's a habit."
  - 30 days: "One month. You're literally glowing."
- Fire `DevineHaptic.streakMilestone` (heavy impact) instead of the regular tap haptic.

**Estimated scope:** ~30 lines changed across 2 files.

---

## Phase 2: Progress Trend Sparkline

**Why second:** The spec demands "progress stats + trend lines users care about" and "progress trends (week over week)." Currently there's zero visual sense of *direction* — just "here's your score now." A sparkline makes progress *feel real*.

### 2A. New component: TrendSparkline

**New file:** `devin/Core/DesignSystem/Components/TrendSparkline.swift`

A compact, elegant sparkline chart that shows score trend over time.

```
struct TrendSparkline: View
```

**Props:**
- `dataPoints: [Double]` — array of values (e.g. last 7 scores or last 14 days of completion %)
- `accentColor: Color` — gradient start color (default `ctaPrimary`)
- `height: CGFloat` — default 40
- `showTrendArrow: Bool` — default true

**Visual:**
- Smooth curved line (using `Path` with quadratic Bézier curves between points) filled below with a gradient fade (accent color at 0.2 opacity → clear)
- Line stroke: 2pt, gradient from `accentColor` to `accentColor.opacity(0.6)`
- If trend is up: small `↑` arrow pill at the trailing edge in `successAccent`
- If trend is down: small `↓` arrow pill in `warningAccent`
- If flat: no arrow
- Animate the line drawing on appear using `.trim(from:to:)` with a 0.6s easeOut — the line "draws itself" left to right. Addictive to watch.
- If fewer than 2 data points: show a dashed horizontal line with "More data soon" in `textMuted`

### 2B. Integrate sparkline into HomeView score hero

**File:** `devin/Features/Home/HomeView.swift`

In the `scoreHero` section, when `glowScore != nil`:
- Below the score ring + label, add the `TrendSparkline` showing the last 7 evidence events' implied scores
- Data source: `model.evidenceLedger` already has timestamped entries. We can derive a simple score history from the ledger (each event represents a scoring moment).
- If only 1 evidence event: show sparkline with single dot + "More data soon" state
- Keep it compact — sparkline is 40pt tall, sits inside the existing `SurfaceCard`

### 2C. Optional: Integrate into PlanView hero card

**File:** `devin/Features/Plan/PlanView.swift`

Add a smaller `TrendSparkline(height: 32)` in the hero card next to the trajectory info. This reinforces "you're heading in the right direction" on the Plan tab too.

**Estimated scope:** 1 new file (~100 lines), ~20 lines added to HomeView, ~15 lines added to PlanView.

---

## Phase 3: Weekly Recap View

**Why third:** The spec explicitly requires "Weekly recap and 'next week upgrade' moment" as a retention mechanic. This is a standalone view/sheet that appears once per week (Sunday or Monday) to celebrate the week and tease what's ahead.

### 3A. New view: WeeklyRecapSheet

**New file:** `devin/Features/Home/WeeklyRecapSheet.swift`

A full-screen sheet that feels like opening a gift. Presented automatically on the first app open of a new week (Monday), or accessible from a "Your week" card on Home.

**Visual flow (vertical scroll, each section animates in staggered):**

1. **Header**: "Your week in review ✨" in `.title2.bold()` with a gradient background card

2. **Stats row** — 3 circular stat cards in a horizontal row:
   - **Actions completed**: e.g. "9/12" with a mini `ProgressRing`
   - **Streak days this week**: e.g. "5" with `StreakFlame(size:20)`
   - **Check-ins**: count of mirror checkins this week

3. **Highlight moment** — A `GradientCard` with the week's best moment:
   - If streak milestone hit: "You hit a 7-day streak this week! 🔥"
   - If all actions done on any day: "You had a perfect day on Wednesday!"
   - If first check-in ever: "You started your mirror journey!"
   - Fallback: "You showed up. That's the hardest part."

4. **Mood summary** — If any mirror check-ins had mood tags this week: show the top 2-3 mood tags as `MoodChip` pills with count badges. "You felt 'Hydrated' 3 times this week."

5. **Next week teaser** — A `SurfaceCard` with:
   - "Next week's focus" header
   - The primary goal badge
   - One-line copy like "Keep the momentum. 3 actions/day, same glow energy."
   - A gradient CTA button: "Let's go →" that dismisses the sheet

6. **Footer**: "See you Monday ✨" in `textMuted`

**Entrance animation:** Each section fades in + slides up with staggered 0.15s delays. The stats row has a "counting up" animation where numbers increment from 0 to final value.

### 3B. Weekly recap trigger logic

**File:** `devin/Features/Home/HomeView.swift`

- Add `@AppStorage("last_recap_week")` tracking the ISO week number of the last shown recap
- On appear, check if current ISO week > stored week AND it's not the user's first week
- If so, present `WeeklyRecapSheet` and update the stored week
- Also add a "Your week" summary card on HomeView (below streak, above timeline link) that opens the recap manually:
  - Small `SurfaceCard` with "This week: 6/9 actions · 3 check-ins" + chevron
  - Tapping opens the same `WeeklyRecapSheet`

### 3C. Helper: Compute weekly stats

**File:** `devin/State/DevineAppModel.swift`

Add computed properties (no persistence changes needed):
- `var thisWeekCheckinCount: Int` — count of `mirrorCheckins` where `createdAt` is in the current ISO week
- `var thisWeekMoodTags: [String: Int]` — frequency map of mood tags from this week's check-ins

Note: Action completion history isn't persisted across days currently (it resets daily). For the recap, we can show the *current day's* completion + streak as proxy, and note that full weekly history tracking is a future backend feature. The recap still works because streaks and check-ins ARE persisted.

**Estimated scope:** 1 new file (~200 lines), ~30 lines in HomeView, ~15 lines in DevineAppModel.

---

## Phase 4: Widgets (WidgetKit Extension)

**Why fourth:** The spec dedicates an entire section (Section 9) to widgets. This is the single biggest retention lever — the user sees devine every time they look at their phone. But it requires a new Xcode target, which is why we do the simpler in-app work first.

### 4A. Create Widget Extension target

**Manual Xcode step** (cannot be done via code — user must add target in Xcode):
- File → New → Target → Widget Extension
- Product name: `devineWidgets`
- Bundle ID: `com.sanket.devin.widgets`
- Include Configuration App Intent: YES (for interactive widgets)
- This creates the `devineWidgets/` folder with boilerplate

### 4B. Shared data layer: App Group

Both the main app and widget need to read the same data.

- Create App Group: `group.com.sanket.devin`
- Add to both targets' entitlements
- Create a shared `WidgetDataProvider.swift` in a new `devin/Core/SharedData/` directory
- This provider reads from a shared JSON file (UserDefaults suite or file in the shared container):
  - `streakDays: Int`
  - `glowScore: Int?`
  - `todayActionsTotal: Int` (always 3)
  - `todayActionsCompleted: Int`
  - `primaryGoalName: String`
  - `primaryGoalIcon: String`
  - `nextActionTitle: String?`

- The main app writes this data every time `DevineAppModel` state changes (in `markActionDone`, `configure`, `rollOverIfNeeded`)

### 4C. Widget: "Today's Actions" (Home Screen, medium/large)

**New file:** `devineWidgets/TodayActionsWidget.swift`

**Small (systemSmall):**
- Circular progress ring showing `completed/total`
- Below: "1 of 3 done" in small text
- Background: `bgPrimary` gradient
- Deep link: opens the app to Home tab

**Medium (systemMedium):**
- Left: Progress ring (completed/total) + streak flame
- Right: List of 3 action titles, completed ones with checkmark in `successAccent`, pending ones in `textPrimary`
- Bottom: "Open devine →"
- Background: `screenBackground` gradient

### 4D. Widget: "Glow Score" (Home Screen, small)

**New file:** `devineWidgets/GlowScoreWidget.swift`

- Centered `ProgressRing`-style arc (simplified for widget — static, not animated)
- Score number in center: bold rounded font
- Below ring: goal name in small text
- If no score: "Start your glow" with empty ring
- Background: subtle gradient

### 4E. Widget: "Streak" (Lock Screen, circular/inline)

**New file:** `devineWidgets/StreakWidget.swift`

**Lock screen circular:**
- Flame icon + streak number
- Uses `AccessoryWidgetBackground()` for the system glass treatment

**Lock screen inline:**
- "🔥 7-day streak" as a single line

### 4F. Widget styling

All widgets must use the same color palette as the app. Since widgets can't import the full `DevineTheme`, create a lightweight `WidgetTheme.swift` in the shared code with the essential colors/gradients as static constants.

**Estimated scope:** New Xcode target (manual), 4-5 new Swift files, 1 shared data provider, entitlements changes. ~400 lines total.

---

## Phase 5: Settings / Preferences Screen

**Why fifth:** The spec says "world-class settings (privacy, integrations, language, notifications)." Currently Profile has legal links and account stubs but no actual preferences. This rounds out the app's completeness.

### 5A. New view: SettingsView

**New file:** `devin/Features/Profile/SettingsView.swift`

Pushed from ProfileView via a "Settings" row (gear icon). Organized in grouped sections:

**Section 1: "Notifications"**
- Toggle: "Daily reminder" (default on) — with time picker (default 8:00 AM)
  - Subtitle: "A gentle nudge to start your actions"
- Toggle: "Streak alerts" (default on)
  - Subtitle: "Don't lose your streak!"
- Toggle: "Weekly recap" (default on)
  - Subtitle: "Your Sunday glow-up summary"
- All toggles use `DevineTheme.Colors.ctaPrimary` tint
- Each toggle stores to `@AppStorage` (UI-only for now, no push notification backend)

**Section 2: "Integrations"**
- Row: "Apple Health" — shows connection status (connected/not connected)
  - Icon: `heart.fill` in `errorAccent`
  - Chevron
  - Tapping shows a sheet explaining benefits: "Connect Apple Health to make your plan 10x more accurate." with a gradient CTA "Connect" and "Not now" secondary
  - This is the "luxury precision upgrade" from the spec
- Row: "Oura Ring" — shows "Coming soon" badge in `textMuted`
  - Icon: `circle.dotted`
  - Disabled state

**Section 3: "Appearance"**
- Row: "App icon" → "Coming soon" badge
- Row: "Language" → shows current language, "Coming soon" badge
  - (Spec requires localization but we're not implementing multi-language yet — just the UI slot)

**Section 4: "Privacy & Data"**
- Row: "Manage my data" → chevron
- Row: "Export my data" → chevron
- Row: "Delete account" → red text, shows confirmation alert
- Footer: "Your data never leaves this device unless you choose to share it." in `textMuted` `.caption2`

All sections use `SurfaceCard` backgrounds with the same `profileRow()` pattern from ProfileView. Section headers use uppercase tracked `.caption` labels.

### 5B. Add Settings entry point in ProfileView

**File:** `devin/Features/Profile/ProfileView.swift`

Add a "Settings" row in the "App" section with `gear` icon, navigating to `SettingsView`.

### 5C. Apple Health connection sheet

**New file:** `devin/Features/Profile/HealthConnectSheet.swift`

A beautiful bottom sheet (`.presentationDetents([.medium])`) that sells the Apple Health integration:
- Gradient icon: `heart.fill` in a circle
- Headline: "Precision upgrade"
- Body: "Connect Apple Health to unlock weight trends, sleep insights, and activity data. Your plan gets smarter with every signal."
- 3 benefit rows with small icons (same pattern as paywall benefits)
- Gradient capsule CTA: "Connect Apple Health"
- Secondary: "Maybe later" text button
- Privacy note footer with lock icon
- On connect tap: just close the sheet for now (actual HealthKit integration is backend work)

**Estimated scope:** 2 new files (~250 lines total), ~10 lines in ProfileView.

---

## Phase 6: Subscores Display

**Why last:** The spec defines 8 subscores but the current model only has a single `glowScore: Int?`. Building the UI for subscores requires defining new model data. Since we're UI-only, we'll scaffold the view with mock data and make it ready for when the AI backend produces real subscores.

### 6A. New model: SubscoreEntry

**File:** `devin/Models/PlanModels.swift` (extend existing file)

```swift
struct SubscoreEntry: Identifiable {
    let id = UUID()
    let category: String        // e.g. "Face structure"
    let icon: String            // SF Symbol
    let score: Int              // 0–100
    let accentColor: Color
    let insight: String         // e.g. "Improving steadily"
}
```

### 6B. New view: SubscoreBreakdownView

**New file:** `devin/Features/Plan/SubscoreBreakdownView.swift`

A pushed view from PlanView's hero card (tap "See breakdown →").

**Layout:**
- Header: "Your glow breakdown" + overall score ring (small, 60pt)
- Grid of subscore cards (2 columns, LazyVGrid):
  - Each card is a `SurfaceCard` containing:
    - Small colored icon in a circle (using the subscore's accent color)
    - Category name in `.caption.bold()`
    - Score number in `.title3.bold()` with the accent color
    - One-line insight in `.caption2` `textSecondary`
    - Tiny `MiniProgressBar` showing the score/100
  - Cards animate in with staggered fade+scale on appear

**Mock data** (shown until real AI scoring exists):
- If `glowScore != nil`: show 4 subscores derived from the overall score (±5-10 random variance) for the categories relevant to the user's `primaryGoal`
- If `glowScore == nil`: show empty state — "Complete your first check-in to unlock your breakdown" with a gradient CTA

**Subscores relevant per goal** (subset of the spec's 8):
- `.faceDefinition`: Face structure, Skin clarity, Confidence
- `.skinGlow`: Skin clarity, Hydration proxy, Consistency
- `.bodySilhouette`: Body composition, Posture, Fitness energy
- `.hairStyle`: Hair health, Style coherence, Consistency
- `.energyFitness`: Fitness energy, Sleep recovery, Stress balance
- `.confidenceConsistency`: Confidence, Consistency, Stress balance

### 6C. Entry point from PlanView

**File:** `devin/Features/Plan/PlanView.swift`

In the hero card, add a tappable "See breakdown →" text below the score ring. NavigationLink to `SubscoreBreakdownView`.

**Estimated scope:** 1 new model struct (~10 lines), 1 new view file (~180 lines), ~10 lines in PlanView.

---

## Implementation Order Summary

| Phase | Feature | Files | Effort |
|-------|---------|-------|--------|
| 1 | Milestone Countdown + Streak Celebration | Edit 2 files | Small |
| 2 | Progress Trend Sparkline | 1 new + edit 2 | Small-Medium |
| 3 | Weekly Recap Sheet | 1 new + edit 2 | Medium |
| 4 | Widgets (WidgetKit) | New target + 5 files | Large (requires manual Xcode step) |
| 5 | Settings / Preferences | 2 new + edit 1 | Medium |
| 6 | Subscores Display | 1 new + edit 2 | Medium |

**Total new files:** ~10
**Total edited files:** ~7
**Phases 1-3 and 5-6 can be built immediately. Phase 4 requires a manual Xcode target creation step from the user.**

---

## Vibe Checklist (every feature must pass)

- [ ] **Screenshot test**: Would a 17-year-old screenshot this and share it?
- [ ] **Dopamine test**: Does completing/viewing this feel satisfying?
- [ ] **One-glance test**: Can you understand it in 3 seconds?
- [ ] **Brand test**: Does it feel like devine (warm, luxury, supportive)?
- [ ] **Not-boring test**: Is there at least one delightful animation or micro-interaction?
- [ ] **Safety test**: Nothing shaming, comparing, or insecurity-inducing?
