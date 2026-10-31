# OpenROM — Mental Map & Developer Onboarding Guide

> Universal Retro Gaming Toolkit (M5 Dev, GPL v3) — a Flutter desktop/Android GUI
> wrapped around a pure-Dart backend engine (`openrom-core`) that orchestrates
> native third-party tools (`chdman`, `maxcso`, `xdelta3`, …).

Version at time of writing: **3.9.5** (`VERSION`, `core/pubspec.yaml`,
`gui/pubspec.yaml` = `3.9.5+1`).

---

## 0. Repository at a glance

```
OpenROM/
├── VERSION                     # single source of truth for release version
├── README.md  CONTRIBUTING.md  SECURITY.md  THANKS.md  TRANSLATORS.md
├── build_linux.sh              # local dev build (core + gui)
├── build_mac.sh
├── build_windows.bat
├── openrom.nsi                 # NSIS installer script (Windows)
├── macos_entitlements.plist
├── crowdin.yml                 # localization sync config
│
├── core/                       # ── BACKEND (pure Dart library + CLI) ──
│   ├── bin/openrom.dart        # CLI entry point — arg parsing + JSON emitter
│   ├── lib/openrom_core.dart   # public library barrel (exports all src/*)
│   └── lib/src/
│       ├── config.dart         # ★ tool-path resolution, config dir, config.json
│       ├── detector.dart       # magic-byte format/platform detection, conversion maps
│       ├── converter.dart      # ★ the conversion state machine (dispatch → tool → parse)
│       ├── compressor.dart     # ZIP create/extract (pure Dart, archive pkg)
│       ├── validator.dart      # chdman verify wrapper
│       ├── cue_generator.dart  # .cue creation + BIN mode detection
│       ├── bin_merger.dart     # multi-track BIN → single BIN+CUE
│       ├── header_remover.dart # NES/SNES/GB copier-header stripping
│       ├── m3u_generator.dart  # multi-disc M3U playlists
│       ├── rom_renamer.dart    # DAT import + CRC32 rename
│       ├── one_g_one_r.dart    # 1G1R dedup filter
│       ├── dcp_builder.dart / dcp_patcher.dart   # Dreamcast DCP
│       ├── ssp_builder.dart    # Saturn SSP patch build
│       ├── ipbin_editor.dart   # Dreamcast IP.BIN fields
│       ├── gdi_reader.dart     # GDI track parser
│       ├── version_reader.dart # reads VERSION next to exe
│       ├── online_prefs.dart   # SharedPreferences keys for opt-in online features
│       ├── logger.dart         # file logger → <config dir>/logs/
│       └── plugin/             # .orplug plugin subsystem
│           ├── plugin_manifest.dart   # schema + validation
│           ├── plugin_registry.dart   # in-memory route/format registry
│           └── plugin_manager.dart    # install/uninstall/load from disk
│
├── gui/                        # ── FRONTEND (Flutter) ──
│   ├── lib/
│   │   ├── main.dart           # bootstrap: window_manager, Android MethodChannel, runApp
│   │   ├── app.dart            # MaterialApp + responsive shell (sidebar / bottom-nav)
│   │   ├── screens/            # 8 screens (see §3)
│   │   ├── controllers/        # HomeController, PluginController (ChangeNotifier)
│   │   ├── services/           # CoreBridge ★, ToolsService, PatcherService, ThemeService…
│   │   ├── providers/          # LocaleProvider (ChangeNotifier)
│   │   ├── patcher/            # in-process patch formats (IPS/BPS/UPS/xdelta/…)
│   │   ├── widgets/            # Sidebar, TopBar, TerminalPanel, RomCard, DropZone
│   │   ├── models/             # ConversionJob, RomFile, errors, ThemeConfig
│   │   ├── l10n/               # 11 locales (.arb + generated Dart)
│   │   └── utils/              # AppVersion, AppConfig (tool paths)
│   ├── android/ linux/ macos/ windows/   # per-platform runner projects
│   ├── themes/                 # JSON theme definitions
│   └── test/                   # widget + unit tests (flutter test)
│
├── assets/
│   └── icons/                  # icon.png/.ico/.icns, banner, screenshots
│   (assets/{windows,linux,macos}/ are GITIGNORED — injected at build time)
│
├── flatpak/                    # Flatpak manifest, .desktop, metainfo, wrapper
├── themes/                     # theme JSON (mirror of gui/themes)
├── scripts/fetch-binaries.sh   # ★ download + SHA-256 verify native tools
├── scripts/update_website.py   # pushes docs/ to SourceForge
├── docs/                       # GitHub Pages site (index.html)
└── .github/workflows/          # CI/CD (see §4)
```

