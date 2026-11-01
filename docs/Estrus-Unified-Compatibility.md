# Estrus Unified pregnancy support

**Estrus Unified pregnancy support** is preselected in Optional Mod Compatibility
when `EstrusUnified.esp` is active. You can untick it; when the ESP is inactive or
missing the option is unavailable. The installer automatically selects
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
outside the release. The current package includes the integrated JSON/MCM changes.

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

## Player pregnancy test

Troubleshoot > Gameplay Tests includes **Estrus Pregnancy Type** (click to cycle
Chaurus, Spider, Dwemer), **Test Player Estrus Pregnancy**, and **Last Estrus Test**.
Close MCM after clicking RUN. The selected type is captured for that request.
The test uses the documented EC/ES/EDStartAnimation ModEvent with pregnancy-only
mode (-1), without starting an animation. It respects Estrus settings and existing
pregnancy restrictions, and checks the player's public API result for up to ten
checks after dispatch. Event dispatch alone is not reported as pregnancy success.
The last result is visible when MCM is reopened; short notifications accompany it.

Only the optional compatibility choice supplies the API-aware test facade. The
base facade reports missing support without linking Estrus API types. An unavailable
or disabled integration can decline the request. Exact internal rejection reasons
are not exposed by the public interface; inspect Estrus settings/logs when unconfirmed.
Player breeder effects retain original side effects, including SexLab purity changes.
The test does not independently change MME milk-maid state or force milk production.

Routine footprints use `[MME Extensions Estrus Test]` and require master Papyrus
Logging; verbose logging is not required. They cover entry, actor/type, eligibility,
skips, dispatch, verified result and cleanup. Event allocation/dispatch failures and
invalid internal inputs are smoke alarms. No per-check polling traces are emitted.
