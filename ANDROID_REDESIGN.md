# Android redesign — implementation and verification

The implemented direction is a quiet, artwork-led radio library with a more focused player. Lead skill: the installed Impeccable pack, selected through the installed design-skills router. Animate supplied interaction guidance, adapted to Flutter. Its context binary could not initialize its external cache, so the installed reference files and actual source/rendered baseline were used directly.

## Implemented

- Accessible light/dark schemes derived from magenta #E81C9B, with neutral surfaces and persisted System/Light/Dark selection.
- Shared search, clear actions, loading/empty/error states, readable two-line station rows, accessible favourite actions and foreground-coloured hearts.
- Lazy Discover category shelves and responsive search grid; unchanged square artwork with contain fit and display-sized decoding.
- Group artwork/context header, featured/all-station hierarchy and preserved30-item pagination. Browse keeps50-item pagination,300ms search and recent history.
- Searchable favourites and recomposed settings preserving existing import/export.
- Readable player dock integrated into layout, shared-artwork expansion, reversible play/pause morph, disabled queue endpoints, scroll-safe expanded playback and neutral offline feedback with Retry.
- Compact Android navigation and rail above700dp; keyboard/inset-aware layout.
- Existing audio service, playback notifier, repositories, database, Android Auto and system media-control logic preserved. No artwork files changed.

## What was verified

- 60 tests passed, including the existing audio/dead-station and database regressions and22 new design/layout/database/cache checks.
- Analyzer for lib/test: no issues. Build runner completed successfully; generated files have no semantic diff.
- Profile APK compiled with the final native resources and palette. Isolated package metadata verified as com.radiov2.radiov2_android.designtest, label RadioV2 Design.
- Theme tests verify4.5:1 contrast for primary text and key accent pairs, system default, persistence and runtime switching through the actual settings route.
- Widget layout checks cover320×568 and800×600, light/dark, 200%text, long names/non-Latin text, offline player,320dp mini-player and reduced-motion play/pause reversal.
- Lazy-construction test provides 2,000 group descriptors and confirms fewer than 25 group-card widgets are built.
- Original app baseline screenshots captured on Galaxy S25: Browse, Discover, group/pagination, settings, mini/expanded player and system notification. Original test playback and media resume verified.

## Physical-device baseline

Same Galaxy S25, profile mode, exact original tracked UI at26ab700, process-cold/filesystem-warm, existing database, empty favourites. Three startup trials and 12 vertical flings. An opt-in shared FrameTiming/cache probe was used; its final chunked logs avoid Android's per-line truncation.

| Measurement | Before | After |
|---|---:|---:|
| Android launch, median |313ms | 287ms |
| Dart bootstrap to first scheduled frame, median |54ms | 50ms |
| Discover first-open live decoded images |54 | 12 |
| Discover image cache |87,874,560bytes | 7,680,000bytes |
| Discover first-open process PSS |390,287KB | 283,375KB |
| Scrolling build/raster p95 |0.807/1.198ms | 0.713/1.115ms |
| Scrolling samples over16.7ms |0/555 | 1/664 |
| Scrolling samples over8.3ms |1/555 | 1/664 |
| Foreground idle CPU,10s |0ticks | 0ticks |
| Background idle CPU,10s |4ticks | 4ticks |
| Visible Discover content-change to settled art |33ms,3trials | 33ms median; range33–67ms |

Startup numbers above are separate measurements, not added together. FrameTiming measures Flutter work; it is not a complete end-to-end input-latency metric. Video settling is30fps resolution and covers local genre assets, not remote station-logo network latency. PSS varies with OS/cache conditions. The table uses the repeat after run; the first after run measured303ms launch,53ms bootstrap and0.681/1.124ms build/raster p95 over692frames. Both after runs had one raster sample over16.7ms:20.748ms initially,18.515ms on repeat, versus original maximum15.246ms. Typical frame work improved, but rare raster stalls remain a measured limitation; these runs do not establish their cause or prove every-frame performance parity. Final focus-only changes do not alter Discover's rendering/loading pipeline.

The original Discover eagerly constructed every category shelf and retained54 decoded images on first open. The new lazy outer builder and bounded decoding address that observed implementation. The first-open image cache fell91.3%, and repeat first-open process PSS fell27.4%. Scrolling p95 improved, but the rare stalls and limited run count prevent a blanket claim about every device or scroll pattern. Cold-library idle PSS was235,313KB before,243,831KB initially after, and226,158KB on repeat. Background PSS was282,168KB before and217,661KB on repeat. These OS-level values are noisy.

## Rendered review and final confirmation