> **Third-party binaries are never committed.** `.gitignore` excludes
> `assets/linux/`, `assets/macos/`, `assets/windows/`. They are downloaded from
> the **OpenROM-bins SourceForge project** and SHA-256 verified at build time by
> `scripts/fetch-binaries.sh` (see §4.1).

---

## 1. Architecture & Flow

### 1.1 The two-layer model

OpenROM is deliberately split into two independently-shippable artifacts that are
**packaged side-by-side** in every release:

| Layer | Artifact | Language | Role |
|-------|----------|----------|------|
| Frontend | `gui` / `OpenROM` / `gui.exe` | Flutter (Dart) | UI, queue, drag-drop, theme, i18n, in-process patchers |
| Backend | `openrom-core` / `openrom-core.exe` | Pure Dart (`core/`) | Detection, conversion orchestration, compression, DAT tools, plugins |

`core/` is **also a normal Dart package** (`package:openrom_core`). The GUI depends
on it via a path dependency:

```yaml
# gui/pubspec.yaml
dependencies:
  openrom_core:
    path: ../core
```

So there are **two different ways** the GUI talks to the core, and it is important
not to confuse them:

1. **Subprocess IPC (the primary path).** For all heavy work the GUI *spawns the
   compiled `openrom-core` binary* and talks to it over a line-delimited JSON
   protocol on stdout. This is what `CoreBridge` does.
2. **In-process library calls (a few lightweight paths).** A handful of GUI files
   `import 'package:openrom_core/openrom_core.dart'` and call functions directly in
   the same Dart isolate — no subprocess. Examples:
   - `gui/lib/utils/config.dart` → `core.getToolPath()` (Android tool paths)
   - `gui/lib/patcher/dcp_builder.dart` → `core.DcpBuilder`
   - `gui/lib/main.dart` → `core.initAndroid(libDir)`
   - `gui/lib/widgets/rom_card.dart` → uses core constants (format colors, maps)
   - `gui/lib/services/plugin_service.dart`, `screens/settings_screen.dart`,
     `screens/plugins_screen.dart` → `PluginManager` directly

> Why the split? The CLI is the **contract**: it can be scripted headlessly, and
> the GUI stays thin. In-process calls are used only where spawning a process
> would be wasteful (path lookups) or where the code is shared logic (patch
> building, plugin management).

### 1.2 The IPC / stream bridge (`gui/lib/services/core_bridge.dart`)

`CoreBridge` is the single choke point between GUI and the core binary. It is a
static class exposing: `detectFile`, `runConversion`, `runCompress`, `runExtract`,
`generateM3u`, `getToolPath`, `runCore`, `getVersion`, `coreExists`.

**Process discovery.** `getCoreExecutablePath()` resolves the backend binary, in
order: cached path → `<exeDir>/openrom-core[.exe]` → bare `openrom-core` on `PATH`
→ legacy `main.py` via `python`/`python3` (dev fallback). The result is cached in
`_cachedCorePath`.

**Protocol: JSON-lines over stdout.** The GUI starts the process and reads stdout
line-by-line (`splitStreamLines`, which splits on `\r\n`/`\n` and keeps a partial
tail), decoding each line as one JSON object with a `type` field:

| `type` | Payload | GUI action |
|--------|---------|------------|
| `progress` | `{percent, file?}` | `onProgress(pct)` → job progress bar |
| `log` | `{message}` | `onLog(msg)` → terminal panel |
| `done` | `{success, error?, output?}` | `onDone(success, err)` → job final status |
| `error` | `{message}` | logged as `[ERROR] …` and buffered for the failure reason |
| `result` | `{file, matched, crc32, canonical_name?, suggested_filename?}` | (scan-roms) |
| `rename` | `{from, to, success, dry_run, error}` | (rename-roms) |

