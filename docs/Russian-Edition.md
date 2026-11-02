# Russian edition

- Choose **Russian** on the FOMOD language page. Choose animation and compatibility options as usual. English remains the default.
- Covers MME Extensions' MCM, supplied messages and stories, Extensions dialogue and the Magelight dashboard. Original Milk Mod Economy and other mods need their own translations.
- Skyrim must already have fonts that support Cyrillic. This option does not replace font configuration or translate recorded voices.
- Personal text and presets take precedence over supplied translations. Reset Edited Text uses Russian defaults; saving applies the reset. Export your edits first if you want a backup.
- Reinstall with English selected to return to English. Restart Skyrim after changing language. Keep the DLL, scripts and language data from the same package together.
- Missing or invalid language data falls back to English and emits a deduplicated Papyrus failure report. Routine initialization follows the master Papyrus logging setting.

The translation data is maintained under `tools/localization`. `generate.py` builds installer payloads without network access. Translation changes must preserve placeholders and structural keys. Russian plugin copies change display text only; form IDs, conditions and script attachments remain intact.

The Russian wording includes machine-assisted draft translations and should receive native-speaker review. Language switching, fonts and presentation also require in-game acceptance after installation.