The initial native pass inspected the actual redesigned app on Galaxy S25: dark Browse, Discover, group detail, favourites, settings, mini/expanded player, neutral offline feedback and system media notification, plus light settings/Discover/search grid/group. Playback connected in 1.30s; system media pause stopped playback and media resume connected in 1.31s. Save/remove favourites and group pagination were exercised.

The bounded review fixes pinned playback controls so they cannot scroll offscreen, made the offline Snackbar neutral with the correct unavailable icon, and cleared text focus before group navigation. A singular search-result count was also corrected. A stronger viewport assertion reproduced the control issue in four small/tablet, light/dark,200%text tests and passed all four after the fix. Settled native recaptures exposed a deferred-focus race: unfocus alone could still restore the keyboard on Back. A real GoRouter regression failed before flushing the pending focus change and passed afterward. Native recapture then confirmed the keyboard remained dismissed.

The final native confirmation passed on Galaxy S25: light/dark browsing, search grid, group, settings and player;130%system text; visible pinned playback controls/queue count; and interrupted expansion, reopening, rapid playback toggles and Back in normal/reduced-motion recordings. Captures and sampled video contact sheets were inspected. Real station failure produced ERROR, Retry changed it to CONNECTING, and a working station then played in1.66s. Background media pause/resume, notification, pagination and favourite save/remove passed again. No Flutter or AndroidRuntime error was logged. This confirmation preceded the user's small artwork/order follow-up described below; its separate native check covers the affected surfaces.

No physical tablet, spoken TalkBack, headset/Bluetooth, call-focus, import/export picker or controlled slow-network logo test was performed. First-ever install/database copy was not benchmarked. Widget tests cover tablet dimensions and200%text. Video samples establish completed interruption/recovery, not a high-speed measurement of every transition frame.

Phone cleanup was verified: stay_on_while_plugged_in restored to0; font scale and animation settings left at their original values; media volume restored; test playback stopped; temporary recordings/dumps removed from the phone. The ordinary production app and its data remain untouched. RadioV2 Design is a distinct installed profile test app; its final APK is build/RadioV2-design-after.apk.

## Missing artwork and group ordering follow-up

The user clarified: featured remains pinned first; after featured, stations with pictures precede missing artwork. The catalog has featured stations without logos, which explains a missing-picture row above ordinary logo-bearing rows. That is retained as the explicit featured exception. Ordinary results now treat null, empty and whitespace-only artwork alike and use name plus ID for deterministic pagination. Group search also includes matching featured stations, which previously disappeared when the featured block was hidden during search. A real Drift regression checks featured placement, artwork ordering across pages, no omissions/duplicates and featured search matches.

Missing, loading or failed images use a neutral station-initials tile in station rows, the dock and expanded player. Existing working bitmap URLs, caching and bounded decoding remain. The initial URL-presence-only ordering was insufficient: the user's later screenshot showed real unsupported/failed URLs between working logos. The subsequent correction below addresses known image failures while preserving fixed rows and avoiding extra requests.

### Screenshot-confirmed artwork correction

The user's Best Radio92.6 URL returns200 image/svg+xml, which the existing bitmap image pipeline cannot decode. The pictured BigFM favicon returnsHTTP403. Merely checking for a nonempty URL promoted both as pictures.

The correction recognises unsupported SVG paths without fetching them, and learns HTTP403/404/410 or decoder failures from ordinary image requests. A non-reactive cache stores at most256 URLs for six hours using existing preferences. Offline, DNS, timeout, rate-limit and server failures are not treated as missing artwork. No image preflight, scan, additional decoding, background timer or list-wide image validation is added.

Each group captures an immutable failure snapshot before its query. All pages and searches use that same snapshot. New failures cannot remove, reorder or duplicate already displayed stations; they affect the next open or explicit retry. The group provider releases its snapshot when the route closes. Featured remains pinned. A previously unseen failed URL can still show its fallback during the first encounter; that position is retained for the rest of the visit. This is the explicit performance/stability tradeoff, rather than a guarantee that every first-encounter remote URL will work.

The actual repository/Drift/notifier regression verifies a late403 leaves the current state identical, the next page retains its first30 rows and60 unique IDs, reopening applies the failure, and all65 stations remain present. The provider-lifecycle check failed before disposal was added and passed afterward. Cache tests cover persistence, TTL, metadata bounds, malformed preferences and ignoring transient connectivity failures. Full60-test suite and analyzer pass; profile build installed separately. The new native comparison and confirmation evidence is retained under before-logo-health/after-logo-health in build/design.

