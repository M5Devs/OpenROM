# The `.orskin` Theme Bundle Specification

**Version 2** · OpenROM Universal Retro Gaming Toolkit · GPL v3

An `.orskin` is the official OpenROM skin package. It is a plain **ZIP archive**
(any ZIP tool can open it) with an `.orskin` extension. Installing a skin never
requires compiling code — it is data only.

Version 2 turns `.orskin` from a colour palette into a full skinning engine with
four pillars:

| Pillar | What it adds | Runtime support |
|--------|--------------|-----------------|
| **A** | Dynamic runtime fonts | `font.ttf`/`font.otf`, loaded at runtime without a restart |
| **B** | Animated GIF wallpapers & dropzones | `wallpaper.*`, `dropzone.*` |
| **C** | Custom icon packs | `icons/<tab>.png` sidebar overrides |
| **D** | Modular navigation | `hiddenTabs` hides tabs and clamps navigation |

Every v2 field is optional; a v1 bundle keeps working unchanged (§7).

---

## 1. Archive layout

```
my-theme.orskin
├── skin.json          # REQUIRED — the skin manifest (see §2)
├── wallpaper.gif      # optional — animated/static background (gif/png/jpg/jpeg/webp)
├── dropzone.gif       # optional — dropzone illustration (gif/png)
├── font.ttf           # optional — runtime-loaded UI font (ttf/otf)
├── icons/             # optional — sidebar icon overrides (see §5)
│   ├── home.png
│   ├── tools.png
│   └── settings.png
├── preview.png        # optional — swatch/screenshot shown in listings
└── README.md          # optional — creator notes, credits, licence
```

