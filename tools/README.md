# Tool Archive Notes

This folder contains build helpers and historical xEdit scripts used while creating or repairing `MMEAlert.esp`.

## Pascal/xEdit Scripts

The `.pas` files are retained for archival and reproducibility purposes. Run them only from SSEEdit with the required plugins loaded, and make a backup of `MMEAlert.esp` first.

### Deferred Blacksmith dialogue step (Vortex)

`AddMMEExtensionsBlacksmithDialogue.pas` is prepared but has not been run. When manual intervention resumes:

1. Deploy the current mod and its dependencies through Vortex.
2. Start SSEEdit against the deployed game `Data` directory and load `Skyrim.esm`, `MilkModNEW.esp`, `MMEAlert.esp`, plus every plugin that touches MME's `[MME] Hey there!` DIAL `06544A` or INFO `06544B`.
3. Confirm `MMEAlert.esp` is the winning override for both records. The installer aborts if another override wins or if the winner has already dropped a link/INFO supplied by an earlier override.
4. Run `AddMMEExtensionsBlacksmithDialogue.pas`, review its log, run **Check for Errors** on `MMEAlert.esp`, and save.
5. Copy the saved deployed `MMEAlert.esp` back to the repository root before building the release package.

The installer adds one Global, two DIALs, two INFOs, and two links. It reuses MME's existing branch and quest; no new DLBR, QUST, or SEQ is needed. The new responses are unvoiced and use forced subtitles inherited from the proven source INFO.

These scripts modify plugin records:

- `AddMMEExtensionsBlacksmithDialogue.pas` (prepared but must be run manually in SSEEdit; load all MME Hey there dialogue conflicts and require `MMEAlert.esp` to win)
- `AddMMEExtensionsAlchemistDialogue.pas` (run after the Blacksmith installer; extends its existing opening wrapper with the Alchemist Living Armor state and choices)
- `AddMMEExtensionsMilkDialogue.pas`
- `AddMMEExtensionsNewMilkMaidDialogue.pas`
- `AttachMMESkyrimNetVoiceControls.pas`
- `CreateMMEAlertMinimalSounds.pas`
- `CreateMMEAlertSoundMarkers.pas`
- `CreateMMEAlertSoundPools.pas`
- `InstallMMEAlertPlayerAlias.pas`
- `RepairMMEAlertPlayerMonitor.pas`

These scripts inspect records without intentionally changing them:

- `InspectMMEAlertSounds.pas`
- `InspectMMEExtensionsNewMilkMaidSource.pas`
- `InspectSkyrimNetPlayerAlias.pas`

The PowerShell and batch files in this folder are developer maintenance helpers and are not included in the game package.

## SDK Shims

`mme-sdk` includes small declaration-only shims for external Papyrus APIs used by the action bridge. They keep release builds independent of unrelated optional source dependencies; Skyrim resolves the real MME and SexLab implementations at runtime.
