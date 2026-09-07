// SPDX-License-Identifier: GPL-3.0-or-later
// Ported from Final ROM (https://github.com/eon-com/final_rom) and
// UniPatcher (https://github.com/btimofeev/UniPatcher) — both GPL v3.
// Adapted for OpenROM by M5 Dev.
/// Buffer size constants for OpenROM patchers.
/// Ported from Final ROM (GPL v3) — only patch-relevant constants kept.
library;

const int _mib = 1024 * 1024;

/// Copy/CRC buffer for ROM patchers (IPS/PPF/APS/UPS/BPS).
const int patchCopyBufferSize = 1 * _mib;

/// Read buffer for file hashing (CRC32).
const int hashReadBufferSize = 4 * _mib;
