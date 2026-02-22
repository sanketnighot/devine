# devine — UI/UX Redesign Plan

## The Problem

Looking at the current screenshots, the app feels like a **developer wireframe**, not a product for girls 14–28. Specific issues:

1. **Dark, flat, monotone cards** — everything is the same dark gray rectangle. No visual hierarchy, no breathing room, no delight.
2. **Default SwiftUI chrome** — `Form`, `List`, `Stepper` all use stock iOS styling. Feels like a Settings app, not a lifestyle brand.
3. **Zero personality** — no gradients, no illustrations, no micro-animations, no emotional hooks. Nothing says "this is for me."
4. **Information dump** — Plan tab shows 6 dense cards in a scroll. Too much text, not enough visual storytelling.
5. **No gamification feel** — streak is a single text line. Actions are a plain checklist. Completing things feels like checking off a todo list, not leveling up.
6. **Social is a blank form** — looks abandoned. Buttons do nothing and there's no visual promise of what's coming.
7. **Profile is a settings dump** — no user identity, no avatar, no glow progress summary.

## The Audience (Think Harder)

Girls 14–28 who want to glow up. They live on:
- **TikTok** — fast, visual, dopamine-optimized, vertical scroll
- **Instagram** — aesthetic grids, stories, polished visuals
- **Pinterest** — mood boards, aspirational imagery, soft palettes
- **BeReal / Locket** — intimate, authentic, friends-only
- **Duolingo** — streak obsession, playful mascot, celebration animations
- **Finch** — self-care through a cute pet, gentle gamification

What they respond to:
- **Visual reward** — things that look and feel beautiful to interact with
- **Progress that feels real** — not abstract numbers, but visual transformation
- **Micro-celebrations** — confetti, glow effects, haptic pulses, encouraging copy
- **Personalization** — "this knows me" moments
- **Social proof without toxicity** — seeing friends succeed together, not competing

What makes them leave:
- Boring / ugly / "adult" UI
- Feeling judged or shamed
- Too much reading / onboarding
- No immediate payoff
- Feeling like an afterthought (generic templates)

## Design Philosophy for Redesign

### 1. "Soft Power" Aesthetic
Not hyper-feminine pink. Not clinical white. A **warm, confident, elevated** aesthetic:
- Soft gradients (rose → peach → cream) as backgrounds, not flat colors
- Glassmorphism / frosted cards with subtle blur
- Generous white space and breathing room
- Typography hierarchy that uses weight + size, not just color dimming

### 2. "Dopamine Architecture"
Every interaction should feel rewarding:
- Action completion → ring fills, glow pulse, haptic, encouraging one-liner
- Streak milestone → celebration animation (confetti/sparkle, not childish)
- Score change → smooth animated counter + trend arrow
- Daily actions → progress bar that fills as you complete (not just checkmarks)

### 3. "Made for Me" Personalization
- Greeting uses time of day: "Good morning", "Almost there", "Wind down"
- Primary goal shown as a styled badge/chip at the top
- Color accent subtly shifts based on goal category (face → rose, skin → peach, energy → warm gold)

### 4. "One Glance" Information Design
- Each screen has ONE hero element and ONE primary action
- Supporting info is progressive disclosure (expandable, not always visible)
- Cards use size + visual weight to create hierarchy (not everything the same size)

---

## Screen-by-Screen Redesign Plan

### HOME TAB — "Your Daily Command Center"

**Current problems:**
- "Limited mode" banner at the top is the first thing you see (negative)
- Score section and primary action card compete for attention
- Actions list looks like a plain checklist
- Streak is an afterthought text line
- No greeting, no personality, no time-awareness

**Redesign:**

```
┌─────────────────────────────────┐
│ Good morning, you ✨            │  ← Time-aware greeting + goal badge
│ Face definition                 │
├─────────────────────────────────┤
│                                 │
│    ╭─────────────────────╮      │
│    │   ◯ ══════ 0/100    │      │  ← Hero: Glow Score ring (large)
│    │   No score yet       │      │     OR "Start your first check-in"
│    │   evidence-gated     │      │     with soft gradient background
│    ╰─────────────────────╯      │
│                                 │
│  ┌──────────────────────────┐   │
│  │ 🔥 AM hydration reset   │   │  ← PRIMARY ACTION CARD (hero-sized)
│  │ 2 min · Your next move  │   │     Gradient background, large tap target
│  │                          │   │     Tap → opens action player
│  │     [ Start Now ]        │   │
│  └──────────────────────────┘   │
│                                 │
│  Today's Progress               │
│  ▓▓░░░░░░░░  1/3               │  ← Visual progress bar (not just checks)
│                                 │
│  ┌────┐ ┌────┐ ┌────┐         │
│  │ ✓  │ │ 2  │ │ 3  │         │  ← Compact action pills (not full cards)
│  │done│ │4m  │ │3m  │         │     Tap to open, check when done
│  └────┘ └────┘ └────┘         │
│                                 │
│  ╭──────────────────────╮      │
│  │ 🔥 3-day streak      │      │  ← Streak card with flame animation
│  │ ████████░░ 3/5 goal  │      │     Visual progress toward weekly goal
│  ╰──────────────────────╯      │
│                                 │
│  📸 Progress timeline →         │  ← Compact link (not a full card)
└─────────────────────────────────┘
```

