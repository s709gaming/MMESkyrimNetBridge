# Body effect magnitude description preflight

Status: investigation complete; implementation pending. No installed files, plugins or runtime state changed.

## Evidence

houseCARL confirmed VortexToMO2 / Default and active MMEAlert.esp. The winning records have no competing overrides:

- 0008C1:MMEAlert.esp Milk Burden ability: Description contains Movement speed reduced by <mag>%.
- 0008C3:MMEAlert.esp Milk Weight ability: Description contains Carried milk reduces carry capacity by <mag> points.
- Their magic effects 0008C0 and 0008C2 repeat these descriptions and both have NoMagnitude, NoDuration, NoArea and Detrimental flags.
- Both effects use Script archetype, ActorValue None, no attached VMAD: they are display records, not the actor-value modifier owner.
- Papyrus log on 2026-10-27 at 21:13:58 reports Milk Burden display updated with magnitude 10. This confirms the display dispatcher supplied a number, not that the engine substituted it or that current engine actor values were measured.

Repository origins: tools/AddMMEBodyEffects.pas authors both the spell DESC overrides and NoMagnitude flags. tools/PatchMMEBodyEffectDescriptions.ps1 also writes the token-bearing spell descriptions using padded binary replacement. tools/Test-BodyEffectsContracts.ps1 currently requires those DESC overrides, so passing it does not validate in-game substitution.

## Proposed implementation

1. Remove the spell-level description override from the two display abilities so descriptions can derive from each magic effect. Keep <mag> in the magic effect descriptions.
2. Clear only NoMagnitude on the two display magic effects. Preserve script archetype, ActorValue None, no VMAD, no duration/area, and all links/FormIDs. Do not convert the display effect to a value-modifier archetype: actual penalties already belong to MMEBodyEffects.ApplyOwnedModifier.
3. Update the authoritative xEdit generator and retire or correct the fixed-length text patch utility so it cannot recreate the bug. Use a record-aware repository plugin edit, not padded text replacement. Check the resulting repository plugin and packaged plugin at the field level.
4. Replace the old DESC-required contract with checks for absent spell overrides, valid magic-effect token descriptions, magnitude allowed, display-only archetype, and unchanged gameplay fields. The exact rendering fix requires an in-game check; NoMagnitude and override precedence are the identified suspects, not separately proven causes.
5. Preserve existing reconciliation, saved keys, defaults and owned modifier calculations. Record-only changes should need no new Papyrus gameplay routes. Existing [MME Extensions Body] master-gated display update/remove traces and deduplicated prerequisite/add failures cover this route. If a PSC refresh migration proves necessary, inspect signatures, compile it, keep PSC/PEX matched, and trace the one-time refresh behind the master toggle.
6. Rebuild MME Extensions.zip and inspect all affected record fields and archive structure. No installation or release version changes.

## Acceptance checks and risks

- After a full game restart, test Milk Burden at two nonzero penalties (for example 3 and 10) and Milk Weight at two values; confirm actual numbers appear, not mag or a missing/zero number.
- Compare displayed values against owned modifier logs, and inspect actor-value deltas independently where available. Ensure the display ability never applies an additional penalty.
- Turn each feature off independently and disable Extensions: display and owned penalty cleanup must remain correct. Check zero milk, threshold transitions, overflow and repeated reconcile without modifier stacking or repeated spell churn.
- Existing save/load: unchanged IDs and keys should preserve compatibility. Existing display ability may need removal/re-addition if the engine retains old active-effect magnitude; first test existing behavior on load and the next magnitude transition before adding migration logic.
- Player-only route remains player-only; no new NPC behavior or optional dependency is introduced. Test with logging on/off; no new log spam or stack dumps.
- Live rendering remains the acceptance gate. Do not mark the issue fixed from source/record tests alone. If automatic substitution still fails, investigate that renderer path before choosing a dynamic-description solution or a deliberately nonnumeric fallback.

Verdict: small, localized display-record fix with low gameplay risk if the display-only archetype is preserved. The existing source contract was insufficient and must be corrected alongside the records.

## Implementation completed, 2026-10-27

Repository MMEAlert.esp updated through tools/body-display-builder (Mutagen). Spell descriptions are cleared to empty text (the writer requires a non-null translated string); the xEdit generator removes DESC altogether. Both represent no custom description text. Both magic effect descriptions retain their magnitude tokens, and only NoMagnitude is cleared (flags 0xE04 to 0xA04). Script archetypes, ActorValue None, VMAD absence and all existing identities remain unchanged. The record-aware helper replaces the old padded ASCII patch utility.

Round-trip validation compares all 80 records against the intentionally edited in-memory source and checks the full header, retaining original master order/content. Binary record regression checks independently inspect descriptions, flags, VMAD absence, effect links and magnitude/area/duration. Existing body contracts now reject the old description overrides and NoMagnitude configuration. No PSC or PEX changes, migration or additional traces were needed. Existing master-gated display-update/remove traces remain intact.

Updated the OStim-only manifest core-plugin hash, rebuilt the generic archive, and verified contents. Installed files and runtime state were not changed. Correct in-game number rendering and existing-save refresh remain pending user installation and smoke testing.
