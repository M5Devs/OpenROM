<p align="center">
  <img src="assets/icons/OpenROM-Banner.jpeg" alt="OpenROM Banner" width="100%"/>
</p>

<h1 align="center">⬡ OpenROM</h1>
<p align="center"><b>Universal Retro Gaming Toolkit</b> — by M5 Dev</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL%20v3-blue.svg"/></a>
  <a href="https://sourceforge.net/projects/openrom/files/latest/download"><img src="https://img.shields.io/sourceforge/dt/openrom.svg?color=2ea043&logo=sourceforge"/></a>
  <img src="https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20Android%20soon-cyan"/>
  <a href="https://github.com/M5Devs/OpenROM/releases/latest"><img src="https://img.shields.io/github/v/release/M5Devs/OpenROM"/></a>
  <a href="https://github.com/M5Devs/OpenROM/releases/latest"><img src="https://img.shields.io/github/downloads/M5Devs/OpenROM/total"/></a>
  <a href="https://sourceforge.net/projects/openrom/files/latest/download"><img src="https://img.shields.io/sourceforge/dm/openrom.svg?color=1f6feb&logo=sourceforge"/></a>
  <a href="https://hosted.weblate.org/engage/openrom/"><img src="https://hosted.weblate.org/widget/openrom/svg-badge.svg" alt="Translation status"></a>
</p>

---

> 🎮 Meet **ROMeo** — OpenROM's official mascot. Your friendly pixel-art cartridge companion for all things ROM.

OpenROM is a free, open-source **Universal Retro Gaming Toolkit** — one app to replace every fragmented ROM tool out there. Convert, patch, compress, clean, and manage your ROM collection with a modern **Flutter desktop UI**, real-time terminal logging, smart platform detection, and a full headless CLI for automation — all running **100% offline**.

---

## ⬇️ Download

