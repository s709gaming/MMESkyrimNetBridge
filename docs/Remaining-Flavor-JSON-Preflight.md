# Remaining flavor messages: JSON research preflight

October 31, 2026. Research and planning only. Inspected current repository source and editor architecture; did not modify gameplay scripts, runtime JSON, editor code, native code, installed mods, profiles or release packages. Existing unrelated worktree changes are preserved. No game actions, build or commit were performed.

## Recommendation and scope

Convert 26 existing on-screen message routes to the same personal JSON editing system. Nine belong with ordinary feature messages; 17 less-used messages belong behind **Show minor messages**, unchecked by default. Preserve the current wording as the shipped default, initially one variant per entry. This is extraction of existing wording, not new flavor writing or new gameplay.

The source audit found additional custom-registry equip/removal notifications beyond the earlier quick scan. It did not establish a need for new story-popup or Skyrim.Net creative-prompt entries in this pass: existing story/AI JSON already covers the main routes. Do not convert factual narration boundaries, prompt assembly, diagnostic output, error messages or underlying original/third-party mod text just to increase coverage.

The current generated catalog contains 147 entries: 51 exposed Skyrim.Net, 60 exposed game messages/stories, and 36 internal. This proposal adds 26 game-message entries for 173 total: 51 AI, 86 player-editable messages, 36 internal. With minor messages hidden, 69 message entries remain visible. The 36 existing internal entries and old personal overrides remain effective.

The companion [source-anchored inventory](Remaining-Flavor-JSON-Inventory.json) records every proposed ID, title, source/function/line, exact original expression, proposed tokenized default, token contract, trigger, placement, and caution. IDs/templates are proposals, not installed runtime JSON. Sources are the repository layer; this does not establish what a running game currently loads.

## Proposed entries

All entries are HUD-only. Similar AI reactions use separate prompts; do not label these Shared merely because the same event also requests narration.