**Key changes:**
- **Time-aware greeting** at top with goal badge chip
- **Glow Score ring** as the hero — large, centered, gradient background. If no score: beautiful empty state with soft CTA, not a plain text block
- **Primary action is THE card** — big, gradient, impossible to miss. This is the "Start" moment
- **3 actions as compact pills** in a horizontal row (not a verbose list). Each shows status icon + title + time. Tap to expand.
- **Progress bar** — visual "1/3 done" bar that fills with gradient as you complete actions
- **Streak** — visual bar toward weekly goal (5/7), flame icon with subtle glow animation
- **Upgrade banner** → move to bottom as a subtle pill, not the first thing you see. Or hide entirely if dismissed once.
- **Mirror entry** stays in toolbar but add a subtle pulse/glow when no check-ins exist yet

### ACTION PLAYER SHEET — "The Micro-Moment"

**Current problems:**
- Plain text dump with a button at the bottom
- No visual energy, no timer feel, no progress feedback

**Redesign:**
- **Full-width gradient header** with action title in large bold
- **Circular timer visualization** — even though it's self-paced, show estimated time as a ring
- **Step-by-step instructions** — break long instructions into numbered micro-steps if possible
- **"Mark as Done" button** — large, gradient, with satisfying haptic + checkmark animation on tap
- **Completion celebration** — brief glow/pulse effect + encouraging one-liner ("Tiny win. Keep going.") before auto-dismiss

### PLAN TAB — "Your Adaptive Blueprint"

**Current problems:**
- 6 dense text cards in a scroll. Feels like a developer dashboard.
- "CurrentStateEstimate", "GoalTrajectory", "NextBestActions" — these are system labels, not user language
- Everything is the same visual weight

**Redesign:**

```
┌─────────────────────────────────┐
│ Your Plan                       │
│ Face definition · Updated today │
├─────────────────────────────────┤
│                                 │
│  ╭──────────────────────────╮  │
│  │  HERO: Score + Trajectory │  │  ← Combined card: Score ring on left,
│  │  ◯ 72  │  4–7 weeks     │  │     trajectory range on right
│  │         │  ████░ 74%     │  │     Confidence as a subtle bar
│  │  "Solid baseline.        │  │     One-line interpretation
│  │   Small daily actions    │  │
│  │   will move this up."    │  │
│  ╰──────────────────────────╯  │
│                                 │
│  This Week                      │
│  ┌────┬────┬────┬────┬────┐    │  ← Weekly calendar strip
│  │ M  │ T✓ │ W✓ │ T  │ F  │    │     Shows completion per day
│  └────┴────┴────┴────┴────┘    │     Today highlighted
│                                 │
│  Today's Actions                │
│  (same compact pills as Home)   │
│                                 │
│  ┌──────────────────────────┐  │
│  │ Plan Stability           │  │  ← Collapsible section
│  │ Theme locked for 5 more  │  │     "Theme locked" with countdown
│  │ days · minor_tweak       │  │     Severity as colored dot
│  └──────────────────────────┘  │
│                                 │
│  ▾ Evidence Log (2 entries)     │  ← Collapsed by default
│                                 │     Expandable accordion
└─────────────────────────────────┘
```