Any non-JSON stdout line is passed through to the log verbatim (so the CLI's
human-readable progress bar also works). stderr lines are prefixed `[STDERR]` and
buffered; on a non-zero exit the buffer becomes the error `details`.

**Exit-code contract:**

| Code | Meaning | GUI mapping |
|------|---------|-------------|
| `0` | success | job `Done` |
| `1` | conversion failed | `OpenROMError.conversionFailed` |
| `2` | unsupported format / bad usage | `OpenROMError.unsupportedFormat` |
| other | unknown | `OpenROMError.unknownError` |

```
┌────────────────────────────────────────────────────────────────────────┐
│ Flutter GUI (gui)                                                       │
│                                                                        │
│  HomeController.startConversion()                                       │
│        │  (per job)                                                     │
│        ▼                                                                │
│  CoreBridge.runConversion(job, outputDir, onProgress, onLog, onDone)    │
│        │                                                                │
│        │  Process.start(corePath, ['--json','--convert',file,          │
│        │                              '--format',fmt,...])              │
│        ▼                                                                │
│   ┌───────────────┐   stdout: {"type":"progress","percent":42.0}\n      │
│   │ openrom-core  │── stdout: {"type":"log","message":"[CHD] …"}\n      │
│   │   (child)     │── stdout: {"type":"done","success":true}\n         │
│   └───────┬───────┘   stderr: raw tool stderr                          │
│           │                                                             │
│   splitStreamLines → jsonDecode → onProgress / onLog / onDone          │
└───────────┼────────────────────────────────────────────────────────────┘
            │ Process.start  (inside the core)
            ▼
   ┌─────────────────┐   stdout progress lines ("... 42.5%")
   │ chdman/maxcso/… │── stderr
   └─────────────────┘
```

### 1.3 Full conversion pipeline (GUI pick → external binary → completion)

Trace: *user drops `game.bin` in the GUI and clicks Convert to CHD.*

```
1. DROP / PICK
   DropZone.onFilesDropped  ──► HomeController.addFilesFromPaths(paths)
   (or file_picker)               └─► FileDetector.detectPaths()
                                        └─► CoreBridge.detectFile(path)   [Process.run]
                                             core: --json --detect <file>
                                             ◄─ {format,platform,valid_targets,…}
                                        └─► builds RomFile, wraps in ConversionJob
   (main.dart Android: initAndroid(nativeLibraryDir) first)

2. QUEUE
   ConversionJob holds: targetFormat, compression, verify, media, audioCodec,
   estimatedOutputSize (ConversionJob.estimateSize()).

3. CONVERT PRESSED  (app.dart _onConvertPressed)
   HomeController.startConversion(globalFormat, compression, verify, outputDir,
                                  audioCodec, onPromptMedia)
     ├─ applies globalFormat if the job supports it
     ├─ if target=CHD and platform unknown and media unset → onPromptMedia() dialog
     │     ("Is this a CD or DVD?") → sets job.media
     └─ per job → CoreBridge.runConversion(...)

4. CORE SUBPROCESS  (core/bin/openrom.dart)
   parse args → build ConversionJob(s) → new Converter(onLogCb, onProgress)
   Converter.convert(job):
     ├─ job.getFileInfo()  → detector.detectFile()  (magic bytes, CHD header type)
     ├─ PluginRegistry.getConversion(fmt,tgt)?  → run plugin command template
     ├─ validate route via detector.getValidTargets(fmt)
     └─ _dispatch() picks the handler:
          CHD   → _toChd()      → chdman createcd|createdvd  (codec per platform)
          ISO   → _fromChd()    → chdman extractcd|extractdvd
          CSO   → _toCso()      → maxcso --threads=N [--use-zopfli|--use-zlib]
          RVZ   → _toRvz()      → nodtool convert
          ECM   → _toEcm()/_fromEcm() → ecm / unecm
          XISO  → _toXiso()/_xisoToFiles() → extract-xiso
          WUD…  → _nkitConvert() → nkit convert -i … -o …
          CCI/ZAR → _xboxConvert() → XGDTool --xiso
          (BIN→CHD auto-generates a temp .cue via _autoCue())

5. EXTERNAL BINARY  (Converter._run)
   Process.start(tool, args)
     ├─ stdout+stderr pumped through processStreamLines()
     ├─ each line → _log()  → onLogCb → CLI emits {"type":"log",…}
     ├─ each line → _parseProgress():
     │     • "… NN%"  (chdman/maxcso style)      → percent
     │     • "Wrote X of Y bytes"                → X/Y*100
     │     • guards against cpu/memory/ram/disk/usage/load lines
     │   → job.progress + onProgress → CLI emits {"type":"progress","percent":NN}
     └─ await exitCode
          exit 0 → progress 100, return true
          else   → job.error = "<tool> failed with exit code N: <stderr>"

6. VERIFY (optional, CHD only)
   Converter.convert(): if ok && job.verify && target==CHD → verifyChd() → chdman verify

7. COMPLETION
   CLI emits {"type":"done","success":true|false,"error":?}
   CoreBridge.onDone → job.status = Done|Failed
   GUI: progress bar completes, terminal shows logs, queue updates.
   Converter._cleanup() deletes temp auto-CUE files.
```

