# Battuta Design System

> **Brand idea — The Ictus.** *A battuta* is the score marking that tells
> musicians to return to strict time, following the conductor. The **ictus** is
> the exact instant a conductor's beat lands. Battuta's identity is built on
> that moment: a decisive gesture that lands precisely, in stage-amber light.

Import everything from one place:

```dart
import 'package:battuta/app/design_system/design_system.dart';
```

---

## 1. Brand mark

| Asset | Widget | Notes |
|---|---|---|
| Mark | `BattutaMark(size:, progress:)` | Baton downbeat → amber **ictus** dot → rebound. `progress` 0–1 draws it on. |
| Wordmark | `BattutaWordmark(height:)` | Mark + lowercase `battuta`, tight tracking. |
| Launch intro | `BrandIntro(child:)` | ~1.4 s one-shot: stage light warms, baton draws, ictus lands, curtain lifts. Non-blocking; skipped under reduced motion. |

**Usage.** Keep the ictus amber and the baton in ink (`brand.ink`). Never
recolor the ictus or put the mark on an amber fill. The minimum size is 16 pt.

## 2. Color (unchanged palette)

All colors come from the existing `AppTheme` constants. `BattutaBrand`
(a `ThemeExtension`) maps them to semantic roles for each brightness:

| Role | Dark | Light |
|---|---|---|
| `canvas` | `slateBackground #1A1C20` | `pearlBackground #F8F9FA` |
| `card` | `slateSurface #24272C` | `pureWhiteSurface #FFFFFF` |
| `cardRaised` (pressed / nested) | `slateSurfaceLight` | `pearlSurfaceLight` |
| `border` | `slateBorder #3A3D44` | `pearlBorder #E1E4E8` |
| `ink` / `inkMuted` / `inkDim` | off-white / muted / dim | charcoal / muted / dim |
| `accent` | `amberAccent #E5A93C` | `amberAccent #E5A93C` |
| `accentInk` (amber text/icons) | `#E5A93C` | `amberAccentLightText #C7831C` |
| `accentWash` (selected states) | `amberMuted` 15 % | `amberMuted` 15 % |

```dart
final brand = BattutaBrand.of(context); // falls back safely without the extension
Container(decoration: brand.cardDecoration(pressed: isPressed));
```

`brand.stageLight` is a flat radial amber glow (no blur shadow) for hero
moments only: the intro and empty states.

## 3. Motion

Durations are named in musical units. **Never write a raw `Duration` for UI motion.**

| Token | Value | Use |
|---|---|---|
| `BattutaMotion.tick` | 120 ms | Press feedback, icon swaps, tints |
| `BattutaMotion.beat` | 220 ms | Indicators, toggles, content switches |
| `BattutaMotion.bar` | 360 ms | Page / tab transitions, list entrances |
| `BattutaMotion.phrase` | 720 ms | Choreographed sequences |
| `BattutaMotion.stagger` | 40 ms | Per-item delay (max 8 items) |

| Curve | Feel | Use |
|---|---|---|
| `downbeat` `Cubic(0.2,0,0,1)` | Fast approach, decisive landing | **Default**: entering, settling |
| `upbeat` `Cubic(0.3,0,1,1)` | Lift-off | Exits |
| `rebound` `Cubic(0.34,1.36,0.64,1)` | Small confident overshoot | Selection, success, release |
| `legato` `Cubic(0.4,0,0.2,1)` | Even | Neutral repositioning |

**Rules**
- Wrap durations in `BattutaMotion.resolve(context, …)` so they collapse to zero
  when the OS *Reduce Motion* setting is on.
- Animations must be **finite**. Never use repeating loops in standard UI (they
  also break `pumpAndSettle` in tests).
- No ink ripples. Press feedback is `BattutaPressable` (scale dip + haptic).

### Motion primitives

| Widget | Behaviour |
|---|---|
| `BattutaPressable` | Scale 0.975 on press (`downbeat`), springs back (`rebound`), selection haptic, keyboard activation, button semantics. `builder:` exposes the `pressed` state. |
| `BattutaEntrance(index:)` | Fade + 12 pt lift on first build, staggered by index. |
| `BattutaPageTransitionsBuilder` | Push: slide 6 % + fade in; previous page recedes to 98 % / 60 %. Android, desktop and web. iOS/macOS keep Cupertino for swipe-back. |
| `battutaTabPage` | Fade-through (98.5 % → 100 %) for top-level tab switches. |

## 4. Spacing, radii, breakpoints

- **Space** (4-pt grid): `xxs 2 · xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · xxxl 48`. Minimum touch target is **44 pt**.
- **Radius**: `xs 6` tags · `sm 10` buttons/inputs/key tiles · `md 14` cards · `lg 20` sheets/dialogs · `pill` FAB, nav spotlight, tag pills.
- **Breakpoint**: `BattutaBreakpoints.rail = 840`. At or above it the shell uses a side rail.

## 5. Signature components

### Stage navigation
`StageNavigationBar` (compact) / `StageNavigationRail` (≥ 840 pt, with the
brand mark). One amber **spotlight** pill glides between destinations
(`bar`, `downbeat`). Icons swap outline → filled with `rebound`, and labels
sharpen to w600 in `accentInk`. Each item is ≥ 44 × 44 and announced as
*selected*.

### Stage card (`SongCard`, setlist card)
A flush `card` surface with a 1 px `border` and radius `md`.
- **Leading tile** (52 × 52, `accentWash` + amber hairline) holds the most
  scannable fact: the song's **key**, or the setlist's song count.
- Title w600 in `ink`, subtitle in `inkMuted`, metadata as icon readouts with
  tabular figures, tags as outlined pills.
- Press: `BattutaPressable`, with the surface tinting to `cardRaised`.

### Stage empty state
`StageEmptyState(icon:, title:, message:, actions:, tone:)`: a stage-light glow,
the icon in a bordered circular spot, and title, message and actions rising in
tempo. Pass `tone: colorScheme.error` for error states.

## 6. Do / Don't

| ✅ Do | ❌ Don't |
|---|---|
| Use `BattutaBrand.of(context)` roles | Hard-code hex values in features |
| Use motion tokens + `resolve()` | `Duration(milliseconds: 300)` literals |
| Use borders for hierarchy | Elevation / drop shadows |
| Keep amber for primary action, selection and live cues | Use amber as decoration |
| Wrap flexible children (`Expanded`, `Wrap`) | Use fixed-width rows that can overflow |

## 7. Adoption status

| Area | Status |
|---|---|
| Theme, tokens, brand extension | ✅ |
| App shell (bar / rail), tab and page transitions, launch intro | ✅ |
| Repertoire (cards, empty states, staggered lists) | ✅ |
| Song detail / editor, Setlist detail, Team, Live, Settings | ⏳ Inherit theme and transitions; migrate custom widgets to `BattutaPressable`, `StageEmptyState` and `brand.*` roles next |

The pre-existing codebase has ~80 raw hex colors, ~110 `Colors.*` uses and
~180 literal font sizes outside the theme. Migrate them to tokens as screens
are touched.