* `skin.json` must sit at the archive root (not inside a folder).
* Assets are matched case-sensitively after normalising `\` to `/`.
* Hidden files, symlinks and any entry that resolves outside the archive root
  are **rejected** on import (see §8).
* Exports are deterministic: entries are written in sorted order with a fixed
  timestamp, so identical inputs produce byte-identical `.orskin` files.

---

## 2. `skin.json`

```json
{
  "id": "cyberpunk-neon",
  "name": "Cyberpunk Neon",
  "author": "Claus Valca",
  "version": "2.0.0",
  "specVersion": 2,
  "mode": "dark",
  "hasCustomFont": true,
  "fontFileName": "font.ttf",
  "hasCustomIcons": true,
  "hasCustomDropzone": true,
  "hiddenTabs": ["dreamcast"],
  "ui": {
    "borderRadius": 12.0,
    "wallpaperOpacity": 0.20,
    "wallpaperBlur": 5.0
  },
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

| Field               | Type   | Required | Notes |
|---------------------|--------|----------|-------|
| `id`                | string | yes      | Stable identifier. Sanitised to `[a-z0-9_-]`; used as the install folder name. |
| `name`              | string | yes      | Human-readable skin name. |
| `author`            | string | no       | Defaults to `"Unknown"`. |
| `version`           | string | no       | SemVer. Defaults to `"1.0.0"`. |
| `specVersion`       | int    | no       | `.orskin` spec revision. Current: `2`. |
| `mode`              | string | no       | `"dark"` (default) or `"light"`; drives which palette variant the skin targets. |
| `hasCustomFont`     | bool   | no       | The bundle ships a runtime font (§4). |
| `fontFileName`      | string | no       | File name of that font, e.g. `"font.ttf"`. |
| `hasCustomIcons`    | bool   | no       | The bundle ships `icons/` overrides (§5). |
| `hasCustomDropzone` | bool   | no       | The bundle ships a `dropzone.*` illustration (§3). |
| `hiddenTabs`        | array  | no       | Tab ids to hide (§6). Unknown ids are ignored. |
| `ui`                | object | no       | Geometry block, see §2.4. |
| `colors`            | object | yes      | See §2.2. |
| `openrom`           | object | no       | OpenROM-specific extensions, see §2.3. |

The `has*` flags and `fontFileName` are advisory hints used to pick the right
asset fast; import still resolves assets by canonical file name (§3–§5), so a
bundle with a missing flag still works.

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
| `fontFamily`   | `ThemeConfig.fontFamily` | Font family name (used when no runtime font is bundled). |
| `layout`       | `ThemeConfig.layout` | `sidebar_left` or `sidebar_right`. |

### 2.4 `ui` (geometry)

v2 nests geometry under a `ui` object. Writers should also mirror the values at
the top level for v1 readers (§7).

| Key                | Type   | Default | Clamp | Notes |
|--------------------|--------|---------|-------|-------|
| `borderRadius`     | number | `12`    | 0–24  | Corner radius in logical px. |
| `wallpaperOpacity` | number | `0.15`  | 0.0–1.0 | Wallpaper layer opacity. |
| `wallpaperBlur`    | number | `0`     | 0.0–20.0 | Gaussian blur radius in px. |

---

## 3. Wallpapers & dropzones (Pillar B)

Place a `wallpaper.<ext>` at the archive root for the background, and a
`dropzone.<ext>` for the drag-and-drop illustration. Recognised extensions are
`.gif`, `.webp`, `.png`, `.jpg`, `.jpeg` (dropzones: `.gif`, `.png`).

* On import OpenROM extracts each asset next to `skin.json` and points the
  palette's `wallpaperPath`/`dropzonePath` at the extracted copy — the original
  file is never referenced directly, so a skin keeps working after the bundle is
  moved or deleted.
* **Animated GIF/WebP wallpapers and dropzones loop automatically.** No extra
  markup is needed: the runtime decodes multi-frame images natively.
* If no `dropzone.*` is present the built-in dropzone icon is used.
* `wallpaperOpacity` and `wallpaperBlur` (§2.4) control how the wallpaper is
  composited behind the UI.

---

## 4. Dynamic runtime fonts (Pillar A)

Ship a single font as `font.ttf` or `font.otf` at the archive root (the
`fontFileName` hint may name it differently). On import OpenROM registers it as
the `SkinCustomFont` family via Flutter's `FontLoader` and applies it to the
global `ThemeData` **without an app restart**.

* A missing, empty or corrupt font is ignored: the theme falls back to its
  `fontFamily` (§2.3) and the rest of the skin still loads.
* The font is applied when the skin is selected and re-applied on startup.
* Only one runtime font per skin is supported; the last one wins.

---

## 5. Custom icon packs (Pillar C)

Ship a `icons/` folder containing PNGs named after the navigation tab they
replace:

```
icons/home.png
icons/tools.png
icons/settings.png
```

* The file name (minus `.png`) must be one of the canonical tab ids in §6.
  Files named after unknown tabs are ignored by the packer.
* Icons are drawn at their natural colours at 24×24 logical px; a broken or
  unreadable icon falls back to the built-in Material icon rather than blanking
  the sidebar.
* Tabs without an override keep their built-in icon, so a partial icon pack is
  valid.

---

## 6. Modular navigation (Pillar D)

`hiddenTabs` lists canonical tab ids the skin hides:

| Tab id      | Default screen |
|-------------|----------------|
| `home`      | Convert / queue |
| `patcher`   | Patcher |
| `tools`     | Tools |
| `dreamcast` | Dreamcast |
| `plugins`   | Plugins |
| `settings`  | Settings |
| `about`     | About |
| `theme`     | Theme Editor |

* Ids outside this list are dropped on load.
* Hidden tabs disappear from the sidebar and the compact bottom navigation bar.
* If the currently-selected tab is hidden, navigation clamps to the first
  visible tab — the UI can never be stranded on a hidden screen.
* The icon-pack keys in §5 use the same ids.

---

## 7. Compatibility with v1

A v1 bundle (named `theme.json`, flat geometry, no assets) still imports: every
v2 field is optional and falls back to its v1 default. `theme.json` and
`skin.json` are both accepted on import; if an archive contains both,
`skin.json` wins.

Writers targeting both readers should emit the v2 `ui` block **and** mirror
`borderRadius`/`wallpaperOpacity`/`wallpaperBlur` at the top level, as OpenROM
does.

---

## 8. Security & limits

`.orskin` files are untrusted input. The importer enforces:

* **Zip-Slip protection** — every entry is canonicalised and must stay strictly
  inside the destination directory; `..` and absolute paths are rejected.
* **No symlinks** — any symbolic-link entry aborts the import.
* **No null bytes** in entry names.
* **Bounded resources** — max 512 entries, 64 MB archive, 32 MB per entry.
* **Manifest validation** — `skin.json` (or `theme.json`) must be present and
  parseable.

A failed import leaves nothing on disk (the partial directory is removed).

---

## 9. Authoring & distribution

1. Build a palette in **Settings → Theme Editor**, or hand-write `skin.json`.
2. Pick a wallpaper, dropzone and font in the Theme Editor; toggle the tabs to
   show or hide.
3. Export with **Settings → Export .orskin** (or **Theme Editor → Export**).
   OpenROM writes a valid, deterministic ZIP with `skin.json` plus every asset.
4. Share the `.orskin`. Users install it via **Settings → Import .orskin**, the
   Theme Editor, or by dropping the file onto the window.

---

## 10. Versioning

| `specVersion` | Changes |
|---------------|---------|
| 1             | Initial `.orskin` release: `theme.json`, portable `colors`, optional wallpaper, `openrom` extensions. |
| 2             | Runtime fonts, animated GIF wallpapers/dropzones, custom icon packs, modular navigation (`hiddenTabs`); geometry moved under `ui`; manifest renamed to `skin.json` (v1 `theme.json` still read). |

Readers should ignore unknown keys and default any missing field.
