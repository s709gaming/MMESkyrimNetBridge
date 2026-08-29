# Tool Archive Notes

This folder contains build helpers and historical xEdit scripts used while creating or repairing `MMEAlert.esp`.

## Pascal/xEdit Scripts

The `.pas` files are retained for archival and reproducibility purposes. Run them only from SSEEdit with the required plugins loaded, and make a backup of `MMEAlert.esp` first.

These scripts modify plugin records:

- `AddMMEExtensionsMilkDialogue.pas`
- `AddMMEExtensionsNewMilkMaidDialogue.pas`
- `AttachMMESkyrimNetVoiceControls.pas`
- `CreateMMEAlertMinimalSounds.pas`
- `CreateMMEAlertSoundMarkers.pas`
- `CreateMMEAlertSoundPools.pas`
- `InstallMMEAlertPlayerAlias.pas`
- `InstallMMEBlacksmithArmorService.pas`
- `RepairMMEAlertPlayerMonitor.pas`

### Blacksmith Armor Service installer

`InstallMMEBlacksmithArmorService.pas` installs the Blacksmith-only armor
service into `MMEAlert.esp`. It creates a top-level service branch, linked
topics/INFOs, dialogue globals, conditions, and the VMAD fragments that call
`MMEVendorServices.psc`.

1. Back up `MMEAlert.esp`.
2. Copy the Pascal file into SSEEdit's `Edit Scripts` folder.
3. Start SSEEdit with `Skyrim.esm`, `MilkModNEW.esp`, and `MMEAlert.esp`
   loaded, with `MMEAlert.esp` after its masters.
4. Right-click any loaded record, choose **Apply Script**, select
   `InstallMMEBlacksmithArmorService`, and run it.
5. Confirm the Messages tab ends with the success summary, then save
   `MMEAlert.esp`.

The installer uses stable EditorIDs and updates its own records on rerun. It
aborts on duplicate generated EditorIDs or missing authoritative records rather
than guessing. Install the newly compiled `MMEVendorServices.pex` alongside the
updated plugin before testing in game.

After SSEEdit's background loader finishes, the installer should normally take
seconds rather than minutes. If an older run aborts after creating records,
prefer closing without saving. If that partial plugin was already saved, the
current installer reuses its stable records and removes the unintended vanilla
INFO children produced by the earlier deep-copy implementation.

These scripts inspect records without intentionally changing them:

- `InspectMMEAlertSounds.pas`
- `InspectMMEExtensionsNewMilkMaidSource.pas`
- `InspectSkyrimNetPlayerAlias.pas`

The PowerShell and batch files in this folder are developer maintenance helpers and are not included in the game package.

## SDK Shims

`mme-sdk` includes small declaration-only shims for external Papyrus APIs used by the action bridge. They keep release builds independent of unrelated optional source dependencies; Skyrim resolves the real MME and SexLab implementations at runtime.