| Proposed key | Player-facing title | Placement | Required tokens | Source |
| --- | --- | --- | --- | --- |
| `capacity_half` | When Her Breasts Become Half Full — Message | Milking & Fullness | {actor} | [MMEAlertsController.psc:2384](../Source/Scripts/MMEAlertsController.psc#L2384) |
| `capacity_full` | When Her Breasts Become Full — Message | Milking & Fullness | {actor} | [MMEAlertsController.psc:2382](../Source/Scripts/MMEAlertsController.psc#L2382) |
| `armor_strip` | When Her Armor Pops Off — Message | Armor Reactions | {armorName} | [MMEArmorScript.psc:266](../Source/Scripts/MMEArmorScript.psc#L266) |
| `refit_needed` | Milking Equipment Needs a Refit — Message | Service Reminders | None | [MMEMilkingEquipmentRefit.psc:201](../Source/Scripts/MMEMilkingEquipmentRefit.psc#L201) |
| `refit_complete` | After a Successful Equipment Refit — Message | Service Reminders | None | [MMEMilkingEquipmentRefit.psc:168](../Source/Scripts/MMEMilkingEquipmentRefit.psc#L168) |
| `armor_lock_player` | Trapped in Armor — Your Character | Armor Locks | {days} | [MMETimedArmorLock.psc:253](../Source/Scripts/MMETimedArmorLock.psc#L253) |
| `armor_lock_npc` | Trapped in Armor — Another Character | Armor Locks | {actor}, {days} | [MMETimedArmorLock.psc:255](../Source/Scripts/MMETimedArmorLock.psc#L255) |
| `armor_released` | Released from Timed Armor — Message | Armor Locks | {actor} | [MMETimedArmorLock.psc:360](../Source/Scripts/MMETimedArmorLock.psc#L360) |
| `parasite_satisfied` | Parasite Armor Is Ready to Let Go — Message | Armor Locks | {actor} | [MMETimedArmorLock.psc:423](../Source/Scripts/MMETimedArmorLock.psc#L423) |
| `rescue_blacksmith_single` | Blacksmith Frees One Companion | Armor Locks / minor | {actor} | [MMEFollowerArmorRescue.psc:92](../Source/Scripts/MMEFollowerArmorRescue.psc#L92) |
| `rescue_direct_single` | One Companion Is Freed | Armor Locks / minor | {actor} | [MMEFollowerArmorRescue.psc:94](../Source/Scripts/MMEFollowerArmorRescue.psc#L94) |
| `rescue_blacksmith_group` | Blacksmith Frees Several Companions | Armor Locks / minor | {count} | [MMEFollowerArmorRescue.psc:98](../Source/Scripts/MMEFollowerArmorRescue.psc#L98) |
| `rescue_direct_group` | Several Companions Are Freed | Armor Locks / minor | {count} | [MMEFollowerArmorRescue.psc:100](../Source/Scripts/MMEFollowerArmorRescue.psc#L100) |
| `venue_thirst` | Someone Nearby Wants Milk — Message | Drinking Milk & Breastfeeding / minor | None | [MMEAlertsController.psc:279](../Source/Scripts/MMEAlertsController.psc#L279) |
| `venue_drink_fallback` | A Nearby Character Drinks Milk — Simple Message | Drinking Milk & Breastfeeding / minor | {actor} | [MMEInnPalaceMilkEvent.psc:223](../Source/Scripts/MMEInnPalaceMilkEvent.psc#L223) |
| `chest_drink` | A Chest Makes Someone Drink Milk — Message | Drinking Milk & Breastfeeding / minor | {actor}, {milkName} | [MMEChestMilkTrap.psc:176](../Source/Scripts/MMEChestMilkTrap.psc#L176) |
| `custom_dwemer_equip` | Custom Dwemer Armor Attaches — Message | Armor Reactions / minor | {armorName} | [MMECustomArmorRegistry.psc:321](../Source/Scripts/MMECustomArmorRegistry.psc#L321) |
| `custom_rows_absorbed` | Custom Living Armor Absorbs Extra Breast Rows — Message | Armor Reactions / minor | {armorName} | [MMECustomArmorRegistry.psc:327](../Source/Scripts/MMECustomArmorRegistry.psc#L327) |
| `custom_living_equip` | Custom Living or Parasite Armor Attaches — Message | Armor Reactions / minor | {armorName} | [MMECustomArmorRegistry.psc:331](../Source/Scripts/MMECustomArmorRegistry.psc#L331) |
| `custom_cups_equip` | Custom Milking Cups Attach — Message | Armor Reactions / minor | None | [MMECustomArmorRegistry.psc:344](../Source/Scripts/MMECustomArmorRegistry.psc#L344) |
| `custom_living_remove` | Custom Living or Parasite Armor Comes Off — Message | Armor Reactions / minor | {armorName} | [MMECustomArmorRegistry.psc:364](../Source/Scripts/MMECustomArmorRegistry.psc#L364) |
| `custom_cups_remove` | Custom Milking Cups Come Off — Message | Armor Reactions / minor | None | [MMECustomArmorRegistry.psc:373](../Source/Scripts/MMECustomArmorRegistry.psc#L373) |
| `new_maid_confirmation` | A New Milk Maid Is Confirmed — Message | Becoming a Milk Maid / minor | {actor} | [MMENewMilkMaid.psc:345](../Source/Scripts/MMENewMilkMaid.psc#L345) |
| `reverse_level_applied` | Milk Maid Level Reduction Begins — Message | Milking & Fullness / minor | {hours}, {levels} | [MMEReverseLevel.psc:98](../Source/Scripts/MMEReverseLevel.psc#L98) |
| `reverse_level_removed` | Milk Maid Level Reduction Ends — Message | Milking & Fullness / minor | None | [MMEReverseLevel.psc:117](../Source/Scripts/MMEReverseLevel.psc#L117) |
| `reverse_level_decrease` | Her Breasts Feel Lighter — Message | Milking & Fullness / minor | {levels} | [MMEReverseLevel.psc:316](../Source/Scripts/MMEReverseLevel.psc#L316) |

## Route decisions that matter

- **Fullness:** replace only the half/full message inside ProcessActor's existing enableCapacityNotifications and local-reaction path. Preserve its crossing/latch logic and early returns. Do not turn recurring scans into recurring notifications.
- **Stripping/refit:** retain the current generic strip versus refit-reminder substitution. The refit reminder fires once per pending removal episode. Keep successful-refit feedback separate from refit errors. Preserve the existing second-person generic strip default rather than silently correcting possible NPC grammar while extracting text.
- **Timed armor:** player and NPC trap messages use the existing rounded-up shownDays, not raw duration or a new rounding implementation. ReleaseInternal must continue respecting showNotification. Parasite expiry clears its lock but leaves the armor equipped; its message must not acquire automatic-removal behavior.
- **Rescue:** four summaries preserve actual successful rescue count/name and blacksmith/direct singular/plural branches. The direct messages also follow a deliberate MCM rescue action; this is feedback for a real action, not routine debug trace output. No-target and rejection messages stay internal. Keep current removal/publication behavior, including any existing per-actor feedback; do not add or consolidate notifications incidentally.
- **Custom armor registry:** six messages are player-only under existing custom classification. The extra-breast-row branch may show both its specialized message and the ordinary attach message; preserve that sequence. Do not move, suppress or reimplement Milk Maid registration, breast-row changes, Lactacid or passive-spell writes when changing the strings.
- **Venue announcement:** no drinker exists when the timer is armed. The text must not gain an actor placeholder, trigger an extra scan, or imply a particular NPC has already drunk.
- **Venue simple message:** this is a low-frequency HUD branch only when a rendered drink reaction was not provided. Normal outcome reactions already use JSON and stay authoritative; this new minor entry does not replace them.
- **Chest drinking:** BuildSituation currently has exactly one source caller, the owned HUD message. Its AI route independently calls NarrateChestMilkDrink using canonical JSON. Preserve stored milk-name fallback, ownership and Notified/Narrated deduplication; do not redirect AI through this editable HUD string.
- **New Maid confirmation:** expose MakeTargetNewMilkMaid's success notification only. The similarly worded controller message is diagnostic and stays internal. Existing conversion feedback and AI prompts remain separate.
- **Reverse leveling:** preserve current application/removal gates, silent removals, progress state and calculations. Use the existing displayed duration and a supplied display value of 1 for the one-level message. A JSON edit never determines the actual decrease or monitoring duration. Do not add an expiry notification where no notification currently exists.

## Existing text that should stay out

- Controller/debug creation and milking start/end notices; trace/report functions; installation audits and test actions.
- Missing dependency/form, busy, unavailable target, failed refit, failed ability and changed-state rejection messages.
- Armor registry Add/Remove confirmations and Dwemer attachment installed/removed status: these communicate service/configuration operations rather than flavorful reactions. Keep their error/status consistency for this pass.
- Nobody nearby needs rescuing: normal expected rejection feedback, not a creative event. It is not an alarm either.
- MMEChestCurseNarration's conversion/surge factual descriptions and fixed outcome boundaries. Its creative outer prompt is already JSON-backed.
- Existing fallback stories/text in ArmorIntroduction, TentacleEffects, Dwemer profiles and typed-list readers. They are resilience defaults for controls already exposed, not additional creative entries.
- NPC dialogue records, MCM labels, optional third-party replacement scripts and original MME MilkQUEST wording. Those are outside this extraction's source boundary.

## JSON and reader design

Propose one ordinary pool file: SKSE/Plugins/StorageUtilData/MMEAlerts/FlavorNotifications.json, using named arrays, and IDs Pools.FlavorNotifications.<key>. This follows the existing pool resolver/personal override convention. Do not change or merge the existing 147 entries. No new profile schema or save migration is needed; missing new overrides simply use the shipped base text.

Use explicit required/allowed token contracts for these entries, authored alongside tools/narration-schema.json or in a small tools/flavor-notification-schema.json consumed by the generator. Do not infer required dynamic facts from whatever prose happens to be in a variant. Names/days/count/hours/levels come from existing route values, already selected actors and existing string conversion. The inventory lists the initial minimal contracts. Do not permit actor on an announcement before a target exists, or use the last rescued name as if it represented an entire group.

Prefer one thin common facade, provisionally MMEFlavorText.psc, over duplicating readers/renderers in ten scripts. Reuse MMETextPool.Pick for personal/base selection, ordinary/legacy handling and existing failures, and MMENarrationText.Render for bounded token substitution. Verify signatures from their actual sources before implementation. Add no SkyrimNetApi, SexLab or other optional dependency to the facade. Do not write to JSON from notification routes.

The facade must accept the entry, original compiled fallback, existing subject/context and supplied token strings. A failed/blank/unresolved rendering must fall back to the original safely rendered message without aborting the underlying successful action or displaying raw braces. The renderer does not escape or reparse replacement values as new templates; actor/armor/item names containing braces must stay literal. Exercise that property in tests.

All initial pools have one variant. Avoid an unnecessary random draw for a one-variant pool if practical without changing existing general pool behavior. Multi-variant wording may consume a text-selection roll; do not add effect/conversion chance rolls or change probability settings. Preserve variant order and duplicate weighting. Do not promise an identical global random-number sequence after introducing randomized wording.

MMETextPool's base path currently reports a master-gated selection trace per call, while MMENarrationOverrides.TraceSource deduplicates source/revision per subject. Reuse those correctly rather than assuming every resolver trace is already deduplicated. These routes are event/crossing messages, not new polling ticks. Keep additional per-message tracing sparse or verbose-only; leave the existing generic pool logger unchanged unless a separate regression-safe improvement is necessary.

## Editor placement

Reuse Game Messages & Stories and the existing Feature dropdown. Proposed placements are in the inventory. Add **Show minor messages** only to this section. Its help: “Include less-used equipment, service and encounter messages. This changes the editor list, not which messages appear during play.” Keep it off by default and remember it with the existing local navigation preference when storage is available; do not create an MCM or gameplay setting.

Use presentation.minor=true on the 17 minor entries, not presentation.visible=false: those are normal editable fields, not internal safeguards. Primary additions remain visible normally. Search and Modified Only operate within the selected section/feature/minor filter. Show an unobtrusive hidden-minor count, including customized ones, so old edits are discoverable without silently overriding the checkbox. Do not add a new tab or duplicate shared controls.

Changing the checkbox, feature, section or search must retain drafts. Save commits all staged edits as before. Reset Player Text must explicitly include all 137 player-editable entries across both sections, including filtered-out minor entries, while retaining 36 internal entries and unknown overrides. This is the current reset semantic extended to the new catalog, not a reset limited to the screen. Capture/legacy staging, presets, inheritance notices, backup and full-replacement warnings retain their existing scopes.

## Papyrus footprints and alarms

- Keep existing gameplay boundary traces for actor eligibility, action success, ownership, lock state and cleanup. No new timers, actor scans or polling traces.
- Reuse [MME Narration Editor] source footprints and [MME Text Pool] failures. Pass the actual actor when already available. A venue announcement/group summary may legitimately have actor=None; identify the entry/count/source instead of inventing a target.
- If the thin facade needs its own render-failure boundary, use [MME Flavor Text], the entry ID, actor/context and concrete failure reason. Rate-limit/deduplicate by entry and failure category. A malformed shipped/user text pool or impossible blank fallback is a genuine failure; absent personal customization and optional native/editor integration are expected fallbacks, not alarms.
- Routine additional diagnostics use existing master logging, with repeated selected-index/display details verbose-only. Do not print personalized story text or routine diagnostics as extra player notifications.
- Test master off, master only, master+verbose, and repeated malformed-file attempts. Confirm a missing optional native component still displays the original message without a loop of alarms.

## Affected files and builds

Ten gameplay source files listed by the inventory, plus the proposed common facade. Support changes: FlavorNotifications.json; explicit token schema; tools/generate_narration_catalog.py; tools/narration-presentation.json; generated include/NarrationCatalog.h; dashboard.js/index.html; build-package.ps1; relevant contract/native/editor tests and documentation. Catalog RPC already forwards the presentation object, so a minor flag should not require a new protocol or request operation. Do not add a separate store or editor.

Compile every changed PSC and the new helper. The OStim generator produces variants for MMEAlertsController, MMEArmorScript and MMENewMilkMaid from common sources; regenerate those rather than editing generated variants independently. Other listed routes should remain common. Verify the isolated OStim import set sees the current helper. Do not modify MilkQUEST or framework calls for this text-only work; if implementation unexpectedly needs that, stop and revisit scope with verified original MME signatures/array behavior first.

Regenerate the native catalog and rebuild universal/VR DLLs. Keep source/PEX pairs matched, update generated manifests through the existing pipeline, build MME Extensions.zip, and verify standard/OStim options, MO2/Vortex FOMOD compatibility, current UI/native bytes and absence of diagnostic artifacts. No installation or commit is authorized by this preflight.

## Tests and acceptance

1. Inventory coverage: 26 unique IDs, source calls still present, exact original default wording and numeric formatting; explicit token contracts and catalog counts 173/51/86/36. Exclude diagnostic/internal categories above.
2. Resolver: personal/base/compiled precedence; one/multiple/duplicate variants; missing file/pool, malformed JSON, wrong types, blanks and unresolved tokens. Preserve literal braces/Unicode/long names in replacements; reject unsupported user tokens without breaking the action. Test without native editor integration too.
3. Routes: half/full crossing and no-repeat behavior; strip versus refit substitution; refit success/error; player/NPC locks and rounded days; silent release; parasite deadline without unequip; singular/plural blacksmith/direct rescue using successful count; custom equip/unequip and multi-row branch; announcement before target selection; normal venue reaction versus rare simple message; owned chest context; confirmed conversion only; reverse-level apply/remove/decrease with silent/no-change paths.
4. Preserve enabled/disabled behavior, actors, cooldowns, rolls, notifications, sounds, animations and cleanup. No new effect while combat/busy guards reject an action, no duplicate queue/publication and no wrong-actor text. Test player/NPC routes independently where currently supported; do not extend player-only routes to NPCs.
5. Editor: primary/minor visibility, group counts, search/Modified Only, preference restoration, draft retention, save/reset of filtered minor edits, preservation of internal/unknown edits, atomic validation, presets, fallback display and short explanatory titles. No JSON prose or IDs change in the older catalog.
6. Compile both backend contexts; run relevant existing contracts for timed armor, follower rescue, refit, custom registry, chest/venue drinking, conversion and reverse leveling. Update string-specific assertions to verify the extracted contracts rather than deleting behavioral checks.
7. Final archive verification plus separately authorized in-game visual/log acceptance: existing save/new defaults, optional Skyrim.Net absent/present, optional native absent, no stack dumps, repeated noise, stale state, stranded movement or notification spam. A passing build is not runtime acceptance.

## Decision

Ready for implementation once this scope is approved. The main work is safe extraction and editor integration, not inventing new events or stories. This preflight deliberately keeps rejected actions, diagnostics, gameplay facts and existing fallback plumbing internal.
