---
status: done
commit: (this commit)
base_sha: 0192598
rounds: 3 of 3
---
# 023: Perform a whole setlist with auto-scroll

**Goal:** Start Live from a setlist, a calendar service or a song and perform it end to end on one device, with
the sections in order, "Next" always visible and lyrics that scroll at the song's tempo.

## What changed
- **Entry points.** Setlist detail "Start live session" (disabled with a hint when the set is empty), the calendar
  service card "Go live" (when the event has a setlist) and song detail "Go live" open `/live/perform?setlist=` or
  `?song=`, a full-screen route declared before the shell so `/live/:sessionId` never matches it.
- **Plan.** `PerformancePlan` (domain) builds the songs in order with the setlist key override as transposition and
  the cues: sections by `orderIndex`, expanded by `repeatCount` and labelled "(i/n)". A song with no sections is one
  "Whole song" cue. A song missing on this device shows a "Not on this device" card you step past with Next.
- **Controller.** `PerformanceController`: song and cue index, next/previous across song boundaries, jump, play and
  pause, speed. `setPlan` keeps the current song by item id and only re-centres when the song or cue changed.
- **View.** `LivePerformancePage`: header "Song 1 of 3 · Way Maker · E", "Next: Coro" / "Next song: …", a section chip
  strip (current amber, next outlined), the chart (`ChordSectionCard`, now public) and a transport bar (icon-only
  Previous, Play/Pause with a 120 pt minimum width, Next / Finish, speed − / + shown as "♩ 68 · 100%"). At 840 pt
  and wider a setlist outline sits on the right. End asks for confirmation; the last song ends in "Set complete"
  with Restart / Close.
- **Auto-scroll.** `ScrollPace`: a section lasts its lyric lines × bars per line × bar seconds, with chord beats only
  as a lower bound (chords-only sections use their beats). A bar is `beats × 60 / BPM` (6/8 counts 2), and no
  tempo means 72 BPM. Speed comes from the scroll offset: the section whose span holds the reading line (30 % of
  the viewport, ramping down from the top) scrolls its span over its duration × the adjustment. Playback stops when
  the last section is consumed. Chip, Next and Previous keep playing; a manual drag pauses. With reduced motion the
  jumps aren't animated, but auto-scroll still runs.
- **Preferences.** Speed (50–200 %, 10 % steps) is remembered per song on the device. Settings has "Bars per chart
  line" (1 / 2 / 4) under chart text size.
- **Live tab.** The demo content is gone (fake section bar, "Trigger Test Cue", hard-coded way-maker cue). The tab
  starts with "Start a session" (upcoming services and setlists). 022's host card, nearby list and join by address
  are unchanged, and "On stage now" only shows during a session.

## Decisions
- The section order (with repeats) is the performance order; there is no separate arrangement.
- The pace is based on lyric lines, not chord lists, because a section's chord list is one pass of the progression.
- The Settings label is "Bars per chart line", because the value is bars per line.

## Deferred
- See `backlog.md` "From 023".

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1470 passed, 9 skipped. On the Samsung SM A366E, "Sunday Worship
Service" → Way Maker (♩68, 4/4, 2 bars per line) played end to end in about 63 s (expected 63 s), with sections
following the scroll, and stopped with Next highlighted.