Progress parsing lives in **one** place in the core (`_parseProgress` in
`converter.dart`) and is re-emitted to the GUI as clean JSON — the GUI never
parses native tool output itself.

---

## 2. Binary Resolution & Dependencies

All third-party tool discovery funnels through **`core/lib/src/config.dart` →
`getToolPath(tool)`**. The GUI calls the same logic either via the CLI
(`--tool-path <tool>`, used by `CoreBridge.getToolPath`) or directly
(`gui/lib/utils/config.dart`).

### 2.1 Resolution order (per platform)

```
getToolPath(tool)
  │
  ├─ Android ──────────────────────────────────────────────────────────────
  │    initAndroid(nativeLibraryDir) set at startup (main.dart via MethodChannel)
  │    → '<nativeLibraryDir>/lib<tool>.so'   (chmod +x)
  │    fallback (no dir): 'lib<tool>.so'  (relies on the loader PATH)
  │
  ├─ Desktop (Windows / Linux / macOS) ────────────────────────────────────
  │    1. config.json override  (config[tool])  → if non-empty & (exists || absolute)
  │    2. getDefaultBundledPath(tool)  → bundled asset next to exe
  │    3. bare tool name  → resolved by the OS PATH
```

### 2.2 Bundled-asset layout (`getDefaultBundledPath`)

```
<baseDir>/assets/
   ├── windows/                     chdman.exe, ecm.exe, unecm.exe, maxcso.exe,
   │                                extract-xiso.exe, nodtool.exe, xdelta3.exe,
   │                                nkit.exe, saturn-patcher.exe, XGDTool.exe
   ├── linux/
   │    ├── x86_64/                 chdman, ecm, unecm, maxcso, extract-xiso,
   │    │                           nodtool, xdelta3, saturn-patcher, XGDTool, nkit
   │    └── arm64/                  (light tools only: xdelta3, ecm, unecm, saturn-patcher)
   └── macos/
        ├── arm64/  ┐
        └── x86_64/ ┘              (no XGDTool build on macOS)
```

`<baseDir>` is discovered by probing, in order:
1. `<exeDir>/assets`
2. `<CWD>/assets`
3. up to **3 parent directories** above `<exeDir>` for an `assets/` folder
4. final fallback: CWD

Architecture folder (`x86_64` vs `arm64`) is inferred from
`'${Platform.version} ${Platform.operatingSystem}'` containing `aarch64`/`arm64`.

Two naming special-cases:
- **`nkit` is the only tool with a distinct bundled layout.** Windows looks for
  `assets/windows/nkit.exe`; Linux/macOS look for
  `assets/<os>/<arch>/nkit/nkit` first, then fall back to the flat
  `assets/<os>/<arch>/nkit`. The published SourceForge layout is a **single
  file** (`…/nkit`), which satisfies the flat fallback.
- **Windows uses `<tool>.exe`, Linux/macOS use the bare name**, and `xgdtool`
  maps to `XGDTool[.exe]` (capitalised). See the `winNames`/`unixNames` maps in
  `config.dart`.

