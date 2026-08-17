# Tool Archive Notes

This folder contains build helpers and historical xEdit scripts used while creating or repairing `MMEAlert.esp`.

## Pascal/xEdit Scripts

The `.pas` files are retained for archival and reproducibility purposes. Run them only from SSEEdit with the required plugins loaded, and make a backup of `MMEAlert.esp` first.

These scripts modify plugin records:

- `AddMMEExtensionsMilkDialogue.pas`
- `AttachMMESkyrimNetVoiceControls.pas`
- `CreateMMEAlertMinimalSounds.pas`
- `CreateMMEAlertSoundMarkers.pas`
- `CreateMMEAlertSoundPools.pas`
- `InstallMMEAlertPlayerAlias.pas`
- `RepairMMEAlertPlayerMonitor.pas`

These scripts inspect records without intentionally changing them:

- `InspectMMEAlertSounds.pas`
- `InspectSkyrimNetPlayerAlias.pas`

The PowerShell and batch files in this folder are developer maintenance helpers and are not included in the game package.

## SDK Shims

`mme-sdk` includes small declaration-only shims for external Papyrus APIs used by the action bridge. They keep release builds independent of unrelated optional source dependencies; Skyrim resolves the real MME and SexLab implementations at runtime.
