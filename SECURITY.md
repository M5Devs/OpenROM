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

## Antivirus False Positives

Some antivirus tools may flag OpenROM's release ZIP. This is a **known false positive** caused by bundled emulation binaries — not actual malware.

### Why It Happens
OpenROM bundles open-source tools (`chdman`, `maxcso`, `ecm`, `xdelta3`, etc.) as native executables. Antivirus heuristic engines sometimes flag:
- ZIPs containing multiple executables (`spreader` heuristic)
- Compression tools that use SIMD/AVX2 instructions (`ml.score` trigger)
- Tools that launch child processes (`sets-process-name` heuristic)

All of these are normal behaviors for emulation and ROM tools — not indicators of malware.

### Verified Detection History
| Release | VirusTotal Score | Notes |
|---------|-----------------|-------|
| v2.6.0 (PyInstaller) | 27/67 | PyInstaller heuristic pattern |
| v2.6.1 (Nuitka) | 14/67 | Remaining flags from bundled tools only |

### Which Tools Are Flagged and Why
| Tool | Flagged By | Reason |
|------|-----------|--------|
| `ecm.exe` | MaxSecure only | `suspicious.gen` — heuristic false positive on compression tools |
| `maxcso.exe` | Trapmine only | `ml.score` — ML heuristic triggered by SIMD-heavy compression code |

### How to Verify Yourself
If you don't trust our binaries — don't. Verify the SHA256 checksums below, or build the tools yourself from their open-source repositories.

---

## Bundled Tools — Transparency

Every binary bundled with OpenROM is open source, built from source, and verifiable.

| Tool | License | Source | Build |
|------|---------|--------|-------|
| `chdman` | GPL v2 | [mamedev/mame](https://github.com/mamedev/mame) | MAME official releases |
| `maxcso` | ISC | [unknownbrackets/maxcso](https://github.com/unknownbrackets/maxcso) | GitHub Actions |
| `ecm` / `unecm` | GPL v2 | [alucryd/ecm-tools](https://github.com/alucryd/ecm-tools) | Built from source |
| `extract-xiso` | GPL v2 | [XboxDev/extract-xiso](https://github.com/XboxDev/extract-xiso) | GitHub Actions |
| `nodtool` | MIT | [encounter/nod](https://github.com/encounter/nod) | GitHub Actions |
| `xdelta3` | Apache 2.0 | [jmacd/xdelta](https://github.com/jmacd/xdelta) | GitHub Actions |

### Don't Trust Our Binaries?

Build them yourself:

```bash
# nodtool
cargo install --locked nodtool

# maxcso
git clone https://github.com/unknownbrackets/maxcso
cd maxcso && make

# xdelta3
git clone https://github.com/jmacd/xdelta
cd xdelta/xdelta3 && ./configure && make

# chdman — part of MAME build
# https://github.com/mamedev/mame
```

---

## SHA256 Checksums

Verify the bundled binaries against these checksums before running OpenROM.

### Windows
```
972cad9fc243ba8d393cd9bfe566af0740e9df543b628b076b99fe77b8d24d20  chdman.exe
d49e12f3ebb6d75ed59d95368ed323f7ab2b0f5351e42fd7417ff43593cacb81  ecm.exe
7c7af9c17e095c3c1e78e644df5f0e72f01c4690b3117f038aafe26eb5a8a2f4  extract-xiso.exe
05f90b74c4ccdb48f93f9e4c51cc96eb959fd7596d79ba80cf6d8008495fadfb  maxcso.exe
139ec57bea9b184497a19190c44414508c9aca45b99f29d9086cf084f95288d1  nodtool.exe
45f597a50d868f2fce11877f52983b2097cf6b9ac569c35122cc3fdc28d03705  unecm.exe
53d90226615f217d3380c39892833311b4e24acd863e1ca01f14b5e772e2e6d0  xdelta3.exe
```

**Verify on Windows (PowerShell):**
```powershell
Get-FileHash .\assets\windows\chdman.exe -Algorithm SHA256
```

### Linux
```
88c4a766745d6610da26a2c9c34919336d82e073c165e5fffed620a464fddb4c  chdman
bb1bb971985fed6a8d92a2e8bebd6a41cfaa775879b462636dd25c78fba06b42  ecm
5d3405746601b723a67fdd5db06e6c225943a9513001f6e80643373f3ed3e947  extract-xiso
1e4a395b104ed4ffe8127bcf665e98738b5061bc6548552c5338552f14699ba3  maxcso
690c8de88589b8831b8d0064eb98048ad86610b77f4ef2ece41e370b1a6c6d2e  nodtool
5b5f1077fcd0fdbd105a5edc95c3e580ab4291242936a40677554e8458fdc5af  unecm
0d38d86de5ab6bbc1adae531331d64585b5a09ce3604a5f090c27f71b6a64b23  xdelta3
```

**Verify on Linux:**
```bash
sha256sum assets/linux/chdman
```

### macOS (Apple Silicon — arm64)
```
375a31e0fe0b3bc55dbc03cadd29ddc698a5f0fc8b03bb1aff658b1a3c74fede  chdman
8eb577701167b22a4bd8226475a653a831d01e9aa4204e3d6468acea3e8bb3e5  ecm
a46e8f9e0384e47b8a933a8709124c93a0aefe46105adb4678c5e7f9902afcc4  extract-xiso
1b3bf24ee995f7313b5ba9d89afcd40e69bdf331020f42635ad1996a2c9b9e3e  maxcso
206f78c3598fe66d277fbace86f9cb7e163f92a9e5881df2354aced452b7ce91  nodtool
99eafff431f343f352a24cf5dafe5ef43c8b67178e0f4249b3fdcdaf2067ed4b  unecm
244a2643774155ab7dc563258a203674feafbbddc7f1f4a4f4486b00e78c1941  xdelta3
```

### macOS (Intel — x86_64)
```
b0e143f52ce4ad0505a859914154efee13900609d047e9d885bf0ed552892c16  chdman
114079a1b564d487adea99d0c30f505709158f10f7033dd0d765c1f7fc16784e  ecm
a46e8f9e0384e47b8a933a8709124c93a0aefe46105adb4678c5e7f9902afcc4  extract-xiso
5e61a500d54e565cb88266d2346cdb9cc864e15316a59933872cee5ffc3dbd0d  maxcso
4603f0171fda5f4beae794dec84d423e3bb5309c34f5af9842d38ab2507d2bb6  nodtool
06b1e0fe9574a140f7b7aab70155e3415e631c90be3184b33f396cdb9a2cf113  unecm
244a2643774155ab7dc563258a203674feafbbddc7f1f4a4f4486b00e78c1941  xdelta3
```

**Verify on macOS:**
```bash
shasum -a 256 assets/macos/arm64/chdman
```

---

## Reporting a Vulnerability

If you discover a security vulnerability in OpenROM:

1. **Do not open a public GitHub issue**
2. Use **GitHub Security Advisories** (private & encrypted):
   👉 [github.com/M5Devs/OpenROM/security/advisories/new](https://github.com/M5Devs/OpenROM/security/advisories/new)

We aim to respond within **72 hours** and release a fix as soon as possible.

---

## Third-Party Tools — Licenses

OpenROM bundles third-party tools. Their licenses are installed alongside the app:

```
$INSTALL_DIR/licenses/
```

Each tool's license is also available at its source repository linked above.

---

*Last updated: 2026-09-13*
*M5 Dev — [github.com/M5Devs/OpenROM](https://github.com/M5Devs/OpenROM)*
