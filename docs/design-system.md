# Battuta Design System

> **Source of truth:** the *Battuta Screens* designs
> (claude.ai artifact "Battuta Screens"). This system implements their
> language in Flutter; when the two disagree, the designs win.

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

### Stage surfaces
| Widget | Use |
|---|---|
| `StageCard(onTap:, selected:, padding:)` | Every card. Flush `card` surface with a 1 px border. Pressable when `onTap` is set; `selected` draws the amber border (e.g. the next service). |
| `StageGroup(title:, children:, footer:)` | iOS-style inset group: a section header plus one bordered card with hairline-separated rows (Settings). |
| `StageSectionHeader(title:)` | Small bold tracked label. Copy is rendered **as written**, never force-uppercased, so localized strings stay correct. |
| `StageIconTile(icon:/label:, caption:, tone:, size:)` | Tinted anchor tile: song key, setlist count, running-order number, settings row icon. |

### Stage controls
| Widget | Use |
|---|---|
| `StageSegmentedControl<T>` | Mutually exclusive **modes** (Director / Follower). A solid amber thumb glides on `downbeat`; 52 pt tall (3 pt inset, so each segment is a 44 pt hit area). Material `SegmentedButton` stays for filters and settings (themed amber). |
| `StageStatusPill(label:, active:, tone:)` | Connection or live state. The dot pings **once** when it becomes active, with no infinite pulse. |

### Status roles
`brand.success` (stageGreen) · `brand.warning` (stageOrange `#FF9800`) ·
`brand.info` (stageBlue) · `brand.danger` (stageRed). `brand.wash(tone)` gives
the matching translucent fill for pills and banners.

### Signature moments
- **Prompter roll** (Live): the on-stage section rises into place as the
  previous one lifts away (`bar`, `downbeat` / `upbeat`).
- **Cue arrival**: a stage cue drops in with a one-shot amber flare.
- **Rolling stats** (Team): roster counts roll up once on appearance.
- **Animated key tile** (Song detail): the key springs in on `rebound`
  when you transpose.

## 6. Do / Don't

| ✅ Do | ❌ Don't |
|---|---|
| Use `BattutaBrand.of(context)` roles | Hard-code hex values in features |
| Use motion tokens + `resolve()` | `Duration(milliseconds: 300)` literals |
| Use borders for hierarchy | Elevation / drop shadows |
| Keep amber for primary action, selection and live cues | Use amber as decoration |
| Wrap flexible children (`Expanded`, `Wrap`) | Use fixed-width rows that can overflow |

## 7. Battuta Screens components

| Design element | Widget |
|---|---|
| Large root title (28/800, steps down to 22 before ellipsizing; 60pt header) | `StageAppBar.large(title:)` |
| Detail header (56pt, 20/700, no rule) | theme `appBarTheme` |
| Section label (13/700, tracked, uppercase) | `StageSectionHeader` (semantics keep original casing) |
| Grouped rows (52pt, full-width dividers) | `StageGroup` + `StageRow` |
| Key badge (amber wash, JetBrains Mono) | `StageKeyPill` |
| Stat tiles (22/800 value, 13 muted label, r16) | `StageStatTile` / `StageStatRow` |
| Segmented control (r12, thumb r9) | `StageSegmentedControl` |
| Filter pill (amber outline + wash when selected; 36 pt pill, 44 pt hit area) | `StageFilterPill` |
| Bottom action bar (52pt, r14 buttons) | `StageActionBar` (+ `.primary()` / `.secondary()`) |
| Add button (56pt, r16, icon only) | theme `floatingActionButtonTheme` + `FloatingActionButton` |

Fonts: Inter-style system sans (SF Pro on Apple), **JetBrains Mono** bundled
for keys and chords.

## 8. Adoption status

| Screen | Status |
|---|---|
| Repertoire | ✅ Matches design (scope pill, inline search, segmented, song rows with key pill, setlist date stamps) |
| Song detail | ✅ Matches design (stats, inline transpose, Add to setlist) + existing extras (sharing, practice audio, view modes, tags). No *Go live* until Live can open a song |
| Setlist detail | ✅ Matches design (date stamp, stats, order card) — *Avg BPM* replaces *Length/Players* (no data); no *Start live session* until Live can open a setlist |
| Settings | ✅ Matches design, including chart text size, prefer flats and keep screen awake; + workspace quota and licences |
| Team roster / Band calendar | ✅ Matches design (filters, grouped members, month grid) + existing scheduling features |
| Live | ◐ Header, LIVE badge, End and section chips match; the setlist-driven performance view is not built yet |
| Song editor, Scanner | ✅ Laid out to their designs (editor keeps dropdowns / stepper and expanded sections; scanner has no scan history) |
| Inbox, Discover, Profile | ◐ Built; minor differences (see `.pipeline/backlog.md`, "From 021") |
| Welcome, Sign in, Create account, Join, Organization profile / settings, Recurring schedules, Repeating service | ◐ Built; not yet laid out to their designs (see `.pipeline/backlog.md`, "From 021") |

### Design features not yet in the app
- Live: song N of M, beat meter, lyrics prompter, Previous / Cue / Next; Go live / Start live session entries.
- Join: invite preview; Sign in: username sign-in and server choice; Organization settings: usage bars.
- Repeating service: interval, weekday set and monthly-by-date rules.
- Lyrics in Merriweather (not bundled yet).

## 9. Previous adoption log

| Area | Status |
|---|---|
| Theme, tokens, brand extension, status roles | ✅ |
| Shell (bar / rail), transitions, launch intro | ✅ |
| Repertoire list, song detail, setlist detail | ✅ |
| Settings (inset groups) | ✅ |
| Live stage sync, stage cue banner, sync indicator | ✅ |
| Team roster and band calendar | ✅ |
| Song editor, scanner, notation toolbars, import / karaoke modals | ✅ Tokenized, no elevations |
| Music-notation painters (`staff_metrics`, `notehead_painter`) | Intentionally keep dedicated notation colors |
