# Translations & Localization in OpenROM

Thank you for helping make OpenROM accessible to gamers and preservationists around the world!

## Contributing Translations

OpenROM uses Flutter's standard Application Resource Bundle (`.arb`) format for localizations.
All translation files are located in `openrom_flutter/lib/l10n/`.

### How to Add a New Language

1. **Copy the Template**:
   Copy `openrom_flutter/lib/l10n/app_en.arb` to `openrom_flutter/lib/l10n/app_<locale>.arb` (e.g., `app_de.arb` for German).

2. **Update Locale Header**:
   Set `"@@locale": "<locale>"` at the top of your new ARB file.

3. **Translate Strings**:
   Translate all string values into your target language.

   > **Important Rules**:
   > - Do **NOT** translate: `"OpenROM"`, `"ROMeo"`, format names (`CHD`, `ISO`, `CSO`, `ECM`, `RVZ`, `XISO`), or platform names (`PS1`, `PS2`, `GameCube`, `Xbox`, `PSP`).
   > - Preserve placeholder variables such as `{count}` without modifying the variable name inside brackets.

4. **Add Locale to `LocaleProvider`**:
   In `openrom_flutter/lib/providers/locale_provider.dart`:
   - Add `Locale('<locale>')` to `supportedLocales`.
   - Update `getNativeName` to return the native name of your language (e.g., `'Deutsch'` for `'de'`).

5. **Test Your Changes**:
   Run `flutter gen-l10n` and `flutter test` inside `openrom_flutter/`.

6. **Submit a Pull Request**:
   Commit your changes and open a PR on GitHub!

---

## Translators & Contributors

Special thanks to the community members contributing localizations:

- **English (`en`)**: OpenROM Team
- **Arabic (`ar`)**: OpenROM Team
- **Spanish (`es`)**: OpenROM Team
- **French (`fr`)**: OpenROM Team
- **Japanese (`ja`)**: OpenROM Team
- **Portuguese (Brazilian) (`pt`)**: OpenROM Team
