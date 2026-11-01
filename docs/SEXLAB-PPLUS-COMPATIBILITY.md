# MME Extensions — SexLab P+ Compatibility

This optional FOMOD component provides the complete MME Extensions compatibility layer for SexLab P+.

## Requirement

SexLab P+ must be installed separately. The SexLab P+ framework is not included in MME Extensions.

The separate **MME SLP+ Edit** package is not required when this FOMOD component is installed.

## Required after installation

Run your behavior generator after installing or updating this component. FNIS is the confirmed generator for the bundled converted animations. The SLSB registry can discover the scenes without this step, but actors will reject their animation events if the generated behavior graph has not been rebuilt.

## Included compatibility work

- A SexLab P+ backend for MME Extensions breastfeeding transactions.
- Adjusted `MME_Dialogues` and `MilkPlayerLoadGame` scripts for SexLab P+ animation discovery and scene handling.
- Converted 3jiou breastfeeding animations and behavior data.
- The corresponding SexLab P+ SLSB animation registry.
- Source files for the distributed Papyrus changes and registry definition.

The converted scenes preserve the intended roles: the Milk Maid is the milk source and the other participant is the drinker.

## Installation boundary

These files are installed only by the **All-in-One SexLab P+ Compatibility** FOMOD option. Standard SexLab installations continue to use the standard MME Extensions backend and do not receive the P+-specific MME overrides, animations, or registry.

## Credit and permission

The MME SexLab P+ script edits and converted 3jiou breastfeeding assets originated in the contributed **MME SLP+ Edit**. They are bundled, modified, and redistributed here with the contributor's permission. Thank you to the contributor for the working conversion and permission to integrate it into MME Extensions.

Milk Mod Economy, SexLab, SexLab P+, and the original animation work remain the work of their respective authors. This compatibility component does not include the SexLab P+ framework itself.

## Stage-hook correction

The P+ MME load-script override now validates participants and rejects empty-source Mode-4 milking before inventory actions and dispatch. Stage-change retries remain available for legitimate milk replenishment; the original MME passive-spell concurrency guard is retained and rechecked before dispatch. Master Papyrus logging records eligibility, skips, dispatch and return. The override is necessary because original MME dispatches outside its milk-availability check. The package build explicitly recompiles this hook. Generic milking narration defaults use neutral wording without assuming self-milking or an empty source; existing custom overrides are preserved.
