# Theme and Design System

This file defines the visual direction for `devine`.

## 1) Design Intent

- Premium, soft, calm, high-trust.
- Feminine-leaning without stereotypes.
- Minimal, elegant, not crowded.
- Progress-first UX with clear hierarchy.

## 2) Brand Feel Keywords

- Soft confidence
- Polished clarity
- Warm refinement
- Supportive momentum

## 3) Core Color Scheme (Light Mode First)

Use these as semantic tokens, not hard-coded per screen.

### Primary Palette

- `rose_500` = `#E76D9A` (brand highlight)
- `peach_400` = `#F4A98A` (warm accent)
- `blush_200` = `#F9D7E3` (soft background accent)
- `cream_100` = `#FFF8F5` (surface warmth)
- `plum_700` = `#5D3550` (high-contrast premium text accent)

### Neutral Palette

- `neutral_950` = `#1B1A1F` (primary text)
- `neutral_700` = `#4F4D57` (secondary text)
- `neutral_500` = `#7A7884` (tertiary text)
- `neutral_200` = `#E9E6ED` (dividers)
- `neutral_100` = `#F5F3F8` (subtle surfaces)
- `white` = `#FFFFFF`

### Functional

- `success` = `#2EAD73`
- `warning` = `#D98A2C`
- `error` = `#C94A4A`

## 4) Tokenized Usage Rules

- Do not directly use palette hex in feature files.
- Map palette to semantic tokens:
  - `bgPrimary`, `bgSecondary`, `surfaceCard`
  - `textPrimary`, `textSecondary`, `textMuted`
  - `ctaPrimary`, `ctaPrimaryPressed`, `ctaSecondary`
  - `ringProgress`, `ringTrack`, `successAccent`
- Ensure dark mode equivalents maintain contrast and mood.

## 5) Typography

- Default family: SF Pro (system) for consistency and clarity.
- Hierarchy:
  - Display/Large Title for hero moments only.
  - Title for section anchors.
  - Body for core reading.
  - Footnote/Caption for metadata.
- Keep copy concise, direct, and supportive.

## 6) Motion + Haptics

- Motion style: subtle, premium, low-noise.
- Use short easing curves for progress transitions.
- Avoid noisy, gamey animations.
- Haptics:
  - action completion: light confirmation
  - streak milestone: soft success feedback

## 7) Component Style Guidance

- Cards: medium/large corner radii, soft contrast.
- Primary CTA: clear prominence, single action focus.
- Progress visuals: calm ring/trend lines, no aggressive colors.
- Icons: simple and readable at small sizes.

## 8) Accessibility Requirements

- WCAG-friendly contrast across all text states.
- Dynamic Type support for all key surfaces.
- Reduced Motion mode must disable celebratory animation bursts.
- Tap targets >= 44x44 points.

## 9) Tone Rules for UI Copy

- Supportive and clear.
- No shaming, no fear-based phrasing.
- No exaggerated claims.
- Prefer practical benefit statements over hype.