**Key changes:**
- **Merge Score + Trajectory** into one hero card (they're related, showing them separately wastes space)
- **Replace system labels** with human language: "This Week" not "NextBestActions", "Evidence Log" not "EvidenceLedger"
- **Weekly calendar strip** — visual dots/checks for each day of the week. Shows consistency at a glance.
- **Collapsible sections** — Stability and Evidence are important but secondary. Collapse by default, expand on tap.
- **Reduce card count** from 6 to 3 visible sections (hero, weekly strip, actions). Rest is progressive disclosure.

### SOCIAL TAB — "Glow Together"

**Current problems:**
- Stock SwiftUI `Form` with `Stepper`. Looks like a developer test page.
- Buttons do nothing. No visual promise.
- No empty state design.

**Redesign:**

```
┌─────────────────────────────────┐
│ Glow Together                   │
├─────────────────────────────────┤
│                                 │
│  ╭──────────────────────────╮  │
│  │   👯‍♀️                      │  │  ← Beautiful empty state illustration
│  │   "Better together"      │  │     (SF Symbol composition or custom)
│  │                          │  │
│  │   Start a circle with    │  │
│  │   your closest 3–8      │  │
│  │   friends. Stay          │  │
│  │   consistent together.   │  │
│  │                          │  │
│  │   [ Create Your Circle ] │  │  ← Primary gradient CTA
│  │   Join with invite code  │  │  ← Secondary text link
│  ╰──────────────────────────╯  │
│                                 │
│  ╭──────────────────────────╮  │
│  │  🏆 Glow Challenges      │  │  ← Teaser card for challenges
│  │  "7-day consistency      │  │
│  │   challenge. Win as      │  │
│  │   a team."               │  │
│  │                          │  │
│  │  Coming with your first  │  │
│  │  circle.                 │  │
│  ╰──────────────────────────╯  │
│                                 │
│  Safety promise                 │
│  No rankings · No comparison    │  ← Subtle footer reassurance
│  Private by default             │
└─────────────────────────────────┘
```

**Key changes:**
- **Beautiful empty state** — not a blank form. An inviting illustration + warm copy that makes you want to invite friends
- **Remove Stepper** — member count (3–8) should be set during circle creation flow, not shown upfront as a bare control
- **Visual hierarchy** — one primary CTA (Create Circle), one secondary (Join), one teaser (Challenges)
- **Safety reassurance** at the bottom — reinforce the "no rankings, private by default" promise

### PROFILE TAB — "Your Glow Identity"

**Current problems:**
- Generic settings list. No user identity.
- No avatar, no name, no progress summary.
- "Limited mode" is just a lock icon label.

**Redesign:**

```
┌─────────────────────────────────┐
│ Profile                         │
├─────────────────────────────────┤
│                                 │
│  ╭──────────────────────────╮  │
│  │  ╭───╮                   │  │  ← Profile header card
│  │  │ 👤│  Hey, you ✨      │  │     Avatar placeholder (gradient circle)
│  │  ╰───╯                   │  │     Goal badge + streak badge
│  │  Face definition          │  │
│  │  🔥 3-day streak         │  │
│  │  📅 Joined Feb 2026      │  │
│  ╰──────────────────────────╯  │
│                                 │
│  ┌ Subscription ────────────┐  │
│  │ ⭐ Limited mode           │  │  ← Styled card, not a plain list row
│  │ Upgrade to unlock your   │  │     Gradient border for upgrade CTA
│  │ full adaptive plan       │  │
│  │ [ Upgrade → ]            │  │
│  └──────────────────────────┘  │
│                                 │
│  Account                        │
│  ┌──────────────────────────┐  │
│  │  Continue with Apple     │  │  ← Grouped card with styled rows
│  │  Continue with Google    │  │
│  └──────────────────────────┘  │
│                                 │
│  App                            │
│  ┌──────────────────────────┐  │
│  │  Terms of Service    →   │  │
│  │  Privacy Policy      →   │  │
│  └──────────────────────────┘  │
│                                 │
│  #if DEBUG                      │
│  Developer                      │
│  ┌──────────────────────────┐  │
│  │  Unlock all flows   [⊘]  │  │
│  └──────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Key changes:**
- **Profile header card** — gradient background, avatar placeholder (gradient circle with initial or icon), goal badge, streak, join date
- **Subscription as a styled card** — not a plain list. If limited mode: warm upgrade prompt with gradient border. If subscribed: calm confirmation.
- **Grouped sections** with subtle headers instead of flat `List` rows

### ONBOARDING — "The First 60 Seconds"

**Current approach works** structurally (4 steps, back button, progress bar) but needs:
- **Gradient backgrounds** per step (not flat solid)
- **Goal cards** should have subtle icons/illustrations, not just text labels
- **Photo step** — add a soft illustration of a phone camera with overlay guide
- **Preview step** — if no score, show a beautiful "Your plan is ready" card with a subtle shimmer/loading effect, not just plain text

### MIRROR CHECK-IN SHEET

**Current approach works** (Form with tags, image picker, note) but:
- **Tag selection** should be colorful chips/pills, not a plain list of text buttons
- **Image preview** should be larger with rounded corners and a subtle shadow
- **"How are you feeling?"** section should feel like a mood picker, not a settings list

---

## Design System Upgrades Required

### 1. New Color Tokens Needed

```swift
// Gradient pairs for backgrounds
static let gradientPrimary: [Color]     // rose → peach (for CTAs, hero cards)
static let gradientBackground: [Color]  // cream → soft lavender (for screen bg)
static let gradientCard: [Color]        // white → faint blush (for elevated cards)

// Goal-specific accent tints
static let goalFace: Color              // warm rose
static let goalSkin: Color              // soft peach
static let goalBody: Color              // warm coral
static let goalHair: Color              // golden amber
static let goalEnergy: Color            // warm gold
static let goalConfidence: Color        // soft plum
```

### 2. New Components Needed

| Component | Purpose |
|-----------|---------|
| `GradientCard` | Card with gradient background + optional border glow |
| `ActionPill` | Compact horizontal action status indicator |
| `ProgressRing` | Animated ring with gradient stroke + glow |
| `StreakFlame` | Animated flame icon with subtle pulse |
| `GoalBadge` | Colored chip showing current goal |
| `TimeGreeting` | "Good morning" / "Good afternoon" / "Wind down" |
| `CelebrationOverlay` | Confetti/sparkle for milestones |
| `WeekStrip` | 7-day calendar strip with completion dots |
| `MoodChip` | Colorful selectable tag pill for mirror check-in |
| `EmptyStateView` | Reusable beautiful empty state with illustration + CTA |
| `ShimmerModifier` | Loading shimmer effect for placeholder states |

### 3. Motion & Haptics System

| Trigger | Animation | Haptic |
|---------|-----------|--------|
| Action completed | Ring fill + checkmark morph + green pulse | `.success` (light) |
| All 3 actions done | Progress bar fills + celebration overlay | `.success` (medium) |
| Streak milestone (3, 7, 14, 21, 30) | Flame grows + sparkle burst | `.success` (heavy) |
| Score updated | Counter animates up/down + trend arrow | `.selection` |
| Sheet appears | Spring-damped slide up | `.impact(style: .light)` |
| Tab switch | Crossfade (no haptic) | None |

### 4. Typography Refinement

Currently using default SF Pro weights. Add:
- **Rounded variant** for display numbers (score, streak count) — SF Rounded for a softer feel
- **Consistent hierarchy**: `.largeTitle` for screen titles, `.title2.bold()` for card headers, `.headline` for labels, `.subheadline` for descriptions

---

## Implementation Order

### Phase 1: Design System Foundation (Do First)
1. Expand `DevineTheme` with gradient tokens, goal colors, and new semantic tokens
2. Build reusable components: `GradientCard`, `ProgressRing`, `GoalBadge`, `TimeGreeting`, `ActionPill`, `WeekStrip`, `EmptyStateView`, `MoodChip`
3. Add haptic feedback utility
4. Add animation helpers (celebration overlay, shimmer modifier)

### Phase 2: Home Tab Redesign
1. Add time-aware greeting + goal badge header
2. Redesign Glow Score section — large centered ring with gradient bg, or beautiful empty state
3. Redesign primary action card — gradient hero card with single "Start Now" CTA
4. Replace action list with compact horizontal pills + progress bar
5. Redesign streak section — flame animation + visual weekly progress bar
6. Move upgrade banner to bottom or hide after dismissal
7. Add completion haptics and micro-celebrations

### Phase 3: Action Player Redesign
1. Gradient header with large title
2. Timer ring visualization
3. Animated completion with encouragement copy
4. Haptic on "Mark as Done"

### Phase 4: Plan Tab Redesign
1. Merge Score + Trajectory into hero card
2. Add weekly calendar strip
3. Replace system labels with human language
4. Make Stability and Evidence sections collapsible
5. Reduce visual clutter — fewer visible cards, more progressive disclosure

### Phase 5: Social Tab Redesign
1. Beautiful empty state with illustration + warm copy
2. Single primary CTA (Create Circle) + secondary (Join)
3. Challenge teaser card
4. Safety reassurance footer
5. Remove Form/Stepper pattern entirely

### Phase 6: Profile Tab Redesign
1. Add profile header card (avatar placeholder, goal, streak, join date)
2. Restyle subscription section as a prominent card
3. Group settings into styled sections with icons
4. Improve visual hierarchy

### Phase 7: Onboarding & Mirror Polish
1. Gradient backgrounds per onboarding step
2. Goal cards with icons/illustrations
3. Mirror tag selection as colorful mood chips
4. Larger image preview area

---

## What NOT to Change

- **Navigation structure** — 4 tabs is correct per the spec
- **Core data flow** — `DevineAppModel` as single state source stays
- **Score gating** — no fake score without evidence (keep this)
- **Privacy language** — all privacy/safety copy is good
- **Feature scope** — this is a UI/UX revamp, not a feature addition

## Success Criteria

After this redesign, the app should:
1. Pass the **"screenshot test"** — if you screenshot any screen, it looks like a premium product you'd share on Instagram
2. Pass the **"3-second test"** — within 3 seconds of opening any tab, you know what to do next
3. Pass the **"dopamine test"** — completing an action feels satisfying, not just transactional
4. Pass the **"audience test"** — a 17-year-old girl would not say "this looks like a boring app"
5. Pass the **"consistency test"** — every screen feels like it belongs to the same premium brand
