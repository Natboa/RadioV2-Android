# Android redesign — working ledger

Lead: installed Impeccable skill; Animate supplies motion guidance adapted to Flutter.
User authorizes autonomous implementation. No commits, pushes, releases or subagents.
Base: main,26ab70026b6a21b948199c1443a589bd9ac22d18.
Preserve unrelated untracked audit files and AGENTS.md.

- [x] Read project instructions, memory, design router and Android guidance; inspect source, screens, audio, image loading and artwork.
- [x] Capture original rendered screens and profile startup, scrolling, image cache and idle resource use on Galaxy S25.
- [x] Implement accessible magenta-seeded light/dark palettes and persisted System/Light/Dark appearance.
- [x] Recompose Browse, Discover, group detail, favourites and settings; preserve lazy construction, pagination and square artwork.
- [x] Redesign dock/expanded player, interruptible motion, neutral offline feedback and media integration.
- [x] Verify tests/analyzer/codegen/build, actual rendered themes/main flows, larger text and reduced motion; measure before/after performance.
- [x] Confirm pinned controls, neutral unavailable message/Retry and keyboard Back fixes in native recaptures.
- [x] Apply user follow-up: neutral initials fallback; featured remains pinned, then ordinary artwork-bearing stations before missing art; verify pagination/search and native renders.
- [x] Record review, evidence, limitations and recovery memory; restore phone settings and stop test playback. Leave all changes uncommitted.

## Direction

Quiet library, expressive player. Neutral canvas, strong headings and section separation. Existing square genre sleeves carry the colour. Magenta #E81C9B is the seed for accessible theme roles. Foreground hearts. A tactile dock expands into a focused player with pinned controls and independently scrollable details. No fake live progress or decorative perpetual animation.

## Verification

56 tests passed; analyzer lib/test clean; codegen succeeded with no semantic generated-source diff; final isolated profile APK built/installed as RadioV2 Design. New regressions reproduced control reachability, deferred search-focus restoration and ordering defects before fixes. Tests cover lazy creation with2,000 descriptors, artwork containment/bounded decoding, contrast/persistence, small/tablet dimensions,200%text, reduced motion, foreground hearts, monograms and actual Drift pagination/search.

Native S25 checks: Browse/search, Discover/grid, group pagination, favourites save/remove, settings, light/dark,130%text, dock/player, normal/reduced interrupted expansion and rapid playback toggles, neutral station timeout/Retry, working-station recovery, Android media notification and background pause/resume. Final artwork follow-up confirmed row/dock/player tiles and featured/ordinary sections. Phone returned to stayawake0,font1.15,window/transition1.0,animator absent,volume4; test app stopped; test temporary phone files removed.

Original -> repeat after: median Android launch313->287ms, bootstrap54->50ms; Discover live images54->12, cache87,874,560->7,680,000bytes; first-open PSS390,287->283,375KB. Build/raster p95.807/1.198->.713/1.115ms; one18.515ms raster outlier after versus original15.246ms maximum (initial after20.748ms). Idle CPU0ticks/10s and background4ticks/10s unchanged. Local-art settling33ms median both. These short runs do not prove every-frame parity; tail stalls and full measurement limits are in ANDROID_REDESIGN.md.

Artwork follow-up whole-group flow,12flings: build/raster p952.765/1.214->2.912/1.244ms,0frames>16.7ms both; PSS295,510->310,657KB. This includes unflushed frames from the preceding group flow and is not pure scroll/input latency. No claim that small differences establish causation.

## Boundaries

Physical tablet, spoken TalkBack, headset/Bluetooth, call focus, import/export picker, controlled slow-network logos and first-ever database copy were not tested. A saved image URL can fail remotely; sorting uses catalog artwork presence without eager validation or unstable image-driven reordering. Featured missing-art entries remain pinned per the latest user instruction.

TaskCreate is unavailable; this ledger tracks the task. Impeccable's context binary could not initialize its cache, so installed references and actual rendered evidence were used directly. Review ran inline because the user prohibits subagents. No further open-ended polish loop. See REDESIGN_REVIEW.md for the scored fixes and ANDROID_REDESIGN.md for reproducible evidence.

## Screenshot-confirmed artwork bug — active follow-up
- [x] Verify latest redesign and diagnose pictured URLs: Best Radio92.6 is SVG(current bitmap renderer cannot decode it); BigFM favicon returnsHTTP403. URL presence alone is insufficient.
- [x] Add bounded persistent confirmed-failure metadata; classify known unsupported URLs; never perform group-open network validation.
- [x] Freeze artwork-order metadata per group visit, including all pages/search; apply new failures on next open/explicit refresh, never remove/reorder visible rows.
- [x] Add regressions for failure classification/TTL/bounds, actual DAO ordering and stable pagination after late image failures.
- [x] Compare startup/group performance, inspect actual S25 list, verify no row disappears, then update evidence/memory. No commits/push/releases.

User specifically requires no brief appearance followed by disappearance AND no performance regression. A previously unseen failed URL needs an encounter before classification; first-encounter order stays fixed. No eager/preflight requests. This replaces the earlier URL-presence-only completion claim for artwork ordering.


The screenshot correction is verified:60tests/analyzer/build pass; exact Best/BigFM native rows retained and no bounds change after6s. Before->after group p952.906/1.214->2.923/1.223ms,0>16.7both. Startup282ms before,323firstafter,292repeat(range282–297); notzero-overheadcertification. Cache12/7.68MB unchanged,foregroundidle0ticksboth; memory/backgroundCPUvariable. Provider lifecycle test failedbeforeautoDispose andpassedafter; pervisitfailure snapshot protects pagination. Six actualfailedURLs persisted withoutinjection. No newimagevalidationrequests. Recommendation:keepboundedmetadatafix; don'tchaseperfectfirst-encounterartworksorting. Phonecleanupverifiedinfinalreport. Alluncommitted.

## v1.0.8 release — explicitly authorized2026-10-24
The user's later instruction "commit push and publish" supersedes the earlier leave-uncommitted restriction for this release. Installed release-flutter workflow applied.
- [x] Confirm remote main and latest release; choose1.0.8, phone build10/TVbuild6.
- [x] Bump both version manifests and README; preserve unrelated local audits/instructions.
- [x] Run final tests/analyzer and build signed production phone/TV APKs without test-package/performance flags:60 tests pass, analyzer clean, both release builds succeed.
- [x] Verify package IDs, versions, signing and artifact hashes: production IDs,1.0.8/code10 phone and code6 TV, non-debuggable, previous-release signer matches, performance probe absent.
- [x] Commit only the redesign/release files and push main: f941ce2dfb304047237215f24974ec26c8b0ebbb.
- [x] Publishv1.0.8 with verified APKs, confirm release assets and save release memory/checkpoint.

Release artifacts: phone109,257,532bytes, SHA2568f44714d9ea680950f5a79b40091b3adc242a1c3571278b9711e8a56ffc5cc4e; TV108,155,719bytes, SHA256798eb25ce367c5f21a4aa256a3e4962050bd1733aef34d5b40394baf40b7f45d. TV interface unchanged; no new physical TV runtime check. Local signed-package verification is retained at build/release/verification.json.

Published [RadioV2 v1.0.8](https://github.com/Natboa/RadioV2-Android/releases/tag/v1.0.8) on2026-10-24. Both GitHub assets are uploaded and their SHA256 digests/sizes match local verified APKs. Release tag targets the validated source commit above. Earlier no-commit notes describe the pre-release milestones and are superseded by this explicitly authorized release.