`ensureExecutable()` runs `chmod +x` on Linux/macOS/Android paths.

### 2.3 Config & environment variables

Config directory (`getDirectoryConfig()`, also used by logger and DAT store):

| OS | Location | Env var used |
|----|----------|--------------|
| Windows | `%APPDATA%\OpenROM` | `APPDATA`, else `USERPROFILE` |
| macOS | `~/Library/Application Support/OpenROM` | `HOME` |
| Linux | `$XDG_CONFIG_HOME/openrom`, else `~/.config/openrom` | `XDG_CONFIG_HOME`, `HOME` |

- **Config file:** `<configDir>/config.json` — a flat map of `tool → absolute path`
  (keys: `chdman`, `maxcso`, `ecm`, `unecm`, `extract-xiso`, `nodtool`, `xdelta3`,
  `nkit`, `saturn-patcher`, `xgdtool`). `loadConfig()`/`saveConfig()` with an
  in-memory cache. Empty string = "use bundled/PATH".
- **Plugins dir** (`PluginManager.pluginsDir`): Windows `%APPDATA%\OpenROM\plugins`;
  Linux/macOS `~/.local/share/openrom/plugins` (fallback `~/.openrom/plugins`).
- **Logs:** `<configDir>/logs/` (`logger.dart`).
- **DATs:** `<configDir>/dats/` (`rom_renamer.dart`).

**Environment variables used by the build/fetch tooling** (not by the app at
runtime):

| Variable | Where | Meaning |
|----------|-------|---------|
| `OPENROM_BINS_BASE_URL` | `scripts/fetch-binaries.sh` | Override the SourceForge base URL (default `https://downloads.sourceforge.net/project/openrom-binaries`) |
| `OPENROM_BINS_CHECKSUMS_URL` | `scripts/fetch-binaries.sh` | Override the checksums URL (default the raw `OpenROM-bins` GitHub `checksums.sha256`) |
| `SF_USER`, `SF_SSH_PRIVATE_KEY` / `SF_SSH_KEY` | OpenROM-bins publish + `deploy_website_sf.yml` | SourceForge SSH upload credentials |
| `GITHUB_TOKEN` | release workflows | Publishing the GitHub Release |

### 2.4 Tool → purpose map

| Tool | Used for | Handler in `converter.dart` |
|------|----------|-----------------------------|
| `chdman` | CD/DVD ⇄ CHD, verify | `_toChd`, `_fromChd`, `verifyChd` |
| `maxcso` | ISO ⇄ CSO/ZSO | `_toCso`, `_csoToIso` |
| `ecm` / `unecm` | ISO/BIN ⇄ ECM | `_toEcm`, `_fromEcm` |
| `extract-xiso` | XISO pack/unpack | `_toXiso`, `_xisoToFiles` |
| `nodtool` | RVZ/WIA/WBFS/GCZ ⇄ ISO | `_toRvz`, `_fromNodtool` |
| `nkit` | WUD/WUX/WUA/NKIT ⇄ ISO | `_nkitConvert` |
| `XGDTool` | CCI/ZAR ⇄ ISO (not on macOS) | `_xboxConvert` |
| `xdelta3` | xdelta/VCDIFF patches (GUI-side) | `gui/lib/patcher/xdelta_patcher.dart` |
| `saturn-patcher` | Saturn SSP patches | SSP path |
| plugin binaries | `.orplug`-registered routes | `_pluginConvert` |

> **`xdelta3` is resolved by the GUI, not the core** — `gui/lib/utils/config.dart`
> → `AppConfig.xdelta3Path` looks **next to the executable**
> (`<exeDir>/xdelta3[.exe]`), and on Android defers to `core.getToolPath`.
> Similarly `PluginManager` binaries resolve under the plugins dir.

---

## 3. State Management & UI Structure

### 3.1 State approach — `ChangeNotifier` + `setState` (no Provider/Riverpod/Bloc)

There is **no** Provider, Riverpod, Bloc, GetX or similar package in
`gui/pubspec.yaml`. State is handled with a hand-rolled pattern:

