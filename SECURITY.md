# Security & Privacy

OpenROM is a local desktop application. This document covers our security practices, privacy policy, and bundled tool transparency.

---

## Privacy

### What We Collect
Nothing. OpenROM does not collect, transmit, or store any personal data.

### What Stays on Your Device
| What | Where | Why |
|------|-------|-----|
| Application settings | OS config directory | Save your preferences |
| Conversion logs | OS config directory `/logs/` | Debug and audit trail |

**OS config directory locations:**
- Windows: `%APPDATA%\OpenROM\`
- macOS: `~/Library/Application Support/OpenROM/`
- Linux: `~/.config/OpenROM/`

You can delete these files at any time.

### Your ROM Files
- Processed **entirely on your local machine**
- Never uploaded, scanned externally, or shared
- Temporary files are deleted automatically after each job

### Network Access
OpenROM makes **zero network requests**. No update checker, no analytics, no telemetry, no cloud sync.

---

## Bundled Tools — Transparency

Every binary bundled with OpenROM is open source, built from source via GitHub Actions, and verifiable.

| Tool | License | Source | Build |
|------|---------|--------|-------|
| `chdman` | GPL v2 | [mamedev/mame](https://github.com/mamedev/mame) | MAME official releases |
| `maxcso` | ISC | [unknownbrackets/maxcso](https://github.com/unknownbrackets/maxcso) | GitHub Actions |
| `ecm` / `unecm` | GPL v2 | [Neill Corlett](https://github.com/alucryd/ecm-tools) | Built from source |
| `extract-xiso` | GPL v2 | [XboxDev/extract-xiso](https://github.com/XboxDev/extract-xiso) | GitHub Actions |
| `nodtool` | MIT | [encounter/nod](https://github.com/encounter/nod) | GitHub Actions |

### Don't Trust Our Binaries?

Build them yourself:

```bash
# nodtool
cargo install --locked nodtool

# maxcso
git clone https://github.com/unknownbrackets/maxcso
cd maxcso && make

# chdman — part of MAME build
# https://github.com/mamedev/mame
```

---

## Reporting a Vulnerability

If you discover a security vulnerability in OpenROM:

1. **Do not open a public GitHub issue**
2. Open a **private** issue or contact us via:
   - GitHub: [M5Devs/OpenROM/issues](https://github.com/M5Devs/OpenROM/issues)
   - Twitter: [@M5Devs](https://x.com/M5Devs)

We aim to respond within **72 hours** and release a fix as soon as possible.

---

## Third-Party Tools — Licenses

OpenROM bundles third-party tools. Their licenses are installed alongside the app and are available in:

```
$INSTALL_DIR/licenses/
```

Each tool's license is also available at its source repository linked above.

---

*Last updated: 2026-08-23*
*M5 Dev — [github.com/M5Devs/OpenROM](https://github.com/M5Devs/OpenROM)*
