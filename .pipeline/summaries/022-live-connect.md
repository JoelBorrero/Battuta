---
status: done
commit: (this commit)
base_sha: 560617f
rounds: 2 of 3
---
# 022: Find and join Live sessions on the same network

**Goal:** Two devices on the same Wi-Fi (or the director's hotspot) connect without typing IPs, offline.

## What changed
- **Hosting.** `startDirectorServer` binds `InternetAddress.anyIPv4` on port `47320` (`liveDefaultPort`), or
  an ephemeral port when it is taken. Calls are serialized: each start closes the previous server first, and
  the notifier shares one in-flight `startHosting`. The host card has a session name (max 40 characters),
  shows "N devices connected" with follower names, and shows `ip:port` (mono, copy) plus a QR code of the
  `battuta-live://ip:port` link under "Can't see it? Join by address". With no private IPv4 it shows
  "Connect to Wi-Fi or turn on your hotspot to host". On resume the page restarts a dead server and
  re-advertises it.
- **Discovery.** The director advertises `_battuta-live._tcp` over mDNS (`bonsoir`, TXT `session`,
  `director`, `v`, `id`). Followers browse and list the sessions nearby, live, without their own session.
  After 5 s with nothing found: "No sessions found nearby" plus Join by address. All of it sits behind
  `LiveSessionDiscovery`, faked in widget tests. The service name stays within 63 UTF-8 bytes
  (`buildLiveServiceName`).
- **Joining.** `LiveJoinAddress.parse` accepts `ip`, `ip:port`, a dotted host name or a `battuta-live://`
  link, and rejects anything else with a message. The connect timeout is 5 s with readable errors. A
  follower that drops reconnects (1 s → 2 s → 5 s, RECONNECTING) until Leave, and each new socket resets the
  sequence and section state, so a relaunched director is heard. A follower greets the director with its
  name: profile display name → account name → device model (`device_info_plus`) → "Battuta device".
- **Links.** `battuta-live://` opens Live and joins. During a session it asks first ("Leave the current
  session and join …?"); a link to the same address does nothing, and malformed links are ignored.
- **Platform.** iOS `NSLocalNetworkUsageDescription`, `NSBonjourServices`, and the `battuta-live` URL type.
  Android `CHANGE_WIFI_MULTICAST_STATE` and the `battuta-live` intent filter.
- **Removed.** The `127.0.0.1` / `8080` defaults and the placeholder connect copy.

## Decisions
- LAN only, so Live works with no internet. Online sessions are task 025.
- There is no in-app camera scanner. The QR opens with the phone's own camera.
- The Director / Follower switch is locked while a session runs; End it first.
- Address picking: private IPv4, Wi-Fi first, then hotspot ranges, skipping loopback, `169.254.*`, cellular
  and VPN interfaces.

## Deferred
- See `backlog.md` "From 022".

## Verification
`flutter analyze`: 0 issues. `flutter test`: 1375 passed, 9 skipped. Debug APK builds with `bonsoir` and
`device_info_plus`.