- **`ChangeNotifier` controllers/services** holding long-lived state:
  - `HomeController` — the conversion queue (`jobs`), `logs`, `isConverting`,
    `showTerminal`; drives `startConversion`, `pickFiles`, `addFilesFromPaths`,
    `removeJob`, `clearCompleted`, `reorderJobs`.
  - `PluginController` — installed plugins + store catalog.
  - `ThemeService` — current + available themes (persisted via `shared_preferences`).
  - `LocaleProvider` — active locale (persisted via `shared_preferences`).
- **`StatefulWidget` + `setState`** for local, screen-scoped state.
- **Manual listener wiring**: `_OpenROMAppState` subscribes to the three global
  notifiers and calls `setState` on change (`_onChanged`); screens subscribe to
  their controller in `initState` and re-render via `setState`.
- **Persistence** is `shared_preferences`; **injection is constructor-based**
  (e.g. `OpenROMApp(homeController:)`, `HomeScreen(controller:)`,
  `PatcherScreen(patcherService:)`) which keeps widgets testable without a DI
  framework.

### 3.2 Screens (all in `gui/lib/screens/`)

The app shell (`app.dart`) is a `MaterialApp` whose `home` is a responsive
`LayoutBuilder`: **wide** → left `Sidebar` (index 0–7) + `TopBar`; **narrow/Android**
→ `TopBar` + `BottomNavigationBar` exposing a subset
(`_mobileScreenIndices = [0, 1, 2, 4, 5]` = Convert, Patch, Tools, Plugins, Settings).
All screens live in an `IndexedStack` (kept alive, not rebuilt).

| # | Screen | File | Controls |
|---|--------|------|----------|
| 0 | Home / Convert | `home_screen.dart` | ROM queue, drop zone, ROM cards, progress, terminal panel, core-presence check on startup |
| 1 | Patcher | `patcher_screen.dart` | 2 tabs — **Apply Patch**, **Build Patch** (IPS/IPS32/UPS/BPS/PPF/APS/EBP/DPS/xdelta/SSP/DCP) |
| 2 | Tools | `tools_screen.dart` | 8 tabs — Compressor, M3U, CUE Generator, BIN Merger, Header Remover, CUE Editor, ROM Renamer, 1G1R Cleaner |
| 3 | Dreamcast | `dreamcast_screen.dart` | 3 tabs — DCP Apply, IP.BIN Editor, GDI Info |
| 4 | Plugins | `plugins_screen.dart` | 2 tabs — installed plugins, plugin store; drag-drop `.orplug` install |
| 5 | Settings | `settings_screen.dart` | Format/compression/verify/output/audio-codec (pushed up via `onSettingsChanged`), theme, locale, update check, online features |
| 6 | About | `about_screen.dart` | version (from `AppVersion.current` / `CoreBridge.getVersion()`), links |
| 7 | Theme Editor | `theme_editor_screen.dart` | edit/save custom theme JSON (HSV picker) |

Supporting widgets: `Sidebar`, `TopBar`, `TerminalPanel`, `RomCard`, `DropZone`,
`ErrorDialog`.

### 3.3 Dynamic application version

`gui/lib/utils/app_version.dart` resolves the displayed version with this
priority: `--dart-define=APP_VERSION` → `readAppVersion()` (reads `VERSION` next
to the executable, or the repo root in dev) → the `AppVersion.fallback`
constant. Release builds ship `VERSION` next to the binary, so the runtime value
tracks the release; keep `AppVersion.fallback` in sync with `VERSION` so dev
builds and `gui/test/app_version_test.dart` stay correct.

---

## 4. CI/CD & Packaging Lifecycle

Workflows live in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `Release.yml` | `workflow_dispatch` (version input) | Build + publish all desktop release artifacts |
| `Flatpak.yml` | `workflow_dispatch` (version input) | Build a `.flatpak` bundle and attach to the release |
| `Android.yml` | `workflow_dispatch`, `release: published` | Build the universal Android APK (gated off releases unless `ENABLE_ANDROID_RELEASE` repo var is `true`) |
| `quality.yml` | PR/push to `main`, manual | Version consistency + format/analyze/test for `gui` and `core` |
| `auto_fix.yml` | manual | `dart format` both packages and auto-commit |
| `pages.yml` | push to `docs/**` | Deploy the docs site to GitHub Pages |
| `deploy_website_sf.yml` | `release: published`, manual | Push the website to SourceForge |
| `daily_code_review.yml` | cron `0 6 * * *` | Static analysis / health check, files issues |

