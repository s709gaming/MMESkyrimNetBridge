# Simplified Chinese edition

- Select **Chinese (Simplified)** on the final FOMOD Language page. English and Russian remain available; choose dashboard and compatibility options independently.
- Translates Extensions' supplied MCM text, messages, stories, dialogue and Magelight labels. Original MME and other mods need their own translations. Recorded voices are unchanged.
- Skyrim's interface fonts must support Chinese characters. The installer does not replace your font configuration. Magelight uses a separate HTML renderer; its font support must also be checked in game.
- Personal text and presets remain unchanged and take precedence. Reset Edited Text restores the selected language's supplied defaults after saving. Restart Skyrim after reinstalling with a different language.
- Translation wording is a machine-assisted draft. Native-speaker proofreading and in-game font/layout acceptance remain necessary.

## Maintaining English, Russian and Chinese

All languages share the same gameplay scripts, native loader, dashboard adapter and placeholder validation. Translation data stays separate from settings and personal edits.

1. Run `python tools/localization/inventory.py` after changing display text.
2. Update `tools/localization/strings/ru.json` and `strings/zh-CN.json`; curated corrections belong in `manual_ru.json` and `manual_zh-CN.json`.
3. Run `python tools/localization/generate.py`. This is deterministic and needs no network connection. It creates language data and text-only plugin copies for the installer.
4. Run `tools/Test-Localization.ps1`, the existing dashboard tests and the package checks. Check both languages whenever the shared loader or adapter changes.

`translate.py` is an optional network-based drafting aid, never a build dependency. It uses `MME_TRANSLATION_LANGUAGE` (`ru` or `zh-CN`) and sends only the checked-in English text inventory for translation. Review its output before shipping. Preserve every placeholder, stable identifier and structural key.

Adding or changing ordinary text needs data updates. Adding another supported language also requires the loader allowlist, generator mapping and installer choice to agree.
