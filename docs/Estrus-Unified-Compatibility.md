# Estrus Unified pregnancy support

Select **Estrus Unified pregnancy support** in Optional Mod Compatibility when
using Estrus Unified. Its ESP must be active. The installer automatically selects
the matching Standard SexLab/P+ or OStim-only MilkQUEST override at priority 60.
Unified's own DLL and complete API script remain required and are not bundled.

## Author's patch

Based on the author's supplied MME Extensions 1.4.3 patches and Author Instructions
(attributed to risarei in the original integration notes). Each build rebases that
small change onto our current backend source instead of copying the older PEX:
reject an invalid actor; check the ESP, SKSE plugin and IsReady; then call
EstrusUnifiedAPI.GetPregnancyType on the actual player or NPC. Types 1 Chaurus,
2 Spider and 3 Dwemer return true. A missing/unready dependency or type 0 falls
through to all original pregnancy checks. Legacy plugin flags are unchanged.
Do not enable the legacy Estrus ESPs alongside Unified.

Our additions are gated traces, invalid-result validation, and deduplicated
invalid-actor/result alarms. Three private variables suppress diagnostics only;
they are not properties and never supply readiness or pregnancy answers. Their
defaults are safe on existing saves and no MCM migration is needed. Every query
checks the real API again. MME's slots, growth, conversion, milk calculations and
scene triggers remain unchanged. Original MME can automatically assign an eligible
pregnant player a Milk Maid slot; this recognition permits that original behavior.

## Installation and upgrades

The default backend scripts contain no Unified API references. This optional
override changes only MilkQUEST source and PEX; it does not replace Unified's
scripts, MilkMCM or body-scaling scripts, and adds no plugin master. The compile-only
API declarations under tools/estrus-unified-sdk are never distributed at runtime.

Use mod-manager **Replace** when changing this option to avoid stale overrides.
Reinstall without this option before removing Unified: the selected script has a
deliberate dependency on Unified's API type. Presence guards are not a guarantee
for a broken installation with a missing or mismatched API script. Keep your
animation backend; switching SexLab/OStim on an existing save remains unsupported.

When replacing the experimental native integration, replace the full Extensions
mod to remove the retired MMEEstrusUnified helper. Its native query/registration
has been removed from this branch and preserved in a development source backup
outside the release. Integrate concurrent JSON/MCM changes before deploying a
full package from this worktree; this package does not contain those changes.

## Diagnostics and verification

Readiness-state changes use the master Papyrus logging switch. Repeated actor
entry/result/completion details require master and verbose logging. Invalid actor
and out-of-range results produce one alarm per failure category. Normal absence,
startup unready state and nonpregnancy are not alarms.

Build checks verify both compiled source/PEX pairs, unchanged original fallbacks,
and installer routing/priority for Standard, P+ and OStim with the option on/off.
On October 31, 2026, the direct-call Standard variant passed an independent MO2
installation and live existing-save test: readiness state 2, two player queries
returning type 0, and an NPC query returning type 0 on the correct reference.
All queries completed and continued original pregnancy checks, without Estrus
API errors or alarms. The test used Unified 1.1.0 on runtime 1.7.104.0.

The installer test also found a missing compatibility guide in the archive; the
guide is now included, and packaging validates every FOMOD file/folder source.
Positive pregnancy types, birth/reset, dependency absence, broader save/load and
logging combinations, P+ and OStim still require runtime validation. This basic
test is not full gameplay acceptance. The game was quit without an explicit save
and the original MO2 activation restored after the test.
