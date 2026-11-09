# Preferred milk type

**Control:** MME Extensions > General > MME Quick Settings > Milking & Production >
Only Produce Preferred Milk Type. Default on for new saves and once when introduced
to an existing save.

**Authority:** Directly mirrors original MME's `MilkQC.MME_SimpleMilkPotions` (Simple
Milk). Changing either menu changes the same property. A save-local marker records
only that the initial default was applied; it never mirrors the selected value.
Initialization waits for original MME's `MilkFlag` and conditions object. Existing
controller updates retry pending initialization without another timer or actor scan.
After initialization, later choices and original MME resets are respected.

**Selection:** Original MilkECON owns detection, forced classifications, quantities,
inventory/container output and trade. Its priority is Succubus, Vampire, Werewolf,
then ordinary racial milk. Each branch includes an Exotic fallback for an unknown
race. Detection must still recognize the supernatural status; unsupported succubus
mods may require MME's existing manual classification.

**Quality:** This original mode chooses the basic item in the selected category,
without Maid-level quality tiers. Off restores MME's ordinary basic/racial selection,
not an absolute ban on racial or supernatural milk. Applies to player and NPC maids.
Existing bottles are unchanged. No original MME script is overridden for this feature.

**Diagnostics:** Default application and user changes use master-gated original-
settings traces. Missing prerequisites during startup are expected waits. Requested
operations with missing settings or failed writes use existing deduplicated alarms.

**Validation:** Source-execution tests cover initialization, later original-menu
choices, disabled/missing startup prerequisites, toggling, pending readiness and
failed writes. In-game bottle output, menu appearance and real save/load acceptance
remain separate live checks.
