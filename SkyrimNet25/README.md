# SkyrimNet 25 Packaging

This directory stores the maintained SkyrimNet 25 external-plugin metadata. The actions and prompts are not duplicated here. `build-package.ps1` generates them from the canonical files in `SkyrimNetActions/` and `SkyrimNetPrompts/`.

## Version split

- SkyrimNet 24 remains the default FOMOD installation. Its actions and prompts use the legacy loose directories beneath `SKSE/Plugins/SkyrimNet/`.
- Checking **Install SkyrimNet 25 compatibility** adds `SKSE/Plugins/SkyrimNet/external/s709gaming.mme-extensions/`.
- SkyrimNet 25 ignores the legacy loose prompt and action directories. They remain in the checked installation so one simple checkbox can provide the version split.
- The ESP, DLL, Papyrus scripts, JSON data, sounds, and OStim scene are shared by both versions.
- Milk Maid lore uses the actor-bio prompt decorator in both layouts and is injected only for actors confirmed as live MME Milk Maids.

## Maintenance

Edit actions and prompts only in their canonical top-level directories. The package builder lowercases each action's internal `name` to create the filename required by SkyrimNet 25 and preserves prompt subdirectories.

The concise lore text is maintained in `SkyrimNetPrompts/0260_mme_extensions_milkmaid.prompt`; its Papyrus decorator returns true only for a live MME Milk Maid.

When action or prompt content changes, increment the semantic `version` in `s709gaming.mme-extensions/manifest.json`. Do not package content under SkyrimNet's `library`, `overlay`, or `saves` directories.

## Version 25 troubleshooting

After installing with the checkbox enabled, completely restart Skyrim. In SkyrimNet, confirm **MME Extensions** appears under Installed Plugins with an **External** badge. A rejected plugin folder should show a reason there; individual skipped files are reported in `SKSE/Plugins/SkyrimNet/logs/SkyrimNet.log`.

Verify all six actions are listed. If the plugin is missing, first check that the installed folder name exactly matches the manifest ID. If only an action is missing, check its filename against its internal `name` and look for a validation warning in `SkyrimNet.log`.
