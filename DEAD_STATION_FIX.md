# Dead-station playback fix — 23 October 2026

## Behaviour

A new station request cancels an unfinished request instead of waiting behind its network load. A request token prevents cancelled loads from playing or reporting errors later. Live `play()` remains unawaited.

An initial station load has a 12-second deadline. If connectivity_plus reports no network interface, the deadline is renewed so a temporary outage can recover. An available interface does not prove Internet access; captive portals and unreachable servers still time out. Connectivity lookup has its own two-second bound.

The handler suppresses duplicate native load errors and late idle events, publishes a stable error on timeout, and preserves ready/playing updates when just_audio's `play()` is a no-op during a source switch. Stop and dispose cancel outstanding attempts and timers.

`StationPlayer` is the small adapter around the locked just_audio 0.9.46 dependency used for deterministic handler tests. The phone handler changes here; the copied TV handler is outside this fix.

## Evidence

Same Galaxy S25 (SM-S931B), Android 17; installed release v1.0.7 compared with a separate package `com.radiov2.radiov2_android.stalltest` built from this change. Original app and favourites were retained.

| Scenario | Installed release | Test build |
| --- | --- | --- |
| Burina.NET Demo Radio alone | Still CONNECTING after 90 seconds | ERROR at 12.50 seconds |
| Burina, then #lofi by reyfm.de | PLAYING 31.09 seconds after good tap | PLAYING 1.70 seconds after good tap |

The script dismissed the keyboard, found actual station rows through the UI hierarchy and verified each station name in the Android media-session metadata. Navigation to the good station took 6.00 seconds before the fix and 6.45 seconds afterward. Times include adb polling overhead. One comparison per build; these are observed runs, not statistical percentiles. The older report's 70-second figure varied between runs.

Additional device checks passed:

- Working station switches: 1.19 seconds to #lofi, 1.09 seconds to Chillout - Radios 100FM, 1.58 seconds back to #lofi.
- Background media pause: stopped state observed after 0.06 seconds; media play reconnected after 0.97 seconds.
- Full network outage for 45 seconds: PLAYING initially, BUFFERING at 11.4 seconds, CONNECTING at 25.4 seconds; no error while offline. After Wi-Fi/mobile data returned, playback resumed automatically in 2.48 seconds.

Wi-Fi/mobile data were restored to enabled and media volume to 7. The separate test app was removed after verification; the original v1.0.7 installation remains. Call audio focus, physical headset controls and Bluetooth were not tested in this task.

Tests were written before implementation. The inherited queue failed the pending-load switch, cancellation and deadline cases. Two additional tests first exposed ready-state replay and stopped playback-state bugs. Final verification:

- `flutter test --no-pub --reporter expanded`: 38 passed (17 audio regressions, 20 database upgrade tests, one existing placeholder).
- `flutter analyze --no-pub lib test`: no issues.
- `flutter build apk --release --no-pub`: succeeded for the separate test package. A later braces-only lint correction has identical runtime semantics.

Reproduce device measurements, when the phone is free:

```powershell
python tools/audit/device_stall_verified.py com.radiov2.radiov2_android both
python tools/audit/device_stall_verified.py com.radiov2.radiov2_android.stalltest both
```

Each run temporarily lowers media volume and restores it. These checks navigate and play stations; avoid running during a call. The test APK is local at `build/RadioV2-stalltest.apk`. The test copy was removed after verification; install the local APK again to repeat these checks.

No version bump, release tag or GitHub release is part of this change.