### 4.1 The shared binary-fetch step (`scripts/fetch-binaries.sh`)

Every packaging job downloads the native tools from **SourceForge** and verifies
each file against the published `checksums.sha256`:

```bash
bash scripts/fetch-binaries.sh --os <linux|macos|windows> [--arch <x86_64|arm64>] --dest <dir>
```

The script:
1. downloads the checksum list (raw `OpenROM-bins` GitHub `checksums.sha256`),
2. selects every `"<os>/<arch>/<file>"` entry (arch omitted → all arches),
3. downloads each from `https://downloads.sourceforge.net/project/openrom-binaries/<os>/<arch>/<file>`,
4. verifies SHA-256 (and `chmod +x` on Unix), aborting on any mismatch.

Exit codes: `0` success, `1` bad args, `2` no match, `3` download failure,
`4` checksum mismatch. This is why `assets/linux|macos|windows/` are gitignored.

### 4.2 `Release.yml` job graph

```
                       workflow_dispatch(version)
                                │
   ┌───────────────┬────────────┼───────────────┬──────────────────────┐
   ▼               ▼            ▼               ▼                      │
build-windows   build-linux   build-linux-arm64  build-macos (matrix:   │
(windows-2022)  (ubuntu-22.04)(ubuntu-24.04-arm)  macos-15 [arm64],     │
                                                   macos-15-intel       │
                                                   [x86_64])            │
   │               │            │               │                      │
   └───────────────┴────────────┴───────────────┘                      │
                                ▼                                      │
                             release (needs: all four) ────────────────┘
                                ▼
                     softprops/action-gh-release@v3 (tag v<version>)
```

**Common build recipe in every job:**
1. checkout → `scripts/fetch-binaries.sh … --dest assets/<os>/[<arch>]`
2. write `VERSION`, patch `gui/pubspec.yaml` version to `<version>+1`
3. `dart-lang/setup-dart` → `cd core && dart pub get && dart compile exe bin/openrom.dart`
   → `dist/openrom-core[.exe]`  ← **the backend is a compiled native Dart exe**
4. `subosito/flutter-action` → `cd gui && flutter pub get && flutter build <target>`
5. bundle core + `VERSION` + `themes/` + `assets/` next to the GUI

**Per-platform packaging:**

| Platform | Runner | GUI build | Core | Packaging | Artifact(s) |
|----------|--------|-----------|------|-----------|-------------|
| **Windows** | `windows-2022` | `flutter build windows` | `openrom-core.exe` | Copy core/VERSION/themes/assets into `…/Release`, write `README.txt`; `Compress-Archive` → **ZIP**; install NSIS + EnVar plugin + ImageMagick, generate BMP/ICO, `makensis openrom.nsi` → **Setup.exe** | `OpenROM_Windows`, `OpenROM_Windows_Installer` |
| **Linux x86_64** | `ubuntu-22.04` | `flutter build linux` | `openrom-core` | Build **AppDir** (`AppRun`, `.desktop`, icon), `appimagetool` → standalone **AppImage**; plus a **Core CLI ZIP** (`openrom-core` + light tools: xdelta3, ecm, unecm, saturn-patcher) | `OpenROM_Linux` → `…_Linux_x86_64.AppImage`, `OpenROM-Core-…_Linux_x86_64.zip` |
| **Linux ARM64** | `ubuntu-24.04-arm` | `flutter build linux` (manual Flutter clone + `precache --linux`) | `openrom-core` | Same as x86_64: standalone **AppImage** + **Core CLI ZIP** (light tools only — heavy conversions need x86_64) | `OpenROM_Linux_arm64` → `…_Linux_arm64.AppImage`, `OpenROM-Core-…_Linux_arm64.zip` |
| **macOS** | matrix `macos-15` (arm64) / `macos-15-intel` (x86_64) | `flutter build macos` | `openrom-core` | Embed core/VERSION/themes/assets into `*.app/Contents/MacOS`, **ad-hoc codesign** with `macos_entitlements.plist`, `hdiutil` → **DMG**, then ZIP | `OpenROM_macOS_arm64`, `OpenROM_macOS_x86_64` |
| **Android** (`Android.yml`) | `ubuntu-latest` | `flutter build apk --release` | core **compiled into the APK** via jniLibs (below) | **APK** | `OpenROM-Android-Universal` |
| **Flatpak** (`Flatpak.yml`) | `ubuntu-22.04` | `flutter build linux` | `openrom-core` | Install bundle + core + tools into `/app`, `flatpak-builder` → **.flatpak** | attached to release |

