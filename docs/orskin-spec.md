# The `.orskin` Theme Bundle Specification

**Version 1** · OpenROM Universal Retro Gaming Toolkit · GPL v3

An `.orskin` is the official OpenROM theme/skin package. It is a plain **ZIP
archive** (any ZIP tool can open it) with a `.orskin` extension. Installing a
skin never requires compiling code — it is data only.

---

## 1. Archive layout

```
my-theme.orskin
├── theme.json      # REQUIRED — the skin manifest (see §2)
├── wallpaper.png   # optional — background image (png/jpg/jpeg/webp/bmp)
├── preview.png     # optional — swatch/screenshot shown in listings
└── README.md       # optional — creator notes, credits, licence
```

* `theme.json` must sit at the archive root (not inside a folder).
* Entry names are matched case-sensitively after normalising `\` to `/`.
* Hidden files, symlinks and any entry that resolves outside the archive root
  are **rejected** on import (see §5).

---

## 2. `theme.json`

```json
{
  "id": "cyberpunk-neon",
  "name": "Cyberpunk Neon",
  "author": "Claus Valca",
  "version": "1.0.0",
  "specVersion": 1,
  "mode": "dark",
  "borderRadius": 12.0,
  "wallpaperOpacity": 0.20,
  "wallpaperBlur": 5.0,
  "colors": {
    "background": "#0d0e15",
    "surface": "#161926",
    "card": "#1e2235",
    "accent": "#e94560",
    "accentSecondary": "#00f0ff",
    "text": "#ffffff",
    "textMuted": "#8b949e",
    "border": "#2d334d"
  },
  "openrom": {
    "sidebarBg": "#0b0c12",
    "terminalBg": "#05060a",
    "terminalText": "#00e676",
    "fontFamily": "Sans-Serif",
    "layout": "sidebar_left"
  }
}
```

### 2.1 Top-level fields

| Field              | Type   | Required | Notes |
|--------------------|--------|----------|-------|
| `id`               | string | yes      | Stable identifier. Sanitised to `[a-z0-9_-]`; used as the install folder name. |
| `name`             | string | yes      | Human-readable skin name. |
| `author`           | string | no       | Defaults to `"Unknown"`. |
| `version`          | string | no       | SemVer. Defaults to `"1.0.0"`. |
| `specVersion`      | int    | no       | `.orskin` spec revision. Current: `1`. |
| `mode`             | string | no       | `"dark"` (default) or `"light"`; drives which palette variant the skin targets. |
| `borderRadius`     | number | no       | Corner radius in logical px, clamped `0–24`. Default `12`. |
| `wallpaperOpacity` | number | no       | Wallpaper layer opacity, clamped `0.0–1.0`. Default `0.15`. |
| `wallpaperBlur`    | number | no       | Gaussian blur radius in px, clamped `0.0–20.0`. Default `0`. |
| `colors`           | object | yes      | See §2.2. |
| `openrom`          | object | no       | OpenROM-specific extensions, see §2.3. |

### 2.2 `colors` (portable palette)

Colours are `#RRGGBB` or `#AARRGGBB` hex strings. Unknown/malformed values fall
back to the default palette rather than failing the import.

| Key               | Maps to (OpenROM) | Notes |
|-------------------|-------------------|-------|
| `background`      | `ThemeConfig.background` | Window background. |
| `surface`         | `ThemeConfig.surface`    | Panels, dialogs, inputs. |
| `card`            | `ThemeConfig.cardBg`     | Cards. |
| `accent`          | `ThemeConfig.accent`     | Primary highlight/CTA. |
| `accentSecondary` | `ThemeConfig.accentSecondary` | Optional second accent. |
| `text`            | `ThemeConfig.textPrimary`   | Primary text. |
| `textMuted`       | `ThemeConfig.textSecondary` | Secondary text. |
| `border`          | `ThemeConfig.borderColor`   | Optional explicit border colour; when absent a translucent `textMuted` is derived. |

### 2.3 `openrom` (namespaced extensions)

The spec's `colors` map covers the portable palette; these keys are OpenROM
specific and live under a namespaced object so other readers can ignore them.

| Key            | Maps to | Notes |
|----------------|---------|-------|
| `sidebarBg`    | `ThemeConfig.sidebarBg` | Navigation sidebar background. |
| `terminalBg`   | `ThemeConfig.terminalBg` | Log/terminal panel background. |
| `terminalText` | `ThemeConfig.terminalText` | Log/terminal text. |
| `fontFamily`   | `ThemeConfig.fontFamily` | Font family name. |
| `layout`       | `ThemeConfig.layout` | `sidebar_left` or `sidebar_right`. |

---

## 3. Wallpaper

Place a `wallpaper.png` (or `.jpg`/`.jpeg`/`.webp`/`.bmp`) at the archive root.
On import OpenROM extracts it next to `theme.json` and points the palette's
`wallpaperPath` at the extracted copy — the original file is never referenced
directly, so a skin keeps working after the bundle is moved or deleted.

`wallpaperOpacity` and `wallpaperBlur` control how the wallpaper is composited
behind the UI.

---

## 4. Authoring & distribution

1. Build a palette in **Settings → Theme Editor**, or hand-write `theme.json`.
2. Export with **Settings → Export .orskin** (or **Theme Editor → Export**).
   OpenROM writes a valid ZIP with `theme.json` + any wallpaper.
3. Share the `.orskin`. Users install it via **Settings → Import .orskin**, the
   Theme Editor, or by dropping the file onto the window.

---

## 5. Security & limits

`.orskin` files are untrusted input. The importer enforces:

* **Zip-Slip protection** — every entry is canonicalised and must stay strictly
  inside the destination directory; `..` and absolute paths are rejected.
* **No symlinks** — any symbolic-link entry aborts the import.
* **No null bytes** in entry names.
* **Bounded resources** — max 512 entries, 64 MB archive, 32 MB per entry.
* **Manifest validation** — `theme.json` must be present and parseable.

A failed import leaves nothing on disk (the partial directory is removed).

---

## 6. Versioning

| `specVersion` | Changes |
|---------------|---------|
| 1             | Initial `.orskin` release: `theme.json`, portable `colors`, optional wallpaper, `openrom` extensions. |

Readers should ignore unknown keys and default any missing field.
