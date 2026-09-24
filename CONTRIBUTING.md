# Contributing to OpenROM

Thanks for taking the time to contribute! OpenROM is a community-driven project and every contribution matters — whether it's a bug report, a new format, or a fix for a typo.

---

## Table of Contents

- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)
- [Pull Requests](#pull-requests)
- [Adding a New Conversion Format](#adding-a-new-conversion-format)
- [Building Bundled Tools (Linux)](#building-bundled-tools-linux)
- [Code Style](#code-style)

---

## Reporting Bugs

Before opening an issue, please:

1. Check that you're running the latest version of OpenROM.
2. Search existing issues to make sure it hasn't been reported already.

When opening a bug report, include:

- **OS and version** (e.g. Windows 11, Ubuntu 22.04)
- **Dart version** (`dart --version`)
- **Steps to reproduce** — what file, what conversion, what settings
- **Expected behavior** vs **what actually happened**
- **Log file** — found in:
  - Windows: `%APPDATA%\OpenROM\logs\`
  - Linux: `~/.config/openrom/logs\`
  - macOS: `~/Library/Application Support/OpenROM/logs\`

---

## Suggesting Features

Open an issue with the `enhancement` label and describe:

- What problem does this solve?
- What should the user experience look like?
- Any tools or references that could help implement it?

---

## Pull Requests

1. **Fork** the repository and create a branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** — keep commits focused and descriptive.

3. **Test your changes** before submitting:
   - Run a real conversion end-to-end
   - Check the live terminal log for errors
   - Test on your OS if possible

4. **Open a Pull Request** against `main` with:
   - A clear title describing what changed
   - A short description of why
   - Screenshots or terminal output if relevant

---

## Adding a New Conversion Format

OpenROM's conversion logic lives in two files:

| File | What to edit |
|------|-------------|
| `core/lib/src/detector.dart` | Add the new extension to `SUPPORTED_INPUT`, `CONVERSION_MAP`, and `COMMAND_TEMPLATES` |
| `core/lib/src/converter.dart` | Add the conversion route in `_dispatch()` and implement the method |

### Example — adding a new input format `XYZ`:

**`core/lib/src/detector.dart`:**
```dart
const Map<String, String> supportedInput = {
  // ...
  '.xyz': 'XYZ',
};

const Map<String, List<String>> conversionMap = {
  // ...
  'XYZ': ['CHD', 'ISO'],
};
```

**`core/lib/src/converter.dart`:**
```dart
Future<ConversionResult> _dispatch(ConversionJob job) async {
  // ...
  final fmt = job.sourceFormat;
  final tgt = job.targetFormat;
  final src = job.sourcePath;

  if (fmt == 'XYZ' && tgt == 'CHD') {
    return _xyzToChd(job, src);
  }
  // ...
}

Future<ConversionResult> _xyzToChd(ConversionJob job, String src) async {
  final tool = Config.getToolPath('your_tool');
  final out  = _outPath(job, src, '.chd');
  final cmd  = [tool, '-i', src, '-o', out];

  AppLogger.info('[XYZ→CHD] ${path.basename(src)}');
  return _run(cmd, job);
}
```

Make sure the tool binary is available or document how to install it.

---

## Building Bundled Tools (Linux)

If you want to contribute pre-built Linux binaries to `assets/linux/`, here's how to build them cleanly using Google Colab (free):

### chdman
```bash
sudo apt install mame-tools
cp $(which chdman) assets/linux/chdman
```

### ecm / unecm
```bash
git clone https://github.com/kidoz/ecm ecm_src
echo '#define ECM_VERSION "2.0.0"' > ecm_src/include/version.h

gcc -O2 -x c -Dnullptr=NULL -Wno-incompatible-pointer-types \
    -o assets/linux/ecm \
    ecm_src/src/ecm.c ecm_src/src/eccedc.c \
    -I ecm_src/include -lm

gcc -O2 -x c -Dnullptr=NULL -Wno-incompatible-pointer-types \
    -o assets/linux/unecm \
    ecm_src/src/unecm.c ecm_src/src/eccedc.c \
    -I ecm_src/include -lm
```

### maxcso
```bash
sudo apt install libuv1-dev liblz4-dev
git clone --depth=1 https://github.com/unknownbrackets/maxcso
cd maxcso && make -j$(nproc)
cp maxcso ../assets/linux/maxcso
```

### extract-xiso
Download the official Linux binary from the
[extract-xiso releases page](https://github.com/XboxDev/extract-xiso/releases)
and place it at `assets/linux/extract-xiso`.

---

## Code Style

OpenROM follows a few simple conventions:

- **Dart 3.0+** — use modern syntax (patterns, records, sealed classes)
- **Type hints** on all function signatures
- **Log everything** through `core/lib/src/logger.dart` — never use bare `print()` in core logic
- **No hardcoded paths** — always use `core/lib/src/config.dart` for tool and directory resolution
- **One class per file** in `ui/` — keep windows self-contained
- **Thread safety** — any background operation goes in a thread; never block the UI

---

## License

By contributing to OpenROM, you agree that your contributions will be licensed under the **GPL v3** license.