The final `release` job downloads all artifacts and publishes them to a GitHub
Release tagged `v<version>` with the download table in the body.

> **Linux split (Issue #174).** Linux releases no longer ship a redundant ZIP
> that duplicates the AppImage. Each arch publishes two clean artifacts: the
> **AppImage** (GUI + bundled engine, run directly) and a separate
> **`OpenROM-Core-<version>_Linux_<arch>.zip`** (headless CLI + light tools) for
> scripting. See the release body's "Linux notes".

### 4.3 Android specifics

`Android.yml` fetches the Android tool libraries from SourceForge and stages them
as **jniLibs**:

```bash
bash scripts/fetch-binaries.sh --os android --dest assets/android
for abi in arm64-v8a x86_64; do
  cp assets/android/$abi/<tool>  gui/android/app/src/main/jniLibs/$abi/lib<tool>.so
done
```

At runtime, `main.dart` queries the native library directory over a
`MethodChannel('com.m5dev.openrom/native')` handled by `MainActivity.kt`
(`getNativeLibraryDir`), then calls `core.initAndroid(libDir)`. From then on
`config.getToolPath()` returns `lib<tool>.so` inside that dir — this is the only
platform where tools are shared libraries rather than executables.

Android is **omitted from the v3.9.5 release**. The `build-android` job is guarded
so the `release: published` trigger no longer fires it; re-enable by dispatching
`Android.yml` manually or setting the repository variable
`ENABLE_ANDROID_RELEASE=true`.

### 4.4 `quality.yml` gate

On every PR/push to `main` it:
- asserts `VERSION` == `core/pubspec.yaml` version and == `gui/pubspec.yaml` `+1`
  (the same invariant the release jobs patch),
- `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test` (gui),
- `dart format`, `dart analyze`, `dart test` (core).

> **Formatter gotcha.** The formatter style (short vs. tall) is decided by the
> package *language version*, which comes from `.dart_tool/package_config.json`.
> A package with no resolved `.dart_tool` is formatted in the **current** style.
> Format a file with the package that owns it (`cd gui && dart format …`) so CI
> agrees.

---

## 5. Quick reference for a new developer

- **Run the GUI (dev):** `cd core && dart pub get && dart compile exe bin/openrom.dart -o ../openrom-core`, then `cd gui && flutter pub get && flutter run`. Place `openrom-core` next to the built `gui` binary (or on `PATH`).
- **CLI only:** `dart run core/bin/openrom.dart --detect game.iso` / `--input game.iso --format CHD` / `--list-formats`.
- **Fetch tools locally:** `bash scripts/fetch-binaries.sh --os linux --arch x86_64 --dest assets/linux/x86_64`.
- **The contract between layers is the JSON-lines protocol in §1.2.** Change it in `core/bin/openrom.dart` (emit) and `CoreBridge` (consume) together.
- **All tool discovery is `core/lib/src/config.dart`.** Change it there; both the CLI and the GUI pick it up.
- **Adding a conversion route:** add the extension/format to `detector.dart` maps, add a handler in `converter.dart:_dispatch`, and a tool to `config.dart` `defaultConfig`. Plugins can add routes without touching core (`plugin_registry.dart`).
- **Adding a screen:** create `gui/lib/screens/<x>_screen.dart`, add it to the `screens` list and nav items in `app.dart` (+ `sidebar.dart` icons, `_mobileScreenIndices` if mobile-visible).
- **Releasing:** bump `VERSION` + both `pubspec.yaml` versions (and `AppVersion.fallback`), commit to `main`, then dispatch `Release.yml` and `Flatpak.yml` with the version input.