Host SQLite diagnostics exposed avoidable repeated string normalisation. The final expression uses a fast common path and only checks SVG suffixes for SVG candidates. In30 alternating warm host trials, the907-station group query added roughly0.2ms with two failures, while the16,826-station largest group added about8ms (about15ms at the artificial256-failure cap). These diagnostics run on the laptop, under variable load, and are not Android end-to-end latency or a claim of zero computational cost. Actual phone measurements are the relevant UI check.

Direct Galaxy S25 comparison for this correction (same profile test app, three process-cold/filesystem-warm starts per run):

| Measurement | Immediately before correction | After correction |
|---|---:|---:|
| Android launch median |282ms(range280–292) |323ms initially;292ms repeat(range282–297) |
| Dart bootstrap/first scheduled frame median |50ms |51ms initially;52ms repeat |
| Discover live images/cache |12 /7,680,000bytes |12 /7,680,000bytes |
| Discover build/raster p95 |0.710/1.163ms |0.649/1.184ms |
| Discover frames over16.7ms |1/560 |1/601 |
| Whole-group-flow build/raster p95 |2.906/1.214ms |2.923/1.223ms |
| Whole-group-flow frames over16.7ms |0/863 |0/721 |
| Foreground idle CPU,10s |0ticks |0ticks |
| Background idle CPU,10s |1tick |4ticks |
| Cold idle PSS |224,559KB |243,234KB |
| Whole-group-flow PSS |301,516KB |292,371KB |

No material group-frame slowdown was observed; startup varied, and the first after run was slower. The repeat overlaps the before range but does not prove zero overhead or statistical parity. PSS and background CPU varied in both directions across the broader runs. The metadata itself contains six learned URL failures after this check; the BigFM403 was confirmed persisted through ordinary image handling, without injecting failure data.

Native screenshots confirm the two working Best Of Rock logos precede the unsupported Best Radio artwork. Their visible row bounds remained identical after six seconds. Best Radio remains in the list below the artwork-bearing rows, both identically named BigFM stations remain searchable, and reopening the group works. The final log had no Flutter/AndroidRuntime errors. Phone settings were restored and test playback stopped. Evidence: after-logo-health-check.json, before/after-logo-health metrics/group-perf JSON, after-logo-health-startup-repeat.json, and logo-health captures under build/design.

The follow-up native captures confirm the initials in group search, Browse, dock and expanded player, in light/dark and130%text. The failed-station message remains neutral with Retry and the player footer remains visible. A comparable whole-group flow through12flings recorded700/593frame samples before/after this follow-up, build/raster p952.765/1.214ms versus2.912/1.244ms, and zero samples over16.7ms in both. This scope includes any frames the idle-flushing probe had retained before scrolling; it is not a pure scrolling or input-latency measurement. PSS was295,510/310,657KB. The small p95/PSS differences are reported rather than interpreted as a proven regression or improvement from these short runs.

The follow-up log contained two Flutter engine timestamp-clamping warnings (reported frame time older than the preceding frame,8.348ms and0.014ms); no Dart exception or AndroidRuntime crash was logged. The earlier full confirmation log was clean. These engine warnings were retained in after-artwork-check.json.

## Review and reproduction

Device verification completed on 2026-10-23 before integration. The user subsequently authorized committing, pushing and publishing v1.0.8 on 2026-10-24.

tools/design/final_device_check.py after repeats comparison, themes, large text, motion and main flows. --skip-metrics retains the preceding comparison rather than repeating it. tools/design/device_artwork.py after confirms the subsequent missing-art treatment and group ordering. Both restore temporary phone settings in finally. Use the bundled Python interpreter; the system Python installation is not working.

Build a separate candidate by setting RADIO_DESIGN_TEST=1 in that PowerShell process and running flutter build apk --profile --dart-define=RADIO_PERF=true. Ordinary builds omit both switches. Profile probes are compiled out when RADIO_PERF is absent.

Evidence: build/design/; source ledger: REDESIGN_PLAN.md; implemented system: DESIGN.md; bounded review status: REDESIGN_REVIEW.md. Release status is tracked in the source ledger.

## Release

[RadioV2 v1.0.8](https://github.com/Natboa/RadioV2-Android/releases/tag/v1.0.8) was published on2026-10-24 from f941ce2dfb304047237215f24974ec26c8b0ebbb after explicit user authorization. Fresh60tests passed and analyzer lib/test was clean. Production phone(code10) and TV(code6) release builds succeeded. Both APKs are non-debuggable, have the expected production identities and match the previous release signing certificate. Test performance probes are absent. GitHub uploaded asset hashes and sizes match the locally verified APKs; exact hashes are in REDESIGN_PLAN.md. The TV interface is unchanged and no new physical TV runtime check was performed. This release also includes the previously pushed phone playback-stall recovery fix.