| Platform | GitHub Release | SourceForge Mirror |
|----------|---------------|-------------------|
| 🪟 Windows | [OpenROM_Windows_Portable.zip](https://github.com/M5Devs/OpenROM/releases/latest) | [Mirror](https://sourceforge.net/projects/openrom/files/latest/download) |
| 🐧 Linux | [OpenROM_Linux_x86_64.zip](https://github.com/M5Devs/OpenROM/releases/latest) | [Mirror](https://sourceforge.net/projects/openrom/files/latest/download) |
| 🍎 macOS Apple Silicon | [OpenROM_macOS_arm64.zip](https://github.com/M5Devs/OpenROM/releases/latest) | [Mirror](https://sourceforge.net/projects/openrom/files/latest/download) |
| 🍎 macOS Intel | [OpenROM_macOS_x86_64.zip](https://github.com/M5Devs/OpenROM/releases/latest) | [Mirror](https://sourceforge.net/projects/openrom/files/latest/download) |
| 🤖 Android | 🚧 Coming soon via Termux | — |

Each release includes the **Flutter GUI** (`OpenROM`) and the **headless CLI** (`openrom-core`).

📖 **Guides & Docs:** [Official Wiki](https://github.com/M5Devs/OpenROM/wiki) — setup, Steam Deck, Termux, FAQs.

---

## 🎮 Features

### 🔁 ROM Conversion
- **20+ conversion paths** — ISO, BIN, CUE, GDI, IMG, ECM, CHD, CSO, ZSO, XISO, RVZ, WIA, WBFS, GCZ and more.
- **Smart Platform Detection** — Magic byte detection for PS1, PS2, PSP, Xbox, GameCube, Wii, Dreamcast — not size guessing.
- **Real CHD Header Parsing** — Reads actual CHD v4/v5 headers to determine CD vs DVD type accurately.
- **Auto CUE Generation** — Generates CUE sheets for standalone BIN files with correct track mode (MODE1/MODE2/AUDIO).
- **Integrity Verification** — Post-conversion CHD integrity check via `chdman verify`.

### 🩹 ROM Patching
- **9 patch formats** — IPS, IPS32, UPS, BPS, PPF, APS, EBP, DPS, xdelta3.
- **Auto format detection** — Drop a patch file and OpenROM detects the format automatically.
- **Checksum verification** — CRC32 integrity checks before and after patching with a detailed report.
- **Ignore checksum mode** — Force-apply patches even on modified ROMs.

### 🗜️ Compression & Extraction
- **ZIP and 7Z support** — Compress ROMs or entire folders with fast / normal / ultra presets.
- **Smart skip** — Already-compressed formats (CHD, CSO, RVZ, 7Z…) are automatically skipped.
- **Batch extraction** — Extract ZIP and 7Z archives with progress tracking.
- **Delete source option** — Auto-clean source files after successful compression.

### 🧹 ROM Header Removal
- **Copier header detection and removal** for NES (iNES), SNES (SMC), Game Boy / GBC — with confidence rating (certain / likely).
- **Auto backup** — Original ROM backed up as `.bak` before any modification.
- **Non-destructive** — Output written to a separate file; source untouched by default.

### 🗂️ Collection Utilities
- **M3U Playlist Generator** — Auto-generate M3U playlists for multi-disc games (PS1, Saturn, etc.).
- **BIN Merger** — Merge multi-track BIN files into a single BIN + CUE.
- **Batch Processing** — Drop a whole folder, process everything at once.

### 🖥️ UI & Workflow
- **Gaming Dashboard UI** — Flutter-powered dark interface inspired by PS5/Xbox aesthetics, with ROM cards, platform badges, and real-time progress.
- **Themeable** — Swap between built-in themes (Gaming Dashboard, Cyberpunk, Terminal, Minimal) or create your own via JSON.
- **Real-time Terminal Log** — Live process output with timestamps, slides up during conversion.
- **Drag & Drop** — Native drag and drop for files and folders.
- **Full Headless CLI** — `openrom-core` for scripting, automation, and Flutter IPC.
- **No Telemetry** — Zero network requests. No analytics. Runs 100% locally forever.

---

## 🔁 Conversion Matrix

| Input | Output | Tool | Notes |
|-------|--------|------|-------|
| ISO | CHD | chdman | `createcd` for PS1/Dreamcast, `createdvd` for PS2/GC |
| ISO | CSO | maxcso | PSP / PS2 |
| ISO | ECM | ecm | |
| ISO | XISO | extract-xiso | Xbox |
| ISO | RVZ | nodtool | GameCube / Wii |
| BIN | CHD | chdman | Auto CUE if missing |
| BIN | ECM | ecm | |
| CUE | CHD | chdman | |
| GDI | CHD | chdman | Dreamcast |
| IMG | CHD | chdman | |
| CHD | ISO | chdman | |
| CHD | BIN/CUE | chdman | |
| CSO | ISO | maxcso | |
| ZSO | ISO | maxcso | |
| ECM | ISO / BIN | unecm | Auto-detects output format |
| XISO | Files | extract-xiso | Extracts to folder |
| RVZ | ISO | nodtool | GameCube / Wii |
| WIA | ISO | nodtool | GameCube / Wii |
| WBFS | ISO | nodtool | Wii |
| GCZ | ISO | nodtool | GameCube / Wii |

---

## 🩹 Supported Patch Formats

| Format | Systems |
|--------|---------|
| IPS / IPS32 | NES, SNES, GBA, and most retro systems |
| UPS | Universal — any ROM |
| BPS | Universal — any ROM |
| PPF | PS1 / PS2 disc patches |
| APS (GBA) | Game Boy Advance |
| APS (N64) | Nintendo 64 |
| EBP | EarthBound / SNES |
| DPS | DOS / PC |
| xdelta3 / VCDIFF | Large ROMs, disc images, PS2, PSP |

---

## 💻 CLI Usage

```bash
# Detect file format and platform
openrom-core --detect game.iso

# Convert a single file
openrom-core --input game.iso --format CHD

# Batch convert a folder
openrom-core --folder /roms/ --format CHD --compression Max

# Convert with verification
openrom-core --input game.iso --format CHD --verify

# Apply a patch
openrom-core --patch game.sfc --patch-file hack.ips

# Compress to 7Z
openrom-core --compress game.iso --format 7z --level ultra

# Remove ROM header
openrom-core --remove-header game.smc

# Generate M3U for multi-disc game
openrom-core --m3u /roms/Metal\ Gear\ Solid/

# Verify a CHD
openrom-core --input game.chd --verify-only

# JSON output (for scripting / Flutter IPC)
openrom-core --json --detect game.iso
```

---

## 🎨 Themes

OpenROM ships with 4 built-in themes and supports fully custom themes via JSON files in the `themes/` folder:

| Theme | Description |
|-------|-------------|
| `default.json` | Gaming Dashboard — dark navy, red accent |
| `cyberpunk.json` | Neon on black |
| `terminal.json` | Green on black, monospace |
| `minimal.json` | Clean light mode |

Create your own theme by copying any JSON file and editing the color values.

---

## 🛠️ Bundled Tools

All tools are open source and verifiable. See [SECURITY.md](SECURITY.md) for SHA256 checksums.

| Tool | Purpose | License |
|------|---------|---------| 
| **chdman** | CHD conversion (MAME) | GPL v2 |
| **maxcso** | CSO/ZSO compression | ISC |
| **ecm / unecm** | ECM compression | GPL v2 |
| **extract-xiso** | Xbox ISO extraction | GPL v2 |
| **nodtool** | GameCube / Wii formats | MIT |
| **xdelta3** | xdelta/VCDIFF patching | Apache 2.0 |

---

## 🚀 Building from Source

### Requirements
- Python 3.10+
- Flutter 3.27+
- PyInstaller 6.0+

### Run Flutter UI from source
```bash
git clone https://github.com/M5Devs/OpenROM
cd OpenROM

# Build headless Python core
pip install -r requirements.txt
pyinstaller --onefile --name openrom-core core/cli.py

# Run Flutter UI
cd openrom_flutter
flutter pub get
flutter run -d windows   # or linux / macos
```

### Build release packages
```bash
# Windows
build_windows.bat

# Linux
./build_linux.sh

# macOS
./build_mac.sh
```

---

## 🗺️ Roadmap

- [x] Flutter UI rewrite (v2.5.0)
- [x] Magic byte platform detection
- [x] CHD header parsing
- [x] Theme system
- [x] ROM Patcher (IPS, BPS, UPS, xdelta3, PPF and more)
- [x] ZIP / 7Z compression & extraction
- [x] ROM header removal (NES, SNES, GB/GBC)
- [x] M3U playlist generator
- [ ] Wii U support (WUD / WUX)
- [ ] Android support via Termux 🤖
- [ ] ROM Checker — No-Intro DAT + RetroAchievements hash verification
- [ ] ARM builds (Linux ARM64)

---

## 🤝 Contributing

Contributions are welcome! Read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on bug reports, feature requests, and pull requests.

---

## 📄 License

OpenROM is licensed under the **GNU General Public License v3.0 (GPL v3)** — a free, copyleft license approved by the Open Source Initiative.

| | |
|---|---|
| ✅ | Free to use personally and commercially |
| ✅ | Free to study, modify, and distribute |
| ✅ | Forks must remain open source under GPL v3 |
| ✅ | Listed on Flathub, Linux distros, and OSI-compliant repos |

See [LICENSE](LICENSE) for the full license text.
