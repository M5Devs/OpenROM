# ⬡ OpenROM

**Universal ROM Compression Suite** — by M5 Dev

[![License: GPL v3 + Commons Clause](https://img.shields.io/badge/License-GPL%20v3%20%2B%20Commons%20Clause-red.svg)](LICENSE)
[![SourceForge Downloads](https://img.shields.io/sourceforge/dt/openrom.svg?color=2ea043&logo=sourceforge)](https://sourceforge.net/projects/openrom/files/latest/download)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-cyan)]()
[![Release](https://img.shields.io/github/v/release/M5Devs/OpenROM)](https://github.com/M5Devs/OpenROM/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/M5Devs/OpenROM/total)](https://github.com/M5Devs/OpenROM/releases/latest)
[![SourceForge Monthly Downloads](https://img.shields.io/sourceforge/dm/openrom.svg?color=1f6feb&logo=sourceforge)](https://sourceforge.net/projects/openrom/files/latest/download)

OpenROM is a Universal ROM Compression Suite built to break the monopoly of proprietary ROM tools. It features a modern two-column UI design, real-time command line terminal logging, batch processing, and direct single-click conversions — plus a full CLI for automation and scripting.

![OpenROM Screenshot](assets/icons/screenshot-1.png)

---

## ⬇️ Download

| Platform | Official Release (GitHub) | Fast Mirror (SourceForge) |
|----------|---------------------------|---------------------------|
| 🪟 Windows | [OpenROM_Windows_Portable.zip](https://github.com/M5Devs/OpenROM/releases/latest) | [Download Mirror](https://sourceforge.net/projects/openrom/files/latest/download) |
| 🐧 Linux | [OpenROM_Linux_x86_64.zip](https://github.com/M5Devs/OpenROM/releases/latest) | [Download Mirror](https://sourceforge.net/projects/openrom/files/latest/download) |
| 🍎 macOS Apple Silicon | [OpenROM_macOS_arm64.zip](https://github.com/M5Devs/OpenROM/releases/latest) | [Download Mirror](https://sourceforge.net/projects/openrom/files/latest/download) |
| 🍎 macOS Intel | [OpenROM_macOS_x86_64.zip](https://github.com/M5Devs/OpenROM/releases/latest) | [Download Mirror](https://sourceforge.net/projects/openrom/files/latest/download) |

Each download includes both the **GUI** and the **CLI** (`openrom-cli`).

---

📖 **Documentation & Guides:** Check out our [Official Wiki](https://github.com/M5Devs/OpenROM/wiki) for setup guides, Steam Deck setup, and FAQs.

---

## 🎮 Features

- **Modern Two-Column Design** — Clean split interface with DROP ZONE & Queue on the left, and Conversion Settings / Controls on the right.
- **Complete Conversion Matrix** — Support for 20+ conversion paths including ISO, BIN, CUE, GDI, IMG, ECM, CHD, CSO, ZSO, XISO, RVZ, WIA, WBFS and GCZ.
- **Full CLI** — Automate conversions via `openrom-cli` for scripting and batch workflows.
- **Live Terminal & Logging** — Real-time process logging saved to your OS config directory.
- **Auto CUE Generation** — Auto-generates CUE files for standalone BIN files with correct track mode detection (MODE1/MODE2/AUDIO).
- **Smart Platform Detection** — Detects PS1, PS2, PSP, Xbox, GameCube, Wii, and Dreamcast from file headers — not just file size.
- **Auto ECM Output Format** — Auto-detects extracted format (ISO/BIN) after ECM decompression.
- **Integrity Verification** — Automatic post-conversion integrity check for CHD files via `chdman verify`.
- **Drag & Drop** — Native drag and drop support for single files and batch folders.
- **No Telemetry** — No network requests, no analytics, no cloud. Runs 100% locally.

---

## 🔁 Complete Conversion Matrix

| Input Format | Output Target | Tool Used | Notes |
|--------------|---------------|-----------|-------|
| ISO | CHD | chdman | `createcd` for PS1, `createdvd` for PS2/GC |
| ISO | CSO | maxcso | PSP/PS2 |
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
| XISO | ISO | extract-xiso | |
| RVZ | ISO | nodtool | GameCube / Wii |
| WIA | ISO | nodtool | GameCube / Wii |
| WBFS | ISO | nodtool | Wii |
| GCZ | ISO | nodtool | GameCube / Wii |

---

## 💻 CLI Usage

Every release includes `openrom-cli` alongside the GUI:

```bash
# Convert a single file
openrom-cli --input game.iso --format CHD

# Batch convert a folder
openrom-cli --folder /roms/ --format CHD --compression Max

# Verify a CHD
openrom-cli --input game.chd --verify-only

# List supported formats
openrom-cli --list-formats
```

---

## 🛠️ Tools Bundled

All tools are open source, built from source, and verifiable. See [SECURITY.md](SECURITY.md) for details.

| Tool | Purpose | License |
|------|---------|---------|
| **chdman** | CHD conversion (MAME) | GPL v2 |
| **maxcso** | PSP/PS2 CSO/ZSO compression | ISC |
| **ecm / unecm** | Error Code Modulator compression | GPL v2 |
| **extract-xiso** | Xbox ISO extraction & creation | GPL v2 |
| **nodtool** | GameCube / Wii RVZ/WIA/WBFS/GCZ | MIT |

---

## 🚀 Building & Running

### Requirements
- Python 3.10+
- Dependencies in `requirements.txt`

### Running from Source
```bash
git clone https://github.com/M5Devs/OpenROM
cd OpenROM
pip install -r requirements.txt
python main.py
```

### Building
```bash
# Windows
build_windows.bat

# Linux
./build_linux.sh

# macOS
./build_mac.sh
```

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to submit bug reports, feature requests, and pull requests.

---

## 📄 License

OpenROM is licensed under **GPL v3 + Commons Clause**.

This means:
- ✅ Free to use personally
- ✅ Free to study, modify, and contribute
- ✅ Forks must remain open source (GPL)
- ❌ Cannot be sold or bundled in a commercial product without written permission

For commercial licensing inquiries: [github.com/M5Devs/OpenROM](https://github.com/M5Devs/OpenROM) or Twitter/X: [M5Devs](https://x.com/M5Devs)
