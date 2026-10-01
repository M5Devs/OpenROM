# Patch Builder Feasibility Research Notes

## Overview
This document evaluates the feasibility of implementing patch builders (patch creation/encoding) for the remaining patch formats in OpenROM: PPF3, APS, DPS, SSP, and DCP.

---

## Format 1: PPF3 (Playstation Patch Format v3)
- **Status**: ✅ FEASIBLE — Implemented in `ppf_builder.dart`.
- **Details**: PPF3 uses a simple 56-byte header (`PPF3` magic, description, image type, block check flag, undo flag, padding) followed by records of `[8-byte LE offset][1-byte chunk size][chunk bytes]`.
- **Implementation**: `PpfBuilder` scans byte differences between original and modified files, writing chunks of modified data with 64-bit offsets.

---

## Format 2: APS (GBA & N64 Variants)
- **Status**: ✅ FEASIBLE — Implemented in `aps_gba_builder.dart` and `aps_n64_builder.dart`.
- **GBA Variant (`APS1`)**: Uses 64KB fixed chunks. Each chunk record carries original and modified CRC16-CCITT checksums along with a 64KB XOR patch buffer.
- **N64 Variant (`APS10`)**: Streamed format containing 73-byte header with N64 cartridge ID, country code, and ROM header CRC bytes (extracted from source N64 ROM header), followed by offset-based literal and RLE data records.

---

## Format 3: DPS (Direct Patch Stream)
- **Status**: ❌ NOT FEASIBLE — Format Obsolescence.
- **Reason**: DPS is an obscure/legacy format that is no longer used or supported by the retro gaming community (no active usage found on Romhacking.net or GitHub in recent years). Modern ROM hacking workflows exclusively use xdelta, BPS, UPS, or IPS.

---

## Format 4: SSP (Sega Saturn Patch)
- **Status**: ❌ NOT FEASIBLE — Binary tool limitation.
- **Reason**: SSP patches are handled via the external `saturn-patcher` binary (`https://github.com/knees/saturn-patcher`). The `saturn-patcher` CLI only accepts `saturn-patcher <patch.ssp> <track1.bin>` for patch application; it does not provide an encode/create mode or CLI option for patch creation.

---

## Format 5: DCP (Dreamcast Patch Container)
- **Status**: ❌ NOT FEASIBLE — High-level container format, not a byte-level diff.
- **Reason**: DCP is OpenROM's archive container format (`.dcp`) for Dreamcast games. It is a ZIP archive containing extracted directory structures, modified files, `IP.BIN` boot sectors, and/or nested `xdelta/` patch files. It is not a single-file byte-level binary diff builder format like IPS/BPS/PPF.
