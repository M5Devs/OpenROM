# Translations & Localization in OpenROM

Thank you for helping make OpenROM accessible to gamers and preservationists around the world!

## 🌐 Translate via Crowdin

The easiest way to contribute a translation is through our Crowdin project — no Git knowledge needed:

**👉 https://crowdin.com/project/openrom**

[![Crowdin](https://badges.crowdin.net/openrom/localized.svg)](https://crowdin.com/project/openrom)

Just pick your language, start translating, and Crowdin will open a Pull Request automatically. Native speakers of any language are welcome!

---

## Contributing Translations via Git

Prefer working directly with files? OpenROM uses Flutter's standard Application Resource Bundle (`.arb`) format.
All translation files are located in `gui/lib/l10n/`.

### How to Add a New Language

1. **Copy the Template**:
   Copy `gui/lib/l10n/app_en.arb` to `gui/lib/l10n/app_<locale>.arb` (e.g., `app_de.arb` for German).

2. **Update Locale Header**:
   Set `"@@locale": "<locale>"` at the top of your new ARB file.

3. **Translate Strings**:
   Translate all string values into your target language.

   > **Important Rules**:
   > - Do **NOT** translate: `"OpenROM"`, `"ROMeo"`, format names (`CHD`, `ISO`, `CSO`, `ECM`, `RVZ`, `XISO`), or platform names (`PS1`, `PS2`, `GameCube`, `Xbox`, `PSP`).
   > - Preserve placeholder variables such as `{count}` without modifying the variable name inside brackets.

4. **Add Locale to `LocaleProvider`**:
   In `gui/lib/providers/locale_provider.dart`:
   - Add `Locale('<locale>')` to `supportedLocales`.
   - Update `getNativeName` to return the native name of your language (e.g., `'Deutsch'` for `'de'`).

5. **Test Your Changes**:
   Run `flutter gen-l10n` and `flutter test` inside `gui/`.

6. **Submit a Pull Request**:
   Commit your changes and open a PR on GitHub!

---

## Translators & Contributors

Special thanks to the community members contributing localizations:

| Language | Code | Status | Maintainer |
|----------|------|--------|------------|
| English | `en` | ✅ Complete | OpenROM Team |
| Arabic | `ar` | ✅ Complete | [@clausvalcatd](https://github.com/clausvalcatd) |
| French | `fr` | 🔴 Need Translation — native review welcome! | [Contribute →](https://crowdin.com/project/openrom) |
| Spanish | `es` | 🔴 Need Translation — native review welcome! | [Contribute →](https://crowdin.com/project/openrom) |
| Japanese | `ja` | 🔴 Need Translation — native review welcome! | [Contribute →](https://crowdin.com/project/openrom) |
| Portuguese | `pt` | 🔴 Need Translation — native review welcome! | [Contribute →](https://crowdin.com/project/openrom) |
| German | `de` | 🔴 Need Translation — native review welcome! | [Contribute →](https://crowdin.com/project/openrom) |
| Italian | `it` | 🔴 Need Translation — native review welcome! | [Contribute →](https://crowdin.com/project/openrom) |
| Russian | `ru` | 🔴 Need Translation — native review welcome! | [Contribute →](https://crowdin.com/project/openrom) |
| Turkish | `tr` | 🔴 Need Translation — native review welcome! | [Contribute →](https://crowdin.com/project/openrom) |
| Chinese Simplified | `zh` | 🔴 Need Translation — native review welcome! | [Contribute →](https://crowdin.com/project/openrom) |

> **Want to maintain a language?** Translate via Crowdin or open a PR and your name will be listed here
