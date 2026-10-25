# FOMOD backend flag gating preflight

Date: 2026-10-25. Investigation only; installer/package/installed mods unchanged.

## Implementation result

Implemented after this preflight: startup/backend selections remain on page one;
the existing compatibility group is now on page two. All option contents, flags,
requirements, priorities and file mappings were preserved. The new
tools/test_fomod_backend_gates.py rejects same-page producers/consumers and the
previous archive, and passes all 18 corrected backend/plugin-state cases plus
a backend-revisit selection model. It is integrated into Test-OStimOnly.ps1;
that suite also passed its 65-effective-script bytecode and source/PEX checks.

Updated dist/MME Extensions 1.4.1.zip in place. CRC/member verification found
506 entries and exactly one changed member: fomod/ModuleConfig.xml. Gameplay
payloads and the archived README were untouched. SHA256:
895678f701b719cf6437fc64c05cc325dbd57ce2393989827dd9556ecbaca210.
Rollback copy: build/diagnostics/fomod-gating-before/MME Extensions 1.4.1.zip.

The native MO2 installer UI was not exercised; Back/Next and reinstall-preset
behavior remain a manual acceptance check. The model follows upstream MO2's
Required/NotUsable selection behavior but is not a native UI test. No installed
mods, profiles, game files or Vortex installation were changed.

## Finding

Confirmed packaging design defect. The active Default profile has Jugs.esp active
and its JUGs mod enabled. The distributed archive now named
`dist/MME Extensions 1.4.1.zip` contains a ModuleConfig.xml byte-identical to the
repository version. Its JUGS rule requires both active Jugs.esp and
mmeNoSexLab=false, with NotUsable as the default.

All choices, including backend flag producers and the JUGS/Elsie consumers,
currently occupy the same Installation Options installStep. MO2's native FOMOD
source passes the current page index into getPluginDependencyType, and its
testCondition flag lookup iterates from maxIndex-1 backwards. Current-page flags
are intentionally outside that search. On page zero the search visits no pages,
so a requested nonempty value such as false fails. Standard SexLab selection
therefore cannot satisfy the JUGS gate. Elsie's gate has the same defect.

Primary source inspected at commit 7c3995682134a63b5040b7865b88a3749b056d68:
https://github.com/ModOrganizer2/modorganizer-installer_fomod/blob/7c3995682134a63b5040b7865b88a3749b056d68/src/fomodinstallerdialog.cpp
Relevant functions: getPluginDependencyType and testCondition, plus page control
type evaluation. The installed installer_fomod.dll exposes no file-version
metadata, so the exact shipped binary/source match was not established. The
source behavior reproduces the reported symptom and the XML design defect.

## Proposed fix

1. Keep startup presets and the exclusive Animation backend group on page one.
2. Move the entire existing Optional mod compatibility group to page two.
3. Preserve backend flags, file mappings, destinations, priorities, detection,
   labels and Required/NotUsable policy. Do not remove the OStim-only exclusion.
4. Keep active-plugin prerequisites for this focused fix. Supporting installed
   but unchecked dependencies would be a separate policy change, not required
   to repair the demonstrated bug.
5. Add a regression check that flag consumers have their producers on an earlier
   step. Exercise Standard, P+ and OStim-only against Active/Inactive/Missing for
   both JUGS and Elsie, and verify the selected file overlay for each backend.
6. Rebuild/repackage the distributable with the corrected XML, preserving the
   current release naming chosen by the user. Verify the archived XML and asset
   hashes; a layout-only fix does not require gameplay script changes.

An in-memory two-page candidate passed 18 backend/plugin-state rule cases using
MO2's earlier-page flag semantics. The current one-page layout reproduced
NotUsable for active JUGS under all three backend choices. This is a model of the
condition evaluator, not a completed native installer UI test.

## Acceptance and stop conditions

- With JUGS active, Standard/P+ makes its patch required/selected on page two.
- With Elsie active, Standard/P+ makes its patch required/selected on page two.
- Missing or inactive original plugins keep their corresponding patches blocked.
- OStim-only keeps both legacy patches blocked. Its current external plugin
  prerequisites still apply; do not weaken those to demonstrate a valid install.
- Back/Next after changing the backend must reevaluate page two and remove any
  stale incompatible selection/file payload. Check the native MO2 UI explicitly.
- Other compatibility options, presets and overlay priorities stay identical.
- Reinstall/Replace presets must not restore a forbidden selection. Confirm the
  final selected files rather than treating a disabled checkbox as proof.
- No README, Papyrus, ESP, installed MO2 profile, game Data or Vortex changes.

The fix is ready for implementation. Native MO2 UI/backtracking validation and
archive verification remain implementation acceptance work. No fix was applied
during this preflight.
